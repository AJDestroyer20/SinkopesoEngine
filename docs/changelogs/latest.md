# Latest (master) changelog

## Additions
- Added HScript-Iris backend integration scaffold in `HaxeScriptBackend` with guarded runtime loading and error-safe fallback behavior.
- Added script loading priority system in `ScriptManager`: `.hx` -> `.hxc` -> `.lua`.
- Added richer advanced state script examples (`PlayState.hx`, `TitleState.hxc`, and Lua fallback example).
- Added compile/setup script updates for `hscript-iris` dependency and clearer build failure messaging.

## Changes
- Script folder loading now prioritizes HScript files before Lua files.
- README and wiki scripting docs updated in English with priority/fallback behavior.

## Stability
- Build scripts now stop on first target failure and print actionable repair guidance.
- HScript backend initialization is exception-guarded and can gracefully deactivate on runtime errors.
