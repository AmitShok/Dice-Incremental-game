# Save format

## Files and version
user://progress.json contains {"save_version":1,"state":{...}}. The display name is D- infinity, but a custom user directory keeps the existing DiceIncremental save location (on Windows: %APPDATA%/Godot/app_userdata/DiceIncremental). The rename does not move or replace player files. progress.json.bak is the previous validated primary. progress.json.tmp is the write candidate.

State contains money, run_earned, dice, counts, upgrades, automatic, talents, statistics, achievements, helpers, prestige_points, prestige_total, next_id, tutorial_step, settings, last_saved and rng_state. Each die contains id, definition_id, x, y, face and automatic_clock. Resource files and Nodes are never serialized.

## Lifecycle
Startup validates primary and falls back to backup when primary is corrupt. Unsupported newer versions are protected and disable saving. If both files are invalid, originals remain untouched and the UI reports that saving is disabled. No automatic reset destroys unrecognized data.

Autosave every 30 seconds when no roll is pending; explicit save and exit settle pending outcomes exactly once with chains disabled. Written state is validated, serialized to .tmp, flushed, a valid primary is copied to .bak, and the candidate is promoted by rename. Failures retain prior files and surface status. Disk roundtrip, replacement and corrupt-primary recovery are tested on Windows. Cross-filesystem/power-loss guarantees require platform qualification and are not claimed.

## Migration
Original save.json is read only if progress.json does not exist. A valid currency-only legacy document becomes a new state preserving its money and granting the starter D6. Missing legacy dice/upgrades cannot be reconstructed. Legacy file is not overwritten.

Counts are derived from validated owned instances on load instead of trusting the redundant counts dictionary. Content IDs must exist. Amounts must be finite and in range, IDs/levels integer, positions within table bounds, and settings must have expected types. RNG state is a decimal string.

## Reset
The Settings confirmation explicitly warns that all progression, Fate and talents reset. It saves and archives the current primary to a timestamped .reset-* file before starting fresh. A failed archive cancels reset. Protected saves cannot be reset through this flow.

## Tests
--test bypasses the production SaveManager. Disk fixtures use unique test-only filenames and clean up only their own paths. Headless tests and rendered test runners must always use -- --test.
