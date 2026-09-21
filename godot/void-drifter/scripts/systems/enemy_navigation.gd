extends RefCounted

# Circumscribed opaque hull radius across all eight fixed idle/thrust canvases.
# Measured at alpha >= 0.5, at the existing 0.48 display scale. Not hitboxes.
const TYPES := {
	"armored_drone": {"radius":17.0,"band":Vector2(0.56,0.72),"top":38.0,"turn":80.0,"orbit":0.62,"approach":35.0,"delay":1.0},
	"void_drone": {"radius":9.35,"band":Vector2(0.38,0.48),"top":70.0,"turn":100.0,"orbit":0.76,"approach":25.0,"delay":0.75},
	"red_scout": {"radius":16.36,"band":Vector2(0.84,0.92),"top":59.5,"turn":150.0,"orbit":0.46,"approach":115.0,"delay":3.0},
	"void_tank": {"radius":19.68,"band":Vector2(0.70,0.80),"top":17.5,"turn":55.0,"orbit":0.56,"approach":230.0,"delay":8.0},
	"ranged_shooter": {"radius":12.91,"band":Vector2(0.86,0.92),"top":28.0,"turn":90.0,"orbit":0.90,"approach":180.0,"delay":5.0},
	"void_boss": {"radius":35.63,"band":Vector2(0.90,0.96),"top":10.0,"turn":30.0,"orbit":1.0,"approach":290.0,"delay":12.0},
}
const LOOKAHEAD := 0.75
const GAP := 6.0
const PLAYER_COLLISION_RADIUS := 8.64

static func initialize(enemy: Dictionary, random: RandomNumberGenerator = null, fleet_orbit_sign: float = 0.0) -> void:
	var id := str(enemy.type_id)
	if not TYPES.has(id): return
	var spec: Dictionary = TYPES[id]
	# Legacy initialization consumes no gameplay RNG, retaining old encounters exactly.
	var fraction := float(posmod(int(enemy.id) * 16807, 997)) / 997.0
	if not enemy.has("nav_preference"):
		enemy.nav_preference = random.randf() if random != null else fraction
		enemy.cruise_factor = random.randf_range(0.88,1.0) if random != null else 0.88+0.12*fraction
		enemy.variation_phase = random.randf()*TAU if random != null else fraction*TAU
		enemy.nav_time = 0.0
		enemy.approach_time = 0.0
		enemy.approach_progress = 0.0
		enemy.jam_time = 0.0
		enemy.avoid_side = -1.0 if int(enemy.id)%2==0 else 1.0
		enemy.avoid_timer = 0.0
		enemy.orbit_edge_timer = 0.0
		enemy.scout_phase = "approach"
		enemy.scout_goal = Vector2.ZERO
		enemy.scout_line = Vector2.ZERO
		enemy.boss_orbit_time = 0.0
		enemy.boss_in_orbit = false
		enemy.nav_entered = false
		enemy.nav_target_distance = 0.0
	if not enemy.has("approach_time"): enemy.approach_time = float(enemy.get("boss_orbit_time", 0.0))
	if not enemy.has("approach_progress"): enemy.approach_progress = 0.0
	if not enemy.has("escape_timer"): enemy.escape_timer = 0.0
	if not enemy.has("contact_latched"): enemy.contact_latched = false
	if not enemy.has("contact_hits_in_pass"): enemy.contact_hits_in_pass = 1 if bool(enemy.contact_latched) else 0
	if not enemy.has("flight_layer"): enemy.flight_layer = posmod(int(enemy.id) * 7, 3) - 1
	if fleet_orbit_sign != 0.0:
		enemy.orbit_sign = -1.0 if fleet_orbit_sign < 0.0 else 1.0
	elif not enemy.has("orbit_sign"):
		enemy.orbit_sign = -1.0 if int(enemy.id) % 2 == 0 else 1.0
	if not enemy.has("flight_heading"):
		enemy.flight_heading = float(enemy.get("visual_rotation",0.0))-PI/2.0
	enemy.navigation_radius = float(spec.radius)

static func safe_distance(enemy: Dictionary) -> float:
	return PLAYER_COLLISION_RADIUS + float(enemy.radius)

static func restart_after_contact(enemy: Dictionary, player_range: float) -> void:
	enemy.approach_time = 0.0
	enemy.approach_progress = 0.0
	enemy.nav_target_distance = preferred_distance(enemy, player_range)
	enemy.escape_timer = 0.0
	enemy.contact_latched = true

