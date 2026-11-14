class_name GameState
extends RefCounted

const MAX_AMOUNT: float = 1e100
const MAX_DICE: int = 100
const TABLE_ROLL_COOLDOWN: float = 60.0
const MAX_HELPERS: int = 12
var table_roll_remaining: float = 0.0
var money: float = 0.0
var run_earned: float = 0.0
var dice: Array[DiceInstance] = []
var counts: Dictionary = {}
var upgrades: Dictionary = {}
# Legacy per-family auto-roll purchases; refunded and cleared on load (helpers replaced them).
var automatic: Dictionary = {}
var talents: Dictionary = {}
var statistics: Dictionary = {}
var achievements: Array = []
var helpers: int = 0
var prestige_points: int = 0
var prestige_total: int = 0
## 2 = the big talent tree with the +1% per held Fate bonus. Older saves get talents refunded.
const FATE_VERSION: int = 2
var fate_version: int = FATE_VERSION
var next_id: int = 1
var tutorial_step: int = 0
var settings: Dictionary = {"sound": true, "music": true, "motion": true, "flashes": true, "numbers": true, "particles": true, "volume": 0.55}
var last_saved: float = 0.0
var rng_state: String = ""
# Cosmetic and table progress survives Fate resets.
var chips: int = 0
var hats: Array = []
var crew_hat: String = ""
var table_id: String = "felt"
var tables: Array = ["felt"]

func add_die(definition_id: String, at: Vector2) -> DiceInstance:
	var die := DiceInstance.new()
	die.id = next_id
	next_id += 1
	die.definition_id = definition_id
	die.position = at
	dice.append(die)
	counts[definition_id] = int(counts.get(definition_id, 0)) + 1
	return die

func find_die(id: int) -> DiceInstance:
	for die in dice:
		if die.id == id:
			return die
	return null

func snapshot() -> Dictionary:
	var items: Array = []
	for die in dice:
		items.append(die.snapshot())
	return {"money": money, "run_earned": run_earned, "dice": items, "counts": counts.duplicate(true),
		"upgrades": upgrades.duplicate(true), "automatic": automatic.duplicate(true),
		"talents": talents.duplicate(true), "statistics": statistics.duplicate(true),
		"achievements": achievements.duplicate(), "helpers": helpers, "prestige_points": prestige_points,
		"prestige_total": prestige_total, "next_id": next_id, "tutorial_step": tutorial_step,
		"settings": settings.duplicate(true), "last_saved": last_saved, "rng_state": rng_state,
		"table_roll_remaining": table_roll_remaining, "chips": chips, "hats": hats.duplicate(),
		"crew_hat": crew_hat, "table_id": table_id, "tables": tables.duplicate(), "fate_version": fate_version}

static func valid_number(value: Variant, lower: float = 0.0, upper: float = MAX_AMOUNT) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and float(value) >= lower and float(value) <= upper

static func valid_integer(value: Variant, lower: float = 0.0, upper: float = 1000000000) -> bool:
	return valid_number(value, lower, upper) and floor(float(value)) == float(value)

static func restore(data: Dictionary, registry: ContentRegistry) -> GameState:
	if not valid_number(data.get("money")) or not valid_number(data.get("run_earned", 0)):
		return null
	if not data.get("dice") is Array or data.dice.size() > MAX_DICE:
		return null
	var result := GameState.new()
	if not valid_number(data.get("table_roll_remaining", 0.0), 0.0, TABLE_ROLL_COOLDOWN):
		return null
	result.table_roll_remaining = float(data.get("table_roll_remaining", 0.0))
	result.money = float(data.money)
	result.run_earned = float(data.get("run_earned", 0))
	var seen: Dictionary = {}
	for item in data.dice:
		if not item is Dictionary or not item.get("definition_id") is String or not registry.dice.has(item.definition_id):
			return null
		if not valid_integer(item.get("id"), 1) or seen.has(int(item.id)):
			return null
		if not valid_number(item.get("x"), 55, 735) or not valid_number(item.get("y"), 140, 505):
			return null
		var die: DiceInstance = result.add_die(item.definition_id, Vector2(item.x, item.y))
		die.id = int(item.id)
		seen[die.id] = true
		if not valid_integer(item.get("face", 1), 1, registry.dice[item.definition_id].sides):
			return null
		die.face = int(item.get("face", 1))
		var clock_value: Variant = item.get("automatic_clock", 0)
		if not valid_number(clock_value, 0, 60):
			return null
		die.automatic_clock = float(clock_value)
		if not item.get("gilded", false) is bool:
			return null
		die.gilded = item.get("gilded", false)
		result.next_id = maxi(result.next_id, die.id + 1)
	if not valid_integer(data.get("next_id", result.next_id), result.next_id):
		return null
	result.next_id = int(data.get("next_id", result.next_id))
	for key in ["upgrades", "automatic", "talents", "statistics", "settings"]:
		if not data.get(key, {}) is Dictionary:
			return null
	for pair in [["upgrades", registry.upgrades], ["talents", registry.talents]]:
		for id in data.get(pair[0], {}):
			if not pair[1].has(id) or not valid_integer(data[pair[0]][id], 0, pair[1][id].max_level):
				return null
			result.get(pair[0])[id] = int(data[pair[0]][id])
	for id in data.get("automatic", {}):
		if not registry.dice.has(id) or not data.automatic[id] is bool:
			return null
		result.automatic[id] = data.automatic[id]
	for key in data.get("statistics", {}):
		if not key is String or not valid_number(data.statistics[key]):
			return null
		result.statistics[key] = float(data.statistics[key])
	for key in ["helpers", "prestige_points", "prestige_total", "tutorial_step"]:
		if not valid_integer(data.get(key, 0)):
			return null
		result.set(key, int(data.get(key, 0)))
	# Saves without the field predate the big talent tree.
	if not valid_integer(data.get("fate_version", 1)):
		return null
	result.fate_version = int(data.get("fate_version", 1))
	if result.helpers > MAX_HELPERS:
		return null
	if not data.get("achievements", []) is Array:
		return null
	for item in data.get("achievements", []):
		if not item is String:
			return null
	result.achievements = data.get("achievements", []).duplicate()
	for key in result.settings:
		if not data.get("settings", {}).has(key):
			continue
		var value: Variant = data.settings[key]
		if key == "volume":
			if not valid_number(value, 0, 1):
				return null
		elif not value is bool:
			return null
		result.settings[key] = value
	if not valid_number(data.get("last_saved", 0)):
		return null
	result.last_saved = float(data.get("last_saved", 0))
	if not data.get("rng_state", "") is String:
		return null
	if not data.get("rng_state", "").is_empty() and not data.get("rng_state").is_valid_int():
		return null
	result.rng_state = data.get("rng_state", "")
	if not valid_integer(data.get("chips", 0)):
		return null
	result.chips = int(data.get("chips", 0))
	for key in ["hats", "tables"]:
		if not data.get(key, []) is Array:
			return null
		for item in data.get(key, []):
			if not item is String:
				return null
	for hat in data.get("hats", []):
		if Cosmetics.HATS.has(hat) and not result.hats.has(hat):
			result.hats.append(hat)
	for table in data.get("tables", []):
		if TableCatalog.TABLES.has(table) and not result.tables.has(table):
			result.tables.append(table)
	var crew: Variant = data.get("crew_hat", "")
	var table_id: Variant = data.get("table_id", "felt")
	if not crew is String or not table_id is String:
		return null
	result.crew_hat = crew if crew == "" or crew == "mix" or result.hats.has(crew) else ""
	result.table_id = table_id if result.tables.has(table_id) else "felt"
	return result
