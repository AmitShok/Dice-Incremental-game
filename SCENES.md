# Editing the game in Godot

Open `scenes/main.tscn` in the 2D editor. The main scene now contains the game's presentation tree before Play is pressed. Its script binds those nodes and updates game data; it does not delete or reconstruct the layout.

| Scene/resource | Edit here |
|---|---|
| `scenes/main.tscn` | Overall composition, confirmation dialog, feedback/audio nodes, die/helper PackedScene references in the Inspector |
| `scenes/tabletop.tscn` | Room sprite and the separate Dice and Helpers layers |
| `scenes/ui/hud.tscn` | Title, wallet, income, Fate, hints, combo text, roll button and toast positions/styles |
| `scenes/ui/shop_panel.tscn` | Sidebar position/size, navigation buttons, scrolling content and footer |
| `scenes/ui/shop_card.tscn` | Shared purchase card layout, title, description and purchase button |
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
