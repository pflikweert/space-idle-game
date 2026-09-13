extends PanelContainer

signal selected(action: String)
var title_label: RichTextLabel
var summary_label: RichTextLabel
var header: PanelContainer
var tabs_box: HBoxContainer
var purchase_options: HBoxContainer
var rows: VBoxContainer
var footer: VBoxContainer
var scroll: ScrollContainer
var background_texture: TextureRect
var ui_factor := 1.0

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.04, 0.10, 0.96)
	style.border_color = Color("#8bbdcb")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)
	background_texture = TextureRect.new()
	background_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_texture.modulate = Color(1, 1, 1, 0.72)
	background_texture.z_index = 0
	add_child(background_texture)
	var body := VBoxContainer.new()
	body.z_index = 1
	body.add_theme_constant_override("separation", 6)
	add_child(body)
	header = PanelContainer.new()
	header.custom_minimum_size.y = 54
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color(0.02,0.12,0.18,0.50)
	header_style.border_color = Color("#65eaff")
	header_style.set_border_width_all(1)
	header_style.border_width_left = 5
	header_style.border_width_right = 5
	header_style.corner_radius_top_left = 18
	header_style.corner_radius_top_right = 5
	header_style.corner_radius_bottom_left = 5
	header_style.corner_radius_bottom_right = 18
	header_style.shadow_color = Color(0.0,0.8,1.0,0.28)
	header_style.shadow_size = 10
	header.add_theme_stylebox_override("panel", header_style)
	var header_content := VBoxContainer.new()
	header.add_child(header_content)
	title_label = _rich_label()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("default_color", Color("#e9fbff"))
	title_label.add_theme_font_size_override("font_size", 24)
	header_content.add_child(title_label)
	summary_label = _rich_label()
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.add_theme_font_size_override("font_size", 15)
	summary_label.add_theme_color_override("default_color", Color("#b9dbe4"))
	header_content.add_child(summary_label)
	body.add_child(header)
	tabs_box = HBoxContainer.new()
	body.add_child(tabs_box)
	purchase_options = HBoxContainer.new()
	body.add_child(purchase_options)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 6)
	scroll.add_child(rows)
	footer = VBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	body.add_child(footer)

func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func button(text: String, action: String, disabled := false) -> Button:
	var control := Button.new()
	if text.contains("◈"):
		control.icon = load("res://assets/ui/icons/coin.svg")
		text = text.replace("◈", "").strip_edges()
	elif text.contains("▣"):
		control.icon = load("res://assets/ui/icons/module.svg")
		text = text.replace("▣", "").strip_edges()
	control.text = text
	control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	control.disabled = disabled
	control.custom_minimum_size.y = 44
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.add_theme_font_size_override("font_size", 19)
	control.add_theme_color_override("default_color", Color("#e0e0ff"))
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#121228") if state != "pressed" else Color("#234052")
		style.border_color = Color("#6070a0") if disabled else Color("#8bbdcb")
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		control.add_theme_stylebox_override(state, style)
	if action in ["start", "resume", "railgun_buy", "equip_card"]:
		var primary = control.get_theme_stylebox("normal").duplicate()
		primary.bg_color = Color("#b88f2d")
		primary.border_color = Color("#edc254")
		control.add_theme_stylebox_override("normal", primary)
	control.pressed.connect(func(): selected.emit(action))
	return control

