# Latest (master) changelog

## Additions
- Added Psych-inspired Lua API baseline (`PsychLuaAPI`) and bound core script helpers for camera/audio/tween/property operations.
- Added accuracy rank system (`F` to `A+`) through `AccuracyRank` and HUD rank output in gameplay.
- Added per-state/substate Lua script examples under `assets/scripts/examples`.
- Added English wiki pages in `docs/wiki` (Architecture, Scripting API, Mods Compatibility, Troubleshooting).

## Changes
- Updated README to English and expanded framework documentation.
- Extended Lua script bootstrap to register Psych-style API helpers automatically.

## Stability
- Improved debuggability by documenting diagnostics and troubleshooting flow.
- Kept systems modular so failures are easier to isolate and fix.
