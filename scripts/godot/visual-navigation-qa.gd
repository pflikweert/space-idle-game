extends SceneTree
const PriorQA = preload("res://../../scripts/godot/visual-gunship-qa.gd")
const OUTPUT := "/tmp/void-navigation-qa"
var game
func _initialize() -> void: call_deferred("capture")
func save_view(name: String) -> void:
	game._update_buttons()
	game.queue_redraw()
	for frame in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT.path_join(name+".png"))
	print("CAPTURE ",name)
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.content_scale_size=Vector2i(430,760)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
	game=PriorQA.Fixture.new()
	game.profile_store=PriorQA.MemoryStore.new()
	root.add_child(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.set_process(false)
	for dimensions in [Vector2i(320,568),Vector2i(390,844),Vector2i(430,932),Vector2i(844,390),Vector2i(1280,800)]:
		root.size=dimensions
		for frame in range(4):await process_frame
		for speed in [1,5,10]:
			game.profile.activeRun={}
			game.start_run()
			game.rng.seed=37
			game.profile.settings.gameSpeed=speed
			game.player.hp=1e6
			game.player.max_hp=1e6
			for index in range(44):
				var id: String="void_boss" if index>=40 else ["void_drone","red_scout","void_tank","ranged_shooter"][index%4]
				game._spawn_enemy_at({"position":game.player.position+Vector2.RIGHT.rotated(index*2.39996)*(130+index%5*20)},id)
				game.enemies[-1].hp=1e6
				game.enemies[-1].max_hp=1e6
				game.enemies[-1].fire_cooldown=float(index%10)*0.1
			var cpu := []
			var wall := []
			var max_effects := 0
			for frame in range(300):
				var start := Time.get_ticks_usec()
				game._process(1.0/60.0)
				var elapsed := (Time.get_ticks_usec()-start)/1000.0
				await process_frame
				await RenderingServer.frame_post_draw
				if frame>=60:
					cpu.append(elapsed)
					wall.append((Time.get_ticks_usec()-start)/1000.0)
				max_effects=maxi(max_effects,game.particles.size())
				if frame in [60,90,120,180,240]: await save_view("fleet-%dx%d-%dx-%d" %[dimensions.x,dimensions.y,speed,frame])
			cpu.sort()
			wall.sort()
			print("PERF ",JSON.stringify({"viewport":str(dimensions),"speed":speed,"cpu_median_ms":cpu[120],"cpu_p95_ms":cpu[228],"frame_median_ms":wall[120],"frame_p95_ms":wall[228],"effects_peak":max_effects}))
	game.queue_free()
	await process_frame
	quit()