func show_content(title: String, summary: String, tabs: Array, entries: Array, actions: Array, quantities: Array = []) -> void:
	var old_scroll := scroll.scroll_vertical
	title_label.text = title
	summary_label.text = summary
	header.visible = true
	_clear(tabs_box)
	_clear(purchase_options)
	purchase_options.visible = not quantities.is_empty()
	tabs_box.visible = not tabs.is_empty()
	_clear(rows)
	_clear(footer)
	for entry in tabs:
		tabs_box.add_child(_choice_button(entry))
	for entry in quantities:
		purchase_options.add_child(_choice_button(entry))
	for entry in entries:
		if entry.has("run_results"):
			_add_run_results(entry.run_results)
			continue
		if entry.has("wave_intel_table"):
			_add_wave_intel_table(entry)
			continue
		if entry.has("enemy_name"):
			_add_enemy_card(entry)
			continue
		if entry.has("upgrade_name"):
			_add_upgrade_card(entry)
			continue
		var label := _rich_label()
		label.text = entry.text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 19)
		label.add_theme_color_override("default_color", Color("#e0e0ff"))
		rows.add_child(label)
		if entry.has("buttons"):
			var row := HBoxContainer.new()
			rows.add_child(row)
			for choice in entry.buttons:
				row.add_child(button(choice.text, choice.action, choice.get("disabled", false)))
	var action_parent: Node = footer
	if actions.size() > 3:
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation",8)
		grid.add_theme_constant_override("v_separation",8)
		footer.add_child(grid)
		action_parent = grid
	if not actions.is_empty() and bool(actions[0].get("inline", false)):
		action_parent = HBoxContainer.new()
		footer.add_child(action_parent)
	for entry in actions:
		if entry.get("inline",false) and action_parent == footer:
			action_parent = HBoxContainer.new()
			footer.add_child(action_parent)
		action_parent.add_child(button(entry.text, entry.action, entry.get("disabled", false)))
	scroll.set_deferred("scroll_vertical", old_scroll)
	show()

func _add_run_results(results: Array) -> void:
	var top_spacer := Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows.add_child(top_spacer)
	for result in results:
		if bool(result.get("wide",false)):
			_add_result_tile(rows,result)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",6)
	rows.add_child(grid)
	for result in results:
		if not bool(result.get("wide",false)):
			_add_result_tile(grid,result)
	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows.add_child(bottom_spacer)

func _add_result_tile(parent: Control, result: Dictionary) -> void:
	var tile := _upgrade_panel(Color("#172f40"))
	parent.add_child(tile)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",2)
	tile.add_child(stack)
	var strip := _upgrade_panel(Color("#24485a"),2)
	stack.add_child(strip)
	strip.add_child(_card_label("[center]%s[/center]" % result.label,11,Color("#bbd4de")))
	stack.add_child(_card_label("[center]%s[/center]" % result.value,15,Color("#d5f2f6")))

func _upgrade_panel(color: Color, padding := 3) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("#315566")
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_bottom_right = 6
	style.corner_detail = 1
	style.set_content_margin_all(padding * ui_factor)
	panel.add_theme_stylebox_override("panel",style)
	return panel

func set_overlay_opacity(alpha: float) -> void:
	var style := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.bg_color.a = clampf(alpha, 0.0, 1.0)
	add_theme_stylebox_override("panel", style)

func set_overlay_background(texture: Texture2D, enabled := true) -> void:
	background_texture.texture = texture
	background_texture.visible = enabled and texture != null

func set_ui_factor(factor: float) -> void:
	ui_factor = factor
	_resize_controls(self, factor)

func _resize_controls(node: Node, factor: float) -> void:
	if node is Button:
		node.custom_minimum_size.y = ceil(44.0 * factor)
		node.add_theme_font_size_override("font_size", ceili(13.0 * factor))
	elif node is TextureRect and node.has_meta("preview_size"):
		node.custom_minimum_size = Vector2.ONE * minf(72,float(node.get_meta("preview_size"))) * factor
	elif node is RichTextLabel:
		node.add_theme_font_size_override("normal_font_size", ceili(float(node.get_meta("base_font_size", 22.0 if node == title_label else 13.0)) * factor))
		node.text = _icon_text(node.text,ceili(13*factor))
	for child in node.get_children():
		_resize_controls(child, factor)

