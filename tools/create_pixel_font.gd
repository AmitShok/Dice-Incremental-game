extends SceneTree
## Builds the game's pixel font: an original, hand-designed bitmap font in two versions,
##   assets/fonts/d_infinity_pixel.fnt          plain glyphs (UI text)
##   assets/fonts/d_infinity_pixel_outline.fnt  the same glyphs with a 1 px dark outline baked
##                                              in, for text drawn over the table (bitmap fonts
##                                              cannot use Godot's outline_size).
## Metrics (font pixels): capitals and digits 6 tall, lowercase x-height 4, descenders 2,
## proportional widths, 1 px letter gap, line height 10, baseline 7. Base size 6 with integer
## scaling, so text sizes 12-17 draw at 2x, 18-23 at 3x, 24-29 at 4x: always whole pixels.
## Run: GODOT --headless --path . --script res://tools/create_pixel_font.gd

const BASE_SIZE: int = 6
const LINE_HEIGHT: int = 10
const BASELINE: int = 7
const TOP_PAD: int = 1 # glyph row 0 sits one pixel below the top of the line
const OUTLINE := Color("#0e0b10")

## Each glyph: [top row (0 = top of capitals), rows...]. "#" is ink.
var GLYPHS: Dictionary = {
	" ": [0, "...", "..."],
	"!": [0, "#", "#", "#", "#", ".", "#"],
	"\"": [0, "#.#", "#.#"],
	"#": [0, ".#.#.", "#####", ".#.#.", ".#.#.", "#####", ".#.#."],
	"$": [-1, "..#..", ".####", "#.#..", ".###.", "..#.#", "####.", "..#.."],
	"%": [0, "##..#", "##.#.", "..#..", ".#...", "#..##", "...##"],
	"&": [0, ".##..", "#..#.", ".##..", "#..#.", "#...#", ".###."],
	"'": [0, "#", "#"],
	"(": [0, ".#", "#.", "#.", "#.", "#.", ".#"],
	")": [0, "#.", ".#", ".#", ".#", ".#", "#."],
	"*": [1, "#.#", ".#.", "#.#"],
	"+": [1, ".#.", ".#.", "###", ".#.", ".#."],
	",": [5, ".#", "#."],
	"-": [3, "###"],
	".": [5, "#"],
	"/": [0, "...#", "..#.", "..#.", ".#..", ".#..", "#..."],
	"0": [0, ".##.", "#..#", "#.##", "##.#", "#..#", ".##."],
	"1": [0, ".#.", "##.", ".#.", ".#.", ".#.", "###"],
	"2": [0, ".##.", "#..#", "..#.", ".#..", "#...", "####"],
	"3": [0, "###.", "...#", ".##.", "...#", "...#", "###."],
	"4": [0, "#..#", "#..#", "####", "...#", "...#", "...#"],
	"5": [0, "####", "#...", "###.", "...#", "...#", "###."],
	"6": [0, ".##.", "#...", "###.", "#..#", "#..#", ".##."],
	"7": [0, "####", "...#", "..#.", ".#..", ".#..", ".#.."],
	"8": [0, ".##.", "#..#", ".##.", "#..#", "#..#", ".##."],
	"9": [0, ".##.", "#..#", "#..#", ".###", "...#", ".##."],
	":": [1, "#", ".", ".", ".", "#"],
	";": [1, ".#", "..", "..", ".#", "#."],
	"<": [1, "..#", ".#.", "#..", ".#.", "..#"],
	"=": [2, "###", "...", "###"],
	">": [1, "#..", ".#.", "..#", ".#.", "#.."],
	"?": [0, ".##.", "#..#", "..#.", ".#..", "....", ".#.."],
	"@": [0, ".###.", "#...#", "#.###", "#.#.#", "#.###", ".##.."],
	"A": [0, ".##.", "#..#", "#..#", "####", "#..#", "#..#"],
	"B": [0, "###.", "#..#", "###.", "#..#", "#..#", "###."],
	"C": [0, ".###", "#...", "#...", "#...", "#...", ".###"],
	"D": [0, "###.", "#..#", "#..#", "#..#", "#..#", "###."],
	"E": [0, "####", "#...", "###.", "#...", "#...", "####"],
	"F": [0, "####", "#...", "###.", "#...", "#...", "#..."],
	"G": [0, ".###", "#...", "#...", "#.##", "#..#", ".###"],
	"H": [0, "#..#", "#..#", "####", "#..#", "#..#", "#..#"],
	"I": [0, "###", ".#.", ".#.", ".#.", ".#.", "###"],
	"J": [0, "..##", "...#", "...#", "...#", "#..#", ".##."],
	"K": [0, "#..#", "#.#.", "##..", "#.#.", "#..#", "#..#"],
	"L": [0, "#...", "#...", "#...", "#...", "#...", "####"],
	"M": [0, "#...#", "##.##", "#.#.#", "#...#", "#...#", "#...#"],
	"N": [0, "#..#", "##.#", "#.##", "#..#", "#..#", "#..#"],
	"O": [0, ".##.", "#..#", "#..#", "#..#", "#..#", ".##."],
	"P": [0, "###.", "#..#", "#..#", "###.", "#...", "#..."],
	"Q": [0, ".##.", "#..#", "#..#", "#..#", "#.#.", ".#.#"],
	"R": [0, "###.", "#..#", "#..#", "###.", "#.#.", "#..#"],
	"S": [0, ".###", "#...", ".##.", "...#", "...#", "###."],
	"T": [0, "#####", "..#..", "..#..", "..#..", "..#..", "..#.."],
	"U": [0, "#..#", "#..#", "#..#", "#..#", "#..#", ".##."],
	"V": [0, "#...#", "#...#", "#...#", ".#.#.", ".#.#.", "..#.."],
	"W": [0, "#...#", "#...#", "#...#", "#.#.#", "##.##", "#...#"],
	"X": [0, "#..#", "#..#", ".##.", ".##.", "#..#", "#..#"],
	"Y": [0, "#...#", "#...#", ".#.#.", "..#..", "..#..", "..#.."],
	"Z": [0, "####", "...#", "..#.", ".#..", "#...", "####"],
	"[": [0, "##", "#.", "#.", "#.", "#.", "##"],
	"\\": [0, "#...", ".#..", ".#..", "..#.", "..#.", "...#"],
	"]": [0, "##", ".#", ".#", ".#", ".#", "##"],
	"^": [0, ".#.", "#.#"],
	"_": [6, "####"],
	"`": [0, "#.", ".#"],
	"a": [2, ".###", "#..#", "#..#", ".###"],
	"b": [0, "#...", "#...", "###.", "#..#", "#..#", "###."],
	"c": [2, ".###", "#...", "#...", ".###"],
	"d": [0, "...#", "...#", ".###", "#..#", "#..#", ".###"],
	"e": [2, ".##.", "####", "#...", ".###"],
	"f": [0, ".##", "#..", "###", "#..", "#..", "#.."],
	"g": [2, ".###", "#..#", "#..#", ".###", "...#", ".##."],
	"h": [0, "#...", "#...", "###.", "#..#", "#..#", "#..#"],
	"i": [0, "#", ".", "#", "#", "#", "#"],
	"j": [0, ".#", "..", ".#", ".#", ".#", ".#", ".#", "#."],
	"k": [0, "#...", "#...", "#..#", "#.#.", "###.", "#..#"],
	"l": [0, "#.", "#.", "#.", "#.", "#.", ".#"],
	"m": [2, "####.", "#.#.#", "#.#.#", "#.#.#"],
	"n": [2, "###.", "#..#", "#..#", "#..#"],
	"o": [2, ".##.", "#..#", "#..#", ".##."],
	"p": [2, "###.", "#..#", "#..#", "###.", "#...", "#..."],
	"q": [2, ".###", "#..#", "#..#", ".###", "...#", "...#"],
	"r": [2, "#.##", "##..", "#...", "#..."],
	"s": [2, ".###", "##..", "..##", "###."],
	"t": [1, ".#.", "###", ".#.", ".#.", "..#"],
	"u": [2, "#..#", "#..#", "#..#", ".###"],
	"v": [2, "#...#", "#...#", ".#.#.", "..#.."],
	"w": [2, "#...#", "#.#.#", "#.#.#", ".#.#."],
	"x": [2, "#..#", ".##.", ".##.", "#..#"],
	"y": [2, "#..#", "#..#", "#..#", ".###", "...#", ".##."],
	"z": [2, "####", "..#.", ".#..", "####"],
	"{": [0, ".##", ".#.", "#..", ".#.", ".#.", ".##"],
	"|": [0, "#", "#", "#", "#", "#", "#", "#"],
	"}": [0, "##.", ".#.", "..#", ".#.", ".#.", "##."],
	"~": [2, ".#.#", "#.#."],
	"×": [2, "#.#", ".#.", "#.#"],
	"·": [3, "#"],
	"–": [3, "####"],
	"—": [3, "######"],
	"−": [3, "###"],
	"→": [1, "..#..", "...#.", "#####", "...#.", "..#.."],
	"•": [2, ".#.", "###", ".#."],
}

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/fonts"))
	_build("d_infinity_pixel", false)
	_build("d_infinity_pixel_outline", true)
	print("PIXEL FONT: %d glyphs, plain and outlined" % GLYPHS.size())
	quit()

