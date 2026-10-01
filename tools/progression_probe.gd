extends SceneTree

func _initialize() -> void:
	var catalog := ContentRegistry.new()
	var session := GameSession.new(catalog)
	session.roller.rng.seed = 38
	var first_helper: float = -1
	var first_fate: float = -1
	var first_combo: float = -1
	var step: float = 0.1
	var throw_clock: float = 0
	for iteration in 18000:
		var seconds: float = iteration * step
		session.tick(step)
		throw_clock += step
		if throw_clock >= 1.2:
			throw_clock = 0
			var ids: Array = []
			for die in session.state.dice:
				ids.append(die.id)
			session.request_roll(ids)
		# Deterministic example buyer; a balancing probe, not a claim about human play.
		if session.state.helpers == 0 and session.state.money >= 250:
			session.progression.hire_helper()
			if session.state.helpers > 0:
				first_helper = seconds
		elif int(session.state.upgrades.get("combos", 0)) == 0 and session.state.money >= 400:
			session.progression.buy_upgrade("combos")
			if int(session.state.upgrades.get("combos", 0)) > 0:
				first_combo = seconds
		else:
			for id in ["d4", "d6", "d8", "d10", "d12", "d20"]:
				if int(session.state.counts.get(id, 0)) < 3 and session.state.money >= session.economy.die_price(id):
					session.progression.buy_die(id)
					break
		if session.progression.fate_reward() > 0:
			first_fate = seconds
			break
	print("PROGRESSION PROBE: throw every 1.2s; helper at ", first_helper, "s; combinations at ", first_combo, "s; first Fate at ", first_fate, "s; dice=", session.state.dice.size(), "; earned=", session.state.run_earned)
	quit()
