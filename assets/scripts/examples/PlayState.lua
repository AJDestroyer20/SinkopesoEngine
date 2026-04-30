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
