extends Control

const Equipment := preload("res://scripts/systems/equipment_registry.gd")
const UI := preload("res://scripts/systems/ui_design_system.gd")

var ship_definition: Dictionary = {}
var profile: Dictionary = {}
var slot_cards: Array[PanelContainer] = []
var slot_data: Array[Dictionary] = []
var ship_rect := Rect2()
var connector_points: Array[Dictionary] = []
var mounted_art: Array[Dictionary] = []
var slot_markers: Array[Dictionary] = []
var show_slot_cards := true
var idle_time := 0.0

func configure(definition: Dictionary, current_profile: Dictionary, include_slot_cards := true) -> void:
	ship_definition = definition
	profile = current_profile
	show_slot_cards = include_slot_cards
	# The overview is a ship showcase, while the legacy hardpoint view is an editor.
	# Give the showcase enough room to read as a hero composition instead of a tiny
	# ship surrounded by editor chrome.
	custom_minimum_size = Vector2(280,430 if show_slot_cards else 320)
	_build()

func _build() -> void:
	for child in get_children(): child.queue_free()
	slot_cards.clear(); slot_data.clear(); connector_points.clear(); mounted_art.clear(); slot_markers.clear()
	var ship := TextureRect.new()
	ship.name = "ShipArt"
	ship.texture = load(str(ship_definition.get("art",{}).get("hangar","")))
	ship.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ship.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ship.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ship)
	var loadout: Dictionary = profile.get("ships",{}).get(str(ship_definition.id),{}).get("loadout",{})
	for hardpoint in ship_definition.get("slots",[]):
		var instance_id := str(loadout.get(str(hardpoint.id),""))
		var instance: Dictionary = profile.get("equipmentItems",{}).get(instance_id,{})
		var equipment := Equipment.definition(str(instance.get("blueprint_id","")))
		if not show_slot_cards:
			if not equipment.is_empty():
				_add_mounted_equipment(hardpoint,equipment)
			_add_slot_marker(hardpoint)
			continue
		var panel := PanelContainer.new()
		panel.name = "Slot_%s" % hardpoint.id
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var accent := UI.CYAN if str(hardpoint.type)=="weapon" else UI.VIOLET
		var style := StyleBoxFlat.new()
		style.bg_color = Color(UI.SURFACE,0.96); style.border_color = Color(accent,0.76); style.set_border_width_all(2); style.corner_radius_top_left = 7; style.corner_radius_bottom_right = 7; style.set_content_margin_all(4)
		panel.add_theme_stylebox_override("panel",style)
		var stack := VBoxContainer.new(); stack.add_theme_constant_override("separation",1); panel.add_child(stack)
		var icon_shell := Control.new(); icon_shell.custom_minimum_size = Vector2(28,28); icon_shell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; stack.add_child(icon_shell)
		var icon := TextureRect.new(); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); icon.offset_left = 3; icon.offset_top = 3; icon.offset_right = -3; icon.offset_bottom = -3
		icon.texture = load(str(equipment.get("art","res://assets/hangar/empty_%s.svg" % hardpoint.type)))
		icon_shell.add_child(icon)
		if not equipment.is_empty():
			var rarity := TextureRect.new(); rarity.texture = load("res://assets/hangar/rarity_%s_frame.svg" % str(equipment.get("rarity","normal"))); rarity.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; rarity.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); rarity.mouse_filter = Control.MOUSE_FILTER_IGNORE; icon_shell.add_child(rarity)
		var label := UI.label("%s\n%s" % [hardpoint.id,("EMPTY" if equipment.is_empty() else "%s · Lv.%d" % [equipment.name,int(instance.get("level",1))])], 8, UI.TEXT, true); label.name = "SlotLabel"; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stack.add_child(label)
		add_child(panel); slot_cards.append(panel); slot_data.append(hardpoint)
		if not equipment.is_empty():
			_add_mounted_equipment(hardpoint,equipment)
	call_deferred("_layout")

