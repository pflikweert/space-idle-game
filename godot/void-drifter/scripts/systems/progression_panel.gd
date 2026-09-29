extends PanelContainer

const UI := preload("res://scripts/systems/ui_design_system.gd")
const WORKSHOP_SCHEMATIC_PATH := "res://assets/ui/workshop/workshop_schematic_v1.png"
const HOME_BLUEPRINT_ART_PATH := "res://assets/ui/home/railgun_blueprint_v1.png"
const HOME_TIER_ART_PATH := "res://assets/ui/home/fracture_field_tier_card_v1.png"
const StandardHeader := preload("res://scripts/systems/standard_screen_header.gd")
const HomeScreenHeader := preload("res://scripts/systems/home_screen_header.gd")

signal selected(action: String)
var header: StandardScreenHeader
var currency_shell: PanelContainer
var currency_bar: HBoxContainer
var currency_status: Array = []
var navigation_context := ""
var tabs_box: HBoxContainer
var purchase_options: HBoxContainer
var rows: VBoxContainer
var footer: VBoxContainer
var footer_shell: PanelContainer
var footer_content: VBoxContainer
var navigation_dock: HBoxContainer
var scroll: ScrollContainer
var background_texture: TextureRect
var ui_factor := 1.0
var _scroll_touch_id := -1
var _home_texture_cache := {}

func _input(event: InputEvent) -> void:
	# ScrollContainer handles wheel input, but Godot does not turn every
	# touchscreen drag into a vertical scroll on native Android. Track only
	# touches that begin inside the content viewport so buttons and the footer
	# retain their normal tap behavior.
	if not visible or not is_instance_valid(scroll): return
	if event is InputEventScreenTouch:
		if event.pressed and scroll.get_global_rect().has_point(event.position):
			_scroll_touch_id = event.index
		elif not event.pressed and event.index == _scroll_touch_id:
			_scroll_touch_id = -1
	elif event is InputEventScreenDrag and event.index == _scroll_touch_id:
		var bar := scroll.get_v_scroll_bar()
		var maximum := int(maxf(0.0, bar.max_value))
		scroll.scroll_vertical = clampi(scroll.scroll_vertical - roundi(event.relative.y), 0, maximum)

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(UI.INK, 0.94)
	# Screen content should sit directly on the command-deck background. Borders
	# belong to individual components, not around the entire application frame.
	style.set_border_width_all(0)
	style.set_corner_radius_all(0)
	style.shadow_size = 0
	style.set_content_margin_all(0)
	add_theme_stylebox_override("panel", style)
	background_texture = TextureRect.new()
	background_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_texture.texture = load("res://assets/ui/theme/command_deck_backdrop_v1.png")
	background_texture.modulate = Color(0.72, 0.86, 1.0, 0.14)
	background_texture.z_index = 0
	background_texture.visible = background_texture.texture != null
	add_child(background_texture)
	var body := VBoxContainer.new()
	body.z_index = 1
	body.add_theme_constant_override("separation", 6)
	add_child(body)
	header = StandardHeader.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.back_pressed.connect(func(): selected.emit("back"))
	body.add_child(header)
	currency_shell = PanelContainer.new()
	currency_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	currency_shell.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var currency_style := StyleBoxFlat.new()
	# The currency strip is its own compact status surface. Keep the visual
	# weight low, but give it clear top and bottom rules so it reads as a
	# deliberate subheader rather than incidental text below the page title.
	currency_style.bg_color = Color("#061522", 0.84)
	currency_style.border_color = Color(UI.CYAN_SOFT, 0.46)
	currency_style.border_width_top = 1
	currency_style.border_width_bottom = 1
	currency_style.content_margin_left = 10
	currency_style.content_margin_right = 10
	currency_style.content_margin_top = 4
	currency_style.content_margin_bottom = 4
	currency_shell.add_theme_stylebox_override("panel", currency_style)
	body.add_child(currency_shell)
	currency_bar = HBoxContainer.new()
	currency_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	currency_bar.add_theme_constant_override("separation", 0)
	currency_shell.add_child(currency_bar)
	currency_shell.hide()
	tabs_box = HBoxContainer.new()
	body.add_child(tabs_box)
	purchase_options = HBoxContainer.new()
	body.add_child(purchase_options)
	scroll = ScrollContainer.new()
	scroll.name = "MenuContentScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	body.add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 6)
	scroll.add_child(rows)
	footer_shell = PanelContainer.new()
	footer_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# This is a dock, not a second content region. Keep it strictly content-height
	# so the scroll view always owns the remaining vertical space.
	footer_shell.size_flags_vertical = Control.SIZE_SHRINK_END
	var footer_style := StyleBoxFlat.new()
	footer_style.bg_color = Color("#071722", 0.94)
	footer_style.border_color = Color(UI.CYAN_SOFT, 0.48)
	footer_style.border_width_top = 1
	footer_style.set_corner_radius_all(0)
	footer_style.content_margin_left = 10
	footer_style.content_margin_right = 10
	footer_style.content_margin_top = 0
	footer_style.content_margin_bottom = 0
	footer_shell.add_theme_stylebox_override("panel", footer_style)
	body.add_child(footer_shell)
	footer_content = VBoxContainer.new()
	footer_content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	footer_content.add_theme_constant_override("separation", 0)
	footer_shell.add_child(footer_content)
	footer = VBoxContainer.new()
	footer.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	footer.add_theme_constant_override("separation", 8)
	footer_content.add_child(footer)
	navigation_dock = HBoxContainer.new()
	navigation_dock.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	navigation_dock.custom_minimum_size.y = 78
	navigation_dock.add_theme_constant_override("separation", 0)
	footer_content.add_child(navigation_dock)

