extends SceneTree

const CELL_SIZE := Vector2i(384, 512)
const PREVIEW_SIZE := Vector2i(512, 512)
const SHEET_SIZE := Vector2i(1536, 1024)
const DIRECTIONS := ["down", "up", "left", "right"]
const MOVEMENT_STATES := ["idle", "thrust"]
const COMBAT_STATES := ["attack", "hit"]
const ALL_STATES := ["idle", "thrust", "attack", "hit"]

const ENEMIES := {
	"ranged-shooter": {
		"godot_dir": "ranged_shooter",
		"shape": "shooter",
		"primary": Color("#a855f7"),
		"accent": Color("#ff3bff"),
		"core": Color("#00e5ff"),
		"scale": 1.0,
	},
	"void-swarm": {
		"godot_dir": "void_swarm",
		"shape": "swarm",
		"primary": Color("#22d3ee"),
		"accent": Color("#f8fafc"),
		"core": Color("#67e8f9"),
		"scale": 0.66,
	},
	"kamikaze": {
		"godot_dir": "kamikaze",
		"shape": "dart",
		"primary": Color("#facc15"),
		"accent": Color("#ff5a1f"),
		"core": Color("#fff7ad"),
		"scale": 0.86,
	},
	"splitter": {
		"godot_dir": "splitter",
		"shape": "splitter",
		"primary": Color("#34d399"),
		"accent": Color("#a7f3d0"),
		"core": Color("#f0fdf4"),
		"scale": 0.95,
	},
	"elite-hunter": {
		"godot_dir": "elite_hunter",
		"shape": "hunter",
		"primary": Color("#ff00ff"),
		"accent": Color("#00e5ff"),
		"core": Color("#ffe4ff"),
		"scale": 1.25,
	},
}

func _init() -> void:
	var options := _parse_args(OS.get_cmdline_user_args())
	var repo_root := String(options.get("repo-root", ""))
	if repo_root == "":
		push_error("Usage: godot --headless --path godot/void-drifter --script scripts/godot/generate-void-drifter-placeholder-enemies.gd -- --repo-root=<repo path>")
		quit(1)
		return

	repo_root = repo_root.trim_suffix("/")
	for enemy_id in ENEMIES.keys():
		_generate_enemy(repo_root, enemy_id, ENEMIES[enemy_id])

	print("Generated VOID DRIFTER placeholder enemy sprites for %d enemies." % ENEMIES.size())
	quit(0)

func _parse_args(args: PackedStringArray) -> Dictionary:
	var options := {}
	for arg in args:
		if not arg.begins_with("--") or not arg.contains("="):
			continue
		var parts := arg.substr(2).split("=", true, 1)
		options[parts[0]] = parts[1]
	return options

