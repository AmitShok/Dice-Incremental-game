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

## A session with exactly the given dice, in order, at the given positions.
func table_of(ids: Array, positions: Array) -> GameSession:
	var game: GameSession = fresh()
	game.state.dice.clear()
	game.state.counts.clear()
	for index in ids.size():
		game.state.add_die(ids[index], positions[index])
	return game

func _new_mechanics_checks() -> void:
	# Legacy auto-roll purchases become a cash refund; nothing auto-rolls any more.
	var legacy := GameState.new()
	legacy.add_die("d6", Vector2(300, 300))
	legacy.automatic = {"d6": true, "d4": true}
	var migrated := GameSession.new(registry, legacy)
	check(migrated.state.automatic.is_empty() and migrated.migration_refund == 1450.0 and migrated.state.money == 1450.0, "Legacy auto-roll is refunded")
	for index in 40:
		migrated.tick(0.1)
	check(migrated.pending.is_empty() and float(migrated.state.statistics.get("rolls", 0)) == 0, "Nothing rolls without helpers")

	# Selling returns half of the latest copy's price and lowers the next price.
	var game: GameSession = fresh()
	game.state.money = 100
	game.state.run_earned = 100
	game.progression.buy_die("d6")
	game.progression.buy_die("d6")
	var earned_before: float = game.state.run_earned
	check(is_equal_approx(game.sell_value(game.state.dice[2].id), 20.0), "Sell value is half the latest price")
	check(is_equal_approx(game.sell_die(game.state.dice[2].id), 20.0) and game.state.counts.d6 == 2 and game.state.dice.size() == 2, "Selling removes the die")
	check(is_equal_approx(game.economy.die_price("d6"), 40.0) and game.state.run_earned == earned_before, "Selling lowers the next price and is not earnings")
	game.request_roll([game.state.dice[0].id])
	check(game.sell_die(game.state.dice[0].id) == 0.0, "Rolling dice cannot be sold")
	game.settle()
	game.sell_die(game.state.dice[0].id)
	check(game.sell_die(game.state.dice[0].id) == 0.0 and game.state.dice.size() == 1, "The last die cannot be sold")
	var restored: GameState = GameState.restore(game.state.snapshot(), registry)
	check(restored != null and restored.counts.d6 == 1, "Save after selling restores counts")

	# Hot streak: manual clicks raise the multiplier, idling resets it.
	game = fresh()
	game.forced_face = 3
	for index in 10:
		game.state.dice[0].cooldown = 0
		game.request_roll([game.state.dice[0].id])
		game.settle()
	check(game.streak == 10 and is_equal_approx(game.streak_multiplier(), 1.25), "Ten quick clicks reach the warm stage")
	var before: float = game.state.money
	game.state.dice[0].cooldown = 0
	game.request_roll([game.state.dice[0].id])
	game.settle()
	check(is_equal_approx(game.state.money - before, 3.75), "Streak multiplies payouts")
	game.tick(GameSession.STREAK_WINDOW + 0.1)
	check(game.streak == 0, "Streak cools after the window")
	game.state.upgrades.momentum = 2
	check(is_equal_approx(game.streak_window(), GameSession.STREAK_WINDOW * 2.0), "Momentum lengthens the window")

	# Spark arcs to the two nearest ready dice with a charged bonus.
	game = table_of(["spark_d8", "d6", "d6", "d6"], [Vector2(300, 300), Vector2(340, 300), Vector2(260, 300), Vector2(700, 480)])
	game.forced_face = 8
	game.request_roll([game.state.dice[0].id], "chain")
	game.tick(1.0)
	var charged: int = 0
	for outcome in game.pending.values():
		if outcome.charged:
			charged += 1
	check(charged == 2 and not game.state.dice[3].busy, "Spark arcs to the two nearest dice only")
	game.settle()
	check(game.state.statistics.arcs == 2, "Arcs are counted")

	# Blast throws all nearby ready dice as one combination-eligible batch.
	game = table_of(["blast_d10", "d6", "d6", "d6"], [Vector2(300, 300), Vector2(340, 300), Vector2(260, 300), Vector2(300, 340)])
	game.state.upgrades.combos = 1
	game.forced_face = 10
	var combos: Array = []
	game.events.combo_triggered.connect(func(label, multiplier): combos.append(label))
	game.request_roll([game.state.dice[0].id], "chain")
	game.tick(1.0)
	check(game.pending.size() == 3 and combos.size() == 1, "Blast rolls neighbors together and combos count")
	game.settle()

	# Gild marks nearby dice; their next roll pays triple once (5x on the Gilded table).
	game = table_of(["gild_d12", "d6", "d6"], [Vector2(300, 300), Vector2(330, 300), Vector2(700, 480)])
	game.forced_face = 12
	game.request_roll([game.state.dice[0].id], "chain")
	game.tick(1.1)
	check(game.state.dice[1].gilded and not game.state.dice[2].gilded, "Gild marks only nearby dice")
	check(GameState.restore(game.state.snapshot(), registry).dice[1].gilded, "Gilded state saves")
	game.forced_face = 2
	before = game.state.money
	game.state.dice[1].cooldown = 0
	game.request_roll([game.state.dice[1].id], "chain")
	game.settle()
	check(is_equal_approx(game.state.money - before, 6.0) and not game.state.dice[1].gilded, "Gilded roll pays triple once")

	# Natural ones drop chips; capsules turn chips into hats.
	game = fresh()
	game.forced_face = 1
	game.request_roll([game.state.dice[0].id], "chain")
	game.settle()
	check(game.state.chips == 1, "A natural one drops a chip")
	check(game.progression.pull_capsule() == "", "Capsule needs enough chips")
	game.state.chips = 1000
	var first_hat: String = game.progression.pull_capsule()
	check(Cosmetics.HATS.has(first_hat) and game.state.hats.has(first_hat) and game.state.crew_hat == first_hat, "First capsule hat is worn")
	for index in 30:
		game.progression.pull_capsule()
	check(game.state.hats.size() > 1 and game.state.chips > 1000 - 31 * Cosmetics.CAPSULE_COST, "Duplicate hats refund chips")
	check(game.progression.wear_hat("mix") and Cosmetics.hat_for(game.state, 1) == game.state.hats[1], "Mixed hats rotate across helpers")
	check(not game.progression.wear_hat("not-a-hat"), "Unknown hats are rejected")

	# Tables unlock from lifetime progress, survive Fate and change rules.
	game = fresh()
	check(not game.select_table("velvet"), "Locked table cannot be chosen")
	game.state.statistics["combos"] = 25.0
	game.forced_face = 3
	game.request_roll([game.state.dice[0].id], "chain")
	game.settle()
	check(game.state.tables.has("velvet") and game.select_table("velvet"), "Velvet unlocks after 25 combinations")
	check(is_equal_approx(game.streak_window(), GameSession.STREAK_WINDOW * 0.5), "Velvet shortens streaks")
	game.state.tables.append("starlit")
	game.select_table("starlit")
	game.forced_face = 1
	game.state.dice[0].cooldown = 0
	before = game.state.money
	var chips_before: int = game.state.chips
	game.request_roll([game.state.dice[0].id], "chain")
	game.settle()
	check(game.state.money == before and game.state.chips == chips_before + 2, "Starlit ones pay nothing but drop two chips")
	game.state.run_earned = ProgressionService.PRESTIGE_THRESHOLD
	game.prestige()
	check(game.state.table_id == "starlit" and game.state.tables.has("velvet") and game.state.chips == chips_before + 2, "Tables and chips survive Fate")
	restored = GameState.restore(game.state.snapshot(), registry)
	check(restored.table_id == "starlit" and restored.tables.size() == 3, "Tables save")
	var tampered: Dictionary = game.state.snapshot()
	tampered.table_id = "gilded"
	check(GameState.restore(tampered, registry).table_id == "felt", "Unowned saved table falls back to felt")

	# Smarter helpers pick the most valuable die; many hands throw several together.
	game = table_of(["d4", "d20", "d6"], [Vector2(150, 300), Vector2(600, 300), Vector2(300, 300)])
	game.state.helpers = 1
	game.state.upgrades.sharp_eyes = 1
	game.automation.sync(1)
	check(game.automation._choose(game, 0) == game.state.dice[1], "Sharp eyes choose the most valuable die")
	game = table_of(["d6", "d6", "d6", "d6"], [Vector2(300, 300), Vector2(330, 300), Vector2(300, 330), Vector2(700, 480)])
	game.state.helpers = 1
	game.state.upgrades.many_hands = 2
	var batch_sizes: Array = []
	game.events.die_roll_started.connect(func(outcome): if outcome.source == "helper": batch_sizes.append(outcome.die_id))
	for index in 200:
		game.tick(0.05)
		if not batch_sizes.is_empty():
			break
	check(batch_sizes.size() == 3, "Many hands throws three nearby dice together")
	game = fresh()
	game.state.helpers = 1
	var plain_income: float = game.automation.expected_income(game)
	game.state.upgrades.strong_arms = 1
	check(plain_income > 0 and is_equal_approx(game.automation.expected_income(game), plain_income * 1.5), "Strong arms raise helper income")
	game.state.helpers = 0
	check(game.automation.expected_income(game) == 0.0, "No helpers means no idle income")

