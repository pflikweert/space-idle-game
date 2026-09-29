class_name StandardScreenHeader
extends Control

## The one shared command-deck header used by every ProgressionPanel screen.
## Its geometry is drawn here instead of approximated with nested rounded panels:
## a clipped outer frame, a dedicated left back zone, centred title and a single
## subtitle rail match the established Blueprint reference composition.

const UI := preload("res://scripts/systems/ui_design_system.gd")

signal back_pressed

var title_label: RichTextLabel
var subtitle_label: RichTextLabel
var back_hitbox: Button
var ui_factor := 1.0
var _syncing_height := false
var _back_available := true
var _home_variant := false

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y = 67.0
	clip_contents = true
	title_label = UI.rich("", UI.DISPLAY_LARGE, UI.TEXT, true)
	title_label.set_meta("standard_header_label", true)
	title_label.add_theme_font_override("normal_font", UI.static_font(UI.WEIGHT_BOLD))
	title_label.add_theme_font_override("bold_font", UI.static_font(UI.WEIGHT_BOLD))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.fit_content = false
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_label)
	subtitle_label = UI.rich("", UI.SECTION, UI.TEXT, false)
	subtitle_label.set_meta("standard_header_label", true)
	subtitle_label.add_theme_font_override("normal_font", UI.static_font(UI.WEIGHT_REGULAR))
	subtitle_label.add_theme_font_override("bold_font", UI.static_font(UI.WEIGHT_BOLD))
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	subtitle_label.fit_content = false
	subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle_label)
	back_hitbox = Button.new()
	back_hitbox.flat = true
	back_hitbox.tooltip_text = "Back"
	for state in ["normal", "hover", "pressed", "disabled"]:
		back_hitbox.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	back_hitbox.pressed.connect(func(): back_pressed.emit())
	add_child(back_hitbox)
	resized.connect(_layout)
	_layout()

func set_ui_factor(factor: float) -> void:
	ui_factor = factor
	_layout()
	queue_redraw()

func set_content(title: String, subtitle: String) -> void:
	# Headers intentionally carry one subtitle rail. Newline-heavy legacy menu
	# summaries collapse into a compact, single readable line rather than growing
	# the header and pushing content down the screen.
	title_label.text = title.replace("[center]", "").replace("[/center]", "").to_upper()
	var compact_subtitle := subtitle.get_slice("\n", 0).replace("◈", "").replace("▣", "").strip_edges()
	# The reference uses a single subtitle rail. Explicitly shorten legacy copy
	# instead of allowing centred rich text to clip from both sides.
	if compact_subtitle.length() > 42:
		compact_subtitle = compact_subtitle.left(41).strip_edges() + "…"
	subtitle_label.text = compact_subtitle
	queue_redraw()

func set_back_available(available: bool) -> void:
	_back_available = available
	back_hitbox.visible = available
	_layout()
	queue_redraw()

## The home screen is the only root screen that needs a little more ceremony.
## It still uses the exact same command-deck frame; this flag only grants the
## title and subtitle the vertical breathing room they need above campaign UI.
func set_home_variant(enabled: bool) -> void:
	if _home_variant == enabled:
		return
	_home_variant = enabled
	_layout()
	queue_redraw()

