extends RefCounted

const CATALOG := [
	{"id": "damage", "name": "Damage", "category": "Attack", "cap": 500},
	{"id": "fire_rate", "name": "Fire Rate", "category": "Attack", "cap": 38},
	{"id": "crit_chance", "name": "Critical Chance", "category": "Attack", "cap": 50},
	{"id": "range", "name": "Range", "category": "Attack", "cap": 30},
	{"id": "max_hp", "name": "Max Hull", "category": "Defense", "cap": 500},
	{"id": "regen", "name": "Hull Regeneration", "category": "Defense", "cap": 100},
	{"id": "shield_capacity", "name": "Shield Capacity", "category": "Defense", "cap": 100},
	{"id": "shield_recharge", "name": "Shield Recharge", "category": "Defense", "cap": 60},
	{"id": "armor", "name": "Armor", "category": "Defense", "cap": 30},
	{"id": "cash_bonus", "name": "Cash Bonus", "category": "Utility", "cap": 100},
	{"id": "cash_wave", "name": "Cash per Wave", "category": "Utility", "cap": 100},
	{"id": "coin_bonus", "name": "Coin Bonus", "category": "Utility", "cap": 100},
]

static func defaults() -> Dictionary:
	var levels := {}
	for definition in CATALOG:
		levels[definition.id] = 0
	return levels

static func definition(id: String) -> Dictionary:
	for entry in CATALOG:
		if entry.id == id:
			return entry
	return {}

static func level(id: String, permanent: Dictionary, temporary: Dictionary = {}) -> int:
	var entry := definition(id)
	if entry.is_empty():
		return 0
	return clampi(int(permanent.get(id, 0)) + int(temporary.get(id, 0)), 0, int(entry.cap))

static func value(id: String, levels: int) -> float:
	match id:
		"damage": return 8.0 * (1.0 + 0.15 * levels)
		"fire_rate": return maxf(90.0, 500.0 / (1.0 + (41.0 / 342.0) * levels))
		"crit_chance": return levels * 0.01
		"range": return 160.0 + 2.0 * levels
		"max_hp": return 140.0 + 20.0 * levels
		"regen": return 0.5 + 0.5 * levels
		"shield_capacity": return 30.0 + 10.0 * levels
		"shield_recharge": return 0.5 + 0.5 * levels
		"armor": return levels * 0.02
		"cash_bonus", "coin_bonus": return 1.0 + 0.05 * levels
		"cash_wave": return 5.0 * levels
	return 0.0

static func display_value(id: String, levels: int) -> String:
	var amount := value(id, levels)
	match id:
		"fire_rate": return "%.2f/s" % (1000.0 / amount)
		"crit_chance", "armor": return "%d%%" % roundi(amount * 100.0)
		"regen": return "%.1f HP/s" % amount
		"shield_capacity": return "%.0f SP" % amount
		"shield_recharge": return "%.1f SP/s" % amount
		"range": return "%d units" % roundi(amount)
		"cash_bonus", "coin_bonus": return "%.2fx" % amount
	return "%.1f" % amount

static func cost(levels: int, permanent: bool) -> float:
	return ceil((25.0 if permanent else 10.0) * pow(1.18 if permanent else 1.10, levels))

# Pure quote: the caller applies wallet and levels together, then saves once.
static func quote(id: String, permanent: Dictionary, temporary: Dictionary, wallet: float, count: int, workshop: bool) -> Dictionary:
	var entry := definition(id)
	var purchased := 0
	var spent := 0.0
	var current := level(id, permanent, {} if workshop else temporary)
	if entry.is_empty():
		return {"count": 0, "cost": 0.0}
	for index in range(clampi(count, 1, 10)):
		if current + index >= int(entry.cap):
			break
		var price := cost(current + index, workshop)
		if spent + price > wallet:
			break
		spent += price
		purchased += 1
	return {"count": purchased, "cost": spent}