func _generate_enemy(repo_root: String, enemy_id: String, config: Dictionary) -> void:
	var output_dir := "%s/assets/game/enemies/%s" % [repo_root, enemy_id]
	var godot_dir := "%s/godot/void-drifter/assets/enemies/%s" % [repo_root, config.godot_dir]
	DirAccess.make_dir_recursive_absolute("%s/frames-cell" % output_dir)
	DirAccess.make_dir_recursive_absolute("%s/frames-tight" % output_dir)
	DirAccess.make_dir_recursive_absolute("%s/sheets" % output_dir)
	DirAccess.make_dir_recursive_absolute("%s/references/luma" % output_dir)
	DirAccess.make_dir_recursive_absolute("%s/generation" % output_dir)
	DirAccess.make_dir_recursive_absolute(godot_dir)

	var movement_sheet := Image.create_empty(SHEET_SIZE.x, SHEET_SIZE.y, false, Image.FORMAT_RGBA8)
	movement_sheet.fill(Color(0, 0, 0, 0))
	var combat_sheet := Image.create_empty(SHEET_SIZE.x, SHEET_SIZE.y, false, Image.FORMAT_RGBA8)
	combat_sheet.fill(Color(0, 0, 0, 0))

	for state_index in range(MOVEMENT_STATES.size()):
		var state: String = MOVEMENT_STATES[state_index]
		for direction_index in range(DIRECTIONS.size()):
			var direction: String = DIRECTIONS[direction_index]
			var frame := _generate_frame(config, state, direction)
			_save_frame(output_dir, godot_dir, state, direction, frame)
			movement_sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, CELL_SIZE), Vector2i(direction_index * CELL_SIZE.x, state_index * CELL_SIZE.y))

	for state_index in range(COMBAT_STATES.size()):
		var state: String = COMBAT_STATES[state_index]
		for direction_index in range(DIRECTIONS.size()):
			var direction: String = DIRECTIONS[direction_index]
			var frame := _generate_frame(config, state, direction)
			_save_frame(output_dir, godot_dir, state, direction, frame)
			combat_sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, CELL_SIZE), Vector2i(direction_index * CELL_SIZE.x, state_index * CELL_SIZE.y))

	_save_image(movement_sheet, "%s/sheets/sheet-a-movement.png" % output_dir)
	_save_image(combat_sheet, "%s/sheets/sheet-b-combat.png" % output_dir)
	_generate_preview(output_dir, enemy_id)

func _save_frame(output_dir: String, godot_dir: String, state: String, direction: String, frame: Image) -> void:
	var frame_name := "%s-%s.png" % [state, direction]
	var tight := _trim_image(frame, 8)
	_save_image(frame, "%s/frames-cell/%s" % [output_dir, frame_name])
	_save_image(tight, "%s/frames-tight/%s" % [output_dir, frame_name])
	_save_image(frame, "%s/%s" % [godot_dir, frame_name])

