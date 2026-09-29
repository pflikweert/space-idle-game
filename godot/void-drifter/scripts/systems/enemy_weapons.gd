extends RefCounted

const Registry := preload("res://scripts/systems/enemy_registry.gd")
const Weapons := preload("res://scripts/systems/weapon_registry.gd")
const ROCKET_SPEED := 85.0
const ROCKET_TURN := PI * 35.0 / 180.0
const ROCKET_LIFE := 8.0
# Forward shoulder launch bays on the fixed 384x512 dreadnought canvas.
const LAUNCHERS := [Vector2(151, 206), Vector2(237, 206)]
const RAIL_PIVOT := Vector2(192, 206)
const RAIL_LENGTH := 7.0

static func weapon_id(enemy: Dictionary) -> String:
	if str(enemy.get("type_id", "")) == Registry.BOSS_ID:
		match str(enemy.get("boss_variant", "")):
			"rail_fortress": return "tank_railgun"
			"rift_carrier": return "enemy_railgun"
	return str(enemy.get("attack_behavior", "contact"))

static func active_rockets(game, owner_id: int) -> int:
	var count := 0
	for shot in game.enemy_projectiles:
		if shot.get("weapon_id", "") == "boss_rocket" and int(shot.get("owner_id", -1)) == owner_id and float(shot.life) > 0.0:
			count += 1
	return count

static func pivot(game, enemy: Dictionary) -> Vector2:
	var rocket := weapon_id(enemy) == "boss_rocket"
	var definition: Dictionary = game._get_enemy_definition(str(enemy.type_id))
	var scale: float = float(definition.visual_canvas_height) * game.COMBAT_SPRITE_SCALE * game._gameplay_visual_scale() / 512.0
	var anchor: Vector2 = LAUNCHERS[int(enemy.get("launcher_index", 0)) % 2] if rocket else Vector2(Weapons.cycle(weapon_id(enemy)).get("pivot", RAIL_PIVOT))
	return enemy.position + ((anchor - Vector2(192, 256)) * scale).rotated(game._enemy_visual_rotation(enemy))

static func aim(game, enemy: Dictionary) -> Vector2:
	return enemy.get("attack_direction", game._get_enemy_forward_direction(enemy))

static func origin(game, enemy: Dictionary) -> Vector2:
	return pivot(game, enemy) + (aim(game, enemy) * float(Weapons.cycle(weapon_id(enemy)).get("barrel", RAIL_LENGTH)) if weapon_id(enemy) != "boss_rocket" else Vector2.ZERO)

static func eligible(game, enemy: Dictionary) -> bool:
	if not game._enemy_is_visible(enemy): return false
	var rocket := weapon_id(enemy) == "boss_rocket"
	if str(enemy.type_id)=="red_scout" and enemy.get("scout_phase","approach")!="approach": return false
	if enemy.position.distance_to(game.player.position) > game._stat("range") * (0.95 if str(enemy.type_id)=="ranged_shooter" else 1.0): return false
	return not rocket or active_rockets(game, int(enemy.id)) < 2

