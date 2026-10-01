# DiceIncremental — implementation and verification
Date: 1 October 2026

## What changed
The existing project now has a playable tabletop progression loop through Fate prestige. It was modified in place; the original is preserved in Git commit 5554263 and a complete baseline archive.

- Immutable Resource definitions, validated content registry, saved die instances, central economy and seeded roll simulation.
- Versioned saves with legacy-currency migration, verified temporary writes, validated backups, corruption recovery, newer-version protection and autosave.
- Original Aseprite artwork: 19 editable masters, exported dice/environment/helper/UI/effect textures and animation metadata.
- Ten dice, seven upgrades, individually clickable/draggable dice, controlled throws and result reveals.
- Helpers with five reachable phases and exclusive targets; per-family automatic rolling.
- Lucky probabilities, Golden payouts, exploding Ember rolls, nearby Prism bonuses, doubles/triples/straights and bounded neighbor chains.
- Fate prestige, four permanent talents, local achievements, statistics, offline production and accessibility settings.
- Headless regression tests, balance tools, rendered integration tests and a parameterized stress runner.
- All eight requested design/engineering documents. Superseded unreferenced legacy logic was retired; original art and Git history remain.

## Verified
Godot 4.7.2, Compatibility renderer, Intel Iris Xe.

A fresh copy with no .godot cache imported successfully, with no logged errors/warnings. Its regression suite passed **64 checks, zero failures**. These cover probability/ranges/determinism, shared-definition immutability, affordability, fractional and automatic payouts, exactly-once commits, timers, combinations, spatial auras, bounded explosions, deleted helper targets, all helper animation phases, target reservation, saves/RNG/settings/Fate roundtrips, backup recovery, future-save protection, invalid data, prestige retention/reset, offline caps, large formatting and 100 simultaneous dice.

One million fair-D6 samples completed in **2,005ms** in the final clean-copy test. This measures headless sampling only.

Rendered integration exercised six pages plus prestige confirmation, the actual prestige callback and a talent purchase. Fast-drag input regression committed a position without triggering a roll. Native Windows interaction earlier verified clicking a die, buying a second die, hiring Moss and autonomous earnings. The native window tool later failed with “foreground window did not report a process id”; the corrected drag was verified through Godot events, not a successful subsequent native-tool drag.

Aseprite reopened and exported the editable masters. An already-installed PixelLab extension emitted startup Lua warnings in batch mode; the project exporter itself completed. No PixelLab generation or external sprite assets were used.

## Performance: measured limits
Five-second rendered debug-build runs, eight helpers, automatic dice. These are short local probes, not a release performance guarantee.

| Dice | Frames/sec | Gameplay tick median / p95 |
|---:|---:|---:|
| 5 | 31.3 | 0.20 / 0.81ms |
| 20 | 26.6 | 0.39 / 3.72ms |
| 50 | 28.5 | 0.76 / 5.52ms |
| 100 | 29.3 | 1.33 / 9.23ms |

The first earlier 100-die run reached 59.2 FPS; later runs were slower, including a visible-window rerun. A headless 100-die run reached 144.7 frames/sec. The similar rendered slowdown at five and 100 dice suggests a rendering/environment limitation rather than linear gameplay overload, but the root cause is not proven. Render/process monitor spikes reached roughly 0.45s in some runs. Sustained rendering performance remains a release blocker; this is not a claim of stable 60 FPS.

Dense tables reduce visual size and animation complexity, hide tiny labels/duplicate shadows, aggregate payout text and avoid overlapping wallet tweens. The game resolves 100 dice without duplicate/dropped awards or unbounded effect work.

## Pacing
A deterministic example buyer throwing every 1.2 seconds reached its first helper around 38 seconds. An initial $25K prestige gate arrived too soon, so the shared threshold was raised to $100K. The corresponding probe reached Fate around 231 seconds. These are scripted strategy timings, not measured human behavior or validated retention.

## Run and controls
Open the existing DiceIncremental project in Godot and press F5.
- Click a die to roll; Space rolls all ready dice.
- Drag dice to arrange a build; hover for descriptions.
- Helpers unlock after $150 earned; Fate begins at $100K run earnings.
- Settings control sound, motion, flashes, floating payouts and particles.
- Progress saves every 30 seconds and on normal exit.
- Isolated test sessions use --test and cannot overwrite the player's progress.

The screenshots in this handoff are generated from a test-funded showcase, not a change to the player's saved progression.

## Remaining work
Initial implementations span roadmap phases 1–8 and a first phase-9 polish pass. Commercial completion is **not** claimed. Remaining gates include the user's first-roll/art-direction review, long-session balancing, final audio/music, export/platform qualification, sustained render profiling, broader accessibility/localization and Steam integration. Future machines, crafting and minigames remain deliberately outside this pass.

The project TODO.md distinguishes implemented systems from these release requirements.

## Follow-up: controlled rendering baseline
The 1 October performance follow-up reproduced neither the earlier 29 FPS result nor the large reported monitor spikes. No runtime optimization was made in this follow-up because the controlled measurements did not establish a gameplay/rendering bottleneck.

A new `tests/render_benchmark.gd` warms up for two seconds, samples actual frame intervals and gameplay tick duration, and separates blank, static, full, silent and hidden scenes. The older stress runner now measures frame intervals instead of treating the periodically updated TIME_PROCESS monitor as a per-frame CPU sample. Both runners refuse to run without `--test`.

Sequential six-second probes on the same Windows / Intel Iris Xe / Compatibility configuration:

| Scenario | VSync | FPS | Frame interval p95 |
|---|---|---:|---:|
| Blank scene | On | 59.99 | 17.75 ms |
| Blank scene | Off | 7,678.71 | 0.20 ms |
| 100 automatic D6 + 8 helpers | On | 59.85 | 17.74 ms |
| 100 automatic D6 + 8 helpers | Off | 868.90 | 1.74 ms |
| Static 100-die table | On | 59.83 | 17.99 ms |

A separate **60-second full-scene run** completed **6,000 rolls**, earned **20,869**, and recorded **59.97 FPS** across 3,598 sampled frames. Frame interval median / p95 / p99: **16.66 / 17.83 / 18.18 ms**; maximum **33.40 ms**, one frame above 33.333 ms. Gameplay tick median / p95: **0.96 / 1.87 ms**. Godot static memory increased from **76.28 to 76.72 MB**, including benchmark samples; this is not a leak assessment.

These are real Windows-renderer debug processes launched with WindowStyle Hidden, not a visible interactive play session or GPU completion benchmark. Uncapped results are diagnostic frame-loop rates, not an achievable display refresh rate. Frame intervals include presentation waits; draw counts are final snapshots. Prior results are preserved above as historical evidence, not directly comparable per-frame CPU measurements. The cause of the earlier slowdown remains unknown. Longer visible sessions, exported builds, mixed special-die builds and additional hardware remain release gates.

After the instrumentation changes, all **64 regression checks passed again**, including save and payout coverage; the million-roll sampler took **2,061 ms**. Player saves were disabled throughout via `--test`.
