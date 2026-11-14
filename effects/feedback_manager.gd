class_name FeedbackManager
extends Node2D
var settings: Dictionary
var labels: Array[Label] = []
var sparks: Array[Sprite2D] = []
var cursor: int = 0
var spark_cursor: int = 0
var active: Array[Dictionary] = []
var aggregate: float = 0.0
var aggregate_clock: float = 0.0
## Text over the table uses the pixel font with its outline baked in (bitmap fonts cannot use
## outline_size). Sizes are whole multiples of the font's 6 px base so pixels stay square.
const TABLE_FONT: FontFile = preload("res://assets/fonts/d_infinity_pixel_outline.fnt")
const FONT_STEP: int = 6

func accumulate(amount: float) -> void:
	aggregate += amount

func clear() -> void:
	for item in active:
		item.node.visible = false
	active.clear()
	aggregate = 0.0
	bursts.clear()
	queue_redraw()

func _ready() -> void:
	z_index = 20
	for index in 40:
		var label := Label.new()
		label.visible = false
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_override("font", TABLE_FONT)
		label.add_theme_font_size_override("font_size", FONT_STEP * 2)
		label.add_theme_color_override("font_color", Color("#fff4dc"))
		label.add_theme_color_override("font_shadow_color", Color("#172c2b"))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		add_child(label)
		labels.append(label)
	for index in 80:
		var spark := Sprite2D.new()
		spark.texture = preload("res://assets/exported/effects/spark.png")
		spark.visible = false
		spark.scale = Vector2(2, 2) # 9x9 sparkle on the 2x art grid
		add_child(spark)
		sparks.append(spark)

func payout(amount: float, at: Vector2, exceptional: bool = false) -> void:
	if settings.get("numbers", true):
		var label: Label = labels[cursor]
		cursor = (cursor + 1) % labels.size()
		_remove_existing(label)
		label.text = "+$" + NumberFormat.compact(amount)
		# Bigger wins get bigger numbers in whole pixel steps: 2x under $1K, 3x under $1M, 4x
		# under $1B, 5x beyond; max and critical rolls go one step up.
		var tier: int = clampi(2 + int(floor(log(maxf(1.0, amount)) / log(1000.0))), 2, 5) + (1 if exceptional else 0)
		label.add_theme_font_size_override("font_size", FONT_STEP * mini(tier, 6))
		label.modulate = Color("#ffd86b") if exceptional else Color.WHITE
		label.position = at + Vector2(-25, -25)
		label.visible = true
		active.append({"node": label, "age": 0.0, "velocity": Vector2(0, -36), "duration": 1.0})
	if exceptional and settings.get("particles", true):
		for index in 8:
			var spark: Sprite2D = sparks[spark_cursor]
			spark_cursor = (spark_cursor + 1) % sparks.size()
			_remove_existing(spark)
			spark.position = at
			spark.modulate = Color.WHITE
			spark.visible = true
			active.append({"node": spark, "age": 0.0, "velocity": Vector2.from_angle(index * TAU / 8) * 65, "duration": 0.55})

func _remove_existing(node: CanvasItem) -> void:
	for index in range(active.size() - 1, -1, -1):
		if active[index].node == node:
			active.remove_at(index)

func _process(delta: float) -> void:
	_tick_bursts(delta)
	aggregate_clock += delta
	if aggregate_clock >= 0.25:
		aggregate_clock = 0.0
		if aggregate > 0:
			payout(aggregate, Vector2(660, 545))
			aggregate = 0.0
	for index in range(active.size() - 1, -1, -1):
		var item: Dictionary = active[index]
		item.age += delta
		if settings.get("motion", true):
			item.node.position += item.velocity * delta
		item.node.modulate.a = maxf(0, 1 - item.age / item.duration)
		if item.age >= item.duration:
			item.node.visible = false
			active.remove_at(index)

# --- Spreading-effect visuals (drawn with _draw; pooled by a small bounded list) ---
const EFFECT_COLORS: Dictionary = {"arc": Color("#8fe3ff"), "blast": Color("#ff9a5a"), "gild": Color("#ffd86b"), "reroll": Color("#f4ce83")}
var bursts: Array[Dictionary] = []