func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func button(text: String, action: String, disabled := false) -> Button:
	var control := Button.new()
	var icon_path := _action_icon(action)
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		control.icon = load(icon_path)
	if text.contains("◈"):
		control.icon = UI.currency_icon("credits", ceili(20.0 * ui_factor))
		text = text.replace("◈", "").strip_edges()
	elif text.contains("▣"):
		control.icon = UI.currency_icon("boss_module", ceili(20.0 * ui_factor))
		text = text.replace("▣", "").strip_edges()
	control.text = text
	control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	control.disabled = disabled
	control.custom_minimum_size.y = 50
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.apply_text(control, UI.BUTTON, UI.TEXT, true)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(UI.SURFACE_RAISED) if state == "normal" else (Color("#123c4e") if state == "hover" else (Color("#062432") if state == "pressed" else Color("#111b29")))
		style.border_color = UI.DISABLED if disabled else (UI.VIOLET if action.begins_with("blueprint") else UI.CYAN)
		style.set_border_width_all(2)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 10
		style.shadow_color = Color(UI.CYAN, 0.16) if not disabled else Color.TRANSPARENT
		style.shadow_size = 7 if not disabled else 0
		style.content_margin_left = 10
		style.content_margin_right = 10
		control.add_theme_stylebox_override(state, style)
	if action in ["start", "resume", "railgun_buy", "equip_card"]:
		var primary = control.get_theme_stylebox("normal").duplicate()
		primary.bg_color = Color("#4e3810")
		primary.border_color = UI.GOLD
		control.add_theme_stylebox_override("normal", primary)
	control.pressed.connect(func(): selected.emit(action))
	return control

func show_content(title: String, summary: String, tabs: Array, entries: Array, actions: Array, quantities: Array = [], can_go_back := true) -> void:
	var old_scroll := scroll.scroll_vertical
	var home_command: Dictionary = {}
	for entry in entries:
		if entry.has("home_command"):
			home_command = Dictionary(entry.home_command)
			break
	# Home owns a dedicated image header. The shared command-deck header remains
	# compact and is used by every other menu.
	var is_home := not home_command.is_empty()
	header.set_home_variant(false)
	header.set_content(title, summary)
	header.set_back_available(can_go_back)
	header.visible = not is_home
	# Individual screens can temporarily shrink the content area (for example
	# card choice and Hangar views). Restore the shared menu defaults whenever a
	# new screen is built, otherwise the next menu can inherit a zero-height
	# ScrollContainer and show only its header/footer.
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 0.0
	rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows.custom_minimum_size.y = 0.0
	# The Workshop is a long, single-scroll calibration list. Its rows must keep
	# their intrinsic height instead of being stretched to fill the viewport.
	var workshop_layout := entries.any(func(entry): return entry.has("workshop_overview"))
	if workshop_layout: rows.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_clear(tabs_box)
	_clear(purchase_options)
	purchase_options.visible = not quantities.is_empty()
	tabs_box.visible = not tabs.is_empty()
	_clear(rows)
	_clear(footer)
	_build_navigation_dock(title)
	if not home_command.is_empty():
		_add_home_command(home_command)
	for entry in tabs:
		tabs_box.add_child(_choice_button(entry))
	for entry in quantities:
		purchase_options.add_child(_choice_button(entry))
	for entry in entries:
		if entry.has("home_command"):
			continue
		if entry.has("tier_brief"):
			_add_tier_brief(entry.tier_brief)
			continue
		if entry.has("workshop_overview"):
			_add_workshop_overview(entry.workshop_overview)
			continue
		if entry.has("workshop_section"):
			_add_workshop_section(entry.workshop_section)
			continue
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
		_set_inline_icon_text(label, str(entry.text), UI.BODY)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.apply_rich_text(label, UI.BODY, UI.TEXT, true)
		rows.add_child(label)
		if entry.has("buttons"):
			var row := HBoxContainer.new()
			rows.add_child(row)
			for choice in entry.buttons:
				row.add_child(button(choice.text, choice.action, choice.get("disabled", false)))
	var action_parent: Node = footer
	if actions.size() > 3 and home_command.is_empty():
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation",8)
		grid.add_theme_constant_override("v_separation",8)
		footer.add_child(grid)
		action_parent = grid
	if not actions.is_empty() and home_command.is_empty() and bool(actions[0].get("inline", false)):
		action_parent = HBoxContainer.new()
		action_parent.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		footer.add_child(action_parent)
	for entry in actions:
		if not home_command.is_empty():
			continue
		if entry.get("inline",false) and action_parent == footer:
			action_parent = HBoxContainer.new()
			action_parent.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			footer.add_child(action_parent)
		var action_button := button(entry.text, entry.action, entry.get("disabled", false))
		if bool(entry.get("compact", false)):
			action_button.set_meta("compact_action", true)
			action_button.custom_minimum_size = Vector2(0, 30 * ui_factor)
			action_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			action_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			action_button.add_theme_font_size_override("font_size", ceili(9 * ui_factor))
		action_parent.add_child(action_button)
	footer_shell.visible = true
	scroll.set_deferred("scroll_vertical", old_scroll)
	show()

## Dedicated portrait home layout. The footer owns navigation, so this screen
## contains only campaign state, the primary expedition action and one next goal.
func _add_home_command(data: Dictionary) -> void:
	rows.add_theme_constant_override("separation", ceili(12.0 * ui_factor))
	# Unlike standard menu headers, the campaign wordmark is part of the home
	# feed. It scrolls away with the tier content instead of consuming fixed UI.
	var home_header := HomeScreenHeader.new()
	home_header.set_ui_factor(ui_factor)
	home_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_child(home_header)
	rows.add_child(_home_tier_card(data))
	rows.add_child(_home_primary_action(data))
	rows.add_child(_home_objective_card(data))

