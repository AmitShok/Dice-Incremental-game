class_name ShopIcons
extends RefCounted
## Icon lookup for shop rows. Frames are 16×16 cells in assets/exported/icons/shop_icons.png,
## in the order drawn by tools/create_icons.lua.

const ORDER: Array[String] = ["heavy", "sixes", "loaded", "combos", "hands", "rhythm", "chain", "momentum",
	"strong_arms", "sharp_eyes", "many_hands", "hire", "fortune", "crit", "stride", "echo", "head_start",
	"heirloom", "patience", "long_nights", "old_friend", "muscle_memory", "house_edge", "prestige", "chip",
	"capsule", "lock", "none", "mix", "up", "table", "book", "gear",
	"golden_touch", "crit_chance", "crit_power", "deep_fortune", "endless_favor", "destiny", "well_paid", "bargain", "haggler",
	"born_harmony", "perfect_harmony", "chip_collector", "hot_hands", "fire_within", "quick_hands", "night_shift", "weighted_fate",
	"chip_hoard", "hat_trick", "divine"]
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

## Frame order of assets/exported/icons/dice_icons.png (written by tools/create_dice_hd.lua).
const DICE_ORDER: Array[String] = ["d4", "d6", "d8", "d10", "d12", "d20", "golden_d6", "lucky_d6", "exploding_d6",
	"multiplier_d6", "spark_d8", "blast_d10", "gild_d12"]
const DICE_SHEET: Texture2D = preload("res://assets/exported/icons/dice_icons.png")

## A die's 16 px icon showing its highest face, the same pixel size as every other icon.
## Dice without an icon frame fall back to a crop of their face sheet.
static func die(definition: DiceDefinition) -> Texture2D:
	var key: String = "die:" + definition.id
	if not _cache.has(key):
		var atlas := AtlasTexture.new()
		var index: int = DICE_ORDER.find(definition.id)
		if index >= 0:
			atlas.atlas = DICE_SHEET
			atlas.region = Rect2(index * 16, 0, 16, 16)
		else:
			atlas.atlas = definition.texture
			atlas.region = Rect2((definition.sides - 1) * 32, 0, 32, 32)
		atlas.filter_clip = true
		_cache[key] = atlas
	return _cache[key]

## Every icon in the game draws at exactly 2x (one art pixel on two screen pixels), like the
## room, dice and helpers. Use this instead of stretching a texture to fill a button.
static func picture(texture: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = "Picture"
	rect.texture = texture
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.size = texture.get_size() * 2.0 if texture != null else Vector2.ZERO
	rect.custom_minimum_size = rect.size
	return rect

## Puts `texture` on `button` at exactly 2x, centred (or at `top` from the top edge).
static func set_button_picture(button: Button, texture: Texture2D, top: float = -1.0) -> void:
	var old: Node = button.get_node_or_null("Picture")
	if old != null:
		old.free()
	button.icon = null
	if texture == null:
		return
	var rect: TextureRect = picture(texture)
	button.add_child(rect)
	rect.set_anchors_preset(Control.PRESET_CENTER if top < 0.0 else Control.PRESET_CENTER_TOP)
	rect.offset_left = -rect.size.x * 0.5
	rect.offset_right = rect.size.x * 0.5
	rect.offset_top = -rect.size.y * 0.5 if top < 0.0 else top
	rect.offset_bottom = rect.offset_top + rect.size.y

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
