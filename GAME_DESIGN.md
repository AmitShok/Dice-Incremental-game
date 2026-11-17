# Game design

## North star
A cozy die-rolling table becomes an engine for controlling probability. Gamblers Table informs object accumulation, earned helpers and build-changing progression; artwork, character design and mechanics here are original.

## Current loop
One free Ivory D6, zero cash. Click a die, or Space/roll-table for a batch. A roll includes anticipation, lift, tumble, landing, revealed face, sound and payout. Cash buys dice, upgrades and helpers. Dragging sets logical spatial position; dragging into the sell tray sells. There is a 100-die table cap and twelve-helper cap.

The free starter replaces the previous $10/empty-table opening deliberately, avoiding an initial shop action before the first satisfying roll. Its ownership counts toward the D6 cost curve; the second D6 costs $20. Existing D6/D20/Golden price bases remain.

## Mechanical identity
Lucky changes probability. Ember explodes on maxima with a depth cap. Prism boosts other dice within 115 logical pixels by 50%; multiple Prism auras do not stack. Loaded corners doubles upper-half weights for ordinary D6. Lucky sixes triples natural six payouts. Table harmony enables doubles ×2, triples ×5 and a 1–5 straight ×8. Highest combination wins, and its multiplier affects that roll batch. A helper with Many hands throws its dice as one batch; separate helpers are separate batches.

Helpers are the only automation (per-family auto-roll was retired; old purchases are refunded as cash on load). Each helper walks to a ready die and throws it. Training on the Helpers page makes them faster (Quick hands), pay more (Strong arms, +50% per level on helper-thrown dice), smarter (Sharp eyes: walk to the most valuable ready die, gilded dice count triple) and handier (Many hands: grab 1–2 more dice within 110px and throw them together, so helper throws can make combinations). Up to twelve helpers.

Manual play stays relevant through the hot streak: each manual click within 2.5s of the last (Momentum lengthens it, Velvet halves it) adds 1. Stages multiply every payout while active: 10 ×1.25, 25 ×1.5, 50 ×2, 100 ×3. Roll the table counts as one click.

Selling: drag a die off the felt into the sell tray below the table to get half the price of its family's most recent copy. Refunds are not run earnings. The last die and rolling dice cannot be sold.

Spreading dice (inspired by chain-reaction incrementals, original names and art): Spark D8 arcs to the two nearest ready dice within 160px on 5+, which roll charged ×2. Blast D10 on a natural 10 throws every ready die within 130px as one batch, so combinations count. Gild D12 on a natural 12 gilds dice within 120px; a gilded die's next roll pays ×3 once. Effects are bounded by depth like Ember.

Tables and chips: every natural 1 drops a chip. The Tables page holds five surfaces with lifetime unlocks that survive Fate: Green felt (no rules), Velvet parlour (25 combinations: combos ×1.5, streak window halved), Oak workbench (8 helpers at once: helpers 50% faster, manual clicks pay 25% less), Starlit cloth (first Fate: maximum faces ×2, ones pay nothing but drop 2 chips), Gilded baize (gild 100 dice: gilded ×5 instead of ×3, Gild dice 30% cheaper). A capsule machine turns 25 chips into a random cosmetic helper hat (common, rare, legendary); duplicates refund 10 chips. The wardrobe puts one hat on every helper or mixes them.

## Fate
Name explicitly chosen by the user. Beginning again needs $100K run earnings the first time, and $100K more after every fresh start ($200K, $300K, and so on; ProgressionService.prestige_threshold). It resets money, dice, ordinary upgrades and helpers; receive floor(sqrt(run earnings / 25000) × House edge) Fate, so the first threshold grants 2, later thresholds grant more, and the Fate page shows the earnings needed for the next one. Every Fate you hold unspent grants +1% income (shown on the Fate plaque, talent tree, reset dialog and Ledger); lifetime Fate gives no bonus by itself, so spending is a trade against that bonus. Fate buys 39 Resource-defined talents on a full-screen map (scenes/ui/talent_tree.tscn, laid out from each talent's tree_position with Fortune at the centre) in branches for payouts and criticals, Fate gain, helpers, run starts and shop discounts, combos and chips, streaks and time, and one devotion talent per die family; Endless favor has 500 ranks as a long-term sink. Talent ranks, total Fate, settings, achievements and lifetime statistics survive. A confirmation describes exactly what resets and what talents carry into the next run.

Talent tree (prerequisite in brackets): Fortune favors you; Critical chance, Fleet of foot, Resonance [Fortune]; Head start ($500/$5K/$50K starting cash) [Fortune]; Heirloom dice (+1 starting D6 per level) [Head start]; Patient table (table cooldown ×0.75 per level) [Fortune]; Long nights (+4h offline cap per level) [Fortune]; Old friends (+1 starting helper per level) [Fleet of foot]; Loyal crew (keep every hired helper across resets) [Old friends]; House edge (+25% Fate per level, multiplicative) [Critical chance]. Run-start talents shape how each new run opens rather than only raising income, giving repeated resets distinct goals.

## Onboarding and accessibility
Contextual guidance explains first roll, first purchase and combination unlock. Hover describes dice. Music, sound effects, motion, counter flashes, floating payouts and particles are independently switchable, with volume control. Space rolls all available dice. Focusable shop buttons support keyboard navigation. Screen-reader support, remapping and localization remain release tasks.

## Not implemented by design
Crafting, fusion, multiple rooms, challenge runs, minigames, multiple prestige layers, machines and Steam integrations remain future content. No imitation characters, ripped sprites, copied UI artwork or reference audio.
