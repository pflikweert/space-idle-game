extends SceneTree

const CELL_SIZE := Vector2i(384, 512)
const PREVIEW_SIZE := Vector2i(512, 512)
const DIRECTIONS := ["down", "up", "left", "right"]
const MOVEMENT_STATES := ["idle", "thrust"]
const COMBAT_STATES := ["attack", "hit"]
const VFX_NAMES := ["death-small", "death-medium", "death-large", "debris-cloud", "bullet-down", "bullet-up", "bullet-left", "bullet-right"]
const PREVIEW_CANDIDATES := ["thrust-right", "idle-right", "thrust-down", "idle-down", "thrust-up", "idle-up"]

const ENEMY_SHEETS := {
	"red-scout-drone": {
		"godot_dir": "red_scout_drone",
		"movement": "sheet-a-movement.png",
		"combat": "sheet-b-combat.png",
	},
	"red-fighter": {
		"godot_dir": "red_fighter",
		"movement": "sheet-a-movement.png",
		"combat": "sheet-b-combat.png",
	},
	"red-cruiser": {
		"godot_dir": "red_cruiser",
		"movement": "sheet-a-movement.png",
		"combat": "sheet-b-combat.png",
	},
}

func _init() -> void:
	var options := _parse_args(OS.get_cmdline_user_args())
	var repo_root := String(options.get("repo-root", ""))
	if repo_root == "":
		push_error("Usage: godot --headless --path godot/void-drifter --script scripts/godot/extract-void-drifter-enemies.gd -- --repo-root=<repo path>")
		quit(1)
		return

	repo_root = repo_root.trim_suffix("/")
	for enemy_id in ENEMY_SHEETS.keys():
		_extract_enemy(repo_root, enemy_id, ENEMY_SHEETS[enemy_id])
	_extract_shared_vfx(repo_root)
	print("Extracted VOID DRIFTER enemy assets from fixed 384x512 cells.")
	quit(0)

func _parse_args(args: PackedStringArray) -> Dictionary:
	var options := {}
	for arg in args:
		if not arg.begins_with("--") or not arg.contains("="):
			continue
		var parts := arg.substr(2).split("=", true, 1)
		options[parts[0]] = parts[1]
	return options

func _extract_enemy(repo_root: String, enemy_id: String, sheet_def: Dictionary) -> void:
	var source_dir := "%s/assets/game/enemies/%s/sheets" % [repo_root, enemy_id]
	var output_dir := "%s/assets/game/enemies/%s" % [repo_root, enemy_id]
	var godot_dir := "%s/godot/void-drifter/assets/enemies/%s" % [repo_root, sheet_def.godot_dir]

	var movement := _load_image("%s/%s" % [source_dir, sheet_def.movement])
	var combat := _load_image("%s/%s" % [source_dir, sheet_def.combat])
	if movement == null or combat == null:
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute("%s/frames-cell" % output_dir)
	DirAccess.make_dir_recursive_absolute("%s/frames-tight" % output_dir)
	DirAccess.make_dir_recursive_absolute(godot_dir)

	_remove_edge_background(movement)
	_remove_edge_background(combat)
	_extract_manual_state_rows(movement, MOVEMENT_STATES, enemy_id, "movement", "%s/frames-cell" % output_dir, "%s/frames-tight" % output_dir, godot_dir)
	_extract_manual_state_rows(combat, COMBAT_STATES, enemy_id, "combat", "%s/frames-cell" % output_dir, "%s/frames-tight" % output_dir, godot_dir)
	_generate_enemy_preview(output_dir, enemy_id)

func _extract_shared_vfx(repo_root: String) -> void:
	var source_path := "%s/assets/game/enemies/shared-vfx/sheets/enemy-shared-vfx.png" % repo_root
	var output_dir := "%s/assets/game/enemies/shared-vfx" % repo_root
	var godot_dir := "%s/godot/void-drifter/assets/enemies/shared_vfx" % repo_root
	var sheet := _load_image(source_path)
	if sheet == null:
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute("%s/frames-cell" % output_dir)
	DirAccess.make_dir_recursive_absolute("%s/frames-tight" % output_dir)
	DirAccess.make_dir_recursive_absolute(godot_dir)

	for index in range(VFX_NAMES.size()):
		var row := int(floor(float(index) / 4.0))
		var col := index % 4
		var frame_name: String = VFX_NAMES[index]
		var cell := _crop_image(sheet, Rect2i(col * CELL_SIZE.x, row * CELL_SIZE.y, CELL_SIZE.x, CELL_SIZE.y))
		var tight := _trim_image(cell, 8)
		_save_image(cell, "%s/frames-cell/%s.png" % [output_dir, frame_name])
		_save_image(tight, "%s/frames-tight/%s.png" % [output_dir, frame_name])
		_save_image(tight, "%s/%s.png" % [godot_dir, frame_name])

