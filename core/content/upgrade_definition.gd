class_name UpgradeDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
## One short line shown on shop rows; the description becomes the tooltip.
@export var summary: String = ""
@export var cost: float = 100.0
@export var growth: float = 2.0
@export var max_level: int = 1
@export var unlock_earned: float = 0.0
@export var stat: String = "payout"
@export var operation: String = "multiply"
@export var value: float = 1.25
@export var condition: String = ""
@export var target: String = ""
@export var permanent: bool = false
@export var prerequisite: String = ""
@export var effects: Array[Resource] = []
## Talent tree only: which shop icon to draw (defaults to the id) and the node's cell on the map.
@export var icon: String = ""
@export var tree_position: Vector2i = Vector2i.ZERO

func valid() -> bool:
	if not stat in ["payout", "luck", "combos", "helper_speed", "roll_speed", "chain", "critical",
			"starting_cash", "starting_dice", "starting_helpers", "table_cooldown", "offline_hours", "keep_helpers", "fate_gain",
			"helper_payout", "helper_smart", "helper_hands", "streak_window", "crit_chance", "crit_power",
			"die_discount", "upgrade_discount", "streak_power", "combo_power", "offline_rate", "chip_gain",
			"hat_bonus", "chip_hoard", "second_chance"] or not operation in ["add", "multiply"]:
		return false
	if not condition in ["", "six", "maximum"] or value < 0 or (operation == "multiply" and value == 0):
		return false
	for effect in effects:
		if not effect is EffectDefinition or not effect.valid():
			return false
	return not id.is_empty() and is_finite(cost) and cost > 0 and max_level > 0 and is_finite(value) and is_finite(growth) and growth >= 1
