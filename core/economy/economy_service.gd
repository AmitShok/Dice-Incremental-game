class_name EconomyService
extends RefCounted

var state: GameState
var registry: ContentRegistry

func _init(game_state: GameState, content: ContentRegistry) -> void:
	state = game_state
	registry = content

func die_price(id: String) -> float:
	if not registry.dice.has(id):
		return INF
	var definition: DiceDefinition = registry.dice[id]
	return minf(GameState.MAX_AMOUNT, definition.base_cost * pow(definition.cost_growth, int(state.counts.get(id, 0))))

func upgrade_price(definition: UpgradeDefinition) -> float:
	var levels: Dictionary = state.talents if definition.permanent else state.upgrades
	return minf(GameState.MAX_AMOUNT, definition.cost * pow(definition.growth, int(levels.get(definition.id, 0))))

func spend(amount: float) -> bool:
	if not is_finite(amount) or amount <= 0 or amount > state.money:
		return false
	state.money -= amount
	return true

func modifier(stat: String, definition_id: String = "", face: int = 0) -> float:
	var additive: float = 0.0
	var multiplier: float = 1.0
	for upgrade in registry.all_modifiers():
		var levels: Dictionary = state.talents if upgrade.permanent else state.upgrades
		var level: int = int(levels.get(upgrade.id, 0))
		if level == 0 or upgrade.stat != stat:
			continue
		if not upgrade.target.is_empty() and upgrade.target != definition_id:
			continue
		if upgrade.condition == "six" and face != 6:
			continue
		if upgrade.condition == "maximum" and (not registry.dice.has(definition_id) or face != registry.dice[definition_id].sides):
			continue
		if upgrade.operation == "add":
			additive += upgrade.value * level
		else:
			multiplier *= pow(upgrade.value, level)
	return (1.0 + additive) * multiplier

func payout(definition: DiceDefinition, face: int, combo: float = 1.0, aura: float = 1.0) -> float:
	var base: float = (face + definition.flat_bonus) * definition.base_payout
	return minf(GameState.MAX_AMOUNT, base * modifier("payout", definition.id, face) * (1.0 + state.prestige_total * 0.1) * combo * aura)

func credit(amount: float) -> void:
	if is_finite(amount) and amount > 0:
		state.money = minf(GameState.MAX_AMOUNT, state.money + amount)
		state.run_earned = minf(GameState.MAX_AMOUNT, state.run_earned + amount)

func expected(definition: DiceDefinition, weights: PackedFloat64Array) -> float:
	var total: float = 0.0
	var value: float = 0.0
	for index in weights.size():
		total += weights[index]
		value += weights[index] * payout(definition, index + 1)
	return value / total if total > 0 else 0.0
