# Editing the game in Godot

Open `scenes/main.tscn` in the 2D editor. The main scene now contains the game's presentation tree before Play is pressed. Its script binds those nodes and updates game data; it does not delete or reconstruct the layout.

| Scene/resource | Edit here |
|---|---|
| `scenes/main.tscn` | Overall composition, confirmation dialog, feedback/audio nodes, die/helper PackedScene references in the Inspector |
| `scenes/tabletop.tscn` | Room sprite and the separate Dice and Helpers layers |
| `scenes/ui/hud.tscn` | Title, wallet, income, Fate, hints, combo text, roll button and toast positions/styles |
| `scenes/ui/shop_panel.tscn` | Sidebar position/size, navigation buttons, scrolling content and footer |
| `scenes/ui/shop_item.tscn` | Click-to-buy shop card: icon, name, price and owned count |
| `scenes/ui/shop_card.tscn` | Larger card with description (legacy layout, still available) |
| `ui/talent_tree.gd` | Fate talent tree popup; node positions in its LAYOUT table |
| `scenes/ui/settings_page.tscn` | Settings buttons, volume slider, save/reset buttons and help text |
| `scenes/ui/debug_panel.tscn` | Development controls; opened from Settings or F3 in debug builds when the main scene developer_tools_enabled switch is on |
| `scenes/d_6.tscn` | Generic die with editable Face, Shadow and Marker nodes; D6 is its editor preview |
| `scenes/helpers/moss.tscn` | Moss sprite, texture, frame count and scale |
| `ui/game_theme.tres` | Shared fonts, colors, spacing and textured button/panel styles |

Double-click an instanced scene in the tree or open its `.tscn` in the FileSystem dock to edit the source scene. Use Editable Children for per-instance overrides where appropriate. Keep node names used by `$Node/Path` bindings when rearranging; update the binding if you rename a node.

Purchased dice, hired helpers and catalog cards are instantiated from these scenes at runtime because their count depends on saved progress. Their content still comes from the existing dice/upgrade/talent Resources. An empty Dice layer in the editor is intentional; play starts with the die instances from the session. Edit the generic die scene to change their shared appearance.

Runtime scripts still control animation, face selection, earned amounts, affordability and pooled transient effects. Dice animation currently assumes the existing 64-pixel presentation size and rest pose, and table dragging uses the existing table bounds; changing those dimensions also requires updating the animation/input constants. This refactor makes the UI composition editable without claiming every gameplay dimension is an Inspector setting.

Edit `game_theme.tres` directly. `tools/bake_theme.gd` is a maintenance tool that replaces it with defaults from `GameTheme.build()`; do not run it after hand-editing the theme unless you want to restore those defaults.

Run the whole game with F5. The standalone die scene can be previewed without a session, but gameplay is wired through the main scene. Economy, automation, saves and Fate remain in their existing services so layout changes do not change payout rules or save format.

## Tumbling dice
The generic die scene exposes tumble_frames (32), tumble_cycles and bounce_height in the Inspector. Each DiceDefinition references its rolling_texture. All dice art comes from tools/create_dice_hd.lua, which renders each die from a real 3D solid (tetrahedron, cube, octahedron, pentagonal trapezohedron, dodecahedron, icosahedron) and flattens it into outlined, cel-shaded pixel art in a 32 px frame (a 21 px body with softly rounded corners; d6 dice use a three-quarter cube view): a resting sheet with one frame per face (frame N-1 shows N) and a seamless 32-frame tumble, every frame normalized to the same body size. It overwrites the masters under assets/source/aseprite/dice and rolls, so back up hand edits first. Numbered dice show one numeral (the result, or the face nearest the camera mid-tumble); d6 pips appear on every face turned towards the viewer. Dice draw at Face scale 2 inside a control scaled 1 (16 dice or fewer), 0.75 (up to 30) or 0.5, so normal tables keep one art pixel on two screen pixels. DiceVisual uses the atlas during airborne turnover, reveals the reserved result for the final small bounce, then settles exactly at the authoritative landing position. There is no full-circle sprite rotation. Secondary shadows are omitted above 30 dice to keep draw batching efficient.


## Table ambience
Open scenes/ambient_table.tscn to move the two flames, steam and plant sprites. The root exposes flame_fps, steam_fps and plant_fps. The scene is instanced beneath Room and before gameplay layers in tabletop.tscn. It has no input controls, audio or economy logic. Motion off uses static candle/plant frames and hides steam; developer pause freezes elapsed animation time.

Editable masters live in assets/source/aseprite/ambient. Export hand edits with tools/export_art.lua. tools/create_ambient_art.lua constructs/replaces the four ambient masters, deriving room_base from the original layered environment/room.aseprite without altering it. The clean backdrop removes the baked flame/leaf pixels so animated replacements do not leave duplicate silhouettes. If the original room art changes, update the derived backdrop and sprite placement accordingly.

## Game name and icon
The display name is D- infinity. Edit the title in scenes/ui/hud.tscn and the application name in project.godot. The original layered icon is assets/source/aseprite/branding/d_infinity_icon.aseprite. Export it with the regular Aseprite exporter, then run python tools/package_icon.py to refresh the Windows ICO from the 256px PNG. tools/create_icon.lua recreates the original master, so do not run it over hand-edited artwork. The custom save-directory setting deliberately retains the previous DiceIncremental storage path.

RoomLife (effects/room_life.gd) is created by main.gd as Tabletop/RoomLife, just below Ambience, so it draws above the room and surface but under the candle flames, dice and helpers. It owns a CandleGlow child with an additive CanvasItemMaterial. setup() re-pivots the two flame sprites on their wicks (offset -8,-20) so they can lean and grow. main.gd forwards rolls, landings, combos, big rolls, streak stages and milestones to it. It only ever moves the Tabletop by a one-pixel thump and always returns it home.

Helpers (scenes/helpers/moss.tscn) use a 12-frame sheet from tools/create_helpers_hd.lua: 0-1 idle, 2-5 walk (four-frame cycle), 6-7 reach, 8-9 throw, 10-11 celebrate. Hats are a child Sprite2D positioned at (0, -12 + HELPER_HEAD_DY[frame]) so they follow the head; keep HELPER_HEAD_DY in main.gd in step with the poses in the generator.

Art rules shared by every asset: one art pixel is drawn as 2x2 screen pixels, a single outline colour (0e0b10), light from the upper left, and the shared palette. Icons are 16 px and always drawn at exactly 32 px: use ShopIcons.picture / ShopIcons.set_button_picture rather than letting a Button stretch its icon. Dice icons come from assets/exported/icons/dice_icons.png (ShopIcons.DICE_ORDER).

Text uses assets/fonts/d_infinity_pixel.fnt (theme default) and d_infinity_pixel_outline.fnt (over the table), generated by tools/create_pixel_font.gd and imported with scaling_mode=1 (integer only). The scale is font_size / 6 rounded, so use 12 for body text, 18 for headings, 24 for money and titles; sizes in between snap to a neighbouring tier.