func _home_tier_card(data: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.custom_minimum_size.y = ceili(214.0 * ui_factor)
	var style := UI.panel(UI.CYAN, 0.88, 10, 2)
	style.bg_color = Color("#071b29", 0.90)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	card.add_theme_stylebox_override("panel", style)
	var stage := Control.new()
	stage.clip_contents = true
	card.add_child(stage)
	var card_art := TextureRect.new()
	card_art.texture = _home_texture(HOME_TIER_ART_PATH)
	card_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	card_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_art.modulate = Color(0.62, 0.82, 1.0, 0.30)
	card_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(card_art)
	var art_shade := ColorRect.new()
	art_shade.color = Color("#04111c", 0.56)
	art_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(art_shade)
	var content := VBoxContainer.new()
	content.z_index = 1
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 22.0 * ui_factor
	content.offset_right = -22.0 * ui_factor
	content.offset_top = 17.0 * ui_factor
	content.offset_bottom = -15.0 * ui_factor
	content.add_theme_constant_override("separation", ceili(7.0 * ui_factor))
	stage.add_child(content)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", ceili(8.0 * ui_factor))
	content.add_child(heading)
	var title := UI.label(str(data.get("tier_title", "TIER I · FRACTURE FIELD")), ceili(17.0 * ui_factor), UI.TEXT, true)
	title.add_theme_font_override("font", UI.static_font(UI.WEIGHT_BOLD))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_child(title)
	var status := PanelContainer.new()
	var status_style := UI.panel(UI.MINT, 0.16, 7, 1)
	status_style.content_margin_left = 8.0 * ui_factor
	status_style.content_margin_right = 8.0 * ui_factor
	status_style.content_margin_top = 3.0 * ui_factor
	status_style.content_margin_bottom = 3.0 * ui_factor
	status.add_theme_stylebox_override("panel", status_style)
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", ceili(4.0 * ui_factor))
	status.add_child(status_row)
	var dot := ColorRect.new()
	dot.color = UI.MINT
	dot.custom_minimum_size = Vector2(7.0, 7.0) * ui_factor
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	status_row.add_child(dot)
	var status_text := UI.label(str(data.get("status", "ACTIVE")), ceili(10.0 * ui_factor), UI.MINT, true)
	status_text.add_theme_font_override("font", UI.static_font(UI.WEIGHT_BOLD))
	status_row.add_child(status_text)
	heading.add_child(status)
	var divider := ColorRect.new()
	divider.color = Color(UI.CYAN_SOFT, 0.22)
	divider.custom_minimum_size.y = ceili(1.0 * ui_factor)
	content.add_child(divider)
	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", ceili(12.0 * ui_factor))
	content.add_child(metrics)
	metrics.add_child(_home_metric("BEST WAVE", str(data.get("best_wave", 1)), UI.TEXT))
	var metric_divider := ColorRect.new()
	metric_divider.color = Color(UI.CYAN_SOFT, 0.26)
	metric_divider.custom_minimum_size = Vector2(1.0, 30.0) * ui_factor
	metric_divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	metrics.add_child(metric_divider)
	var tier_metric_label := str(data.get("tier_metric_label", "NEXT TIER"))
	var tier_metric_value := str(data.get("tier_metric_value", "W%d" % int(data.get("tier_goal", 100))))
	metrics.add_child(_home_metric(tier_metric_label, tier_metric_value, UI.CYAN_SOFT))
	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", ceili(6.0 * ui_factor))
	content.add_child(progress_row)
	var segments := HBoxContainer.new()
	segments.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	segments.add_theme_constant_override("separation", ceili(3.0 * ui_factor))
	progress_row.add_child(segments)
	var progress := clampf(float(data.get("progress", 0.0)), 0.0, 1.0)
	for index in range(10):
		var segment := PanelContainer.new()
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.custom_minimum_size.y = ceili(11.0 * ui_factor)
		var segment_style := StyleBoxFlat.new()
		segment_style.bg_color = UI.CYAN if float(index + 1) <= ceilf(progress * 10.0) else Color("#163243")
		segment_style.corner_radius_top_left = 2
		segment_style.corner_radius_top_right = 2
		segment_style.corner_radius_bottom_left = 2
		segment_style.corner_radius_bottom_right = 2
		segment.add_theme_stylebox_override("panel", segment_style)
		segments.add_child(segment)
	var progress_text := UI.label("%d / %d" % [int(data.get("progress_wave", 1)), int(data.get("tier_goal", 100))], ceili(11.0 * ui_factor), UI.CYAN_SOFT, true)
	progress_text.add_theme_font_override("font", UI.static_font(UI.WEIGHT_BOLD))
	progress_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_row.add_child(progress_text)
	var brief_spacer := Control.new()
	brief_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	brief_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(brief_spacer)
	var claimable_rewards := int(data.get("claimable_rewards", 0))
	if claimable_rewards > 0:
		var ready := UI.label("%d REWARD%s READY TO CLAIM" % [claimable_rewards, "" if claimable_rewards == 1 else "S"], ceili(9.0 * ui_factor), UI.GOLD, true)
		ready.add_theme_font_override("font", UI.static_font(UI.WEIGHT_BOLD))
		ready.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(ready)
	var brief := button("VIEW TIER BRIEF", "tier_brief")
	brief.custom_minimum_size = Vector2(150.0 * ui_factor, ceili(30.0 * ui_factor))
	brief.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	brief.size_flags_vertical = Control.SIZE_SHRINK_END
	brief.add_theme_font_size_override("font_size", ceili(10.0 * ui_factor))
	content.add_child(brief)
	return card

func _home_metric(caption: String, value: String, color: Color) -> VBoxContainer:
	var metric := VBoxContainer.new()
	metric.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metric.add_theme_constant_override("separation", 0)
	var caption_label := UI.label(caption, ceili(10.0 * ui_factor), UI.MUTED, true)
	caption_label.add_theme_font_override("font", UI.static_font(UI.WEIGHT_MEDIUM))
	metric.add_child(caption_label)
	var value_label := UI.label(value, ceili(22.0 * ui_factor), color, true)
	value_label.add_theme_font_override("font", UI.static_font(UI.WEIGHT_BOLD))
	metric.add_child(value_label)
	return metric

func _home_primary_action(data: Dictionary) -> PanelContainer:
	var shell := PanelContainer.new()
	shell.custom_minimum_size.y = ceili(72.0 * ui_factor)
	shell.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var style := UI.panel(UI.GOLD, 0.96, 11, 2)
	style.bg_color = Color("#3c2b0d", 0.96)
	style.content_margin_left = 14.0 * ui_factor
	style.content_margin_right = 14.0 * ui_factor
	style.content_margin_top = 8.0 * ui_factor
	style.content_margin_bottom = 8.0 * ui_factor
	shell.add_theme_stylebox_override("panel", style)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shell.add_child(stack)
	var title := UI.label(str(data.get("primary_label", "START EXPEDITION")), ceili(19.0 * ui_factor), UI.GOLD, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UI.static_font(UI.WEIGHT_BOLD))
	stack.add_child(title)
	var subtitle := UI.label(str(data.get("tier_title", "TIER I · FRACTURE FIELD")), ceili(9.0 * ui_factor), Color("#ffe4a3"), true)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font", UI.static_font(UI.WEIGHT_MEDIUM))
	stack.add_child(subtitle)
	var tap := Button.new()
	tap.flat = true
	tap.tooltip_text = str(data.get("primary_label", "START EXPEDITION")).capitalize()
	tap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0.0)
	tap.pressed.connect(func(): selected.emit(str(data.get("primary_action", "start"))))
	shell.add_child(tap)
	return shell

