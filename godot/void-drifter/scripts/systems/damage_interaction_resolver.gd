extends RefCounted

const DAMAGE_TYPES := ["kinetic", "electricity", "explosive", "plasma", "beam"]
const MIN_MODIFIER := 0.5
const MAX_MODIFIER := 1.5

static func clamp_modifier(value: float) -> float:
	return clampf(value,MIN_MODIFIER,MAX_MODIFIER)

static func _matches(entry: Dictionary, kind: String, target_id: String) -> bool:
	return str(entry.get("target_kind","")) == kind and str(entry.get("target_id","")) == target_id

static func _modifier(entries: Array, target_kind: String, target_id: String) -> float:
	var result := 1.0
	for entry in entries:
		if _matches(entry,target_kind,target_id): result *= clamp_modifier(float(entry.get("multiplier",1.0)))
	return clamp_modifier(result)

static func _has_match(entries: Array, target_kind: String, target_id: String) -> bool:
	for entry in entries:
		if _matches(entry,target_kind,target_id): return true
	return false

static func profile_is_valid(profile: Dictionary) -> bool:
	var resistances: Array = profile.get("resistances",[])
	var weaknesses: Array = profile.get("weaknesses",[])
	for resistance in resistances:
		if _has_match(weaknesses,str(resistance.get("target_kind","")),str(resistance.get("target_id",""))): return false
	return true

static func resolve(projectile: Dictionary, enemy_profile: Dictionary) -> Dictionary:
	var family := str(projectile.get("weaponFamily",projectile.get("weapon_family","")))
	var damage_type := str(projectile.get("damageType",projectile.get("damage_type","")))
	var base := maxf(0.0,float(projectile.get("damage",projectile.get("resolvedDamage",0.0))))
	var resistances: Array = enemy_profile.get("resistances",[])
	var weaknesses: Array = enemy_profile.get("weaknesses",[])
	var immunities: Array = enemy_profile.get("immunities",[])
	# A conflict is invalid data, so it resolves safely to neutral rather than
	# depending on dictionary order. Immunity is reserved for future effects;
	# direct damage uses the minimum factor instead of reaching zero.
	var valid := profile_is_valid(enemy_profile)
	var family_modifier := 1.0
	var type_modifier := 1.0
	if valid:
		if _has_match(immunities,"damage_type",damage_type) or _has_match(immunities,"family",family):
			type_modifier = MIN_MODIFIER
		else:
			family_modifier = _modifier(resistances,"family",family) * _modifier(weaknesses,"family",family)
			type_modifier = _modifier(resistances,"damage_type",damage_type) * _modifier(weaknesses,"damage_type",damage_type)
	var final_damage := base * clamp_modifier(family_modifier) * clamp_modifier(type_modifier)
	return {"damage":final_damage,"family_modifier":clamp_modifier(family_modifier),"damage_type_modifier":clamp_modifier(type_modifier),"family":family,"damage_type":damage_type,"valid_profile":valid}
