extends "res://scripts/systems/progression_panel.gd"

const Cards := preload("res://scripts/systems/railgun_cards.gd")
const HangarView := preload("res://scripts/systems/hangar_view.gd")
const Loadouts := preload("res://scripts/systems/loadout_system.gd")
const Equipment := preload("res://scripts/systems/equipment_registry.gd")
const ShipRegistry := preload("res://scripts/systems/ship_registry.gd")
const ModuleProgression := preload("res://scripts/systems/module_progression.gd")
const WeaponStats := preload("res://scripts/systems/weapon_stat_resolver.gd")
const Upgrades := preload("res://scripts/systems/upgrade_registry.gd")
const CurrencyUI := preload("res://scripts/systems/ui_design_system.gd")
const LOADOUT_DISPLAY_FONT := preload("res://assets/ui/fonts/Oxanium-Variable.ttf")
var loadout_bold_font: FontVariation
var wide_cards := false
var preserved_unlocks: Array = []
var art: Texture2D
var rail_ui_factor := 1.0
var choice_card_art_size := 64.0
var choice_loadout_slot_size := 64.0

class HangarSegmentedBar extends Control:
	var progress := 0.0
	var accent := Color.WHITE

	func set_progress(value: float, color: Color) -> void:
		progress = clampf(value, 0.0, 1.0)
		accent = color
		queue_redraw()

	func _draw() -> void:
		if size.x <= 0.0 or size.y <= 0.0: return
		var track := Rect2(Vector2(0.5, 1.5), Vector2(size.x - 1.0, size.y - 3.0))
		draw_style_box(_box(Color("#081a29"), Color("#27566e"), 1, 4), track)
		var inset := 4.0
		var gap := 4.0
		var segment_width := maxf(1.0, (track.size.x - inset * 2.0 - gap * 4.0) / 5.0)
		for index in range(5):
			var segment := Rect2(track.position + Vector2(inset + index * (segment_width + gap), inset), Vector2(segment_width, maxf(1.0, track.size.y - inset * 2.0)))
			draw_style_box(_box(Color("#173047"), Color("#173047"), 0, 2), segment)
			var amount := clampf(progress * 5.0 - float(index), 0.0, 1.0)
			if amount > 0.0:
				var filled := Rect2(segment.position, Vector2(segment.size.x * amount, segment.size.y))
				draw_style_box(_box(Color(accent, 0.92), Color(accent, 0.92), 0, 2), filled)

	func _box(background: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = background
		style.border_color = border
		style.set_border_width_all(width)
		style.set_corner_radius_all(radius)
		return style

func illustration(key: String) -> Texture2D:
	var path := "res://assets/ui/railgun_cards/%s.png" % key
	return load(path) if ResourceLoader.exists(path) else art

func portrait(key: String, height: float) -> TextureRect:
	var image := TextureRect.new()
	image.texture = illustration(key)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# Card art is square source artwork. Never crop it to a shallow card strip.
	image.clip_contents = false
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2(height,height) * rail_ui_factor
	image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return image


func show_railgun(game: Control) -> void:
	_set_default_overlay_style()
	# Keep the legacy entry point, but render the canonical equipment screen. This
	# prevents the retired card UI from exposing a second, stale Railgun model.
	game.hangar_selected_equipment = Equipment.RAILGUN_INSTANCE_ID
	game.menu_view = "equipment_detail"
	_show_equipment_detail(game)

func _show_legacy_hangar(game: Control) -> void:
	_set_default_overlay_style()
	var ship: Dictionary = game._active_ship()
	var state: Dictionary = game.profile.ships.get(str(ship.id),{})
	var reserve_count := Loadouts.reserve_items(game.profile).size()
	var compact_name := str(ship.name).trim_suffix(" Gunship")
	show_content("HANGAR · %s" % compact_name,"%s · HULL %.0f · %d HARDPOINTS · RESERVE %d" % [str(ship.rarity).to_upper(),float(ship.base_stats.max_hp),ship.slots.size(),reserve_count],[],[],[])
	var view := HangarView.new()
	view.name = "DynamicHangarView"
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.configure(ship,game.profile)
	rows.add_child(view)
	var railgun := Equipment.definition(Equipment.RAILGUN_ID)
	var aux_box := _upgrade_panel(Color("#101f2e"),8)
	rows.add_child(aux_box)
	var aux_words := VBoxContainer.new(); aux_box.add_child(aux_words)
	var railgun_item: Dictionary = game.profile.equipmentItems.get(Equipment.RAILGUN_INSTANCE_ID,{})
	var railgun_stats := _equipment_stats(game,railgun_item if not railgun_item.is_empty() else {"blueprint_id":Equipment.RAILGUN_ID,"level":1},railgun)
	aux_words.add_child(_card_label("Railgun  ·  COMMON",15,Color("#d6d9df")))
	aux_words.add_child(_card_label("RAILGUN  ·  KINETIC  ·  Damage %.1f  ·  Magazine %d  ·  Reload %.2fs" % [float(railgun_stats.damage),int(railgun_stats.magazine),float(railgun_stats.reload)],11,Color("#c2dce6")))
	if railgun_item.is_empty():
		var build_cost: Dictionary = Equipment.RAILGUN_BUILD_COST
		aux_words.add_child(_card_label("Blueprint found · build in reserve · Cost ◈ %d  ▣ %d" % [int(build_cost.coins),int(build_cost.modules)],12,Color("#69f0bc")))
		var build_button := button("Build Railgun", "build_railgun", game.profile.totalCoins < build_cost.coins or game.profile.railgunModules < build_cost.modules or game.status not in ["menu","dead"])
		aux_words.add_child(build_button)
	else:
		var installed_slot := ""
		for slot_id in state.get("loadout",{}):
			if str(state.loadout[slot_id]) == Equipment.RAILGUN_INSTANCE_ID: installed_slot = str(slot_id)
		if installed_slot.is_empty():
			aux_words.add_child(_card_label("Built · in reserve · choose a free weapon hardpoint",12,Color("#f3d36a")))
			for slot in ship.slots:
				if str(slot.type) != "weapon" or not str(state.loadout.get(str(slot.id),"")).is_empty(): continue
				aux_words.add_child(button("Install in %s" % str(slot.id),"install_equipment:%s:%s" % [Equipment.RAILGUN_INSTANCE_ID,str(slot.id)],game.status not in ["menu","dead"]))
		else:
			aux_words.add_child(_card_label("Installed in %s · active combat weapon" % installed_slot,12,Color("#69f0bc")))
			aux_words.add_child(button("Unequip to Reserve","unequip_equipment:%s" % Equipment.RAILGUN_INSTANCE_ID,game.status not in ["menu","dead"]))
	var missile := Equipment.definition(Equipment.MICRO_MISSILE_RACK_ID)
	var missile_unlocked: bool = Equipment.MICRO_MISSILE_RACK_ID in game.profile.get("unlockedEquipmentBlueprints",[])
	var missile_item: Dictionary = game.profile.equipmentItems.get(Equipment.MICRO_MISSILE_RACK_INSTANCE_ID,{})
	var missile_box := _upgrade_panel(Color("#2a1b12"),8); rows.add_child(missile_box)
	var missile_words := VBoxContainer.new(); missile_box.add_child(missile_words)
	missile_words.add_child(_card_label("Micro Missile Rack  ·  NORMAL",15,Color("#ffb347")))
	missile_words.add_child(_card_label("EXPLOSIVE  ·  CYAN HOMING  ·  Damage 18  ·  3-ROCKET SALVO  ·  Reload 4.0s" if missile_unlocked else "LOCKED · Defeat an Armored Drone",11,Color("#b9f3ff")))
	if missile_unlocked and missile_item.is_empty():
		var missile_cost: Dictionary = missile.get("build_cost",{"coins":2500,"modules":0})
		missile_words.add_child(button("Build Missile · ◈ %d" % int(missile_cost.coins),"build_micro_missile",game.profile.totalCoins < missile_cost.coins or game.status not in ["menu","dead"]))
	elif missile_unlocked:
		var missile_slot := ""
		for slot_id in state.get("loadout",{}):
			if str(state.loadout[slot_id]) == Equipment.MICRO_MISSILE_RACK_INSTANCE_ID: missile_slot = str(slot_id)
		if missile_slot.is_empty():
			missile_words.add_child(_card_label("Built · reserve · choose a free weapon hardpoint",12,Color("#f3d36a")))
			for slot in ship.slots:
				if str(slot.type) == "weapon" and str(state.loadout.get(str(slot.id),"")).is_empty(): missile_words.add_child(button("Install in %s" % str(slot.id),"install_equipment:%s:%s" % [Equipment.MICRO_MISSILE_RACK_INSTANCE_ID,str(slot.id)],game.status not in ["menu","dead"]))
		else:
			missile_words.add_child(_card_label("Installed in %s · active explosive weapon" % missile_slot,12,Color("#69f0bc")))
			missile_words.add_child(button("Unequip to Reserve","unequip_equipment:%s" % Equipment.MICRO_MISSILE_RACK_INSTANCE_ID,game.status not in ["menu","dead"]))
	var legend := _card_label("[color=#00e5ff]WEAPON[/color]   [color=#b965ff]SYSTEM[/color]   Empty hardpoints are available for future equipment.",11,Color("#c2dce6"))
	rows.add_child(legend)
	var actions := HBoxContainer.new(); footer.add_child(actions)
	actions.add_child(button("Railgun Upgrade","railgun")); actions.add_child(button("Milestones","railgun_catalog")); actions.add_child(button("Back","back"))
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	set_ui_factor(rail_ui_factor)

func show_hangar(game: Control) -> void:
	_set_default_overlay_style()
	match game.menu_view:
		"ship_systems": _show_ship_systems(game)
		"loadout": _show_loadout(game)
		"equipment_picker": _show_equipment_picker(game)
		"equipment_detail": _show_equipment_detail(game)
		"blueprints": _show_blueprints(game)
		"blueprint_detail": _show_blueprint_detail(game)
		_: _show_hangar_overview(game)
	set_ui_factor(rail_ui_factor)

func _show_ship_systems(game: Control) -> void:
	var ship: Dictionary = game._active_ship()
	var state: Dictionary = game.profile.get("ships",{}).get(game._active_ship_id(),{})
	var level := clampi(int(state.get("upgrade_level",0)),0,ShipRegistry.SHIP_LEVEL_CAP)
	var cap := ShipRegistry.SHIP_LEVEL_CAP
	var accent := UI.CYAN
	var cost := ShipRegistry.upgrade_cost(level)
	var locked: bool = not game.profile.activeRun.is_empty() or game.status not in ["menu","dead"]
	show_content("CHASSIS BAY","SHIP DETAILS  ·  %s  ·  %s" % [str(ship.get("name","DRIFTER")).to_upper(),str(ship.get("rarity","common")).to_upper()],[],[],[])
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	rows.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var identity := _hangar_panel(Color("#071b2b"),8)
	rows.add_child(identity)
	var identity_line := HBoxContainer.new()
	identity_line.add_theme_constant_override("separation",12 * rail_ui_factor)
	identity.add_child(identity_line)
	var portrait := TextureRect.new()
	portrait.texture = load(str(ship.get("art",{}).get("hangar","")))
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(108,108) * rail_ui_factor
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity_line.add_child(portrait)
	var identity_words := VBoxContainer.new()
	identity_words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity_line.add_child(identity_words)
	identity_words.add_child(_loadout_label(str(ship.get("name","DRIFTER")).to_upper(),20,Color("#f1fbff")))
	identity_words.add_child(_loadout_label("CHASSIS  ·  %s" % str(ship.get("rarity","common")).to_upper(),11,accent))
	identity_words.add_child(_loadout_label("%d weapon hardpoints  ·  %d system hardpoints" % [_slot_count(ship,"weapon"),_slot_count(ship,"system")],11,Color("#a9c6d8")))
	identity_words.add_child(_loadout_label("Modules and slots are unique to this ship loadout.",11,Color("#c7e7ef")))

	var level_panel := _hangar_panel(Color("#091d2c"),8)
	rows.add_child(level_panel)
	var level_stack := VBoxContainer.new()
	level_stack.add_theme_constant_override("separation",5 * rail_ui_factor)
	level_panel.add_child(level_stack)
	var level_header := HBoxContainer.new()
	level_stack.add_child(level_header)
	level_header.add_child(_loadout_label("CHASSIS LEVEL",12,Color("#b9f3ff")))
	var level_value := _loadout_label("LV.%d / %d" % [level,cap],18,Color("#f1fbff"))
	level_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_header.add_child(level_value)
	var level_bar := HangarSegmentedBar.new()
	level_bar.custom_minimum_size.y = 22 * rail_ui_factor
	level_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_bar.set_progress(float(level) / float(cap),accent)
	level_stack.add_child(level_bar)
	level_stack.add_child(_loadout_label("Every chassis level improves the ship itself. Rarity belongs to modules, not to this upgrade track.",10,Color("#8faebb")))

	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation",6 * rail_ui_factor)
	stats.add_theme_constant_override("v_separation",6 * rail_ui_factor)
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_child(_card_label("CURRENT CHASSIS PROFILE",12,Color("#b9f3ff")))
	rows.add_child(stats)
	_add_chassis_stat_card(stats,"HULL", "%.0f" % game._ship_base_stat("max_hp"), "Effective %.0f" % game._stat("max_hp"), "+8 / level", Color("#75eaf5"), "res://assets/ui/icons/hull.svg")
	_add_chassis_stat_card(stats,"REGEN", "%.2f /s" % game._ship_base_stat("regen"), "Effective %.2f /s" % game._stat("regen"), "+0.04 / level", Color("#69f0bc"), "res://assets/ui/icons/regen.svg")
	_add_chassis_stat_card(stats,"ARMOR", "Rating %.1f" % game._armor_rating(game._ship_base_stat("armor")), "Effective %.1f%% DR" % (game._armor_damage_reduction_for(game._stat("armor")) * 100.0), "+0.3 rating / level", Color("#c68cff"), "res://assets/ui/icons/upgrade_chevrons.svg")
	_add_chassis_stat_card(stats,"ATTACK", "%.1f" % game._ship_base_stat("damage"), "Effective %.1f" % game._stat("damage"), "+0.5 / level", Color("#ffd45f"), "res://assets/ui/icons/hangar_damage.svg")

	var next_panel := _hangar_panel(Color("#102033"),8)
	rows.add_child(next_panel)
	var next_stack := VBoxContainer.new()
	next_stack.add_theme_constant_override("separation",4 * rail_ui_factor)
	next_panel.add_child(next_stack)
	var next_level := level + 1
	if level >= cap:
		next_stack.add_child(_loadout_label("CHASSIS MASTERED",15,Color("#69f0bc")))
		next_stack.add_child(_loadout_label("All chassis improvements are unlocked.",11,Color("#c7e7ef")))
	else:
		next_stack.add_child(_loadout_label("NEXT CALIBRATION  ·  LV.%d" % next_level,12,Color("#b9f3ff")))
		next_stack.add_child(_loadout_label("HULL +8   ·   REGEN +0.04/s   ·   ARMOR RATING +0.3   ·   ATTACK +0.5",11,Color("#d7f7ff")))
		next_stack.add_child(_loadout_label("Upgrade cost  ◈ %s" % game._money(float(cost)),12,Color("#ffd45f")))

	var footer_actions := HBoxContainer.new()
	footer_actions.add_theme_constant_override("separation",8 * rail_ui_factor)
	footer.add_child(footer_actions)
	footer_actions.add_child(_detail_action_button("UPGRADE CHASSIS", "ship_upgrade", locked or level >= cap or float(game.profile.totalCoins) < cost, accent, "res://assets/ui/icons/upgrade_chevrons.svg"))
	footer_actions.add_child(_detail_action_button("WORKSHOP", "workshop", false, Color("#b965ff")))
	footer.add_child(_hangar_button("BACK TO LOADOUT", "back", false, Color("#8bbdcb")))
	_add_resume_run_button(game)

func _slot_count(ship: Dictionary, slot_type: String) -> int:
	var count := 0
	for slot in ship.get("slots",[]):
		if str(slot.get("type","")) == slot_type: count += 1
	return count

func _add_chassis_stat_card(parent: Control, label: String, value: String, effective: String, delta: String, accent: Color, icon_path: String) -> void:
	var panel := _hangar_panel(Color("#071723"),6)
	panel.custom_minimum_size.y = 78 * rail_ui_factor
	parent.add_child(panel)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation",7 * rail_ui_factor)
	panel.add_child(line)
	var icon := TextureRect.new()
	icon.texture = load(icon_path) if ResourceLoader.exists(icon_path) else load("res://assets/ui/icons/upgrade_chevrons.svg")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(27,27) * rail_ui_factor
	icon.modulate = accent
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(icon)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(words)
	words.add_child(_loadout_label(label,10,Color("#a9c6d8")))
	words.add_child(_loadout_label(value,16,Color("#f1fbff")))
	words.add_child(_loadout_label(effective,9,Color("#d3a6ff")))
	words.add_child(_loadout_label(delta,9,accent))

func _hangar_locked(game: Control) -> bool:
	return game._hangar_changes_locked()

func _add_resume_run_button(game: Control) -> void:
	if game.status != "paused": return
	footer.add_child(_hangar_button("RESUME\nRUN", "resume", false, Color("#75eaf5"), "res://assets/ui/icons/launch.svg"))

func _show_hangar_overview(game: Control) -> void:
	var ship: Dictionary = game._active_ship()
	show_content("HANGAR", "%s  ·  %s" % [str(ship.get("name","DRIFTER")).to_upper(),str(ship.get("rarity","normal")).to_upper()],[],[],[])
	# Keep the primary actions anchored in the footer. On smaller phones the ship
	# and stat area scrolls instead of pushing the navigation below the viewport.
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	rows.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var view := HangarView.new()
	view.name = "HangarShipOverview"
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.configure(ship,game.profile,false)
	rows.add_child(view)
	var stats := GridContainer.new()
	stats.name = "HangarStatConsole"
	stats.columns = 1
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_theme_constant_override("h_separation",6)
	stats.add_theme_constant_override("v_separation",6)
	rows.add_child(stats)
	stats.add_theme_constant_override("separation", 5)
	_add_hangar_stat_row(stats, game, "HULL", "res://assets/ui/icons/hull.svg", "max_hp", Color("#75eaf5"))
	_add_hangar_stat_row(stats, game, "SHIELD", "res://assets/ui/icons/shield.svg", "shield_capacity", Color("#b965ff"))
	_add_hangar_stat_row(stats, game, "DAMAGE", "res://assets/ui/icons/hangar_damage.svg", "damage", Color("#ffd45f"))
	_add_hangar_stat_row(stats, game, "ARMOR", "res://assets/ui/icons/upgrade_chevrons.svg", "armor", Color("#75eaf5"))
	if _hangar_locked(game): rows.add_child(_card_label("Equipment changes are locked during an active run. Use ENABLE / DISABLE to control each installed slot.",12,Color("#ffe080")))
	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("h_separation",6)
	actions.add_theme_constant_override("v_separation",6)
	footer.add_child(actions)
	actions.add_child(_hangar_button("MANAGE\nLOADOUT","manage_loadout",false,Color("#00e5ff"),"res://assets/ui/icons/loadout.svg"))
	actions.add_child(_hangar_button("BLUEPRINTS","blueprints",false,Color("#b965ff"),"res://assets/ui/icons/blueprints.svg"))
	actions.add_child(_hangar_button("SHIP\nSYSTEMS","ship_systems",_hangar_locked(game),Color("#8bbdcb"),"res://assets/ui/icons/systems.svg"))
	var paused_run: bool = game.status == "paused"
	var run_label := "RESUME\nRUN" if paused_run else ("START RUN" if not _hangar_locked(game) else "RUN ACTIVE")
	var run_action := "resume" if paused_run else "start"
	var run_disabled := false if paused_run else _hangar_locked(game)
	actions.add_child(_hangar_button(run_label,run_action,run_disabled,Color("#75eaf5"),"res://assets/ui/icons/launch.svg"))
	_add_resume_run_button(game)

func _show_loadout(game: Control) -> void:
	var ship: Dictionary = game._active_ship()
	var loadout: Dictionary = game.profile.ships.get(str(ship.get("id","")),{}).get("loadout",{})
	var weapon_total: int = int(ship.get("slots",[]).filter(func(slot): return str(slot.get("type","")) == "weapon").size())
	var system_total: int = int(ship.get("slots",[]).filter(func(slot): return str(slot.get("type","")) == "system").size())
	var weapons := 0
	var systems := 0
	for slot in ship.get("slots",[]):
		if str(loadout.get(str(slot.get("id","")),"")).is_empty(): continue
		if str(slot.get("type","")) == "weapon": weapons += 1
		else: systems += 1
	show_content("DRIFTER LOADOUT","%d/%d WEAPONS  ·  %d/%d SYSTEMS" % [weapons,weapon_total,systems,system_total],[],[],[])
	_add_active_ship_summary(game, ship)
	if game.hangar_selected_equipment.is_empty():
		for slot in ship.get("slots",[]):
			var initial_item := Loadouts.installed_instance(game.profile,str(slot.get("id","")))
			if not initial_item.is_empty():
				game.hangar_selected_equipment = str(initial_item.get("id",""))
				break
	# The slot grid may grow with future ships. Let this content scroll while the
	# Back action remains reachable in the persistent footer.
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	rows.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var narrow_loadout := get_viewport_rect().size.x / maxf(0.1,rail_ui_factor) < 700.0
	if _hangar_locked(game): rows.add_child(_card_label("Loadout locked during an active run. Retire or finish the run to make changes.",12,Color("#ffe080")))
	for section in [["WEAPON SLOTS","weapon",Color("#00e5ff")],["SYSTEM SLOTS","system",Color("#b965ff")]]:
		rows.add_child(_card_label(str(section[0]),15,section[2]))
		var grid := GridContainer.new()
		# Keep the horizontal slot hierarchy, but use two columns. The compact
		# measurements below include room for the ScrollContainer scrollbar.
		grid.columns = 2
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		grid.add_theme_constant_override("h_separation",6)
		grid.add_theme_constant_override("v_separation",6)
		rows.add_child(grid)
		for slot in ship.get("slots",[]):
			if str(slot.get("type","")) != str(section[1]): continue
			var item: Dictionary = Loadouts.installed_instance(game.profile,str(slot.get("id","")))
			var blueprint: Dictionary = Equipment.definition(str(item.get("blueprint_id","")))
			_add_loadout_slot_card(grid,slot,blueprint,item,section[2],str(item.get("id","")) == game.hangar_selected_equipment,narrow_loadout,game._is_loadout_slot_enabled(str(slot.get("id",""))))
	var selected_item: Dictionary = game.profile.equipmentItems.get(game.hangar_selected_equipment,{})
	if selected_item.is_empty():
		for slot in ship.get("slots",[]):
			selected_item = Loadouts.installed_instance(game.profile,str(slot.get("id","")))
			if not selected_item.is_empty():
				game.hangar_selected_equipment = str(selected_item.get("id",""))
				break
	if not selected_item.is_empty(): _add_loadout_selection_detail(game,selected_item,narrow_loadout)
	_add_reserve_summary(game)
	footer.add_child(_hangar_button("BACK", "back", false, Color("#8bbdcb")))
	_add_resume_run_button(game)

func _add_active_ship_summary(game: Control, ship: Dictionary) -> void:
	var state: Dictionary = game.profile.get("ships", {}).get(str(ship.get("id", "")), {})
	var panel := _hangar_panel(Color("#071b2b"), 8)
	panel.name = "ActiveShipSummary"
	rows.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6 * rail_ui_factor)
	panel.add_child(stack)
	var identity := HBoxContainer.new()
	identity.add_theme_constant_override("separation", 9 * rail_ui_factor)
	stack.add_child(identity)
	var art := TextureRect.new()
	art.texture = load(str(ship.get("art", {}).get("hangar", "")))
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = Vector2(58, 58) * rail_ui_factor
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity.add_child(art)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(words)
	words.add_child(_loadout_label("ACTIVE SHIP  ·  %s" % str(ship.get("name", "DRIFTER")).to_upper(), 14, Color("#f1fbff")))
	words.add_child(_loadout_label("CHASSIS LV.%d/%d  ·  %d WEAPON  ·  %d SYSTEM" % [int(state.get("upgrade_level", 0)), ShipRegistry.SHIP_LEVEL_CAP, _slot_count(ship, "weapon"), _slot_count(ship, "system")], 10, Color("#a9c6d8")))
	words.add_child(_loadout_label("HULL %.0f  ·  SHIELD %.0f  ·  ATTACK %.1f" % [game._stat("max_hp"), game._stat("shield_capacity"), game._stat("damage")], 10, Color("#d7f7ff")))
	var routes := HBoxContainer.new()
	routes.add_theme_constant_override("separation", 6 * rail_ui_factor)
	stack.add_child(routes)
	routes.add_child(_detail_action_button("CHASSIS BAY", "ship_systems", false, Color("#8bbdcb"), "res://assets/ui/icons/systems.svg"))
	routes.add_child(_detail_action_button("BLUEPRINTS", "blueprints", false, Color("#b965ff"), "res://assets/ui/icons/blueprints.svg"))