func _home_objective_card(data: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.custom_minimum_size.y = ceili(118.0 * ui_factor)
	var style := UI.panel(UI.CYAN_SOFT, 0.88, 9, 1)
	style.bg_color = Color("#071926", 0.92)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	card.add_theme_stylebox_override("panel", style)
	var stage := Control.new()
	stage.clip_contents = true
	card.add_child(stage)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 19.0 * ui_factor
	row.offset_right = -19.0 * ui_factor
	row.offset_top = 13.0 * ui_factor
	row.offset_bottom = -13.0 * ui_factor
	row.add_theme_constant_override("separation", ceili(10.0 * ui_factor))
	stage.add_child(row)
	var art_frame := PanelContainer.new()
	art_frame.custom_minimum_size = Vector2(106.0, 82.0) * ui_factor
	var art_style := UI.panel(UI.GOLD, 0.15, 6, 1)
	art_frame.add_theme_stylebox_override("panel", art_style)
	row.add_child(art_frame)
	var art := TextureRect.new()
	var art_path := str(data.get("objective_art", HOME_BLUEPRINT_ART_PATH))
	art.texture = _home_texture(art_path)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4.0 * ui_factor)
	art_frame.add_child(art)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	var label := UI.label("NEXT OBJECTIVE", ceili(9.0 * ui_factor), UI.CYAN_SOFT, true)
	label.add_theme_font_override("font", UI.static_font(UI.WEIGHT_MEDIUM))
	info.add_child(label)
	var objective := UI.label(str(data.get("objective_title", "RAILGUN BLUEPRINT")), ceili(14.0 * ui_factor), UI.TEXT, true)
	objective.add_theme_font_override("font", UI.static_font(UI.WEIGHT_BOLD))
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(objective)
	var detail := UI.label(str(data.get("objective_detail", "Reach Wave 40 to unlock an additional Railgun module.")), ceili(10.0 * ui_factor), UI.MUTED, false)
	detail.add_theme_font_override("font", UI.static_font(UI.WEIGHT_REGULAR))
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(detail)
	var badge := PanelContainer.new()
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var badge_style := UI.panel(UI.GOLD, 0.18, 6, 1)
	badge_style.content_margin_left = 7.0 * ui_factor
	badge_style.content_margin_right = 7.0 * ui_factor
	badge.add_theme_stylebox_override("panel", badge_style)
	var badge_text := UI.label(str(data.get("objective_badge", "W40")), ceili(12.0 * ui_factor), UI.GOLD, true)
	badge_text.add_theme_font_override("font", UI.static_font(UI.WEIGHT_BOLD))
	badge.add_child(badge_text)
	row.add_child(badge)
	return card

func _home_texture(path: String) -> Texture2D:
	var resolved_path := path if not path.is_empty() else HOME_BLUEPRINT_ART_PATH
	if _home_texture_cache.has(resolved_path):
		return _home_texture_cache[resolved_path]
	var texture: Texture2D = load(resolved_path) if ResourceLoader.exists(resolved_path) else null
	if texture == null and resolved_path.to_lower().ends_with(".png"):
		var image := Image.new()
		if image.load(resolved_path) == OK:
			texture = ImageTexture.create_from_image(image)
	if texture == null and resolved_path != HOME_BLUEPRINT_ART_PATH:
		return _home_texture(HOME_BLUEPRINT_ART_PATH)
	_home_texture_cache[resolved_path] = texture
	return texture

func _home_footer_icon(index: int) -> Texture2D:
	var icon_paths := [
		"res://assets/ui/icons/navigation/home_v1.png",
		"res://assets/ui/icons/navigation/loadout_v1.png",
		"res://assets/ui/icons/navigation/workshop_v1.png",
		"res://assets/ui/icons/navigation/codex_v1.png",
		"res://assets/ui/icons/navigation/settings_v1.png",
	]
	return _home_texture(icon_paths[clampi(index, 0, icon_paths.size() - 1)])

func set_currency_status(entries: Array) -> void:
	currency_status = entries.duplicate(true)
	_rebuild_currency_status()

func set_navigation_context(section: String) -> void:
	navigation_context = section

func _rebuild_currency_status() -> void:
	if not is_instance_valid(currency_shell) or not is_instance_valid(currency_bar):
		return
	_clear(currency_bar)
	currency_shell.visible = not currency_status.is_empty()
	if currency_status.is_empty():
		return
	currency_shell.custom_minimum_size.y = ceili(44.0 * ui_factor)
	currency_bar.add_theme_constant_override("separation", 0)
	for index in currency_status.size():
		var entry: Dictionary = currency_status[index]
		var currency_id := str(entry.get("id", "credits"))
		var cell := HBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.alignment = BoxContainer.ALIGNMENT_CENTER
		cell.add_theme_constant_override("separation", ceili(8.0 * ui_factor))
		currency_bar.add_child(cell)
		var icon := TextureRect.new()
		var icon_size := ceili(22.0 * ui_factor)
		icon.texture = UI.currency_icon(currency_id, icon_size)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2.ONE * icon_size
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(icon)
		var value := UI.label(str(entry.get("value", "0")), ceili(16.0 * ui_factor), UI.TEXT, true)
		value.add_theme_font_override("font", UI.static_font(UI.WEIGHT_BOLD))
		value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cell.add_child(value)
		if index < currency_status.size() - 1:
			var separator := ColorRect.new()
			separator.color = Color(UI.CYAN_SOFT, 0.55)
			separator.custom_minimum_size = Vector2(1, ceili(22.0 * ui_factor))
			separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
			currency_bar.add_child(separator)

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

func set_overlay_background(texture: Texture2D, enabled := true, opacity := 0.14) -> void:
	background_texture.texture = texture
	background_texture.modulate = Color(0.72, 0.86, 1.0, clampf(opacity, 0.0, 1.0))
	background_texture.visible = enabled and texture != null

func _action_icon(action: String) -> String:
	if action == "nav:home": return "res://assets/ui/icons/footer_home_v2.svg"
	if action == "nav:workshop": return "res://assets/ui/icons/footer_workshop_v2.svg"
	if action == "nav:loadout": return "res://assets/ui/icons/footer_loadout_v2.svg"
	if action == "nav:codex": return "res://assets/ui/icons/footer_codex_v2.svg"
	if action == "nav:settings": return "res://assets/ui/icons/footer_settings_v2.svg"
	if action in ["start", "resume"]: return "res://assets/ui/icons/launch.svg"
	if action == "manage_loadout": return "res://assets/ui/icons/loadout.svg"
	if action == "ship_systems": return "res://assets/ui/icons/systems.svg"
	if action == "blueprints" or action.begins_with("blueprint") or action.begins_with("view_blueprints"): return "res://assets/ui/icons/blueprints.svg"
	if action == "back" or action.begins_with("back_"): return "res://assets/ui/icons/back.svg"
	return ""

