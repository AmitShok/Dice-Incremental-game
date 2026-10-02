class_name DiceDefinition
extends Resource

@export var rolling_texture: Texture2D

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var sides: int = 6
@export var base_cost: float = 10.0
@export var cost_growth: float = 2.0
@export var base_payout: float = 1.0
@export var flat_bonus: float = 0.0
@export var weights: PackedFloat64Array = []
@export var duration: float = 0.85
@export var unlock_earned: float = 0.0
@export var auto_cost: float = 1000.0
@export var auto_interval: float = 1.0
@export var behavior: String = ""
@export var tags: PackedStringArray = []
@export var texture: Texture2D
@export var tint: Color = Color.WHITE
@export var effects: Array[Resource] = []

func valid() -> bool:
	for effect in effects:
		if not effect is EffectDefinition or not effect.valid():
			return false
	if id.is_empty() or sides < 2 or sides > 100 or not is_finite(base_cost) or base_cost <= 0:
		return false
	if not is_finite(base_payout) or base_payout <= 0 or not is_finite(flat_bonus) or flat_bonus < 0:
		return false
	if not is_finite(duration) or duration < 0.1 or not is_finite(auto_interval) or auto_interval < 0.1:
		return false
	if not is_finite(cost_growth) or cost_growth < 1.0 or not is_finite(auto_cost) or auto_cost <= 0:
		return false
	if not is_finite(unlock_earned) or unlock_earned < 0:
		return false
	if not weights.is_empty():
		if weights.size() != sides:
			return false
		var total: float = 0.0
		for weight in weights:
			if not is_finite(weight) or weight < 0:
				return false
			total += weight
		if total <= 0:
			return false
	return true