func _add_loadout_selection_detail(game: Control, item: Dictionary, compact := false) -> void:
	var blueprint: Dictionary = Equipment.definition(str(item.get("blueprint_id","")))
	if blueprint.is_empty(): return
	var accent := _loadout_slot_accent(blueprint,false)
	var shell := PanelContainer.new()
	var shell_style := _loadout_slot_style(accent,false)
	shell_style.bg_color = Color("#06141F")
	shell_style.shadow_color = Color.TRANSPARENT
	shell_style.shadow_size = 0
	shell.add_theme_stylebox_override("panel",shell_style)
	shell.custom_minimum_size.y = (330 if compact else 270) * rail_ui_factor
	rows.add_child(shell)
	var frame := TextureRect.new()
	frame.texture = load("res://assets/ui/components/equipment_detail_frame.svg")
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.modulate = Color("#79e9f5")
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.add_child(frame)
	var margin := MarginContainer.new()
	var detail_inset := 12.0 if compact else 22.0
	margin.add_theme_constant_override("margin_left",detail_inset * rail_ui_factor)
	margin.add_theme_constant_override("margin_right",detail_inset * rail_ui_factor)
	margin.add_theme_constant_override("margin_top",12 * rail_ui_factor if compact else 18 * rail_ui_factor)
	margin.add_theme_constant_override("margin_bottom",12 * rail_ui_factor if compact else 18 * rail_ui_factor)
	shell.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",7 * rail_ui_factor if compact else 10 * rail_ui_factor)
	margin.add_child(stack)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation",12 * rail_ui_factor)
	stack.add_child(header)
	var detail_slot := _loadout_label(_installed_slot_id(game,str(item.get("id",""))),16 if compact else 20,accent)
	detail_slot.custom_minimum_size.x = 30 * rail_ui_factor if compact else 42 * rail_ui_factor
	header.add_child(detail_slot)
	var divider := ColorRect.new(); divider.color = Color(accent,0.60); divider.custom_minimum_size = Vector2(2,26) * rail_ui_factor; header.add_child(divider)
	var detail_title := _loadout_label(str(blueprint.get("name","UNKNOWN")).to_upper(),15 if compact else 19,Color("#f2fdff"))
	detail_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	detail_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(detail_title)
	var top: BoxContainer = VBoxContainer.new() if compact else HBoxContainer.new()
	top.add_theme_constant_override("separation",8 * rail_ui_factor if compact else 20 * rail_ui_factor)
	stack.add_child(top)
	var art_path := str(blueprint.get("slot_art",blueprint.get("art","")))
	var art_socket := PanelContainer.new()
	var art_socket_style := StyleBoxFlat.new()
	art_socket_style.bg_color = Color("#061923")
	art_socket_style.border_color = accent
	art_socket_style.set_border_width_all(2)
	art_socket_style.corner_radius_top_left = 8
	art_socket_style.corner_radius_bottom_right = 8
	art_socket.add_theme_stylebox_override("panel",art_socket_style)
	art_socket.custom_minimum_size = Vector2(92,82) * rail_ui_factor if compact else Vector2(124,112) * rail_ui_factor
	if compact: art_socket.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	top.add_child(art_socket)
	if ResourceLoader.exists(art_path):
		var image := TextureRect.new()
		image.texture = load(art_path)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,Control.PRESET_MODE_MINSIZE,12 * rail_ui_factor)
		art_socket.add_child(image)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation",4 * rail_ui_factor if compact else 6 * rail_ui_factor)
	top.add_child(info)
	var tags := HBoxContainer.new(); tags.add_theme_constant_override("separation",8 * rail_ui_factor); info.add_child(tags)
	tags.add_child(_detail_tag(str(blueprint.get("family",blueprint.get("weapon_family",blueprint.get("item_type","system")))).to_upper(),accent))
	tags.add_child(_detail_tag(str(blueprint.get("damage_type",blueprint.get("item_type","system"))).to_upper(),Color("#8bbdcb")))
	info.add_child(_loadout_label("LEVEL %d" % int(item.get("level",1)),18,Color("#dceeff")))
	var stats := _equipment_stats(game,item,blueprint)
	var stat_row := HBoxContainer.new(); stat_row.add_theme_constant_override("separation",8 * rail_ui_factor); info.add_child(stat_row)
	_add_detail_stat(stat_row,"res://assets/ui/icons/damage.svg","DAMAGE","%.1f" % float(stats.get("damage",0)),accent)
	_add_detail_stat_divider(stat_row)
	_add_detail_stat(stat_row,"res://assets/ui/icons/magazine.svg","MAGAZINE",str(int(stats.get("magazine",stats.get("capacity",0)))),accent)
	_add_detail_stat_divider(stat_row)
	_add_detail_stat(stat_row,"res://assets/ui/icons/reload.svg","RELOAD","%.2fs" % float(stats.get("reload",0)),accent)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation",12 * rail_ui_factor)
	stack.add_child(actions)
	# The Loadout stays a compact confirmation of what is installed. Spending and
	# removal deliberately live one step deeper, so an accidental tap cannot alter
	# the player's build while they are browsing their hardpoints.
	actions.add_child(_detail_action_button("DETAILS","equipment_details:%s" % str(item.get("id","")),false,accent))

