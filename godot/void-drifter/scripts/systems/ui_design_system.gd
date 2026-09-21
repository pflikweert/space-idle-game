extends RefCounted

## Shared visual language for the command-deck UI.
## Keep screen logic in the owning panels; this file owns only reusable visual
## tokens and constructors so new screens do not invent a second UI language.

const FONT_RESOURCE := preload("res://assets/ui/fonts/Oxanium-Variable.ttf")

const INK := Color("#050b16")
const SURFACE := Color("#071824")
const SURFACE_RAISED := Color("#0b2231")
const GRID := Color("#17384d")
const CYAN := Color("#12d9f2")
const CYAN_SOFT := Color("#8bddea")
const BLUE := Color("#5d9cff")
const VIOLET := Color("#b66cff")
const GOLD := Color("#f5bd3d")
const MINT := Color("#69e6b5")
const STEEL := Color("#71879a")
const TEXT := Color("#e9f7ff")
const MUTED := Color("#9bb8c7")
const DISABLED := Color("#415465")

const DISPLAY_LARGE := 28
const DISPLAY_MEDIUM := 21
const SECTION := 15
const BODY := 14
const META := 11
const BUTTON := 15

static var _regular: FontVariation
static var _bold: FontVariation

static func font(bold := false) -> FontVariation:
	if bold:
		if _bold == null:
			_bold = FontVariation.new()
			_bold.base_font = FONT_RESOURCE
			_bold.variation_opentype = {"wght": 700}
		return _bold
	if _regular == null:
		_regular = FontVariation.new()
		_regular.base_font = FONT_RESOURCE
		_regular.variation_opentype = {"wght": 500}
	return _regular

static func rarity_color(rarity: String, empty := false) -> Color:
	if empty: return STEEL
	match rarity.to_lower():
		"epic": return VIOLET
		"advanced", "rare": return BLUE
		"legendary": return GOLD
		_: return CYAN

static func label(text: String, size := BODY, color := TEXT, bold := true) -> Label:
	var control := Label.new()
	control.text = text
	control.add_theme_font_override("font", font(bold))
	control.add_theme_font_size_override("font_size", size)
	control.add_theme_color_override("font_color", color)
	control.add_theme_color_override("font_outline_color", Color(INK, 0.45))
	control.add_theme_constant_override("outline_size", 1)
	return control

static func rich(text := "", size := BODY, color := TEXT, bold := true) -> RichTextLabel:
	var control := RichTextLabel.new()
	control.bbcode_enabled = true
	control.fit_content = true
	control.scroll_active = false
	control.text = text
	control.add_theme_font_override("normal_font", font(bold))
	control.add_theme_font_override("bold_font", font(true))
	control.add_theme_font_override("italics_font", font(false))
	control.add_theme_font_size_override("normal_font_size", size)
	control.add_theme_color_override("default_color", color)
	return control

static func panel(accent := CYAN, alpha := 0.96, radius := 8, border := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(SURFACE, alpha)
	style.border_color = Color(accent, 0.9)
	style.set_border_width_all(border)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(accent, 0.16)
	style.shadow_size = 8
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func button(accent := CYAN, disabled := false, primary := false) -> StyleBoxFlat:
	var style := panel(accent if not disabled else DISABLED, 0.94 if not disabled else 0.78, 7, 2)
	style.bg_color = Color(SURFACE_RAISED if not primary else Color("#102f3a"), 0.96)
	if disabled:
		style.shadow_color = Color.TRANSPARENT
		style.shadow_size = 0
	return style

static func apply_text(control: Control, size: int, color := TEXT, bold := true) -> void:
	control.add_theme_font_override("font", font(bold))
	control.add_theme_font_size_override("font_size", size)
	control.add_theme_color_override("font_color", color)
	control.add_theme_color_override("default_color", color)

static func apply_rich_text(control: RichTextLabel, size: int, color := TEXT, bold := true) -> void:
	control.add_theme_font_override("normal_font", font(bold))
	control.add_theme_font_override("bold_font", font(true))
	control.add_theme_font_override("italics_font", font(false))
	control.add_theme_font_size_override("normal_font_size", size)
	control.add_theme_font_size_override("font_size", size)
	control.add_theme_color_override("default_color", color)
