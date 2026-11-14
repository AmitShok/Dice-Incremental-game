class_name TableCatalog
extends RefCounted

## Playing surfaces. Each has an unlock condition (checked against lifetime state) and a rule.
## Rules are read by EconomyService/GameSession through rule(); unlocks persist across Fate.
const TABLES: Dictionary = {
	"felt": {"name": "Green felt", "rule": "No special rules. A good table for any build.",
		"unlock": "Always available."},
	"velvet": {"name": "Velvet parlour", "rule": "Combinations pay 1.5× more. Hot streaks cool twice as fast.",
		"unlock": "Roll 25 combinations (lifetime)."},
	"workbench": {"name": "Oak workbench", "rule": "Helpers move and act 50% faster. Your own clicks pay 25% less.",
		"unlock": "Have 8 helpers at once."},
	"starlit": {"name": "Starlit cloth", "rule": "Maximum faces pay double. Ones pay nothing, but give 2 chips.",
		"unlock": "Begin again with Fate once."},
	"gilded": {"name": "Gilded baize", "rule": "Gilded dice pay 5× instead of 3×. Gild dice cost 30% less.",
		"unlock": "Gild 100 dice (lifetime)."},
}

static func unlocked_by(state: GameState, id: String) -> bool:
	match id:
		"felt": return true
		"velvet": return float(state.statistics.get("combos", 0)) >= 25
		"workbench": return state.helpers >= 8
		"starlit": return state.prestige_total >= 1
		"gilded": return float(state.statistics.get("gilded", 0)) >= 100
	return false

## Adds newly earned tables; returns their ids so the UI can announce them.
static func check_unlocks(state: GameState) -> Array[String]:
	var fresh: Array[String] = []
	for id in TABLES:
		if not state.tables.has(id) and unlocked_by(state, id):
			state.tables.append(id)
			fresh.append(id)
	return fresh
