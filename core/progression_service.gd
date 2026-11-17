class_name ProgressionService
extends RefCounted

const PRESTIGE_THRESHOLD: float = 100000.0
# Fate = floor(sqrt(run earnings / FATE_SCALE) × House edge); reaching the threshold grants 2.
const FATE_SCALE: float = 25000.0
const MAX_FATE: int = 1000000000

var state: GameState
var registry: ContentRegistry
var economy: EconomyService
var events: GameEvents

func _init(s: GameState, r: ContentRegistry, e: EconomyService, bus: GameEvents) -> void:
	state = s
	registry = r
	economy = e
	events = bus

func buy_die(id: String) -> bool:
	if not registry.dice.has(id) or state.dice.size() >= GameState.MAX_DICE:
		return false
	var definition: DiceDefinition = registry.dice[id]
	if state.run_earned < definition.unlock_earned or not economy.spend(economy.die_price(id)):
		return false
	var at: Vector2 = _open_position()
	state.add_die(id, at)
	StatisticsService.increment(state, "dice_purchased")
	state.tutorial_step = maxi(state.tutorial_step, 2)
	events.purchased.emit("dice", id)
	events.changed.emit()
	return true

func _open_position() -> Vector2:
	var best := Vector2(135, 210)
	var widest: float = -1.0
	# A staggered (honeycomb) grid of 14 x 9 = 126 spots, evenly spaced in both directions so a
	# full table packs evenly instead of stacking dice in columns. Kept clear of the felt's corner
	# brackets and rails so new dice (and their name tags) always land on open felt.
	for index in 126:
		var row: int = int(index / 14)
		var candidate := Vector2(100 + index % 14 * 43 + (21 if row % 2 == 1 else 0), 180 + row * 35)
		var distance: float = INF
		for die in state.dice:
			distance = minf(distance, candidate.distance_squared_to(die.position))
		if distance > widest:
			widest = distance
			best = candidate
	return best

func buy_upgrade(id: String, permanent: bool = false) -> bool:
	var catalog: Dictionary = registry.talents if permanent else registry.upgrades
	var levels: Dictionary = state.talents if permanent else state.upgrades
	if not catalog.has(id):
		return false
	var definition: UpgradeDefinition = catalog[id]
	if int(levels.get(id, 0)) >= definition.max_level:
		return false
	if state.run_earned < definition.unlock_earned and not permanent:
		return false
	if not definition.prerequisite.is_empty() and int(levels.get(definition.prerequisite, 0)) == 0:
		return false
	var price: float = economy.upgrade_price(definition)
	if permanent:
		if state.prestige_points < price:
			return false
		state.prestige_points -= int(price)
	elif not economy.spend(price):
		return false
	levels[id] = int(levels.get(id, 0)) + 1
	if permanent:
		apply_talent_grants()
	StatisticsService.increment(state, "upgrades_purchased")
	events.purchased.emit("talent" if permanent else "upgrade", id)
	events.changed.emit()
	return true

## Talents that make a shop upgrade permanent: owning the talent gives the upgrade for free in
## every run (the shop shows it as owned), instead of leaving a now-useless purchase on offer.
const TALENT_GRANTS: Dictionary = {"born_harmony": "combos", "sharp_crew": "sharp_eyes"}

## Gives the upgrades granted by owned talents. Called when a talent is bought, after a fresh
## start clears the run's upgrades, and when a session loads.
func apply_talent_grants() -> void:
	for talent in TALENT_GRANTS:
		var upgrade: String = TALENT_GRANTS[talent]
		if int(state.talents.get(talent, 0)) > 0 and registry.upgrades.has(upgrade):
			state.upgrades[upgrade] = maxi(int(state.upgrades.get(upgrade, 0)), registry.upgrades[upgrade].max_level)

func helper_price() -> float:
	return 250.0 * pow(2.8, state.helpers)

func hire_helper() -> bool:
	if state.helpers >= GameState.MAX_HELPERS or state.run_earned < 150 or not economy.spend(helper_price()):
		return false
	state.helpers += 1
	StatisticsService.increment(state, "helpers_hired")
	events.purchased.emit("helper", "croupier")
	events.changed.emit()
	return true

## Run earnings needed to begin again for Fate. It rises with every fresh start: $100K for the
## first, $200K for the second, $300K for the third and so on (PRESTIGE_THRESHOLD x starts + 1).
func prestige_threshold() -> float:
	return minf(GameState.MAX_AMOUNT, PRESTIGE_THRESHOLD * (1.0 + fresh_starts()))

