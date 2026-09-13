extends RefCounted

static func choose_target(position: Vector2, bounds: Rect2, enemies: Array, projectiles: Array, speed: float) -> Vector2:
	var best := position
	var best_score := -INF
	for index in range(9):
		var direction := Vector2.ZERO if index == 0 else Vector2.RIGHT.rotated(float(index - 1) * TAU / 8.0)
		var candidate := position + direction * speed * 0.20
		candidate = candidate.clamp(bounds.position, bounds.end)
		var score := 0.0
		# Sample the movement path as well as its destination; do not dodge through a threat.
		for fraction in [0.25, 0.5, 1.0]:
			var sample := position.lerp(candidate, fraction)
			for enemy in enemies:
				var predicted: Vector2 = enemy.position + enemy.get("velocity", Vector2.ZERO) * 0.20 * fraction
				var clearance := sample.distance_to(predicted) - float(enemy.radius) - 12.0
				score -= 800.0 / maxf(1.0, clearance)
			for projectile in projectiles:
				var start: Vector2 = projectile.position
				var end: Vector2 = start + projectile.velocity * 0.35
				var nearest := Geometry2D.get_closest_point_to_segment(sample, start, end)
				var clearance := sample.distance_to(nearest) - float(projectile.radius) - 12.0
				score -= 1200.0 / maxf(1.0, clearance)
		# Prefer holding still when safe and avoid getting trapped at an edge.
		score -= candidate.distance_to(position) * 0.01
		var edge := minf(minf(candidate.x - bounds.position.x, bounds.end.x - candidate.x), minf(candidate.y - bounds.position.y, bounds.end.y - candidate.y))
		score -= 5.0 / maxf(1.0, edge)
		if score > best_score:
			best_score = score
			best = candidate
	return best
