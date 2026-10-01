extends Node

var currency: float = 10
var owned_dice: Array = []

var global_multiplier: float = 1.0


func _process(delta):
	process_auto_rolls(delta)

func process_auto_rolls(delta):
	var total := 0
	for dice in owned_dice:
		total += dice.process_auto_roll(delta)
	currency += total

func _ready():
	set_process(true)

func roll_all_dice():
	var total := 0
	
	for dice in owned_dice:
		total += dice.roll()
	
	total *= global_multiplier
	currency += total
	
	print("Rolled:", total, "Money:", currency)

func buy_dice(dice_data: DiceData) -> bool:
	if currency >= dice_data.cost:
		currency -= dice_data.cost

		# Create dice instance
		var dice = preload("res://scripts/dice.gd").new()
		dice.data = dice_data
		owned_dice.append(dice)

		# DOUBLE the cost for next purchase
		dice_data.cost *= 2

		return true
	return false

func count_owned_dice(dice_data: DiceData) -> int:
	var count := 0
	for dice in owned_dice:
		if dice.data == dice_data:
			count += 1
	return count

func get_auto_roll_income_per_second() -> float:
	var total := 0.0
	for dice in owned_dice:
		if dice.data.has_auto_roll_upgrade:
			# Each dice rolls every auto_roll_interval seconds
			# Expected income per second = average roll * (1 / interval)
			var avg_roll = (dice.data.sides + 1) / 2.0
			avg_roll += dice.data.flat_bonus
			avg_roll *= dice.data.multiplier
			total += avg_roll / dice.data.auto_roll_interval
	return total
