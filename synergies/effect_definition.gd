class_name EffectDefinition
extends Resource

## What happens after a die lands.
## reroll: roll `target` again (self or nearest ready die).
## arc:    roll up to `count` nearest ready dice within radius, each separately, with a charged bonus.
## blast:  roll every ready die within radius together as one batch, so combinations can trigger.
## gild:   mark every die within radius as gilded; its next roll pays the gilded bonus once.
@export var trigger: String = "landed"
@export var condition: String = "maximum"
@export var target: String = "nearest"
@export var action: String = "reroll"
@export var radius: float = 140.0
@export var max_depth: int = 4
@export var count: int = 1

const ACTIONS: Array[String] = ["reroll", "arc", "blast", "gild"]

func valid() -> bool:
	return trigger == "landed" and condition in ["always", "maximum", "minimum", "high"] and target in ["self", "nearest", "radius"] \
		and action in ACTIONS and is_finite(radius) and radius > 0 and max_depth >= 0 and max_depth <= 4 and count >= 1 and count <= 8
