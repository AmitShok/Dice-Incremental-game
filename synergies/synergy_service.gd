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

static func nearest(state: GameState, source: DiceInstance, radius: float = 140.0) -> DiceInstance:
	var target: DiceInstance = null
	var distance: float = radius
	for candidate in state.dice:
		if candidate == source or candidate.busy or candidate.cooldown > 0:
			continue
		var current: float = candidate.position.distance_to(source.position)
		if current < distance:
			distance = current
			target = candidate
	return target

static func aura(state: GameState, registry: ContentRegistry, source: DiceInstance) -> float:
	for candidate in state.dice:
		if candidate != source and registry.dice[candidate.definition_id].behavior == "aura" and candidate.position.distance_to(source.position) <= 115:
			return 1.5
	return 1.0

static func followups(state: GameState, registry: ContentRegistry, outcome: Dictionary, source: DiceInstance) -> Array[int]:
	var rules: Array = registry.dice[source.definition_id].effects.duplicate()
	for upgrade in registry.all_modifiers():
		var levels: Dictionary = state.talents if upgrade.permanent else state.upgrades
		if int(levels.get(upgrade.id, 0)) > 0:
			rules.append_array(upgrade.effects)
	var targets: Array[int] = []
	for rule in rules:
		if outcome.depth >= rule.max_depth or rule.trigger != "landed":
			continue
		if rule.condition == "maximum" and outcome.face != outcome.sides:
			continue
		if rule.condition == "minimum" and outcome.face != 1:
			continue
		var target: DiceInstance = source if rule.target == "self" else nearest(state, source, rule.radius)
		if target != null and not targets.has(target.id):
			targets.append(target.id)
	return targets
