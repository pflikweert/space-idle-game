extends SceneTree
const Scene = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/profile_store.gd")
const Enemies = preload("res://scripts/systems/enemy_registry.gd")
const OUTPUT := "/tmp/void-orbit-qa"
class MemoryStore extends Store:
	func load_profile() -> Dictionary: return _default_profile()
	func save_profile(_profile: Dictionary) -> bool: return true
func _initialize() -> void: call_deferred("capture")
func save_view(name: String) -> void:
	for frame in range(3): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT.path_join(name + ".png"))
	print("CAPTURE ", name)
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.content_scale_size = Vector2i(430, 760)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	var game = Scene.instantiate()
	game.profile_store = MemoryStore.new()
	root.add_child(game)
	game.set_process(false)
	for dimensions in [Vector2i(320, 568), Vector2i(390, 844), Vector2i(430, 932), Vector2i(844, 390), Vector2i(1280, 800)]:
		root.size = dimensions
		for frame in range(4): await process_frame
		game.profile.activeRun = {}
		game.start_run()
		game.rng.seed = 37
		game.profile.settings.gameSpeed = 1
		var bounds: Rect2 = game._get_playfield_rect(game.get_viewport_rect().size)
		game.player.position = bounds.get_center()
		game.player_target = game.player.position
		var roles := ["void_drone", "red_scout", "void_tank", "ranged_shooter"]
		for index in range(12):
			game._spawn_enemy_at({"position": game.player.position + Vector2.RIGHT.rotated(index * TAU / 12) * (130 + index % 3 * 15)}, roles[index % 4])
		game._spawn_enemy_at({"position": game.player.position + Vector2(0, -210)}, "void_boss")
		# Isolated flight scene: no damage/fire, so all headings and scales remain inspectable.
		for shot in range(10):
			for tick in range(12):
				game._update_enemy_movement(1.0 / 60.0)
				game._separate_enemies()
				game._update_visual_effects(1.0 / 60.0)
			game.status = "running"
			game.runState.status = "running"
			game.overlay.hide()
			game._update_buttons()
			game.queue_redraw()
			await save_view("flight-%dx%d-%02d" % [dimensions.x, dimensions.y, shot])
		game.profile.settings.gameSpeed = 5
		for shot in range(5):
			for tick in range(12):
				game._update_enemy_movement(5.0 / 60.0)
				game._separate_enemies()
				game._update_visual_effects(1.0 / 60.0)
			game.status = "running"
			game.runState.status = "running"
			game.overlay.hide()
			game._update_buttons()
			game.queue_redraw()
			await save_view("flight-5x-%dx%d-%02d" % [dimensions.x, dimensions.y, shot])
		game.status = "paused"
		game.menu_view = "codex"
		game._refresh_overlay()
		game._update_buttons()
		await save_view("codex-%dx%d" % [dimensions.x, dimensions.y])
	game.queue_free()
	await process_frame
	quit()
