class_name GameSession
extends RefCounted

var registry: ContentRegistry
var state: GameState
var events := GameEvents.new()
var roller := RollSystem.new()
var economy: EconomyService
var progression: ProgressionService
var automation := AutomationService.new()
var pending: Dictionary = {}
var next_roll: int = 1
var paused: bool = false
var save_locked: bool = false
var forced_face: int = 0

func _init(content: ContentRegistry, existing: GameState = null) -> void:
	registry = content
	state = existing if existing != null else GameState.new()
	if existing == null and registry.dice.has("d6"):
		state.add_die("d6", Vector2(395, 310))
	if not state.rng_state.is_empty() and state.rng_state.is_valid_int():
		roller.rng.state = state.rng_state.to_int()
	economy = EconomyService.new(state, registry)
	progression = ProgressionService.new(state, registry, economy, events)

func request_roll(ids: Array, source: String = "manual", depth: int = 0) -> bool:
	if paused or depth > 4 or pending.size() >= 100:
		return false
	var outcomes: Array = []
	for id in ids:
		var die: DiceInstance = state.find_die(int(id))
		if die == null or die.busy or die.cooldown > 0:
			continue
		var definition: DiceDefinition = registry.dice[die.definition_id]
		var face: int = roller.sample(definition, economy.modifier("luck", definition.id))
		if OS.is_debug_build() and forced_face != 0:
			face = definition.sides if forced_face < 0 else clampi(forced_face, 1, definition.sides)
		var critical: bool = economy.modifier("critical") > 1.0 and roller.rng.randf() < 0.1
		var duration: float = definition.duration / economy.modifier("roll_speed")
		var outcome: Dictionary = {"roll_id": next_roll, "die_id": die.id, "definition_id": definition.id,
			"face": face, "sides": definition.sides, "source": source, "depth": depth,
			"critical": critical, "duration": duration, "remaining": duration,
			"position": die.position, "payout": 0.0, "combo": 1.0, "label": ""}
		outcome.landing_position = die.position
		if state.settings.get("motion", true):
			# A separate deterministic stream keeps movement from consuming payout RNG.
			var scatter := RandomNumberGenerator.new()
			scatter.seed = hash("%d:%d:%d" % [next_roll, die.id, face])
			var offset: Vector2 = Vector2.from_angle(scatter.randf_range(0, TAU)) * scatter.randf_range(12, 32)
			outcome.landing_position = (die.position + offset).clamp(Vector2(65, 150), Vector2(725, 500))
		next_roll += 1
		die.busy = true
		outcomes.append(outcome)
		if outcomes.size() + pending.size() >= 100:
			break
	var combo: Dictionary = SynergyService.batch(outcomes, economy.modifier("combos") > 1.0)
	if not combo.label.is_empty():
		events.combo_triggered.emit(combo.label, combo.multiplier)
		StatisticsService.increment(state, "combos")
		var combo_stat: String = "straights" if combo.multiplier == 8 else ("triples" if combo.multiplier == 5 else "doubles")
		StatisticsService.increment(state, combo_stat)
		if combo.label == "SNAKE EYES":
			StatisticsService.increment(state, "snake_eyes")
	for outcome in outcomes:
		var definition: DiceDefinition = registry.dice[outcome.definition_id]
		var die: DiceInstance = state.find_die(outcome.die_id)
		outcome.combo = combo.multiplier
		outcome.label = combo.label
		outcome.payout = economy.payout(definition, outcome.face, combo.multiplier * (3.0 if outcome.critical else 1.0), SynergyService.aura(state, registry, die))
		pending[outcome.roll_id] = outcome
		events.die_roll_started.emit(outcome.duplicate())
	if not outcomes.is_empty():
		state.tutorial_step = maxi(state.tutorial_step, 1)
	return not outcomes.is_empty()

func finish_roll(roll_id: int, allow_chains: bool = true) -> bool:
	if not pending.has(roll_id):
		return false
	var outcome: Dictionary = pending[roll_id]
	pending.erase(roll_id)
	var die: DiceInstance = state.find_die(outcome.die_id)
	if die == null:
		return false
	die.busy = false
	die.cooldown = 0.15
	die.face = outcome.face
	die.position = outcome.landing_position
	outcome.position = die.position
	economy.credit(outcome.payout)
	StatisticsService.resolved(state, outcome)
	if outcome.face == 20 and outcome.sides == 20:
		StatisticsService.increment(state, "natural_twenty")
	events.die_landed.emit(outcome)
	events.money_generated.emit(outcome.payout, die.position)
	if allow_chains:
		for target_id in SynergyService.followups(state, registry, outcome, die):
			if target_id == die.id:
				die.cooldown = 0.0
			request_roll([target_id], "chain", outcome.depth + 1)
	StatisticsService.check_achievements(state, events)
	events.changed.emit()
	return true

func tick(delta: float) -> void:
	if paused or not is_finite(delta) or delta <= 0:
		return
	StatisticsService.increment(state, "playtime", delta)
	var completed: Array[int] = []
	for key in pending:
		pending[key].remaining -= delta
		if pending[key].remaining <= 0:
			completed.append(key)
	for id in completed:
		finish_roll(id)
	automation.tick(minf(delta, 5.0), self)

func settle() -> void:
	# Closing a session commits reserved outcomes once, without spawning new chains.
	for id in pending.keys():
		finish_roll(id, false)
	state.rng_state = str(roller.rng.state)

func prestige() -> bool:
	settle()
	var success: bool = progression.prestige()
	if success:
		automation.workers.clear()
	return success

func move_die(id: int, at: Vector2) -> bool:
	var die: DiceInstance = state.find_die(id)
	if die == null or die.busy:
		return false
	die.position = at.clamp(Vector2(65, 150), Vector2(725, 500))
	events.changed.emit()
	return true

func offline(seconds: float) -> float:
	var elapsed: float = clampf(seconds, 0, 14400)
	var amount: float = minf(GameState.MAX_AMOUNT, automation.expected_income(self) * elapsed * 0.5)
	economy.credit(amount)
	StatisticsService.increment(state, "offline_earned", amount)
	StatisticsService.increment(state, "earned", amount)
	return amount
