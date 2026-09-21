extends SceneTree

const Damage := preload("res://scripts/systems/damage_interaction_resolver.gd")
const Enemies := preload("res://scripts/systems/enemy_registry.gd")

var checks := 0
var failures := 0
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: "+message)

func _initialize() -> void: call_deferred("run_tests")

func run_tests() -> void:
	var kinetic := {"damage":100.0,"weaponFamily":"railgun","damageType":"kinetic"}
	for id in [Enemies.VOID_DRONE_ID,Enemies.RED_SCOUT_ID,Enemies.VOID_TANK_ID,Enemies.BOSS_ID,Enemies.RANGED_SHOOTER_ID]:
		var neutral := Damage.resolve(kinetic,Enemies.get_definition(id))
		expect(is_equal_approx(float(neutral.damage),100.0),"Current roster remains neutral: "+id)
	var resistance := Damage.resolve(kinetic,{"resistances":[{"target_kind":"damage_type","target_id":"kinetic","multiplier":0.75}],"weaknesses":[],"immunities":[]})
	expect(is_equal_approx(float(resistance.damage),75.0),"Damage-type resistance reduces damage")
	var weakness := Damage.resolve(kinetic,{"resistances":[],"weaknesses":[{"target_kind":"damage_type","target_id":"kinetic","multiplier":1.25}],"immunities":[]})
	expect(is_equal_approx(float(weakness.damage),125.0),"Damage-type weakness increases damage")
	var combined := Damage.resolve(kinetic,{"resistances":[{"target_kind":"family","target_id":"railgun","multiplier":0.75}],"weaknesses":[{"target_kind":"damage_type","target_id":"kinetic","multiplier":1.25}],"immunities":[]})
	expect(is_equal_approx(float(combined.damage),93.75) and is_equal_approx(float(combined.family_modifier),0.75) and is_equal_approx(float(combined.damage_type_modifier),1.25),"Family modifier then damage-type modifier has fixed order")
	var clamped := Damage.resolve(kinetic,{"resistances":[{"target_kind":"damage_type","target_id":"kinetic","multiplier":0.1}],"weaknesses":[],"immunities":[]})
	expect(is_equal_approx(float(clamped.damage),50.0),"Resistance clamps at 0.5")
	var immune := Damage.resolve(kinetic,{"resistances":[],"weaknesses":[],"immunities":[{"target_kind":"damage_type","target_id":"kinetic","multiplier":0.0}]})
	expect(is_equal_approx(float(immune.damage),50.0),"Direct immunity resolves to minimum damage factor")
	var conflict := Damage.resolve(kinetic,{"resistances":[{"target_kind":"damage_type","target_id":"kinetic","multiplier":0.75}],"weaknesses":[{"target_kind":"damage_type","target_id":"kinetic","multiplier":1.25}],"immunities":[]})
	expect(not bool(conflict.valid_profile) and is_equal_approx(float(conflict.damage),100.0),"Conflicting resistance and weakness resolve safely to neutral")
	var unknown := Damage.resolve({"damage":100.0,"weaponFamily":"unknown_family","damageType":"unknown_type"},{"resistances":[],"weaknesses":[],"immunities":[]})
	expect(is_equal_approx(float(unknown.damage),100.0),"Unknown family and damage type stay safe")
	var beam := Damage.resolve({"damage":100.0,"weaponFamily":"beam","damageType":"beam"},{"resistances":[],"weaknesses":[{"target_kind":"family","target_id":"beam","multiplier":1.25}],"immunities":[]})
	expect(is_equal_approx(float(beam.damage),125.0),"Family fixture supports beam interaction")
	print("Damage interaction checks: %d, failures: %d" % [checks,failures])
	print("DAMAGE_TABLE: neutral kinetic 1.0 -> 100.00 | electricity resistance 0.75 -> 75.00 | explosive weakness 1.25 -> 125.00 | immunity floor 0.50 -> %.2f" % float(immune.damage))
	quit(1 if failures else 0)
