class_name EffectDefinition
extends Resource

@export var trigger: String = "landed"
@export var condition: String = "maximum"
@export var target: String = "nearest"
@export var action: String = "reroll"
@export var radius: float = 140.0
@export var max_depth: int = 4

func valid() -> bool:
	return trigger == "landed" and condition in ["always", "maximum", "minimum"] and target in ["self", "nearest"] and action == "reroll" and is_finite(radius) and radius > 0 and max_depth >= 0 and max_depth <= 4
