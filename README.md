# DiceIncremental

A cozy tabletop incremental about turning a handful of dice into a probability engine.

## Run
Open this existing project in Godot 4.7.2 and press F6 on main.tscn or F5. The renderer is Compatibility. No external runtime packages are required. Start with one Ivory D6; click it or press Space to roll, drag to arrange, and use the right-hand shop. Buy helpers after earning $150 in the run. Fate becomes available after $100,000 earned.

## Current playable release
Ten dice definitions (D4, D6, D8, D10, D12, D20, Golden, Lucky, Ember, Prism); seven ordinary upgrades; walking helpers and per-family automation; doubles/triples/straights; spatial auras and bounded rerolls; Fate prestige and four permanent talents; statistics, eight local milestones, offline income, settings and versioned saves.

Art is created/exported in Aseprite with editable masters in assets/source/aseprite. No downloaded or ImageGen sprites. Sound cues are original synthesized waveforms. This is a playable development build, not a certified commercial release; see TODO.md for the remaining quality gates.

## Verification
Replace GODOT below with your Godot executable. Run from the project directory.

```
GODOT --headless --path . --editor --import --quit
GODOT --headless --path . --script res://tests/test_runner.gd -- --test
GODOT --path . --script res://tests/visual_runner.gd -- --test
GODOT --path . --script res://tests/stress_runner.gd -- --test
GODOT --headless --path . --script res://tools/balance.gd -- --test
```

Set DICE_TEST_OUTPUT to an existing directory to capture visual test PNGs. --test disables player-save access, not gameplay. Tests never overwrite progress.json. Native desktop click/drag behavior is additionally a manual QA item.

For isolated developer play, use `GODOT --path . -- --test --dev` then F3. Debug controls require both a debug build and --dev. Ordinary launches do not show them.

## Artwork
Normal export: `ASEPRITE -b --script-param root=PROJECT_PATH --script tools/export_art.lua`. This reads .aseprite masters and exports PNG/JSON; it never regenerates originals. tools/create_art.lua is the initial artwork construction script and may overwrite original art: do not run it on edited masters without a backup.

## Project safety
The original project was preserved in Git commit 5554263 before implementation. Existing legacy PNGs are preserved. Superseded dice scripts and Resources were retired after reference checks; their exact originals remain in Git. New progress saves use progress.json, leaving legacy save.json untouched. See SAVE_FORMAT.md for recovery and migration behavior.