static func preferred_distance(enemy: Dictionary, player_range: float) -> float:
	var spec: Dictionary = TYPES[str(enemy.type_id)]
	var outer := player_range*lerpf(spec.band.x,spec.band.y,float(enemy.nav_preference))
	var progress := clampf((float(enemy.approach_time)-float(spec.delay))/float(spec.approach),0.0,1.0)
	progress = smoothstep(0.0,1.0,progress)
	enemy.approach_progress = progress
	# Aim slightly through the collision boundary so a completed spiral produces
	# a real impact instead of hovering one fraction outside the hull.
	return lerpf(outer,maxf(1.0,safe_distance(enemy)-1.5),progress)

static func feasible_point(point: Vector2, player: Vector2, radius: float, bounds: Rect2) -> Vector2:
	if bounds.has_point(point): return point
	# Project a desired orbit point to the nearest available arc; no world pathfinding.
	var chosen := bounds.get_center()
	var best := INF
	for index in range(48):
		var candidate := player+Vector2.from_angle(TAU*index/48.0)*radius
		if not bounds.has_point(candidate):continue
		var score := point.distance_squared_to(candidate)
		if score<best:
			best=score
			chosen=candidate
	return chosen if best<INF else Vector2(clampf(point.x,bounds.position.x,bounds.end.x),clampf(point.y,bounds.position.y,bounds.end.y))

static func preferred_velocity(enemy: Dictionary, player: Vector2, player_range: float, bounds: Rect2, delta: float) -> Vector2:
	var spec: Dictionary = TYPES[str(enemy.type_id)]
	var position: Vector2 = enemy.position
	var offset := position-player
	var distance := offset.length()
	var outward := offset.normalized() if distance>0.01 else Vector2.RIGHT.rotated(float(enemy.id))
	var legal := bounds.grow(-float(spec.radius)-3.0)
	var top := minf(float(enemy.speed),float(spec.top))
	var cruise := top*clampf(float(enemy.cruise_factor)+0.04*sin(float(enemy.nav_time)*0.65+float(enemy.variation_phase)),0.0,1.0)
	var target := preferred_distance(enemy,player_range)
	if float(enemy.nav_target_distance)<=0.0: enemy.nav_target_distance=target
	var tracking_speed := maxf(4.0,player_range/float(spec.approach))
	enemy.nav_target_distance=move_toward(float(enemy.nav_target_distance),target,tracking_speed*delta)
	target=maxf(1.0,float(enemy.nav_target_distance))
	if legal.has_point(position): enemy.nav_entered=true
	if not bool(enemy.nav_entered):
		var entry := feasible_point(player+outward*target,player,target,legal)
		return (entry-position).limit_length(cruise)
	var tangent := outward.orthogonal()*float(enemy.orbit_sign)
	var inward_speed := clampf((distance-target)*1.7,-cruise*0.45,cruise*0.72)
	var orbit_fade := lerpf(1.0,0.28,float(enemy.approach_progress))
	var route := tangent*cruise*float(spec.orbit)*orbit_fade-outward*inward_speed
	var projected := position+route*0.6
	if not legal.has_point(projected):
		# Slide along the available arc without reversing the fleet's handedness.
		var clamped := Vector2(clampf(projected.x,legal.position.x,legal.end.x),clampf(projected.y,legal.position.y,legal.end.y))
		route+=(clamped-projected)*2.5
		var tangent_speed := route.dot(tangent)
		var minimum_tangent := cruise*0.12
		if tangent_speed<minimum_tangent: route+=tangent*(minimum_tangent-tangent_speed)
	return route.limit_length(cruise)

