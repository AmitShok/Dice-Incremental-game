class_name RollSystem
extends RefCounted

var rng := RandomNumberGenerator.new()

func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value

func weights_for(definition: DiceDefinition, high_bias: float = 1.0) -> PackedFloat64Array:
	var weights := PackedFloat64Array()
	for index in definition.sides:
		var base: float = definition.weights[index] if not definition.weights.is_empty() else 1.0
		if index + 1 > definition.sides / 2.0:
			base *= high_bias
		weights.append(base)
	return weights

func sample(definition: DiceDefinition, high_bias: float = 1.0) -> int:
	var weights: PackedFloat64Array = weights_for(definition, high_bias)
	var total: float = 0.0
	for weight in weights:
		total += weight
	var selection: float = rng.randf() * total
	for index in weights.size():
		selection -= weights[index]
		if selection < 0:
			return index + 1
	return definition.sides

func simulate_rolls(definition: DiceDefinition, count: int, high_bias: float = 1.0) -> Dictionary:
	var histogram: Array[int] = []
	histogram.resize(definition.sides)
	histogram.fill(0)
	for index in maxi(0, count):
		histogram[sample(definition, high_bias) - 1] += 1
	return {"rolls": count, "histogram": histogram}
