class_name TalentTree
extends PanelContainer
## Fate talents as a node tree over the table. Columns follow prerequisite depth and lines
## connect each talent to the one it needs. Click a node to buy a rank; hover to read it.

var session: GameSession
var on_prestige: Callable = func(): pass
var on_notice: Callable = func(_message: String): pass
var nodes: Dictionary = {}
var graph: Control
var fate_label: Label
var begin_button: Button
var info_name: Label
var info_text: Label
const NODE_SIZE := Vector2(52, 52)
const GOLD := Color("#f4ce83")
## Hand-placed [column, row] for the shipped talents so branches read left to right without
## overlaps; any new talent falls back to its prerequisite depth.
const LAYOUT: Dictionary = {"fortune": [0, 2], "crit": [1, 0], "house_edge": [2, 0], "stride": [1, 1],
	"old_friend": [2, 1], "muscle_memory": [3, 1], "echo": [1, 2], "head_start": [1, 3], "heirloom": [2, 3],
	"patience": [1, 4], "long_nights": [2, 4]}
const COLUMNS: int = 4
const ROWS: int = 5
const GRAPH_HEIGHT: float = 300.0

func setup(game: GameSession) -> void:
	session = game
	position = Vector2(36, 104)
	custom_minimum_size = Vector2(712, 420)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 30
	var column := VBoxContainer.new()
	add_child(column)
	var top := HBoxContainer.new()
	column.add_child(top)
	var title := Label.new()
	title.text = "FATE TALENTS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", GOLD)
	top.add_child(title)
	fate_label = Label.new()
	fate_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fate_label.add_theme_font_size_override("font_size", 16)
	fate_label.add_theme_color_override("font_color", Color("#c5b4df"))
	top.add_child(fate_label)
	begin_button = Button.new()
	begin_button.custom_minimum_size = Vector2(190, 40)
	begin_button.pressed.connect(func(): on_prestige.call())
	top.add_child(begin_button)
	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(70, 40)
	close.pressed.connect(hide)
	top.add_child(close)
	graph = Control.new()
	graph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph.custom_minimum_size = Vector2(0, GRAPH_HEIGHT)
	graph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	graph.draw.connect(_draw_links)
	column.add_child(graph)
	var info := HBoxContainer.new()
	column.add_child(info)
	info_name = Label.new()
	info_name.add_theme_color_override("font_color", GOLD)
	info.add_child(info_name)
	info_text = Label.new()
	info_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_text.add_theme_font_size_override("font_size", 13)
	info.add_child(info_text)
	_build_nodes()
	hide()

func _depth(id: String) -> int:
	var depth: int = 0
	var cursor: String = id
	while not session.registry.talents[cursor].prerequisite.is_empty() and depth < 8:
		cursor = session.registry.talents[cursor].prerequisite
		depth += 1
	return depth

func _build_nodes() -> void:
	var fallback_rows: Dictionary = {}
	for id in session.registry.talents:
		var cell: Array = LAYOUT.get(id, [])
		if cell.is_empty():
			var depth: int = mini(_depth(id), COLUMNS - 1)
			fallback_rows[depth] = int(fallback_rows.get(depth, ROWS)) + 1
			cell = [depth, (fallback_rows[depth] - 1) % ROWS]
		var x: float = 24.0 + (672.0 - NODE_SIZE.x) * float(cell[0]) / (COLUMNS - 1)
		var y: float = (GRAPH_HEIGHT - NODE_SIZE.y) * float(cell[1]) / (ROWS - 1)
		nodes[id] = _node_button(id, Vector2(x, y))

func _node_button(id: String, at: Vector2) -> Button:
	var button := Button.new()
	button.position = at
	button.size = NODE_SIZE
	button.custom_minimum_size = NODE_SIZE
	button.icon = ShopIcons.icon(id)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.add_theme_font_size_override("font_size", 11)
	button.toggle_mode = true
	button.mouse_entered.connect(func(): _explain(id))
	button.pressed.connect(func():
		_explain(id)
		if not session.progression.buy_upgrade(id, true):
			on_notice.call("Not enough Fate, or its prerequisite is missing.")
		refresh()
	)
	graph.add_child(button)
	return button

func _explain(id: String) -> void:
	var definition: UpgradeDefinition = session.registry.talents[id]
	var level: int = int(session.state.talents.get(id, 0))
	var needs: String = ""
	if not definition.prerequisite.is_empty() and int(session.state.talents.get(definition.prerequisite, 0)) == 0:
		needs = "  Needs %s first." % session.registry.talents[definition.prerequisite].display_name
	var cost: String = "Maxed" if level >= definition.max_level else "%s Fate" % NumberFormat.compact(session.economy.upgrade_price(definition))
	info_name.text = "%s  %d/%d  ·  %s   " % [definition.display_name, level, definition.max_level, cost]
	info_text.text = definition.description + needs

func _draw_links() -> void:
	for id in nodes:
		var definition: UpgradeDefinition = session.registry.talents[id]
		if definition.prerequisite.is_empty() or not nodes.has(definition.prerequisite):
			continue
		var from: Button = nodes[definition.prerequisite]
		var to: Button = nodes[id]
		var owned: bool = int(session.state.talents.get(definition.prerequisite, 0)) > 0
		graph.draw_line(from.position + NODE_SIZE * 0.5, to.position + NODE_SIZE * 0.5, GOLD if owned else Color(0.4, 0.38, 0.45), 3.0)

func open() -> void:
	refresh()
	info_name.text = "Click a talent to buy a rank."
	info_text.text = "Talents are permanent and survive every fresh start."
	show()

func refresh() -> void:
	var state: GameState = session.state
	fate_label.text = "%d Fate to spend" % state.prestige_points
	var reward: int = session.progression.fate_reward()
	begin_button.disabled = reward <= 0
	begin_button.text = "Begin again · +%d Fate" % reward if reward > 0 else "Fate at $%s" % NumberFormat.compact(ProgressionService.PRESTIGE_THRESHOLD)
	for id in nodes:
		var definition: UpgradeDefinition = session.registry.talents[id]
		var button: Button = nodes[id]
		var level: int = int(state.talents.get(id, 0))
		var needs_missing: bool = not definition.prerequisite.is_empty() and int(state.talents.get(definition.prerequisite, 0)) == 0
		button.text = "%d/%d" % [level, definition.max_level]
		button.set_pressed_no_signal(level >= definition.max_level)
		button.disabled = needs_missing
		var affordable: bool = state.prestige_points >= session.economy.upgrade_price(definition)
		button.modulate = Color(0.5, 0.5, 0.56) if needs_missing else (Color.WHITE if affordable or level >= definition.max_level else Color(0.75, 0.75, 0.8))
		button.tooltip_text = definition.display_name
	graph.queue_redraw()