func _choice_button(entry: Dictionary) -> Button:
	var control := button(entry.text, entry.action, entry.get("disabled", false))
	if bool(entry.get("selected", false)):
		var style := control.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		style.bg_color = Color("#18394b")
		control.add_theme_stylebox_override("normal", style)
		control.add_theme_color_override("default_color", Color("#8bbdcb"))
	return control

func _card_label(text: String, font_size: int, color: Color) -> RichTextLabel:
	var label := _rich_label()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_meta("base_font_size", mini(font_size, 15))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("default_color", color)
	return label

func _add_upgrade_card(entry: Dictionary) -> void:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.13, 0.82)
	style.border_color = Color(0.20, 0.35, 0.43, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)
	rows.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.size_flags_stretch_ratio = 1.7
	row.add_child(details)
	details.add_child(_card_label(entry.upgrade_name, 19, Color("#e0e0ff")))
	details.add_child(_card_label("Lv %d / %d" % [entry.level, entry.cap], 15, Color("#91a7b6")))
	details.add_child(_card_label(entry.values, 17, Color("#b4d3df")))
	var purchase: Dictionary = entry.purchase
	var buy := button(purchase.text, purchase.action, purchase.disabled)
	buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buy.size_flags_stretch_ratio = 1.0
	row.add_child(buy)

func _add_enemy_card(entry: Dictionary) -> void:
	var accent := Color("#ffae65") if entry.boss else Color("#7ed9e4")
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0c1725")
	style.border_color = Color("#6d4530") if entry.boss else Color("#264451")
	style.set_border_width_all(1)
	style.border_width_left = 3
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", style)
	rows.add_child(card)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	card.add_child(body)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 6)
	body.add_child(heading)
	if entry.preview != null:
		var preview := TextureRect.new()
		preview.texture = entry.preview
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.custom_minimum_size = Vector2(104, 104)
		preview.set_meta("preview_size", 104.0)
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.modulate = Color.WHITE if entry.discovered else Color(0.65, 0.72, 0.78, 0.85)
		heading.add_child(preview)
	else:
		var fallback := _upgrade_panel(Color("#102838"), 3)
		fallback.custom_minimum_size = Vector2(72, 72)
		fallback.add_child(_card_label("[center]NO\nSIGNAL[/center]", 12, accent))
		heading.add_child(fallback)
	var intro := VBoxContainer.new()
	intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heading.add_child(intro)
	intro.add_child(_card_label(entry.arrival, 14, accent))
	intro.add_child(_card_label(entry.enemy_name, 22, Color("#eef7ff")))
	intro.add_child(_card_label(entry.role, 17, Color("#a7bacb")))
	body.add_child(_card_label(entry.description, 17, Color("#c1cfdd")))
	if not str(entry.stats).is_empty():
		body.add_child(_card_label(entry.stats, 16, Color("#d6e9ef")))
	if not str(entry.note).is_empty():
		body.add_child(_card_label(entry.note, 14, Color("#92a6b7")))
	body.add_child(_card_label("%s  /  %d kills" % ["ENCOUNTERED" if entry.discovered else "NOT ENCOUNTERED", entry.kills], 14, accent))
	if entry.has("action"):
		body.add_child(_card_label("TAP FOR CODEX", 13, Color("#8bbdcb")))
		var tap_target := Button.new()
		tap_target.flat = true
		tap_target.tooltip_text = "Open Codex entry"
		tap_target.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for state in ["normal", "hover", "pressed", "disabled"]:
			tap_target.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		tap_target.pressed.connect(func(): selected.emit(str(entry.action)))
		card.add_child(tap_target)

