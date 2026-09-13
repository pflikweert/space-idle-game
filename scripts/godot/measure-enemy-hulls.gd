extends SceneTree
const Registry = preload("res://scripts/systems/enemy_registry.gd")
func _initialize() -> void:
	for id in ["void_drone","red_scout","void_tank","ranged_shooter","void_boss"]:
		var spec: Dictionary = Registry.get_definition(id)
		var radius := 0.0
		for state in ["idle", "thrust"]:
			for direction in ["up","down","left","right"]:
				var path := "res://assets/enemies/%s/%s-%s.png" % [spec.asset_key,state,direction]
				var frame := Image.load_from_file(ProjectSettings.globalize_path(path))
				var pivot := Vector2(frame.get_size()) * 0.5
				for y in range(frame.get_height()):
					for x in range(frame.get_width()):
						if frame.get_pixel(x,y).a >= 0.5:
							radius = maxf(radius,Vector2(x,y).distance_to(pivot) * float(spec.visual_canvas_height)*0.48/frame.get_height())
		print(id,": ", snappedf(radius,0.01))
	quit()
