class_name Cosmetics
extends RefCounted

## Helper hats from the capsule machine. Purely cosmetic; frame = column in helpers/hats.png.
const HATS: Dictionary = {
	"cone": {"name": "Party cone", "rarity": "common", "frame": 0},
	"beret": {"name": "Painter's beret", "rarity": "common", "frame": 1},
	"cap": {"name": "Felt cap", "rarity": "common", "frame": 2},
	"flower": {"name": "Daisy", "rarity": "common", "frame": 3},
	"tophat": {"name": "Top hat", "rarity": "rare", "frame": 4},
	"wizard": {"name": "Star hat", "rarity": "rare", "frame": 5},
	"crown": {"name": "Tiny crown", "rarity": "legendary", "frame": 6},
	"halo": {"name": "Halo", "rarity": "legendary", "frame": 7},
}
const WEIGHTS: Dictionary = {"common": 70.0, "rare": 25.0, "legendary": 5.0}
const CAPSULE_COST: int = 25
const DUPLICATE_REFUND: int = 10

## Weighted random hat id using the provided generator (never the payout RNG).
static func draw(rng: RandomNumberGenerator) -> String:
	var total: float = 0.0
	for id in HATS:
		total += WEIGHTS[HATS[id].rarity]
	var pick: float = rng.randf() * total
	for id in HATS:
		pick -= WEIGHTS[HATS[id].rarity]
		if pick <= 0.0:
			return id
	return HATS.keys().back()

## Hat id worn by helper `index` given the crew setting; "" means bare-headed.
static func hat_for(state: GameState, index: int) -> String:
	if state.crew_hat == "mix" and not state.hats.is_empty():
		return state.hats[index % state.hats.size()]
	return state.crew_hat if state.hats.has(state.crew_hat) else ""
