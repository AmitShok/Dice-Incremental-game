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

func _ready() -> void:
	z_index = 20
	for index in 40:
		var label := Label.new()
		label.visible = false
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color("#ffe0a0"))
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
		label.position = at + Vector2(-25, -25)
		label.modulate = Color.WHITE
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