func _add_mounted_equipment(hardpoint: Dictionary, equipment: Dictionary) -> void:
	var mount := TextureRect.new()
	mount.name = "Mounted_%s" % hardpoint.id
	mount.texture = load(str(equipment.get("mount_art",equipment.art)))
	mount.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mount.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mount)
	var overlay: TextureRect
	var overlay_path := str(equipment.get("overlay_art",""))
	if not overlay_path.is_empty():
		overlay = TextureRect.new()
		overlay.name = "MountedOverlay_%s" % hardpoint.id
		overlay.texture = load(overlay_path)
		overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(overlay)
	mounted_art.append({"node":mount,"overlay":overlay,"hardpoint":hardpoint,"equipment":equipment,"weapon":str(hardpoint.type)=="weapon"})

func _add_slot_marker(hardpoint: Dictionary) -> void:
	var kind := str(hardpoint.get("type",""))
	var accent := UI.CYAN if kind == "weapon" else UI.VIOLET
	var marker := PanelContainer.new()
	marker.name = "Hardpoint_%s" % str(hardpoint.get("id",""))
	marker.custom_minimum_size = Vector2(23,14)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(UI.INK,0.74)
	style.border_color = Color(accent,0.58)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 3
	style.corner_radius_bottom_right = 3
	marker.add_theme_stylebox_override("panel",style)
	var label := UI.label("", 7, Color(accent,0.82), true)
	label.text = str(hardpoint.get("id",""))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marker.add_child(label)
	add_child(marker)
	slot_markers.append({"node":marker,"hardpoint":hardpoint})

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and not ship_definition.is_empty(): call_deferred("_layout")

func _process(delta: float) -> void:
	if ship_definition.is_empty(): return
	idle_time += delta
	for mounted in mounted_art:
		var is_system := str(mounted.hardpoint.get("type","")) == "system"
		var pulse := 0.5 + 0.5 * sin(idle_time * (2.8 if is_system else 1.7) + float(mounted.hardpoint.position.x) * 8.0)
		mounted.node.modulate = Color(1.0,1.0,1.0,0.92 + pulse * 0.08)
		var overlay: TextureRect = mounted.get("overlay") as TextureRect
		if is_instance_valid(overlay):
			overlay.modulate = Color(1.0,1.0,1.0,0.94 + pulse * 0.06)
			if bool(mounted.equipment.get("rotates_to_target",false)):
				overlay.rotation = sin(idle_time * 0.7 + float(mounted.hardpoint.position.x) * 5.0) * 0.045
	queue_redraw()

func _layout_mount(mounted: Dictionary, point: Vector2) -> void:
	var mount_size: Vector2 = mounted.hardpoint.get("mount_size",Vector2(0.18,0.18))
	var scale := float(mounted.equipment.get("mount_scale",1.0))
	var extent := mount_size * ship_rect.size * scale
	mounted.node.position = point-extent/2.0
	mounted.node.size = extent
	mounted.node.pivot_offset = extent / 2.0
	var overlay: TextureRect = mounted.get("overlay") as TextureRect
	if not is_instance_valid(overlay): return
	var overlay_scale := float(mounted.equipment.get("overlay_scale",1.0))
	var overlay_extent := mount_size * ship_rect.size * overlay_scale
	var overlay_pivot: Vector2 = mounted.equipment.get("overlay_pivot",Vector2(0.5,0.5))
	overlay.position = point-overlay_extent*overlay_pivot
	overlay.size = overlay_extent
	overlay.pivot_offset = overlay_extent*overlay_pivot

