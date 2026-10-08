# Economy

## Contracts
Amounts use double-precision floats capped at 1e100. This is a defined finite range, not arbitrary precision. Purchases reject nonfinite, nonpositive and unaffordable prices. UI formatting uses K/M/B/T and scientific notation beyond named suffixes. A future mantissa/exponent money type can replace this boundary if design exceeds the range.

Per-family die cost = base_cost × cost_growth ^ owned_count; default growth 2. Starter D6 counts as owned. Ordinary upgrade cost = base × growth ^ current_level. Helpers cost 250 × 2.8 ^ hired, up to eight.

Payout = (natural face + flat bonus) × die base payout × matching upgrade modifiers × (1 + lifetime Fate × 0.1) × batch combination × spatial aura × critical. Additive modifier contributions are summed before multiplicative factors. Conditions inspect natural face. Values are fixed when the roll is reserved, so mid-animation purchases cannot retroactively change payout.

## Timing and probabilities

Roll the table (button or Space) has a shared 60-second cooldown after a successful batch. Individual clicks and automatic/helper rolls retain their per-die timing. The table timer uses simulation time (including developer speed/pause), persists across saving, and decreases while offline. Historical scripted batch pacing probes below do not model this new table-action restriction.

All ordinary dice (D4, D6, D8, D10, D12, D20) have base payout 1: a natural 5 pays $5 before bonuses. Special dice retain their advertised multipliers: Golden ×10, Lucky ×2, Ember ×3, Prism ×2. Upgrades, Fate, combos, auras and criticals can still increase payouts. Hovering a landed die shows its last face and awarded amount. Earlier scripted pacing numbers below predate the ordinary-die payout correction and need retuning.
Dice duration is authored per definition and divided by roll-speed modifier. Post-landing cooldown 0.15s. Automatic clocks preserve fractions, accumulate during rolling and cap backlog at five seconds. The system processes ready dice each update; it does not retrospectively simulate unlimited rolls in a long frame.

Fair distributions default to unit weights. Lucky D6 = [1,1,1,1,3,3], giving P(5 or 6)=0.6. Loaded corners doubles ordinary D6 upper-half weights. Critical talent gives 10% chance of ×3 payout, expected multiplier 1.2. RNG for visuals/audio never consumes gameplay RNG.

## Estimates / offline
Displayed ~income/sec is an analytical estimate: weighted expected payout, current bonuses and aura; automatic rate uses max(interval, roll duration + cooldown). Helper estimate assumes a three-second travel/action cycle adjusted by helper speed and number of eligible dice. It is not a measured throughput meter and does not include chain/explosion/combo gains.

Offline earnings = min(max(time away,0),4 hours) × estimated production × 0.5. It grants cash and offline/lifetime money statistics, not fictitious physical rolls. Backward clock movement yields zero. Local clock manipulation cannot be fully prevented in an offline game.

## Balance tooling
tools/balance.gd prints definition base prices, expected payout, automation price and nominal one-die payback. RollSystem.simulate_rolls runs without scenes. Tests cover fair/weighted distributions and a million-roll sample.

## Initial targets
First roll immediately; second basic die after a few manual rolls; first helper as a noticeable earned change; first Fate reset within a focused early session. These are design targets, not measured player retention or validated long-session timings. Original expensive Golden automation is retained, and broader pacing needs human playtests before release.

## Initial pacing probe
A seeded automated buyer throwing every 1.2 seconds reached its first helper at 37.8s and combinations at 72.9s. The original $25K prestige gate arrived at 119.8s, too early for the intended engine-building stage. The gate was raised to $100K and centralized in ProgressionService.PRESTIGE_THRESHOLD. These are scripted probes, not human playtest results.

With the $100K gate, the same automated probe reached first Fate at 231.4s with 18 dice. Helper behavior subsequently gained explicit interaction/celebration delays; this remains an indicative probe rather than a fixed timing guarantee.
