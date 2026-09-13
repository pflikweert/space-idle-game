extends SceneTree

const Store = preload("res://scripts/profile_store.gd")
const Upgrades = preload("res://scripts/systems/upgrade_registry.gd")
const Game = preload("res://scripts/void_drifter_game.gd")
const Cards = preload("res://scripts/systems/railgun_cards.gd")
class SimulationGame extends Game:
	var cards_enabled := true
	func _handle_card_progress() -> void:
		if cards_enabled: super._handle_card_progress()


class MemoryStore extends Store:
	func load_profile() -> Dictionary:
		return _default_profile()
	func save_profile(_profile: Dictionary) -> bool:
		return true

func _initialize() -> void:
	call_deferred("simulate")

func simulate() -> void:
	root.size = Vector2i(430, 760)
	var game = SimulationGame.new()
	game.cards_enabled = not OS.get_cmdline_user_args().has("--without-cards")
	game.profile_store = MemoryStore.new()
	root.add_child(game)
	game.set_process(false)
	var results := []
	var quick := OS.get_cmdline_user_args().has("--quick")
	var scenarios := ["no_purchases", "cash_only", "developed"] if quick else ["no_purchases", "cash_only", "developed", "strong"]
	if OS.get_cmdline_user_args().has("--no-purchases"): scenarios = ["no_purchases"]
	if OS.get_cmdline_user_args().has("--first-workshop"): scenarios = ["first_workshop"]
	var seeds := [11, 37, 91] if quick else [11, 37, 91, 17, 53, 73, 101, 137, 173, 211]
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--scenario="):
			scenarios = [argument.trim_prefix("--scenario=")]
		if argument.begins_with("--seed="):
			seeds = [int(argument.trim_prefix("--seed="))]
	for scenario in scenarios:
		for seed_value in seeds:
			game.profile = game.profile_store._default_profile()
			game.metaProgress = game.profile
			if scenario in ["developed", "first_workshop"]:
				for id in Upgrades.defaults():
					game.profile.permanentUpgrades[id] = mini(10 if scenario == "first_workshop" else 30, int(Upgrades.definition(id).cap))
			elif scenario == "strong":
				game.profile.permanentUpgrades = {"range": 30, "damage": 100, "fire_rate": 38, "crit_chance": 50, "max_hp": 100, "regen": 40, "armor": 30, "cash_bonus": 20, "cash_wave": 20, "coin_bonus": 20}
				game.profile.autoDodgeUnlocked = true
			game.profile.settings.autoCards = true
			game.start_run()
			game.cards = Cards.fresh(seed_value)
			game.rng.seed = seed_value
			# Include shared fleet handedness in the deterministic fixture.
			game.runState.fleetOrbitSign = -1.0 if seed_value % 2 == 0 else 1.0
			var first_card := -1.0
			var first_epic := -1.0
			var first_module := -1.0
			var next_shop := 120.0
			var max_enemies := 0
			var early_visible: Array[int] = []
			var hidden_enemy_seconds := 0.0
			var next_sample := 1.0
			var limit := 7200.0 if scenario == "strong" else 5400.0
			while game.status == "running" and float(game.runState.elapsedSeconds) < limit:
				game._update_world(1.0 / 30.0)
				if first_card < 0 and game.cards.choices > 0: first_card = game.runState.elapsedSeconds
				if first_epic < 0 and Cards.epic_count(game.cards) > 0: first_epic = game.runState.elapsedSeconds
				if first_module < 0 and game.cards.modules > 0: first_module = game.runState.elapsedSeconds
				max_enemies = maxi(max_enemies, game.enemies.size())
				if float(game.runState.elapsedSeconds) >= next_sample:
					next_sample += 1.0
					var visible := 0
					for enemy in game.enemies:
						if game._enemy_is_visible(enemy): visible += 1
					hidden_enemy_seconds += game.enemies.size() - visible
					if game.runState.wave <= 5 and game.runState.phase == "spawning" and fmod(float(game.runState.elapsedSeconds), 35.0) >= 5.0:
						early_visible.append(visible)
				if scenario != "no_purchases" and game.status == "running" and float(game.runState.elapsedSeconds) >= next_shop:
					next_shop += 120.0
					# A reproducible player policy, not an automatic buying feature.
					game._on_panel_action("shop")
					for purchase in range(500):
						var chosen := ""
						var cheapest := INF
						for id in ["damage", "fire_rate", "crit_chance", "range", "max_hp", "regen", "armor", "shield_capacity", "shield_recharge", "cash_bonus", "cash_wave"]:
							var level := Upgrades.level(id, game.profile.permanentUpgrades, game.run_upgrades)
							if id in ["cash_bonus", "cash_wave"] and (level >= 20 or float(game.runState.elapsedSeconds) > 1800):
								continue
							var quote := Upgrades.quote(id, game.profile.permanentUpgrades, game.run_upgrades, float(game.runState.cash), 1, false)
							if int(quote.count) > 0 and float(quote.cost) < cheapest:
								chosen = id
								cheapest = float(quote.cost)
						if chosen == "":
							break
						game._buy_upgrade(chosen, 1)
					game._on_panel_action("resume")
				if int(float(game.runState.elapsedSeconds) * 30) % 3000 == 0:
					await process_frame
			early_visible.sort()
			var result := {"cards_enabled":game.cards_enabled,"cards":game.cards.choices,"epics":Cards.epic_count(game.cards),"modules":game.cards.modules,"first_card_seconds":first_card,"first_epic_seconds":first_epic,"first_module_seconds":first_module,"early_visible_median": early_visible[early_visible.size() / 2] if not early_visible.is_empty() else 0, "hidden_enemy_seconds": hidden_enemy_seconds, "scenario": scenario, "seed": seed_value, "minutes": snappedf(float(game.runState.elapsedSeconds) / 60.0, 0.01), "wave": game.runState.wave, "status": game.status, "max_enemies": max_enemies, "coins": floor(float(game.runState.coinsEarned))}
			results.append(result)
			print(JSON.stringify(result))
	for scenario in scenarios:
		var waves := []
		var minutes := []
		var in_band := 0
		for result in results:
			if result.scenario != scenario: continue
			waves.append(result.wave)
			minutes.append(result.minutes)
			if result.status == "dead" and result.wave >= 12 and result.wave <= 18: in_band += 1
		waves.sort()
		minutes.sort()
		print("SUMMARY " + JSON.stringify({"scenario": scenario, "wave_min": waves.front(), "wave_median": (waves[(waves.size() - 1) / 2] + waves[waves.size() / 2]) / 2.0, "wave_max": waves.back(), "minutes_min": minutes.front(), "minutes_median": (minutes[(minutes.size() - 1) / 2] + minutes[minutes.size() / 2]) / 2.0, "minutes_max": minutes.back(), "deaths_12_to_18": in_band}))
	game.queue_free()
	await process_frame
	quit()