func set_ui_factor(factor: float) -> void:
	ui_factor = factor
	footer_shell.visible = true
	_resize_controls(self, factor)
	_rebuild_currency_status()

func _resize_controls(node: Node, factor: float) -> void:
	if node is Button:
		if node.has_meta("nav_dock"):
			node.custom_minimum_size = Vector2(0, ceil(38.0 * factor))
			node.add_theme_font_size_override("font_size", ceili(8.0 * factor))
		elif node.has_meta("compact_upgrade"):
			node.custom_minimum_size = Vector2(84.0 * factor, ceil(40.0 * factor))
			node.add_theme_font_size_override("font_size", ceili(9.0 * factor))
		elif node.has_meta("workshop_upgrade"):
			if node.has_meta("workshop_upgrade_narrow"):
				node.custom_minimum_size = Vector2(78.0 * factor, ceil(42.0 * factor))
				node.add_theme_font_size_override("font_size", ceili(9.0 * factor))
			else:
				node.custom_minimum_size = Vector2(124.0 * factor, ceil(50.0 * factor))
				node.add_theme_font_size_override("font_size", ceili(12.0 * factor))
		elif node.has_meta("compact_action"):
			node.custom_minimum_size = Vector2(node.custom_minimum_size.x, ceil(30.0 * factor))
			node.add_theme_font_size_override("font_size", ceili(9.0 * factor))
		else:
			# Keep normal actions at the platform touch-target minimum. The previous
			# 50px baseline made the four-row paused-run action grid exceed a short
			# landscape viewport after stretch scaling.
			node.custom_minimum_size.y = ceil(44.0 * factor)
			node.add_theme_font_size_override("font_size", ceili(13.0 * factor))
	elif node is TextureRect and node.has_meta("preview_size"):
		node.custom_minimum_size = Vector2.ONE * minf(72,float(node.get_meta("preview_size"))) * factor
	elif node is PanelContainer and node.has_meta("nav_dock_tile"):
		node.custom_minimum_size = Vector2(0, ceil(78.0 * factor))
	elif node is RichTextLabel:
		if not node.has_meta("standard_header_label"):
			node.add_theme_font_size_override("normal_font_size", ceili(float(node.get_meta("base_font_size", 13.0)) * factor))
		if node.has_meta("inline_icon_source"):
			_set_inline_icon_text(node, str(node.get_meta("inline_icon_source")), int(node.get_meta("inline_icon_font_size", 13)))
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
	_set_inline_icon_text(label, text, font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_meta("base_font_size", mini(font_size, 15))
	UI.apply_rich_text(label, font_size, color, true)
	return label

func _compact_card_label(text: String, font_size: int, color: Color) -> RichTextLabel:
	var label := _card_label(text, font_size, color)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.fit_content = true
	return label

func _upgrade_row_label(text: String, font_size: int, color: Color, bold_700 := false) -> Label:
	var label := UI.label(text, font_size, color, false)
	if bold_700: label.add_theme_font_override("font", UI.static_font(UI.WEIGHT_BOLD))
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	return label

func _add_workshop_overview(data: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 88 * ui_factor
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", UI.panel(UI.CYAN, 0.92, 9, 1))
	rows.add_child(panel)
	var schematic := TextureRect.new()
	# The schematic is decorative. Skipping it in headless checks keeps the test
	# runner from allocating a dummy GPU texture solely for menu presentation.
	if DisplayServer.get_name() != "headless": schematic.texture = load(WORKSHOP_SCHEMATIC_PATH)
	schematic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	schematic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	schematic.modulate = Color(0.72, 0.9, 1.0, 0.5)
	schematic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(schematic)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4 * ui_factor)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content)
	var overview_heading := HBoxContainer.new()
	overview_heading.add_theme_constant_override("separation", 6 * ui_factor)
	content.add_child(overview_heading)
	var overview_title := _card_label("SYSTEM CALIBRATION", 11, UI.CYAN_SOFT)
	overview_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overview_heading.add_child(overview_title)
	if data.has("context_action"):
		var reset := button(str(data.context_action.get("text", "RESET")), str(data.context_action.get("action", "reset_workshop")), bool(data.context_action.get("disabled", false)))
		reset.set_meta("compact_action", true)
		reset.custom_minimum_size = Vector2(58 * ui_factor, 24 * ui_factor)
		reset.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		reset.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		reset.add_theme_font_size_override("font_size", ceili(8 * ui_factor))
		overview_heading.add_child(reset)
	content.add_child(_card_label("SHIP OUTPUT", 16, UI.TEXT))
	var stat_row := HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 5 * ui_factor)
	content.add_child(stat_row)
	for stat in data.get("stats", []):
		var cell := _upgrade_panel(Color("#071824", 0.86), 4)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_row.add_child(cell)
		var words := VBoxContainer.new()
		cell.add_child(words)
		words.add_child(_card_label(str(stat.get("label", "OUTPUT")).to_upper(), 9, Color("#9bc7d5")))
		words.add_child(_card_label(str(stat.get("value", "0")), 14, Color("#f7c95f")))

func _add_workshop_section(data: Dictionary) -> void:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 7 * ui_factor)
	line.custom_minimum_size.y = 24 * ui_factor
	rows.add_child(line)
	var marker := ColorRect.new()
	marker.color = Color(str(data.get("accent", "#12d9f2")))
	marker.custom_minimum_size = Vector2(3 * ui_factor, 22 * ui_factor)
	line.add_child(marker)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(words)
	words.add_child(_card_label(str(data.get("title", "SYSTEMS")).to_upper(), 13, UI.TEXT))
	var description := str(data.get("description", ""))
	if not description.is_empty(): words.add_child(_card_label(description, 9, UI.MUTED))

func _add_tier_brief(data: Dictionary) -> void:
	rows.add_theme_constant_override("separation", ceili(8.0 * ui_factor))
	for reward in data.get("rewards", []):
		_add_tier_reward_row(reward)
	_add_tier_brief_note()

