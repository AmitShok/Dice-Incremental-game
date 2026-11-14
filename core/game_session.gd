class_name GameSession
extends RefCounted

## Hot streak: manual clicks inside the window keep the streak alive; stages multiply every payout.
const STREAK_STAGES: Array = [[0, 1.0, ""], [10, 1.25, "WARM"], [25, 1.5, "HOT"], [50, 2.0, "BLAZING"], [100, 3.0, "INFINITE"]]
const STREAK_WINDOW: float = 2.5
const ARC_BONUS: float = 2.0

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
var streak: int = 0
var streak_timer: float = 0.0
## Cash refunded on load for legacy auto-roll purchases (helpers replaced them).
var migration_refund: float = 0.0
## Fate handed back once when old talent trees were replaced (shown as a notice on load).
var talent_refund: int = 0

func _init(content: ContentRegistry, existing: GameState = null) -> void:
	registry = content
	state = existing if existing != null else GameState.new()
	# Early exports could autosave an empty table before their content loaded.
	# Recover only the missing starter; retain the rest of the saved state.
	if state.dice.is_empty() and registry.dice.has("d6"):
		state.add_die("d6", Vector2(395, 310))
	if not state.rng_state.is_empty() and state.rng_state.is_valid_int():
		roller.rng.state = state.rng_state.to_int()
	economy = EconomyService.new(state, registry)
	progression = ProgressionService.new(state, registry, economy, events)
	progression.cosmetic_rng.randomize()
	_refund_legacy_automation()
	_refund_old_talents()

func _refund_legacy_automation() -> void:
	for id in state.automatic:
		if bool(state.automatic[id]) and registry.dice.has(id):
			migration_refund += registry.dice[id].auto_cost
	state.automatic.clear()
	if migration_refund > 0:
		state.money = minf(GameState.MAX_AMOUNT, state.money + migration_refund)

## Saves from before the big talent tree get every spent Fate back so they can pick again.
func _refund_old_talents() -> void:
	if state.fate_version >= GameState.FATE_VERSION:
		return
	for id in state.talents:
		var definition: UpgradeDefinition = registry.talents.get(id)
		if definition == null:
			continue
		for level in int(state.talents[id]):
			talent_refund += int(round(definition.cost * pow(definition.growth, level)))
	state.talents.clear()
	state.prestige_points = mini(ProgressionService.MAX_FATE, state.prestige_points + talent_refund)
	state.fate_version = GameState.FATE_VERSION

func roll_table() -> bool:
	if paused or state.table_roll_remaining > 0.0:
		return false
	var ids: Array[int] = []
	for die in state.dice:
		ids.append(die.id)
	if not request_roll(ids):
		return false
	state.table_roll_remaining = table_cooldown()
	events.changed.emit()
	return true

func table_cooldown() -> float:
	return GameState.TABLE_ROLL_COOLDOWN * economy.modifier("table_cooldown")

func offline_cap_seconds() -> float:
	return 14400.0 * economy.modifier("offline_hours")

# --- Hot streak -------------------------------------------------------------

func streak_window() -> float:
	return STREAK_WINDOW * economy.modifier("streak_window") * (0.5 if state.table_id == "velvet" else 1.0)

func streak_stage() -> int:
	var stage: int = 0
	for index in STREAK_STAGES.size():
		if streak >= STREAK_STAGES[index][0]:
			stage = index
	return stage

func streak_multiplier() -> float:
	# Fire within makes every stage hotter: WARM ×1.25 becomes ×1.5 at +100%.
	return 1.0 + (float(STREAK_STAGES[streak_stage()][1]) - 1.0) * economy.modifier("streak_power")

func _bump_streak() -> void:
	var before: int = streak_stage()
	streak += 1
	streak_timer = streak_window()
	if streak_stage() != before:
		events.streak_stage_changed.emit(streak_stage())
	StatisticsService.record_max(state, "best_streak", streak)

# --- Rolling ----------------------------------------------------------------

func request_roll(ids: Array, source: String = "manual", depth: int = 0, bonus: float = 1.0) -> bool:
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
		# Divine intervention: some 1s land on the top face. Only draws RNG when owned.
		if face == 1 and economy.modifier("second_chance") > 1.0 and roller.rng.randf() < economy.modifier("second_chance") - 1.0:
			face = definition.sides
		var critical: bool = economy.crit_chance() > 0.0 and roller.rng.randf() < economy.crit_chance()
		var duration: float = definition.duration / economy.modifier("roll_speed")
		var outcome: Dictionary = {"roll_id": next_roll, "die_id": die.id, "definition_id": definition.id,
			"face": face, "sides": definition.sides, "source": source, "depth": depth,
			"critical": critical, "duration": duration, "remaining": duration,
			"position": die.position, "payout": 0.0, "combo": 1.0, "label": "",
			"gilded": die.gilded, "charged": bonus > 1.0}
		die.gilded = false
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
	if outcomes.is_empty():
		return false
	if source == "manual" and depth == 0:
		_bump_streak()
	var combo: Dictionary = SynergyService.batch(outcomes, economy.modifier("combos") > 1.0)
	if not combo.label.is_empty():
		if state.table_id == "velvet":
			combo.multiplier *= 1.5
		combo.multiplier *= economy.modifier("combo_power")
		events.combo_triggered.emit(combo.label, combo.multiplier)
		StatisticsService.increment(state, "combos")
		var combo_stat: String = "straights" if combo.label == "STRAIGHT" else ("triples" if combo.label == "TRIPLES" else "doubles")
		StatisticsService.increment(state, combo_stat)
		if combo.label == "SNAKE EYES":
			StatisticsService.increment(state, "snake_eyes")
	var shared: float = combo.multiplier * bonus * streak_multiplier()
	for outcome in outcomes:
		var definition: DiceDefinition = registry.dice[outcome.definition_id]
		var die: DiceInstance = state.find_die(outcome.die_id)
		outcome.combo = combo.multiplier
		outcome.label = combo.label
		var multiplier: float = shared * (economy.crit_multiplier() if outcome.critical else 1.0) * _situational(outcome)
		outcome.payout = economy.payout(definition, outcome.face, multiplier, SynergyService.aura(state, registry, die))
		pending[outcome.roll_id] = outcome
		events.die_roll_started.emit(outcome.duplicate())
	state.tutorial_step = maxi(state.tutorial_step, 1)
	return true