func _extract_state_rows(sheet: Image, states: Array, cell_dir: String, tight_dir: String, godot_dir: String) -> void:
	for row in range(states.size()):
		for col in range(DIRECTIONS.size()):
			var frame_name: String = "%s-%s" % [states[row], DIRECTIONS[col]]
			var cell := _crop_image(sheet, Rect2i(col * CELL_SIZE.x, row * CELL_SIZE.y, CELL_SIZE.x, CELL_SIZE.y))
			var centered := _center_alpha_on_canvas(cell, CELL_SIZE)
			var tight := _trim_image(centered, 8)
			_save_image(centered, "%s/%s.png" % [cell_dir, frame_name])
			_save_image(tight, "%s/%s.png" % [tight_dir, frame_name])
			_save_image(centered, "%s/%s.png" % [godot_dir, frame_name])

func _extract_manual_state_rows(sheet: Image, states: Array, enemy_id: String, sheet_kind: String, cell_dir: String, tight_dir: String, godot_dir: String) -> void:
	for row in range(states.size()):
		var centers := _get_slot_centers(enemy_id, sheet_kind, row)
		var front_crop_size := _get_crop_size(enemy_id)
		var side_crop_size := _get_side_crop_size(enemy_id)
		var down_cell := _make_gameplay_cell(sheet, centers.down, front_crop_size)
		var up_cell := _make_gameplay_cell(sheet, centers.up, front_crop_size)
		var side_cell := _make_gameplay_cell(sheet, centers.side, side_crop_size)
		var mirrored_side := side_cell.duplicate()
		mirrored_side.flip_x()

		var side_source_direction := _get_side_source_direction(enemy_id, sheet_kind, row)
		var frames := {
			"%s-down" % states[row]: down_cell,
			"%s-up" % states[row]: up_cell,
		}
		if side_source_direction == "right":
			frames["%s-right" % states[row]] = side_cell
			frames["%s-left" % states[row]] = mirrored_side
		else:
			frames["%s-left" % states[row]] = side_cell
			frames["%s-right" % states[row]] = mirrored_side

		for frame_name in frames.keys():
			var cell: Image = frames[frame_name]
			var tight := _trim_image(cell, 8)
			_save_image(cell, "%s/%s.png" % [cell_dir, frame_name])
			_save_image(tight, "%s/%s.png" % [tight_dir, frame_name])
			_save_image(cell, "%s/%s.png" % [godot_dir, frame_name])

func _get_slot_centers(enemy_id: String, sheet_kind: String, row: int) -> Dictionary:
	var y := 250 if row == 0 else 730
	if sheet_kind == "combat":
		y = 245 if row == 0 else 725

	match enemy_id:
		"red-scout-drone":
			if sheet_kind == "movement":
				return { "down": Vector2i(366, y), "up": Vector2i(764, y), "side": Vector2i(1198, y) }
			return { "down": Vector2i(520, y), "up": Vector2i(895, y), "side": Vector2i(1268, y) }
		"red-fighter":
			if sheet_kind == "movement":
				return { "down": Vector2i(260, y), "up": Vector2i(640, y), "side": Vector2i(1360, y) }
			return { "down": Vector2i(270, y), "up": Vector2i(640, y), "side": Vector2i(1292, y) }
		"red-cruiser":
			if sheet_kind == "movement":
				return { "down": Vector2i(280, y), "up": Vector2i(740, y), "side": Vector2i(1238, y) }
			return { "down": Vector2i(292, y), "up": Vector2i(742, y), "side": Vector2i(1242, y) }

	return { "down": Vector2i(300, y), "up": Vector2i(740, y), "side": Vector2i(1220, y) }

func _get_crop_size(enemy_id: String) -> Vector2i:
	match enemy_id:
		"red-scout-drone":
			return Vector2i(470, 470)
		"red-fighter":
			return Vector2i(560, 500)
		"red-cruiser":
			return Vector2i(660, 560)
	return Vector2i(520, 500)

func _get_side_crop_size(enemy_id: String) -> Vector2i:
	match enemy_id:
		"red-scout-drone":
			return Vector2i(420, 390)
		"red-fighter":
			return Vector2i(330, 330)
		"red-cruiser":
			return Vector2i(480, 340)
	return Vector2i(420, 360)

