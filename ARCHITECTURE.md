# Architecture

## Ownership
Two thin existing autoload names remain: GameManager composes/ticks GameSession; SaveManager handles startup, autosave and exit persistence. They do not own dice formulas.

GameSession coordinates commands and pending roll transactions. GameState owns serializable progress; DiceInstance is RefCounted state, not an unattached Node. ContentRegistry loads validated .tres definitions from dice, upgrades and talents directories in filename order. A die's Resource never changes when a player purchases something. Counts are reconstructed from owned instances on load.

EconomyService validates spending and resolves modifiers. ProgressionService owns purchase and prestige commands. RollSystem provides weighted, seedable sampling and a render-free simulation. AutomationService schedules per-family auto rolls and walking helper state. StatisticsService handles resolved-outcome counts and local milestones. GameEvents is a session-scoped signal bus.

Presentation consists of the main tabletop controller, ShopPanel, reusable scenes/d_6.tscn (now a generic DiceVisual), AudioService and pooled FeedbackManager. UI sends commands; it never writes arbitrary payout/currency values except explicitly gated developer controls.

## Roll transaction
request_roll validates each ID, reserves idle instances, samples faces and constructs a uniquely identified pending outcome with payout snapshotted at request time. Batch combinations are computed only for that request. Events start visual animation. A central session tick commits the outcome after its duration, exactly once. Rendering does not choose results or award money. settle() commits pending rolls without creating new chains for save/exit/prestige.

Manual and automatic rolls share this path. Invalid/deleted targets are ignored. Pause suspends simulation. RNG state is saved as a decimal string to avoid JSON number precision loss. Pending animations themselves are not saved; settled state is.

## Effects
EffectDefinition expresses trigger, condition, target, action, radius and maximum depth. The first action is reroll, supporting self and nearest ready target, maximum/minimum/always conditions. Ember and Chain reaction reference these Resources. Upgrade/talent effects merge with die effects; duplicate targets are deduplicated. Maximum chain depth is four and pending outcomes are bounded to 100. New action families should be added to a focused effect executor with tests, not into UI scripts. Prism aura currently uses a simple one-aura proximity query; general spatial indexes are unnecessary at the measured 100-die cap.

## Performance
One session scheduler and one helper-visual loop; individual dice process only during rolling. HUD refreshes coalesce, shop affordability updates at 2.5 Hz, effect pools cap at 40 labels/80 sparks, audio at 12 voices. Large tables reduce die visual scale and aggregate payout text. No unbounded offline physics simulation.

## Extension examples
Add D100 with a valid DiceDefinition, 100-frame Aseprite face sheet and presentation reference; shop enumeration needs no edit. Add an upgrade/talent through UpgradeDefinition and existing stat/effect operators. A new behavior such as Banker needs explicit saved instance state and resolution semantics; the current architecture provides boundaries but does not falsely claim such a mechanic is already implemented.

Services are tested without scene nodes. Avoid creating an autoload for every subsystem. Keep commands authoritative and events observational.