static func update(game, enemy: Dictionary, delta: float) -> void:
	enemy.attack_real_timer = maxf(0.0, float(enemy.get("attack_real_timer", 0.0)) - delta / float(game._game_speed()))
	var id := weapon_id(enemy)
	if not Weapons.CYCLES.has(id): return
	Weapons.ensure_cycle(enemy, id)
	var spec := Weapons.cycle(id)
	var remaining := Weapons.tick_reload(enemy, id, delta)
	if float(enemy.reload_timer) > 0.0: return
	var cooldown := maxf(0.0, float(enemy.get("fire_cooldown", 0.0)))
	enemy.fire_cooldown = maxf(0.0, cooldown - remaining)
	remaining = maxf(0.0, remaining - cooldown)
	if float(enemy.fire_cooldown) > 0.000001: return
	if not eligible(game, enemy):
		enemy.attack_warmup_timer = 0.0
		return
	if float(enemy.get("attack_warmup_timer", 0.0)) <= 0.0:
		# Lock a world-space target for the warning. Fast circling ships may move far
		# enough during warmup that reusing their old aim angle from a new muzzle would
		# send the round beside an otherwise stationary player.
		enemy.attack_target = game._player_deflector_surface(pivot(game, enemy), enemy.get("attack_direction", game._get_enemy_forward_direction(enemy)))
		enemy.attack_direction = (Vector2(enemy.attack_target) - pivot(game, enemy)).normalized()
		enemy.attack_warmup_timer = float(spec.warmup)
		if str(enemy.get("type_id", "")) in [Registry.BOSS_ID, Registry.ELITE_HUNTER_ID, Registry.KAMIKAZE_ID]:
			enemy.attack_real_timer = maxf(0.30, float(spec.warmup) / float(game._game_speed()))
	var overshoot := maxf(0.0, remaining - float(enemy.attack_warmup_timer))
	enemy.attack_warmup_timer = maxf(0.0, float(enemy.attack_warmup_timer) - remaining)
	if float(enemy.attack_warmup_timer) > 0.000001 or float(enemy.get("attack_real_timer", 0.0)) > 0.000001: return
	enemy.attack_warmup_timer = 0.0
	fire(game, enemy)
	Weapons.consume(enemy, id)
	# Warmup is part of the next shot interval, not added on top.
	enemy.fire_cooldown = maxf(0.0, float(spec.interval) - float(spec.warmup) - overshoot) if int(enemy.ammo) > 0 else 0.0

	if int(enemy.ammo) == 0: Weapons.tick_reload(enemy, id, overshoot)

static func fire(game, enemy: Dictionary) -> void:
	var id := weapon_id(enemy)
	var rocket := id == "boss_rocket"
	var start := origin(game, enemy)
	var direction := aim(game, enemy).normalized()
	# Reacquire the closest field surface at the muzzle after warm-up.
	var target: Vector2 = game._player_deflector_surface(start, direction)
	if target.distance_squared_to(start) > 0.001:
		direction = (target - start).normalized()
	var life := ROCKET_LIFE if rocket else 2.2
	var base_contact := float(Registry.get_definition(str(enemy.type_id)).base_stats.contact_damage)
	var damage := float(Weapons.cycle(id).damage)*float(enemy.contact_damage)/maxf(0.001,base_contact)
	game.enemy_projectiles.append({"id": game.next_id, "owner_id": int(enemy.id), "weapon_id": id,
		"position": start, "previous_position": start, "radius": 3.2 if rocket else 2.0,
		"velocity": direction * (ROCKET_SPEED if rocket else Weapons.PROJECTILE_SPEED),
		"damage": damage,
		"damage_multiplier": 1.0, "life": life,
		"visual_trail_points": [start]})
	game.next_id += 1
	# Detached real-time flash keeps its exact launcher/muzzle when the ship moves.
	var flash: Dictionary = game.EffectRegistry.make("enemy_muzzle", start)
	flash.direction = direction
	flash.weapon_id = id
	game._append_effect(flash)
	enemy.attack_visual_timer = game.ENEMY_ATTACK_VISUAL_SECONDS
	if rocket: enemy.launcher_index = (int(enemy.get("launcher_index", 0)) + 1) % 2
	game.audio_events.emit(game.AudioEvents.SHOOT, {"source": "enemy", "weapon": id})

static func move_projectile(game, shot: Dictionary, delta: float) -> void:
	shot.previous_position = shot.position
	var step := minf(delta, maxf(0.0, float(shot.life)))
	if shot.get("weapon_id", "") == "boss_rocket":
		var velocity: Vector2 = shot.velocity
		var desired: Vector2 = game._player_deflector_surface(shot.position, -velocity.normalized()) - shot.position
		if desired.length_squared() > 0.001:
			var turn := clampf(wrapf(desired.angle() - velocity.angle(), -PI, PI), -ROCKET_TURN * step, ROCKET_TURN * step)
			shot.velocity = velocity.rotated(turn)
	shot.position += shot.velocity * step
	game._append_projectile_visual_samples(shot,"visual_trail_points",5.0,48 if shot.get("weapon_id","") == "boss_rocket" else 24)
	shot.life = maxf(0.0, float(shot.life) - delta)