func _talent_tree_checks() -> void:
	# Unspent Fate is +1% income each; spending it lowers the bonus. Lifetime Fate gives nothing.
	var game: GameSession = fresh()
	var plain: float = game.economy.payout(registry.dice.d6, 6)
	game.state.prestige_total = 500
	check(is_equal_approx(game.economy.payout(registry.dice.d6, 6), plain), "Lifetime Fate alone no longer raises payouts")
	game.state.prestige_points = 50
	check(is_equal_approx(game.economy.payout(registry.dice.d6, 6), plain * 1.5), "Each held Fate adds 1% income")
	check(game.progression.buy_upgrade("fortune", true) and game.state.prestige_points == 49, "Buying a talent spends held Fate")
	check(is_equal_approx(game.economy.payout(registry.dice.d6, 6), plain * 1.49 * 1.2), "Spending Fate lowers the held bonus")

	# Every talent has its own cell and an existing prerequisite.
	var cells: Dictionary = {}
	var layout_ok: bool = true
	for id in registry.talents:
		var definition: UpgradeDefinition = registry.talents[id]
		layout_ok = layout_ok and not cells.has(definition.tree_position) and (definition.prerequisite.is_empty() or registry.talents.has(definition.prerequisite))
		layout_ok = layout_ok and (not definition.target.is_empty() or ShopIcons.icon(definition.icon if not definition.icon.is_empty() else id) != null)
		cells[definition.tree_position] = id
	check(layout_ok, "Talents have unique cells, real prerequisites and icons")
	# The talent tree scene holds a real TalentNode for every talent (rebuild it with
	# tools/build_talent_tree_scene.gd after adding talents).
	var tree_scene: Node = load("res://scenes/ui/talent_tree.tscn").instantiate()
	var links: Node = tree_scene.get_node("Column/Map/Links")
	var scene_ok: bool = true
	for id in registry.talents:
		var placed: Node = links.get_node_or_null(id)
		scene_ok = scene_ok and placed is TalentNode and placed.prerequisite == registry.talents[id].prerequisite
	check(scene_ok, "talent_tree.tscn has a node for every talent with its prerequisite")
	tree_scene.free()

	# Old saves (no fate_version) get every spent Fate back once.
	var old: Dictionary = fresh().state.snapshot()
	old.erase("fate_version")
	old.talents = {"fortune": 3, "crit": 1}
	old.prestige_points = 4
	var restored: GameState = GameState.restore(old, registry)
	var migrated := GameSession.new(registry, restored)
	check(migrated.talent_refund == 9 and migrated.state.prestige_points == 13 and migrated.state.talents.is_empty(), "Old talent trees are refunded")
	var again := GameSession.new(registry, GameState.restore(migrated.state.snapshot(), registry))
	check(again.talent_refund == 0 and again.state.prestige_points == 13, "The talent refund happens only once")

	# Critical talents: chance and power.
	var crits: GameSession = fresh()
	check(crits.economy.crit_chance() == 0.0, "No criticals without the Critical talent")
	crits.state.talents.merge({"crit": 1, "crit_chance": 4, "crit_power": 2})
	check(is_equal_approx(crits.economy.crit_chance(), 0.3) and is_equal_approx(crits.economy.crit_multiplier(), 5.0), "Keen eye and Heavy hitter improve criticals")

	# Discounts, streak power, combo power, chips, hoarding and offline rate.
	var shop: GameSession = fresh()
	var die_price: float = shop.economy.die_price("d6")
	var upgrade_price: float = shop.economy.upgrade_price(registry.upgrades.heavy)
	shop.state.talents.merge({"bargain": 2, "haggler": 1})
	check(is_equal_approx(shop.economy.die_price("d6"), die_price * 0.81) and is_equal_approx(shop.economy.upgrade_price(registry.upgrades.heavy), upgrade_price * 0.9), "Bargain hunter and Haggler discount the shop")
	var streaky: GameSession = fresh()
	streaky.streak = 50
	streaky.state.talents.fire_within = 4
	check(is_equal_approx(streaky.streak_multiplier(), 3.0), "Fire within makes BLAZING ×3")
	var hoard: GameSession = fresh()
	var base_pay: float = hoard.economy.payout(registry.dice.d6, 6)
	hoard.state.chips = 5000
	hoard.state.hats = ["cap", "flower"]
	hoard.state.talents.merge({"chip_hoard": 1, "hat_trick": 1})
	check(is_equal_approx(hoard.economy.payout(registry.dice.d6, 6), base_pay * 1.5 * 1.06), "Chip hoard caps at 1,000 chips and Hat trick counts hats")
	var chips: GameSession = table_of(["d6"], [Vector2(300, 300)])
	chips.state.talents.chip_collector = 2
	chips.forced_face = 1
	chips.request_roll([chips.state.dice[0].id])
	chips.settle()
	check(chips.state.chips == 3, "Chip collector adds chips per 1 rolled")
	var divine: GameSession = table_of(["d6"], [Vector2(300, 300)])
	divine.state.talents.divine = 3
	var ones: int = 0
	for attempt in 3000:
		divine.state.dice[0].cooldown = 0
		divine.request_roll([divine.state.dice[0].id])
		divine.settle()
		ones += 1 if divine.state.dice[0].face == 1 else 0
	# A fair D6 lands 1 about 500 times in 3000; with 30% rescued it is about 350.
	check(ones < 420, "Divine intervention turns some 1s into maximums")

