# Roadmap and quality gates

## Implemented and exercised
- [x] Foundation/state/content/economy separation and versioned persistence.
- [x] One-D6 controllable roll, stable face reveal and payout feedback.
- [x] Core purchasing, multiple dice, upgrades and estimated income.
- [x] Editable Aseprite sources and export pipeline.
- [x] One walking helper and helper-speed upgrades.
- [x] Lucky, exploding and spatial-multiplier dice.
- [x] Doubles, triples, straight, max-trigger neighbor rerolls and depth bounds.
- [x] Fate prestige and a first four-talent tree.
- [x] Settings, contextual hints, local milestones, tests and documentation.

## Required before commercial release
- [ ] Human review of the first 30 seconds and 1,000-roll feel; do not treat passing tests as this approval.
- [ ] Long-session economy tuning, progression telemetry and exploit/degenerate-build review.
- [ ] Art-direction review and richer hand-polished Aseprite animations, table details and UI icons.
- [ ] Music/ambience composition and final audio mix; current synthesized cues are functional original sound design.
- [ ] More intentional helper interaction/celebration timing and priorities.
- [ ] Keyboard remapping, gamepad navigation, screen-reader support and localization.
- [ ] Extended save soak/power-interruption/platform testing, profile management and cloud conflict design.
- [x] Controlled 60-second 100-die/eight-helper rendering baseline with real frame intervals and active payout verification.
- [ ] Longer visible mixed-build performance soak, investigate any recurring spikes and qualify exported builds on additional hardware.
- [ ] Export presets/release packaging, licenses/credits, Steam achievements and Steam Cloud.
- [ ] Expand talent content only after early progression is tuned.
- [ ] Replace finite float money with mantissa/exponent representation if the target economy exceeds 1e100.
- [x] Retire unreferenced legacy scripts/resources after migration; original sources remain in Git.

## Future content (not requested for immediate implementation)
Banker/Copycat/Vampire/Chaos/Glass/Mimic, machines, crafting/fusion, rooms, challenges, minigames, multiple prestige layers, leaderboards and cosmetics. Add state and effects at the owning service boundary rather than growing the tabletop UI into a gameplay manager.
