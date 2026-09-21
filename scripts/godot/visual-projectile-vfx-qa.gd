extends SceneTree

const PriorQA := preload("res://../../scripts/godot/visual-gunship-qa.gd")
const Weapons := preload("res://scripts/systems/weapon_registry.gd")
const Equipment := preload("res://scripts/systems/equipment_registry.gd")
const OUTPUT := "/tmp/void-projectile-vfx-qa"

var game

func _initialize() -> void:
	call_deferred("capture")

func _rail(projectile_id: int, start: Vector2, end: Vector2, _second_instance := false, fragment := false) -> Dictionary:
	var direction := (end-start).normalized()
	var bullet := Weapons.build_projectile(projectile_id,start,direction,10.0,false,900.0)
	bullet.position = end
	bullet.previous_position = end-direction*18.0
	bullet.velocity = direction*1600.0
	bullet.visual_kind = "railgun"
	bullet.visual_trail_points = [start,start.lerp(end,0.35),start.lerp(end,0.68),end]
	bullet.sourceBlueprintId = Equipment.RAILGUN_ID
	bullet.is_fragment = fragment
	if fragment: bullet.radius = 1.6
	return bullet

func _missile(projectile_id: int, points: Array, super_missile := false) -> Dictionary:
	var start := Vector2(points[0])
	var end := Vector2(points.back())
	var direction := (end-Vector2(points[points.size()-2])).normalized()
	var bullet := Weapons.build_projectile(projectile_id,start,direction,18.0,false,600.0)
	bullet.position = end
	bullet.previous_position = Vector2(points[points.size()-2])
	bullet.velocity = direction*210.0
	bullet.visual_kind = "micro_missile"
	bullet.trail_points = points
	bullet.launched = true
	bullet.is_super_missile = super_missile
	return bullet

func _save_view(name: String) -> void:
	game._update_buttons()
	game.queue_redraw()
	for frame in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT.path_join(name+".png"))
	print("CAPTURE ",name)

func _prepare_scene() -> Dictionary:
	game.profile.activeRun = {}
	game.start_run()
	game.set_process(false)
	game.enemies.clear()
	game.particles.clear()
	game.muzzle_flashes.clear()
	var bounds: Rect2 = game._get_playfield_rect(game.get_viewport_rect().size)
	var center := bounds.get_center()
	game.player.position = center+Vector2(0,bounds.size.y*0.14)
	game.player_target = game.player.position
	game._spawn_enemy_at({"position":center+Vector2(0,-bounds.size.y*0.23)},"armored_drone")
	game.enemies[-1].hp = 1e9
	return {"bounds":bounds,"center":center,"player":game.player.position,"target":game.enemies[-1].position}

func _set_case(case_id: String, scene: Dictionary, density := 1) -> void:
	game.bullets.clear()
	game.particles.clear()
	game.muzzle_flashes.clear()
	var player_pos: Vector2 = scene.player
	var target: Vector2 = scene.target
	match case_id:
		"railgun":
			game.bullets.append(_rail(101,player_pos,target))
		game._add_muzzle_flash(player_pos,(target-player_pos).normalized(),false,Equipment.RAILGUN_ID)
		"railgun_multi":
			for index in range(3):
				var side := Vector2(index-1,0)*8.0
				game.bullets.append(_rail(110+index,player_pos+side,target+side*0.45,index==2))
		"missiles":
			for index in range(3):
				var lane := float(index-1)
				var side := Vector2.RIGHT*lane*11.0
				var bend := Vector2.RIGHT*lane*34.0
				var points := [player_pos+side,player_pos+Vector2(0,-35)+side*1.3,player_pos+Vector2(0,-82)+bend,target+side*0.25]
				game.bullets.append(_missile(120+index,points,index==2))
			game._add_missile_muzzle_flash(player_pos,Vector2.UP,false)
		"multi_active":
			game.bullets.append(_rail(130,player_pos+Vector2(-8,0),target+Vector2(-28,0)))
			game.bullets.append(_rail(131,player_pos+Vector2(8,0),target+Vector2(28,0),true))
			game.bullets.append(_missile(132,[player_pos,player_pos+Vector2(-24,-42),player_pos+Vector2(-38,-90),target],false))
			game.bullets.append(_missile(133,[player_pos+Vector2(10,0),player_pos+Vector2(34,-40),player_pos+Vector2(45,-88),target+Vector2(10,0)],true))
		"combat":
			for index in range(5*density):
				var lane := float((index%5)-2)
				var spread_target := target+Vector2(lane*16.0,float(index%3)*7.0)
				if index%3==2:
					game.bullets.append(_missile(200+index,[player_pos+Vector2(lane*3.0,0),player_pos+Vector2(lane*13.0,-38),player_pos+Vector2(-lane*10.0,-82),spread_target],index%6==5))
				else:
					game.bullets.append(_rail(200+index,player_pos+Vector2(lane*2.5,0),spread_target,index%3==1))

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.content_scale_size = Vector2i(430,760)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	game = PriorQA.Fixture.new()
	game.profile_store = PriorQA.MemoryStore.new()
	root.add_child(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.set_process(false)
	for dimensions in [Vector2i(320,568),Vector2i(390,844),Vector2i(430,932),Vector2i(1280,800)]:
		root.size = dimensions
		for frame in range(4): await process_frame
		var scene := _prepare_scene()
		for case_id in ["railgun","railgun_multi","missiles","multi_active"]:
			_set_case(case_id,scene)
			await _save_view("%s-%dx%d" % [case_id,dimensions.x,dimensions.y])
		for speed in [1,10]:
			_set_case("combat",scene,1 if speed==1 else 2)
			await _save_view("combat-%dx%d-%dx" % [dimensions.x,dimensions.y,speed])
	root.size = Vector2i(390,844)
	var scene := _prepare_scene()
	for density in [1,2]:
		_set_case("combat",scene,density)
		var started := Time.get_ticks_usec()
		for frame in range(240):
			game.queue_redraw()
			await process_frame
		var elapsed_ms := float(Time.get_ticks_usec()-started)/1000.0
		print("VFX PERF density=",density," frames=240 average_ms=",elapsed_ms/240.0," projectiles=",game.bullets.size())
	game.queue_free()
	await process_frame
	quit()
