# Save format

## Files and version
user://progress.json contains {"save_version":1,"state":{...}}. The display name is D- infinity, but a custom user directory keeps the existing DiceIncremental save location (on Windows: %APPDATA%/Godot/app_userdata/DiceIncremental). The rename does not move or replace player files. progress.json.bak is the previous validated primary. progress.json.tmp is the write candidate.

State contains money, run_earned, dice, counts, upgrades, automatic (legacy; refunded and emptied on load), talents, statistics, achievements, helpers (0–12), prestige_points, prestige_total, next_id, tutorial_step, settings (now including music), last_saved, rng_state, and the optional chips, hats, crew_hat, table_id, tables and fate_version. A save without fate_version (1) predates the 39-talent tree: on load every spent talent rank is refunded as Fate, talents are cleared and fate_version becomes 2. Each die contains id, definition_id, x, y, face, automatic_clock (legacy) and optional gilded. Missing optional fields default (0 chips, no hats, felt table); unknown hats or tables are dropped and an unowned table falls back to felt. Resource files and Nodes are never serialized.

## Lifecycle

Optional `table_roll_remaining` stores 0–60 seconds of the shared table-roll cooldown. Missing values in older saves default to zero. Invalid values are rejected. Loaded cooldown decreases by elapsed offline time through the existing offline step; it is not cleared just by saving or restarting.
Startup validates primary and falls back to backup when primary is corrupt. Unsupported newer versions are protected and disable saving. If both files are invalid, originals remain untouched and the UI reports that saving is disabled. No automatic reset destroys unrecognized data.

Autosave every 30 seconds when no roll is pending; explicit save and exit settle pending outcomes exactly once with chains disabled. Written state is validated, serialized to .tmp, flushed, a valid primary is copied to .bak, and the candidate is promoted by rename. Failures retain prior files and surface status. Disk roundtrip, replacement and corrupt-primary recovery are tested on Windows. Cross-filesystem/power-loss guarantees require platform qualification and are not claimed.

## Migration
Original save.json is read only if progress.json does not exist. A valid currency-only legacy document becomes a new state preserving its money and granting the starter D6. Missing legacy dice/upgrades cannot be reconstructed. Legacy file is not overwritten.

Counts are derived from validated owned instances on load instead of trusting the redundant counts dictionary. Content IDs must exist. Amounts must be finite and in range, IDs/levels integer, positions within table bounds, and settings must have expected types. RNG state is a decimal string.

## Reset
The Settings confirmation explicitly warns that all progression, Fate and talents reset. It saves and archives the current primary to a timestamped .reset-* file before starting fresh. A failed archive cancels reset. Protected saves cannot be reset through this flow.

## Tests
--test bypasses the production SaveManager. Disk fixtures use unique test-only filenames and clean up only their own paths. Headless tests and rendered test runners must always use -- --test.

On the Web, user:// is the browser's IndexedDB, which Godot syncs asynchronously. SaveManager therefore also autosaves every 5 seconds (30 on desktop), saves on the page's visibilitychange (hidden) and pagehide events and on focus loss or app pause, and mirrors every verified save to localStorage under the key "d-infinity/progress.json". On load the newer of the file and the mirror (by state.last_saved) is used, so progress survives a tab or browser being closed straight after an action, and survives losing the IndexedDB copy.
