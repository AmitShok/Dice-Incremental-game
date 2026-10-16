# D- infinity

A cozy tabletop incremental about turning a handful of dice into a probability engine.

## Run
Open this existing project in Godot 4.7.2 and press F6 on main.tscn or F5. The renderer is Compatibility. No external runtime packages are required. Start with one Ivory D6; click it or press Space to roll, drag to arrange, and use the right-hand shop. Buy helpers after earning $150 in the run. Fate becomes available after $100,000 earned.

## Current playable release

The presentation is composed from editable Godot scenes. Start with `scenes/main.tscn`; open its tabletop, HUD and shop instances to arrange their children in the editor. See [SCENES.md](SCENES.md) for the scene map and editing workflow.
Ten dice definitions (D4, D6, D8, D10, D12, D20, Golden, Lucky, Ember, Prism); seven ordinary upgrades; walking helpers and per-family automation; doubles/triples/straights; spatial auras and bounded rerolls; Fate prestige and four permanent talents; statistics, eight local milestones, offline income, settings and versioned saves.

Art is created/exported in Aseprite with editable masters in assets/source/aseprite. No downloaded or ImageGen sprites. Sound cues are original synthesized waveforms. This is a playable development build, not a certified commercial release; see TODO.md for the remaining quality gates.

## Verification

Automated `--test` sessions mute the Master audio bus for that process, without changing saved player sound settings. For background tool runs also pass `--audio-driver Dummy` before `--`; this prevents the test from using the computer's speakers at all.
Replace GODOT below with your Godot executable. Run from the project directory.

```
GODOT --headless --path . --editor --import --quit
GODOT --headless --path . --script res://tests/test_runner.gd -- --test
GODOT --path . --script res://tests/visual_runner.gd -- --test
GODOT --path . --script res://tests/resize_runner.gd -- --test
GODOT --path . --script res://tests/tumble_runner.gd -- --test
GODOT --audio-driver Dummy --path . --script res://tests/ambient_runner.gd -- --test
GODOT --path . --script res://tests/stress_runner.gd -- --test
GODOT --path . --script res://tests/render_benchmark.gd -- --test --mode=full --seconds=60
GODOT --headless --path . --script res://tools/balance.gd -- --test
```

Set DICE_TEST_OUTPUT to an existing directory to capture visual test PNGs. --test disables player-save access, not gameplay. Tests never overwrite progress.json. Native desktop click/drag behavior is additionally a manual QA item.

The render benchmark warms up for two seconds, then reports actual frame intervals, gameplay tick times, roll/payout activity and memory. Compare `--mode=blank`, `static`, `full`, `silent` or `hidden`; add `--vsync=off` only for a diagnostic uncapped run. Run scenarios sequentially with the same window/environment conditions. Frame intervals include presentation waits and are not CPU execution times. Draw counts are a final monitor snapshot. The benchmark and stress scripts enforce `--test`; keep this flag on every test command.

In this development build, open Settings → Open developer tools (or press F3). The panel has a Close button. For isolated developer play use `GODOT --path . -- --test`. Before public release, disable `developer_tools_enabled` on the main scene; non-debug exports also hide the tools automatically.

## Exporting Windows and HTML

Use the **Windows Desktop** or **Web** preset in Project > Export. Re-export after updating; existing builds retain the old content loader. For Windows, keep the `.exe` and matching `.pck` together. For Web, export as `index.html` and upload all generated files together to an HTTPS host. For a local preview, serve the export folder with `python -m http.server 8000 --bind 127.0.0.1` and open `http://127.0.0.1:8000`; do not open the HTML directly from disk. The Web preset disables thread support so it does not require cross-origin isolation headers.

Content discovery uses `ResourceLoader.list_directory()` so exported `.tres` remaps still resolve. See [Godot's resource listing guidance](https://docs.godotengine.org/en/4.7/classes/class_diraccess.html). Lucky weights use PackedFloat32Array because the 4.7.2 binary resource export dropped this property's PackedFloat64Array values; sampling still uses Float64 math.

Run `./tools/verify_exports.ps1 -Godot "PATH_TO_GODOT.exe" -OutputDirectory "PATH_OUTSIDE_PROJECT"` in PowerShell to build both release targets and run gameplay and rendered integration checks against each exported PCK. Matching export templates must be installed. Tests use the editor executable to run test scripts against packaged resources because release templates do not support `--script`. They run silently with player saves disabled. Browser/Windows release startup should also be checked after engine upgrades.

## Artwork
Normal export: `ASEPRITE -b --script-param root=PROJECT_PATH --script tools/export_art.lua`. This reads .aseprite masters and exports PNG/JSON; it never regenerates originals. tools/create_art.lua is the initial artwork construction script and may overwrite original art: do not run it on edited masters without a backup.

## Project safety
The original project was preserved in Git commit 5554263 before implementation. Existing legacy PNGs are preserved. Superseded dice scripts and Resources were retired after reference checks; their exact originals remain in Git. New progress saves use progress.json, leaving legacy save.json untouched. See SAVE_FORMAT.md for recovery and migration behavior.
