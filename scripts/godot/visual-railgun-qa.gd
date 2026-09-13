extends SceneTree

const Scene = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/profile_store.gd")
const Enemies = preload("res://scripts/systems/enemy_registry.gd")
const OUTPUT := "/tmp/void-railgun-qa"

class MemoryStore extends Store:
	func load_profile() -> Dictionary:
		return _default_profile()
	func save_profile(_profile: Dictionary) -> bool:
		return true

class Gallery extends Control:
	var entries: Array = []
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#06101c"))
		var font := ThemeDB.fallback_font
		for index in range(entries.size()):
			var entry: Dictionary = entries[index]
			var origin := Vector2(20 + (index % 5) * 250, 20 + (index / 5) * 215)
			draw_string(font, origin + Vector2(0, 16), entry.label, HORIZONTAL_ALIGNMENT_LEFT, 242, 13, Color.WHITE)
			var tex: Texture2D = entry.texture
			for height in [150.0, float(entry.height)]:
				var center := origin + Vector2(70 if height == 150.0 else 190, 110)
				var dimensions: Vector2 = tex.get_size() * height / tex.get_height()
				draw_set_transform(center, PI if entry.player else 0.0)
				draw_texture_rect(tex, Rect2(-dimensions / 2.0, dimensions), false)
				draw_set_transform(Vector2.ZERO)
			draw_string(font, origin + Vector2(4, 203), "150px canvas / gameplay scale", HORIZONTAL_ALIGNMENT_LEFT, 240, 12, Color("#93a8bc"))

func _initialize() -> void:
	call_deferred("capture")

func save_view(name: String) -> void:
	for frame in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT.path_join(name + ".png"))
	print("CAPTURE ", name)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.size = Vector2i(1280, 900)
	root.content_scale_size = Vector2i(1280, 900)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	var gallery := Gallery.new()
	root.add_child(gallery)
	gallery.size = Vector2(1280, 900)
	var entries := []
	var heights := {}
	var folders := ["res://assets/player_ship", "res://assets/vfx", "res://assets/vfx/railgun", "res://assets/enemies/shared_vfx"]
	for id in Enemies.get_definitions():
		var definition: Dictionary = Enemies.get_definition(id)
		var folder := "res://assets/enemies/" + str(definition.asset_key)
		folders.append(folder)
		heights[folder] = float(definition.visual_canvas_height) * 0.48
	var visited := {}
	for folder in folders:
		if visited.has(folder): continue
		visited[folder] = true
		for file in DirAccess.get_files_at(folder):
			if not file.ends_with(".png"): continue
			var img := Image.load_from_file(folder.path_join(file))
			img.convert(Image.FORMAT_RGBA8)
			var bounds := img.get_used_rect()
			var touches_edge := bounds.position.x == 0 or bounds.position.y == 0 or bounds.end.x == img.get_width() or bounds.end.y == img.get_height()
			print("ASSET ", folder.get_file(), "/", file, " canvas=", img.get_size(), " alpha_bounds=", bounds, " touches_edge=", touches_edge)
			entries.append({"label": folder.get_file() + "/" + file, "texture": ImageTexture.create_from_image(img), "height": 98.0 if folder.contains("player_ship") else float(heights.get(folder, 70.0)), "player": folder.contains("player_ship")})
	for page in range(ceili(entries.size() / 20.0)):
		gallery.entries = entries.slice(page * 20, (page + 1) * 20)
		gallery.queue_redraw()
		await save_view("sprites-%02d" % page)
	gallery.queue_free()
	await process_frame
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
		game.profile.settings.gameSpeed = 5
		var bounds: Rect2 = game._get_playfield_rect(game.get_viewport_rect().size)
		game.player.position = bounds.get_center()
		game.player_target = game.player.position
		game._spawn_enemy_at({"position": game.player.position + Vector2(-45, -90)}, "void_boss")
		game._spawn_enemy_at({"position": game.player.position + Vector2(70, -30)}, "ranged_shooter")
		game._spawn_enemy_at({"position": game.player.position + Vector2(-75, 40)}, "void_tank")
		game._spawn_enemy_at({"position": game.player.position + Vector2(80, 65)}, "red_scout")
		game._spawn_enemy_at({"position": game.player.position + Vector2(-50, 75)}, "void_drone")
		game.runState.wave = 10
		game.wave_message = "BOSS INBOUND"
		game.wave_message_timer = 1.0
		game._fire_at_nearest_enemy()
		game._update_projectiles(0.03)
		game._resolve_collisions()
		game._update_buttons()
		game.queue_redraw()
		await save_view("combat-%dx%d" % [dimensions.x, dimensions.y])
		for hit in range(4):
			game._update_damage_feedback(0.2)
			game._apply_damage_to_player(3.0, "IMPACT")
		game.queue_redraw()
		await save_view("damage-feedback-%dx%d" % [dimensions.x, dimensions.y])
		var boss: Dictionary = game.enemies[0]
		boss.hp = boss.max_hp * 0.2
		game.wave_message_timer = 0
		for index in range(4):
			game._update_visual_effects(0.08)
			game.queue_redraw()
			await save_view("boss-damaged-%dx%d-%02d" % [dimensions.x, dimensions.y, index])
		game._add_enemy_death_explosion(boss, Color.ORANGE)
		game.enemies.erase(boss)
		for index in range(10):
			game.queue_redraw()
			await save_view("boss-death-%dx%d-%02d" % [dimensions.x, dimensions.y, index])
			game._update_visual_effects(0.1)
	game.queue_free()
	await process_frame
	quit()