func _dice_size_checks() -> void:
	# Dice keep full size until 40, then shrink gently to 70% at the 100-die cap, never below.
	check(DiceVisual.size_for(1) == 1.0 and DiceVisual.size_for(40) == 1.0, "Dice stay full size up to 40")
	check(DiceVisual.size_for(70) < 1.0 and DiceVisual.size_for(70) > 0.7, "Dice shrink gradually past 40")
	check(is_equal_approx(DiceVisual.size_for(100), 0.7) and is_equal_approx(DiceVisual.size_for(150), 0.7), "Dice never get smaller than 70%")
	var steady: bool = true
	for count in range(40, 101):
		steady = steady and DiceVisual.size_for(count + 1) <= DiceVisual.size_for(count) and DiceVisual.size_for(count) - DiceVisual.size_for(count + 1) <= 0.051
	check(steady, "Each extra die shrinks the table by at most one 5% step")

func _web_save_checks() -> void:
	# The newer of two saves wins (file vs the Web localStorage mirror); either may be missing.
	var older := GameState.new()
	older.last_saved = 100.0
	older.money = 1.0
	var newer := GameState.new()
	newer.last_saved = 200.0
	newer.money = 2.0
	check(SaveStore.newest(older, newer) == newer and SaveStore.newest(newer, older) == newer, "Newest save wins")
	check(SaveStore.newest(null, older) == older and SaveStore.newest(older, null) == older and SaveStore.newest(null, null) == null, "A missing copy falls back to the other")
	# A successful write records the exact JSON, which decodes back to the same progress.
	var path: String = "user://web_mirror_test.json"
	var store := SaveStore.new(registry, path)
	var game: GameSession = fresh()
	game.state.money = 4321.0
	check(store.write(game.state) and not store.last_serialized.is_empty(), "Write records the saved JSON")
	var mirrored: GameState = store.decode(store.last_serialized)
	check(mirrored != null and mirrored.money == 4321.0 and is_equal_approx(mirrored.last_saved, game.state.last_saved), "Mirrored JSON restores the same progress")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))