func _detail_tag(text: String, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#071925")
	style.border_color = color
	style.set_border_width_all(2)
	style.corner_radius_top_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	panel.add_theme_stylebox_override("panel",style)
	panel.custom_minimum_size.x = (text.length() * 8 + 20) * rail_ui_factor
	panel.add_child(_loadout_label(text,12,color))
	return panel

func _add_detail_stat(parent: Control, icon_path: String, label: String, value: String, accent: Color) -> void:
	var stat := HBoxContainer.new()
	stat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat.add_theme_constant_override("separation",4 * rail_ui_factor)
	parent.add_child(stat)
	var icon := TextureRect.new()
	icon.texture = load(icon_path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(28,28) * rail_ui_factor
	icon.modulate = accent
	stat.add_child(icon)
	var words := VBoxContainer.new(); stat.add_child(words)
	words.add_child(_loadout_label(label,10,Color("#a9c6d8")))
	words.add_child(_loadout_label(value,17,Color("#f1fbff")))

func _add_detail_stat_divider(parent: Control) -> void:
	var divider := ColorRect.new()
	divider.color = Color("#8bbdcb",0.55)
	divider.custom_minimum_size = Vector2(1,42) * rail_ui_factor
	parent.add_child(divider)

func _detail_action_button(text: String, action: String, disabled: bool, accent: Color, icon_path := "") -> Button:
	var control := Button.new()
	control.text = text
	control.disabled = disabled
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.custom_minimum_size.y = 54 * rail_ui_factor
	UI.apply_text(control, UI.BUTTON, UI.TEXT, true)
	control.add_theme_constant_override("outline_size",1)
	control.add_theme_color_override("font_outline_color",Color("#e9fbff"))
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path): control.icon = load(icon_path)
	var primary := action.begins_with("upgrade")
	for state in ["normal","hover","pressed","disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(UI.SURFACE_RAISED) if primary else Color(UI.SURFACE)
		if state == "hover" and not disabled: style.bg_color = Color("#0b3145") if primary else Color("#0c2330")
		if state == "pressed" and not disabled: style.bg_color = Color("#061722")
		if disabled: style.bg_color = Color("#0b1822")
		style.border_color = Color(accent,0.55) if disabled else (accent if primary else UI.CYAN_SOFT)
		style.set_border_width_all(2)
		style.corner_radius_top_left = 8
		style.corner_radius_bottom_right = 8
		style.shadow_color = Color(accent,0.22) if primary else Color.TRANSPARENT
		style.shadow_size = 6 if primary and not disabled else 0
		control.add_theme_stylebox_override(state,style)
	control.pressed.connect(func(): selected.emit(action))
	return control

func _installed_slot_id(game: Control, item_id: String) -> String:
	for slot in game._active_ship().get("slots",[]):
		if str(Loadouts.installed_instance(game.profile,str(slot.get("id",""))).get("id","")) == item_id:
			return str(slot.get("id",""))
	return "RESERVE"

func _loadout_detail_glow_color(blueprint: Dictionary) -> Color:
	return UI.rarity_color(str(blueprint.get("rarity","normal")))

func _show_equipment_picker(game: Control) -> void:
	var slot: Dictionary = game._active_ship().get("slots",[]).filter(func(entry): return str(entry.get("id","")) == game.hangar_selected_slot).front() if game._active_ship().get("slots",[]).any(func(entry): return str(entry.get("id","")) == game.hangar_selected_slot) else {}
	if slot.is_empty():
		game.menu_view = "loadout"
		_show_loadout(game)
		return
	show_content("%s EMPTY" % game.hangar_selected_slot,"SELECT COMPATIBLE EQUIPMENT",[],[],[])
	var compatible := []
	for item_id in Loadouts.reserve_items(game.profile):
		var item: Dictionary = game.profile.equipmentItems.get(item_id,{})
		var blueprint: Dictionary = Equipment.definition(str(item.get("blueprint_id","")))
		if not slot.get("accepts",[]).has(str(blueprint.get("item_type",""))): continue
		var candidate: Dictionary = game.profile.ships.get(game._active_ship_id(),{}).get("loadout",{}).duplicate(true)
		candidate[game.hangar_selected_slot] = item_id
		if Loadouts.validate(game._active_ship_id(),candidate,game.profile.equipmentItems).valid: compatible.append(item_id)
	if compatible.is_empty():
		rows.add_child(_card_label("No compatible equipment in reserve.",15,Color("#c2dce6")))
		footer.add_child(_hangar_button("VIEW BLUEPRINTS","view_blueprints:%s" % ("weapons" if str(slot.get("type","")) == "weapon" else "systems"),_hangar_locked(game),Color("#b965ff")))
	else:
		for item_id in compatible:
			var item: Dictionary = game.profile.equipmentItems.get(item_id,{})
			var blueprint: Dictionary = Equipment.definition(str(item.get("blueprint_id","")))
			_add_equipment_card(game,rows,blueprint,item,"equip_reserve:%s" % item_id,_hangar_locked(game))
	footer.add_child(_hangar_button("BACK TO LOADOUT","back",false,Color("#8bbdcb")))
	_add_resume_run_button(game)

func _show_equipment_detail(game: Control) -> void:
	var item: Dictionary = game.profile.equipmentItems.get(game.hangar_selected_equipment,{})
	if item.is_empty():
		game.menu_view = "loadout"
		_show_loadout(game)
		return
	var blueprint: Dictionary = Equipment.definition(str(item.get("blueprint_id","")))
	show_content("EQUIPMENT DETAILS","UPGRADE WEAPONS  ·  IMPROVE YOUR LOADOUT",[],[],[])
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	rows.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_add_equipment_detail_hero(game,item,blueprint)
	_add_equipment_comparison(game,item,blueprint)
	_add_equipment_milestones(item,blueprint)
	rows.add_child(_card_label("%s" % ("EQUIPPED" if not Loadouts.reserve_items(game.profile).has(str(item.get("id",""))) else "IN RESERVE"),12,Color("#69f0bc")))
	if not game.hangar_pending_unequip.is_empty() and game.hangar_pending_unequip == str(item.get("id","")):
		rows.add_child(_card_label("Unequipping this item removes your last defensive system. Continue?",13,Color("#ffe080")))
		footer.add_child(_hangar_button("CONFIRM UNEQUIP TO RESERVE","confirm_unequip",_hangar_locked(game),Color("#ffb347")))
		footer.add_child(_hangar_button("CANCEL","cancel_unequip",false,Color("#8bbdcb")))
	else:
		var cap := ModuleProgression.level_cap(str(item.get("rarity","common")))
		footer.add_child(_equipment_upgrade_button(game,item,blueprint,cap))
		var secondary_actions := HBoxContainer.new()
		secondary_actions.add_theme_constant_override("separation",8 * rail_ui_factor)
		footer.add_child(secondary_actions)
		secondary_actions.add_child(_detail_action_button("UNEQUIP","request_unequip:%s" % str(item.get("id","")),_hangar_locked(game),Color("#b965ff")))
		secondary_actions.add_child(_detail_action_button("BACK TO LOADOUT","back",false,Color("#8bbdcb")))
		if game.status == "paused":
			secondary_actions.add_child(_detail_action_button("RESUME RUN","resume",false,Color("#75eaf5"),"res://assets/ui/icons/launch.svg"))

func _equipment_upgrade_cost(item: Dictionary, blueprint: Dictionary) -> Dictionary:
	return Equipment.upgrade_cost(str(blueprint.get("id","")),int(item.get("level",1)))

func _equipment_upgrade_button(game: Control, item: Dictionary, blueprint: Dictionary, cap: int) -> Button:
	var level := int(item.get("level",1))
	var cost := _equipment_upgrade_cost(item,blueprint)
	var at_cap := level >= cap
	var can_afford := float(game.profile.get("totalCoins",0)) >= float(cost.get("coins",0)) and int(game.profile.get("railgunModules",0)) >= int(cost.get("modules",0))
	var disabled := at_cap or _hangar_locked(game) or not can_afford
	var control := Button.new()
	control.text = ""
	control.tooltip_text = "MAX LEVEL" if at_cap else "UPGRADE · %d CREDITS · %d BOSS MODULES" % [int(cost.get("coins",0)),int(cost.get("modules",0))]
	control.disabled = disabled
	control.custom_minimum_size.y = 62 * rail_ui_factor
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state in ["normal","hover","pressed","disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#261708") if state == "normal" else Color("#34220d")
		style.border_color = Color("#f7ba37")
		if state == "pressed": style.bg_color = Color("#160f08")
		if state == "disabled":
			style.bg_color = Color("#15130f")
			style.border_color = Color("#73613c")
		style.set_border_width_all(3)
		style.corner_radius_top_left = 9
		style.corner_radius_top_right = 9
		style.corner_radius_bottom_left = 9
		style.corner_radius_bottom_right = 9
		style.shadow_color = Color("#f7ba37",0.20) if not disabled else Color.TRANSPARENT
		style.shadow_size = 6 if not disabled else 0
		control.add_theme_stylebox_override(state,style)
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,Control.PRESET_MODE_MINSIZE,8 * rail_ui_factor)
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_theme_constant_override("separation",10 * rail_ui_factor)
	control.add_child(line)
	var label_color := Color("#ffd35a") if not disabled else Color("#9b916f")
	var caption := _loadout_label("MAX LEVEL" if at_cap else "UPGRADE",23,label_color)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(caption)
	_add_upgrade_cost_separator(line,disabled)
	_add_upgrade_cost(line,CurrencyUI.currency_path("credits"),str(int(cost.get("coins",0))) if not at_cap else "--",disabled)
	_add_upgrade_cost_separator(line,disabled)
	_add_upgrade_cost(line,CurrencyUI.currency_path("boss_module"),str(int(cost.get("modules",0))) if not at_cap else "--",disabled)
	control.pressed.connect(func(): selected.emit("upgrade_equipment_detail:%s" % str(item.get("id",""))))
	return control

func _add_upgrade_cost_separator(parent: Control, disabled: bool) -> void:
	var separator := ColorRect.new()
	separator.color = Color("#d1a45a",0.75) if not disabled else Color("#756b53",0.65)
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	separator.custom_minimum_size = Vector2(2,28) * rail_ui_factor
	parent.add_child(separator)

func _add_upgrade_cost(parent: Control, icon_path: String, amount: String, disabled: bool) -> void:
	var group := HBoxContainer.new()
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_theme_constant_override("separation",7 * rail_ui_factor)
	parent.add_child(group)
	var icon := TextureRect.new()
	icon.texture = load(icon_path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(26,26) * rail_ui_factor
	icon.modulate = Color("#ffd35a") if not disabled else Color("#8b846e")
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(icon)
	var value := _loadout_label(amount,19,Color("#fff0c0") if not disabled else Color("#9b916f"))
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(value)

func _add_equipment_detail_hero(game: Control, item: Dictionary, blueprint: Dictionary) -> void:
	var accent := _loadout_slot_accent(blueprint,false)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 198 * rail_ui_factor
	var panel_style := _loadout_slot_style(accent,false)
	panel_style.bg_color = Color("#06141f")
	panel.add_theme_stylebox_override("panel",panel_style)
	rows.add_child(panel)
	var frame := TextureRect.new()
	frame.texture = load("res://assets/ui/components/equipment_detail_frame.svg")
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.modulate = Color(accent,0.92)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(frame)
	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left",18 * rail_ui_factor)
	padding.add_theme_constant_override("margin_right",18 * rail_ui_factor)
	padding.add_theme_constant_override("margin_top",14 * rail_ui_factor)
	padding.add_theme_constant_override("margin_bottom",12 * rail_ui_factor)
	panel.add_child(padding)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",4 * rail_ui_factor)
	padding.add_child(stack)
	stack.add_child(_loadout_label(str(blueprint.get("name","EQUIPMENT")).to_upper(),22,Color("#f2fdff")))
	var tags := HBoxContainer.new()
	tags.add_theme_constant_override("separation",8 * rail_ui_factor)
	tags.add_child(_detail_tag(str(blueprint.get("rarity","normal")).to_upper(),accent))
	var current_level := int(item.get("level",1))
	var level_cap := ModuleProgression.level_cap(str(item.get("rarity","common")))
	tags.add_child(_detail_tag("LV.%d / %d" % [current_level,level_cap],Color("#f1fbff")))
	tags.add_child(_detail_tag(str(blueprint.get("family",blueprint.get("item_type","system"))).to_upper(),accent))
	tags.add_child(_detail_tag(str(blueprint.get("damage_type",blueprint.get("item_type","system"))).to_upper(),Color("#8bbdcb")))
	stack.add_child(tags)
	var art_path := str(blueprint.get("slot_art",blueprint.get("art","")))
	if ResourceLoader.exists(art_path):
		var image := TextureRect.new()
		image.texture = load(art_path)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.custom_minimum_size = Vector2(0,108) * rail_ui_factor
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(image)
	var location := "%s  ·  %s" % [_installed_slot_id(game,str(item.get("id",""))),"EQUIPPED" if not Loadouts.reserve_items(game.profile).has(str(item.get("id",""))) else "IN RESERVE"]
	stack.add_child(_loadout_label(location,12,Color("#a9c6d8")))

func _add_equipment_comparison(game: Control, item: Dictionary, blueprint: Dictionary) -> void:
	var current := _equipment_stats(game,item,blueprint)
	var cap := ModuleProgression.level_cap(str(item.get("rarity","common")))
	var advanced := item.duplicate(true)
	advanced.level = mini(cap,int(item.get("level",1)) + 1)
	var next := _equipment_stats(game,advanced,blueprint)
	# This is deliberately a single comparison instrument, rather than a grid of
	# generic cards: all five rows scan in the same left-to-right order as the
	# blueprint reference (stat -> current -> improvement -> next level).
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",4 * rail_ui_factor)
	rows.add_child(stack)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation",0)
	stack.add_child(header)
	_add_comparison_spacer(header,1.82)
	_add_comparison_header(header,"CURRENT · LV.%d" % int(item.get("level",1)),Color("#72eaff"),1.0)
	_add_comparison_spacer(header,0.45)
	_add_comparison_header(header,"NEXT LEVEL" if int(item.get("level",1)) < cap else "MAX LEVEL",Color("#79f0be") if int(item.get("level",1)) < cap else Color("#91a7af"),1.0)
	var table := PanelContainer.new()
	var table_style := StyleBoxFlat.new()
	table_style.bg_color = Color("#06131e")
	table_style.border_color = Color("#365f73")
	table_style.set_border_width_all(2)
	table_style.corner_radius_top_left = 7
	table_style.corner_radius_top_right = 7
	table_style.corner_radius_bottom_left = 7
	table_style.corner_radius_bottom_right = 7
	table.add_theme_stylebox_override("panel",table_style)
	stack.add_child(table)
	var table_rows := VBoxContainer.new()
	table_rows.add_theme_constant_override("separation",0)
	table.add_child(table_rows)
	var comparison_rows := _equipment_comparison_rows(blueprint,current,next)
	for index in range(comparison_rows.size()):
		_add_equipment_comparison_row(table_rows,comparison_rows[index],int(item.get("level",1)) < cap,index > 0)

func _add_comparison_spacer(parent: Control, ratio: float) -> void:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.size_flags_stretch_ratio = ratio
	spacer.custom_minimum_size.y = 22 * rail_ui_factor
	parent.add_child(spacer)

func _add_comparison_header(parent: Control, text: String, color: Color, ratio: float) -> void:
	var label := _loadout_label(text,13,color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_stretch_ratio = ratio
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size.y = 22 * rail_ui_factor
	parent.add_child(label)

func _comparison_divider(vertical: bool) -> ColorRect:
	var divider := ColorRect.new()
	divider.color = Color("#31566b",0.92)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	divider.custom_minimum_size = Vector2(2,0) * rail_ui_factor if vertical else Vector2(0,1) * rail_ui_factor
	divider.size_flags_vertical = Control.SIZE_EXPAND_FILL if vertical else Control.SIZE_SHRINK_CENTER
	divider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if vertical else Control.SIZE_EXPAND_FILL
	return divider

func _add_equipment_comparison_row(parent: Control, entry: Dictionary, can_upgrade: bool, divider_before: bool) -> void:
	if divider_before: parent.add_child(_comparison_divider(false))
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation",0)
	line.custom_minimum_size.y = 43 * rail_ui_factor
	parent.add_child(line)
	var stat := HBoxContainer.new()
	stat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat.size_flags_stretch_ratio = 1.82
	stat.add_theme_constant_override("separation",8 * rail_ui_factor)
	line.add_child(stat)
	var icon := TextureRect.new()
	icon.texture = load(_equipment_comparison_icon(str(entry.get("key",""))))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(27,27) * rail_ui_factor
	icon.modulate = Color("#c7e7fa")
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stat.add_child(icon)
	var name := _loadout_label(str(entry.label),13,Color("#d9edfa"))
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat.add_child(name)
	line.add_child(_comparison_divider(true))
	_add_comparison_value(line,str(entry.current),Color("#e7f7ff"),1.0)
	line.add_child(_comparison_divider(true))
	var chevron := TextureRect.new()
	chevron.texture = load("res://assets/ui/icons/comparison_chevrons.svg")
	chevron.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chevron.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chevron.custom_minimum_size = Vector2(22,22) * rail_ui_factor
	chevron.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chevron.size_flags_stretch_ratio = 0.45
	chevron.modulate = Color("#69ddf5") if can_upgrade else Color("#6d8792")
	chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(chevron)
	line.add_child(_comparison_divider(true))
	_add_comparison_value(line,str(entry.next),Color("#79f0be") if can_upgrade and bool(entry.get("changed",false)) else Color("#b8c7cf"),1.0)

func _add_comparison_value(parent: Control, value: String, color: Color, ratio: float) -> void:
	var label := _loadout_label(value,17,color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_stretch_ratio = ratio
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)

func _equipment_comparison_icon(key: String) -> String:
	match key:
		"damage": return "res://assets/ui/icons/damage.svg"
		"interval", "recharge", "crit", "explosion_damage", "super_chance": return "res://assets/ui/icons/fire_interval.svg"
		"magazine": return "res://assets/ui/icons/magazine.svg"
		"reload": return "res://assets/ui/icons/reload.svg"
		"range": return "res://assets/ui/icons/range.svg"
		"projectile_speed", "shots", "hits", "explosion_radius", "void_burst_radius", "splinter_count", "fragment_count": return "res://assets/ui/icons/launch.svg"
		"capacity": return "res://assets/ui/icons/shield.svg"
	return "res://assets/ui/icons/damage.svg"

func _equipment_comparison_rows(blueprint: Dictionary, current: Dictionary, next: Dictionary) -> Array:
	var keys: Array = []
	if str(blueprint.get("item_type","")) == "system":
		keys = [{"key":"capacity","label":"CAPACITY","suffix":""},{"key":"recharge","label":"RECHARGE","suffix":"/s"},{"key":"recharge_delay","label":"RESTART DELAY","suffix":"s"}]
	else:
		keys = [{"key":"damage","label":"IMPACT DAMAGE","suffix":""},{"key":"crit","label":"CRIT CHANCE","suffix":"%"},{"key":"interval","label":"FIRE INTERVAL","suffix":"s"},{"key":"shots","label":"PROJECTILES","suffix":""},{"key":"hits","label":"PENETRATION","suffix":""},{"key":"magazine","label":"MAGAZINE","suffix":""},{"key":"reload","label":"RELOAD","suffix":"s"},{"key":"range","label":"RANGE","suffix":""},{"key":"projectile_speed","label":"PROJECTILE SPEED","suffix":""}]
		if str(blueprint.get("id","")) == Equipment.MICRO_MISSILE_RACK_ID:
			keys += [{"key":"explosion_ratio","label":"EXPLOSION DAMAGE","suffix":"%"},{"key":"explosion_radius","label":"EXPLOSION RADIUS","suffix":""},{"key":"super_chance","label":"SUPER MISSILE","suffix":"%"},{"key":"splinter_count","label":"SPLINTERS","suffix":""},{"key":"fragment_count","label":"FRAGMENTS","suffix":""}]
		else:
			keys += [{"key":"fragments","label":"SHATTER BULLETS","suffix":""},{"key":"void_burst_ratio","label":"VOID BURST DAMAGE","suffix":"%"},{"key":"void_burst_radius","label":"VOID BURST RADIUS","suffix":""},{"key":"rampage","label":"RAMPAGE / HIT","suffix":"%"}]
	var rows_data: Array = []
	for entry in keys:
		var key := str(entry.key)
		if not current.has(key) and not next.has(key): continue
		var current_value := float(current.get(key,0))
		var next_value := float(next.get(key,0))
		var suffix := str(entry.suffix)
		var display_current := current_value
		var display_next := next_value
		if suffix == "%":
			display_current *= 100.0
			display_next *= 100.0
		rows_data.append({"key":key,"label":entry.label,"current":_format_equipment_stat(display_current,suffix),"next":_format_equipment_stat(display_next,suffix),"changed":not is_equal_approx(current_value,next_value)})
	return rows_data

func _format_equipment_stat(value: float, suffix: String) -> String:
	var digits := "%.2f" % value if suffix in ["s","/s"] else (str(int(value)) if is_equal_approx(value,round(value)) else "%.1f" % value)
	return digits + suffix

func _add_equipment_milestones(item: Dictionary, blueprint: Dictionary) -> void:
	var milestones: Dictionary = blueprint.get("milestones",{})
	if milestones.is_empty(): return
	var panel := _hangar_panel(Color("#06131f"),6)
	rows.add_child(panel)
	var canvas := Control.new()
	# Milestones belong to the screen's main ScrollContainer. Size this panel
	# from its content instead of nesting a second scrollable viewport inside it.
	var milestone_height := 88 * milestones.size() + 6 * maxi(0,milestones.size() - 1) + 56
	canvas.custom_minimum_size = Vector2(0,milestone_height) * rail_ui_factor
	panel.add_child(canvas)
	var backdrop := TextureRect.new()
	backdrop.texture = load("res://assets/ui/milestones/upgrade_milestone_vertical_v1.png")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate = Color(1,1,1,0.42)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(backdrop)
	var stack := VBoxContainer.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.add_theme_constant_override("separation",7 * rail_ui_factor)
	stack.add_theme_constant_override("margin_left",8 * rail_ui_factor)
	stack.add_theme_constant_override("margin_right",8 * rail_ui_factor)
	stack.add_theme_constant_override("margin_top",8 * rail_ui_factor)
	stack.add_theme_constant_override("margin_bottom",8 * rail_ui_factor)
	canvas.add_child(stack)
	var header := HBoxContainer.new()
	stack.add_child(header)
	header.add_child(_loadout_label("UPGRADE MILESTONES",13,Color("#d9f8ff")))
	var current_level := int(item.get("level",1))
	var header_status := _loadout_label("LV.%d  ·  %s" % [current_level,str(blueprint.get("name","MODULE")).to_upper()],11,Color("#87b9ca"))
	header_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(header_status)
	var track := VBoxContainer.new()
	track.name = "MilestoneVerticalTrack"
	track.add_theme_constant_override("separation",6 * rail_ui_factor)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	stack.add_child(track)
	var levels := []
	for key in milestones: levels.append(int(key))
	levels.sort()
	for level in levels:
		var definition: Dictionary = milestones.get(str(level),{})
		var tier := str(definition.get("tier","normal")).to_upper()
		var complete: bool = current_level >= level
		var epic := tier == "EPIC"
		var accent := Color("#ffbd73") if epic else Color("#73e5f5")
		var milestone := PanelContainer.new()
		milestone.custom_minimum_size = Vector2(0,88) * rail_ui_factor
		milestone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color("#102433",0.96) if complete else Color("#0a1722",0.94)
		card_style.border_color = Color(accent,0.96 if complete else 0.42)
		card_style.set_border_width_all(2 if complete else 1)
		card_style.corner_radius_top_left = 8
		card_style.corner_radius_top_right = 8
		card_style.corner_radius_bottom_left = 8
		card_style.corner_radius_bottom_right = 8
		card_style.shadow_color = Color(accent,0.22) if complete else Color.TRANSPARENT
		card_style.shadow_size = 8 if complete else 0
		milestone.add_theme_stylebox_override("panel",card_style)
		track.add_child(milestone)
		var content_margin := MarginContainer.new()
		content_margin.add_theme_constant_override("margin_left",8 * rail_ui_factor)
		content_margin.add_theme_constant_override("margin_right",8 * rail_ui_factor)
		content_margin.add_theme_constant_override("margin_top",5 * rail_ui_factor)
		content_margin.add_theme_constant_override("margin_bottom",5 * rail_ui_factor)
		milestone.add_child(content_margin)
		var content := HBoxContainer.new()
		content.add_theme_constant_override("separation",10 * rail_ui_factor)
		content_margin.add_child(content)
		var identity := VBoxContainer.new()
		identity.custom_minimum_size.x = 74 * rail_ui_factor
		identity.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content.add_child(identity)
		var badge := _detail_tag("%02d" % level,accent if complete else Color("#668391"))
		badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		identity.add_child(badge)
		var tier_label := _loadout_label(tier,9,accent if complete else Color("#79929e"))
		tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		identity.add_child(tier_label)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.size_flags_vertical = Control.SIZE_EXPAND_FILL
		details.add_theme_constant_override("separation",3 * rail_ui_factor)
		content.add_child(details)
		var title_color := Color("#ffbd73") if epic else (Color("#f1fbff") if complete else Color("#9bb1ba"))
		var title := _loadout_label(str(definition.get("title","UNKNOWN")).to_upper(),12,title_color)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_child(title)
		var rule := ColorRect.new()
		rule.color = Color(accent,0.72 if complete else 0.28)
		rule.custom_minimum_size = Vector2(0,1) * rail_ui_factor
		details.add_child(rule)
		var description := _loadout_label(str(definition.get("description","")),10,Color("#c8e2ea") if complete else Color("#78919d"))
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.size_flags_vertical = Control.SIZE_EXPAND_FILL
		details.add_child(description)
		var state := _loadout_label("UNLOCKED" if complete else "LOCKED",9,Color("#78efc7") if complete else Color("#6f8791"))
		state.size_flags_horizontal = Control.SIZE_SHRINK_END
		state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		content.add_child(state)

func _show_blueprints(game: Control) -> void:
	show_content("BLUEPRINTS","COLLECTION AND PROGRESSION",[],[],[])
	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation",5)
	rows.add_child(filters)
	for filter in ["weapons","systems","ships"]:
		filters.add_child(_hangar_button(filter.to_upper(),"blueprint_filter:%s" % filter,false,Color("#00e5ff") if game.hangar_blueprint_filter == filter else Color("#52768a")))
	if game.hangar_blueprint_filter == "ships":
		var ship: Dictionary = game._active_ship()
		rows.add_child(_hangar_button("%s\n%s · ACTIVE SHIP" % [str(ship.get("name","DRIFTER")).to_upper(),str(ship.get("rarity","normal")).to_upper()],"",true,Color("#75eaf5")))
	else:
		var type := "weapon" if game.hangar_blueprint_filter == "weapons" else "system"
		for blueprint_id in Equipment.EQUIPMENT:
			var blueprint: Dictionary = Equipment.definition(str(blueprint_id))
			if str(blueprint.get("item_type","")) != type: continue
			var unlocked: bool = game.profile.get("unlockedEquipmentBlueprints",[]).has(str(blueprint_id))
			var caption := "%s\n%s · %s" % [str(blueprint.get("name","UNKNOWN")).to_upper(),_blueprint_status(game,str(blueprint_id)),str(blueprint.get("damage_type",blueprint.get("item_type",""))).to_upper()]
			rows.add_child(_hangar_button(caption,"blueprint_detail:%s" % str(blueprint_id),false,Color("#00e5ff") if unlocked else Color("#597080")))
	footer.add_child(_hangar_button("BACK TO LOADOUT","back",false,Color("#8bbdcb")))
	_add_resume_run_button(game)

func _show_blueprint_detail(game: Control) -> void:
	var selected: String = game.hangar_selected_equipment
	var item: Dictionary = game.profile.equipmentItems.get(selected,{})
	var blueprint_id := str(item.get("blueprint_id",selected))
	var blueprint: Dictionary = Equipment.definition(blueprint_id)
	if blueprint.is_empty():
		game.menu_view = "blueprints"
		_show_blueprints(game)
		return
	show_content(str(blueprint.get("name","BLUEPRINT")).to_upper(),"BLUEPRINT DETAIL · %s" % _blueprint_status(game,blueprint_id),[],[],[])
	var display_item := {"id":"","blueprint_id":blueprint_id,"level":1}
	_add_equipment_card(game,rows,blueprint,display_item,"",true)
	rows.add_child(_card_label("LEVEL 1 PREVIEW\n%s" % _stat_summary(_equipment_stats(game,display_item,blueprint)),14,Color("#d7f7ff")))
	var owned_count := _owned_count_for_blueprint(game,blueprint_id)
	var buildable := blueprint.has("build_cost") and not Equipment.build_instance_id(blueprint_id).is_empty()
	var info := "LOCKED · %s" % str(blueprint.get("unlock",{}).get("type","UNKNOWN")).to_upper()
	if game.profile.get("unlockedEquipmentBlueprints",[]).has(blueprint_id):
		info = "BUILDING ADDS ONE NEW ITEM TO YOUR RESERVE" if buildable else "STARTER EQUIPMENT IS MANAGED FROM LOADOUT"
		if owned_count > 0: info += " · OWNED %d" % owned_count
	rows.add_child(_card_label(info,13,Color("#c2dce6")))
	var locked := _hangar_locked(game)
	if buildable and game.profile.get("unlockedEquipmentBlueprints",[]).has(blueprint_id):
		var requirements := _add_blueprint_build_requirements(game,blueprint)
		var caption := "BUILD TO RESERVE" if owned_count == 0 else "BUILD ANOTHER"
		footer.add_child(_hangar_button(caption,"build_equipment:%s" % blueprint_id,locked or not bool(requirements.affordable),Color("#00e5ff")))
	footer.add_child(_hangar_button("BACK TO BLUEPRINTS","back",false,Color("#8bbdcb")))
	_add_resume_run_button(game)

func _owned_count_for_blueprint(game: Control, blueprint_id: String) -> int:
	var count := 0
	for item_id in game.profile.get("equipmentInventory",[]):
		var candidate: Dictionary = game.profile.equipmentItems.get(str(item_id),{})
		if str(candidate.get("blueprint_id","")) == blueprint_id: count += 1
	return count

func _add_blueprint_build_requirements(game: Control, blueprint: Dictionary) -> Dictionary:
	var cost: Dictionary = blueprint.get("build_cost",{})
	var required_coins := float(cost.get("coins",0.0))
	var required_modules := int(cost.get("modules",0))
	var owned_coins := float(game.profile.get("totalCoins",0.0))
	var owned_modules := int(game.profile.get("railgunModules",0))
	var coins_ready := owned_coins >= required_coins
	var modules_ready := owned_modules >= required_modules
	var affordable := coins_ready and modules_ready
	var panel := _hangar_panel(Color("#071923"),10)
	rows.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",8 * rail_ui_factor)
	panel.add_child(stack)
	stack.add_child(_loadout_label("BUILD REQUIREMENTS",14,Color("#dffaff")))
	_add_build_cost_row(stack,CurrencyUI.currency_path("credits"),"CREDITS",_format_build_amount(owned_coins),_format_build_amount(required_coins),coins_ready)
	_add_build_cost_row(stack,CurrencyUI.currency_path("boss_module"),"BOSS MODULES",str(owned_modules),str(required_modules),modules_ready)
	var state_text := "READY · ITEM WILL BE ADDED TO RESERVE"
	var state_color := Color("#69f0bc")
	if _hangar_locked(game):
		state_text = "BUILD LOCKED DURING ACTIVE RUN"
		state_color = Color("#ffe080")
	elif not affordable:
		var missing := []
		if not coins_ready: missing.append("%s CREDITS" % _format_build_amount(required_coins-owned_coins))
		if not modules_ready: missing.append("%d BOSS MODULES" % (required_modules-owned_modules))
		state_text = "MISSING · %s" % " · ".join(missing)
		state_color = Color("#ffb36a")
	stack.add_child(_card_label(state_text,12,state_color))
	return {"affordable":affordable,"cost":cost}

func _add_build_cost_row(parent: Control, icon_path: String, label: String, owned: String, required: String, ready: bool) -> void:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation",8 * rail_ui_factor)
	parent.add_child(line)
	var icon := TextureRect.new()
	icon.texture = load(icon_path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(24,24) * rail_ui_factor
	icon.modulate = Color("#69f0bc") if ready else Color("#ffb36a")
	line.add_child(icon)
	var name := _loadout_label(label,12,Color("#a9c6d8"))
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(name)
	var amount := _loadout_label("%s / %s" % [owned,required],14,Color("#69f0bc") if ready else Color("#ffb36a"))
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.add_child(amount)

func _format_build_amount(value: float) -> String:
	var digits := str(maxi(0,roundi(value)))
	var formatted := ""
	var group_index := 0
	for index in range(digits.length()-1,-1,-1):
		if group_index > 0 and group_index % 3 == 0: formatted = "," + formatted
		formatted = digits[index] + formatted
		group_index += 1
	return formatted

func _hangar_panel(color: Color, padding := 4) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",UI.panel(color,0.95,7,1))
	panel.add_theme_constant_override("content_margin_left",padding)
	panel.add_theme_constant_override("content_margin_right",padding)
	panel.add_theme_constant_override("content_margin_top",padding)
	panel.add_theme_constant_override("content_margin_bottom",padding)
	var style := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.border_color = Color("#315f73")
	style.border_width_left = 3
	panel.add_theme_stylebox_override("panel",style)
	return panel

func _hangar_button(text: String, action: String, disabled: bool, accent: Color, icon_path := "") -> Button:
	var control := button(text,action,disabled)
	control.custom_minimum_size.y = 70 * rail_ui_factor
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		control.icon = load(icon_path)
	var style := control.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	style.bg_color = Color(0.03,0.10,0.16,0.94)
	style.border_color = Color(accent,0.9)
	style.set_border_width_all(2)
	control.add_theme_stylebox_override("normal",style)
	return control

func _hangar_permanent_level(game: Control, id: String) -> int:
	return Upgrades.level(id, game.profile.get("permanentUpgrades", {}), {})

func _hangar_stat_value(game: Control, id: String) -> float:
	return game._armor_damage_reduction() if id == "armor" else game._stat(id)

func _add_hangar_stat_row(parent: Control, game: Control, label: String, icon_path: String, stat_id: String, accent: Color) -> void:
	var row := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#071b2b")
	style.border_color = Color("#255a72")
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 8 * rail_ui_factor
	style.content_margin_right = 8 * rail_ui_factor
	style.content_margin_top = 5 * rail_ui_factor
	style.content_margin_bottom = 5 * rail_ui_factor
	row.add_theme_stylebox_override("panel", style)
	row.custom_minimum_size.y = 48 * rail_ui_factor
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8 * rail_ui_factor)
	row.add_child(line)
	var icon := TextureRect.new()
	icon.texture = load(icon_path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(32, 32) * rail_ui_factor
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(icon)
	var title := _loadout_label(label, 14, Color("#dffaff"))
	title.custom_minimum_size.x = 72 * rail_ui_factor
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(title)
	var bar := HangarSegmentedBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.custom_minimum_size.y = 20 * rail_ui_factor
	var level := _hangar_permanent_level(game, stat_id)
	bar.set_progress(float(level) / maxf(1.0, float(Upgrades.definition(stat_id).get("cap", 1))), accent)
	line.add_child(bar)
	var value := _hangar_stat_value(game, stat_id)
	var shield_module_equipped: bool = bool(game._has_equipped_blueprint(game.EquipmentRegistry.SHIELD_CORE_ID))
	var display_value := "NO MODULE" if stat_id in ["shield_capacity", "shield_recharge"] and not shield_module_equipped else _format_hangar_stat(stat_id, value)
	var number := _loadout_label(display_value, 16, Color("#ffbd72") if display_value == "NO MODULE" else Color("#e9fbff"))
	number.custom_minimum_size.x = 48 * rail_ui_factor
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	number.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(number)

func _format_hangar_stat(stat_id: String, value: float) -> String:
	if stat_id == "armor": return "%d%%" % roundi(value * 100.0)
	return str(int(round(value))) if is_equal_approx(value, round(value)) else "%.1f" % value

func _add_reserve_summary(game: Control) -> void:
	rows.add_child(_card_label("RESERVE INVENTORY",15,Color("#8bbdcb")))
	var reserve := Loadouts.reserve_items(game.profile)
	var panel := _hangar_panel(Color("#071723"),6)
	panel.custom_minimum_size.y = 104 * rail_ui_factor if reserve.is_empty() else 0.0
	rows.add_child(panel)
	if reserve.is_empty():
		var words := VBoxContainer.new(); panel.add_child(words)
		words.add_child(_card_label("NO EQUIPMENT IN RESERVE",13,Color("#d7f7ff")))
		words.add_child(_card_label("Build a blueprint to add compatible equipment here.",11,Color("#9fb8c2")))
		words.add_child(_hangar_button("VIEW BLUEPRINTS","view_blueprints:weapons",_hangar_locked(game),Color("#b965ff"),"res://assets/ui/icons/blueprints.svg"))
		return
	var grid := GridContainer.new(); grid.columns = 2; grid.add_theme_constant_override("h_separation",6); grid.add_theme_constant_override("v_separation",6); panel.add_child(grid)
	for item_id in reserve:
		var item: Dictionary = game.profile.equipmentItems.get(item_id,{})
		var blueprint: Dictionary = Equipment.definition(str(item.get("blueprint_id","")))
		_add_equipment_card(game,grid,blueprint,item,"",true)

func _add_equipment_card(game: Control, parent: Control, blueprint: Dictionary, item: Dictionary, action: String, disabled: bool) -> void:
	var accent := Color("#b965ff") if str(blueprint.get("item_type","")) == "system" else (Color("#ffbf42") if str(blueprint.get("damage_type","")) == "explosive" else Color("#00e5ff"))
	var shell := _hangar_panel(Color("#081926"),5)
	parent.add_child(shell)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation",8)
	shell.add_child(line)
	var art_path := str(blueprint.get("art",""))
	if not art_path.is_empty() and ResourceLoader.exists(art_path):
		var image := TextureRect.new()
		image.texture = load(art_path)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.custom_minimum_size = Vector2(72,72) * rail_ui_factor
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(image)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(words)
	words.add_child(_card_label(str(blueprint.get("name","UNKNOWN")).to_upper(),16,Color("#effcff")))
	words.add_child(_card_label("%s · %s" % [str(blueprint.get("rarity","normal")).to_upper(),str(blueprint.get("family",blueprint.get("damage_type",blueprint.get("item_type","")))).to_upper()],11,accent))
	if not item.is_empty():
		var level := int(item.get("level",1))
		words.add_child(_card_label("Lv.%d  ·  %s" % [level,_stat_summary(_equipment_stats(game,item,blueprint))],11,Color("#b9dbe4")))
	if not action.is_empty():
		var tap := Button.new()
		tap.flat = true
		tap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tap.disabled = disabled
		for state in ["normal","hover","pressed","disabled"]: tap.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		tap.pressed.connect(func(): selected.emit(action))
		shell.add_child(tap)

func _loadout_slot_accent(blueprint: Dictionary, empty: bool) -> Color:
	return UI.rarity_color(str(blueprint.get("rarity","normal")), empty)

func _loadout_slot_style(accent: Color, empty: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	# The visible border is the reusable vector frame below. Keeping this shell
	# borderless prevents the unwanted double-outline around equipment bays.
	style.bg_color = UI.INK if empty else UI.SURFACE
	style.border_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	return style

func _loadout_label(text: String, font_size: int, color: Color) -> Label:
	var label := UI.label(text, font_size, color, true)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_color_override("font_outline_color",color.darkened(0.2))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _loadout_bold_display_font() -> FontVariation:
	return UI.font(true)

func _loadout_name_lines(name: String) -> String:
	var words := name.to_upper().split(" ",false)
	if words.size() < 2 or name.length() <= 12: return name.to_upper()
	var split_at := ceili(float(words.size()) / 2.0)
	return " ".join(words.slice(0,split_at)) + "\n" + " ".join(words.slice(split_at))

func _add_loadout_slot_card(parent: Control, slot: Dictionary, blueprint: Dictionary, item: Dictionary, _section_accent: Color, is_selected := false, compact := false, slot_enabled := true) -> void:
	var empty := item.is_empty()
	if empty: slot_enabled = false
	var accent := _loadout_slot_accent(blueprint,empty)
	var glow_color := _loadout_detail_glow_color(blueprint)
	var shell := PanelContainer.new()
	shell.name = "LoadoutSlot_%s" % str(slot.get("id", ""))
	var shell_style := _loadout_slot_style(accent,empty)
	if is_selected and not empty:
		shell_style.bg_color = Color(glow_color,0.24)
		shell_style.shadow_color = Color(glow_color,0.40)
		shell_style.shadow_size = 14
	shell.add_theme_stylebox_override("panel",shell_style)
	shell.custom_minimum_size.y = (108 if compact else 112) * rail_ui_factor
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	parent.add_child(shell)
	var frame := TextureRect.new()
	frame.texture = load("res://assets/ui/components/equipment_slot_frame.svg")
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	var state_alpha := 0.34 if not slot_enabled and not empty else (0.58 if empty else (1.0 if is_selected else 0.84))
	frame.modulate = Color(accent,state_alpha)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.add_child(frame)
	# The card-wide selection hit area must be behind every visible child so the
	# module switch remains an independent, clickable control.
	var tap := Button.new()
	tap.flat = true
	tap.mouse_filter = Control.MOUSE_FILTER_PASS
	tap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for state in ["normal","hover","pressed","disabled"]: tap.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	tap.pressed.connect(func(): selected.emit("hangar_slot:%s" % str(slot.get("id",""))))
	shell.add_child(tap)
	var padding := MarginContainer.new()
	var inset_left := 16.0 if compact else 20.0
	var inset_right := 8.0 if compact else 20.0
	padding.add_theme_constant_override("margin_left",inset_left * rail_ui_factor)
	padding.add_theme_constant_override("margin_right",inset_right * rail_ui_factor)
	padding.add_theme_constant_override("margin_top",8 * rail_ui_factor if compact else 14 * rail_ui_factor)
	padding.add_theme_constant_override("margin_bottom",8 * rail_ui_factor if compact else 14 * rail_ui_factor)
	shell.add_child(padding)
	# Keep the slot hierarchy horizontal even in compact mode: bay code, socket,
	# and equipment label should remain readable beside each other.
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation",4 * rail_ui_factor if compact else 12 * rail_ui_factor)
	padding.add_child(line)
	var slot_code := _loadout_label(str(slot.get("id","")).to_upper(),13 if compact else 20,accent)
	slot_code.custom_minimum_size = Vector2(26 if compact else 38,0) * rail_ui_factor
	slot_code.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_code.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(slot_code)
	var socket := PanelContainer.new()
	var socket_style := StyleBoxFlat.new()
	socket_style.bg_color = Color("#091720")
	socket_style.border_color = Color.TRANSPARENT
	socket_style.set_border_width_all(0)
	socket.add_theme_stylebox_override("panel",socket_style)
	socket.custom_minimum_size = Vector2(44 if compact else 82,44 if compact else 82) * rail_ui_factor
	socket.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	socket.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(socket)
	if empty:
		var socket_frame := TextureRect.new()
		socket_frame.texture = load("res://assets/ui/components/equipment_socket_frame.svg")
		socket_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		socket_frame.stretch_mode = TextureRect.STRETCH_SCALE
		socket_frame.modulate = Color(accent,0.48)
		socket_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		socket_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		socket.add_child(socket_frame)
		var plus := _loadout_label("+",22 if compact else 42,Color("#90a9bb"))
		plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		socket.add_child(plus)
	else:
		var art_path := str(blueprint.get("slot_art",blueprint.get("art","")))
		if ResourceLoader.exists(art_path):
			var image := TextureRect.new()
			image.texture = load(art_path)
			image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			image.mouse_filter = Control.MOUSE_FILTER_IGNORE
			image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,Control.PRESET_MODE_MINSIZE,12 * rail_ui_factor)
			socket.add_child(image)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.custom_minimum_size.x = 0.0
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	if compact: words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(words)
	if empty:
		words.add_child(_loadout_label("EMPTY",10 if compact else 18,Color("#b9cbd4")))
	else:
		# Names deliberately remain compact: even long equipment names read in two
		# lines without changing the fixed height of a touch-friendly slot card.
		var module_color := Color("#718894") if not slot_enabled else Color("#f2fdff")
		words.add_child(_loadout_label(_loadout_name_lines(str(blueprint.get("name","UNKNOWN"))),10 if compact else 15,module_color))
		words.add_child(_loadout_label("Lv.%d" % int(item.get("level",1)),11 if compact else 16,accent))
	if not empty:
		# A quiet pill keeps the enabled state visible without competing with the
		# module name. The dot acts as the thumb and shifts with the state.
		var toggle := PanelContainer.new()
		toggle.tooltip_text = "Disable this slot during the run" if slot_enabled else "Enable this slot during the run"
		toggle.custom_minimum_size = Vector2(32 if compact else 38,14 if compact else 16) * rail_ui_factor
		toggle.size_flags_horizontal = Control.SIZE_SHRINK_END
		toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var toggle_style := StyleBoxFlat.new()
		toggle_style.bg_color = Color("#123b43") if slot_enabled else Color("#1a2630")
		toggle_style.border_color = Color("#69efc2") if slot_enabled else Color("#536a76")
		toggle_style.set_border_width_all(1)
		toggle_style.set_corner_radius_all(8)
		toggle.add_theme_stylebox_override("panel",toggle_style)
		var knob := Label.new()
		knob.text = "●"
		knob.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if slot_enabled else HORIZONTAL_ALIGNMENT_LEFT
		knob.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		knob.add_theme_font_size_override("font_size",8 if compact else 9)
		knob.add_theme_color_override("font_color",Color("#8ff6d1") if slot_enabled else Color("#718894"))
		toggle.add_child(knob)
		toggle.gui_input.connect(func(event):
			if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
				selected.emit("toggle_slot:%s" % str(slot.get("id","")))
		)
		line.add_child(toggle)

func _equipment_stats(game: Control, item: Dictionary, blueprint: Dictionary) -> Dictionary:
	if str(blueprint.get("item_type","")) == "weapon": return game._weapon_runtime_stats({"item":item,"blueprint":blueprint})
	if str(item.get("blueprint_id","")) == Equipment.SHIELD_CORE_ID:
		return Equipment.shield_core_stats(int(item.get("level",1)),{"capacity":float(item.get("legacy_capacity_bonus",0.0)),"recharge":float(item.get("legacy_recharge_bonus",0.0))})
	return Equipment.stats_for(str(item.get("blueprint_id","")),int(item.get("level",1)))

func _next_stat_summary(game: Control, item: Dictionary, blueprint: Dictionary) -> String:
	var cap := ModuleProgression.level_cap(str(item.get("rarity","common")))
	if int(item.get("level",1)) >= cap: return "MAX LEVEL"
	var advanced: Dictionary = item.duplicate(true)
	advanced.level = int(advanced.get("level",1)) + 1
	return _stat_summary(_equipment_stats(game,advanced,blueprint))

func _stat_summary(stats: Dictionary) -> String:
	var values := []
	for key in ["damage","crit","explosion_ratio","explosion_radius","void_burst_ratio","void_burst_radius","capacity","recharge","recharge_delay","interval","shots","hits","magazine","reload","range","projectile_speed","fragments","splinter_count","fragment_count"]:
		if not stats.has(key): continue
		var value = stats[key]
		var shown := float(value) * 100.0 if key in ["crit","explosion_ratio","void_burst_ratio"] else float(value)
		values.append("%s %s%s" % [key.to_upper(),"%.1f" % shown if value is float else str(value),"%" if key in ["crit","explosion_ratio","void_burst_ratio"] else ""])
	return " · ".join(values) if not values.is_empty() else "NO VARIABLE STATS"

func _next_milestone(blueprint: Dictionary, level: int) -> String:
	var milestones: Dictionary = blueprint.get("milestones",{})
	var candidates := []
	for key in milestones:
		if int(key) > level: candidates.append(int(key))
	if candidates.is_empty(): return "NO FURTHER MILESTONES"
	candidates.sort()
	var next: int = int(candidates[0])
	return "Lv.%d · %s" % [next,_milestone_text(milestones.get(str(next),""))]

func _milestone_text(value: Variant) -> String:
	if value is String: return str(value)
	if value is Dictionary:
		var changes := []
		for key in value: changes.append("%s %s" % [str(key).to_upper(),str(value[key])])
		return " · ".join(changes)
	return str(value)

func _blueprint_status(game: Control, blueprint_id: String) -> String:
	if not game.profile.get("unlockedEquipmentBlueprints",[]).has(blueprint_id): return "LOCKED"
	var owned := []
	for item_id in game.profile.get("equipmentInventory",[]):
		if str(game.profile.equipmentItems.get(item_id,{}).get("blueprint_id","")) == blueprint_id: owned.append(str(item_id))
	if owned.is_empty(): return "UNLOCKED"
	if owned.size() > 1: return "OWNED x%d" % owned.size()
	for item_id in owned:
		if not Loadouts.reserve_items(game.profile).has(item_id): return "EQUIPPED"
	return "IN RESERVE"

func _set_choice_overlay_style() -> void:
	var panel_style := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	panel_style.bg_color = Color(0.0,0.0,0.0,0.0)
	panel_style.border_color = Color(0.0,0.0,0.0,0.0)
	panel_style.set_border_width_all(0)
	panel_style.content_margin_left = 6 * rail_ui_factor
	panel_style.content_margin_right = 6 * rail_ui_factor
	panel_style.content_margin_top = 6 * rail_ui_factor
	panel_style.content_margin_bottom = 6 * rail_ui_factor
	add_theme_stylebox_override("panel",panel_style)

func _set_default_overlay_style() -> void:
	var panel_style := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	panel_style.bg_color = Color(0.035,0.04,0.10,0.96)
	panel_style.border_color = Color("#8bbdcb")
	panel_style.set_border_width_all(1)
	panel_style.content_margin_left = 8
	panel_style.content_margin_right = 8
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	add_theme_stylebox_override("panel",panel_style)

func _add_collection_row(state: Dictionary, level: int) -> void:
	var heading := _card_label("CURRENT LOADOUT",11,Color("#69e6f5"))
	var collection := VBoxContainer.new()
	collection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	purchase_options.visible = true
	purchase_options.add_child(collection)
	collection.add_child(heading)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",4 * rail_ui_factor)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection.add_child(row)
	_add_collection_card(row,{"art_key":"hero"},1,Cards.stars(state))
	for index in range(4): _add_collection_card(row,{},0)

func _collection_shell() -> PanelContainer:
	var shell := PanelContainer.new()
	shell.clip_contents = true
	# Five equal slots span precisely the same content width as the three-card grid.
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.custom_minimum_size = Vector2.ONE * choice_loadout_slot_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.01,0.05,0.08,0.22)
	style.border_color = Color(0.32,0.84,0.92,0.82)
	style.set_border_width_all(2)
	style.border_width_bottom = 2
	style.set_content_margin_all(4 * rail_ui_factor)
	style.corner_radius_top_left = 8
	style.corner_radius_bottom_right = 8
	shell.add_theme_stylebox_override("panel",style)
	return shell

func _add_collection_card(parent: Control, entry: Dictionary, rank: int, stars := "") -> void:
	var shell := _collection_shell()
	parent.add_child(shell)
	if entry.is_empty(): return
	var frame := Control.new()
	# PanelContainer applies the inset, leaving the cyan border visible around art.
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shell.add_child(frame)
	var image := portrait(entry.art_key,0)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_child(image)
	var star_label := _card_label("[center]%s[/center]" % (stars if not stars.is_empty() else "★".repeat(mini(4,rank))+"☆".repeat(maxi(0,4-rank))),10,Color("#d9f8ff"))
	star_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	star_label.position.y = -18 * rail_ui_factor
	star_label.size.y = 18 * rail_ui_factor
	star_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(star_label)


# Permanent upgrade UI only; both previews use the same weapon calculation as combat.
func _show_upgrade(game: Control, level: int) -> void:
	var item: Dictionary = game._railgun_instance()
	var rarity := str(item.get("rarity", "common")).to_upper()
	var cap := 40 if rarity == "COMMON" else 80
	show_content("[center]RAILGUN  Lv.%d[/center]" % level,"%s MODULE" % rarity,[],[],[])
	var current: Dictionary = game._railgun_stats()
	var next_item := item.duplicate(true)
	next_item.level = mini(cap, level + 1)
	var upcoming := current.duplicate(true)
	if level < cap:
		var railgun_base := Equipment.railgun_stats(int(next_item.level))
		var next_base := {"damage":Equipment.damage_from_ship(Equipment.RAILGUN_ID,int(next_item.level),game._stat("damage")),"interval":float(railgun_base.get("fire_interval",500.0)) / 1000.0,"magazine":int(railgun_base.get("magazine",6)),"reload":float(railgun_base.get("reload",3.0)),"range":game._stat("range"),"projectile_speed":1600.0,"shots":1,"crit":game._stat("crit_chance"),"crit_multiplier":2.0,"width":1.0,"hits":1,"fragments":0,"rampage":0.0}
		upcoming = WeaponStats.resolve(Equipment.RAILGUN_ID,"railgun",int(next_item.level),next_base,{},game._stat("crit_chance"))
	var intro := HBoxContainer.new()
	intro.add_theme_constant_override("separation",12)
	rows.add_child(intro)
	var image := portrait("hero",88)
	image.custom_minimum_size = Vector2.ONE * 88 * rail_ui_factor
	image.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	image.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	intro.add_child(image)
	var description := _card_label("Fires automatically. Every five module levels unlocks a permanent Railgun milestone; no run cards or random offers.",13,Color("#b5dce5"))
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	intro.add_child(description)
	var improvements := _add_stat_grid(rows,current,upcoming)
	for milestone in [5,10,15,20]:
		var unlocked: bool = level >= milestone
		rows.add_child(_card_label("%s  ·  %s" % ["UNLOCKED" if unlocked else "LOCKED Lv.%d" % milestone, str(Equipment.definition(Equipment.RAILGUN_ID).milestones[str(milestone)])],12,Color("#69f0bc") if unlocked else Color("#96acbb")))
	var improvement := "Common mastery reached" if level >= cap else "Next upgrade: " + ", ".join(improvements)
	footer.add_child(_card_label("[center]%s[/center]" % improvement,13,Color("#69f0bc")))
	var cost := Equipment.upgrade_cost(Equipment.RAILGUN_ID,level)
	var blocked: bool = level >= cap or not game.profile.activeRun.is_empty() or game.status not in ["menu","dead"] or game.profile.totalCoins < cost.coins or game.profile.railgunModules < cost.modules
	var actions := HBoxContainer.new()
	footer.add_child(actions)
	var upgrade := button("Common Mastery" if level >= cap else "Upgrade","railgun_buy",blocked)
	upgrade.size_flags_stretch_ratio = 2.0
	for state in ["normal","hover","pressed","disabled"]:
		var style := upgrade.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		style.bg_color = Color("#f5bf18") if not blocked else Color("#766326")
		style.border_color = Color("#ffdf72") if not blocked else Color("#ac9142")
		style.corner_radius_top_left = 8
		style.corner_radius_bottom_right = 8
		style.corner_detail = 1
		upgrade.add_theme_stylebox_override(state,style)
		upgrade.add_theme_color_override("font_"+state+"_color",Color("#172432") if not blocked else Color("#e0d3a8"))
	upgrade.add_theme_color_override("font_color",Color("#172432"))
	actions.add_child(upgrade)
	var currencies := HBoxContainer.new()
	footer.add_child(currencies)
	for currency in [["◈",game.profile.totalCoins,cost.coins],["▣",game.profile.railgunModules,cost.modules]]:
		var amount := str(int(currency[1]))
		if level < cap and currency[1] < currency[2]: amount = "[color=#ff8585]"+amount+"[/color]"
		var text := "%s  %s / %s" % [currency[0],amount,str(int(currency[2])) if level < cap else "--"]
		var label := _card_label("[center]%s[/center]" % text,12,Color("#c4e2e9"))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		currencies.add_child(label)
	if not game.profile.activeRun.is_empty() and level < cap:
		footer.add_child(_card_label("Finish the current run to upgrade.",11,Color("#ffe080")))
	var navigation := HBoxContainer.new()
	footer.add_child(navigation)
	var back := button("Back","back")
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.custom_minimum_size.x = 64 * rail_ui_factor
	navigation.add_child(back)
	if game.save_error:
		navigation.add_child(_card_label("Save failed. Retry save.",11,Color("#ff8585")))
		navigation.add_child(button("Retry Save","save"))
	set_ui_factor(rail_ui_factor)

func _add_stat_grid(parent: Control, current: Dictionary, upcoming: Dictionary = {}) -> Array[String]:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",6)
	parent.add_child(grid)
	var improvements: Array[String] = []
	for item in [["Damage","damage"],["Crit","crit"],["Magazine","magazine"],["Reload","reload"],["Projectiles","shots"],["Piercing","hits"]]:
		var key: String = item[1]
		var value := _stat_value(key,float(current[key]))
		if not upcoming.is_empty():
			var delta := float(upcoming[key])-float(current[key])
			if not is_zero_approx(delta):
				var change := ("+" if delta > 0 else "-") + _stat_value(key,absf(delta),true)
				var better := delta < 0 if key == "reload" else delta > 0
				value += " [color=%s]%s[/color]" % ["#69f0bc" if better else "#ff8585",change]
				improvements.append("%s %s" % [item[0],change])
		var tile := _upgrade_panel(Color("#172f40"))
		grid.add_child(tile)
		var stack := VBoxContainer.new()
		stack.add_theme_constant_override("separation",2)
		tile.add_child(stack)
		var strip := _upgrade_panel(Color("#24485a"),2)
		stack.add_child(strip)
		strip.add_child(_card_label("[center]%s[/center]" % item[0],11,Color("#bbd4de")))
		stack.add_child(_card_label("[center]%s[/center]" % value,15,Color("#d5f2f6")))
	return improvements

func _stat_value(key: String, value: float, difference := false) -> String:
	match key:
		"damage": return ("%.2f" % value).trim_suffix("0").trim_suffix(".")
		"crit": return "%.0f%%" % (value*100)
		"reload": return "%.2fs" % value
		"hits": return str(int(value) if difference else maxi(0,int(value)-1))
	return str(int(value))

func _card_title_plate(text: String, accent: Color) -> PanelContainer:
	var plate := PanelContainer.new()
	# Keep every card body aligned, including titles that wrap on narrow screens.
	plate.custom_minimum_size.y = 54 * rail_ui_factor
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent,0.12)
	style.border_color = Color(accent,0.82)
	style.border_width_bottom = 2
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 0
	style.content_margin_left = 8 * rail_ui_factor
	style.content_margin_right = 8 * rail_ui_factor
	style.content_margin_top = 4 * rail_ui_factor
	style.content_margin_bottom = 4 * rail_ui_factor
	plate.add_theme_stylebox_override("panel",style)
	var label := _card_label("[b]%s[/b]" % text,8 if not wide_cards else 10,Color("#f3fbff"))
	label.fit_content = false
	label.custom_minimum_size.y = 46 * rail_ui_factor
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plate.add_child(label)
	return plate

func _add_card(parent: Control, entry: Dictionary, action: String, detail: String, level: int, state: Dictionary) -> void:
	var accent := Color("#d697ff") if entry.epic else Color("#81deef")
	var locked := not Cards.is_unlocked(entry,level,preserved_unlocks)
	var shell := PanelContainer.new()
	shell.clip_contents = true
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14,0.11,0.22,0.52) if entry.epic else Color(0.03,0.13,0.18,0.46)
	style.border_color = accent.darkened(0.35) if locked else accent
	style.set_border_width_all(2)
	style.corner_radius_top_left = 7
	style.corner_radius_bottom_right = 7
	# Keep artwork flush to the inner edge while reserving the border pixels.
	style.set_content_margin_all(2 * rail_ui_factor)
	style.shadow_color = Color(accent,0.12)
	style.shadow_size = 5 if entry.epic else 0
	shell.add_theme_stylebox_override("panel",style)
	parent.add_child(shell)
	if entry.epic and not locked and action.begins_with("card:"):
		var pulse := shell.create_tween().set_loops()
		pulse.tween_property(style,"border_color",accent.lightened(0.35),0.9)
		pulse.tween_property(style,"border_color",accent,0.9)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation",0)
	shell.add_child(content)
	var title := str(entry.name)
	var rank := int(state.ranks.get(entry.id,0))
	if rank > 0: title += "  " + (["I","II","III","IV"][mini(3,rank-1)] if entry.epic else "+%d" % rank)
	content.add_child(_card_title_plate(title,accent))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation",0)
	content.add_child(body)
	var image := portrait(entry.art_key,choice_card_art_size / rail_ui_factor)
	if locked: image.modulate = Color(0.35,0.4,0.45)
	body.add_child(image)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.custom_minimum_size.y = 44 * rail_ui_factor
	var text_inset := MarginContainer.new()
	text_inset.add_theme_constant_override("margin_left",8 * rail_ui_factor)
	text_inset.add_theme_constant_override("margin_right",8 * rail_ui_factor)
	text_inset.add_theme_constant_override("margin_top",4 * rail_ui_factor)
	text_inset.add_theme_constant_override("margin_bottom",6 * rail_ui_factor)
	text_inset.add_child(words)
	body.add_child(text_inset)
	# Every screen uses the same card body; rank only changes the title.
	var cap := Cards.effective_cap(entry)
	var cap_text := "  ·  MAX %d" % cap if cap > 0 else ""
	var effect := _card_label(entry.short_effect + cap_text,11 if not wide_cards else 13,Color("#dfedf4"))
	effect.fit_content = false
	effect.custom_minimum_size.y = (32 if not wide_cards else 36) * rail_ui_factor
	words.add_child(effect)
	if not detail.is_empty(): words.add_child(_card_label(detail,13,Color("#8df5cb")))
	if not action.is_empty():
		# The entire card is a target; all labels ignore input so text/art clicks select too.
		_ignore_input(shell)
		shell.mouse_filter = Control.MOUSE_FILTER_PASS
		shell.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		shell.gui_input.connect(_card_input.bind(shell,action))
		shell.focus_mode = Control.FOCUS_ALL
		var focus := style.duplicate() as StyleBoxFlat
		focus.border_color = Color("#edc254")
		focus.set_border_width_all(2)
		shell.add_theme_stylebox_override("focus",focus)
		shell.mouse_entered.connect(func(): shell.modulate = Color(1.1,1.1,1.1))
		shell.mouse_exited.connect(func(): shell.modulate = Color.WHITE)

func _card_input(event: InputEvent, shell: Control, action: String) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT or event is InputEventScreenTouch:
		if event.pressed:
			shell.set_meta("press_start",event.position)
		elif shell.has_meta("press_start"):
			var start: Vector2 = shell.get_meta("press_start")
			shell.remove_meta("press_start")
			if start.distance_to(event.position)<12.0:
				shell.accept_event()
				selected.emit(action)
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		if shell.has_meta("press_start") and Vector2(shell.get_meta("press_start")).distance_to(event.position)>=12.0:
			shell.remove_meta("press_start")
	elif event.is_action_pressed("ui_accept"):
		shell.accept_event()
		selected.emit(action)

func _ignore_input(node: Node) -> void:
	if node is Control: node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children(): _ignore_input(child)

func _focus_if_live(control: Control) -> void:
	if is_instance_valid(control) and control.is_inside_tree(): control.grab_focus()
