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
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color("#fff4dc"))
		label.add_theme_color_override("font_outline_color", Color("#120d10"))
		label.add_theme_constant_override("outline_size", 6)
		label.add_theme_color_override("font_shadow_color", Color("#172c2b"))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		add_child(label)
		labels.append(label)
	for index in 80:
		var spark := Sprite2D.new()
		spark.texture = preload("res://assets/exported/effects/spark.png")
		spark.visible = false
		spark.scale = Vector2(0.6, 0.6)
		add_child(spark)
		sparks.append(spark)

func payout(amount: float, at: Vector2, exceptional: bool = false) -> void:
	if settings.get("numbers", true):
		var label: Label = labels[cursor]
		cursor = (cursor + 1) % labels.size()
		_remove_existing(label)
		label.text = "+$" + NumberFormat.compact(amount)
		# Bigger wins get bigger numbers, so jackpots read at a glance.
		var size: int = int(clampf(16.0 + log(maxf(1.0, amount)) / log(10.0) * 3.0, 16.0, 34.0))
		label.add_theme_font_size_override("font_size", size + (6 if exceptional else 0))
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
	label.add_theme_font_size_override("font_size", 16)
	label.position = at + Vector2(-28, -40)
	label.modulate = color
	label.visible = true
	active.append({"node": label, "age": 0.0, "velocity": Vector2(0, -28), "duration": 0.9})

func _draw() -> void:
	for burst in bursts:
		var t: float = burst.age / burst.duration
		var color: Color = EFFECT_COLORS.get(burst.action, Color.WHITE)
		color.a = 1.0 - t
		match burst.action:
			"arc":
				for target in burst.targets:
					# A jagged bolt: deterministic zig-zag between source and target.
					var points := PackedVector2Array()
					var from: Vector2 = burst.from
					var to: Vector2 = target
					var normal: Vector2 = (to - from).orthogonal().normalized()
					for step in 7:
						var k: float = step / 6.0
						var jitter: float = 0.0 if step == 0 or step == 6 else (7.0 if step % 2 == 0 else -7.0)
						points.append(from.lerp(to, k) + normal * jitter)
					draw_polyline(points, color, 3.0)
					draw_polyline(points, Color(1, 1, 1, color.a), 1.0)
			"blast":
				draw_arc(burst.from, 20.0 + 120.0 * t, 0, TAU, 40, color, 4.0 * (1.0 - t) + 1.0)
			"gild":
				draw_arc(burst.from, 15.0 + 105.0 * t, 0, TAU, 32, color, 2.0)
				for target in burst.targets:
					draw_circle(target, 18.0 * (1.0 - t) + 4.0, Color(color.r, color.g, color.b, color.a * 0.35))
			"reroll":
				for target in burst.targets:
					draw_line(burst.from, target, color, 2.0)

func _tick_bursts(delta: float) -> void:
	if bursts.is_empty():
		return
	for index in range(bursts.size() - 1, -1, -1):
		bursts[index].age += delta
		if bursts[index].age >= bursts[index].duration:
			bursts.remove_at(index)
	queue_redraw()