func _fate_endgame_checks() -> void:
	var game: GameSession = fresh()
	game.state.run_earned = ProgressionService.PRESTIGE_THRESHOLD - 1
	check(game.progression.fate_reward() == 0, "No Fate below the threshold")
	game.state.run_earned = ProgressionService.PRESTIGE_THRESHOLD
	check(game.progression.fate_reward() == 2, "Threshold grants two Fate")
	var next_at: float = game.progression.next_fate_at()
	game.state.run_earned = next_at
	check(next_at > ProgressionService.PRESTIGE_THRESHOLD and game.progression.fate_reward() == 3, "Next-Fate target grants exactly one more")
	game.state.run_earned = ProgressionService.PRESTIGE_THRESHOLD * 16
	game.state.talents.house_edge = 2
	check(game.progression.fate_reward() == 12, "House edge multiplies Fate")
	game.state.run_earned = game.progression.next_fate_at()
	check(game.progression.fate_reward() == 13, "Next-Fate target accounts for House edge")

	game = fresh()
	game.state.run_earned = ProgressionService.PRESTIGE_THRESHOLD
	game.state.talents.merge({"fortune": 1, "head_start": 2, "heirloom": 2, "stride": 1, "old_friend": 1, "muscle_memory": 1})
	game.state.helpers = 5
	check(game.progression.carryover_summary().contains("$5.00K") and game.progression.carryover_summary().contains("5 of your helpers"), "Confirmation lists talent carry-over")
	check(game.prestige(), "Talented prestige succeeds")
	check(game.state.money == 5000.0 and game.state.run_earned == 0, "Head start grants unearned starting cash")
	check(game.state.dice.size() == 3 and game.state.counts.d6 == 3, "Heirloom dice add starter D6s")
	var spread: bool = game.state.dice[0].position.distance_to(game.state.dice[1].position) > 30 and game.state.dice[1].position.distance_to(game.state.dice[2].position) > 30
	check(spread, "Heirloom dice do not overlap")
	check(game.state.helpers == 5, "Loyal crew keeps every hired helper")
	var restored: GameState = GameState.restore(game.state.snapshot(), registry)
	check(restored != null and restored.talents.muscle_memory == 1 and restored.talents.heirloom == 2, "New talents survive save round trip")
	game = fresh()
	game.state.run_earned = ProgressionService.PRESTIGE_THRESHOLD
	game.state.helpers = 5
	game.state.talents.merge({"fortune": 1, "stride": 1, "old_friend": 1})
	game.prestige()
	check(game.state.helpers == 1, "Old friends rehire one helper without Loyal crew")

	game = fresh()
	check(is_equal_approx(game.table_cooldown(), 60.0), "Base table cooldown")
	game.state.talents.merge({"fortune": 1, "patience": 2})
	check(game.roll_table() and is_equal_approx(game.state.table_roll_remaining, 33.75), "Patient table shortens cooldown")
	check(GameState.restore(game.state.snapshot(), registry) != null, "Shortened cooldown saves")

	var short_night: GameSession = fresh()
	var long_night: GameSession = fresh()
	short_night.state.helpers = 1
	long_night.state.helpers = 1
	long_night.state.talents.merge({"fortune": 1, "long_nights": 1})
	var short_amount: float = short_night.offline(28800)
	var long_amount: float = long_night.offline(28800)
	# Fortune's +20% payout also applies, so a doubled window yields 2.4×.
	check(is_equal_approx(long_amount, short_amount * 2.4), "Long nights doubles offline window")

