extends SceneTree

# Run from repository root with --path godot/void-drifter.
# Preserve real alpha and one shared coordinate scale throughout each sequence.
func _initialize() -> void:
	var repo := ProjectSettings.globalize_path("res://../..")
	if "--scouts" in OS.get_cmdline_user_args():
		_import_ship(repo, "void-drone-v3", "void_drone_v3")
		_import_ship(repo, "red-scout-v3", "red_scout_v3")
		quit()
		return
	var boss_root := repo.path_join("assets/game/enemies/void-dreadnought")
	var boss := Image.load_from_file(boss_root.path_join("sheets/dreadnought-source.png"))
	boss.convert(Image.FORMAT_RGBA8)
	assert(boss.get_pixel(0, 0).a == 0.0, "Boss source must have real alpha")
	var hull := boss.get_region(boss.get_used_rect())
	hull.resize(roundi(hull.get_width() * 340.0 / hull.get_height()), 340, Image.INTERPOLATE_LANCZOS)
	var square := Image.create_empty(384, 384, false, Image.FORMAT_RGBA8)
	square.blit_rect(hull, Rect2i(Vector2i.ZERO, hull.get_size()), (square.get_size() - hull.get_size()) / 2)
	var sheet := Image.create_empty(384 * 4, 512 * 2, false, Image.FORMAT_RGBA8)
	var directions := ["up", "right", "down", "left"]
	for index in range(4):
		var cell := Image.create_empty(384, 512, false, Image.FORMAT_RGBA8)
		cell.blit_rect(square, Rect2i(Vector2i.ZERO, square.get_size()), Vector2i(0, 64))
		for state in ["idle", "thrust"]:
			var filename := "%s-%s.png" % [state, directions[index]]
			_save(cell, boss_root.path_join("frames-cell/" + filename))
			_save(cell, "res://assets/enemies/void_dreadnought/" + filename)
			sheet.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(index * 384, 512 if state == "thrust" else 0))
		if index == 0:
			_save(cell, boss_root.path_join("preview.png"))
			_save(cell, "res://assets/enemies/void_dreadnought/preview.png")
		square.rotate_90(CLOCKWISE)
	_save(sheet, boss_root.path_join("sheets/sheet-a-movement.png"))
	var vfx_root := repo.path_join("assets/game/enemies/shared-vfx/railgun-revision")
	var explosion := Image.load_from_file(vfx_root.path_join("sheets/explosion-source.png"))
	explosion.convert(Image.FORMAT_RGBA8)
	assert(explosion.get_pixel(0, 0).a == 0.0, "Explosion source must have real alpha")
	var cell_size := Vector2i(explosion.get_width() / 4, explosion.get_height() / 2)
	for index in range(8):
		var frame := explosion.get_region(Rect2i(Vector2i(index % 4, index / 4) * cell_size, cell_size))
		# Resize the full cell identically: never fit per-frame alpha bounds.
		frame.resize(320, 320, Image.INTERPOLATE_LANCZOS)
		var canvas := Image.create_empty(384, 512, false, Image.FORMAT_RGBA8)
		canvas.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(32, 96))
		var name := "explosion-%02d.png" % index
		_save(canvas, vfx_root.path_join("frames-cell/" + name))
		_save(canvas, "res://assets/vfx/railgun/" + name)
	_import_ship(repo, "void-tank-v3", "void_tank_v3")
	_import_ship(repo, "rift-shooter-v3", "rift_shooter_v3")
	print("Imported boss directions and eight stable explosion frames with preserved alpha")
	quit()

func _save(image: Image, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	assert(image.save_png(path) == OK, path)

func _import_ship(repo: String, name: String, key: String) -> void:
	var source_root := repo.path_join("assets/game/enemies/" + name)
	var source := Image.load_from_file(source_root.path_join("sheets/ship-source.png"))
	source.convert(Image.FORMAT_RGBA8)
	assert(source.get_pixel(0, 0).a == 0.0, "Ship source requires real alpha")
	var hull := source.get_region(source.get_used_rect())
	hull.resize(roundi(hull.get_width() * 340.0 / hull.get_height()), 340, Image.INTERPOLATE_LANCZOS)
	var square := Image.create_empty(384, 384, false, Image.FORMAT_RGBA8)
	square.blit_rect(hull, Rect2i(Vector2i.ZERO, hull.get_size()), (square.get_size() - hull.get_size()) / 2)
	var sheet := Image.create_empty(1536, 1024, false, Image.FORMAT_RGBA8)
	var directions := ["up", "right", "down", "left"]
	for index in range(4):
		var cell := Image.create_empty(384, 512, false, Image.FORMAT_RGBA8)
		cell.blit_rect(square, Rect2i(Vector2i.ZERO, square.get_size()), Vector2i(0, 64))
		for state in ["idle", "thrust"]:
			var file := "%s-%s.png" % [state, directions[index]]
			_save(cell, source_root.path_join("frames-cell/" + file))
			_save(cell, "res://assets/enemies/" + key + "/" + file)
			sheet.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(index * 384, 512 if state == "thrust" else 0))
		if index == 0:
			_save(cell, source_root.path_join("preview.png"))
			_save(cell, "res://assets/enemies/" + key + "/preview.png")
		square.rotate_90(CLOCKWISE)
	_save(sheet, source_root.path_join("sheets/sheet-a-movement.png"))
