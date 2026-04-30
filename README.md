# Sinkopeso Engine

Sinkopeso Engine is a rhythm-game framework built on HaxeFlixel, focused on modular architecture, scripting, modding, and long-term maintainability.

## Current Highlights
- Centralized `GameContext` service container.
- Config-driven boot via `assets/data/data.json`.
- Global pub/sub `EventBus`.
- Multi-backend scripting foundations (Lua + HaxeScript scaffold).
- Audio service integration with reactive audio hooks.
- Psych-like mod layout support plus compatibility scanning and export scaffolding.
- Camera controller, diagnostics utilities, and gameplay extensibility primitives.

## Quick Structure
- `source/core`: config, context, events, state helpers.
- `source/systems`: audio, scripting, mods, plugins, debug, camera, save, logic.
- `source/gameplay`: chart adapters, event graph, AI helpers.

## Scripting API (Psych-inspired baseline)
Available Lua helpers include:
- `playSound`
- `cameraShake`
- `cameraFlash`
- `startTimer`
- `runHaxeCode`
- `addSprite`
- `removeSprite`
- `setProperty` / `getProperty`
- `doTweenX` / `doTweenY` / `doTweenAlpha` / `doTweenAngle`

Script examples for each state/substate are under:
- `assets/scripts/examples/`

## Accuracy Ranks
Gameplay HUD now exposes rank bands:
- F, D, C, B, A, A+

## Debugging
- Press `F3` in `PlayState` to run runtime diagnostics.

## Wiki
See `docs/wiki/` for implementation notes and help pages.


## Script loading priority
- The engine now attempts **HScript first** (`.hx`, then `.hxc`).
- If HScript fails and a Lua script with the same basename exists, it falls back to `.lua`.
