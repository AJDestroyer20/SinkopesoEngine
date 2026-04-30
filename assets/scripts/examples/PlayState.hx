// HScript-Iris style PlayState example (high-level behavior script)
var pulse = 0.0;

function onCreate() {
	trace('PlayState.hx script loaded');
	set('customMessage', 'HScript runtime active');
}

function onUpdate(elapsed) {
	pulse += elapsed;
	if (pulse > 0.25) {
		pulse = 0;
		cameraShake(0.0015, 0.03);
	}
}

function onBeatHit(curBeat) {
	if (curBeat % 4 == 0) {
		doTweenAlpha('hudPulse', 'camHUD', 0.9, 0.07);
		doTweenAlpha('hudPulseBack', 'camHUD', 1, 0.14);
	}
}
