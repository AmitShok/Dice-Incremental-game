extends Control

@onready var money_label = $VBoxContainer/MoneyLabel
@onready var roll_button = $VBoxContainer/RollButton
@onready var shop_container = $VBoxContainer/ShopContainer
@onready var income_label = $VBoxContainer/IncomeLabel

# Preload all dice resources
var dice_resources = [
	preload("res://resources/d6.tres"),
	preload("res://resources/d20.tres"),
	preload("res://resources/golden_d6.tres")
]

func _ready():
	roll_button.pressed.connect(_on_roll_pressed)
	create_shop()
	update_money()
	
func _process(delta):
	update_money()
	update_income()
	
func update_income():
	var income = GameManager.get_auto_roll_income_per_second()
	if income > 0:
		income_label.visible = true
		var rounded_income = floor(income * 10) / 10.0
		income_label.text = "Income/sec: " + str(rounded_income)
	else:
		income_label.visible = false

# Handle clicking "Roll" button
func _on_roll_pressed():
	GameManager.roll_all_dice()

# Update money label every frame
func update_money():
	money_label.text = "Money: " + str(round(GameManager.currency))

# Clear all children from a container
func clear_container(container: Node):
	for child in container.get_children():
		child.queue_free()

# Build the shop UI dynamically
func create_shop():
	# Remove old buttons
	clear_container(shop_container)
	
	for dice_data in dice_resources:
		var dice_copy = dice_data  # capture correctly in lambda
		
		# Count how many dice of this type the player owns
		var count = GameManager.count_owned_dice(dice_copy)
		
		# BUY DICE BUTTON
		var dice_button = Button.new()
		dice_button.text = dice_copy.dice_name + " (" + str(count) + ") - $" + str(round(dice_copy.cost))
		dice_button.pressed.connect(func():
			if GameManager.buy_dice(dice_copy):
				create_shop()  # refresh counts and buttons
			else:
				print("Not enough money for", dice_copy.dice_name)
		)
		shop_container.add_child(dice_button)
		
		# AUTO-ROLL UPGRADE BUTTON (only if player owns at least 1 and upgrade not bought)
		var has_dice := false
		for dice in GameManager.owned_dice:
			if dice.data == dice_copy:
				has_dice = true
				break
		
		if has_dice and not dice_copy.has_auto_roll_upgrade:
			var auto_button = Button.new()
			auto_button.text = "Auto-Roll $" + str(round(dice_copy.auto_roll_cost))
			auto_button.pressed.connect(func():
				if GameManager.currency >= dice_copy.auto_roll_cost:
					GameManager.currency -= dice_copy.auto_roll_cost
					dice_copy.has_auto_roll_upgrade = true
					print("Auto-roll unlocked for", dice_copy.dice_name)
					create_shop()
				else:
					print("Not enough money for auto-roll upgrade")
			)
			shop_container.add_child(auto_button)