func _add_tier_reward_row(reward: Dictionary) -> void:
	var narrow := get_viewport_rect().size.x / maxf(0.1, ui_factor) < 560.0
	var state := str(reward.get("state", "locked"))
	var reward_type := str(reward.get("type", "cache"))
	var row := PanelContainer.new()
	row.custom_minimum_size.y = ceili((78.0 if narrow else 94.0) * ui_factor)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#071925", 0.90)
	style.border_color = Color("#2b6078", 0.92)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 10.0 * ui_factor
	style.content_margin_right = 10.0 * ui_factor
	style.content_margin_top = 7.0 * ui_factor
	style.content_margin_bottom = 7.0 * ui_factor
	row.add_theme_stylebox_override("panel", style)
	rows.add_child(row)
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", ceili(8.0 * ui_factor))
	row.add_child(content)
	var wave_box := VBoxContainer.new()
	wave_box.custom_minimum_size.x = (54.0 if narrow else 68.0) * ui_factor
	wave_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(wave_box)
	var wave_label := UI.label("WAVE", ceili(10.0 * ui_factor), UI.CYAN_SOFT, true)
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_box.add_child(wave_label)
	var wave_value := UI.label(str(int(reward.get("wave", 0))), ceili((27.0 if narrow else 34.0) * ui_factor), UI.TEXT, true)
	wave_value.add_theme_font_override("font", UI.static_font(UI.WEIGHT_BOLD))
	wave_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_box.add_child(wave_value)
	var divider := ColorRect.new()
	divider.color = Color(UI.CYAN_SOFT, 0.58)
	divider.custom_minimum_size = Vector2(1, ceili((38.0 if narrow else 48.0) * ui_factor))
	divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(divider)
	var reward_content := HBoxContainer.new()
	reward_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reward_content.add_theme_constant_override("separation", ceili(8.0 * ui_factor))
	content.add_child(reward_content)
	if reward_type == "cache":
		_add_tier_cache_reward(reward_content, reward, narrow)
	else:
		_add_tier_visual_reward(reward_content, reward, narrow)
	content.add_child(_tier_reward_status(reward, narrow))

func _add_tier_cache_reward(parent: HBoxContainer, reward: Dictionary, narrow: bool) -> void:
	var art_lane := _tier_reward_art_lane(parent, narrow)
	var amount_box := HBoxContainer.new()
	amount_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	amount_box.add_theme_constant_override("separation", ceili(7.0 * ui_factor))
	art_lane.add_child(amount_box)
	for payload in [
		{"currency":"credits", "amount":"×%s" % str(int(reward.get("credits", 0)))},
		{"currency":"boss_module", "amount":"×%s" % str(int(reward.get("modules", 0)))},
	]:
		var token := VBoxContainer.new()
		token.alignment = BoxContainer.ALIGNMENT_CENTER
		token.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		amount_box.add_child(token)
		var icon := TextureRect.new()
		var icon_size := ceili((25.0 if narrow else 31.0) * ui_factor)
		icon.texture = UI.currency_icon(str(payload.currency), icon_size)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2.ONE * icon_size
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		token.add_child(icon)
		var amount := UI.label(str(payload.amount), ceili(9.0 * ui_factor), UI.TEXT, true)
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		token.add_child(amount)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(details)
	var title := UI.label("CREDITS", ceili(10.0 * ui_factor), UI.TEXT, true)
	title.add_theme_font_override("font", UI.static_font(UI.WEIGHT_BOLD))
	details.add_child(title)
	details.add_child(UI.label("MODULES", ceili(9.0 * ui_factor), UI.CYAN_SOFT, true))

func _add_tier_visual_reward(parent: HBoxContainer, reward: Dictionary, narrow: bool) -> void:
	var art_lane := _tier_reward_art_lane(parent, narrow)
	var art := TextureRect.new()
	art.texture = load(str(reward.get("art", "")))
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = Vector2((72.0 if narrow else 92.0) * ui_factor, (46.0 if narrow else 58.0) * ui_factor)
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.modulate = Color(0.58, 0.91, 1.0, 0.96)
	art_lane.add_child(art)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(details)
	var title := UI.label(str(reward.get("title", "UNLOCK")), ceili(11.0 * ui_factor), UI.TEXT, true)
	title.add_theme_font_override("font", UI.static_font(UI.WEIGHT_BOLD))
	details.add_child(title)
	var detail := UI.label(str(reward.get("detail", "Blueprint")).to_upper(), ceili(9.0 * ui_factor), UI.CYAN_SOFT, true)
	details.add_child(detail)

## Every reward reserves the same presentation lane. This keeps reward titles
## aligned across currency bundles, weapon artwork and future reward types.
func _tier_reward_art_lane(parent: HBoxContainer, narrow: bool) -> CenterContainer:
	var lane := CenterContainer.new()
	lane.custom_minimum_size = Vector2((86.0 if narrow else 108.0) * ui_factor, 0.0)
	lane.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	lane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(lane)
	return lane

func _tier_reward_status(reward: Dictionary, narrow: bool) -> Control:
	var state := str(reward.get("state", "locked"))
	var status_size := Vector2((98.0 if narrow else 126.0) * ui_factor, (42.0 if narrow else 50.0) * ui_factor)
	if state == "claimable":
		var claim := Button.new()
		claim.custom_minimum_size = status_size
		claim.size_flags_horizontal = Control.SIZE_SHRINK_END
		claim.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		claim.text = "CLAIM"
		claim.tooltip_text = "Claim Tier reward"
		claim.alignment = HORIZONTAL_ALIGNMENT_CENTER
		claim.add_theme_font_override("font", UI.static_font(UI.WEIGHT_BOLD))
		claim.add_theme_font_size_override("font_size", ceili(10.0 * ui_factor))
		claim.add_theme_color_override("font_color", Color("#ffe4a3"))
		var claim_style := StyleBoxFlat.new()
		claim_style.bg_color = Color("#3d2c09", 0.90)
		claim_style.border_color = UI.GOLD
		claim_style.set_border_width_all(1)
		claim_style.corner_radius_top_left = 4
		claim_style.corner_radius_bottom_right = 4
		claim.add_theme_stylebox_override("normal", claim_style)
		var claim_hover := claim_style.duplicate() as StyleBoxFlat
		claim_hover.bg_color = Color("#584110", 0.98)
		claim.add_theme_stylebox_override("hover", claim_hover)
		claim.add_theme_stylebox_override("pressed", claim_hover)
		claim.pressed.connect(func(): selected.emit("claim_tier_reward:%s" % str(reward.get("id", ""))))
		return claim
	var status := PanelContainer.new()
	status.custom_minimum_size = status_size
	status.size_flags_horizontal = Control.SIZE_SHRINK_END
	status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#06131f", 0.68)
	style.border_color = Color("#496b80", 0.86)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 6.0 * ui_factor
	style.content_margin_right = 6.0 * ui_factor
	status.add_theme_stylebox_override("panel", style)
	var line := HBoxContainer.new()
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_theme_constant_override("separation", 5.0 * ui_factor)
	status.add_child(line)
	if state == "claimed":
		line.add_child(UI.label("CLAIMED", ceili(10.0 * ui_factor), UI.MUTED, true))
	elif state == "unlocked":
		style.border_color = Color(UI.CYAN, 0.94)
		line.add_child(UI.label("UNLOCKED", ceili(10.0 * ui_factor), UI.CYAN, true))
	else:
		var lock := TextureRect.new()
		lock.texture = load("res://assets/ui/icons/lock.svg")
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.custom_minimum_size = Vector2.ONE * ceili(18.0 * ui_factor)
		lock.modulate = Color(UI.STEEL, 0.90)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(lock)
		var locked_words := VBoxContainer.new()
		locked_words.alignment = BoxContainer.ALIGNMENT_CENTER
		line.add_child(locked_words)
		locked_words.add_child(UI.label("LOCKED", ceili(9.0 * ui_factor), UI.STEEL, true))
		locked_words.add_child(UI.label("WAVE %d" % int(reward.get("wave", 0)), ceili(8.0 * ui_factor), UI.MUTED, true))
	return status

