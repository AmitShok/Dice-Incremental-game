# Changelog

## 2026-11-15 — Web export checked on desktop and touch phones

- Exported the Web build to `../d-infinity web/`. It passes the full Web verification against the exported package: gameplay, visual, resize, desktop touch and phone touch.
- Played the export in a browser on desktop (click to roll, Space to roll the table, buying, mouse drag, wheel scrolling, sound) and on an emulated 740×360 touch phone (tap to roll, finger drag, swipe-scrolling the shop without buying, tab taps, dragging a die into the sell tray). All worked.
- **Fixes found while testing:**
  - New dice could spawn in a felt corner under the gold bracket. The spawn grid now stays clear of the corners and rails.
  - A dragged die passed under the sell tray. It now floats above the HUD while held.
- **`tools/verify_exports.ps1`:**
  - It no longer reports passing checks as failures (PowerShell returned an empty exit code without reading the process handle).
  - A new `-Targets` option runs only the presets whose export templates are installed.
- `tests/touch_runner.gd` now lets the last purchase sound finish before quitting, so no audio stream is left in use at exit.
- **Known engine limitation:** the Web build treats an interrupted touch (`touchcancel`) like a release, so a system gesture during a drag drops the die where the finger was.

## 2026-11-14 — Pixel font

- All text now uses the game's own pixel font, D-infinity Pixel, built by `tools/create_pixel_font.gd`. Every glyph was designed by hand for readability:
  - capitals and digits 6 px tall,
  - a 4 px lowercase x-height with true descenders (g, j, p, q, y),
  - proportional widths with a 1 px gap between letters,
  - a slashed zero,
  - plus the × · – — − → • symbols the game uses.
- Two versions ship in `assets/fonts/`: a plain one for the UI, and one with a 1 px dark outline baked in for text over the table. That covers payout pops, dice tags, the hint line, combo text and the streak label. Bitmap fonts can't use Godot's `outline_size`.
- The font scales only in whole steps (size ÷ 6, rounded), so text pixels are always square, matching the art:
  - body text is 12 (2×, 12 px capitals),
  - headings are 18 (3×),
  - money and Fate are 24 (4×),
  - payout pops step from 2× under $1K up to 5×, one step bigger for max and critical rolls.
- Every text size in the scenes and code was mapped onto those tiers. The theme default is now 12.
- **Layout fixes for the wider pixel letters:**
  - The game title is 3× with the tagline on two lines, so it no longer runs into the money plaque.
  - The money amount sits lower, inside its plaque.
  - The Settings heading is normal size and wraps.
  - The reset dialog uses the game theme, so its text and buttons are cream instead of dim grey.

## 2026-11-14 — Art consistency pass

- **One outline colour:** the dice and Moss now use the same near-black outline (`0e0b10`) as the room, UI and icons.
- **One pixel size for every icon:** every 16 px icon now draws at exactly 2×, the same grid as the room, dice and helpers. This covers shop cards, tabs, the Ledger and Settings buttons, hat tiles, the info boxes and talent nodes.
  - Before, tabs drew icons at 1.6×, cards at 2.25× and the talent info box at 2.5×.
  - Use `ShopIcons.set_button_picture` instead of stretching an icon to fill a button.
- **Dice icons:** `tools/create_dice_hd.lua` now also renders a 16 px icon per die (its highest face) into `assets/exported/icons/dice_icons.png`. Shop cards and die-devotion talents now match the other icons, instead of showing a crop of the 32 px dice art at half the pixel size.
- **Talent tree links** draw in 2 px blocks on the art grid, like the effects.

## 2026-11-14 — Art upgrade, phase 4: effects

- New `tools/create_effects_hd.lua` redraws the dice contact shadow and the payout spark on the 2× art grid:
  - The shadow is a 22×6 felt-green oval with a darker core, matching the shadows painted under Moss and the table. It now draws at an even 2× instead of 1.5×, and shrinks a little while the die is airborne.
  - The spark is a 9×9 four-point sparkle with a white heart, drawn at 2× instead of being shrunk to 0.6×.
- Arc, blast, gild and reroll effects now draw in pixel blocks snapped to the 2-pixel art grid, instead of smooth anti-aliased lines. They fade in three flat steps.
  - **Arc:** a jagged bolt with a white core.
  - **Blast:** a shock ring that thins as it spreads, with a white inner ring at first.
  - **Gild:** a gold ring, with a sparkle on each gilded die.
  - **Reroll:** a pixel line.
- This completes the art upgrade. Dice, room, tables, helpers, hats, icons, room life and effects now share one pixel grid, one lamp direction, one outline colour and one palette.

