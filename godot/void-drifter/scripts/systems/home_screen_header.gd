class_name HomeScreenHeader
extends Control

## Home is the only screen with a campaign wordmark. Keeping it separate from
## StandardScreenHeader prevents ordinary menus from inheriting decorative art.

const WORDMARK_PATH := "res://assets/ui/home/void_drifter_wordmark_v1.png"

var wordmark: TextureRect
var ui_factor := 1.0
var _syncing_height := false

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y = 120.0
	wordmark = TextureRect.new()
	wordmark.texture = load(WORDMARK_PATH)
	wordmark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wordmark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wordmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wordmark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(wordmark)
	resized.connect(_layout)
	_layout()

func set_ui_factor(factor: float) -> void:
	ui_factor = factor
	_layout()

func _layout() -> void:
	if size.x <= 0.0 or _syncing_height:
		return
	# Preserve the generated wordmark ratio. The artwork contains transparent
	# breathing room, so no decorative panel or hand-drawn replacement is needed.
	var desired_height := maxf(100.0 * ui_factor, round(size.x * 724.0 / 2172.0))
	if not is_equal_approx(custom_minimum_size.y, desired_height):
		_syncing_height = true
		custom_minimum_size.y = desired_height
		_syncing_height = false
