class_name AutomationService
extends RefCounted

## Helpers are the game's only automation. Each walks to a ready die and throws it.
## Upgrades make them faster (helper_speed), pay more (helper_payout), choose the most
## valuable die (helper_smart) and grab nearby dice to throw together (helper_hands).
const HANDS_RADIUS: float = 110.0
const BASE_SPEED: float = 100.0

var workers: Array[Dictionary] = []
var cursor: int = 0

func sync(count: int) -> void:
	while workers.size() < count:
		workers.append({"position": Vector2(95 + workers.size() * 35, 450), "target": 0, "phase": "idle", "wait": 0.0, "extra": []})
	if workers.size() > count:
		workers.resize(count)

static func speed_factor(session: GameSession) -> float:
	return session.economy.modifier("helper_speed") * (1.5 if session.state.table_id == "workbench" else 1.0)

static func extra_hands(session: GameSession) -> int:
	return maxi(0, roundi(session.economy.modifier("helper_hands") - 1.0))

func tick(delta: float, session: GameSession) -> void:
	var state: GameState = session.state
	sync(state.helpers)
	var speed: float = speed_factor(session)
	for die in state.dice:
		die.cooldown = maxf(0, die.cooldown - delta)
	for worker_index in workers.size():
		var worker: Dictionary = workers[worker_index]
		worker.wait = maxf(0, worker.wait - delta)
		if worker.wait > 0:
			continue
		var target: DiceInstance = state.find_die(int(worker.target))
		if worker.phase == "roll":
			worker.phase = "celebrate" if target != null and target.face == session.registry.dice[target.definition_id].sides else "idle"
			worker.wait = 0.45 if worker.phase == "celebrate" else 0.15
			worker.target = 0
			continue
		if worker.phase == "interact":
			if target != null and _throw(session, worker, target):
				worker.phase = "roll"
				worker.wait = session.registry.dice[target.definition_id].duration / session.economy.modifier("roll_speed")
				continue
			worker.target = 0
			target = null
		if target == null or target.busy:
			worker.target = 0
			worker.phase = "idle"
			target = _choose(session, worker_index)
			if target == null:
				continue
			worker.target = target.id
		var destination: Vector2 = target.position + Vector2(-34, 30)
		worker.position = (worker.position as Vector2).move_toward(destination, delta * BASE_SPEED * speed)
		worker.phase = "walk"
		if (worker.position as Vector2).distance_to(destination) < 2:
			worker.phase = "interact"
			worker.wait = 0.22 / speed

## Throws the target plus up to extra_hands() nearby unclaimed ready dice as one batch.
func _throw(session: GameSession, worker: Dictionary, target: DiceInstance) -> bool:
	var ids: Array = [target.id]
	var claimed: Array = _claimed_ids(int(worker.target))
	for neighbor in SynergyService.nearest_many(session.state, target, HANDS_RADIUS, extra_hands(session), claimed):
		ids.append(neighbor.id)
	return session.request_roll(ids, "helper")

func _choose(session: GameSession, requester: int) -> DiceInstance:
	var state: GameState = session.state
	if state.dice.is_empty():
		return null
	var claimed: Array = _claimed_ids(-1, requester)
	if session.economy.modifier("helper_smart") > 1.0:
		var best: DiceInstance = null
		var best_value: float = -1.0
		for candidate in state.dice:
			if candidate.busy or candidate.cooldown > 0 or claimed.has(candidate.id):
				continue
			var value: float = die_value(session, candidate)
			if value > best_value:
				best_value = value
				best = candidate
		return best
	for attempt in state.dice.size():
		cursor = (cursor + 1) % state.dice.size()
		var candidate: DiceInstance = state.dice[cursor]
		if not candidate.busy and candidate.cooldown <= 0 and not claimed.has(candidate.id):
			return candidate
	return null

static func die_value(session: GameSession, die: DiceInstance) -> float:
	var definition: DiceDefinition = session.registry.dice[die.definition_id]
	return definition.base_payout * (definition.sides + 1) * 0.5 * (3.0 if die.gilded else 1.0)

func _claimed_ids(keep: int = -1, requester: int = -1) -> Array:
	var ids: Array = []
	for index in workers.size():
		var id: int = int(workers[index].target)
		if index != requester and id != 0 and id != keep:
			ids.append(id)
	return ids

## Analytical ~income/sec shown in the HUD and used for offline earnings.
## Assumes a three-second helper cycle; excludes streaks, chains, combos and manual play.
func expected_income(session: GameSession) -> float:
	var values: Array[float] = []
	for die in session.state.dice:
		var definition: DiceDefinition = session.registry.dice[die.definition_id]
		var mean: float = session.economy.expected(definition, session.roller.weights_for(definition, session.economy.modifier("luck", definition.id)))
		if session.economy.modifier("critical") > 1.0:
			mean *= 1.2
		values.append(mean * SynergyService.aura(session.state, session.registry, die))
	if values.is_empty() or session.state.helpers == 0:
		return 0.0
	var sum: float = 0.0
	for value in values:
		sum += value
	var throws_per_cycle: float = minf(session.state.helpers * (1 + extra_hands(session)), values.size())
	return sum / values.size() * throws_per_cycle * speed_factor(session) * session.economy.modifier("helper_payout") / 3.0