func run() -> void:
	registry = ContentRegistry.new()
	check(registry.errors.is_empty() and registry.dice.size() == 13, "All dice content validates")
	check(registry.upgrades.size() == 11 and registry.talents.size() == 39, "Upgrades and talents load")
	var definition: DiceDefinition = registry.dice.d6
	var invalid := DiceDefinition.new()
	invalid.id = "invalid"
	invalid.base_cost = -1
	check(not invalid.valid(), "Negative price content rejected")
	invalid.base_cost = 1
	invalid.weights = PackedFloat32Array([0,0,0,0,0,0])
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
	check(registry.dice.lucky_d6.weights == PackedFloat32Array([1,1,1,1,3,3]), "Lucky weights survive resource packaging")
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
	game.request_roll([1], "helper")
	game.settle()
	check(game.state.money == 15, "Helper and manual payout paths match")

	for id in ["d4", "d6", "d8", "d10", "d12", "d20"]:
		for source in ["manual", "helper", "chain"]:
			var face_matches: bool = true
			var plain_game: GameSession = fresh()
			plain_game.state.dice.clear()
			plain_game.state.counts.clear()
			var plain_die: DiceInstance = plain_game.state.add_die(id, Vector2(300,300))
			for face in range(1, registry.dice[id].sides + 1):
				plain_die.cooldown = 0
				plain_game.forced_face = face
				plain_game.streak = 0
				var previous_money: float = plain_game.state.money
				plain_game.request_roll([plain_die.id], source)
				plain_game.settle()
				face_matches = face_matches and plain_die.face == face and is_equal_approx(plain_game.state.money - previous_money, float(face))
			check(face_matches, "%s %s pays every natural face exactly without bonuses" % [id, source])

	_new_mechanics_checks()

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
	game.state.helpers = 3
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
	check(restored.upgrades.heavy == 2 and restored.helpers == 3 and restored.talents.fortune == 1, "Save preserves progression")
	check(not restored.settings.motion and restored.statistics.rolls == 42 and restored.prestige_points == 2, "Save preserves settings, statistics and Fate")
	var roundtrip_rng := GameSession.new(registry, restored)
	check(roundtrip_rng.roller.rng.state == rng_a.rng.state, "Save preserves RNG state")
	# The first broken exports autosaved an otherwise valid state with no dice.
	var empty_table: Dictionary = game.state.snapshot()
	empty_table.dice = []
	empty_table.counts = {}
	var empty_save: String = JSON.stringify({"save_version": 1, "state": empty_table})
	var repaired := GameSession.new(registry, store.decode(empty_save))
	check(repaired.state.dice.size() == 1 and repaired.state.counts.get("d6", 0) == 1, "Empty saved table receives exactly one starter die")
	check(repaired.state.money == 123.75 and repaired.state.upgrades.heavy == 2 and repaired.state.talents.fortune == 1 and repaired.state.prestige_points == 2 and repaired.state.prestige_total == 3, "Empty-table recovery preserves currency and progression")
	check(not repaired.state.settings.motion and repaired.state.statistics.rolls == 42 and repaired.state.rng_state == game.state.rng_state, "Empty-table recovery preserves settings, statistics and RNG")
	check(repaired.request_roll([repaired.state.dice[0].id]) if not repaired.state.dice.is_empty() else false, "Recovered starter can roll")
	repaired.settle()
	var repaired_again := GameSession.new(registry, store.decode(JSON.stringify({"save_version": 1, "state": repaired.state.snapshot()})))
	check(repaired_again.state.dice.size() == 1, "Saving and loading recovered table does not duplicate starter")
	check(roundtrip_rng.state.dice.size() == 1 and roundtrip_rng.state.dice[0].position == Vector2(200,250), "Normal saved table keeps existing die")
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
	check(game.progression.fate_reward() == 4, "Fate square-root reward")
	check(game.prestige(), "Prestige succeeds")
	check(game.state.money == 0 and game.state.helpers == 0 and game.state.upgrades.is_empty() and game.state.dice.size() == 1, "Prestige resets run-only state")
	check(game.state.prestige_points == 4 and game.state.talents.fortune == 1 and not game.state.settings.sound, "Prestige retains permanent state")
	_fate_endgame_checks()
	_talent_tree_checks()
	_web_save_checks()
	_dice_size_checks()
	game = fresh()
	check(not game.prestige(), "Early prestige rejected")
	check(game.offline(-100) == 0, "Backward clock earns nothing")
	game.state.helpers = 1
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
	var moving_game: GameSession = fresh()
	var still_game: GameSession = fresh()
	moving_game.roller.rng.seed = 234
	still_game.roller.rng.seed = 234
	still_game.state.settings.motion = false
	var origin: Vector2 = moving_game.state.dice[0].position
	moving_game.request_roll([1])
	still_game.request_roll([1])
	var moving_outcome: Dictionary = moving_game.pending.values()[0]
	var still_outcome: Dictionary = still_game.pending.values()[0]
	check(moving_outcome.landing_position.distance_to(origin) >= 11.9 and moving_outcome.landing_position.distance_to(origin) <= 32.1, "Roll travels a small distance")
	check(moving_game.state.dice[0].position == origin, "Position commits only on landing")
	check(moving_outcome.face == still_outcome.face and moving_outcome.payout == still_outcome.payout and moving_game.roller.rng.state == still_game.roller.rng.state, "Scatter does not consume payout RNG")
	moving_game.settle()
	still_game.settle()
	check(moving_game.state.dice[0].position == moving_outcome.landing_position and still_game.state.dice[0].position == origin, "Landing persists and reduced motion stays still")
	var moved_save: GameState = GameState.restore(moving_game.state.snapshot(), registry)
	check(moved_save != null and moved_save.dice[0].position == moving_game.state.dice[0].position, "Save retains rolled landing position")
	var bounded: bool = true
	for edge in [Vector2(65,150), Vector2(725,150), Vector2(65,500), Vector2(725,500)]:
		for attempt in 20:
			moving_game.state.dice[0].position = edge
			moving_game.state.dice[0].cooldown = 0
			moving_game.request_roll([1])
			moving_game.settle()
			var landed: Vector2 = moving_game.state.dice[0].position
			bounded = bounded and landed.x >= 65 and landed.x <= 725 and landed.y >= 150 and landed.y <= 500
	check(bounded, "Roll destinations stay on table at all four edges")
	started = Time.get_ticks_msec()
	var result: Dictionary = rng_a.simulate_rolls(definition, 1000000)
	print("SIMULATION 1,000,000 rolls: ", Time.get_ticks_msec() - started, " ms; histogram=", result.histogram)
	print("TEST RESULT: ", passed, " passed; ", failed, " failed")
	quit(1 if failed > 0 else 0)
