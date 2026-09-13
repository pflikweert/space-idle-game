extends SceneTree
const Prior = preload("res://../../scripts/godot/visual-compact-qa.gd")
const Visuals = preload("res://scripts/systems/railgun_visuals.gd")
const OUTPUT := "/tmp/void-railgun-pulses-qa"
class Gallery extends Control:
	var visuals := Visuals.new()
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO,size),Color("#07121e"))
		var font := ThemeDB.fallback_font
		var kinds := ["pulse","fragment","muzzle","impact","fragment_impact"]
		for row in range(kinds.size()):
			draw_string(font,Vector2(16,34+row*90),str(kinds[row]),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#b9d4e2"))
			for frame in range(4):
				var texture := visuals.texture(kinds[row],frame/4.0)
				draw_texture_rect(texture,Rect2(190+frame*145,14+row*90,128,64),false)
func _initialize() -> void: call_deferred("capture")
func save_view(name: String) -> void:
	for frame in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT.path_join(name+".png"))
	print("CAPTURE ",name)
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.size = Vector2i(800,470)
	root.content_scale_size = root.size
	var gallery := Gallery.new()
	root.add_child(gallery)
	gallery.size = Vector2(800,470)
	await save_view("frames")
	gallery.queue_free()
	await process_frame
	root.content_scale_size = Vector2i(430,760)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	var game := Prior.CaptureGame.new()
	game.profile_store = Prior.PriorQA.MemoryStore.new()
	root.add_child(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.set_process(false)
	for dimensions in [Vector2i(390,844),Vector2i(1280,800)]:
		root.size = dimensions
		for frame in range(5): await process_frame
		for speed in [1,2,3,4,5,10]:
			game.profile = game.profile_store._default_profile()
			game.profile.permanentUpgrades.fire_rate = 38
			game.profile.permanentUpgrades.range = 100
			game.profile.settings.gameSpeed = speed
			game.start_run()
			game.app_backgrounded = false
			game.cards.choices = 25
			game.cards.ranks = {"twin":2,"shatter":2,"magazine":12}
			for index in range(8):
				game._spawn_enemy_at({"position":game.player.position+Vector2.UP.rotated(index*TAU/8)*160},"void_tank")
				game.enemies[-1].hp = 999999
			for frame in range(45): game._process(1.0/60)
			game.queue_redraw()
			await save_view("salvo-%dx-%dx%d" % [speed,dimensions.x,dimensions.y])
	game.queue_free()
	await process_frame
	quit()
