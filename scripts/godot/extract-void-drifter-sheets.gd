extends SceneTree

const SHIP_FRAMES := {
	"player_ship_idle": Rect2i(0, 0, 768, 341),
	"player_ship_bank_left": Rect2i(768, 0, 768, 341),
	"player_ship_bank_right": Rect2i(1536, 0, 768, 341),
	"player_ship_boost": Rect2i(768, 341, 768, 341),
	"player_ship_damaged": Rect2i(1536, 682, 768, 342),
	"player_ship_shield": Rect2i(0, 682, 768, 342),
	"player_ship_icon": Rect2i(2304, 682, 768, 342),
}

const VFX_FRAMES := {
	"player_plasma_bolt": Rect2i(30, 42, 150, 210),
	"player_laser_beam": Rect2i(250, 24, 120, 250),
	"enemy_red_bullet": Rect2i(448, 66, 132, 190),
	"enemy_purple_shot": Rect2i(614, 78, 142, 170),
	"hit_spark": Rect2i(780, 78, 174, 170),
	"small_explosion": Rect2i(44, 328, 300, 276),
	"enemy_death_explosion": Rect2i(378, 318, 300, 300),
	"shield_impact": Rect2i(690, 328, 320, 224),
	"engine_trail": Rect2i(590, 686, 118, 294),
	"levelup_burst": Rect2i(756, 712, 260, 260),
}

func _init() -> void:
	var options := _parse_args(OS.get_cmdline_user_args())
	var ship_sheet := String(options.get("ship-sheet", ""))
	var vfx_sheet := String(options.get("vfx-sheet", ""))

	if ship_sheet == "" or vfx_sheet == "":
		push_error("Usage: godot --headless --path godot/void-drifter --script scripts/godot/extract-void-drifter-sheets.gd -- --ship-sheet=<path> --vfx-sheet=<path>")
		quit(1)
		return

	_extract_sheet(ship_sheet, "res://assets/player_ship", SHIP_FRAMES, true, 0.018, 0.055, 18)
	_extract_sheet(vfx_sheet, "res://assets/vfx", VFX_FRAMES, true, 0.070, 0.180, 10)
	print("Extracted VOID DRIFTER ship and VFX sheet assets.")
	quit(0)

func _parse_args(args: PackedStringArray) -> Dictionary:
	var options := {}
	for arg in args:
		if not arg.begins_with("--") or not arg.contains("="):
			continue
		var parts := arg.substr(2).split("=", true, 1)
		options[parts[0]] = parts[1]
	return options

func _extract_sheet(source_path: String, output_dir: String, frames: Dictionary, remove_black: bool, alpha_threshold: float, alpha_fade: float, trim_padding: int) -> void:
	var image := Image.new()
	var error := image.load(_global_path(source_path))
	if error != OK:
		push_error("Could not load sheet: %s" % source_path)
		quit(1)
		return

	image.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute(_global_path(output_dir))

	for frame_name in frames.keys():
		var cell := _crop_image(image, frames[frame_name])
		if remove_black:
			_remove_dark_background(cell, alpha_threshold, alpha_fade)
		var trimmed := _trim_image(cell, trim_padding)
		var output_path := _global_path("%s/%s.png" % [output_dir, frame_name])
		var save_error := trimmed.save_png(output_path)
		if save_error != OK:
			push_error("Could not save sprite: %s" % output_path)
			quit(1)
			return

func _crop_image(source: Image, rect: Rect2i) -> Image:
	var cropped := Image.create_empty(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	cropped.blit_rect(source, rect, Vector2i.ZERO)
	return cropped

func _remove_dark_background(image: Image, alpha_threshold: float, alpha_fade: float) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			var glow := maxf(color.r, maxf(color.g, color.b))
			var alpha := clampf((glow - alpha_threshold) / alpha_fade, 0.0, color.a)
			if alpha <= 0.01:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				color.a = minf(color.a, alpha)
				image.set_pixel(x, y, color)

func _trim_image(image: Image, padding: int) -> Image:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1

	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.02:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)

	if max_x < min_x or max_y < min_y:
		return image

	min_x = maxi(0, min_x - padding)
	min_y = maxi(0, min_y - padding)
	max_x = mini(image.get_width() - 1, max_x + padding)
	max_y = mini(image.get_height() - 1, max_y + padding)

	var rect := Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
	return _crop_image(image, rect)

func _global_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	return path
