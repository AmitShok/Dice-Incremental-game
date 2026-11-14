class_name RoomLife
extends Node2D
## Idle and reactive room animation, drawn on the room's 2-screen-pixel art grid so it matches
## the pixel art. Idle: dust motes in the lamplight and flickering candle glow. Reactive:
## candles gust on rolls and burn hotter with the streak, felt dust puffs where dice land, a
## shelf chip stack that tracks chips held, brass glints on combos and big rolls, a table
## thump on combos and a ledger page flip on milestones.
## Respects the motion, flashes and particles settings and freezes while the session is paused.
## Purely visual: nothing here touches game state.

const ART := 2.0 # screen pixels per art pixel
const LAMP := Vector2(392, 300)
const DUST_AREA := Rect2(40, 92, 720, 430)
const CANDLES: Array[Vector2] = [Vector2(56, 70), Vector2(722, 70)] # flame base, screen px
const CHIP_BASE := Vector2(200, 576) # centre of the bottom chip on the shelf
const CHIP_MAX: int = 10
const LEDGER_SPINE := Vector2(92, 542)
const RAIL := Rect2(44, 104, 700, 22)
const WALLET := Rect2(432, 8, 264, 64)
const STREAK_TINT: Array[Color] = [Color(1, 1, 1), Color(1.1, 1.0, 0.85), Color(1.25, 1.05, 0.8), Color(1.4, 1.25, 1.0), Color(0.85, 1.1, 1.6)]
const CREAM := Color("#f0dfbd")
const GLOW := Color("#ffb45a")
const BRASS_HI := Color("#f5db9f")
const INK := Color("#0e0b10")
const CHIP_RED := Color("#b8433f")
const CHIP_RED_DARK := Color("#6e2522")
const CHIP_RED_HI := Color("#d65a52")
const PAPER := Color("#e9dcc0")
const PAPER_LINE := Color("#c9b996")

var session: GameSession
var flames: Array[Sprite2D] = []
var time: float = 0.0
var motes: Array[Dictionary] = []
var puffs: Array[Dictionary] = []
var gust: float = 0.0
var streak_stage: int = 0
var glints: Array[Dictionary] = []
var thump: float = 0.0
var thump_base: Vector2 = Vector2.ZERO
var page_flip: float = -1.0
var chip_drop: float = -1.0
var shown_chips: int = 0
var rng := RandomNumberGenerator.new()
## Candle light is added to the wall (additive blend) on its own layer, so it brightens what is
## underneath instead of painting a disc over it.
var glow_layer: Node2D

func setup(game: GameSession, left_flame: Sprite2D, right_flame: Sprite2D) -> void:
	session = game
	rng.seed = 38
	# Pivot the flames on their wick so they can lean and grow without drifting.
	for pair in [[left_flame, CANDLES[0]], [right_flame, CANDLES[1]]]:
		var flame: Sprite2D = pair[0]
		flame.centered = false
		flame.offset = Vector2(-8, -20)
		flame.position = pair[1]
		flames.append(flame)
	for index in 26:
		motes.append({"pos": Vector2(rng.randf_range(DUST_AREA.position.x, DUST_AREA.end.x), rng.randf_range(DUST_AREA.position.y, DUST_AREA.end.y)),
			"vel": Vector2(rng.randf_range(-5, 5), rng.randf_range(-7, -2)), "phase": rng.randf() * TAU})
	glow_layer = Node2D.new()
	glow_layer.name = "CandleGlow"
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow_layer.material = additive
	glow_layer.show_behind_parent = true
	glow_layer.draw.connect(_draw_candle_glow)
	add_child(glow_layer)
	thump_base = get_parent().position
	shown_chips = _chip_count()

func _settings() -> Dictionary:
	return session.state.settings

func _chip_count() -> int:
	return mini(CHIP_MAX, int(ceil(session.state.chips / 4.0)))

# --- Reactions (called by main) ---------------------------------------------------------

func on_table_roll() -> void:
	if _settings().get("motion", true):
		gust = 1.0

func on_land(at: Vector2, natural_one: bool) -> void:
	if _settings().get("particles", true) and _settings().get("motion", true) and puffs.size() < 60:
		for index in 5:
			var angle: float = rng.randf_range(0, TAU)
			puffs.append({"pos": at + Vector2(0, 14), "vel": Vector2(cos(angle) * rng.randf_range(18, 34), sin(angle) * rng.randf_range(6, 12)), "age": 0.0})
	if natural_one and _settings().get("motion", true) and _chip_count() > shown_chips:
		chip_drop = 0.0

