extends SceneTree
## Pacing probe: a steady, greedy player in one run (no talents). It clicks one ready die every
## 0.35 s (about 3 clicks a second), rolls the table whenever its cooldown allows, helpers throw
## on their own, and it always buys the cheapest thing it can afford among
## dice (up to 6 of each), upgrades and helpers. Prints when it reaches the first Fate threshold,
## when every upgrade is maxed, and what it owns at checkpoints. A balancing aid, not a claim
## about human play. Run: GODOT --headless --path . --script res://tools/pacing_probe.gd

const STEP: float = 0.1
const LIMIT_SECONDS: float = 3.0 * 3600.0
const CHECKPOINTS: Array[float] = [120.0, 300.0, 600.0, 1200.0, 1800.0, 3600.0, 7200.0]

func _initialize() -> void:
	var catalog := ContentRegistry.new()
	var session := GameSession.new(catalog)
	session.roller.rng.seed = 38
	var throw_clock: float = 0.0
	var first_fate: float = -1.0
	var all_upgrades: float = -1.0
	var next_checkpoint: int = 0
	var seconds: float = 0.0
	while seconds < LIMIT_SECONDS:
		seconds += STEP
		session.tick(STEP)
		throw_clock += STEP
		if session.state.table_roll_remaining <= 0.0:
			session.roll_table()
		if throw_clock >= 0.35:
			throw_clock = 0.0
			_click_one(session)
		_buy_cheapest(session, catalog)
		if first_fate < 0.0 and session.state.run_earned >= session.progression.prestige_threshold():
			first_fate = seconds
		if all_upgrades < 0.0 and _upgrades_maxed(session, catalog):
			all_upgrades = seconds
		if next_checkpoint < CHECKPOINTS.size() and seconds >= CHECKPOINTS[next_checkpoint]:
			print("  t=%5.0fs  earned=$%s  dice=%d  helpers=%d  upgrade levels=%d/%d" % [seconds, NumberFormat.compact(session.state.run_earned), session.state.dice.size(), session.state.helpers, _levels(session), _max_levels(catalog)])
			next_checkpoint += 1
		if first_fate >= 0.0 and all_upgrades >= 0.0 and next_checkpoint >= CHECKPOINTS.size():
			break
	print("PACING: first Fate threshold at %s; every upgrade maxed at %s" % [_time(first_fate), _time(all_upgrades)])
	quit()

var click_cursor: int = 0

## One click: the next die in turn that is ready to roll.
func _click_one(session: GameSession) -> void:
	var count: int = session.state.dice.size()
	for attempt in count:
		var die: DiceInstance = session.state.dice[(click_cursor + attempt) % count]
		if not die.busy and die.cooldown <= 0.0:
			click_cursor = (click_cursor + attempt + 1) % count
			session.request_roll([die.id])
			return

func _buy_cheapest(session: GameSession, catalog: ContentRegistry) -> void:
	var best_price: float = INF
	var best: Callable
	for id in ["d4", "d6", "d8", "d10", "d12", "d20"]:
		if int(session.state.counts.get(id, 0)) < 6 and session.state.run_earned >= catalog.dice[id].unlock_earned:
			var price: float = session.economy.die_price(id)
			if price < best_price:
				best_price = price
				best = func(): session.progression.buy_die(id)
	for id in catalog.upgrades:
		var definition: UpgradeDefinition = catalog.upgrades[id]
		if int(session.state.upgrades.get(id, 0)) < definition.max_level and session.state.run_earned >= definition.unlock_earned:
			var price: float = session.economy.upgrade_price(definition)
			if price < best_price:
				best_price = price
				best = func(): session.progression.buy_upgrade(id)
	if session.state.helpers < GameState.MAX_HELPERS and session.state.run_earned >= 150.0:
		var price: float = session.progression.helper_price()
		if price < best_price:
			best_price = price
			best = func(): session.progression.hire_helper()
	if best.is_valid() and session.state.money >= best_price:
		best.call()

func _levels(session: GameSession) -> int:
	var total: int = 0
	for id in session.state.upgrades:
		total += int(session.state.upgrades[id])
	return total

func _max_levels(catalog: ContentRegistry) -> int:
	var total: int = 0
	for id in catalog.upgrades:
		total += catalog.upgrades[id].max_level
	return total

func _upgrades_maxed(session: GameSession, catalog: ContentRegistry) -> bool:
	return _levels(session) >= _max_levels(catalog)

func _time(seconds: float) -> String:
	return "never (over %d min)" % int(LIMIT_SECONDS / 60.0) if seconds < 0.0 else "%.1f min" % (seconds / 60.0)
