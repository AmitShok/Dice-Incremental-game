extends Resource
class_name DiceData

@export var dice_name: String
@export var sides: int = 6
@export var multiplier: float = 1.0
@export var flat_bonus: int = 0
@export var cost: float = 10
@export var is_support: bool = false
@export var has_auto_roll_upgrade: bool = false
@export var auto_roll_cost: float = 50  # default, can be customized per dice
@export var auto_roll_interval: float = 1.0  # seconds between auto-rolls