## Multipliers that depend on who rolled, the table and the die's own state.
func _situational(outcome: Dictionary) -> float:
	var value: float = 1.0
	if outcome.source == "helper":
		value *= economy.modifier("helper_payout")
	if outcome.source == "manual" and state.table_id == "workbench":
		value *= 0.75
	if outcome.gilded:
		value *= 5.0 if state.table_id == "gilded" else 3.0
	if state.table_id == "starlit":
		if outcome.face == outcome.sides:
			value *= 2.0
		elif outcome.face == 1:
			value = 0.0
	return value

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
	if outcome.face == 1:
		var earned_chips: int = (2 if state.table_id == "starlit" else 1) * roundi(economy.modifier("chip_gain"))
		state.chips = mini(1000000000, state.chips + earned_chips)
		StatisticsService.increment(state, "chips", earned_chips)
	events.die_landed.emit(outcome)
	events.money_generated.emit(outcome.payout, die.position)
	if allow_chains:
		_apply_followups(outcome, die)
	StatisticsService.check_achievements(state, events)
	for table in TableCatalog.check_unlocks(state):
		events.table_unlocked.emit(table)
	events.changed.emit()
	return true

func _apply_followups(outcome: Dictionary, die: DiceInstance) -> void:
	for followup in SynergyService.followups(state, registry, outcome, die):
		var positions: Array = []
		for id in followup.ids:
			var target: DiceInstance = state.find_die(id)
			if target != null:
				positions.append(target.position)
		match followup.action:
			"reroll":
				if followup.ids[0] == die.id:
					die.cooldown = 0.0
				request_roll(followup.ids, "chain", outcome.depth + 1)
			"arc":
				for id in followup.ids:
					request_roll([id], "chain", outcome.depth + 1, ARC_BONUS)
				StatisticsService.increment(state, "arcs", followup.ids.size())
			"blast":
				request_roll(followup.ids, "chain", outcome.depth + 1)
				StatisticsService.increment(state, "blasts")
			"gild":
				for id in followup.ids:
					state.find_die(id).gilded = true
				StatisticsService.increment(state, "gilded", followup.ids.size())
		events.effect_triggered.emit(followup.action, die.position, positions)

# --- Selling ----------------------------------------------------------------

## Cash a die would return if sold now: half of what its latest copy cost.
func sell_value(id: int) -> float:
	var die: DiceInstance = state.find_die(id)
	if die == null:
		return 0.0
	var owned: int = int(state.counts.get(die.definition_id, 1))
	return 0.5 * economy.die_price_at(die.definition_id, maxi(0, owned - 1))

func can_sell(id: int) -> bool:
	var die: DiceInstance = state.find_die(id)
	return die != null and not die.busy and state.dice.size() > 1

func sell_die(id: int) -> float:
	if paused or not can_sell(id):
		return 0.0
	var die: DiceInstance = state.find_die(id)
	var amount: float = sell_value(id)
	state.dice.erase(die)
	var remaining: int = int(state.counts.get(die.definition_id, 1)) - 1
	if remaining > 0:
		state.counts[die.definition_id] = remaining
	else:
		state.counts.erase(die.definition_id)
	# Refunds are not earnings, so they never advance Fate.
	state.money = minf(GameState.MAX_AMOUNT, state.money + amount)
	StatisticsService.increment(state, "dice_sold")
	events.die_sold.emit(amount, die.position)
	events.changed.emit()
	return amount

# --- Clock ------------------------------------------------------------------

func tick(delta: float) -> void:
	if paused or not is_finite(delta) or delta <= 0:
		return
	StatisticsService.increment(state, "playtime", delta)
	state.table_roll_remaining = maxf(0.0, state.table_roll_remaining - delta)
	if streak > 0:
		streak_timer -= delta
		if streak_timer <= 0.0:
			streak = 0
			events.streak_stage_changed.emit(0)
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
		streak = 0
	return success

func select_table(id: String) -> bool:
	if not state.tables.has(id) or state.table_id == id:
		return false
	state.table_id = id
	events.changed.emit()
	return true

func move_die(id: int, at: Vector2) -> bool:
	var die: DiceInstance = state.find_die(id)
	if die == null or die.busy:
		return false
	die.position = at.clamp(Vector2(65, 150), Vector2(725, 500))
	events.changed.emit()
	return true

func offline(seconds: float) -> float:
	var elapsed: float = clampf(seconds, 0, offline_cap_seconds())
	state.table_roll_remaining = maxf(0.0, state.table_roll_remaining - elapsed)
	var amount: float = minf(GameState.MAX_AMOUNT, automation.expected_income(self) * elapsed * 0.5 * economy.modifier("offline_rate"))
	economy.credit(amount)
	StatisticsService.increment(state, "offline_earned", amount)
	StatisticsService.increment(state, "earned", amount)
	return amount
