extends SceneTree

var failed: int = 0
var passed: int = 0
var registry: ContentRegistry

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + message)

func fresh() -> GameSession:
	return GameSession.new(registry)

func run() -> void:
	registry = ContentRegistry.new()
	check(registry.errors.is_empty() and registry.dice.size() == 10, "All dice content validates")
	check(registry.upgrades.size() == 7 and registry.talents.size() == 4, "Upgrades and talents load")
	var definition: DiceDefinition = registry.dice.d6
	var invalid := DiceDefinition.new()
	invalid.id = "invalid"
	invalid.base_cost = -1
	check(not invalid.valid(), "Negative price content rejected")
	invalid.base_cost = 1
	invalid.weights = PackedFloat64Array([0,0,0,0,0,0])
	check(not invalid.valid(), "Zero-weight distribution rejected")
	var rng_a := RollSystem.new(1234)
	var rng_b := RollSystem.new(1234)
	var identical: bool = true
	var in_range: bool = true
	for index in 10000:
		var value: int = rng_a.sample(definition)
		identical = identical and value == rng_b.sample(definition)
		in_range = in_range and value >= 1 and value <= 6
	check(identical and in_range, "Seeded samples repeat and remain in range")
	var histogram: Array = rng_a.simulate_rolls(definition, 100000).histogram
	for value in histogram:
		check(absf(float(value) / 100000.0 - 1.0 / 6.0) < 0.007, "Fair D6 distribution")
	var loaded: Array = rng_a.simulate_rolls(registry.dice.lucky_d6, 100000).histogram
	check(absf(float(loaded[4] + loaded[5]) / 100000.0 - 0.6) < 0.008, "Lucky die weighted distribution")

	var game: GameSession = fresh()
	check(game.state.dice.size() == 1 and game.state.money == 0, "New run starts with one die")
	var initial_cost: float = definition.base_cost
	game.state.money = 19
	check(not game.progression.buy_die("d6") and game.state.money == 19, "Unaffordable purchase leaves state intact")
	game.state.money = 20
	check(game.progression.buy_die("d6") and game.state.money == 0, "Exact-cost purchase succeeds")
	check(definition.base_cost == initial_cost and game.state.counts.d6 == 2, "Purchases never mutate definitions")
	check(not game.economy.spend(-1) and not game.economy.spend(INF) and game.state.money == 0, "Invalid transactions rejected")
	game = fresh()
	game.forced_face = 6
	game.state.upgrades.heavy = 1
	check(game.request_roll([1]), "Manual roll can reserve a die")
	check(not game.request_roll([1]), "Busy die cannot reserve duplicate roll")
	check(game.state.money == 0, "Payout waits for landing")
	var rid: int = int(game.pending.keys()[0])
	game.finish_roll(rid)
	check(is_equal_approx(game.state.money, 7.5), "Fractional modifier applies exactly once")
	check(not game.finish_roll(rid) and game.state.money == 7.5, "Duplicate completion cannot award twice")
	check(game.state.statistics.rolls == 1 and game.state.statistics.maximums == 1, "Statistics count one resolution")
	game.state.dice[0].cooldown = 0
	game.request_roll([1], "automatic")
	game.settle()
	check(game.state.money == 15, "Automatic and manual payout paths match")

	game = fresh()
	game.state.automatic.d6 = true
	game.tick(0.4)
	check(game.pending.is_empty(), "Auto interval not yet reached")
	game.tick(0.7)
	check(game.pending.size() == 1 and is_equal_approx(game.state.dice[0].automatic_clock, 0.1), "Timer carries fractional remainder")
	game.tick(20)
	check(game.pending.size() <= 1 and game.state.dice[0].automatic_clock <= 5, "Stall work remains bounded")

	var doubles: Dictionary = SynergyService.batch([{"face": 2}, {"face": 2}], true)
	var triple: Dictionary = SynergyService.batch([{"face": 6}, {"face": 6}, {"face": 6}], true)
	var straight: Dictionary = SynergyService.batch([{"face": 1},{"face": 2},{"face": 3},{"face": 4},{"face": 5}], true)
	check(doubles.multiplier == 2 and triple.multiplier == 5 and straight.multiplier == 8, "Combination rules")
	check(SynergyService.batch([{"face": 1}, {"face": 1}], false).multiplier == 1, "Combinations require unlock")
	game = fresh()
	game.state.money = 10000
	game.state.run_earned = 10000
	game.progression.buy_die("multiplier_d6")
	var aura_die: DiceInstance = game.state.dice[1]
	aura_die.position = game.state.dice[0].position + Vector2(30, 0)
	check(SynergyService.aura(game.state, registry, game.state.dice[0]) == 1.5, "Neighbor aura applies")
	aura_die.position += Vector2(300, 0)
	check(SynergyService.aura(game.state, registry, game.state.dice[0]) == 1.0, "Distant aura does not apply")

	game = fresh()
	game.state.dice.clear()
	game.state.add_die("exploding_d6", Vector2(300,300))
	game.forced_face = -1
	game.request_roll([game.state.dice[0].id])
	for index in 20:
		game.tick(1)
	check(game.state.statistics.rolls == 5 and game.pending.is_empty(), "Explosions terminate at depth budget")
	game = fresh()
	game.state.helpers = 1
	game.tick(0.1)
	game.state.dice.clear()
	game.tick(0.1)
	check(game.pending.is_empty(), "Helper tolerates deleted target")
	game = fresh()
	game.state.helpers = 1
	for index in 300:
		game.tick(0.05)
	check(float(game.state.statistics.get("rolls", 0)) > 0, "Helper walks and resolves real rolls")
	game = fresh()
	game.state.helpers = 2
	game.forced_face = -1
	var helper_phases: Dictionary = {}
	var exclusive: bool = true
	for index in 400:
		game.tick(0.05)
		for worker in game.automation.workers:
			helper_phases[worker.phase] = true
		if game.automation.workers[0].target != 0 and game.automation.workers[0].target == game.automation.workers[1].target:
			exclusive = false
	check(exclusive, "Helpers reserve distinct targets")
	check(helper_phases.has("walk") and helper_phases.has("interact") and helper_phases.has("roll") and helper_phases.has("celebrate") and helper_phases.has("idle"), "All five helper phases are reachable")

	game = fresh()
	game.state.money = 123.75
	game.state.run_earned = 100
	game.state.upgrades.heavy = 2
	game.state.automatic.d6 = true
	game.state.settings.motion = false
	game.state.statistics.rolls = 42
	game.state.talents.fortune = 1
	game.state.prestige_points = 2
	game.state.prestige_total = 3
	game.state.dice[0].position = Vector2(200,250)
	game.state.rng_state = str(rng_a.rng.state)
	var store := SaveStore.new(registry, "user://test-progress.json")
	var encoded: String = JSON.stringify({"save_version": 1, "state": game.state.snapshot()})
	var restored: GameState = store.decode(encoded)
	check(restored != null and restored.money == 123.75 and restored.dice[0].position == Vector2(200,250), "Save preserves money and positions")
	check(restored.upgrades.heavy == 2 and restored.automatic.d6 and restored.talents.fortune == 1, "Save preserves progression")
	check(not restored.settings.motion and restored.statistics.rolls == 42 and restored.prestige_points == 2, "Save preserves settings, statistics and Fate")
	var roundtrip_rng := GameSession.new(registry, restored)
	check(roundtrip_rng.roller.rng.state == rng_a.rng.state, "Save preserves RNG state")
	check(store.decode("{broken") == null, "Malformed JSON rejected")
	var broken: Dictionary = game.state.snapshot()
	broken.dice[0].definition_id = "missing"
	check(store.decode(JSON.stringify({"save_version":1,"state":broken})) == null, "Unknown definition rejected")
	check(store.decode('{"currency": 88.5}').money == 88.5, "Legacy currency save migration")
	check(store.decode('{"save_version":999,"state":{}}') == null and store.protected, "Future version protected")

	# Use a unique test-only path; never touch the player's progress file.
	var test_path: String = "user://test-" + str(Time.get_ticks_usec()) + ".json"
	store = SaveStore.new(registry, test_path)
	check(store.write(game.state), "First safe write")
	game.state.money = 456.25
	check(store.write(game.state), "Safe replacement creates backup")
	check(store.load_state().money == 456.25, "Disk roundtrip")
	var corrupt := FileAccess.open(test_path, FileAccess.WRITE)
	corrupt.store_string("{broken")
	corrupt.close()
	var recovered: GameState = store.load_state()
	check(recovered != null and recovered.money == 123.75 and store.recovered, "Corruption recovers previous backup")
	check(store.write(recovered), "Recovered save can be promoted")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(test_path + suffix):
			DirAccess.remove_absolute(test_path + suffix)

	game = fresh()
	game.state.run_earned = ProgressionService.PRESTIGE_THRESHOLD * 4
	game.state.money = 999
	game.state.helpers = 2
	game.state.upgrades.heavy = 2
	game.state.talents.fortune = 1
	game.state.settings.sound = false
	check(game.progression.fate_reward() == 2, "Fate square-root reward")
	check(game.prestige(), "Prestige succeeds")
	check(game.state.money == 0 and game.state.helpers == 0 and game.state.upgrades.is_empty() and game.state.dice.size() == 1, "Prestige resets run-only state")
	check(game.state.prestige_points == 2 and game.state.talents.fortune == 1 and not game.state.settings.sound, "Prestige retains permanent state")
	game = fresh()
	check(not game.prestige(), "Early prestige rejected")
	check(game.offline(-100) == 0, "Backward clock earns nothing")
	game.state.automatic.d6 = true
	var offline_1: float = game.offline(14400)
	var offline_2: float = game.offline(999999)
	check(is_equal_approx(offline_1, offline_2) and offline_1 > 0, "Offline earnings capped")
	check(not NumberFormat.compact(1e100).is_empty() and NumberFormat.compact(1250) == "1.25K", "Large number formatting")
	game = fresh()
	for index in 99:
		game.state.add_die("d6", Vector2(80 + index % 9 * 65, 180 + int(index / 9) % 5 * 57))
	var ids: Array = []
	for die in game.state.dice:
		ids.append(die.id)
	game.request_roll(ids)
	game.settle()
	check(game.state.statistics.rolls == 100, "100 dice resolve without dropped or duplicate payouts")
	var malformed: Dictionary = game.state.snapshot()
	malformed.dice[0].id = 1.5
	check(GameState.restore(malformed, registry) == null, "Fractional instance IDs rejected")
	malformed = game.state.snapshot()
	malformed.rng_state = "not-a-state"
	check(GameState.restore(malformed, registry) == null, "Invalid RNG state rejected")
	var future_path: String = "user://future-test-" + str(Time.get_ticks_usec()) + ".json"
	var future_file := FileAccess.open(future_path, FileAccess.WRITE)
	future_file.store_string('{"save_version":999,"state":{}}')
	future_file.close()
	var future_store := SaveStore.new(registry, future_path)
	check(not future_store.write(game.state) and future_store.protected, "Write protects newer save even without prior load")
	check(FileAccess.get_file_as_string(future_path).contains("999"), "Future save bytes retained")
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(future_path + suffix):
			DirAccess.remove_absolute(future_path + suffix)
	game = fresh()
	game.state.run_earned = 1e100
	check(game.progression.fate_reward() == 1000000000, "Fate reward cannot overflow integer range")
	var invalid_effect := EffectDefinition.new()
	invalid_effect.max_depth = 99
	check(not invalid_effect.valid(), "Unbounded effect definition rejected")
	var started: int = Time.get_ticks_msec()
	var result: Dictionary = rng_a.simulate_rolls(definition, 1000000)
	print("SIMULATION 1,000,000 rolls: ", Time.get_ticks_msec() - started, " ms; histogram=", result.histogram)
	print("TEST RESULT: ", passed, " passed; ", failed, " failed")
	quit(1 if failed > 0 else 0)
