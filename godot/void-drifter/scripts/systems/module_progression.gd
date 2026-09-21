extends RefCounted

## Shared progression rules for every equipment instance and ship chassis.
## This registry deliberately owns caps, rarity order and milestone eligibility;
## combat effects move into the module resolver in the next implementation phase.

const RARITIES := ["common", "rare", "epic", "legendary"]
const LEVEL_CAPS := {"common":40, "rare":80, "epic":120, "legendary":160}
const BLUEPRINT_IDS := {"rare":"rare_blueprint", "epic":"epic_blueprint", "legendary":"legendary_blueprint"}

static func valid_rarity(value: String) -> String:
	return value if RARITIES.has(value) else "common"

static func level_cap(rarity: String) -> int:
	return int(LEVEL_CAPS.get(valid_rarity(rarity), LEVEL_CAPS.common))

static func next_rarity(rarity: String) -> String:
	var index := RARITIES.find(valid_rarity(rarity))
	return RARITIES[index + 1] if index >= 0 and index + 1 < RARITIES.size() else ""

static func required_blueprint(rarity: String) -> String:
	return str(BLUEPRINT_IDS.get(valid_rarity(rarity), ""))

static func can_promote(item: Dictionary, owned_blueprints: Dictionary) -> bool:
	var current := valid_rarity(str(item.get("rarity", "common")))
	var target := next_rarity(current)
	if target.is_empty() or int(item.get("level", 1)) < level_cap(current): return false
	return int(owned_blueprints.get(required_blueprint(target), 0)) > 0

static func sanitize_item(item: Dictionary, blueprint: Dictionary) -> Dictionary:
	var clean := item.duplicate(true)
	var rarity := valid_rarity(str(clean.get("rarity", blueprint.get("rarity", "common"))))
	clean.rarity = rarity
	clean.level = clampi(int(clean.get("level", 1)), 1, level_cap(rarity))
	clean.xp = maxi(0, int(clean.get("xp", 0)))
	clean.milestones = _unique_levels(clean.get("milestones", []), int(clean.level))
	return clean

static func _unique_levels(raw: Variant, maximum: int) -> Array:
	var result: Array = []
	if not raw is Array: return result
	for value in raw:
		var level := int(value)
		if level <= 0 or level > maximum or level % 5 != 0 or result.has(level): continue
		result.append(level)
	result.sort()
	return result
static func unlocked_milestones(level: int) -> Array:
	var result: Array = []
	for milestone in range(5, maxi(1, level) + 1, 5): result.append(milestone)
	return result
