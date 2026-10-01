class_name AutomationService
extends RefCounted

var workers: Array[Dictionary] = []
var cursor: int = 0

func sync(count: int) -> void:
	while workers.size() < count:
		workers.append({"position": Vector2(95 + workers.size() * 35, 450), "target": 0, "phase": "idle", "wait": 0.0})
	if workers.size() > count:
		workers.resize(count)

func tick(delta: float, session: GameSession) -> void:
	var state: GameState = session.state
	sync(state.helpers)
	var speed: float = 100.0 * session.economy.modifier("helper_speed")
	for die in state.dice:
		die.cooldown = maxf(0, die.cooldown - delta)
		if not bool(state.automatic.get(die.definition_id, false)):
			continue
		var definition: DiceDefinition = session.registry.dice[die.definition_id]
		# Bounded backlog retains fractions without producing an unbounded catch-up storm.
		die.automatic_clock = minf(5.0, die.automatic_clock + delta)
		if not die.busy and die.cooldown <= 0 and die.automatic_clock >= definition.auto_interval:
			if session.request_roll([die.id], "automatic"):
				die.automatic_clock -= definition.auto_interval
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
			if target != null and session.request_roll([target.id], "helper"):
				worker.phase = "roll"
				worker.wait = session.registry.dice[target.definition_id].duration / session.economy.modifier("roll_speed")
				continue
			worker.target = 0
			target = null
		if target == null or target.busy or bool(state.automatic.get(target.definition_id, false)):
			worker.target = 0
			worker.phase = "idle"
			if state.dice.is_empty():
				continue
			for attempt in state.dice.size():
				cursor = (cursor + 1) % state.dice.size()
				var candidate: DiceInstance = state.dice[cursor]
				if not candidate.busy and candidate.cooldown <= 0 and not bool(state.automatic.get(candidate.definition_id, false)) and not _claimed(candidate.id, worker_index):
					target = candidate
					worker.target = candidate.id
					break
		if int(worker.target) == 0 or target == null:
			continue
		var destination: Vector2 = target.position + Vector2(-34, 30)
		worker.position = (worker.position as Vector2).move_toward(destination, delta * speed)
		worker.phase = "walk"
		if (worker.position as Vector2).distance_to(destination) < 2:
			worker.phase = "interact"
			worker.wait = 0.22 / session.economy.modifier("helper_speed")

func _claimed(id: int, requester: int) -> bool:
	for index in workers.size():
		if index != requester and int(workers[index].target) == id:
			return true
	return false

func expected_income(session: GameSession) -> float:
	var production: float = 0.0
	var manual_values: Array[float] = []
	for die in session.state.dice:
		var definition: DiceDefinition = session.registry.dice[die.definition_id]
		var mean: float = session.economy.expected(definition, session.roller.weights_for(definition, session.economy.modifier("luck", definition.id)))
		if session.economy.modifier("critical") > 1.0:
			mean *= 1.2
		mean *= SynergyService.aura(session.state, session.registry, die)
		if bool(session.state.automatic.get(die.definition_id, false)):
			production += mean / maxf(definition.auto_interval, definition.duration / session.economy.modifier("roll_speed") + 0.15)
		else:
			manual_values.append(mean)
	if not manual_values.is_empty():
		var sum: float = 0.0
		for value in manual_values:
			sum += value
		# Conservative travel+interaction estimate, not a promise of measured throughput.
		production += sum / manual_values.size() * minf(session.state.helpers, manual_values.size()) * session.economy.modifier("helper_speed") / 3.0
	return production
