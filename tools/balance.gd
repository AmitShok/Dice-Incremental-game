extends SceneTree

func _initialize() -> void:
	var registry := ContentRegistry.new()
	var session := GameSession.new(registry)
	var roller := RollSystem.new(38)
	print("Definition,base_cost,expected_payout,auto_cost,base_auto_payback_seconds")
	for definition in registry.dice.values():
		var mean: float = session.economy.expected(definition, roller.weights_for(definition))
		print("%s,%.2f,%.3f,%.2f,%.2f" % [definition.id, definition.base_cost, mean, definition.auto_cost, definition.auto_cost / (mean / maxf(definition.auto_interval, definition.duration + 0.15))])
	quit()
