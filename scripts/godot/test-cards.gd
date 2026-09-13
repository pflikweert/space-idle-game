extends SceneTree
const Cards = preload("res://scripts/systems/railgun_cards.gd")
const Game = preload("res://scripts/void_drifter_game.gd")
const Store = preload("res://scripts/profile_store.gd")
const Weapons = preload("res://scripts/systems/weapon_registry.gd")
var checks := 0
var failures := 0
var game
var path := ""
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+message)
func _initialize() -> void: call_deferred("run_tests")
func fresh() -> void:
	game.app_backgrounded = false
	game.profile = game.profile_store._default_profile()
	game.start_run()
	game.cards = Cards.fresh(37)
func run_tests() -> void:
	root.size = Vector2i(430,760)
	# Pure progression: milestones, offers, caps, RNG, full builds at every unlock level.
	for level in range(1,11):
		for seed_value in range(20):
			var state := Cards.fresh(seed_value)
			for choice in range(1,26):
				state.xp += Cards.threshold(state)
				var epic := choice in [4,9,16,25]
				expect(Cards.is_epic(state)==epic,"Exact epic schedule")
				expect(Cards.ensure_offer(state,level),"Enough eligible cards")
				expect(state.offer.size()==3 and state.offer[0]!=state.offer[1] and state.offer[1]!=state.offer[2] and state.offer[0]!=state.offer[2],"Three unique cards")
				for id in state.offer:
					var entry := Cards.definition(id)
					expect(entry.epic==epic and entry.unlock<=level,"Rarity and permanent gate")
				var saved := state.duplicate(true)
				var selected := Cards.auto_pick(state)
				expect(Cards.auto_pick(saved)==selected and saved.rng==state.rng,"Restored RNG chooses same card")
				expect(Cards.choose(state,selected),"Eligible choice succeeds")
				expect(not Cards.choose(state,selected),"Duplicate choice rejected")
				expect(Cards.epic_count(state)<=4,"Epic count capped")
				for entry in Cards.CATALOG:
					if entry.cap>0: expect(int(state.ranks.get(entry.id,0))<=entry.cap,"Rank cap respected")
	for n in range(5):
		var curve := Cards.fresh()
		curve.choices = n
		expect(Cards.threshold(curve)==[40,64,96,136,184][n],"Quadratic XP curve")
	var recent := Cards.fresh()
	recent.version = 2
	recent.choices = 2
	recent.xp = 24
	recent.ranks = {"power":2}
	Cards.migrate(recent)
	expect(recent.xp==48 and recent.ranks.power==2,"Version 2 migration preserves half progress")
	Cards.migrate(recent)
	expect(recent.xp==48,"Version 3 migration does not repeat")
	recent.version = 2
	recent.xp = 48
	recent.offer = ["power","reload","magazine"]
	Cards.migrate(recent)
	expect(Cards.choose(recent,"power"),"Version 2 pending offer remains selectable")
	var legacy := Cards.fresh()
	legacy.erase("version")
	legacy.choices = 2
	legacy.xp = 10
	legacy.ranks = {"caliber":1}
	Cards.migrate(legacy)
	expect(legacy.xp==48 and legacy.ranks.caliber==1,"Migration retains XP fraction and ranks")
	Cards.migrate(legacy)
	expect(legacy.xp==48,"Migration is idempotent")
	legacy.erase("version")
	legacy.xp = 0
	legacy.offer = ["power","reload","magazine"]
	Cards.migrate(legacy)
	expect(Cards.choose(legacy,"power"),"Legacy pending offer stays immediately selectable")
	legacy.choices = 27
	legacy.offer = ["power","reload","magazine"]
	legacy.xp = 999999
	var preserved: Dictionary = legacy.ranks.duplicate()
	expect(not Cards.ensure_offer(legacy,10) and legacy.offer.is_empty() and legacy.ranks==preserved,"Cap preserves old builds and removes offers")
	var stats_state := Cards.fresh()
	stats_state.ranks = {"power":2,"core":1,"caliber":1,"critical":3,"reload":2,"magazine":2,"twin":2,"piercer":1,"shredder":1,"shatter":1,"rampage":1}
	var values := Cards.stats(stats_state,6,20,0.9)
	expect(is_equal_approx(values.damage,47.3),"Workshop base, permanent multiplier and additive cards compose")
	expect(values.crit==1.0 and is_equal_approx(values.crit_multiplier,2.35),"Critical cap and damage multiplier")
	expect(values.magazine==8 and values.shots==3 and values.hits==4 and is_equal_approx(values.reload,1.62),"Magazine, projectiles, piercing, reload independent")
	path = OS.get_cache_dir().path_join("void-cards-test-%d.json" % Time.get_ticks_usec())
	var store := Store.new()
	store.profile_path = path
	store._write_json(path,{"saveVersion":3,"totalCoins":100,"permanentUpgrades":{"xp_gain":3,"damage":2},"workshopSpent":55})
	var migrated := store.load_profile()
	expect(migrated.saveVersion==4 and migrated.totalCoins==100,"V3 never refunds XP again")
	expect(migrated.railgunLevel==1 and migrated.railgunModules==0 and not migrated.settings.autoCards,"New profile fields default safely")
	expect(store.load_profile().totalCoins==100,"V4 reload remains idempotent")
	game = Game.new()
	game.profile_store = store
	root.add_child(game)
	game.set_process(false)
	fresh()
	game.cards.xp = 104
	var combat_rng: int = game.rng.state
	game._handle_card_progress()
	expect(game.status=="card_choice" and game.cards.offer.size()==3,"Manual level-up pauses")
	var shell: Control = game.overlay.rows.get_child(0).get_child(0)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = Vector2(10,10)
	press.pressed = true
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = Vector2(10,10)
	release.pressed = false
	game.overlay._card_input(press,shell,"card:"+str(game.cards.offer[0]))
	expect(game.cards.choices==0,"Card waits for release")
	var drag := InputEventMouseMotion.new()
	drag.position = Vector2(10,50)
	game.overlay._card_input(drag,shell,"card:"+str(game.cards.offer[0]))
	game.overlay._card_input(release,shell,"card:"+str(game.cards.offer[0]))
	expect(game.cards.choices==0,"Scroll gesture cannot select a card")
	expect(game.rng.state==combat_rng,"Card offers leave combat RNG untouched")
	var offer: Array = game.cards.offer.duplicate()
	game.profile = store.load_profile()
	game._restore_run()
	expect(game.status=="paused" and game.cards.offer==offer,"Reload restores same pending offer paused")
	game._on_panel_action("resume")
	expect(game.status=="card_choice" and game.cards.offer==offer,"Resume returns to same choice")
	shell = game.overlay.rows.get_child(0).get_child(0)
	game.overlay._card_input(press,shell,"card:"+str(offer[0]))
	game.overlay._card_input(release,shell,"card:"+str(offer[0]))
	expect(game.cards.choices==0 and game.selected_card==offer[0],"Tap selects without applying")
	var keyboard := InputEventAction.new()
	keyboard.action = "ui_accept"
	keyboard.pressed = true
	shell = game.overlay.rows.get_child(0).get_child(1)
	game.overlay._card_input(keyboard,shell,"card:"+str(offer[1]))
	expect(game.cards.choices==0 and game.selected_card==offer[1],"Selection can change before Equip")
	game._on_panel_action("equip_card")
	expect(game.cards.choices==1 and game.cards.xp==64 and game.status=="card_choice","Overflow XP queues next manual choice")
	game._on_panel_action("auto_cards")
	expect(game.cards.choices==2 and game.status=="running" and game.profile.settings.autoCards,"Enable Auto Cards resolves pending choice and resumes")
	game.cards.xp = 400
	game._pause_run()
	var before: int = game.cards.choices
	game._handle_card_progress()
	expect(game.cards.choices==before,"Ordinary pause blocks automatic selection")
	game.app_backgrounded = true
	game._on_panel_action("resume")
	expect(game.status=="paused" and game.cards.choices==before,"Background blocks resume and selection")
	game.app_backgrounded = false
	game._on_panel_action("resume")
	expect(game.cards.choices==before+1,"Resume processes auto choice")
	game._on_panel_action("auto_cards")
	expect(game.status=="card_choice" and game.cards.choices==before+1,"Disabling auto keeps applied choices and exposes pending choice")
	game._pause_run()
	game.profile = store.load_profile()
	game._restore_run()
	expect(not game.profile.settings.autoCards,"Auto preference persists off")
	fresh()
	game.cards.xp = 999999
	game.profile.settings.autoCards = true
	for index in range(30): game._handle_card_progress()
	expect(game.cards.choices==25 and Cards.epic_count(game.cards)==4 and game.status=="running","Auto stops at 25 choices")
	for speed in Store.GAME_SPEEDS:
		fresh()
		game.profile.settings.gameSpeed = speed
		game.profile.settings.autoCards = true
		game.cards.xp = 40
		game._process(0.03)
		expect(game.cards.choices==1 and game.status=="running","Auto works at speed %d" % speed)
	# Save failure keeps the same pending offer and exposes a retry in the card UI.
	fresh()
	game.cards.xp = 104
	game._handle_card_progress()
	store.profile_path = path.path_join("missing.json") # Parent is a file: deliberate write failure.
	game._on_panel_action("card:"+str(game.cards.offer[0]))
	game._on_panel_action("equip_card")
	expect(game.save_error and game.overlay.summary_label.text.contains("Save failed"),"Card overlay exposes failed save")
	var pending: Array = game.cards.offer.duplicate()
	store.profile_path = path
	game._on_panel_action("save")
	game.profile = store.load_profile()
	game._restore_run()
	expect(not game.save_error and game.cards.choices==1 and game.cards.offer==pending,"Retry persists once without reroll or duplicate selection")
	game.profile.activeRun.erase("cards")
	game._restore_run()
	expect(game.cards.choices==0 and game.cards.xp==0 and game.cards.modules==0,"Legacy active run receives no retroactive cards or loot")
	# Boss payouts, saving and permanent purchase atomicity in the existing profile transaction.
	fresh()
	game._spawn_enemy_at({"position":game.player.position+Vector2(80,0)},"void_boss")
	var boss: Dictionary = game.enemies[0]
	game._grant_enemy_rewards(boss)
	game._grant_enemy_rewards(boss)
	expect(game.cards.modules==1 and game.cards.xp==15,"Boss module and XP awarded once")
	game._save_run()
	game.profile = store.load_profile()
	game._restore_run()
	expect(game.cards.modules==1,"Unbanked module resumes")
	game._end_run()
	game._end_run()
	expect(game.profile.railgunModules==1,"Module banked only once")
	game.profile.totalCoins = 100
	game._buy_railgun()
	expect(game.profile.railgunLevel==2 and game.profile.totalCoins==0 and game.profile.railgunModules==0,"Permanent upgrade charges both currencies")
	game._buy_railgun()
	expect(game.profile.railgunLevel==2,"Insufficient upgrade rejected")
	expect(Cards.price(3).modules==1 and Cards.price(4).modules==2 and Cards.price(7).modules==3,"Module price bands")
	game.profile = store.load_profile()
	expect(game.profile.railgunLevel==2 and game.profile.railgunCoinsSpent==100,"Permanent upgrade survives load")
	game.profile.workshopSpent = 25.0
	game.profile.permanentUpgrades.damage = 1
	game.profile = store.reset_workshop(game.profile)
	expect(game.profile.railgunLevel==2 and game.profile.railgunModules==0,"Workshop reset preserves railgun")
	game.profile.totalCoins = 99999
	game.profile.railgunModules = 999
	game.start_run()
	game._buy_railgun()
	expect(game.profile.railgunLevel==2,"Permanent purchase blocked during run")
	game._end_run()
	game.profile.railgunLevel = 9
	game._buy_railgun()
	var max_wallet: float = game.profile.totalCoins
	expect(game.profile.railgunLevel==10,"Permanent Railgun reaches level ten")
	game._buy_railgun()
	expect(game.profile.railgunLevel==10 and game.profile.totalCoins==max_wallet,"Max Railgun cannot spend again")
	# Actual projectiles: multi-shot consumes one round; magazine restores upgraded size.
	fresh()
	game.cards.ranks = {"twin":2,"magazine":2,"reload":1,"core":1}
	game.profile.permanentUpgrades.crit_chance = 50
	game.cards.ranks.critical = 10 # isolated deterministic critical fixture
	game._spawn_enemy_at({"position":game.player.position+Vector2(60,0)},"void_tank")
	game.fire_timer = 0
	game._update_weapons(1)
	expect(game.bullets.size()==3 and game.player.weapon.ammo==5,"Three projectiles consume one round")
	expect(is_equal_approx(game.bullets[0].damage,8*1.5*2.1),"Projectile contains upgraded crit damage")
	game.player.weapon.ammo = 0
	game.player.weapon.reload_timer = 1.8
	game._tick_railgun_reload(1.8)
	expect(game.player.weapon.ammo==8 and game.player.weapon.reload_timer==0,"Upgraded reload restores eight rounds")
	# Ordered contacts independent of enemy array order; no repeated hit on next frame.
	fresh()
	var origin: Vector2 = game.player.position
	for distance in [90,30,60]:
		game._spawn_enemy_at({"position":origin+Vector2(distance,0)},"void_tank")
		game.enemies[-1].hp = 100.0
		game.enemies[-1].radius = 3.0
	var bullet := Weapons.build_projectile(900,origin,Vector2.RIGHT,10,false,120)
	bullet.position = origin+Vector2(110,0)
	bullet.remaining_distance = 10.0
	bullet.hits_left = 3
	bullet.hit_ids = []
	bullet.rampage = 0.15
	game.bullets.append(bullet)
	game._resolve_collisions()
	expect(is_equal_approx(game.enemies[1].hp,90) and is_equal_approx(game.enemies[2].hp,100) and is_equal_approx(game.enemies[0].hp,100),"Piercing stops at first surviving enemy")
	expect(game.bullets.is_empty(),"Piercing stops after target budget")
	fresh()
	origin = game.player.position
	game._spawn_enemy_at({"position":origin+Vector2(30,0)},"void_tank")
	game.enemies[0].hp = 100
	bullet = Weapons.build_projectile(901,origin,Vector2.RIGHT,10,false,120)
	bullet.position = origin+Vector2(50,0)
	bullet.remaining_distance = 70
	bullet.hits_left = 3
	bullet.hit_ids = []
	bullet.fragments = 2
	game.bullets.append(bullet)
	game._resolve_collisions()
	expect(game.bullets.size()==2,"First impact spawns two fragments")
	var hp_after: float = game.enemies[0].hp
	game._resolve_collisions()
	expect(game.enemies[0].hp==hp_after and game.bullets.size()==2,"Existing target ignored; fragments cannot recurse")
	for fragment in game.bullets:
		if fragment.id != 901: expect(fragment.damage==5 and fragment.fragments==0 and fragment.radius==1.6,"Fragment damage and range are bounded")
	game._save_run()
	var hits: Array = game.bullets[0].hit_ids.duplicate()
	game.profile = store.load_profile()
	game._restore_run()
	expect(game.bullets[0].hit_ids==hits,"Piercing history survives save")
	game._resolve_collisions()
	expect(game.enemies[0].hp==hp_after,"Restored projectile cannot hit the same enemy again")
	fresh()
	origin = game.player.position
	for distance in [30,60,90]:
		game._spawn_enemy_at({"position":origin+Vector2(distance,0)},"void_tank")
		game.enemies[-1].hp = 1
		game.enemies[-1].radius = 3
	bullet = Weapons.build_projectile(999,origin,Vector2.RIGHT,10,false,300)
	bullet.position = origin+Vector2(110,0)
	bullet.hits_left = 3
	game.bullets.append(bullet)
	game._resolve_collisions()
	expect(game.enemies.is_empty() and game.runState.kills==3,"Piercing continues through successive kills")
	fresh()
	origin = game.player.position
	game._spawn_enemy_at({"position":origin+Vector2(30,0)},"void_tank")
	game.enemies[0].hp = 1
	game.enemies[0].radius = 3
	for index in range(3):
		bullet = Weapons.build_projectile(1000+index,origin,Vector2.RIGHT,10,false,300)
		bullet.position = origin+Vector2(60,0)
		game.bullets.append(bullet)
	game._resolve_collisions()
	expect(game.bullets.size()==2 and game.runState.kills==1,"Other two rounds pass killed target without duplicate reward")
	fresh()
	origin = game.player.position
	for offset in [Vector2(30,0),Vector2(60,20),Vector2(80,-20)]:
		game._spawn_enemy_at({"position":origin+offset},"void_tank")
		game.enemies[-1].hp = 100
		game.enemies[-1].radius = 3
	bullet = Weapons.build_projectile(1100,origin,Vector2.RIGHT,10,false,300)
	bullet.position = origin+Vector2(40,0)
	bullet.fragments = 2
	game.bullets.append(bullet)
	game._resolve_collisions()
	expect(game.bullets.size()==2,"Shatter replaces stopped parent with two fragments")
	for index in range(2):
		var fragment: Dictionary = game.bullets[index]
		expect(fragment.velocity.normalized().is_equal_approx((game.enemies[index+1].position-fragment.position).normalized()),"Shatter aims at distinct nearest targets")
		expect(fragment.damage==5 and fragment.get("fragments")==0,"Shatter damage is half impact, no recursion")
	game.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp", ".v2.bak"]: DirAccess.remove_absolute(path+suffix)
	print("Card checks: %d passed / %d failed" % [checks-failures,failures])
	quit(0 if failures==0 else 1)
