extends RefCounted

const RECHARGE_DELAY := 3.0

static func absorb(player: Dictionary, damage: float) -> Dictionary:
	if damage <= 0.0: return {"shield": 0.0, "hull": 0.0, "broken": false}
	player.shield_delay = RECHARGE_DELAY
	var before := maxf(0.0, float(player.get("shield", 0.0)))
	var absorbed := minf(before, damage)
	player.shield = before - absorbed
	var hull_loss := minf(maxf(0.0, float(player.hp)), damage - absorbed)
	player.hp = maxf(0.0, float(player.hp) - hull_loss)
	return {"shield": absorbed, "hull": hull_loss, "broken": before > 0.0 and player.shield == 0.0}

static func update(player: Dictionary, delta: float, rate: float) -> void:
	var delay := maxf(0.0, float(player.get("shield_delay", 0.0)))
	player.shield_delay = maxf(0.0, delay - delta)
	var charging_time := maxf(0.0, delta - delay)
	player.shield = minf(float(player.max_shield), maxf(0.0, float(player.shield)) + rate * charging_time)