## 2026-11-14 — Art upgrade, phase 3: helpers, hats and icons

- New `tools/create_helpers_hd.lua` redraws Moss (12 frames of 24×32) and the eight hats in the dice style: the shared outline, one lamp to the upper left, cel-shaded face, ears, apron and hands, eye highlights, blush and a painted floor shadow.
- Every pose now reads distinctly:
  - a breathing idle,
  - a real 4-frame walk with alternating feet and a body bob (the game now plays all four frames),
  - reaching out for a die,
  - winding up with the die held high, then releasing it with motion pixels,
  - a celebration jump with both arms up, an open mouth and sparkles.
- Hats are outlined and shaded, and follow the head through every frame, including the jump (`HELPER_HEAD_DY` in `main.gd`).
- `tools/create_art_v2.lua` no longer writes the hats.
- Shop and talent icons get a finishing pass in `tools/create_icons.lua`: every shape gets the shared one-pixel outline, and solid areas get a lit top-left edge and a shaded bottom-right edge, so all 53 icons read as one set. The Helper icon is redrawn as the new Moss.
- 18 more icons are redrawn so each shows what it does:
  - Heavy dice: a kettlebell.
  - Table harmony: a pair of matching dice.
  - Quick hands: a mitten with speed lines.
  - Rolling rhythm: a metronome.
  - Strong arms: a flexed arm.
  - Many hands: two hands.
  - Fortune: a four-leaf clover.
  - Fleet of foot: a winged boot.
  - Head start: a coin with a go arrow.
  - Loyal crew: two Moss faces.
  - Golden touch: a shining gold die.
  - Well-paid crew: Moss with a coin.
  - Haggler: a % tag.
  - Bargain hunter: a die with a slashed price tag.
  - House edge: a house with a Fate star over the door.
  - Chip collector: a chip stack with a plus.
  - Chip hoard: a chip pyramid.
  - Divine intervention: a die with a halo.
  - Old friends: a bigger heart.

## 2026-11-14 — A living room

- New `effects/room_life.gd` (RoomLife) animates the room on the same 2-pixel art grid as the art.
- **Idle:**
  - Dust motes drift and twinkle in the lamplight, brighter near the lamp.
  - Each candle casts a banded, flickering glow on the wall. It's drawn additively, so it brightens the wall rather than covering it.
- **Reactive:**
  - **Candles:** the flames lean in a gust when three or more dice are in the air (a table roll or a many-hands throw). They also burn taller and hotter as the hot streak climbs, turning blue-white at INFINITE, and cool back down when the streak ends.
  - **Felt dust** puffs up where each die lands.
  - **The shelf chip stack** shows the chips you hold (one chip per 4, up to 10), and a chip drops onto it with a bounce on every natural 1. It replaces the stack that used to be painted into the room.
  - **Brass glints** sweep along the table rail on combos and across the money plaque on max or critical rolls.
  - **Combos** thump the table by one art pixel.
  - **The ledger** turns a page when you unlock a milestone.
- **Settings:** reduced motion stills the flames and skips gusts, puffs, thumps, chip drops and page turns. Flashes off removes glints, and particles off removes dust and puffs. Everything freezes while the session is paused, and room life never touches game state.
- New `tests/room_life_runner.gd` covers every reaction and settings rule. The 100-die stress test is unchanged at about 143 fps.

## 2026-11-14 — Art upgrade, phase 2: room and tables

- The room is redrawn by `tools/create_art_v2.lua` under the dice's lighting rule: one lamp to the upper left, so top-left edges catch light and bottom-right edges fall into shade.
  - **Walls:** damask wallpaper, with lamplight in flat bands seamed by a one-pixel checker instead of dithering. A crown moulding with dentils runs along the top, and a riveted picture rail sits under the header.
  - **Table:** the rail is carved mahogany with an outer roll, a grain-streaked top, a brass inlay and an inner slope, each side lit evenly from its nearest edge. Brass rosettes sit at the corners, studs line the rails, and the table throws a flat shadow on the wall.
  - **Shop cabinet:** framed in the same carved wood, with rosettes and an inset slatted panel.
  - **Plaques:** the money and Fate plaques get bevelled edges, corner rivets and an inset screen with a shadowed lip.
  - **Props:** outlined candles with wax drips, an outlined ledger with a ribbon, a feathered quill, and a new stack of house chips on the shelf.
- The table surfaces' edge shading is now one flat step instead of a dithered gradient. Their corner marks are now outlined metal L-brackets with a lit edge and a rivet.
- Layout and positions are unchanged. The UI buttons, panels and sell tray keep their existing brass-and-felt skin, which already matched.

