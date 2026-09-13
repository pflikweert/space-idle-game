extends SceneTree
const Game = preload("res://scripts/void_drifter_game.gd")
const Store = preload("res://scripts/profile_store.gd")
const OUTPUT := "/tmp/void-gunship-qa"
class MemoryStore extends Store:
	func load_profile() -> Dictionary: return _default_profile()
	func save_profile(_profile: Dictionary) -> bool: return true
class Fixture extends Game:
	func _notification(what: int) -> void:
		# QA window focus changes must not alter the deliberately isolated fixture.
		if what == NOTIFICATION_RESIZED: super._notification(what)
var game
func _initialize() -> void: call_deferred("capture")
func save_view(name: String) -> void:
	game._update_buttons()
	game.queue_redraw()
	for frame in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT.path_join(name + ".png"))
	print("CAPTURE ", name)
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.content_scale_size = Vector2i(430,760)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	game = Fixture.new()
	game.profile_store = MemoryStore.new()
	root.add_child(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.set_process(false)
	for dimensions in [Vector2i(320,568),Vector2i(390,844),Vector2i(430,932),Vector2i(844,390),Vector2i(1280,800)]:
		root.size = dimensions
		for frame in range(4): await process_frame
		game.profile.activeRun = {}
		game.start_run()
		game.player.position = game._get_playfield_rect(game.get_viewport_rect().size).get_center()
		game.player_target = game.player.position
		game.profile.settings.gameSpeed = 10
		for index in range(8):
			game.rail_direction = Vector2.UP.rotated(index * TAU/8)
			game._update_visual_effects(0.1)
			game._add_muzzle_flash(game.player.position + game.rail_direction * game.player.radius, game.rail_direction, false)
			await save_view("aim-%dx%d-%d" % [dimensions.x,dimensions.y,index])
		game._apply_damage_to_player(8,"HIT",game.player.position + Vector2(-10,0), Vector2.RIGHT)
		game._update_visual_effects(0.1)
		await save_view("shield-hit-%dx%d" % [dimensions.x,dimensions.y])
		game._apply_damage_to_player(80,"IMPACT",game.player.position + Vector2(10,0), Vector2.LEFT)
		game._update_visual_effects(0.1)
		await save_view("hull-hit-%dx%d" % [dimensions.x,dimensions.y])
		game.player.hp = 25
		game._update_visual_effects(0.1)
		game.pointer_down = true
		game.player_velocity_x = 470
		for index in range(3):
			game._update_visual_effects(0.1)
			await save_view("critical-%dx%d-%d" % [dimensions.x,dimensions.y,index])
		game._pause_run()
		game.menu_view = "shop"
		game.shop_category = "Defense"
		game._refresh_overlay()
		for frame in range(5): await process_frame
		game.overlay.scroll.scroll_vertical = 180
		await save_view("shield-shop-%dx%d" % [dimensions.x,dimensions.y])
		game._on_panel_action("resume")
		game.player.hp = 0
		game._end_run(true)
		for index in range(8):
			await save_view("death-%dx%d-%d" % [dimensions.x,dimensions.y,index])
			game._process(0.1)
		await save_view("result-%dx%d" % [dimensions.x,dimensions.y])
	if "--captures-only" in OS.get_cmdline_user_args():
		game.queue_free()
		await process_frame
		quit()
		return
	# CPU/update and native render wall-time samples; deliberately saturated encounter.
	root.size = Vector2i(390,844)
	for frame in range(4): await process_frame
	for speed in [1,5,10]:
		game.profile.activeRun = {}
		game.start_run()
		game.profile.settings.gameSpeed = speed
		game.player.hp = 1e9
		game.player.max_hp = 1e9
		for index in range(44):
			game._spawn_enemy_at({"position": game.player.position + Vector2.UP.rotated(index * 2.4) * (45 + index % 6 * 10)}, "void_boss" if index >= 40 else ("ranged_shooter" if index % 3 == 0 else "void_tank"))
			game.enemies[-1].hp = 1e9
			game.enemies[-1].max_hp = 1e9
		var cpu := []
		var wall := []
		var effect_peak := 0
		for index in range(210):
			var start := Time.get_ticks_usec()
			game._process(1.0/60.0)
			var update_ms := (Time.get_ticks_usec()-start)/1000.0
			await process_frame
			await RenderingServer.frame_post_draw
			if index >= 30:
				cpu.append(update_ms)
				wall.append((Time.get_ticks_usec()-start)/1000.0)
			effect_peak = maxi(effect_peak,game.particles.size())
		cpu.sort()
		wall.sort()
		print("PERF ", JSON.stringify({"speed":speed,"enemies":game.enemies.size(),"effects_peak":effect_peak,"update_ms_median":cpu[90],"update_ms_p95":cpu[171],"native_frame_ms_median":wall[90],"native_frame_ms_p95":wall[171]}))
	game.queue_free()
	await process_frame
	quit()
