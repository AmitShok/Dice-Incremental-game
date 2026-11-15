@tool
class_name TalentLinks
extends Control
## The talent tree's map: holds the TalentNode children at their positions and draws the links
## between them (from each node's prerequisite) in 2 px blocks on the art grid. Runs in the
## editor too, so moving a talent in talent_tree.tscn updates its links live.

const GOLD := Color("#f4ce83")
const UNOWNED := Color(0.36, 0.34, 0.42)
const BED := Color(0, 0, 0, 0.45)

## Talent ids the player owns at least one rank of; their outgoing links draw gold.
var owned: Dictionary = {}

func _ready() -> void:
	child_order_changed.connect(queue_redraw)
	set_process(Engine.is_editor_hint())

func _process(_delta: float) -> void:
	# In the editor, redraw as talents are dragged around.
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	for child in get_children():
		var node := child as TalentNode
		if node == null or node.prerequisite.is_empty() or not has_node(node.prerequisite):
			continue
		var from_node: Control = get_node(node.prerequisite)
		var from: Vector2 = from_node.position + from_node.size * 0.5
		var to: Vector2 = node.position + node.size * 0.5
		_pixel_line(from, to, BED, 3)
		_pixel_line(from, to, GOLD if owned.has(node.prerequisite) else UNOWNED, 1)

func _pixel_line(from: Vector2, to: Vector2, color: Color, size: int) -> void:
	var steps: int = maxi(1, int(ceil(maxf(absf(to.x - from.x), absf(to.y - from.y)) / 2.0)))
	for index in steps + 1:
		var at: Vector2 = (from.lerp(to, float(index) / steps) / 2.0).floor() * 2.0 - Vector2.ONE * (size - 1)
		draw_rect(Rect2(at, Vector2.ONE * 2.0 * size), color)
