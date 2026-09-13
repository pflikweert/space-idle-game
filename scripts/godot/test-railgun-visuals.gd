extends SceneTree
const Prior = preload("res://../../scripts/godot/visual-gunship-qa.gd")
const Visuals = preload("res://scripts/systems/railgun_visuals.gd")
const Weapons = preload("res://scripts/systems/weapon_registry.gd")
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		printerr("FAIL: ",message)
		quit(1)
func _initialize() -> void: call_deferred("run_tests")
func run_tests() -> void:
	var game := Prior.Fixture.new()
	game.profile_store = Prior.MemoryStore.new()
	root.add_child(game)
	game.set_process(false)
	game.start_run()
	game.enemies.clear()
	var origin: Vector2 = game.player.position
	for speed in [1,2,3,4,5,10]:
		game.bullets.clear()
		game.particles.clear()
		for fragment in [false,true]:
			var bullet := Weapons.build_projectile(800+int(fragment),origin,Vector2.UP,10,false,1000)
			bullet.is_fragment = fragment
			game.bullets.append(bullet)
		for step in range(speed):
			for bullet in game.bullets:
				bullet.previous_position = bullet.position
				bullet.position += Vector2.UP*2
			game._resolve_collisions()
		var traces: Array = game.particles.filter(func(effect): return effect.kind=="rail_trace")
		check(traces.size()==2,"One trace per projectile across simulation substeps")
		for trace in traces:
			check(trace.position.distance_to(trace.end)<= (8.0 if trace.is_fragment else 20.0),"Bounded pulse length")
	check(Visuals.trace_start(Vector2.ZERO,Vector2(500,0),false)==Vector2(480,0),"Large step produces short railgun pulse")
	check(Visuals.trace_start(Vector2.ZERO,Vector2(500,0),true)==Vector2(492,0),"Fragment is less than half the pulse length")
	check(Visuals.trace_start(Vector2.ZERO,Vector2(2,0),false)==Vector2.ZERO,"Short movement cannot extend before muzzle")
	check(Visuals.is_fragment({"radius":1.6}),"Old saved fragments retain distinct presentation")
	var visuals := Visuals.new()
	for kind in ["pulse","fragment","impact","fragment_impact","muzzle"]:
		for frame in range(4):
			var texture := visuals.texture(kind,frame/4.0)
			check(texture!=null and texture.get_size()==Vector2(64,32),"Stable frame canvas")
	game.queue_free()
	await process_frame
	print("Railgun visual checks: ",checks," passed")
	quit()