func _layout() -> void:
	if size.x > 0.0 and not _syncing_height:
		# Reference frame: 848 × 118. The home keeps the same geometry, expanded
		# to 848 × 230 for campaign identity without relying on a stretched image.
		var reference_height: float = round(size.x * (230.0 if _home_variant else 118.0) / 848.0)
		if not is_equal_approx(custom_minimum_size.y, reference_height):
			_syncing_height = true
			custom_minimum_size.y = reference_height
			_syncing_height = false
	var f := maxf(0.1, size.x / 848.0)
	var width := size.x
	back_hitbox.position = Vector2(27.0 * f, 25.0 * f)
	back_hitbox.size = Vector2(89.0 * f, 67.0 * f)
	if _home_variant:
		title_label.position = Vector2(42.0 * f, 43.0 * f)
		title_label.size = Vector2(maxf(1.0, width - 84.0 * f), 68.0 * f)
		title_label.add_theme_font_size_override("normal_font_size", roundi(55.0 * f))
		subtitle_label.position = Vector2(54.0 * f, 126.0 * f)
		subtitle_label.size = Vector2(maxf(1.0, width - 108.0 * f), 28.0 * f)
		subtitle_label.add_theme_font_size_override("normal_font_size", roundi(21.0 * f))
		return
	# Main screens have no back action, so reclaim that empty zone for a fully
	# readable centred title/subtitle rather than clipping the subtitle rail.
	var side_inset := (132.0 if _back_available else 42.0) * f
	title_label.position = Vector2(side_inset, 16.0 * f)
	title_label.size = Vector2(maxf(1.0, width - side_inset * 2.0), 46.0 * f)
	title_label.add_theme_font_size_override("normal_font_size", roundi(39.0 * f))
	var subtitle_inset := (144.0 if _back_available else 52.0) * f
	subtitle_label.position = Vector2(subtitle_inset, 72.0 * f)
	subtitle_label.size = Vector2(maxf(1.0, width - subtitle_inset * 2.0), 23.0 * f)
	subtitle_label.add_theme_font_size_override("normal_font_size", roundi(20.0 * f))

func _draw() -> void:
	var f := maxf(0.1, size.x / 848.0)
	var rect := Rect2(Vector2.ZERO, size)
	# Containers briefly assign a partial height before the width-derived minimum
	# has propagated. Do not triangulate a folded polygon during that frame.
	if rect.size.x <= 0.0 or rect.size.y < 40.0 * f:
		return
	var outer := PackedVector2Array([
		Vector2(10.0 * f, 9.0 * f), Vector2(rect.size.x - 24.0 * f, 9.0 * f), Vector2(rect.size.x - 14.0 * f, 19.0 * f),
		Vector2(rect.size.x - 14.0 * f, rect.size.y - 20.0 * f), Vector2(rect.size.x - 24.0 * f, rect.size.y - 10.0 * f),
		Vector2(10.0 * f, rect.size.y - 10.0 * f), Vector2(1.0 * f, rect.size.y - 19.0 * f), Vector2(1.0 * f, 19.0 * f)
	])
	draw_colored_polygon(outer, Color("#061725", 0.92 if _home_variant else 0.98))
	draw_polyline(PackedVector2Array([outer[0], outer[1], outer[2], outer[3], outer[4], outer[5], outer[6], outer[7], outer[0]]), UI.CYAN, maxf(1.0, 2.0 * f), true)
	if _back_available:
		var back := Rect2(Vector2(27.0 * f, 25.0 * f), Vector2(89.0 * f, 67.0 * f))
		var back_cut := 12.0 * f
		var back_points := PackedVector2Array([
			Vector2(back.position.x + back_cut, back.position.y), Vector2(back.end.x, back.position.y),
			Vector2(back.end.x, back.end.y - back_cut), Vector2(back.end.x - back_cut, back.end.y),
			Vector2(back.position.x, back.end.y), Vector2(back.position.x, back.position.y + back_cut)
		])
		draw_colored_polygon(back_points, Color("#0a2130", 0.96))
		draw_polyline(PackedVector2Array([back_points[0], back_points[1], back_points[2], back_points[3], back_points[4], back_points[5], back_points[0]]), UI.CYAN, maxf(1.0, 1.5 * f), true)
		draw_line(Vector2(76.0 * f, 43.0 * f), Vector2(59.0 * f, 59.0 * f), UI.CYAN_SOFT, maxf(1.0, 3.4 * f), true)
		draw_line(Vector2(59.0 * f, 59.0 * f), Vector2(76.0 * f, 75.0 * f), UI.CYAN_SOFT, maxf(1.0, 3.4 * f), true)
