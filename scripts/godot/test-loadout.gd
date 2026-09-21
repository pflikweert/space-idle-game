extends SceneTree

const Store := preload("res://scripts/profile_store.gd")
const Ships := preload("res://scripts/systems/ship_registry.gd")
const Equipment := preload("res://scripts/systems/equipment_registry.gd")
const Loadouts := preload("res://scripts/systems/loadout_system.gd")
const Game := preload("res://scripts/void_drifter_game.gd")

var checks := 0
var failures := 0

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: "+message)

func _initialize() -> void: call_deferred("run_tests")

func run_tests() -> void:
	root.size = Vector2i(390,844)
	var ship := Ships.definition(Ships.STARTER_SHIP_ID)
	expect(ship.slots.size()==6 and ship.slots.filter(func(slot): return slot.type=="weapon").size()==4,"Starter hardpoints come from blueprint")
	expect(ship.slots.all(func(slot): return slot.position is Vector2 and slot.accepts is Array),"Every hardpoint has normalized anchor and compatibility")
	expect(ship.slots.all(func(slot): return slot.get("mount_size",Vector2.ZERO).x > 0.0 and slot.get("mount_size",Vector2.ZERO).y > 0.0),"Every hardpoint defines physical mount geometry")
	expect(ship.get("presentation",{}).get("source_canvas",Vector2.ZERO) == Vector2(1024,1536) and float(ship.get("presentation",{}).get("shield_height_multiplier",0.0)) > 1.0,"Ship presentation defines a fixed combat canvas and shield fit")
	expect(str(ship.art.hangar).contains("round_systems"),"Hangar and combat use the gunship with two circular system bays")
	var s1: Dictionary = ship.slots.filter(func(slot): return str(slot.id)=="S1")[0]
	var s2: Dictionary = ship.slots.filter(func(slot): return str(slot.id)=="S2")[0]
	var system_pixels := Vector2(s1.mount_size) * Vector2(ship.presentation.source_canvas)
	expect(s1.mount_size == s2.mount_size and absf(system_pixels.x-system_pixels.y) < 1.0 and float(s1.position.y) < 0.46,"S1 and S2 use equal circular geometry and S1 is centered on its visible bay")
	expect(Ships.MAX_ACTIVE_WEAPON_FAMILIES==5 and int(ship.max_active_weapon_families)<=5,"Global family ceiling and ship cap are explicit")
	for blueprint_id in [Equipment.RAILGUN_ID,Equipment.MICRO_MISSILE_RACK_ID,Equipment.SHIELD_CORE_ID]:
		expect(not str(Equipment.definition(blueprint_id).get("mount_art","")).is_empty(),"Equipped %s has a ship mount asset" % blueprint_id)
	var starter_mount := Equipment.definition(Equipment.RAILGUN_ID)
	var missile_mount := Equipment.definition(Equipment.MICRO_MISSILE_RACK_ID)
	expect(int(starter_mount.max_active_copies)==4 and int(missile_mount.max_active_copies)==4,"Railgun and Missile blueprints can fill the weapon hardpoints")
	expect(str(starter_mount.mount_art).contains("weapon_socket_cover") and bool(starter_mount.rotates_to_target),"Railgun uses the full socket-cover plate and rotating turret layer")
	expect(str(missile_mount.mount_art) == str(starter_mount.mount_art) and not str(missile_mount.overlay_art).is_empty() and float(missile_mount.overlay_scale) > 1.0,"Missile Rack combines the full socket cover with a cradle-filling payload")
	var store := Store.new(); var path := OS.get_cache_dir().path_join("void-loadout-%d.json" % Time.get_ticks_usec()); store.profile_path = path
	store._write_json(path,{"saveVersion":5,"totalCoins":999})
	var profile := store.load_profile()
	expect(profile.saveVersion==Store.SAVE_VERSION and profile.totalCoins==0 and profile.activeShipId=="starter_ship","Mismatched local save resets cleanly")
	expect(profile.equipmentItems.size()==2 and profile.equipmentInventory.size()==2,"Starter equipment is stored as two instances")
	expect(profile.ships.starter_ship.loadout.W1==Equipment.RAILGUN_INSTANCE_ID and profile.ships.starter_ship.loadout.S1==Equipment.SHIELD_CORE_INSTANCE_ID,"Starter instances occupy blueprint-compatible slots")
	expect(Loadouts.reserve_items(profile).is_empty(),"Installed starter equipment is not duplicated in reserve")
	var duplicate: Dictionary = profile.ships.starter_ship.loadout.duplicate(true); duplicate.W2 = Equipment.RAILGUN_INSTANCE_ID
	var duplicate_result := Loadouts.validate("starter_ship",duplicate,profile.equipmentItems)
	expect(not duplicate_result.valid and duplicate_result.loadout.W2=="","One instance cannot occupy two hardpoints")
	var wrong: Dictionary = profile.ships.starter_ship.loadout.duplicate(true); wrong.W2 = Equipment.SHIELD_CORE_INSTANCE_ID; wrong.S1 = ""
	var wrong_result := Loadouts.validate("starter_ship",wrong,profile.equipmentItems)
	expect(not wrong_result.valid and wrong_result.loadout.W2=="","System equipment is rejected by weapon hardpoint")
	profile.totalCoins = 42; store.save_profile(profile); profile.totalCoins = 84; store.save_profile(profile)
	var broken := FileAccess.open(path,FileAccess.WRITE); broken.store_string("{"); broken.close()
	var recovered := store.load_profile()
	expect(recovered.totalCoins==42,"Only a same-version backup recovers a broken primary")
	var game := Game.new(); game.profile_store = store; root.add_child(game); game.set_process(false)
	game.profile = store._default_profile(); game.metaProgress = game.profile; game.reset_world("menu")
	var w1: Dictionary = ship.slots.filter(func(slot): return str(slot.id)=="W1")[0]
	var expected_mount: Vector2 = game.player.position + game.gunship.local_anchor_offset(w1.position)
	var runtime_mount: Vector2 = game._weapon_mount_position({"anchor":w1.position})
	expect(runtime_mount.is_equal_approx(expected_mount) and not game._weapon_origin({"anchor":w1.position},Vector2.UP).is_equal_approx(runtime_mount),"Weapon mounts use the registry anchor and muzzle offset without a W1 special case")
	expect(game._railgun_level()==1 and is_equal_approx(game._railgun_stats().damage,8.0),"Railgun combat damage and level stay unchanged")
	expect(is_equal_approx(game._get_player_max_hp(),140.0) and is_equal_approx(game._player_move_speed(),470.0),"Starter hull and movement stat parity")
	expect(is_equal_approx(game._stat("shield_capacity"),30.0) and is_equal_approx(game._stat("shield_recharge"),0.5),"Installed Shield Core provides existing shield stats")
	game.gunship.hit({"hull":0.0,"shield":1.0,"broken":false},game.player.position,game.player.position + Vector2.UP,Vector2.DOWN,"CONTACT")
	game.gunship.update(game,0.01)
	expect(game.gunship.shield_flash > 0.0,"Shield Core receives a visual response from an existing shield impact")
	game.gunship.reset()
	game.player_motion_speed = 0.0; game.gunship.update(game,0.05)
	var idle_throttle := game.gunship.throttle
	game.player_motion_speed = game._player_move_speed(); game.gunship.update(game,0.20)
	expect(game.gunship.throttle > idle_throttle,"Thruster throttle reacts to movement without changing ship speed")
	game.profile.ships.starter_ship.loadout.S1 = ""; game.metaProgress = game.profile
	expect(game._stat("shield_capacity")==0.0 and game._stat("shield_recharge")==0.0,"Empty system hardpoint removes shield capacity and recharge")
	game.profile = store._default_profile(); game.metaProgress = game.profile; game.start_run(); game._save_run()
	var snapshot: Dictionary = Store.decode(game.profile.activeRun)
	expect(snapshot.version==3 and snapshot.active_ship_id=="starter_ship" and snapshot.combat_loadout.W1==Equipment.RAILGUN_INSTANCE_ID and snapshot.weapon_runtime.size()==1,"Active run persists ship, loadout and Railgun runtime")
	game.menu_view = "hangar"; game.status = "paused"; game._refresh_overlay()
	var hangar = game.overlay.rows.get_node_or_null("HangarShipOverview")
	expect(hangar != null and hangar.mounted_art.size()==2 and hangar.slot_markers.size()==6,"Hangar overview renders mounted equipment and all six physical slot markers")
	hangar._layout()
	var w1_mount: Dictionary = hangar.mounted_art.filter(func(mounted): return str(mounted.hardpoint.id)=="W1")[0]
	expect(is_instance_valid(w1_mount.overlay) and w1_mount.node.size.is_equal_approx(Vector2(w1_mount.hardpoint.mount_size)*hangar.ship_rect.size),"Hangar railgun has a full socket cover beneath its separate turret head")
	var fixture_core_id := "shield-core-fixture-s2"
	game.profile.equipmentItems[fixture_core_id] = {"id":fixture_core_id,"blueprint_id":Equipment.SHIELD_CORE_ID,"level":1}
	game.profile.equipmentInventory.append(fixture_core_id)
	game.profile.ships.starter_ship.loadout.S2 = fixture_core_id
	game._refresh_overlay()
	hangar = game.overlay.rows.get_node_or_null("HangarShipOverview")
	hangar._layout()
	var s2_mount: Dictionary = hangar.mounted_art.filter(func(mounted): return str(mounted.hardpoint.id)=="S2")[0]
	var expected_s2_extent: Vector2 = Vector2(s2_mount.hardpoint.mount_size) * hangar.ship_rect.size * float(s2_mount.equipment.get("mount_scale",1.0))
	var expected_s2_center: Vector2 = hangar.ship_rect.position + Vector2(s2_mount.hardpoint.position) * hangar.ship_rect.size
	expect(hangar.mounted_art.size()==3 and s2_mount.node.size.is_equal_approx(expected_s2_extent) and (s2_mount.node.position+s2_mount.node.size/2.0).is_equal_approx(expected_s2_center),"Fixture system fills and centers on the circular S2 bay with shared geometry")
	game.profile.ships.starter_ship.loadout.S2 = ""
	game.profile.equipmentItems.erase(fixture_core_id)
	game.profile.equipmentInventory.erase(fixture_core_id)
	game._refresh_overlay()
	game.profile.permanentUpgrades.max_hp = 3
	game.profile.equipmentItems[Equipment.SHIELD_CORE_INSTANCE_ID].level = 4
	game.profile.permanentUpgrades.damage = 3
	game.profile.permanentUpgrades.armor = 3
	game.metaProgress = game.profile
	game.menu_view = "hangar"
	game._refresh_overlay()
	var stat_console = game.overlay.rows.get_node_or_null("HangarStatConsole")
	expect(stat_console != null and stat_console.get_child_count() == 4,"Hangar uses one four-row stat console")
	expect(is_equal_approx(game.overlay._hangar_stat_value(game,"max_hp"),165.2) and is_equal_approx(game.overlay._hangar_stat_value(game,"shield_capacity"),37.5),"Hangar hull uses chassis base times Workshop while shield uses Shield Core progression")
	var hangar_damage: float = game.overlay._hangar_stat_value(game,"damage")
	var hangar_armor: float = game.overlay._hangar_stat_value(game,"armor")
	expect(is_equal_approx(hangar_damage,9.44) and is_equal_approx(hangar_armor,0.075),"Hangar damage and armor use permanent Workshop values (%.3f / %.3f)" % [hangar_damage,hangar_armor])
	var hull_bar = stat_console.get_child(0).get_child(0).get_child(2)
	var armor_bar = stat_console.get_child(3).get_child(0).get_child(2)
	expect(is_equal_approx(hull_bar.progress, 3.0 / 100.0) and is_equal_approx(armor_bar.progress, 3.0 / 30.0),"Hangar bars use permanent level divided by Workshop cap")
	game.profile.ships.starter_ship.loadout.S1 = ""
	expect(is_equal_approx(game.overlay._hangar_stat_value(game,"shield_capacity"),0.0),"Hangar shield reads zero without an equipped Shield Core")
	game.profile.ships.starter_ship.loadout.S1 = Equipment.SHIELD_CORE_INSTANCE_ID
	game.status = "menu"; game.profile.activeRun = {}; game.menu_view = "main"
	game._on_panel_action("hangar")
	expect(game.menu_view == "hangar","Main menu opens the central Hangar overview")
	game._on_panel_action("manage_loadout")
	expect(game.menu_view == "loadout","Hangar overview opens the separate Loadout grid")
	game._on_panel_action("hangar_slot:W2")
	expect(game.menu_view == "equipment_picker" and game.hangar_selected_slot == "W2","Empty weapon slot opens its compatible reserve picker")
	game.profile.totalCoins = 0; game.profile.railgunModules = 0
	game._on_panel_action("blueprint_detail:" + Equipment.RAILGUN_ID)
	var railgun_detail_text := ""
	for label in game.overlay.find_children("*","RichTextLabel",true,false): railgun_detail_text += str(label.text) + "\n"
	for label in game.overlay.find_children("*","Label",true,false): railgun_detail_text += str(label.text) + "\n"
	var railgun_build_buttons := game.overlay.find_children("*","Button",true,false).filter(func(control): return str(control.text) == "BUILD ANOTHER")
	expect(railgun_detail_text.contains("5,000") and railgun_detail_text.contains("2") and railgun_detail_text.contains("MISSING") and railgun_build_buttons.size()==1 and railgun_build_buttons[0].disabled,"Railgun blueprint shows copy build costs")
	game.profile.totalCoins = 5000; game.profile.railgunModules = 2
	game._on_panel_action("build_equipment:" + Equipment.RAILGUN_ID)
	expect(game.profile.equipmentItems.has("railgun-002") and Loadouts.reserve_items(game.profile).has("railgun-002") and game.hangar_selected_equipment == Equipment.RAILGUN_ID,"Railgun blueprint build creates a reserve copy")
	var build_buttons_after_success := game.overlay.find_children("*","Button",true,false).filter(func(control): return str(control.text) == "BUILD ANOTHER")
	var railgun_after_text := ""
	for label in game.overlay.find_children("*","RichTextLabel",true,false): railgun_after_text += str(label.text) + "\n"
	for label in game.overlay.find_children("*","Label",true,false): railgun_after_text += str(label.text) + "\n"
	expect(build_buttons_after_success.size()==1 and railgun_after_text.contains("OWNED 2") and not railgun_after_text.contains("NEXT LEVEL"),"Railgun blueprint offers another copy")
	game.profile.totalCoins = 5000; game.profile.railgunModules = 2
	game._on_panel_action("build_equipment:" + Equipment.RAILGUN_ID)
	var second_railgun_id := "railgun-003"
	expect(game.profile.equipmentItems.has(second_railgun_id) and Loadouts.reserve_items(game.profile).has(second_railgun_id) and str(game.overlay.summary_label.text).contains("OWNED x3"),"Second Railgun build creates the next numbered instance")
	game.hangar_selected_slot = "W2"
	game._on_panel_action("equip_reserve:railgun-002")
	expect(game.menu_view == "loadout" and game.profile.ships.starter_ship.loadout.W2 == "railgun-002","Reserve picker equips a Railgun copy")
	game.hangar_selected_slot = "W3"
	game._on_panel_action("equip_reserve:" + second_railgun_id)
	expect(game.profile.ships.starter_ship.loadout.W3 == second_railgun_id,"A second built Railgun can be equipped to another hardpoint")
	game._on_panel_action("hangar_slot:W2")
	expect(game.menu_view == "loadout" and game.hangar_selected_equipment == "railgun-002","Filled slot opens its in-context Loadout detail panel")
	var compact_detail_buttons := game.overlay.find_children("*","Button",true,false).filter(func(control): return str(control.text) == "DETAILS")
	expect(compact_detail_buttons.size()==1,"Compact Loadout panel offers Details instead of a direct upgrade action")
	game._on_panel_action("equipment_details:railgun-002")
	expect(game.menu_view == "equipment_detail" and game.hangar_selected_equipment == "railgun-002","Details opens the selected Railgun copy's progression screen")
	var detail_labels := ""
	for label in game.overlay.find_children("*","Label",true,false): detail_labels += str(label.text) + "\n"
	var disabled_upgrade_buttons := game.overlay.find_children("*","Button",true,false).filter(func(control): return str(control.tooltip_text).contains("UPGRADE") and control.disabled)
	expect(detail_labels.contains("LV.1 / 40") and detail_labels.contains("800") and detail_labels.contains("2") and disabled_upgrade_buttons.size()==1,"Railgun copy detail shows current level and normal upgrade costs")
	game.menu_view = "loadout"
	game._on_panel_action("request_unequip:railgun-002")
	expect(game.profile.ships.starter_ship.loadout.W2 == "" and Loadouts.reserve_items(game.profile).has("railgun-002"),"Railgun copy unequips to reserve")
	game.profile.unlockedEquipmentBlueprints.append(Equipment.MICRO_MISSILE_RACK_ID)
	game.profile.totalCoins = 600; game.profile.railgunModules = 0
	game._on_panel_action("blueprint_detail:" + Equipment.MICRO_MISSILE_RACK_ID)
	var missile_detail_text := ""
	for label in game.overlay.find_children("*","RichTextLabel",true,false): missile_detail_text += str(label.text) + "\n"
	for label in game.overlay.find_children("*","Label",true,false): missile_detail_text += str(label.text) + "\n"
	var missile_build_buttons := game.overlay.find_children("*","Button",true,false).filter(func(control): return str(control.text) == "BUILD TO RESERVE")
	expect(missile_detail_text.contains("2,000") and missile_detail_text.contains("1,400 CREDITS") and missile_build_buttons.size()==1 and missile_build_buttons[0].disabled,"Missile detail shows total and missing build cost")
	game.profile.totalCoins = 2000
	game._on_panel_action("build_equipment:" + Equipment.MICRO_MISSILE_RACK_ID)
	expect(game.profile.equipmentItems.has(Equipment.MICRO_MISSILE_RACK_INSTANCE_ID) and game.hangar_selected_equipment == Equipment.MICRO_MISSILE_RACK_ID and Loadouts.reserve_items(game.profile).has(Equipment.MICRO_MISSILE_RACK_INSTANCE_ID),"Missile Build creates a reserve item and keeps the blueprint selected for repeat builds")
	game._on_panel_action("hangar_slot:S1")
	game._on_panel_action("request_unequip:" + Equipment.SHIELD_CORE_INSTANCE_ID)
	expect(game.hangar_pending_unequip == Equipment.SHIELD_CORE_INSTANCE_ID,"Last defensive system asks for confirmation before unequipping")
	game._on_panel_action("cancel_unequip")
	expect(game.profile.ships.starter_ship.loadout.S1 == Equipment.SHIELD_CORE_INSTANCE_ID,"Cancelled defensive unequip preserves the system")
	game.start_run(); game.menu_view = "hangar"; game._on_panel_action("manage_loadout")
	expect(game._hangar_changes_locked() and game.menu_view == "loadout","Active run leaves Hangar readable while mutation controls are locked")
	expect(game._is_loadout_slot_enabled("W1") and game.weapon_runtime_by_item_id.has(Equipment.RAILGUN_INSTANCE_ID),"Active run starts with the equipped module enabled")
	game._on_panel_action("toggle_slot:W1")
	expect(not game._is_loadout_slot_enabled("W1") and not game.weapon_runtime_by_item_id.has(Equipment.RAILGUN_INSTANCE_ID) and game.weapon_runtime_by_item_id.has(second_railgun_id),"Loadout switch disables only the selected module immediately during a run")
	game._on_panel_action("toggle_slot:W1")
	expect(game._is_loadout_slot_enabled("W1") and game.weapon_runtime_by_item_id.has(Equipment.RAILGUN_INSTANCE_ID),"Loadout switch re-enables the module during a run")
	print("Loadout checks: %d, failures: %d" % [checks,failures])
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
	quit(1 if failures else 0)