## 2026-11-14 — Art upgrade, phase 1: HD dice

- The art direction is now **HD pixel art in the style of Gamblers Table and What the Buck?!**: one fixed pixel grid, a near-black outline, flat cel-shaded tone bands and bright bevel and rim highlights. Colours come from the game's existing palette (the original soft dice colours plus the outline, cream highlight and shade shared with the helpers and table), so the new dice match the rest of the art.
- Every die is redrawn by `tools/create_dice_hd.lua`. It renders each die as a real 3D solid and flattens it into that style:
  - a 3/4 top-down resting view; the d6 family uses a classic cube view (result face forward, lit top lid, shaded right side) with pips inked in a deep shade of each variant's own colour,
  - softly rounded corners on every shape,
  - crisp pixel-font numerals (only the result is shown, so the d12 and d20 stay readable),
  - pips on every d6 face turned towards the viewer,
  - gold glints on the Golden D6 and Gild D12.
- The tumble animation is now 32 frames (was 24). It is a seamless two-axis roll, and the die keeps the same size in every frame.
- Dice now draw at an exact 2× pixel scale (one art pixel on two screen pixels, matching the room) on tables of up to 16 dice, about 46 px across, close to the old size; previously they drew at an uneven 1.3×. Crowded tables step down to 1.5× and 1×.
- Removed `tools/recolor_dice.gd` and `tools/create_roll_art.lua`, which the new script replaces.

## 2026-11-14 — Hold or spend: held Fate and a 39-talent tree

- Removed the hidden +10% income per lifetime Fate. Instead, every Fate you hold unspent adds +1% income, so spending is a visible trade.
- The bonus is shown in four places:
  - the Fate plaque ("FATE 40 · +40%"),
  - the talent tree header,
  - each talent's info line ("Buying it drops your held-Fate bonus from +40% to +30%"),
  - the reset dialog and the Ledger, which also lists total Fate earned.
- The talent tree grew from 11 to 39 talents on a draggable map, with Fortune at the centre. Its branches:
  - **Payouts:** Golden touch, Keen eye, Heavy hitter, Deep pockets, and Endless favor (500 ranks), plus Divine intervention (some 1s become max rolls).
  - **Fate gain:** Destiny.
  - **Helpers:** Well-paid crew, Sharp crew, Extra hands.
  - **Shop:** Bargain hunter, Haggler.
  - **Combos:** Born in harmony, Perfect harmony.
  - **Chips and hats:** Chip collector, Chip hoard, Hat trick.
  - **Streaks and time:** Hot hands, Fire within, Quick hands, Night shift, Weighted fate.
  - **Dice:** one Devotion talent per die family (D4 to D20).
- Some ideas come from Gamblers Table's large talent update, which pays out for hats owned and for holding unused currency.
- Old saves get every spent talent rank back as Fate once, with a notice, so you can choose again from the new tree.
- 20 new talent icons; talent nodes show their icon at 2×.

## 2026-11-14 — A Gamblers Table-style shop

