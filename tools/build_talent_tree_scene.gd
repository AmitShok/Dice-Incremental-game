extends SceneTree
## Builds scenes/ui/talent_tree.tscn: the Fate talent tree popup with one TalentNode instance per
## talent, placed on a grid from each talent's tree_position (Fortune in the middle).
## Run after adding talents or to reset the layout (this replaces hand edits to the scene):
##   GODOT --headless --path . --script res://tools/build_talent_tree_scene.gd
## Rearranging talents by hand in the editor is fine too; the game uses the scene as saved.

const OUT := "res://scenes/ui/talent_tree.tscn"
const CELL := Vector2(92, 66)
const MARGIN := Vector2(8, 4)
const NODE_SIZE := Vector2(58, 58)
const GOLD := Color("#f4ce83")
const LILAC := Color("#c5b4df")

var tree_root: PanelContainer

func _initialize() -> void:
	var registry := ContentRegistry.new()
	tree_root = PanelContainer.new()
	tree_root.name = "TalentTree"
	tree_root.set_script(load("res://ui/talent_tree.gd"))
	tree_root.theme = load("res://ui/game_theme.tres")
	tree_root.position = Vector2(8, 8)
	tree_root.custom_minimum_size = Vector2(1104, 624)
	tree_root.size = tree_root.custom_minimum_size
	tree_root.mouse_filter = Control.MOUSE_FILTER_STOP
	tree_root.z_index = 30
	var column := _add(tree_root, VBoxContainer.new(), "Column")
	column.add_theme_constant_override("separation", 6)
	_header(column)
	var map := _add(column, CenterContainer.new(), "Map")
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var links := _add(map, Control.new(), "Links")
	links.set_script(load("res://ui/talent_links.gd"))
	links.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_talents(links, registry)
	_info(column)
	var scene := PackedScene.new()
	var error: Error = scene.pack(tree_root)
	if error == OK:
		error = ResourceSaver.save(scene, OUT)
	print("TALENT TREE SCENE: %d talents -> %s (%s)" % [registry.talents.size(), OUT, error_string(error)])
	quit(0 if error == OK else 1)

func _add(parent: Node, child: Node, child_name: String) -> Node:
	child.name = child_name
	parent.add_child(child)
	child.owner = tree_root
	return child

func _label(parent: Node, label_name: String, text: String, font_size: int, color: Color = Color(0, 0, 0, 0)) -> Label:
	var label: Label = _add(parent, Label.new(), label_name)
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	if color.a > 0.0:
		label.add_theme_color_override("font_color", color)
	return label

func _header(column: Node) -> void:
	var top := _add(column, HBoxContainer.new(), "Header")
	top.add_theme_constant_override("separation", 12)
	var close: Button = _add(top, Button.new(), "Close")
	close.text = "Close"
	close.custom_minimum_size = Vector2(70, 40)
	_label(top, "Title", "FATE TALENTS", 18, GOLD)
	var middle := _add(top, VBoxContainer.new(), "Middle")
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 0)
	var held := _label(middle, "Held", "0 Fate held", 18, LILAC)
	held.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var total := _label(middle, "Total", "Each Fate you hold makes every roll pay 1% more.", 12)
	total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total.modulate = Color(1, 1, 1, 0.75)
	var begin: Button = _add(top, Button.new(), "Begin")
	begin.text = "Begin again"
	begin.custom_minimum_size = Vector2(200, 40)

func _talents(links: Control, registry: ContentRegistry) -> void:
	var node_scene: PackedScene = load("res://scenes/ui/talent_node.tscn")
	var low := Vector2i(1000, 1000)
	var high := Vector2i(-1000, -1000)
	for id in registry.talents:
		var cell: Vector2i = registry.talents[id].tree_position
		low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
		high = Vector2i(maxi(high.x, cell.x), maxi(high.y, cell.y))
	links.custom_minimum_size = MARGIN * 2 + Vector2(high - low) * CELL + NODE_SIZE
	for id in registry.talents:
		var definition: UpgradeDefinition = registry.talents[id]
		var node: TalentNode = node_scene.instantiate()
		node.name = id
		links.add_child(node)
		node.owner = tree_root
		node.position = MARGIN + Vector2(definition.tree_position - low) * CELL
		node.talent_id = id
		node.prerequisite = definition.prerequisite
		node.tooltip_text = definition.display_name
		if not definition.target.is_empty() and registry.dice.has(definition.target):
			node.icon_texture = ShopIcons.die(registry.dice[definition.target])
		else:
			node.icon_texture = ShopIcons.icon(definition.icon if not definition.icon.is_empty() else definition.id)

func _info(column: Node) -> void:
	var box: PanelContainer = _add(column, PanelContainer.new(), "Info")
	box.custom_minimum_size = Vector2(0, 70)
	var line := _add(box, HBoxContainer.new(), "Line")
	line.add_theme_constant_override("separation", 10)
	var icon: TextureRect = _add(line, TextureRect.new(), "Icon")
	icon.custom_minimum_size = Vector2(32, 32) # 16 px icons at exactly 2x
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var text := _add(line, VBoxContainer.new(), "Text")
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	_label(text, "Name", "Tap or click a talent to buy a rank.", 12, GOLD)
	var body := _label(text, "Body", "Talents are permanent.", 12)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(text, "Trade", "", 12, LILAC)
