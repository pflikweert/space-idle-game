extends SceneTree
const Card = preload("res://scripts/systems/weapon_hud_card.gd")
const Prior = preload("res://../../scripts/godot/visual-gunship-qa.gd")
const UI = preload("res://scripts/systems/compact_ui.gd")
const Equipment = preload("res://scripts/systems/equipment_registry.gd")
var checks := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		printerr("FAIL: ",label)
		quit(1)
func _initialize() -> void: call_deferred("run_tests")
func run_tests() -> void:
	var railgun_definition := Equipment.definition(Equipment.RAILGUN_ID)
	var railgun_hud_path := str(railgun_definition.get("hud_art",""))
	check(str(railgun_definition.name) == "Railgun" and str(railgun_definition.rarity) == "normal","Railgun blueprint uses the visible name and normal rarity")
	check(railgun_hud_path == "res://assets/ui/weapon_cards/starter_railgun.png","Railgun keeps its dedicated gameplay-slot portrait")
	var railgun_hud: Texture2D = load(railgun_hud_path)
	check(railgun_hud != null and railgun_hud.get_size() == Vector2(1254,1254),"Railgun HUD portrait has a stable square canvas")
	var railgun_image := railgun_hud.get_image()
	check(railgun_image.detect_alpha() != Image.ALPHA_NONE,"Railgun HUD portrait preserves transparent alpha")
	var railgun_corners := [railgun_image.get_pixel(0,0),railgun_image.get_pixel(railgun_image.get_width()-1,0),railgun_image.get_pixel(0,railgun_image.get_height()-1),railgun_image.get_pixel(railgun_image.get_width()-1,railgun_image.get_height()-1)]
	check(railgun_corners.all(func(color): return color.a == 0.0),"Railgun HUD portrait has transparent canvas corners")
	var card := Card.new()
	root.add_child(card)
	card.update_state(2,2,0,6,true)
	check(card.reloading and card.remaining_fraction==1,"Full reload mask")
	card.update_state(1,2,0,6,false)
	check(card.remaining_fraction==0.5,"Pause reads actual timer without advancing it")
	card.update_state(0.45,0.9,0,8,true)
	check(is_equal_approx(card.remaining_fraction,0.5),"Reload modifier controls denominator")
	card.update_state(0,0.9,8,8,true)
	check(not card.reloading and card.remaining_fraction==0 and card.ready_glow>0,"Ready clears mask and triggers pulse")
	var other := Card.new()
	root.add_child(other)
	other.update_state(0.9,0.9,0,8,true)
	check(other.remaining_fraction==1 and card.remaining_fraction==0,"Card instances do not share reload state")
	for speed in [1,2,3,4,5,10]:
		var remaining := maxf(0,2.0-speed*0.1)
		card.update_state(remaining,2,0,6,true)
		check(is_equal_approx(card.remaining_fraction,remaining/2),"Speed uses supplied game timer")
	for dimensions in [Vector2(320,568),Vector2(390,844),Vector2(430,932),Vector2(844,390),Vector2(1280,800)]:
		for safe in [Vector4.ZERO,Vector4(12,24,12,20)]:
			var layout := UI.hud_layout(dimensions,1,safe)
			for rect in layout.buttons+layout.slots+[layout.cards]:
				check(layout.area.encloses(rect),"HUD stays inside safe area")
				check(rect.size.x>=44 and rect.size.y>=44,"Touch target at least 44px")
			check(not layout.weapon.intersects(layout.cards),"Auto Cards outside weapon row")
			check(layout.slots.size()==5,"Exactly five slots")
			for index in range(4): check(not layout.slots[index].intersects(layout.slots[index+1]),"Adjacent slots do not overlap")
	var game := Prior.Fixture.new()
	game.profile_store = Prior.MemoryStore.new()
	root.add_child(game)
	game.set_process(false)
	game.start_run()
	game.cards.choices = 25
	game.cards.ranks.reload = 2
	for speed in [1,2,3,4,5,10]:
		game.profile.settings.gameSpeed = speed
		game.app_backgrounded = false
		game.status = "running"
		var duration: float = game._railgun_stats().reload
		game.player.weapon.reload_timer = duration
		game.player.weapon.ammo = 0
		game._process(0.05)
		check(is_equal_approx(game.weapon_hud.remaining_fraction,(duration-0.05*speed)/duration),"HUD tracks actual sped-up reload with modifiers")
		game.status = "paused"
		var before: float = game.player.weapon.reload_timer
		game._process(0.1)
		check(game.player.weapon.reload_timer==before,"Pause preserves reload")
		check(is_equal_approx(game.weapon_hud.remaining_fraction,before/duration),"Paused HUD retains exact fraction")
	game.status = "running"
	game.wave_message_timer = 2
	game.card_notices.assign(["Power Railgun · +20% damage","Quick Reload · Reload ×0.90"])
	game._update_card_notice(0.1)
	check(game.card_notices.size()==2 and game.card_notice_timer==0,"Wave has priority over upgrade notices")
	game.wave_message_timer = 0
	game._update_card_notice(0.1)
	check(game.card_notices.size()==1 and game.card_notice.begins_with("Power"),"Upgrade notices process in order")
	game._update_card_notice(4)
	check(game.card_notices.is_empty() and game.card_notice.begins_with("Quick"),"Second upgrade follows first")
	var target := {"position":Vector2(100,100),"hp":30.0}
	game._apply_damage_to_enemy(target,12,false)
	check(game.enemy_damage_numbers[-1].amount==12 and not game.enemy_damage_numbers[-1].critical,"Normal feedback uses actual damage")
	game._apply_damage_to_enemy(target,25,true)
	check(game.enemy_damage_numbers[-1].amount==18 and game.enemy_damage_numbers[-1].critical,"Critical feedback uses actual loss and crit status")
	game.damage_numbers.clear()
	game._add_damage_number(2,"SHIELD",Color.CYAN)
	game._add_damage_number(3,"SHIELD",Color.CYAN)
	check(game.damage_numbers.size()==1 and game.damage_numbers[0].amount==5,"Rapid shield damage bundled")
	check(not game.auto_control.visible,"Dodge removed from HUD")
	check(game.weapon_huds.size()==5,"Current gameplay HUD owns five dynamic weapon-slot cards")
	for slot in game.weapon_huds: check(slot.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Weapon-slot cards ignore input")
	game.queue_free()
	card.queue_free()
	other.queue_free()
	await process_frame
	print("Weapon HUD checks: ",checks," passed")
	quit()
