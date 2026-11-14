class_name SynergyService
extends RefCounted

static func batch(outcomes: Array, enabled: bool) -> Dictionary:
	if not enabled or outcomes.size() < 2:
		return {"label": "", "multiplier": 1.0}
	var counts: Dictionary = {}
	for outcome in outcomes:
		counts[outcome.face] = int(counts.get(outcome.face, 0)) + 1
	var most: int = 0
	for count in counts.values():
		most = maxi(most, int(count))
	if counts.has(1) and counts.has(2) and counts.has(3) and counts.has(4) and counts.has(5):
		return {"label": "STRAIGHT", "multiplier": 8.0}
	if most >= 3:
		return {"label": "TRIPLES", "multiplier": 5.0}
	if most == 2:
		return {"label": "SNAKE EYES" if int(counts.get(1, 0)) >= 2 else "DOUBLES", "multiplier": 2.0}
	return {"label": "", "multiplier": 1.0}

static func _ready_die(candidate: DiceInstance) -> bool:
	return not candidate.busy and candidate.cooldown <= 0

static func nearest(state: GameState, source: DiceInstance, radius: float = 140.0) -> DiceInstance:
	var found: Array[DiceInstance] = nearest_many(state, source, radius, 1)
	return null if found.is_empty() else found[0]

## Ready dice within radius, closest first, at most `limit`.
static func nearest_many(state: GameState, source: DiceInstance, radius: float, limit: int, exclude: Array = []) -> Array[DiceInstance]:
	var candidates: Array = []
	for candidate in state.dice:
		if candidate == source or not _ready_die(candidate) or exclude.has(candidate.id):
			continue
		var distance: float = candidate.position.distance_to(source.position)
		if distance < radius:
			candidates.append([distance, candidate])
	candidates.sort_custom(func(a, b): return a[0] < b[0])
	var result: Array[DiceInstance] = []
	for pair in candidates.slice(0, limit):
		result.append(pair[1])
	return result

## Every die (busy or not) within radius, excluding the source.
static func within(state: GameState, source: DiceInstance, radius: float) -> Array[DiceInstance]:
	var result: Array[DiceInstance] = []
	for candidate in state.dice:
		if candidate != source and candidate.position.distance_to(source.position) <= radius:
			result.append(candidate)
	return result

static func aura(state: GameState, registry: ContentRegistry, source: DiceInstance) -> float:
	for candidate in state.dice:
		if candidate != source and registry.dice[candidate.definition_id].behavior == "aura" and candidate.position.distance_to(source.position) <= 115:
			return 1.5
	return 1.0

static func _condition_met(rule: EffectDefinition, outcome: Dictionary) -> bool:
	match rule.condition:
		"maximum": return outcome.face == outcome.sides
		"minimum": return outcome.face == 1
		"high": return outcome.face * 2 > outcome.sides
	return true

## Returns follow-up actions as {"action": String, "ids": Array[int]}.
## Each die id appears at most once across all returned actions.
static func followups(state: GameState, registry: ContentRegistry, outcome: Dictionary, source: DiceInstance) -> Array[Dictionary]:
	var rules: Array = registry.dice[source.definition_id].effects.duplicate()
	for upgrade in registry.all_modifiers():
		var levels: Dictionary = state.talents if upgrade.permanent else state.upgrades
		if int(levels.get(upgrade.id, 0)) > 0:
			rules.append_array(upgrade.effects)
	var used: Array = []
	var actions: Array[Dictionary] = []
	for rule in rules:
		if outcome.depth >= rule.max_depth or rule.trigger != "landed" or not _condition_met(rule, outcome):
			continue
		var ids: Array[int] = []
		match rule.action:
			"reroll":
				if rule.target == "self":
					if not used.has(source.id):
						ids.append(source.id)
				else:
					for target in nearest_many(state, source, rule.radius, 1, used):
						ids.append(target.id)
			"arc", "blast":
				var limit: int = rule.count if rule.action == "arc" else GameState.MAX_DICE
				for target in nearest_many(state, source, rule.radius, limit, used):
					ids.append(target.id)
			"gild":
				for target in within(state, source, rule.radius):
					if not target.gilded:
						ids.append(target.id)
		if ids.is_empty():
			continue
		used.append_array(ids)
		actions.append({"action": rule.action, "ids": ids})
	return actions