func _get_side_source_direction(enemy_id: String, sheet_kind: String, row: int) -> String:
	if enemy_id == "red-cruiser" and sheet_kind == "movement" and row == 1:
		return "right"
	return "left"

func _make_gameplay_cell(sheet: Image, center: Vector2i, crop_size: Vector2i) -> Image:
	var position := Vector2i(
		clampi(center.x - crop_size.x / 2, 0, max(0, sheet.get_width() - crop_size.x)),
		clampi(center.y - crop_size.y / 2, 0, max(0, sheet.get_height() - crop_size.y))
	)
	var cropped := _crop_image(sheet, Rect2i(position, crop_size))
	_remove_edge_background(cropped)
	_remove_residual_background(cropped)
	return _fit_alpha_on_canvas(cropped, CELL_SIZE, 14)

func _load_image(path: String) -> Image:
	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		push_error("Could not load image: %s" % path)
		return null
	image.convert(Image.FORMAT_RGBA8)
	return image

func _crop_image(source: Image, rect: Rect2i) -> Image:
	var cropped := Image.create_empty(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	cropped.blit_rect(source, rect, Vector2i.ZERO)
	return cropped

func _remove_edge_background(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var queue: Array[int] = []

	for x in range(width):
		queue.append(x)
		queue.append((height - 1) * width + x)
	for y in range(height):
		queue.append(y * width)
		queue.append(y * width + width - 1)

	var cursor := 0
	while cursor < queue.size():
		var index := queue[cursor]
		cursor += 1
		if index < 0 or index >= visited.size() or visited[index] == 1:
			continue

		var x := index % width
		var y := int(floor(float(index) / float(width)))
		var color := image.get_pixel(x, y)
		if not _is_background_candidate(color):
			continue

		visited[index] = 1
		color.a = 0.0
		image.set_pixel(x, y, color)

		if x > 0:
			queue.append(index - 1)
		if x < width - 1:
			queue.append(index + 1)
		if y > 0:
			queue.append(index - width)
		if y < height - 1:
			queue.append(index + width)

func _is_background_candidate(color: Color) -> bool:
	var brightness := maxf(color.r, maxf(color.g, color.b))
	var green_ratio := color.g / maxf(0.001, color.r)
	var blue_ratio := color.b / maxf(0.001, color.r)
	var warm_background := color.r > 0.08 and color.r > color.g * 1.08 and color.r > color.b * 1.08 and green_ratio > 0.24 and blue_ratio > 0.12 and color.g < 0.70 and color.b < 0.56
	var near_black_edge := brightness < 0.035
	return warm_background or near_black_edge

func _remove_residual_background(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a <= 0.0:
				continue

			var brightness := maxf(color.r, maxf(color.g, color.b))
			var green_ratio := color.g / maxf(0.001, color.r)
			var blue_ratio := color.b / maxf(0.001, color.r)
			var flame_core := color.r > 0.72 and color.g > 0.30 and color.b < 0.20
			var ship_red_panel := color.r > 0.16 and color.r > color.g * 1.55 and color.r > color.b * 1.50 and green_ratio < 0.32
			var soft_warm_backdrop := not flame_core and not ship_red_panel and color.r > 0.08 and green_ratio > 0.22 and blue_ratio > 0.13 and color.g < 0.72 and color.b < 0.58
			var low_detail_shadow := brightness < 0.026
			if soft_warm_backdrop or low_detail_shadow:
				color.a = 0.0
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
	return _crop_image(image, Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1))

func _center_alpha_on_canvas(image: Image, canvas_size: Vector2i) -> Image:
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

	var content_rect := Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
	var centered := Image.create_empty(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	centered.fill(Color(0, 0, 0, 0))
	var destination := Vector2i(
		int(floor(float(canvas_size.x - content_rect.size.x) / 2.0)),
		int(floor(float(canvas_size.y - content_rect.size.y) / 2.0))
	)
	centered.blit_rect(image, content_rect, destination)
	return centered

func _fit_alpha_on_canvas(image: Image, canvas_size: Vector2i, padding: int) -> Image:
	var tight := _trim_image(image, 2)
	var max_width: int = max(1, canvas_size.x - padding * 2)
	var max_height: int = max(1, canvas_size.y - padding * 2)
	var scale := minf(float(max_width) / float(tight.get_width()), float(max_height) / float(tight.get_height()))
	scale = minf(1.0, scale)

	if scale < 0.999:
		tight.resize(maxi(1, int(floor(float(tight.get_width()) * scale))), maxi(1, int(floor(float(tight.get_height()) * scale))), Image.INTERPOLATE_LANCZOS)

	var centered := Image.create_empty(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	centered.fill(Color(0, 0, 0, 0))
	var destination := Vector2i(
		int(floor(float(canvas_size.x - tight.get_width()) / 2.0)),
		int(floor(float(canvas_size.y - tight.get_height()) / 2.0))
	)
	centered.blit_rect(tight, Rect2i(Vector2i.ZERO, Vector2i(tight.get_width(), tight.get_height())), destination)
	return centered

func _generate_enemy_preview(output_dir: String, enemy_id: String) -> void:
	var best_image: Image = null
	var best_score := -1
	for candidate in PREVIEW_CANDIDATES:
		var image := _load_image("%s/frames-cell/%s.png" % [output_dir, candidate])
		if image == null:
			continue
		var alpha_info := _get_alpha_info(image)
		var score := int(alpha_info.alpha_pixels) + int(alpha_info.width * alpha_info.height / 12)
		if score > best_score:
			best_score = score
			best_image = image

	if best_image == null:
		return

	var preview := _make_preview_image(best_image)
	_save_image(preview, "%s/preview.png" % output_dir)
	print("%s preview alpha score: %d" % [enemy_id, best_score])

func _get_alpha_info(image: Image) -> Dictionary:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	var alpha_pixels := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.02:
				continue
			alpha_pixels += 1
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)

	if max_x < min_x or max_y < min_y:
		return { "alpha_pixels": 0, "width": 0, "height": 0 }

	return {
		"alpha_pixels": alpha_pixels,
		"width": max_x - min_x + 1,
		"height": max_y - min_y + 1,
	}

func _make_preview_image(source: Image) -> Image:
	var preview := Image.create_empty(PREVIEW_SIZE.x, PREVIEW_SIZE.y, false, Image.FORMAT_RGBA8)
	preview.fill(Color(0, 0, 0, 0))

	var scaled := source.duplicate()
	var max_width := PREVIEW_SIZE.x - 70
	var max_height := PREVIEW_SIZE.y - 58
	var scale := minf(float(max_width) / float(source.get_width()), float(max_height) / float(source.get_height()))
	var scaled_width := maxi(1, int(floor(float(source.get_width()) * scale)))
	var scaled_height := maxi(1, int(floor(float(source.get_height()) * scale)))
	scaled.resize(scaled_width, scaled_height, Image.INTERPOLATE_LANCZOS)
	var destination := Vector2i(
		int(floor(float(PREVIEW_SIZE.x - scaled_width) / 2.0)),
		int(floor(float(PREVIEW_SIZE.y - scaled_height) / 2.0))
	)

	for y in range(scaled.get_height()):
		for x in range(scaled.get_width()):
			var color: Color = scaled.get_pixel(x, y)
			if color.a <= 0.02:
				continue
			var alpha := minf(0.36, color.a * 0.28)
			for offset in [Vector2i(-12, 0), Vector2i(12, 0), Vector2i(0, -12), Vector2i(0, 12), Vector2i(-8, -8), Vector2i(8, -8), Vector2i(-8, 8), Vector2i(8, 8)]:
				_blend_pixel(preview, destination + Vector2i(x, y) + offset, Color(1.0, 0.08, 0.04, alpha))

	for y in range(scaled.get_height()):
		for x in range(scaled.get_width()):
			var color: Color = scaled.get_pixel(x, y)
			if color.a <= 0.02:
				continue
			color.r = minf(1.0, color.r * 1.34 + 0.10)
			color.g = minf(1.0, color.g * 1.20 + 0.05)
			color.b = minf(1.0, color.b * 1.16 + 0.04)
			color.a = minf(1.0, color.a * 1.12)
			_blend_pixel(preview, destination + Vector2i(x, y), color)

	return preview

func _blend_pixel(image: Image, position: Vector2i, color: Color) -> void:
	if position.x < 0 or position.y < 0 or position.x >= image.get_width() or position.y >= image.get_height():
		return

	var existing := image.get_pixel(position.x, position.y)
	var out_alpha := color.a + existing.a * (1.0 - color.a)
	if out_alpha <= 0.0:
		return
	var out_color := Color(
		(color.r * color.a + existing.r * existing.a * (1.0 - color.a)) / out_alpha,
		(color.g * color.a + existing.g * existing.a * (1.0 - color.a)) / out_alpha,
		(color.b * color.a + existing.b * existing.a * (1.0 - color.a)) / out_alpha,
		out_alpha
	)
	image.set_pixel(position.x, position.y, out_color)

func _save_image(image: Image, path: String) -> void:
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save sprite: %s" % path)
		quit(1)
