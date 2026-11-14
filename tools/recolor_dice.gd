extends SceneTree
## Derives the Spark, Blast and Gild dice from the existing D8/D10/D12 art so they keep the
## established dice style. Re-hues saturated body pixels; ink, pips and numerals stay as drawn.
## Run: GODOT --headless --path . --script res://tools/recolor_dice.gd
## Then build editable masters: ASEPRITE -b IN.png --save-as assets/source/aseprite/<dir>/<name>.aseprite

const SPECS: Array = [
	# source, destination, hue (0-1), saturation multiplier, value multiplier
	["d8", "spark_d8", 0.53, 1.35, 1.08],
	["d10", "blast_d10", 0.05, 1.45, 1.05],
	["d12", "gild_d12", 0.12, 1.5, 1.12],
]

func _initialize() -> void:
	for spec in SPECS:
		for folder in ["dice", "rolls"]:
			var source: Image = Image.load_from_file("res://assets/exported/%s/%s.png" % [folder, spec[0]])
			for y in source.get_height():
				for x in source.get_width():
					var c: Color = source.get_pixel(x, y)
					if c.a <= 0.0 or c.s < 0.12 or c.v < 0.18:
						continue
					source.set_pixel(x, y, Color.from_hsv(spec[2], clampf(c.s * spec[3], 0.0, 1.0), clampf(c.v * spec[4], 0.0, 1.0), c.a))
			source.save_png("res://assets/exported/%s/%s.png" % [folder, spec[1]])
	print("RECOLOR: wrote spark_d8, blast_d10 and gild_d12 face and roll sheets")
	quit()
