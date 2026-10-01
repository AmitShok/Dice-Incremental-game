class_name StatisticsService
extends RefCounted

static func increment(state: GameState, key: String, value: float = 1.0) -> void:
	state.statistics[key] = minf(GameState.MAX_AMOUNT, float(state.statistics.get(key, 0)) + value)

static func resolved(state: GameState, outcome: Dictionary) -> void:
	increment(state, "rolls")
	increment(state, "earned", outcome.payout)
	state.statistics["best_payout"] = maxf(float(state.statistics.get("best_payout", 0)), outcome.payout)
	if outcome.face == 6:
		increment(state, "sixes")
	if outcome.face == outcome.sides:
		increment(state, "maximums")
	if outcome.face == 1:
		increment(state, "minimums")
	if outcome.critical:
		increment(state, "criticals")

static func check_achievements(state: GameState, events: GameEvents) -> void:
	var checks: Dictionary = {
		"First throw": float(state.statistics.get("rolls", 0)) >= 1,
		"Dice collector": state.dice.size() >= 10,
		"Dice goblin": state.dice.size() >= 50,
		"The house grows": float(state.statistics.get("earned", 0)) >= 1000000,
		"A helping hand": state.helpers >= 1,
		"Another chance": state.prestige_total >= 1,
		"Snake eyes": float(state.statistics.get("snake_eyes", 0)) >= 1,
		"Perfect twenty": float(state.statistics.get("natural_twenty", 0)) >= 1}
	for id in checks:
		if checks[id] and not state.achievements.has(id):
			state.achievements.append(id)
			events.achievement_unlocked.emit(id)
