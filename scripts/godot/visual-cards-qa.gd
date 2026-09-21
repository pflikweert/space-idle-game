extends SceneTree
const PriorQA = preload("res://../../scripts/godot/visual-gunship-qa.gd")
const Cards = preload("res://scripts/systems/railgun_cards.gd")
const OUTPUT := "/tmp/void-cards-qa"
var game
func _initialize() -> void: call_deferred("capture")
func save_view(name: String) -> void:
	game._update_buttons()
	game.queue_redraw()
	for frame in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT.path_join(name+".png"))
	print("CAPTURE ",name," panel=",game.overlay.get_rect()," scroll=",game.overlay.scroll.size)
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
		for frame in range(5): await process_frame
		game.profile = game.profile_store._default_profile()
		game.reset_world("menu")
		game._refresh_overlay()
		var suffix := "-%dx%d" % [dimensions.x,dimensions.y]
		await save_view("main"+suffix)
		game._on_panel_action("railgun")
		await save_view("workshop"+suffix)
		game.profile.totalCoins = 1000
		game.profile.railgunModules = 3
		game._refresh_overlay()
		await save_view("affordable"+suffix)
		game._on_panel_action("railgun_buy")
		await save_view("purchased"+suffix)
		game._on_panel_action("railgun_catalog")
		await save_view("catalogue"+suffix)
		game.overlay.scroll.scroll_vertical = 1200
		await save_view("locked"+suffix)
		game._on_panel_action("card_info:shatter")
		await save_view("detail"+suffix)
		game.start_run()
		var center: Vector2 = game.player.position
		for index in range(12): game._spawn_enemy_at({"position":center+Vector2.UP.rotated(index*2.4)*90}, "void_tank" if index%3==0 else "red_scout")
		game.cards.xp = 6
		await save_view("gameplay"+suffix)
		game.cards.xp = 10
		game._handle_card_progress()
		await save_view("choice"+suffix)
		game.cards = Cards.fresh(27)
		game.cards.choices = 3
		game.cards.xp = Cards.threshold(game.cards)
		Cards.ensure_offer(game.cards,1)
		game.status = "card_choice"
		game._refresh_overlay()
		await save_view("epic"+suffix)
		game._railgun_instance().level = 10
		game.cards.choices = 24
		game.cards.xp = Cards.threshold(game.cards)
		game.cards.offer = ["core","shatter","rampage"]
		game._refresh_overlay()
		await save_view("late-epic"+suffix)
		print("CHOICE FIT ",suffix," ",game.overlay.rows.size.y <= game.overlay.scroll.size.y)
		game._on_panel_action("auto_cards")
		await save_view("auto"+suffix)
		game._pause_run()
		await save_view("pause"+suffix)
		game._on_panel_action("build")
		await save_view("build"+suffix)
		game.cards.modules = 1
		game._end_run()
		await save_view("result"+suffix)
	game.queue_free()
	await process_frame
	quit()
