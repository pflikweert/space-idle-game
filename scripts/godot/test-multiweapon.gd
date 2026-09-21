extends SceneTree

const Store := preload("res://scripts/profile_store.gd")
const Equipment := preload("res://scripts/systems/equipment_registry.gd")
const Game := preload("res://scripts/void_drifter_game.gd")

var checks := 0
var failures := 0
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: "+message)

func _initialize() -> void: call_deferred("run_tests")

func run_tests() -> void:
	root.size = Vector2i(390,844)
	var profile := Store.new()._default_profile()
	profile.equipmentItems["railgun-002"] = {"id":"railgun-002","blueprint_id":Equipment.RAILGUN_ID,"level":1}
	profile.equipmentInventory.append("railgun-002")
	profile.ships.starter_ship.loadout.W2 = "railgun-002"
	var store := Store.new(); store.profile_path = OS.get_cache_dir().path_join("void-multi-%d.json" % Time.get_ticks_usec()); store.save_profile(profile)
	var game := Game.new(); game.profile_store = store; root.add_child(game); game.set_process(false); game.profile = profile; game.metaProgress = profile; game.reset_world("menu"); game.start_run(); game.set_process(false)
	game.enemies = [{"id":101,"hp":1000.0,"max_hp":1000.0,"position":game.player.position+Vector2(0,-80),"radius":12.0,"type_id":"void_drone","velocity":Vector2.ZERO,"visual_state":"idle","hit_flash":0.0,"attack_visual_timer":0.0,"attack_warmup_timer":0.0}]
	game._update_weapons(1000.0)
	expect(game.weapon_runtime_by_item_id.size()==2 and game.bullets.size()==2,"Multiple Railgun instances fire independently")
	var sources := {}; for bullet in game.bullets: sources[str(bullet.sourceEquipmentId)] = true
	expect(sources.has(Equipment.RAILGUN_INSTANCE_ID) and sources.has("railgun-002"),"Projectiles carry source instance metadata")
	expect(game.mount_visuals.has(Equipment.RAILGUN_INSTANCE_ID) and game.mount_visuals.has("railgun-002"),"Each firing Railgun triggers its equipped mount visual")
	game._update_visual_effects(0.25)
	expect(game.mount_aim_angles.size()==2 and absf(float(game.mount_aim_angles[Equipment.RAILGUN_INSTANCE_ID])-float(game.mount_aim_angles["railgun-002"])) > 0.01,"Each Railgun turret independently turns from its own hardpoint toward the target")
	expect(game.mount_visuals.is_empty(),"Railgun mount visuals expire without persisting runtime state")
	var second_railgun: Dictionary = game.weapon_runtime_by_item_id["railgun-002"]
	var starter: Dictionary = game.weapon_runtime_by_item_id[Equipment.RAILGUN_INSTANCE_ID]
	expect(int(second_railgun.ammo)==5 and int(starter.ammo)==5,"Railgun instances use the same magazine")
	second_railgun.fire_timer = 0.0; second_railgun.reload_timer = 3.0; starter.fire_timer = 0.0; starter.reload_timer = 0.0
	game.weapon_runtime_by_item_id["railgun-002"] = second_railgun; game.weapon_runtime_by_item_id[Equipment.RAILGUN_INSTANCE_ID] = starter
	game.enemies = []
	game._update_weapons(500.0)
	expect(float(game.weapon_runtime_by_item_id["railgun-002"].reload_timer)>0.0 and int(starter.ammo)==5,"One Railgun can reload while another waits without a target")
	game.enemies = [{"id":202,"hp":1000.0,"max_hp":1000.0,"position":game.player.position+Vector2(0,-80),"radius":12.0,"type_id":"void_drone","velocity":Vector2.ZERO,"visual_state":"idle","hit_flash":0.0,"attack_visual_timer":0.0,"attack_warmup_timer":0.0}]
	game._save_run(); var snapshot: Dictionary = Store.decode(game.profile.activeRun)
	expect(snapshot.version==3 and snapshot.weapon_runtime.size()==2 and float(snapshot.weapon_runtime["railgun-002"].reload_timer)>0.0,"Paused save preserves per-Railgun reload state")
	print("Multiweapon checks: %d, failures: %d" % [checks,failures])
	quit(1 if failures else 0)
