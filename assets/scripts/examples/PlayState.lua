-- Advanced PlayState Lua example
local elapsedAcc = 0

function onCreate()
  trace('PlayState.lua fallback script loaded')
  setProperty('camHUD', 'alpha', 1)
  playSound('introGo')
end

function onUpdate(elapsed)
  elapsedAcc = elapsedAcc + elapsed
  if elapsedAcc >= 0.5 then
    elapsedAcc = 0
    cameraShake(0.001, 0.05)
  end
end

function onBeatHit(curBeat)
  if curBeat % 2 == 0 then
    doTweenAngle('hudTw', 'camHUD', 1.5, 0.08)
    doTweenAngle('hudTwBack', 'camHUD', 0, 0.12)
-- Example script for PlayState
function onCreate()
  trace('PlayState: onCreate')
end

function onUpdate(elapsed)
  -- your per-frame logic
end

function onBeatHit(curBeat)
  if curBeat % 4 == 0 then
    cameraShake(0.002, 0.05)
  end
end
