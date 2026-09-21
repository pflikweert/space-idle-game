extends SceneTree

const Equipment := preload("res://scripts/systems/equipment_registry.gd")
const Enemies := preload("res://scripts/systems/enemy_registry.gd")
const Damage := preload("res://scripts/systems/damage_interaction_resolver.gd")
const Profile := preload("res://scripts/profile_store.gd")
var checks := 0
var failures := 0
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: "+message)
func _initialize() -> void: call_deferred("run_tests")
func run_tests() -> void:
	var blueprint := Equipment.definition(Equipment.MICRO_MISSILE_RACK_ID)
	expect(blueprint.get("family") == "explosive" and blueprint.get("damage_type") == "explosive", "Micro Missile blueprint family and damage type")
	var level_one := Equipment.micro_missile_stats(1); var level_twenty := Equipment.micro_missile_stats(20)
	expect(is_equal_approx(Equipment.damage_from_ship(Equipment.MICRO_MISSILE_RACK_ID,1,8.0),10.4) and int(level_one.magazine)==3 and is_equal_approx(float(level_one.reload),4.0), "Level 1 stats use ship damage")
	expect(is_equal_approx(Equipment.damage_from_ship(Equipment.MICRO_MISSILE_RACK_ID,20,8.0),48.4) and int(level_twenty.magazine)==3 and is_equal_approx(float(level_twenty.reload),3.6) and is_equal_approx(float(level_twenty.range),200.0) and is_equal_approx(float(level_twenty.super_chance),0.3), "Damage scaling and missile payload milestones")
	expect(int(Equipment.micro_missile_upgrade_cost(1).coins)==600 and int(Equipment.micro_missile_upgrade_cost(2).coins)==935 and int(Equipment.micro_missile_upgrade_cost(1).modules)==2 and int(Equipment.micro_missile_upgrade_cost(2).modules)==3, "Upgrade cost curve")
	var drone := Enemies.get_definition(Enemies.ARMORED_DRONE_ID)
	expect(int(drone.base_stats.hp)==36 and int(drone.spawn.weight)==12 and int(drone.spawn.min_run_level)==4, "Armored Drone roster stats")
	var missile_hit := Damage.resolve({"damage":18.0,"weaponFamily":"explosive","damageType":"explosive"},drone)
	var rail_hit := Damage.resolve({"damage":8.0,"weaponFamily":"railgun","damageType":"kinetic"},drone)
	expect(is_equal_approx(float(missile_hit.damage),22.5), "Explosive weakness resolves to 22.5")
	expect(is_equal_approx(float(rail_hit.damage),6.0), "Kinetic resistance resolves Starter hit to 6")
	var profile_store := Profile.new(); var profile := profile_store._default_profile()
	profile = profile_store.record_run(profile,{"run_id":"phase11-drone","enemy_kills":{"armored_drone":1}})
	expect(Equipment.MICRO_MISSILE_RACK_ID in profile.unlockedEquipmentBlueprints, "Blueprint unlocks at settlement")
	print("Phase 11 checks: %d passed / %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