static func update(enemies: Array, player: Vector2, player_range: float, bounds: Rect2, fleet_orbit_sign: float, delta: float) -> void:
	var desired: Array[Vector2]=[]
	var avoidance: Array[Vector2]=[]
	# Do not mutate positions/velocities until every steering decision is complete.
	for enemy in enemies:
		initialize(enemy, null, fleet_orbit_sign)
		enemy.nav_time=float(enemy.nav_time)+delta
		if bool(enemy.nav_entered): enemy.approach_time=float(enemy.approach_time)+delta
		if bool(enemy.contact_latched) and enemy.position.distance_to(player)>safe_distance(enemy)+12.0:
			enemy.contact_latched=false
			enemy.contact_hits_in_pass=0
		if str(enemy.type_id)=="void_boss": enemy.boss_orbit_time=float(enemy.approach_time)
		enemy.avoid_timer=maxf(0,float(enemy.avoid_timer)-delta)
		enemy.orbit_edge_timer=maxf(0,float(enemy.orbit_edge_timer)-delta)
		desired.append(preferred_velocity(enemy,player,player_range,bounds,delta))
		avoidance.append(Vector2.ZERO)
	for i in range(enemies.size()):
		var a: Dictionary=enemies[i]
		for j in range(i+1,enemies.size()):
			var b: Dictionary=enemies[j]
			# Ships in distinct visual altitude lanes intentionally pass over/under
			# one another and need no planar avoidance.
			if int(a.flight_layer)!=int(b.flight_layer):continue
			var offset: Vector2=a.position-b.position
			# Visual hulls may overlap. Steering reacts before deep intersections,
			# but route intent wins increasingly as each ship closes for contact.
			var margin := (float(a.navigation_radius)+float(b.navigation_radius))*0.68+1.0
			if offset.length_squared()>pow(margin+90.0,2):continue
			var relative: Vector2=a.velocity-b.velocity
			var time := clampf(-offset.dot(relative)/maxf(0.001,relative.length_squared()),0,LOOKAHEAD)
			var projected := offset+relative*time
			var current_distance := offset.length()
			var near := minf(current_distance,projected.length())
			if near>margin+8:continue
			var normal := offset.normalized() if current_distance>0.01 else Vector2.from_angle(float(a.id)*2.39996)
			var urgency := clampf((margin+8-near)/(margin+8),0,1)
			if float(a.avoid_timer)<=0:
				a.avoid_side=-1.0 if (int(a.id)+int(b.id))%2==0 else 1.0
				a.avoid_timer=0.6
			var sidestep := normal.orthogonal()*float(a.avoid_side)*0.3 if current_distance>margin else Vector2.ZERO
			var force := (normal+sidestep)*urgency*3.1
			var share := float(b.navigation_radius)/(float(a.navigation_radius)+float(b.navigation_radius))
			avoidance[i]+=force*share*float(TYPES[str(a.type_id)].top)*lerpf(1.0,0.45,float(a.approach_progress))
			avoidance[j]-=force*(1.0-share)*float(TYPES[str(b.type_id)].top)*lerpf(1.0,0.45,float(b.approach_progress))
	var velocities: Array[Vector2]=[]
	for i in range(enemies.size()):
		var enemy: Dictionary=enemies[i]
		var spec: Dictionary=TYPES[str(enemy.type_id)]
		var top := minf(float(enemy.speed),float(spec.top))
		var acceleration := top*4.0
		var route := desired[i]
		var outside_lane := Vector2(enemy.position).distance_to(player)>float(enemy.nav_target_distance)+10.0
		if Vector2(enemy.velocity).length()<0.5 and route.length()>top*0.25 and (avoidance[i].length()>0.1 or outside_lane):
			enemy.jam_time=float(enemy.get("jam_time",0.0))+delta
		else: enemy.jam_time=0.0
		enemy.escape_timer=maxf(0.0,float(enemy.get("escape_timer",0.0))-delta)
		if float(enemy.jam_time)>1.5 and float(enemy.escape_timer)<=0:
			enemy.escape_timer=3.0
			enemy.jam_time=0.0
		if float(enemy.escape_timer)>0:
			# A blocked ship gives up its slot and skirts the queue on its saved side.
			var radial: Vector2=(enemy.position-player).normalized()
			route=(radial*0.5+radial.orthogonal()*float(enemy.avoid_side))*top
		var wanted := (route+avoidance[i]).limit_length(top)
		var outward: Vector2=enemy.position-player
		var clearance := outward.length()-safe_distance(enemy)
		outward=outward.normalized()
		var closing := -wanted.dot(outward)
		var closing_allowed := maxf(0.0,clearance+2.0)*2.0
		if closing>closing_allowed: wanted+=outward*(closing-closing_allowed)
		wanted=wanted.limit_length(top)
		var old_heading := float(enemy.flight_heading)
		var angle := old_heading
		if wanted.length_squared()>0.001:
			angle+=clampf(wrapf(wanted.angle()-old_heading,-PI,PI),-deg_to_rad(float(spec.turn))*delta,deg_to_rad(float(spec.turn))*delta)
		enemy.flight_heading=angle
		var alignment := maxf(0,cos(wrapf(wanted.angle()-angle,-PI,PI)))
		var speed := move_toward(Vector2(enemy.velocity).length(),wanted.length()*alignment,acceleration*delta)
		var velocity := Vector2.from_angle(angle)*minf(top,speed)
		# Last-resort braking along current heading; never teleport or turn the hull abruptly.
		var inward := -velocity.dot(outward)
		if inward>0 and clearance+2.0<inward*LOOKAHEAD:
			var safe_speed := speed*clampf(maxf(0,clearance+2.0)/(inward*LOOKAHEAD),0,1)
			velocity=Vector2.from_angle(angle)*move_toward(Vector2(enemy.velocity).length(),safe_speed,acceleration*delta)
		velocities.append(velocity)
	for i in range(enemies.size()):
		enemies[i].velocity=velocities[i]
		enemies[i].position+=velocities[i]*delta
