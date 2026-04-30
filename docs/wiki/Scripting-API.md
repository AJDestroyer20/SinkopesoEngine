# Scripting API (Lua)

Psych-inspired baseline helpers currently include:
- Property access: `getProperty`, `setProperty`
- Tween helpers: `doTweenX`, `doTweenY`, `doTweenAlpha`, `doTweenAngle`
- Camera FX: `cameraShake`, `cameraFlash`
- Audio: `playSound`
- Utility: `startTimer`, `runHaxeCode`, `addSprite`, `removeSprite`

Examples are in `assets/scripts/examples`.


## Priority & fallback
Script loading priority is:
1. `.hx` (HScript-Iris)
2. `.hxc` (HScript-Iris)
3. `.lua` fallback

If HScript fails to initialize, Lua with the same base name can be used as fallback.