- The shop is now a compact item list: icon tabs (Dice, Upgrades, Helpers & hats, Tables, Fate) with the active one highlighted, and click-to-buy cards showing an icon, name, price (red when you can't afford it) and owned count or level. Descriptions moved to an info box at the bottom of the shop that explains whatever card you point at or tap.
- Only the next locked item in each list is shown, so lists stay short.
- Hats are a picture grid on the Helpers tab (unfound hats show as silhouettes) next to the capsule machine, which shows your chips and reveals each prize with its rarity colour.
- Tables are picture tiles using their real surface art.
- Fate talents open as a node tree over the table, from the Fate tab or by clicking the Fate plaque; a thin bar under the plaque shows progress to the next Fate and the plaque pulses when Fate is ready.
- The header shows chips and hats collected; a natural 1 pops "+1 chip", and reaching 25 chips points you to the capsule.
- Bigger, outlined payout numbers that grow with the amount; Ledger and Settings became icon buttons.
- New 33-icon shop sheet (`tools/create_icons.lua`) and a one-line `summary` on every die, upgrade and talent.

## 2026-11-14 — Helpers, selling, streaks, spreading dice, tables, audio and new art

- **Helpers are the only automation.** Per-family auto-roll is gone; existing saves get its cost refunded as cash with a notice. New helper training on the Helpers page: Strong arms (+50% helper pay), Sharp eyes (pick the most valuable die) and Many hands (throw 2–3 nearby dice together, so helpers can make combinations). Helper cap raised to 12. The Enchanted memory talent became Loyal crew (keep hired helpers across Fate).
- **Sell tray.** Drag any die off the felt into the tray below the table for half the price of its latest copy. Prices drop back accordingly; refunds never count toward Fate.
- **Hot streak.** Quick manual clicks build a streak (×1.25 → ×3) shown above the table; the Momentum upgrade lengthens it.
- **Spreading dice.** Spark D8 arcs to nearby dice for charged ×2 throws, Blast D10 throws its neighbours as one combo-eligible batch, Gild D12 makes neighbours' next roll pay ×3. New arc/blast/gild visuals.
- **Tables and chips.** Natural 1s drop chips. Five tables with lifetime unlocks and rule changes (Green felt, Velvet parlour, Oak workbench, Starlit cloth, Gilded baize), a hat capsule machine and a wardrobe for helpers.
- **Audio fixed on the web.** Sound effects and a new music loop ship as imported WAV assets on a fixed bus layout, which the Web export's sample playback needs; verified playing and looping in a local Web build. New Music toggle in Settings. Regenerate sounds with `tools/generate_audio.gd`.
- **Art pass 1.** Full-screen room with lamplit wallpaper, a mahogany-and-brass table, wallet and Fate plaques and a shop cabinet; five table surfaces; a new 2×-pixel UI skin with a pressed state; sell tray; eight helper hats; Spark/Blast/Gild dice derived from the existing dice style. Masters from `tools/create_art_v2.lua` and `tools/recolor_dice.gd`; `tests/art_preview_runner.gd` renders every table for review.
- 144 gameplay checks plus visual, touch, scroll, cooldown, resize, tumble, ambient, stress and branding runners pass.

## 2026-11-14 — Deeper Fate endgame

- Fate now pays floor(sqrt(run earnings / $25K)): 2 Fate at the $100K threshold, 4 at $400K, 6 at $900K. The Fate page shows the earnings needed for the next Fate.
- Seven new talents: Head start, Heirloom dice, Patient table, Long nights, Old friends, Enchanted memory and House edge. They change how each new run opens (cash, dice, helpers, kept automation), shorten the table cooldown, extend offline earnings and boost Fate gain.
- The prestige confirmation lists what talents carry into the next run. Talent cards name their actual prerequisite.
- Existing saves load unchanged; new talents start at level 0. 17 new gameplay checks; all 112 checks, rendered, touch, scroll, resize and cooldown runners pass.

## 2026-10-17 — Improve touchscreen controls

- Let card and button input propagate to native scroll containers, with an 8-pixel drag threshold and native momentum/button cancellation.
- Increase shop navigation, purchase, settings and developer button minimum heights to 44 logical pixels.
- Tolerate finger jitter when tapping dice and cancel interrupted drags without moving or rolling.
- Add touch-input regression coverage to Windows and Web package verification at desktop and phone landscape sizes.

## 2026-10-16 — Recover empty tables and prevent mirrored mobile layout

- Restore one starter D6 when loading an empty table left by the earlier broken exports, preserving money, upgrades, Fate, settings and statistics. Existing dice are unchanged.
- Explicitly set the main scene layout to left-to-right so inherited RTL layouts cannot move the shop onto the table.
- Add saved-empty-table regression coverage and phone portrait/landscape checks under both layout directions; include resizing checks in export verification.

## 2026-10-16 — Repair exported content loading

- Use export-aware resource discovery to restore the starting die and dice/upgrade shops in Windows and Web exports; report empty catalogs instead of failing silently.
- Preserve Lucky die probability weights during binary export using PackedFloat32Array storage.
- Add a Web export preset and a repeatable script that builds and checks both release packages.
- All 89 gameplay checks and rendered integration pass against both packages; Windows release startup and browser spawning, rolling/payout, and upgrade display verified.

## 2026-10-11 — Restore preferred dice and icon style

- Restored the earlier resting dice faces and rounded infinity icon, including their editable Aseprite masters.
- Kept the tumbling and bounce animation, sizing each rolling frame to its restored die body so it no longer shrinks during rolls.
- All 240 rolling-frame size comparisons, animation checks, branding checks and rendered integration passed.

## 2026-10-11 — Consistent dice artwork and clearer icon

- Rebuilt resting faces and rolling frames from shared polyhedral geometry, palette and lighting, with matching 26-pixel body footprints inside each 32-pixel frame.
- Rolls approach the resting orientation before revealing the result; numbered resting faces retain large readable digits.
- Reworked the application icon as a three-faced die with side pips and a front infinity engraving; refreshed PNG, ICO and layered Aseprite master.
- All 240 rolling-frame footprint comparisons and animation checks passed; 88 gameplay/save checks and rendered integration passed. The local 100-die probe measured 59.84 FPS.

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
