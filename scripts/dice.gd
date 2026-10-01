extends Node

var data: DiceData

func roll() -> float:
	var result = randi_range(1, data.sides)
	result += data.flat_bonus
	result *= data.multiplier
	return result


var auto_roll_timer := 0.0

func process_auto_roll(delta) -> float:
	if data.has_auto_roll_upgrade:
		auto_roll_timer += delta
		if auto_roll_timer >= data.auto_roll_interval:
			auto_roll_timer = 0
			return roll()
	return 0