func _build(name: String, outlined: bool) -> void:
	var pad: int = 1 if outlined else 0
	# Lay glyphs out left to right with a 1 px gap between cells.
	var cells: Array = []
	var width: int = 1
	var height: int = 0
	for ch in GLYPHS:
		var spec: Array = GLYPHS[ch]
		var rows: Array = spec.slice(1)
		var w: int = String(rows[0]).length()
		cells.append({"ch": ch, "top": int(spec[0]), "rows": rows, "w": w, "x": width})
		width += w + pad * 2 + 1
		height = maxi(height, rows.size() + pad * 2)
	var image := Image.create(width, height + 2, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var lines: PackedStringArray = []
	lines.append('info face="D-infinity Pixel" size=%d bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1' % BASE_SIZE)
	lines.append("common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0" % [LINE_HEIGHT, BASELINE, image.get_width(), image.get_height()])
	lines.append('page id=0 file="%s.png"' % name)
	lines.append("chars count=%d" % cells.size())
	for cell in cells:
		var rows: Array = cell.rows
		var ink: Array = []
		for y in rows.size():
			for x in cell.w:
				if String(rows[y])[x] == "#":
					ink.append(Vector2i(x, y))
		if outlined:
			# A one-pixel ring (including diagonals) of the outline colour around every ink pixel.
			for p in ink:
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						image.set_pixel(cell.x + pad + p.x + dx, 1 + pad + p.y + dy, OUTLINE)
		for p in ink:
			image.set_pixel(cell.x + pad + p.x, 1 + pad + p.y, Color.WHITE)
		var advance: int = cell.w + 1
		if cell.ch == " ":
			advance = 3
		lines.append("char id=%d x=%d y=%d width=%d height=%d xoffset=%d yoffset=%d xadvance=%d page=0 chnl=15" % [
			String(cell.ch).unicode_at(0), cell.x, 1, cell.w + pad * 2, rows.size() + pad * 2,
			-pad, TOP_PAD + int(cell.top) - pad, advance])
	image.save_png(ProjectSettings.globalize_path("res://assets/fonts/%s.png" % name))
	var file := FileAccess.open("res://assets/fonts/%s.fnt" % name, FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
