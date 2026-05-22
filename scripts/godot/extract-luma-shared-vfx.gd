extends SceneTree

const OUTPUT_CELL_SIZE := Vector2i(384, 512)
const GRID_COLUMNS := 4
const GRID_ROWS := 2
const FRAME_NAMES := [
	"explosion-transition-01",
	"explosion-transition-02",
	"explosion-transition-03",
	"explosion-transition-04",
	"explosion-ending-01",
	"explosion-ending-02",
	"explosion-ending-03",
	"explosion-ending-04",
]

func _init() -> void:
	var options := _parse_args(OS.get_cmdline_user_args())
	var repo_root := String(options.get("repo-root", "")).trim_suffix("/")
	var source_path := String(options.get("source", ""))
	if repo_root == "" or source_path == "":
		push_error("Usage: godot --headless --path godot/void-drifter --script scripts/godot/extract-luma-shared-vfx.gd -- --repo-root=<repo path> --source=<generated sheet path>")
		quit(1)
		return

	if not source_path.begins_with("/"):
		source_path = "%s/%s" % [repo_root, source_path]

	var source := _load_image(source_path)
	if source == null:
		quit(1)
		return

	var output_dir := "%s/assets/game/enemies/shared-vfx/luma-explosion-set" % repo_root
	DirAccess.make_dir_recursive_absolute("%s/frames-cell" % output_dir)
	DirAccess.make_dir_recursive_absolute("%s/frames-tight" % output_dir)

	var source_cell_size := Vector2i(
		int(floor(float(source.get_width()) / float(GRID_COLUMNS))),
		int(floor(float(source.get_height()) / float(GRID_ROWS)))
	)

	for index in range(FRAME_NAMES.size()):
		var col := index % GRID_COLUMNS
		var row := int(floor(float(index) / float(GRID_COLUMNS)))
		var raw_cell := _crop_image(
			source,
			Rect2i(col * source_cell_size.x, row * source_cell_size.y, source_cell_size.x, source_cell_size.y)
		)
		_remove_dark_background(raw_cell)
		var gameplay_cell := _fit_alpha_on_canvas(raw_cell, OUTPUT_CELL_SIZE, 22)
		var tight := _trim_image(gameplay_cell, 10)
		_save_image(gameplay_cell, "%s/frames-cell/%s.png" % [output_dir, FRAME_NAMES[index]])
		_save_image(tight, "%s/frames-tight/%s.png" % [output_dir, FRAME_NAMES[index]])

	print("Extracted Luma shared explosion VFX candidate from %s" % source_path)
	quit(0)

func _parse_args(args: PackedStringArray) -> Dictionary:
	var options := {}
	for arg in args:
		if not arg.begins_with("--") or not arg.contains("="):
			continue
		var parts := arg.substr(2).split("=", true, 1)
		options[parts[0]] = parts[1]
	return options

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
	cropped.fill(Color(0, 0, 0, 0))
	cropped.blit_rect(source, rect, Vector2i.ZERO)
	return cropped

func _remove_dark_background(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			var brightness := maxf(color.r, maxf(color.g, color.b))
			if brightness < 0.25:
				color.a = 0.0
			elif brightness < 0.42:
				color.a = color.a * ((brightness - 0.25) / 0.17)
			else:
				color.a = minf(1.0, color.a * 1.08)
			image.set_pixel(x, y, color)

func _trim_image(image: Image, padding: int) -> Image:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1

	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.03:
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

func _fit_alpha_on_canvas(image: Image, canvas_size: Vector2i, padding: int) -> Image:
	var tight := _trim_image(image, 2)
	var max_width: int = max(1, canvas_size.x - padding * 2)
	var max_height: int = max(1, canvas_size.y - padding * 2)
	var scale := minf(float(max_width) / float(tight.get_width()), float(max_height) / float(tight.get_height()))
	scale = minf(1.0, scale)

	if scale < 0.999:
		tight.resize(
			maxi(1, int(floor(float(tight.get_width()) * scale))),
			maxi(1, int(floor(float(tight.get_height()) * scale))),
			Image.INTERPOLATE_NEAREST
		)

	var centered := Image.create_empty(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	centered.fill(Color(0, 0, 0, 0))
	var destination := Vector2i(
		int(floor(float(canvas_size.x - tight.get_width()) / 2.0)),
		int(floor(float(canvas_size.y - tight.get_height()) / 2.0))
	)
	centered.blit_rect(tight, Rect2i(Vector2i.ZERO, Vector2i(tight.get_width(), tight.get_height())), destination)
	return centered

func _save_image(image: Image, path: String) -> void:
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save image: %s" % path)
		quit(1)
