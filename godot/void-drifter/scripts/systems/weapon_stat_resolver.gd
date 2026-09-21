extends RefCounted

const Equipment := preload("res://scripts/systems/equipment_registry.gd")

## Single runtime stat resolver for every active weapon instance.
## Railgun milestones are deterministic module progress, not random run cards.
static func resolve(blueprint_id: String, family: String, level: int, base_stats: Dictionary, _legacy_cards: Dictionary = {}, base_crit := 0.0) -> Dictionary:
	var result := base_stats.duplicate(true)
	if family != "railgun": return result
	if blueprint_id != Equipment.RAILGUN_ID: return result
	var module_level_multiplier := 1.0 + 0.025 * float(maxi(0, level - 1))
	result.damage = float(result.get("damage",1.0)) * module_level_multiplier
	result.damage *= float(result.get("milestone_damage_multiplier",1.0))
	result.crit = minf(1.0, base_crit + float(result.get("milestone_crit_bonus",0.0)))
	return result
