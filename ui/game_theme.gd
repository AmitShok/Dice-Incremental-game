class_name GameTheme
extends RefCounted
## Builds the shared UI theme. Skins are 32×32 PNGs drawn at 2× pixel scale so UI pixels match
## the room art; the 10px nine-slice margin keeps their brass rims crisp at any size.
## Regenerate the .tres with tools/bake_theme.gd (this replaces hand edits to game_theme.tres).

static func skin(name: String, content: float = 9.0) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = load("res://assets/exported/ui/%s.png" % name)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_texture_margin(side, 10)
		box.set_content_margin(side, content)
	return box

static func build() -> Theme:
	var result := Theme.new()
	# The game's own pixel font. It scales by whole steps of its 6 px base (size / 6, rounded):
	# 12 is 2x for body text, 18 is 3x for headings, 24 is 4x for money and titles.
	result.default_font = load("res://assets/fonts/d_infinity_pixel.fnt")
	result.default_font_size = 12
	result.set_color("font_color", "Label", Color("#e7deca"))
	result.set_color("font_color", "Button", Color("#f3dfb4"))
	result.set_color("font_hover_color", "Button", Color("#fff1cf"))
	result.set_color("font_pressed_color", "Button", Color("#e8cf98"))
	result.set_color("font_focus_color", "Button", Color("#fff1cf"))
	result.set_color("font_disabled_color", "Button", Color("#7f8a83"))
	result.set_color("font_outline_color", "Button", Color("#0e0b10"))
	result.set_constant("outline_size", "Button", 2)
	result.set_stylebox("normal", "Button", skin("button"))
	result.set_stylebox("hover", "Button", skin("button_hover"))
	result.set_stylebox("pressed", "Button", skin("button_pressed"))
	result.set_stylebox("disabled", "Button", skin("button_disabled"))
	result.set_stylebox("focus", "Button", skin("button_hover"))
	result.set_stylebox("panel", "PanelContainer", skin("panel", 11.0))
	result.set_stylebox("panel", "PopupPanel", skin("panel", 11.0))
	result.set_stylebox("panel", "AcceptDialog", skin("panel", 11.0))
	result.set_constant("separation", "VBoxContainer", 8)
	return result
