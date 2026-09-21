extends SceneTree

const Store := preload("res://scripts/profile_store.gd")
const Equipment := preload("res://scripts/systems/equipment_registry.gd")
const Loadouts := preload("res://scripts/systems/loadout_system.gd")
const Game := preload("res://scripts/void_drifter_game.gd")

var checks := 0
var failures := 0

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: "+message)

func fixture_items(count: int, families: Array = []) -> Dictionary:
	var items := {}
	for index in count:
		var family := str(families[index]) if index < families.size() else "railgun"
		var id := "fixture-%d" % index
		items[id] = {"id":id,"blueprint_id":"fixture_weapon_%s" % family,"level":1}
	return items

func _initialize() -> void: call_deferred("run_tests")

func run_tests() -> void:
	expect(Loadouts.MAX_ACTIVE_WEAPONS == 5 and Loadouts.MAX_ACTIVE_WEAPON_FAMILIES == 5,"Global active weapon and family caps are explicit")
	var starter_items := fixture_items(4)
	var four := {"W1":"fixture-0","W2":"fixture-1","W3":"fixture-2","W4":"fixture-3","S1":"","S2":""}
	var result := Loadouts.validate("starter_ship",four,starter_items)
	expect(result.valid,"Starter allows four active weapons")
	var five := four.duplicate(true); five["W5"] = "fixture-0"
	result = Loadouts.validate("starter_ship",five,starter_items)
	expect(not result.valid and result.errors.has("unknown_slot:W5"),"Starter fifth weapon is rejected by physical hardpoints")
	var assault_items := fixture_items(6,["electricity","explosive","kinetic","plasma","laser","missile"])
	var assault := {"W1":"fixture-0","W2":"fixture-1","W3":"fixture-2","W4":"fixture-3","W5":"fixture-4","W6":"fixture-5"}
	result = Loadouts.validate("assault_fixture",assault,assault_items)
	expect(not result.valid and result.errors.has("active_weapon_cap:5"),"Assault sixth weapon hits global cap")
	result = Loadouts.validate("assault_fixture",assault,assault_items.duplicate(true))
	expect(result.errors.has("weapon_family_cap:5") or result.errors.has("active_weapon_cap:5"),"Six distinct families are rejected")
	var five_families := fixture_items(6,["railgun","railgun","electricity","explosive","plasma","laser"])
	result = Loadouts.validate("assault_fixture",assault,five_families)
	expect(not result.valid and result.errors.has("active_weapon_cap:5") and not result.errors.has("weapon_family_cap:5"),"Multiple Railguns count as one family")
	var support := {"W1":"fixture-0","W2":"fixture-1"}
	result = Loadouts.validate("support_fixture",support,fixture_items(2,["railgun","electricity"]))
	expect(result.valid,"Support fixture accepts its two weapons")
	var support_over := support.duplicate(true); support_over.W3 = "fixture-0"
	result = Loadouts.validate("support_fixture",support_over,fixture_items(2,["railgun","electricity"]))
	expect(not result.valid and result.errors.has("unknown_slot:W3"),"Support physical capacity is enforced")
	var specialist := {"W1":"fixture-0","W2":"fixture-1","W3":"fixture-2"}
	result = Loadouts.validate("specialist_fixture",specialist,fixture_items(3,["railgun","electricity","explosive"]))
	expect(not result.valid and result.errors.has("weapon_family_cap:2"),"Specialist lower family cap is enforced")
	var duplicate := {"W1":"fixture-0","W2":"fixture-0"}
	result = Loadouts.validate("assault_fixture",duplicate,fixture_items(1))
	expect(not result.valid and result.errors.has("duplicate_instance:fixture-0"),"Duplicate instance use is rejected")
	var wrong_type := {"S1":"fixture-0"}
	result = Loadouts.validate("starter_ship",wrong_type,fixture_items(1))
	expect(not result.valid and result.errors.has("incompatible:S1:fixture-0"),"Weapon in system slot is rejected")
	var profile := Store.new()._default_profile()
	profile.equipmentItems.merge(fixture_items(1)); profile.equipmentInventory.append("fixture-0")
	var invalid := {"W1":Equipment.RAILGUN_INSTANCE_ID,"W2":"fixture-0","W3":"","W4":"","S1":Equipment.SHIELD_CORE_INSTANCE_ID,"S2":""}
	profile.ships.starter_ship.loadout = Loadouts.validate("starter_ship",invalid,profile.equipmentItems).loadout
	var reserve := Loadouts.reserve_items(profile)
	expect(reserve.is_empty(),"Installed items leave no duplicate reserve entries")
	var rejected := invalid.duplicate(true); rejected.W5 = "fixture-0"
	var rejected_result := Loadouts.validate("starter_ship",rejected,profile.equipmentItems)
	expect(not rejected_result.valid and profile.equipmentInventory.has("fixture-0"),"Rejected installation preserves reserve inventory")
	var path := OS.get_cache_dir().path_join("void-active-loadout-%d.json" % Time.get_ticks_usec()); var store := Store.new(); store.profile_path = path
	profile.ships.starter_ship.loadout.W2 = "fixture-0"; store.save_profile(profile); var loaded := store.load_profile()
	expect(loaded.ships.starter_ship.loadout.W2 == "fixture-0" and Loadouts.reserve_items(loaded).is_empty(),"Save/load preserves active and reserve state")
	var game := Game.new(); game.profile_store = store; root.add_child(game); game.set_process(false); game.profile = loaded; game.metaProgress = loaded; game.status = "menu"; game.start_run()
	game._save_run(); var snapshot: Dictionary = Store.decode(game.profile.activeRun)
	var run_check := Loadouts.validate("starter_ship",snapshot.combat_loadout,game.profile.equipmentItems)
	expect(run_check.valid and snapshot.combat_loadout.W2 == "fixture-0" and game.bullets.is_empty(),"Active run reads validated loadout without combat changes")
	print("Active loadout checks: %d, failures: %d" % [checks,failures])
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
	quit(1 if failures else 0)
