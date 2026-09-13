extends SceneTree
const Scene = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/profile_store.gd")
const RADII := {"void_drone":9.35,"red_scout":16.36,"void_tank":19.68,"ranged_shooter":12.91,"void_boss":35.63}
const BANDS := {"void_drone":Vector2(0.75,0.85),"red_scout":Vector2(0.65,1.05),"void_tank":Vector2(0.65,0.75),"ranged_shooter":Vector2(0.85,0.90),"void_boss":Vector2(0.65,0.92)}
class MemoryStore extends Store:
	func load_profile() -> Dictionary: return _default_profile()
	func save_profile(_profile: Dictionary) -> bool: return true
var game
var failed := 0
func _initialize() -> void: call_deferred("measure")
func step(delta: float) -> void:
	game._update_enemy_movement(delta)
	game._resolve_collisions()
	game._update_visual_effects(delta)
func fresh() -> void:
	game.profile.activeRun = {}
	game.start_run()
	game.rng.seed = 37
	game.player.hp = 1e9
	game.player.max_hp = 1e9
func measure() -> void:
	root.size = Vector2i(430,760)
	game = Scene.instantiate()
	game.profile_store = MemoryStore.new()
	root.add_child(game)
	game.set_process(false)
	for id in RADII:
		for corner in [false,true]:
			fresh()
			var bounds: Rect2 = game._get_playfield_rect(game.get_viewport_rect().size)
			if corner: game.player.position = bounds.position + Vector2(22,22)
			game.player_target = game.player.position
			game._spawn_enemy_at({"position":game.player.position + Vector2(190,80)},id)
			var safe := 45.0+float(RADII[id])+6.0
			var band: Vector2 = BANDS[id]
			var good := 0
			var inside := 0
			var samples := 0
			var min_distance := INF
			var maximum_speed := 0.0
			for frame in range(3600):
				step(1.0/30.0)
				if frame<600: continue
				var enemy: Dictionary = game.enemies[0]
				var distance: float = enemy.position.distance_to(game.player.position)
				var minimum := maxf(safe,band.x*120.0)-3.0
				var maximum := maxf(safe,band.y*120.0)+3.0
				if distance>=minimum and distance<=maximum: good+=1
				if distance<safe-1: inside+=1
				samples+=1
				min_distance=minf(min_distance,distance)
				maximum_speed=maxf(maximum_speed,enemy.velocity.length())
			print("NAV ",JSON.stringify({"type":id,"corner":corner,"band_fraction":float(good)/samples,"unsafe_fraction":float(inside)/samples,"min_distance":min_distance,"max_speed":maximum_speed}))
			if float(good)/samples<0.9 or inside>0: failed+=1
	fresh()
	for index in range(44):
		var id: String = "void_boss" if index>=40 else ["void_drone","red_scout","void_tank","ranged_shooter"][index%4]
		game._spawn_enemy_at({"position":game.player.position+Vector2.RIGHT.rotated(index*2.39996)*(100+index%5*25)},id)
	var overlaps := 0
	var unsafe := 0
	var stalled := 0
	var samples := 0
	for frame in range(1800):
		step(1.0/30.0)
		if frame<300 or frame%10!=0:continue
		samples+=1
		for i in range(game.enemies.size()):
			var a: Dictionary=game.enemies[i]
			if a.position.distance_to(game.player.position)<51+float(RADII[a.type_id])-1:unsafe+=1
			if a.velocity.length()<0.5:stalled+=1
			for j in range(i+1,game.enemies.size()):
				var b: Dictionary=game.enemies[j]
				if a.position.distance_to(b.position)<float(RADII[a.type_id])+float(RADII[b.type_id]): overlaps+=1
	print("CROWD ",JSON.stringify({"overlapping_pairs_per_sample":float(overlaps)/samples,"unsafe_enemies_per_sample":float(unsafe)/samples,"stalled_per_sample":float(stalled)/samples}))
	# A crowded ship must resume its route once neighboring traffic clears.
	var fleet: Array=game.enemies.duplicate(true)
	var resumed := 0
	for captured in fleet:
		game.enemies.clear()
		game.enemies.append(captured.duplicate(true))
		var origin: Vector2=game.enemies[0].position
		var furthest := 0.0
		for frame in range(300):
			step(1.0/30.0)
			furthest=maxf(furthest,game.enemies[0].position.distance_to(origin))
		if furthest>5.0: resumed+=1
		else: print("HOLD ",JSON.stringify({"type":captured.type_id,"distance":game.enemies[0].position.distance_to(game.player.position),"moved":furthest,"speed":game.enemies[0].velocity.length()}))
	print("CLEARANCE ",JSON.stringify({"resumed":resumed,"ships":fleet.size()}))
	if resumed!=fleet.size() or unsafe>0: failed+=1
	game.queue_free()
	await process_frame
	quit(1 if failed>0 else 0)