func _add_wave_intel_table(entry: Dictionary) -> void:
	var detailed := str(entry.get("mode", "roster")) == "stats"
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#091522")
	style.border_color = Color("#315566")
	style.set_border_width_all(1)
	style.border_width_left = 3
	style.corner_radius_top_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 5 * ui_factor
	style.content_margin_right = 5 * ui_factor
	style.content_margin_top = 5 * ui_factor
	style.content_margin_bottom = 5 * ui_factor
	panel.add_theme_stylebox_override("panel", style)
	rows.add_child(panel)
	var table := VBoxContainer.new()
	table.add_theme_constant_override("separation", 3)
	panel.add_child(table)
	var headings := ["ENEMY", "SPAWN" if not detailed else "HULL", "HULL" if not detailed else "HIT", "HIT" if not detailed else "SPD", "SPD" if not detailed else "SHOT"]
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 3)
	table.add_child(header_row)
	var spacer := Control.new()
	spacer.custom_minimum_size.x = 36 * ui_factor
	header_row.add_child(spacer)
	for index in headings.size():
		var cell := _table_cell(headings[index], index == 0, true, detailed)
		header_row.add_child(cell)
	for entry_row in entry.rows:
		var row_panel := PanelContainer.new()
		row_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = Color("#182330") if bool(entry_row.get("boss", false)) else Color("#0e1d2a")
		row_style.border_color = Color("#ffae65") if bool(entry_row.get("boss", false)) else Color("#284555")
		row_style.set_border_width_all(1)
		row_style.border_width_left = 3 if bool(entry_row.get("boss", false)) else 1
		row_style.corner_radius_top_right = 3
		row_style.corner_radius_bottom_left = 3
		row_style.content_margin_left = 3 * ui_factor
		row_style.content_margin_right = 3 * ui_factor
		row_style.content_margin_top = 2 * ui_factor
		row_style.content_margin_bottom = 2 * ui_factor
		row_panel.add_theme_stylebox_override("panel", row_style)
		table.add_child(row_panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		row_panel.add_child(row)
		if entry_row.preview != null:
			var preview := TextureRect.new()
			preview.texture = entry_row.preview
			preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			preview.custom_minimum_size = Vector2(36, 36) * ui_factor
			preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(preview)
		else:
			var fallback := _card_label("[center]•[/center]", 15, Color("#8bbdcb"))
			fallback.custom_minimum_size = Vector2(36, 36) * ui_factor
			row.add_child(fallback)
		var name := str(entry_row.get("enemy_name", "UNKNOWN"))
		row.add_child(_table_cell(name + "\n[color=#91a7b6]" + str(entry_row.get("role", "")) + "[/color]", true, false, detailed))
		for value in entry_row.get("values", []):
			row.add_child(_table_cell(str(value), false, false, detailed))
		var tap_target := Button.new()
		tap_target.flat = true
		tap_target.tooltip_text = "Open Codex entry"
		tap_target.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for state in ["normal", "hover", "pressed", "disabled"]:
			tap_target.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		tap_target.pressed.connect(func(): selected.emit(str(entry_row.action)))
		row_panel.add_child(tap_target)

func _table_cell(text: String, is_name: bool, is_header: bool, detailed: bool) -> RichTextLabel:
	var color := Color("#8bbdcb") if is_header else Color("#ddf4ff")
	var cell := _card_label(text if is_name else "[center]" + text + "[/center]", 12 if is_header else 14, color)
	cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if is_name else HORIZONTAL_ALIGNMENT_CENTER
	cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Keep the short stat headers on one line; this is the main scan path on mobile.
	cell.custom_minimum_size.x = (83 if is_name else (55 if detailed else 54)) * ui_factor
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL if is_name else Control.SIZE_SHRINK_CENTER
	return cell

func _rich_label() -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	return label

func _icon_text(value: String, pixels: int) -> String:
	var icons := {"◈":"coin","▣":"module","★":"star","☆":"star_empty","✦":"star","✓":"unlocked","◇":"lock","→":"arrow"}
	for symbol in icons:
		value = value.replace(symbol,"[img=%dx%d]res://assets/ui/icons/%s.svg[/img]" % [pixels,pixels,icons[symbol]])
	return value