func _layout() -> void:
	if size.x <= 0: return
	if not show_slot_cards:
		var ship_texture: Texture2D = (get_node("ShipArt") as TextureRect).texture
		var texture_size: Vector2 = ship_texture.get_size()
		var aspect: float = texture_size.x / maxf(1.0,texture_size.y)
		var showcase_w: float = minf(clampf(size.x * 0.82,220.0,380.0),(size.y - 12.0) * aspect)
		var showcase_h: float = showcase_w / aspect
		ship_rect = Rect2(Vector2((size.x-showcase_w)/2.0,maxf(6.0,(size.y-showcase_h)/2.0)),Vector2(showcase_w,showcase_h))
		get_node("ShipArt").position = ship_rect.position; get_node("ShipArt").size = ship_rect.size
		for mounted in mounted_art:
			var point := ship_rect.position + Vector2(mounted.hardpoint.position)*ship_rect.size
			_layout_mount(mounted,point)
		for marker in slot_markers:
			var point := ship_rect.position + Vector2(marker.hardpoint.position) * ship_rect.size
			var offset := Vector2(-11,12) if str(marker.hardpoint.type) == "system" else (Vector2(8,-12) if float(marker.hardpoint.position.x) <= 0.5 else Vector2(-31,-12))
			marker.node.position = point + offset
			marker.node.size = Vector2(23,14)
		queue_redraw()
		return
	var card_w := clampf(size.x*0.25,78.0,108.0); var card_h := 76.0
	var ship_w := clampf(size.x-card_w*2.0,160.0,260.0); var ship_h := 286.0
	ship_rect = Rect2(Vector2((size.x-ship_w)/2.0,38),Vector2(ship_w,ship_h))
	get_node("ShipArt").position = ship_rect.position; get_node("ShipArt").size = ship_rect.size
	var left_index := 0; var right_index := 0; connector_points.clear()
	for index in range(slot_cards.size()):
		var hardpoint := slot_data[index]; var panel := slot_cards[index]
		var right := float(hardpoint.position.x) >= 0.5
		if is_equal_approx(float(hardpoint.position.x),0.5): right = (index % 2)==0
		var lane := right_index if right else left_index
		if right: right_index += 1
		else: left_index += 1
		panel.position = Vector2(size.x-card_w if right else 0,42+lane*94); panel.size = Vector2(card_w,card_h)
		var anchor := ship_rect.position + Vector2(hardpoint.position) * ship_rect.size
		var card_point := Vector2(panel.position.x if right else panel.position.x+card_w,panel.position.y+card_h/2)
		connector_points.append({"from":anchor,"to":card_point,"type":hardpoint.type})
	for mounted in mounted_art:
		var point := ship_rect.position + Vector2(mounted.hardpoint.position)*ship_rect.size
		_layout_mount(mounted,point)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.015,0.03,0.07,0.74),true)
	for x in range(0,int(size.x),20): draw_line(Vector2(x,0),Vector2(x,size.y),Color(0.08,0.35,0.45,0.10),1)
	for y in range(0,int(size.y),20): draw_line(Vector2(0,y),Vector2(size.x,y),Color(0.08,0.35,0.45,0.10),1)
	if not ship_rect.has_area(): return
	var presentation: Dictionary = ship_definition.get("presentation",{})
	for index in range((presentation.get("engine_anchors",[]) as Array).size()):
		var anchor: Vector2 = presentation.engine_anchors[index]
		var nozzle := ship_rect.position + anchor * ship_rect.size
		var flutter := 0.78 + 0.22 * sin(idle_time * 7.0 + index * 1.9)
		var length := 7.0 * flutter
		draw_line(nozzle,nozzle + Vector2(0,length),Color(0.22,0.82,1.0,0.45),2.0,true)
		draw_line(nozzle,nozzle + Vector2(0,length * 0.65),Color(0.78,1.0,1.0,0.70),0.7,true)
	for connector in connector_points:
		var color := UI.CYAN if str(connector.type)=="weapon" else UI.VIOLET
		draw_polyline(PackedVector2Array([connector.from,Vector2(connector.to.x,connector.from.y),connector.to]),Color(color,0.62),1.5,true)
		draw_circle(connector.from,3.5,Color(color,0.9))
