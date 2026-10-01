class_name GameTheme
extends RefCounted

static func skin(name: String) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = load("res://assets/exported/ui/%s.png" % name)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_texture_margin(side, 5)
		box.set_content_margin(side, 8)
	return box

static func build() -> Theme:
	var result := Theme.new()
	result.default_font_size = 16
	result.set_color("font_color", "Label", Color("#e7deca"))
	result.set_color("font_color", "Button", Color("#f3dfb4"))
	result.set_color("font_disabled_color", "Button", Color("#909b92"))
	result.set_stylebox("normal", "Button", skin("button"))
	result.set_stylebox("hover", "Button", skin("button_hover"))
	result.set_stylebox("pressed", "Button", skin("button_hover"))
	result.set_stylebox("disabled", "Button", skin("button_disabled"))
	result.set_stylebox("focus", "Button", skin("button_hover"))
	result.set_stylebox("panel", "PanelContainer", skin("panel"))
	result.set_stylebox("panel", "PopupPanel", skin("panel"))
	result.set_stylebox("panel", "AcceptDialog", skin("panel"))
	result.set_constant("separation", "VBoxContainer", 8)
	return result
