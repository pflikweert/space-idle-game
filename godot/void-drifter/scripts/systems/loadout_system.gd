extends RefCounted

const Ships := preload("res://scripts/systems/ship_registry.gd")
const Equipment := preload("res://scripts/systems/equipment_registry.gd")
const MAX_ACTIVE_WEAPONS := 5
const MAX_ACTIVE_WEAPON_FAMILIES := 5

static func starter_ship_state() -> Dictionary:
	return {"upgrade_level":0,"mastery_level":0,"mastery_xp":0,"loadout":{"W1":Equipment.RAILGUN_INSTANCE_ID,"W2":"","W3":"","W4":"","S1":Equipment.SHIELD_CORE_INSTANCE_ID,"S2":""},"slot_enabled":{"W1":true,"W2":true,"W3":true,"W4":true,"S1":true,"S2":true}}

static func validate(ship_id: String, loadout: Dictionary, items: Dictionary) -> Dictionary:
	var ship := Ships.fixture_definition(ship_id) if ship_id.ends_with("_fixture") else Ships.definition(ship_id)
	var clean := {}; var used := {}; var errors: Array[String] = []
	if ship.is_empty(): return {"loadout":{},"valid":false,"errors":["unknown_ship:%s" % ship_id]}
	var known_slots := {}
	var weapon_slots := 0
	for hardpoint in ship.get("slots", []):
		var slot_id := str(hardpoint.id); var instance_id := str(loadout.get(slot_id, "")); clean[slot_id] = ""
		known_slots[slot_id] = true
		if str(hardpoint.get("type","")) == "weapon" and hardpoint.get("accepts",[]).has("weapon"): weapon_slots += 1
		if instance_id == "": continue
		if used.has(instance_id): errors.append("duplicate_instance:%s" % instance_id); continue
		var instance: Dictionary = items.get(instance_id, {})
		var equipment := Equipment.definition(str(instance.get("blueprint_id", "")))
		if instance.is_empty() or equipment.is_empty(): errors.append("missing_instance:%s" % instance_id); continue
		if not hardpoint.get("accepts", []).has(str(equipment.item_type)): errors.append("incompatible:%s:%s" % [slot_id,instance_id]); continue
		clean[slot_id] = instance_id; used[instance_id] = true
	for supplied_slot in loadout:
		if not known_slots.has(str(supplied_slot)) and not str(loadout[supplied_slot]).is_empty(): errors.append("unknown_slot:%s" % supplied_slot)
	var active_weapons := 0; var families := {}; var copies := {}
	for slot_id in clean:
		var instance_id := str(clean[slot_id]); if instance_id.is_empty(): continue
		var instance: Dictionary = items.get(instance_id,{})
		var equipment: Dictionary = Equipment.definition(str(instance.get("blueprint_id","")))
		if str(equipment.get("item_type","")) != "weapon": continue
		active_weapons += 1
		var family := str(equipment.get("family",equipment.get("weapon_family","")))
		if not family.is_empty(): families[family] = true
		var blueprint_id := str(instance.get("blueprint_id","")); copies[blueprint_id] = int(copies.get(blueprint_id,0)) + 1
	var global_weapon_cap := MAX_ACTIVE_WEAPONS
	var ship_weapon_cap := int(ship.get("max_active_weapons",weapon_slots))
	var effective_weapon_cap := mini(global_weapon_cap,mini(ship_weapon_cap,weapon_slots))
	if active_weapons > effective_weapon_cap: errors.append("active_weapon_cap:%d" % effective_weapon_cap)
	var global_family_cap := MAX_ACTIVE_WEAPON_FAMILIES
	var ship_family_cap := int(ship.get("max_active_weapon_families",global_family_cap))
	if families.size() > mini(global_family_cap,ship_family_cap): errors.append("weapon_family_cap:%d" % mini(global_family_cap,ship_family_cap))
	for blueprint_id in copies:
		var max_copies := int(Equipment.definition(str(blueprint_id)).get("max_active_copies",999))
		if int(copies[blueprint_id]) > max_copies: errors.append("active_copy_cap:%s:%d" % [blueprint_id,max_copies])
	return {"loadout":clean,"valid":errors.is_empty(),"errors":errors}

static func reserve_items(profile: Dictionary, ship_id := "") -> Array[String]:
	var active_ship := ship_id if ship_id != "" else str(profile.get("activeShipId",Ships.STARTER_SHIP_ID))
	var equipped := {}
	for instance_id in profile.get("ships",{}).get(active_ship,{}).get("loadout",{}).values():
		if str(instance_id) != "": equipped[str(instance_id)] = true
	var reserve: Array[String] = []
	for instance_id in profile.get("equipmentInventory",[]):
		if not equipped.has(str(instance_id)): reserve.append(str(instance_id))
	return reserve

static func installed_instance(profile: Dictionary, slot_id: String, ship_id := "") -> Dictionary:
	var active_ship := ship_id if ship_id != "" else str(profile.get("activeShipId",Ships.STARTER_SHIP_ID))
	var instance_id := str(profile.get("ships",{}).get(active_ship,{}).get("loadout",{}).get(slot_id,""))
	return profile.get("equipmentItems",{}).get(instance_id,{})
