# Changelog

## 2026-10-08 — Roll-table cooldown

- Roll the table and Space share a 60-second cooldown after a successful batch; clicking individual dice, helpers and automatic rolls remain available.
- The button shows a ceiling-rounded m:ss countdown and a refill progress bar, disabling until ready. No cooldown is consumed when no die can roll.
- Remaining time persists in saves, decreases offline, and follows simulation pause/speed while playing. Older saves default to ready.
- Dedicated cooldown/save/input/UI checks, 88 regression checks and rendered integration passed.

## 2026-10-08 — Dice icons in the shop

- Added a die icon beside each dice purchase and per-family automatic-rolling card.
- Die-specific upgrades/talents use their target die's artwork; general bonuses remain unmarked so they do not imply a single-die restriction.
- Icons reuse the existing Aseprite face sheets through AtlasTexture regions in the editable shop-card header. Rendered UI and purchase-scroll checks passed.

## 2026-10-08 — Shop keeps its place

- Purchases update card prices and ownership in place, preserving scroll position and keyboard focus.
- Settings toggles update their label without rebuilding the page.
- Rendered regression verified purchases on Dice, Upgrades, Helpers and Fate, plus a Settings toggle.

## 2026-10-08 — Ordinary dice pay their face value

- Removed hidden D8/D10/D12 base multipliers (1.3/1.6/1.8). All ordinary dice now pay the rolled number before progression bonuses.
- Made special-die payout multipliers explicit in descriptions and added last-roll face/payout information to die hover text.
- Added every-face payout coverage for all ordinary dice through manual, automatic and helper roll paths.

## 2026-10-08 — D- infinity branding

- Renamed the application, window title and table heading to D- infinity.
- Created a layered Aseprite die icon with an infinity symbol, plus PNG and Windows ICO exports.
- Kept the existing save-directory path through an explicit custom directory. Branding checks, all 70 regression checks and rendered UI tests passed.

## 2026-10-02 — Animated table ambience

- Added independently flickering candles, rising cup steam and slow plant sway in an editable ambient scene.
- Created four Aseprite masters: a clean derived room backdrop plus flame, steam and plant loops; original room master remains untouched.
- Motion off freezes flames/leaves and hides steam. Developer pause freezes animation time. No new audio or gameplay effects.
- Rendered ambience and interaction checks passed; 100-die probe remained around 60 FPS.

## 2026-10-02 — Silent automated tests

- Muted the Master bus automatically for every `--test` session, including hidden rendered tests. Saved sound preferences and ordinary play remain unchanged.
- Added checks that the test bus stays muted through Settings sound toggles; background test commands use the Dummy audio driver as well.

## 2026-10-02 — Scrollable developer tools

- Kept the developer panel inside its existing bounds with a vertically scrollable action list and a fixed Close button.
- Enabled scrolling to keyboard-focused controls. Rendered integration verifies that the last action is visible and clickable after scrolling.

## 2026-10-02 — Tumbling dice animation

- Replaced full-circle flat sprite spins with 24-frame shaded, multi-face Aseprite tumble animations for all ten dice.
- Added decelerating travel, diminishing bounces, impact squash, height-sensitive shadows and an early stable result reveal.
- Exposed tumble cycles/frame count/bounce height on the die scene. Motion disabled skips tumbling; dense tables omit secondary shadows to preserve batching.
- Added all-dice animation checks and retained authoritative roll outcomes and payouts.

## 2026-10-02 — Window resizing

- Changed integer-only stretching to fractional scaling with the 1120×640 aspect ratio preserved. Smaller windows now fit the whole table and sidebar; other aspect ratios use letterboxing.
- Reproduced clipping before the fix. Added a rendered resize regression checking layout, bounds, scale and physical-coordinate button clicks at four window sizes.

## 2026-10-02 — Smaller dice and rolling travel

- Reduced normal dice to 65% size while retaining the dense-table size.
- Added short random travel, bounded and saved landing positions, and stationary reduced-motion rolls.
- Added Settings access and a Close button for developer tools, with an Inspector release switch and non-debug export gate.
- Verified 70 regression checks and rendered movement/developer-tool integration.
## 2026-10-02 — Editable scene composition

- Replaced runtime construction of the main layout with authored tabletop, HUD, shop, settings and debug scenes.
- Added reusable purchase-card and Moss scenes; the generic die now owns its face, shadow and marker in its scene.
- Serialized the shared theme and exposed die/helper scene references in the Inspector.
- Preserved existing state, services, art and save format. Added scene-edit persistence and actual button-wiring checks to rendered integration.

## 2026-10-01 — Controlled performance verification

- Added isolated rendering scenarios, warmup, actual frame interval percentiles, activity checks and memory reporting.
- Corrected stress timing labels/sampling and required the isolated test flag.
- Measured a 60-second, 100-die/eight-helper run at 59.97 FPS with 6,000 completed payouts; 64 regression checks passed.
- Earlier slowdown did not reproduce; visible export/hardware qualification remains open. No speculative runtime changes.
## 2026-10-01 — First complete playable progression pass

- Preserved original project in Git before editing; no replacement project.
- Separated immutable content from saved dice instances and progression.
- Added validated catalog, shared economy, deterministic weighted rolls, typed events and statistics.
- Corrected fractional payout truncation, differing manual/auto modifiers, negative purchases and discarded timer fractions.
- Added safe versioned saves, legacy currency migration, backup recovery, autosave and capped offline earnings.
- Built original Aseprite table, ten dice face sheets, UI skins, effects and tagged helper animations.
- Added physical-looking controlled rolls, per-die input/dragging, pooled feedback and synthesized audio.
- Added D4/D8/D10/D12, Lucky/Ember/Prism mechanics, seven upgrades, walking helpers and family automation.
- Added combination batches, spatial auras and bounded Resource-defined chain effects.
- Added Fate (user-selected name), prestige reset confirmation, four permanent talents and local milestones.
- Added accessibility controls, stats ledger, reset archive, gated development controls, balance/simulation tools and rendered tests.

This pass establishes initial playable implementations across roadmap phases 1–8 plus a first polish/QA pass. It does not certify commercial readiness or declare every phase's subjective quality gate complete.