func effect(action: String, from: Vector2, targets: Array) -> void:
	if not settings.get("particles", true):
		return
	if bursts.size() >= 24:
		bursts.pop_front()
	bursts.append({"action": action, "from": from, "targets": targets.duplicate(), "age": 0.0, "duration": 0.6 if action != "blast" else 0.5})
	if action == "gild":
		for target in targets:
			payout_text("GILDED", target, Color("#ffd86b"))
	queue_redraw()

func payout_text(text: String, at: Vector2, color: Color) -> void:
	if not settings.get("numbers", true):
		return
	var label: Label = labels[cursor]
	cursor = (cursor + 1) % labels.size()
	_remove_existing(label)
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_STEP * 2)
	label.position = at + Vector2(-28, -40)
	label.modulate = color
	label.visible = true
	active.append({"node": label, "age": 0.0, "velocity": Vector2(0, -28), "duration": 0.9})

## Effects draw on the room's 2-screen-pixel art grid in flat blocks, and fade in three steps,
## so they read as pixel art like everything else rather than smooth vector lines.
const PX := 2.0

func _block(at: Vector2, color: Color, size: int = 1) -> void:
	draw_rect(Rect2((at / PX).floor() * PX, Vector2.ONE * PX * size), color)

func _pixel_line(from: Vector2, to: Vector2, color: Color, size: int = 1) -> void:
	var steps: int = maxi(1, int(ceil(maxf(absf(to.x - from.x), absf(to.y - from.y)) / PX)))
	for index in steps + 1:
		_block(from.lerp(to, float(index) / steps), color, size)

func _pixel_ring(centre: Vector2, radius: float, color: Color, size: int = 1) -> void:
	var count: int = maxi(8, int(ceil(TAU * radius / PX)))
	for index in count:
		_block(centre + Vector2.from_angle(TAU * index / count) * radius, color, size)

## A small four-point sparkle centred on `at`.
func _pixel_sparkle(at: Vector2, color: Color, arm: int) -> void:
	_block(at, Color(1, 1, 1, color.a))
	for step in range(1, arm + 1):
		for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			_block(at + direction * step * PX, color)

func _draw() -> void:
	for burst in bursts:
		var t: float = burst.age / burst.duration
		var color: Color = EFFECT_COLORS.get(burst.action, Color.WHITE)
		color.a = ceilf((1.0 - t) * 3.0) / 3.0
		var core := Color(1, 1, 1, color.a)
		match burst.action:
			"arc":
				for target in burst.targets:
					# A jagged bolt: deterministic zig-zag between source and target, a coloured
					# body two art pixels wide with a white core.
					var from: Vector2 = burst.from
					var to: Vector2 = target
					var normal: Vector2 = (to - from).orthogonal().normalized()
					var points: Array[Vector2] = []
					for step in 7:
						var k: float = step / 6.0
						var jitter: float = 0.0 if step == 0 or step == 6 else (8.0 if step % 2 == 0 else -8.0)
						points.append(from.lerp(to, k) + normal * jitter)
					for index in points.size() - 1:
						_pixel_line(points[index] - Vector2(PX, PX) * 0.5, points[index + 1] - Vector2(PX, PX) * 0.5, color, 2)
					for index in points.size() - 1:
						_pixel_line(points[index], points[index + 1], core)
			"blast":
				# An expanding shock ring: thick at first, thinning as it spreads.
				var radius: float = 20.0 + 120.0 * t
				_pixel_ring(burst.from, radius, color, 2 if t < 0.5 else 1)
				if t < 0.35:
					_pixel_ring(burst.from, radius * 0.6, core)
			"gild":
				_pixel_ring(burst.from, 15.0 + 105.0 * t, color)
				for target in burst.targets:
					_pixel_sparkle(target, color, 1 + int((1.0 - t) * 3.0))
			"reroll":
				for target in burst.targets:
					_pixel_line(burst.from, target, color)

func _tick_bursts(delta: float) -> void:
	if bursts.is_empty():
		return
	for index in range(bursts.size() - 1, -1, -1):
		bursts[index].age += delta
		if bursts[index].age >= bursts[index].duration:
			bursts.remove_at(index)
	queue_redraw()