func on_streak(stage: int) -> void:
	streak_stage = clampi(stage, 0, STREAK_TINT.size() - 1)

func on_combo() -> void:
	_glint(RAIL)
	if _settings().get("motion", true):
		thump = 1.0

func on_big_roll() -> void:
	_glint(WALLET)

func on_milestone() -> void:
	if _settings().get("motion", true):
		page_flip = 0.0

func _glint(area: Rect2) -> void:
	if _settings().get("flashes", true) and glints.size() < 4:
		glints.append({"area": area, "t": 0.0})

# --- Simulation ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	if session == null or session.paused:
		return
	var motion: bool = _settings().get("motion", true)
	time += delta
	if streak_stage > 0 and session.streak_stage() == 0:
		streak_stage = 0
	for mote in motes:
		if motion:
			mote.pos += mote.vel * delta
			mote.pos.x += sin(time * 0.7 + mote.phase) * 3.0 * delta
			if mote.pos.y < DUST_AREA.position.y:
				mote.pos = Vector2(rng.randf_range(DUST_AREA.position.x, DUST_AREA.end.x), DUST_AREA.end.y)
			if mote.pos.x < DUST_AREA.position.x or mote.pos.x > DUST_AREA.end.x:
				mote.pos.x = rng.randf_range(DUST_AREA.position.x, DUST_AREA.end.x)
	for index in range(puffs.size() - 1, -1, -1):
		var puff: Dictionary = puffs[index]
		puff.age += delta
		puff.pos += puff.vel * delta
		puff.vel *= 0.9
		if puff.age > 0.4:
			puffs.remove_at(index)
	for index in range(glints.size() - 1, -1, -1):
		glints[index].t += delta / 0.55
		if glints[index].t >= 1.0:
			glints.remove_at(index)
	gust = maxf(0.0, gust - delta * 1.6)
	if page_flip >= 0.0:
		page_flip += delta / 0.6
		if page_flip >= 1.0:
			page_flip = -1.0
	if chip_drop >= 0.0:
		chip_drop += delta / 0.35
		if chip_drop >= 1.0:
			chip_drop = -1.0
	if chip_drop < 0.0:
		shown_chips = _chip_count()
	_update_flames(motion)
	_update_thump(delta, motion)
	queue_redraw()
	glow_layer.queue_redraw()

func _update_flames(motion: bool) -> void:
	var tint: Color = STREAK_TINT[streak_stage]
	for index in flames.size():
		var flame: Sprite2D = flames[index]
		flame.modulate = tint
		if not motion:
			flame.scale = Vector2(2, 2)
			flame.skew = 0.0
			continue
		var grow: float = 1.0 + streak_stage * 0.07
		var flicker: float = 1.0 + sin(time * 9.0 + index * 2.1) * 0.03
		flame.scale = Vector2(2.0, 2.0 * grow * flicker)
		# A gust leans both flames away from the table, then they spring back upright.
		var lean: float = sin(gust * PI * 2.5) * gust * 0.45
		flame.skew = lean if index == 0 else -lean

func _update_thump(delta: float, motion: bool) -> void:
	var parent: Node2D = get_parent()
	if thump > 0.0 and motion:
		thump = maxf(0.0, thump - delta * 6.0)
		parent.position = thump_base + Vector2(0, ART * round(sin(thump * PI * 3.0)))
	elif parent.position != thump_base:
		parent.position = thump_base

# --- Drawing (everything snapped to the 2-pixel art grid) ---------------------------------

func _px(at: Vector2, color: Color, size: Vector2 = Vector2.ONE) -> void:
	draw_rect(Rect2((at / ART).floor() * ART, size * ART), color)

func _draw() -> void:
	if session == null:
		return
	if _settings().get("particles", true):
		_draw_dust()
		_draw_puffs()
	_draw_glints()
	_draw_chip_stack()
	_draw_page_flip()

func _draw_candle_glow() -> void:
	# Three flat, banded discs that breathe with the flame and widen with the streak.
	var boost: float = 1.0 + streak_stage * 0.18
	var tint: Color = STREAK_TINT[streak_stage]
	for index in CANDLES.size():
		var flicker: float = 1.0 + (sin(time * 7.3 + index * 1.7) + sin(time * 13.1 + index)) * 0.04
		var centre: Vector2 = CANDLES[index] + Vector2(0, -14)
		for band in [[30.0, 0.06], [20.0, 0.07], [11.0, 0.09]]:
			var radius: float = round(band[0] * boost * flicker / ART) * ART
			var color: Color = Color(GLOW.r * tint.r, GLOW.g * tint.g, GLOW.b * tint.b, band[1])
			glow_layer.draw_circle(centre, radius, color)

