class_name EconomyService
extends RefCounted

var state: GameState
var registry: ContentRegistry

func _init(game_state: GameState, content: ContentRegistry) -> void:
	state = game_state
	registry = content

func die_price(id: String) -> float:
	return die_price_at(id, int(state.counts.get(id, 0)))

## Price of a die when `owned` copies of its family are already on the table.
func die_price_at(id: String, owned: int) -> float:
	if not registry.dice.has(id):
		return INF
	var definition: DiceDefinition = registry.dice[id]
	var discount: float = 0.7 if state.table_id == "gilded" and definition.behavior == "gild" else 1.0
	return minf(GameState.MAX_AMOUNT, definition.base_cost * discount * modifier("die_discount") * pow(definition.cost_growth, owned))

func upgrade_price(definition: UpgradeDefinition) -> float:
	var levels: Dictionary = state.talents if definition.permanent else state.upgrades
	var discount: float = 1.0 if definition.permanent else modifier("upgrade_discount")
	return minf(GameState.MAX_AMOUNT, definition.cost * discount * pow(definition.growth, int(levels.get(definition.id, 0))))

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

## Every Fate you hold (not spent) adds this much income. Shown on the Fate plaque and talent tree.
const FATE_HOLD_BONUS: float = 0.01

## Income multiplier from unspent Fate: +1% per Fate held. Spending Fate lowers it.
func fate_bonus() -> float:
	return 1.0 + state.prestige_points * FATE_HOLD_BONUS

## Hat trick (per hat owned) and Chip hoard (per chip held, up to 1,000) talents.
const HOARD_CHIP_CAP: int = 1000

func hoard_bonus() -> float:
	var hats: float = 1.0 + (modifier("hat_bonus") - 1.0) * state.hats.size()
	var chips: float = 1.0 + (modifier("chip_hoard") - 1.0) * mini(state.chips, HOARD_CHIP_CAP)
	return hats * chips

func payout(definition: DiceDefinition, face: int, combo: float = 1.0, aura: float = 1.0) -> float:
	var base: float = (face + definition.flat_bonus) * definition.base_payout
	return minf(GameState.MAX_AMOUNT, base * modifier("payout", definition.id, face) * fate_bonus() * hoard_bonus() * combo * aura)

func credit(amount: float) -> void:
	if is_finite(amount) and amount > 0:
		state.money = minf(GameState.MAX_AMOUNT, state.money + amount)
		state.run_earned = minf(GameState.MAX_AMOUNT, state.run_earned + amount)

## Critical rolls: the Critical talent turns them on; Keen eye and Heavy hitter improve them.
func crit_chance() -> float:
	return 0.0 if modifier("critical") <= 1.0 else minf(1.0, 0.1 + modifier("crit_chance") - 1.0)

func crit_multiplier() -> float:
	return 2.0 + modifier("crit_power")

func expected(definition: DiceDefinition, weights: PackedFloat64Array) -> float:
	var total: float = 0.0
	var value: float = 0.0
	for index in weights.size():
		total += weights[index]
		value += weights[index] * payout(definition, index + 1)
	return value / total if total > 0 else 0.0
