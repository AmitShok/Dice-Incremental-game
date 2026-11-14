class_name ShopIcons
extends RefCounted
## Icon lookup for shop rows. Frames are 16×16 cells in assets/exported/icons/shop_icons.png,
## in the order drawn by tools/create_icons.lua.

const ORDER: Array[String] = ["heavy", "sixes", "loaded", "combos", "hands", "rhythm", "chain", "momentum",
	"strong_arms", "sharp_eyes", "many_hands", "hire", "fortune", "crit", "stride", "echo", "head_start",
	"heirloom", "patience", "long_nights", "old_friend", "muscle_memory", "house_edge", "prestige", "chip",
	"capsule", "lock", "none", "mix", "up", "table", "book", "gear"]
const SHEET: Texture2D = preload("res://assets/exported/icons/shop_icons.png")
const HATS: Texture2D = preload("res://assets/exported/helpers/hats.png")
static var _cache: Dictionary = {}

static func icon(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var index: int = ORDER.find(id)
	if index < 0:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET
	atlas.region = Rect2(index * 16, 0, 16, 16)
	_cache[id] = atlas
	return atlas

## A die's highest face, used as its shop icon.
static func die(definition: DiceDefinition) -> Texture2D:
	var key: String = "die:" + definition.id
	if not _cache.has(key):
		var atlas := AtlasTexture.new()
		atlas.atlas = definition.texture
		atlas.region = Rect2((definition.sides - 1) * 32, 0, 32, 32)
		atlas.filter_clip = true
		_cache[key] = atlas
	return _cache[key]

static func hat(id: String) -> Texture2D:
	if not Cosmetics.HATS.has(id):
		return icon("none" if id.is_empty() else "mix")
	var key: String = "hat:" + id
	if not _cache.has(key):
		var atlas := AtlasTexture.new()
		atlas.atlas = HATS
		atlas.region = Rect2(Cosmetics.HATS[id].frame * 16, 0, 16, 12)
		_cache[key] = atlas
	return _cache[key]

const RARITY_COLORS: Dictionary = {"common": Color("#d9d2c0"), "rare": Color("#7fb8ff"), "legendary": Color("#ffcf5a")}