func _generate_frame(config: Dictionary, state: String, direction: String) -> Image:
	var image := Image.create_empty(CELL_SIZE.x, CELL_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var forward := _direction_vector(direction)
	var side := Vector2(-forward.y, forward.x)
	var center := Vector2(CELL_SIZE.x * 0.5, CELL_SIZE.y * 0.5)
	var scale := 72.0 * float(config.scale)
	var primary: Color = config.primary
	var accent: Color = config.accent
	var core: Color = config.core
	var state_scale := 1.0
	if state == "thrust":
		state_scale = 1.04
	elif state == "attack":
		state_scale = 1.08
	elif state == "hit":
		state_scale = 1.0
	scale *= state_scale

	var glow_color := primary
	glow_color.a = 0.10 if state != "attack" else 0.16
	_draw_soft_circle(image, center, scale * 1.36, glow_color, 5)

	match String(config.shape):
		"swarm":
			_draw_swarm(image, center, forward, side, scale, primary, accent, core, state)
		"dart":
			_draw_dart(image, center, forward, side, scale, primary, accent, core, state)
		"splitter":
			_draw_splitter(image, center, forward, side, scale, primary, accent, core, state)
		"hunter":
			_draw_hunter(image, center, forward, side, scale, primary, accent, core, state)
		_:
			_draw_shooter(image, center, forward, side, scale, primary, accent, core, state)

	if state == "hit":
		_draw_soft_circle(image, center, scale * 0.92, Color(1, 1, 1, 0.22), 3)
		_draw_line(image, center - side * scale * 0.64 - forward * scale * 0.05, center + side * scale * 0.62 + forward * scale * 0.12, Color(1, 1, 1, 0.38), 3)

	return image

func _draw_shooter(image: Image, center: Vector2, forward: Vector2, side: Vector2, scale: float, primary: Color, accent: Color, core: Color, state: String) -> void:
	var body := [
		center + forward * scale * 1.05,
		center + side * scale * 0.52 + forward * scale * 0.18,
		center + side * scale * 0.38 - forward * scale * 0.72,
		center - forward * scale * 0.95,
		center - side * scale * 0.38 - forward * scale * 0.72,
		center - side * scale * 0.52 + forward * scale * 0.18,
	]
	_draw_polygon(image, body, Color(primary.r * 0.38, primary.g * 0.38, primary.b * 0.46, 0.96))
	_draw_polygon_outline(image, body, primary, 3)
	_draw_line(image, center - side * scale * 0.60, center + side * scale * 0.60, Color(accent.r, accent.g, accent.b, 0.72), 3)
	_draw_soft_circle(image, center + forward * scale * 0.10, scale * 0.19, core, 2)
	_draw_thrusters(image, center, forward, side, scale, accent, state)
	if state == "attack":
		_draw_soft_circle(image, center + forward * scale * 1.28, scale * 0.22, accent, 3)

func _draw_swarm(image: Image, center: Vector2, forward: Vector2, side: Vector2, scale: float, primary: Color, accent: Color, core: Color, state: String) -> void:
	for offset in [Vector2.ZERO, -side * scale * 0.34 - forward * scale * 0.18, side * scale * 0.34 - forward * scale * 0.18]:
		var local_center: Vector2 = center + offset
		var body := [
			local_center + forward * scale * 0.68,
			local_center + side * scale * 0.34,
			local_center - forward * scale * 0.52,
			local_center - side * scale * 0.34,
		]
		_draw_polygon(image, body, Color(primary.r * 0.34, primary.g * 0.42, primary.b * 0.46, 0.92))
		_draw_polygon_outline(image, body, primary, 2)
		_draw_soft_circle(image, local_center, scale * 0.12, core, 2)
	_draw_thrusters(image, center, forward, side, scale * 0.84, accent, state)

func _draw_dart(image: Image, center: Vector2, forward: Vector2, side: Vector2, scale: float, primary: Color, accent: Color, core: Color, state: String) -> void:
	var body := [
		center + forward * scale * 1.42,
		center + side * scale * 0.32 + forward * scale * 0.02,
		center + side * scale * 0.16 - forward * scale * 0.88,
		center - forward * scale * 1.08,
		center - side * scale * 0.16 - forward * scale * 0.88,
		center - side * scale * 0.32 + forward * scale * 0.02,
	]
	_draw_polygon(image, body, Color(primary.r * 0.54, primary.g * 0.40, primary.b * 0.10, 0.98))
	_draw_polygon_outline(image, body, primary, 3)
	_draw_line(image, center - forward * scale * 0.76, center + forward * scale * 0.94, Color(core.r, core.g, core.b, 0.80), 2)
	_draw_soft_circle(image, center - forward * scale * 0.02, scale * 0.16, core, 2)
	_draw_thrusters(image, center, forward, side, scale * 1.05, accent, state)
	if state == "attack" or state == "thrust":
		_draw_soft_circle(image, center - forward * scale * 1.18, scale * 0.32, accent, 3)

func _draw_splitter(image: Image, center: Vector2, forward: Vector2, side: Vector2, scale: float, primary: Color, accent: Color, core: Color, state: String) -> void:
	var left := center - side * scale * 0.30
	var right := center + side * scale * 0.30
	for local_center in [left, right]:
		var shard := [
			local_center + forward * scale * 0.78,
			local_center + side * scale * 0.30,
			local_center - forward * scale * 0.72,
			local_center - side * scale * 0.30,
		]
		_draw_polygon(image, shard, Color(primary.r * 0.30, primary.g * 0.50, primary.b * 0.34, 0.95))
		_draw_polygon_outline(image, shard, primary, 3)
	_draw_line(image, center - forward * scale * 0.82, center + forward * scale * 0.82, Color(accent.r, accent.g, accent.b, 0.72), 2)
	_draw_line(image, center - side * scale * 0.52, center + side * scale * 0.52, Color(accent.r, accent.g, accent.b, 0.45), 2)
	_draw_soft_circle(image, center, scale * 0.18, core, 2)
	_draw_thrusters(image, center, forward, side, scale, accent, state)

func _draw_hunter(image: Image, center: Vector2, forward: Vector2, side: Vector2, scale: float, primary: Color, accent: Color, core: Color, state: String) -> void:
	var body := [
		center + forward * scale * 1.08,
		center + side * scale * 0.78 + forward * scale * 0.12,
		center + side * scale * 0.52 - forward * scale * 0.42,
		center + side * scale * 0.20 - forward * scale * 1.02,
		center - forward * scale * 0.72,
		center - side * scale * 0.20 - forward * scale * 1.02,
		center - side * scale * 0.52 - forward * scale * 0.42,
		center - side * scale * 0.78 + forward * scale * 0.12,
	]
	_draw_polygon(image, body, Color(primary.r * 0.30, primary.g * 0.16, primary.b * 0.40, 0.98))
	_draw_polygon_outline(image, body, primary, 4)
	_draw_line(image, center - side * scale * 0.78 + forward * scale * 0.04, center + side * scale * 0.78 + forward * scale * 0.04, Color(accent.r, accent.g, accent.b, 0.70), 3)
	_draw_soft_circle(image, center + forward * scale * 0.08, scale * 0.20, core, 3)
	_draw_thrusters(image, center, forward, side, scale * 1.08, accent, state)
	if state == "attack":
		_draw_soft_circle(image, center + forward * scale * 1.20, scale * 0.24, accent, 4)

func _draw_thrusters(image: Image, center: Vector2, forward: Vector2, side: Vector2, scale: float, accent: Color, state: String) -> void:
	var intensity := 1.0
	if state == "thrust":
		intensity = 1.45
	elif state == "attack":
		intensity = 1.20
	var tail := center - forward * scale * 0.92
	for offset in [-0.20, 0.20]:
		var flame_center: Vector2 = tail + side * scale * offset
		var flame := [
			flame_center - forward * scale * 0.42 * intensity,
			flame_center + side * scale * 0.12,
			flame_center + forward * scale * 0.10,
			flame_center - side * scale * 0.12,
		]
		_draw_polygon(image, flame, Color(accent.r, accent.g, accent.b, 0.55))
		_draw_soft_circle(image, flame_center - forward * scale * 0.18 * intensity, scale * 0.12 * intensity, Color(accent.r, accent.g, accent.b, 0.24), 2)

func _direction_vector(direction: String) -> Vector2:
	match direction:
		"up":
			return Vector2(0, -1)
		"left":
			return Vector2(-1, 0)
		"right":
			return Vector2(1, 0)
	return Vector2(0, 1)

func _draw_polygon(image: Image, points: Array, color: Color) -> void:
	var bounds := _get_bounds(points, image.get_width(), image.get_height())
	for y in range(bounds.position.y, bounds.position.y + bounds.size.y):
		for x in range(bounds.position.x, bounds.position.x + bounds.size.x):
			if _point_in_polygon(Vector2(float(x) + 0.5, float(y) + 0.5), points):
				_blend_pixel(image, Vector2i(x, y), color)

func _draw_polygon_outline(image: Image, points: Array, color: Color, width: int) -> void:
	for index in range(points.size()):
		_draw_line(image, points[index], points[(index + 1) % points.size()], color, width)

func _draw_line(image: Image, start: Vector2, end: Vector2, color: Color, width: int) -> void:
	var delta := end - start
	var steps := maxi(1, int(ceil(delta.length())))
	for step in range(steps + 1):
		var position := start.lerp(end, float(step) / float(steps))
		_draw_circle(image, position, float(width), color)

func _draw_soft_circle(image: Image, center: Vector2, radius: float, color: Color, rings: int) -> void:
	for ring in range(rings, 0, -1):
		var ring_color := color
		ring_color.a = color.a * float(rings - ring + 1) / float(rings)
		_draw_circle(image, center, radius * float(ring) / float(rings), ring_color)

func _draw_circle(image: Image, center: Vector2, radius: float, color: Color) -> void:
	var min_x := maxi(0, int(floor(center.x - radius)))
	var max_x := mini(image.get_width() - 1, int(ceil(center.x + radius)))
	var min_y := maxi(0, int(floor(center.y - radius)))
	var max_y := mini(image.get_height() - 1, int(ceil(center.y + radius)))
	var radius_squared := radius * radius
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var distance_squared := Vector2(float(x) + 0.5, float(y) + 0.5).distance_squared_to(center)
			if distance_squared <= radius_squared:
				_blend_pixel(image, Vector2i(x, y), color)

func _get_bounds(points: Array, width: int, height: int) -> Rect2i:
	var min_x := width - 1
	var min_y := height - 1
	var max_x := 0
	var max_y := 0
	for point in points:
		min_x = mini(min_x, int(floor(point.x)))
		min_y = mini(min_y, int(floor(point.y)))
		max_x = maxi(max_x, int(ceil(point.x)))
		max_y = maxi(max_y, int(ceil(point.y)))
	min_x = clampi(min_x - 2, 0, width - 1)
	min_y = clampi(min_y - 2, 0, height - 1)
	max_x = clampi(max_x + 2, 0, width - 1)
	max_y = clampi(max_y + 2, 0, height - 1)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func _point_in_polygon(point: Vector2, polygon: Array) -> bool:
	var inside := false
	var j := polygon.size() - 1
	for i in range(polygon.size()):
		var pi: Vector2 = polygon[i]
		var pj: Vector2 = polygon[j]
		if ((pi.y > point.y) != (pj.y > point.y)) and (point.x < (pj.x - pi.x) * (point.y - pi.y) / maxf(0.001, pj.y - pi.y) + pi.x):
			inside = not inside
		j = i
	return inside

func _blend_pixel(image: Image, position: Vector2i, color: Color) -> void:
	if position.x < 0 or position.y < 0 or position.x >= image.get_width() or position.y >= image.get_height():
		return
	var existing := image.get_pixelv(position)
	var alpha := clampf(color.a, 0.0, 1.0)
	var inverse := 1.0 - alpha
	var out_alpha := alpha + existing.a * inverse
	if out_alpha <= 0.0:
		image.set_pixelv(position, Color(0, 0, 0, 0))
		return
	var out_color := Color(
		(color.r * alpha + existing.r * existing.a * inverse) / out_alpha,
		(color.g * alpha + existing.g * existing.a * inverse) / out_alpha,
		(color.b * alpha + existing.b * existing.a * inverse) / out_alpha,
		out_alpha
	)
	image.set_pixelv(position, out_color)

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
	var cropped := Image.create_empty(max_x - min_x + 1, max_y - min_y + 1, false, Image.FORMAT_RGBA8)
	cropped.blit_rect(image, Rect2i(min_x, min_y, cropped.get_width(), cropped.get_height()), Vector2i.ZERO)
	return cropped

func _generate_preview(output_dir: String, enemy_id: String) -> void:
	var source := Image.new()
	var source_path := "%s/frames-cell/thrust-right.png" % output_dir
	if source.load(source_path) != OK:
		push_error("Could not load preview source: %s" % source_path)
		return
	source.convert(Image.FORMAT_RGBA8)
	var preview := Image.create_empty(PREVIEW_SIZE.x, PREVIEW_SIZE.y, false, Image.FORMAT_RGBA8)
	preview.fill(Color(0, 0, 0, 0))
	var scaled := source.duplicate()
	scaled.resize(PREVIEW_SIZE.x, PREVIEW_SIZE.y, Image.INTERPOLATE_LANCZOS)
	preview.blit_rect(scaled, Rect2i(Vector2i.ZERO, PREVIEW_SIZE), Vector2i.ZERO)
	_save_image(preview, "%s/preview.png" % output_dir)
	print("Generated preview for %s" % enemy_id)

func _save_image(image: Image, path: String) -> void:
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save image: %s" % path)
