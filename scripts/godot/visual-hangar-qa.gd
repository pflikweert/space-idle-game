extends SceneTree

const PriorQA := preload("res://../../scripts/godot/visual-gunship-qa.gd")
const Equipment := preload("res://scripts/systems/equipment_registry.gd")
const OUTPUT := "/tmp/void-hangar-qa"
var game

func _initialize() -> void: call_deferred("capture")

func save_view(name: String) -> void:
	game._refresh_overlay(); game._update_buttons(); game.queue_redraw()
	for frame in range(10): await process_frame
	await RenderingServer.frame_post_draw
	var path := OUTPUT.path_join(name+".png")
	root.get_texture().get_image().save_png(path)
	print("CAPTURE ",path," slots=",game._active_ship().slots.size()," panel=",game.overlay.get_rect())

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.content_scale_size = Vector2i(430,760)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	game = PriorQA.Fixture.new(); game.profile_store = PriorQA.MemoryStore.new(); root.add_child(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); game.set_process(false)
	for dimensions in [Vector2i(320,568),Vector2i(390,844),Vector2i(430,932),Vector2i(1280,800)]:
		root.size = dimensions
		for frame in range(5): await process_frame
		game.profile = game.profile_store._default_profile(); game.metaProgress = game.profile; game.reset_world("menu")
		game.profile.unlockedEquipmentBlueprints.append(Equipment.MICRO_MISSILE_RACK_ID)
		game.profile.totalCoins = 1000; game.profile.railgunModules = 0
		game.hangar_selected_equipment = Equipment.MICRO_MISSILE_RACK_ID; game.menu_view = "blueprint_detail"
		await save_view("blueprint-detail-missile-insufficient-%dx%d" % [dimensions.x,dimensions.y])
		game.profile.totalCoins = 7500; game.profile.railgunModules = 3
		game.hangar_selected_equipment = Equipment.RAILGUN_ID
		await save_view("blueprint-detail-railgun-ready-%dx%d" % [dimensions.x,dimensions.y])
		if "--blueprints-only" in OS.get_cmdline_user_args(): continue
		game.profile = game.profile_store._default_profile(); game.metaProgress = game.profile; game.reset_world("menu"); game.menu_view = "hangar"
		game.profile.equipmentItems["railgun-002"] = {"id":"railgun-002","blueprint_id":Equipment.RAILGUN_ID,"level":1}
		game.profile.equipmentItems[Equipment.MICRO_MISSILE_RACK_INSTANCE_ID] = {"id":Equipment.MICRO_MISSILE_RACK_INSTANCE_ID,"blueprint_id":Equipment.MICRO_MISSILE_RACK_ID,"level":1}
		game.profile.equipmentItems["shield-core-qa-s2"] = {"id":"shield-core-qa-s2","blueprint_id":Equipment.SHIELD_CORE_ID,"level":1}
		game.profile.equipmentInventory.append_array(["railgun-002",Equipment.MICRO_MISSILE_RACK_INSTANCE_ID,"shield-core-qa-s2"])
		game.profile.ships.starter_ship.loadout.W2 = "railgun-002"
		game.profile.ships.starter_ship.loadout.W4 = Equipment.MICRO_MISSILE_RACK_INSTANCE_ID
		game.profile.ships.starter_ship.loadout.S2 = "shield-core-qa-s2"
		await save_view("hangar-%dx%d" % [dimensions.x,dimensions.y])
		game.menu_view = "loadout"
		await save_view("loadout-%dx%d" % [dimensions.x,dimensions.y])
		game.hangar_selected_equipment = "railgun-002"
		game.menu_view = "equipment_detail"
		await save_view("equipment-detail-railgun-%dx%d" % [dimensions.x,dimensions.y])
		game.profile.totalCoins = 5000
		game.profile.railgunModules = 5
		await save_view("equipment-detail-railgun-ready-%dx%d" % [dimensions.x,dimensions.y])
		game.menu_view = "blueprints"
		await save_view("blueprints-%dx%d" % [dimensions.x,dimensions.y])
	game.queue_free(); await process_frame; quit()
