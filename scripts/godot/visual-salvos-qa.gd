extends SceneTree
const PriorQA = preload("res://../../scripts/godot/visual-gunship-qa.gd")
const OUTPUT := "/tmp/void-salvos-qa"
var game
func _initialize() -> void: call_deferred("capture")
func save_view(name: String) -> void:
	game._update_buttons()
	game.queue_redraw()
	for frame in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT.path_join(name + ".png"))
	print("CAPTURE ",name)
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.content_scale_size = Vector2i(430,760)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	game = PriorQA.Fixture.new()
	game.profile_store = PriorQA.MemoryStore.new()
	root.add_child(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.set_process(false)
	for dimensions in [Vector2i(320,568),Vector2i(390,844),Vector2i(430,932),Vector2i(844,390),Vector2i(1280,800)]:
		root.size = dimensions
		for frame in range(4): await process_frame
		game.profile.activeRun = {}
		game.start_run()
		var center: Vector2 = game._get_playfield_rect(game.get_viewport_rect().size).get_center()
		game.player.position = center
		game.player_target = center
		await save_view("quiet-%dx%d" % [dimensions.x,dimensions.y])
		game._spawn_enemy_at({"position":center+Vector2(-75,-45)},"void_boss")
		game._spawn_enemy_at({"position":center+Vector2(80,-40)},"ranged_shooter")
		game._update_visual_effects(0.2)
		for index in range(8):
			game.particles.clear()
			game.enemy_projectiles.clear()
			for enemy in game.enemies:
				enemy.visual_rotation = index * TAU / 8
				enemy.attack_direction = (center-game.EnemyWeapons.pivot(game,enemy)).normalized()
				enemy.attack_warmup_timer = 0.12
				enemy.attack_visual_timer = 0.0
				enemy.reload_timer = 0.0
				enemy.ammo = 1
			game.player.weapon = {"ammo":2,"reload_timer":0.0}
			await save_view("warning-%dx%d-%d" % [dimensions.x,dimensions.y,index])
			for enemy in game.enemies:
				game._fire_enemy_projectile(enemy)
				enemy.attack_warmup_timer = 0.0
			game._update_projectiles(0.033)
			game._resolve_collisions()
			await save_view("shot-%dx%d-%d" % [dimensions.x,dimensions.y,index])
			game._update_visual_effects(0.08)
			game._update_projectiles(0.033)
			game._resolve_collisions()
			game.player.weapon = {"ammo":0,"reload_timer":1.3}
			for enemy in game.enemies: enemy.reload_timer = 2.0
			await save_view("reload-%dx%d-%d" % [dimensions.x,dimensions.y,index])
		game.profile.activeRun = {}
		game.start_run()
		game.player.hp = 1e9
		game.player.max_hp = 1e9
		for index in range(44):
			game._spawn_enemy_at({"position":game.player.position+Vector2.UP.rotated(index*2.4)*(45+index%6*10)},"void_boss" if index>=40 else ("ranged_shooter" if index%3==0 else "void_tank"))
			game.enemies[-1].hp = 1e9
		for speed in [1,5,10]:
			game.profile.settings.gameSpeed = speed
			for frame in range(180):
				game._process(1.0/60.0)
				if frame in [120,125,130]: await save_view("combat-%dx%d-%dx-%d" % [dimensions.x,dimensions.y,speed,frame])
	game.queue_free()
	await process_frame
	quit()