## Fresh starts taken so far (lifetime statistic; survives every reset except a full wipe).
func fresh_starts() -> int:
	return int(state.statistics.get("prestiges", 0.0))

func fate_reward() -> int:
	if state.run_earned < prestige_threshold():
		return 0
	var raw: float = floor(sqrt(state.run_earned / FATE_SCALE) * economy.modifier("fate_gain") + 1e-9)
	return int(minf(MAX_FATE - state.prestige_total, raw))

## Run earnings needed for one more Fate than fate_reward() currently gives.
func next_fate_at() -> float:
	var target: float = fate_reward() + 1
	return minf(GameState.MAX_AMOUNT, maxf(prestige_threshold(), FATE_SCALE * pow(target / economy.modifier("fate_gain"), 2)))

## Head start: $500 × 10^(level − 1); nothing without the talent.
func starting_cash() -> float:
	var bonus: float = economy.modifier("starting_cash")
	return 50.0 * bonus if bonus > 1.0 else 0.0

## Text describing what talents carry into the next run, for the confirmation dialog.
func carryover_summary() -> String:
	var parts: PackedStringArray = []
	if starting_cash() > 0:
		parts.append("$" + NumberFormat.compact(starting_cash()))
	if _talent_count("starting_dice") > 0:
		parts.append("%d extra D6" % _talent_count("starting_dice"))
	var kept: int = state.helpers if _talent_count("keep_helpers") > 0 else 0
	var extra: int = _talent_count("starting_helpers")
	if kept > 0:
		parts.append(("all %d of your helpers" % kept) + (" plus %d more" % extra if extra > 0 else ""))
	elif extra > 0:
		parts.append("%d helper%s" % [extra, "" if extra == 1 else "s"])
	for talent in TALENT_GRANTS:
		if int(state.talents.get(talent, 0)) > 0 and registry.upgrades.has(TALENT_GRANTS[talent]):
			parts.append(registry.upgrades[TALENT_GRANTS[talent]].display_name)
	return "" if parts.is_empty() else "\nYour talents start the next run with " + ", ".join(parts) + "."

func _talent_count(stat: String) -> int:
	return maxi(0, roundi(economy.modifier(stat) - 1.0))

func prestige() -> bool:
	var reward: int = fate_reward()
	if reward < 1 or not registry.dice.has("d6"):
		return false
	state.prestige_points += reward
	state.prestige_total += reward
	state.money = 0
	state.run_earned = 0
	state.dice.clear()
	state.counts.clear()
	state.upgrades.clear()
	apply_talent_grants()
	var kept_helpers: int = state.helpers if _talent_count("keep_helpers") > 0 else 0
	state.helpers = 0
	state.tutorial_step = 2
	state.add_die("d6", Vector2(395, 310))
	# Talents survive the reset, so their run-start bonuses apply after run upgrades are cleared.
	state.money = starting_cash()
	for index in _talent_count("starting_dice"):
		state.add_die("d6", _open_position())
	var kept: int = kept_helpers
	# Old friends adds its helpers on top of the crew Loyal crew keeps.
	state.helpers = mini(GameState.MAX_HELPERS, kept + _talent_count("starting_helpers"))
	StatisticsService.increment(state, "prestiges")
	events.prestige_completed.emit()
	events.changed.emit()
	return true

# --- Capsule machine (cosmetic; never touches the payout RNG) ------------------
var cosmetic_rng := RandomNumberGenerator.new()

## Spends chips for a random hat. Returns the hat id, or "" if unaffordable.
## Duplicates refund some chips; the first hat is worn automatically.
func pull_capsule() -> String:
	if state.chips < Cosmetics.CAPSULE_COST:
		return ""
	state.chips -= Cosmetics.CAPSULE_COST
	var hat: String = Cosmetics.draw(cosmetic_rng)
	if state.hats.has(hat):
		state.chips += Cosmetics.DUPLICATE_REFUND
	else:
		state.hats.append(hat)
		if state.crew_hat.is_empty():
			state.crew_hat = hat
	StatisticsService.increment(state, "capsules")
	events.purchased.emit("capsule", hat)
	events.changed.emit()
	return hat

## "" = no hats, "mix" = each helper wears a different owned hat, otherwise an owned hat id.
func wear_hat(id: String) -> bool:
	if not (id.is_empty() or id == "mix" or state.hats.has(id)):
		return false
	state.crew_hat = id
	events.changed.emit()
	return true