func _add_tier_brief_note() -> void:
	var note := PanelContainer.new()
	note.custom_minimum_size.y = ceili(58.0 * ui_factor)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#071925", 0.86)
	style.border_color = Color("#2b6078", 0.86)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 12.0 * ui_factor
	style.content_margin_right = 12.0 * ui_factor
	note.add_theme_stylebox_override("panel", style)
	rows.add_child(note)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10.0 * ui_factor)
	note.add_child(line)
	var info := UI.label("i", ceili(22.0 * ui_factor), UI.CYAN, true)
	info.custom_minimum_size.x = 16.0 * ui_factor
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(info)
	var divider := ColorRect.new()
	divider.color = Color(UI.CYAN_SOFT, 0.55)
	divider.custom_minimum_size = Vector2(1, ceili(28.0 * ui_factor))
	divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(divider)
	var copy := UI.label("WAVES CONTINUE AFTER TIER UNLOCK", ceili(10.0 * ui_factor), UI.TEXT, true)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(copy)

func _add_upgrade_card(entry: Dictionary) -> void:
	var narrow := get_viewport_rect().size.x / maxf(0.1, ui_factor) < 700.0
	var card := PanelContainer.new()
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#071722", 0.92)
	style.border_color = Color("#28546b", 0.78)
	style.set_border_width_all(1)
	style.border_width_left = 3
	style.corner_radius_top_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	card.add_theme_stylebox_override("panel", style)
	rows.add_child(card)
	var shell := HBoxContainer.new()
	shell.add_theme_constant_override("separation", 7 * ui_factor)
	card.add_child(shell)
	# The icon spans both content rows, so its width must match that visual weight.
	var card_icon := _upgrade_icon_box(entry, 52 if narrow else 64)
	card_icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(card_icon)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 4 * ui_factor)
	shell.add_child(content)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 7 * ui_factor)
	content.add_child(heading)
	var title := _upgrade_row_label(str(entry.upgrade_name).to_upper(), 14 if narrow else 16, UI.TEXT, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	heading.add_child(_upgrade_row_label("LV. %d / %d" % [entry.level, entry.cap], 10 if narrow else 12, UI.CYAN_SOFT))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", (5 if narrow else 10) * ui_factor)
	row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	content.add_child(row)
	row.add_child(_upgrade_metric("EFFECTIVE", str(entry.get("effective_value", "0")), 15 if narrow else 17, Color("#f7c95f"), 72 if narrow else 88, str(entry.get("multiplier_value", "")), true))
	if not narrow: _add_upgrade_divider(row)
	var next_metric := _upgrade_metric("NEXT", str(entry.get("next_hint", "MAX")), 15 if narrow else 17, UI.TEXT, 80 if narrow else 112, "", true)
	row.add_child(next_metric)
	if not narrow: _add_upgrade_divider(row)
	row.add_child(_upgrade_cost_metric(str(entry.get("price_text", "0")), narrow, str(entry.get("currency_id", "credits"))))
	var purchase: Dictionary = entry.purchase
	var buy := button(purchase.text, purchase.action, purchase.disabled)
	buy.set_meta("workshop_upgrade", true)
	if narrow: buy.set_meta("workshop_upgrade_narrow", true)
	if narrow and buy.text != "MAX": buy.text = "UPGRADE"
	buy.custom_minimum_size = Vector2((102 if narrow else 124) * ui_factor, (42 if narrow else 50) * ui_factor)
	buy.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buy.add_theme_font_size_override("font_size", ceili((9 if narrow else 12) * ui_factor))
	row.add_child(buy)

func _add_upgrade_divider(parent: Container) -> void:
	var divider := ColorRect.new()
	divider.color = Color("#255267", 0.72)
	divider.custom_minimum_size = Vector2(1 * ui_factor, 42 * ui_factor)
	divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(divider)

func _upgrade_metric(caption: String, value: String, value_size: int, color: Color, width := 72, detail := "", value_bold_700 := false) -> VBoxContainer:
	return _upgrade_metric_with_detail(caption, value, value_size, color, width, detail, value_bold_700)

func _upgrade_metric_with_detail(caption: String, value: String, value_size: int, color: Color, width := 72, detail := "", value_bold_700 := false) -> VBoxContainer:
	var metric := VBoxContainer.new()
	metric.custom_minimum_size.x = width * ui_factor
	metric.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metric.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	metric.add_child(_upgrade_row_label(caption, 11, UI.MUTED))
	metric.add_child(_upgrade_row_label(value, value_size, color, value_bold_700))
	if not detail.is_empty(): metric.add_child(_upgrade_row_label(detail, 9, UI.CYAN_SOFT))
	return metric

func _upgrade_icon_box(entry: Dictionary, size: float) -> PanelContainer:
	var icon_box := _upgrade_panel(Color("#0a2232"), 3)
	icon_box.custom_minimum_size = Vector2(size, size) * ui_factor
	icon_box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	icon_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon := TextureRect.new()
	icon.texture = _upgrade_icon(str(entry.get("id", "")), str(entry.get("category", "")), str(entry.get("upgrade_name", "")))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(size * 0.54, size * 0.54) * ui_factor
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_box.add_child(icon)
	return icon_box

func _upgrade_cost_metric(price: String, narrow: bool, currency_id := "credits") -> VBoxContainer:
	var metric := VBoxContainer.new()
	metric.custom_minimum_size.x = (62 if narrow else 92) * ui_factor
	metric.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metric.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	metric.add_child(_upgrade_row_label("COST", 11, UI.MUTED))
	if price.is_empty():
		return metric
	var value_row := HBoxContainer.new()
	value_row.add_theme_constant_override("separation", 3 * ui_factor)
	metric.add_child(value_row)
	var coin := TextureRect.new()
	coin.texture = UI.currency_icon(currency_id)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.custom_minimum_size = Vector2((10 if narrow else 15), (10 if narrow else 15)) * ui_factor
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_row.add_child(coin)
	value_row.add_child(_upgrade_row_label(price, 15 if narrow else 17, UI.CYAN_SOFT, true))
	return metric

func _build_navigation_dock(title: String) -> void:
	_clear(navigation_dock)
	var active := navigation_context if not navigation_context.is_empty() else "home"
	if navigation_context.is_empty():
		if title == "WORKSHOP": active = "workshop"
		elif title == "CHASSIS BAY" or title.contains("LOADOUT"): active = "loadout"
		elif title.contains("CODEX") or title.contains("INTEL"): active = "codex"
		elif title == "SETTINGS": active = "settings"
	var navigation_items: Array = [
		{"id":"home", "text":"EXPEDITION", "icon_index":0},
		{"id":"loadout", "text":"LOADOUT", "icon_index":1},
		{"id":"workshop", "text":"WORKSHOP", "icon_index":2},
		{"id":"codex", "text":"CODEX", "icon_index":3},
		{"id":"settings", "text":"SETTINGS", "icon_index":4}
	]
	for index in navigation_items.size():
		var item: Dictionary = navigation_items[index]
		var item_id := str(item.get("id", "home"))
		var tile := PanelContainer.new()
		tile.set_meta("nav_dock_tile", true)
		tile.custom_minimum_size = Vector2(0, 78 * ui_factor)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tile_style := StyleBoxFlat.new()
		tile_style.bg_color = Color.TRANSPARENT
		tile_style.set_border_width_all(0)
		tile_style.set_corner_radius_all(0)
		tile_style.content_margin_top = 0
		tile_style.content_margin_bottom = 0
		tile.add_theme_stylebox_override("panel", tile_style)
		var stack := VBoxContainer.new()
		stack.add_theme_constant_override("separation", 0)
		tile.add_child(stack)
		var active_marker := ColorRect.new()
		active_marker.color = Color(UI.CYAN, 0.95) if item_id == active else Color.TRANSPARENT
		active_marker.custom_minimum_size.y = ceili(2.0 * ui_factor)
		active_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(active_marker)
		var content := VBoxContainer.new()
		content.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_theme_constant_override("separation", ceili(2.0 * ui_factor))
		stack.add_child(content)
		var icon := TextureRect.new()
		icon.texture = _home_footer_icon(int(item.get("icon_index", 0)))
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(31.0, 31.0) * ui_factor
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.modulate = Color.WHITE if item_id == active else Color(0.62, 0.74, 0.87, 0.88)
		content.add_child(icon)
		var caption := UI.label(str(item.text), ceili(10.0 * ui_factor), UI.CYAN if item_id == active else UI.MUTED, true)
		caption.add_theme_font_override("font", UI.static_font(UI.WEIGHT_BOLD if item_id == active else UI.WEIGHT_MEDIUM))
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(caption)
		var destination := "nav:%s" % item_id
		var tap := Button.new()
		tap.flat = true
		tap.tooltip_text = str(item.text).capitalize()
		tap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tap.pressed.connect(func(): selected.emit(destination))
		tile.add_child(tap)
		navigation_dock.add_child(tile)
		if index < navigation_items.size() - 1:
			var separator := ColorRect.new()
			separator.color = Color(UI.CYAN_SOFT, 0.28)
			separator.custom_minimum_size = Vector2(1, ceili(56.0 * ui_factor))
			separator.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
			navigation_dock.add_child(separator)

func _upgrade_icon(id: String, category: String, upgrade_name: String) -> Texture2D:
	# Gameplay IDs are intentionally stable; the generated visual names are descriptive.
	# Keep their translation here so a renamed visual can never silently fall back to a generic icon.
	var asset_id: String = {
		"damage": "ship_attack",
		"crit_chance": "critical_chance",
		"max_hp": "hull",
		"regen": "hull_regeneration",
	}.get(id, id)
	var generated_path := "res://assets/ui/workshop/upgrade_icons/%s_v1.png" % asset_id
	if not id.is_empty() and ResourceLoader.exists(generated_path): return load(generated_path)
	var path := "res://assets/ui/icons/upgrade_chevrons.svg"
	if category == "Attack": path = "res://assets/ui/icons/damage.svg"
	elif category == "Defense":
		path = "res://assets/ui/icons/shield.svg" if upgrade_name.to_lower().contains("shield") else "res://assets/ui/icons/hull.svg"
	elif category == "Utility": path = "res://assets/ui/icons/reload.svg"
	return load(path)

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
	return UI.rich()

func _set_inline_icon_text(label: RichTextLabel, source: String, font_size: int) -> void:
	label.set_meta("inline_icon_source", source)
	label.set_meta("inline_icon_font_size", font_size)
	label.text = _icon_text(source, _inline_icon_size(font_size))

func _inline_icon_size(font_size: int) -> int:
	return clampi(ceili(font_size * ui_factor), 10, 18)

func _icon_text(value: String, pixels: int) -> String:
	var icons := {"◈":UI.currency_path("credits"),"¤":UI.currency_path("cash"),"▣":UI.currency_path("boss_module"),"★":"res://assets/ui/icons/star.svg","☆":"res://assets/ui/icons/star_empty.svg","✦":"res://assets/ui/icons/star.svg","✓":"res://assets/ui/icons/unlocked.svg","◇":"res://assets/ui/icons/lock.svg","→":"res://assets/ui/icons/arrow.svg"}
	for symbol in icons:
		value = value.replace(symbol,"[img=%dx%d]%s[/img]" % [pixels,pixels,icons[symbol]])
	return value
