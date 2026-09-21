extends SceneTree

const Progression := preload("res://scripts/systems/module_progression.gd")
const Equipment := preload("res://scripts/systems/equipment_registry.gd")
const Store := preload("res://scripts/profile_store.gd")
const WeaponStats := preload("res://scripts/systems/weapon_stat_resolver.gd")
const Ships := preload("res://scripts/systems/ship_registry.gd")

var checks := 0
var failures := 0

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	var starter: Dictionary = Equipment.starter_instances()[Equipment.RAILGUN_INSTANCE_ID]
	expect(starter.rarity == "common" and starter.level == 1 and starter.xp == 0 and starter.milestones.is_empty(), "Starter module has Common progression state")
	expect(Progression.level_cap("common") == 40 and Progression.level_cap("rare") == 80 and Progression.next_rarity("rare") == "epic", "Shared rarity caps are ordered")
	var sanitized := Progression.sanitize_item({"level":999,"rarity":"unknown","xp":-4,"milestones":[5,5,7,45]}, Equipment.definition(Equipment.RAILGUN_ID))
	expect(sanitized.rarity == "common" and sanitized.level == 40 and sanitized.xp == 0 and sanitized.milestones == [5], "Item sanitization clamps invalid progression safely")
	var item := {"level":40,"rarity":"common"}
	expect(Progression.can_promote(item,{"rare_blueprint":1}), "A capped Common item can use a Rare Blueprint")
	expect(not Progression.can_promote(item,{"rare_blueprint":0}), "Promotion requires an owned blueprint")
	var rail_base := {"damage":8.0,"reload":3.0,"hits":1,"crit":0.02}
	rail_base.merge({"milestone_damage_multiplier":float(Equipment.railgun_stats(5).damage_multiplier),"milestone_crit_bonus":float(Equipment.railgun_stats(5).crit_bonus)},true)
	var level_five := WeaponStats.resolve(Equipment.RAILGUN_ID,"railgun",5,rail_base,{"ranks":{"power":99}},0.02)
	expect(is_equal_approx(level_five.damage,14.08) and is_equal_approx(float(level_five.crit),0.07) and level_five.hits == 1, "Level 5 grants Heavy Caliber damage and crit")
	var level_twenty := Equipment.railgun_stats(20)
	expect(int(level_twenty.shatter_fragments) == 2 and is_equal_approx(float(level_twenty.shatter_damage_ratio),0.5) and is_equal_approx(float(level_twenty.void_burst_ratio),0.5) and is_equal_approx(float(level_twenty.void_burst_radius),42.0) and not level_twenty.has("shots"), "Railgun Shatter and Void Burst stats resolve from milestones")
	var store := Store.new()
	var old := store._default_profile()
	old.saveVersion = 8
	old.equipmentItems[Equipment.RAILGUN_INSTANCE_ID].level = 12
	old.activeRun = {"cards":{"modules":2,"ranks":{"power":3,"twin":1}}}
	var migrated := store._migrate_shield_core_profile(store._migrate_cardless_profile(old))
	expect(migrated.saveVersion == Store.SAVE_VERSION and migrated.equipmentItems[Equipment.RAILGUN_INSTANCE_ID].level == 12 and migrated.equipmentItems[Equipment.RAILGUN_INSTANCE_ID].rarity == "common", "Version 8 migration preserves item level and Common rarity")
	expect(not migrated.settings.has("autoCards") and not migrated.activeRun.has("cards") and migrated.railgunModules == 6 and migrated.equipmentItems[Equipment.RAILGUN_INSTANCE_ID].xp == 320, "Cardless migration removes card state and compensates active-run investment")
	var shield := Equipment.shield_core_stats(20)
	expect(shield.capacity > 30.0 and shield.recharge > 0.5 and shield.recharge_delay < 3.0, "Shield Core levels apply deterministic capacity, recharge and delay milestones")
	var rail_40 := Equipment.railgun_stats(40)
	var missile_40 := Equipment.micro_missile_stats(40)
	expect(int(rail_40.additional_bullets) == 3 and int(rail_40.penetration_bonus) == 2 and is_equal_approx(float(rail_40.reload),2.1) and is_equal_approx(float(rail_40.rampage_cap),1.0) and is_equal_approx(float(rail_40.void_burst_ratio),0.65) and is_equal_approx(float(rail_40.void_burst_radius),54.6) and is_equal_approx(float(missile_40.echo_damage_ratio),0.6) and is_equal_approx(float(missile_40.echo_radius_multiplier),1.5), "Level 40 Epic payloads preserve Rampage cap and amplify Void Burst")
	expect(Equipment.definition(Equipment.RAILGUN_ID).name == "Railgun" and Equipment.definition(Equipment.RAILGUN_ID).max_active_copies == 4, "Railgun blueprint owns the starter and copy instances")
	expect(Ships.upgrade_cost(0) == 750 and Ships.upgraded_stat(Ships.STARTER_SHIP_ID,"max_hp",5) == 180.0 and Ships.upgraded_stat(Ships.STARTER_SHIP_ID,"damage",5) == 10.5 and Ships.upgraded_stat(Ships.STARTER_SHIP_ID,"move_speed",5) == 470.0, "Ship chassis levels use hull and base attack progression while movement speed stays fixed")
	expect(Equipment.railgun_upgrade_cost(1).modules == 2 and Equipment.railgun_upgrade_cost(2).modules == 3 and Equipment.railgun_upgrade_cost(5).modules == 6 and Equipment.shield_core_upgrade_cost(1).modules == 2 and Equipment.micro_missile_upgrade_cost(1).modules == 2, "Module upgrade costs rise one Boss Module per next level")
	print("Module progression checks: %d, failures: %d" % [checks, failures])
	quit(1 if failures else 0)