func _draw_dust() -> void:
	for mote in motes:
		var lamp: float = clampf(1.0 - mote.pos.distance_to(LAMP) / 420.0, 0.0, 1.0)
		var twinkle: float = 0.5 + 0.5 * sin(time * 1.8 + mote.phase)
		# alpha in three flat steps so motes read as pixels, not soft blobs
		var level: float = floor((lamp * 0.7 + twinkle * 0.3) * 3.0) / 3.0
		if level > 0.0:
			_px(mote.pos, Color(CREAM, 0.12 + level * 0.28))

func _draw_puffs() -> void:
	for puff in puffs:
		var fade: float = 1.0 - puff.age / 0.4
		_px(puff.pos, Color(0.72, 0.84, 0.76, 0.5 if fade > 0.5 else 0.25))

func _draw_glints() -> void:
	# A diagonal band of brass highlight sweeping left to right across the area.
	for glint in glints:
		var area: Rect2 = glint.area
		var x0: float = lerpf(area.position.x - 20, area.end.x + 20, glint.t)
		var y: float = area.position.y
		while y < area.end.y:
			var x: float = x0 - (y - area.position.y) * 0.6
			if x >= area.position.x and x + 6 <= area.end.x:
				_px(Vector2(x, y), Color(BRASS_HI, 0.75), Vector2(3, 1))
			y += ART

## One row of art pixels from x = -half to +half around `at` (screen px, snapped to the grid).
func _row(at: Vector2, y: int, half: int, color: Color) -> void:
	draw_rect(Rect2(at + Vector2(-half * ART, y * ART), Vector2((half * 2 + 1) * ART, ART)), color)

## A stack of `count` house chips standing on `base` (centre of the bottom edge): each chip
## shows its 2-pixel edge (red with cream notches, a dark seam below), the top chip shows its
## face (red with a cream ring), and one outline wraps the whole stack.
func _draw_stack(base: Vector2, count: int) -> void:
	if count <= 0:
		return
	var b: Vector2 = (base / ART).floor() * ART
	var top: int = -count * 2 # first edge row of the top chip
	# outline: a rounded column wrapping the edges and the top face
	_row(b, 1, 5, INK)
	for y in range(top - 2, 1):
		_row(b, y, 7, INK)
	_row(b, top - 3, 5, INK)
	# chip edges, bottom up
	for index in count:
		var y: int = -index * 2
		_row(b, y, 6, CHIP_RED_DARK)
		_row(b, y - 1, 6, CHIP_RED)
		for x in [-4, 0, 4]:
			draw_rect(Rect2(b + Vector2(x * ART, (y - 1) * ART), Vector2(ART, ART)), CREAM)
	# top face: lit rim at the back, cream ring, red centre
	_row(b, top - 2, 5, CHIP_RED_HI)
	_row(b, top - 1, 6, CHIP_RED)
	_row(b, top - 1, 4, CREAM)
	_row(b, top - 1, 2, CHIP_RED)
	draw_rect(Rect2(b + Vector2(-3 * ART, (top - 2) * ART), Vector2(ART * 2, ART)), Color("#f08a80"))

func _draw_chip_stack() -> void:
	var count: int = shown_chips
	_draw_stack(CHIP_BASE, count)
	if chip_drop >= 0.0:
		# The new chip falls onto the stack and settles with a small bounce.
		var land: Vector2 = CHIP_BASE - Vector2(0, count * 2 * ART)
		var t: float = chip_drop
		var height: float = (1.0 - t * t) * 40.0 if t < 0.75 else sin((t - 0.75) / 0.25 * PI) * 4.0
		_draw_stack(land - Vector2(0, height), 1)

func _draw_page_flip() -> void:
	if page_flip < 0.0:
		return
	# The right-hand page swings over the spine to the left.
	var width: float = cos(page_flip * PI) * 34.0
	var top: float = LEDGER_SPINE.y
	var rect := Rect2(LEDGER_SPINE.x, top, width, 38) if width >= 0 else Rect2(LEDGER_SPINE.x + width, top, -width, 38)
	rect.position = (rect.position / ART).floor() * ART
	rect.size = (rect.size / ART).ceil() * ART
	if rect.size.x < ART:
		return
	draw_rect(rect.grow(ART), INK)
	draw_rect(rect, PAPER)
	var y: float = rect.position.y + 6
	while y < rect.end.y - 4 and rect.size.x > 6:
		draw_rect(Rect2(rect.position.x + 4, y, rect.size.x - 8, ART), PAPER_LINE)
		y += 6
