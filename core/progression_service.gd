class_name ProgressionService
extends RefCounted

const PRESTIGE_THRESHOLD: float = 100000.0

var state: GameState
var registry: ContentRegistry
var economy: EconomyService
var events: GameEvents

func _init(s: GameState, r: ContentRegistry, e: EconomyService, bus: GameEvents) -> void:
	state = s
	registry = r
	economy = e
	events = bus

func buy_die(id: String) -> bool:
	if not registry.dice.has(id) or state.dice.size() >= GameState.MAX_DICE:
		return false
	var definition: DiceDefinition = registry.dice[id]
	if state.run_earned < definition.unlock_earned or not economy.spend(economy.die_price(id)):
		return false
	var at: Vector2 = _open_position()
	state.add_die(id, at)
	StatisticsService.increment(state, "dice_purchased")
	state.tutorial_step = maxi(state.tutorial_step, 2)
	events.purchased.emit("dice", id)
	events.changed.emit()
	return true

func _open_position() -> Vector2:
	var best := Vector2(135, 210)
	var widest: float = -1.0
	for index in 110:
		var candidate := Vector2(85 + index % 11 * 61, 170 + int(index / 11) * 34)
		var distance: float = INF
		for die in state.dice:
			distance = minf(distance, candidate.distance_squared_to(die.position))
		if distance > widest:
			widest = distance
			best = candidate
	return best

func buy_upgrade(id: String, permanent: bool = false) -> bool:
	var catalog: Dictionary = registry.talents if permanent else registry.upgrades
	var levels: Dictionary = state.talents if permanent else state.upgrades
	if not catalog.has(id):
		return false
	var definition: UpgradeDefinition = catalog[id]
	if int(levels.get(id, 0)) >= definition.max_level:
		return false
	if state.run_earned < definition.unlock_earned and not permanent:
		return false
	if not definition.prerequisite.is_empty() and int(levels.get(definition.prerequisite, 0)) == 0:
		return false
	var price: float = economy.upgrade_price(definition)
	if permanent:
		if state.prestige_points < price:
			return false
		state.prestige_points -= int(price)
	elif not economy.spend(price):
		return false
	levels[id] = int(levels.get(id, 0)) + 1
	StatisticsService.increment(state, "upgrades_purchased")
	events.purchased.emit("talent" if permanent else "upgrade", id)
	events.changed.emit()
	return true

func buy_automatic(id: String) -> bool:
	if not registry.dice.has(id) or bool(state.automatic.get(id, false)) or int(state.counts.get(id, 0)) == 0:
		return false
	if not economy.spend(registry.dice[id].auto_cost):
		return false
	state.automatic[id] = true
	events.purchased.emit("automatic", id)
	events.changed.emit()
	return true

func helper_price() -> float:
	return 250.0 * pow(2.8, state.helpers)

func hire_helper() -> bool:
	if state.helpers >= 8 or state.run_earned < 150 or not economy.spend(helper_price()):
		return false
	state.helpers += 1
	StatisticsService.increment(state, "helpers_hired")
	events.purchased.emit("helper", "croupier")
	events.changed.emit()
	return true

func fate_reward() -> int:
	return int(minf(1000000000 - state.prestige_total, floor(sqrt(state.run_earned / PRESTIGE_THRESHOLD))))

func prestige() -> bool:
	var reward: int = fate_reward()
	if reward < 1 or not registry.dice.has("d6"):
		return false
	state.prestige_points += reward
	state.prestige_total += reward
	state.money = 0
	state.run_earned = 0
	state.dice.clear()
	state.counts.clear()
	state.upgrades.clear()
	state.automatic.clear()
	state.helpers = 0
	state.tutorial_step = 2
	state.add_die("d6", Vector2(395, 310))
	StatisticsService.increment(state, "prestiges")
	events.prestige_completed.emit()
	events.changed.emit()
	return true
