@tool
class_name TalentNode
extends Button
## One talent on the Fate talent tree (scenes/ui/talent_node.tscn): its icon at exactly 2x above
## its rank. The node's name is its talent id. It runs in the editor too, so the tree scene shows
## real icons and its links while you arrange it.

## Talent id this node stands for (matches the .tres id; the node is named after it too).
@export var talent_id: String = ""
## The talent this one needs first; the map draws a link from it. Mirrors the .tres
## prerequisite so links show in the editor without loading game content.
@export var prerequisite: String = ""
@export var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		if is_node_ready():
			$Icon.texture = value

func _ready() -> void:
	$Icon.texture = icon_texture

## "level/max", or just the level for talents with no real limit.
func set_rank(text: String) -> void:
	$Rank.text = text
