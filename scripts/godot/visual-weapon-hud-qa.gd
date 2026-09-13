extends SceneTree
const Prior = preload("res://../../scripts/godot/visual-compact-qa.gd")
const OUTPUT := "/tmp/void-weapon-hud-qa"
class SafeGame extends Prior.CaptureGame:
	var simulated_safe := Vector4.ZERO
	func _hud_safe_area(units: float) -> Vector4: return simulated_safe*units
var game
func _initialize() -> void: call_deferred("capture")
func shot(name: String) -> void:
	game._update_buttons()
	game.queue_redraw()
	for frame in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT.path_join(name+".png"))
	print("CAPTURE ",name)
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.content_scale_size = Vector2i(430,760)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	game = SafeGame.new()
	game.profile_store = Prior.PriorQA.MemoryStore.new()
	root.add_child(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.set_process(false)
	for dimensions in [Vector2i(320,568),Vector2i(390,844),Vector2i(430,932),Vector2i(844,390),Vector2i(1280,800)]:
		root.size = dimensions
		for frame in range(5): await process_frame
		game.profile = game.profile_store._default_profile()
		game.start_run()
		game.app_backgrounded = false
		game.runState.cash = 31300
		game.runState.coinsEarned = 14100
		game.cards.modules = 7
		game.cards.choices = 9
		game.cards.ranks.reload = 2
		for index in range(8): game._spawn_enemy_at({"position":game.player.position+Vector2.UP.rotated(index*TAU/8)*110},"void_tank")
		var suffix := "-%dx%d" % [dimensions.x,dimensions.y]
		await shot("ready"+suffix)
		for fraction in [1.0,0.75,0.5,0.25]:
			game.player.weapon.reload_timer = game._railgun_stats().reload*fraction
			game.player.weapon.ammo = 0
			await shot("reload-%d" % int(fraction*100)+suffix)
		game.player.weapon.reload_timer = 0
		game.player.weapon.ammo = 6
		await shot("ready-pulse"+suffix)
		game.profile.settings.autoCards = true
		game.wave_message_timer = 0
		game.card_notices.append("Heavy Caliber · +25% damage · +25% crit damage")
		game._update_card_notice(0.1)
		game._apply_damage_to_enemy({"position":game.player.position+Vector2(-60,-50),"hp":200.0},42,false)
		game._apply_damage_to_enemy({"position":game.player.position+Vector2(60,-50),"hp":200.0},84,true)
		await shot("auto-popup-damage"+suffix)
		game.simulated_safe = Vector4(12,24,12,20)
		game.last_layout_size = Vector2.ZERO
		await shot("safe-area"+suffix)
		game.simulated_safe = Vector4.ZERO
		game.last_layout_size = Vector2.ZERO
	game.queue_free()
	await process_frame
	quit()
