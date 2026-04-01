package gameplay.cinematic;

import flixel.FlxCamera;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;

/**
 * CinematicCamera
 * 
 * Extends FlxCamera behavior with BPM-reactive zoom, dynamic panning,
 * cinematic bars, and scripted camera sequences.
 * 
 * ─── Integration in PlayState ────────────────────────────────────────────
 * 
 *   var camCinematic:CinematicCamera;
 * 
 *   // In create(), after camera setup:
 *   camCinematic = new CinematicCamera(FlxG.camera);
 *   camCinematic.bpm = Conductor.bpm;
 *   camCinematic.beatZoomAmount = 0.03;
 *   camCinematic.beatZoomEnabled = true;
 * 
 *   // In beatHit():
 *   camCinematic.onBeat(curBeat);
 * 
 *   // In update():
 *   camCinematic.update(elapsed);
 * 
 *   // Scripted: push a camera move
 *   camCinematic.pushMove({x:100, y:50, zoom:1.2, duration:2.0, ease:"quadOut"});
 *   camCinematic.showBars(true, 0.5); // letterbox
 */
class CinematicCamera
{
	var cam:FlxCamera;

	// ─── Beat Zoom ───────────────────────────────────────────────────────

	/** Enable camera bump on every beat */
	public var beatZoomEnabled:Bool   = true;

	/** How much zoom is added per beat */
	public var beatZoomAmount:Float   = 0.03;

	/** The base zoom to lerp back to */
	public var baseZoom:Float         = 1.0;

	/** Speed at which zoom lerps back to base */
	public var zoomLerpSpeed:Float    = 3.0;

	/** Only bump every N beats (default 1 = every beat) */
	public var beatZoomInterval:Int   = 1;

	// ─── HUD Camera ──────────────────────────────────────────────────────

	/** Optional HUD camera to also bump */
	public var hudCamera:FlxCamera = null;
	public var hudBeatZoomAmount:Float = 0.01;

	// ─── Move Queue ──────────────────────────────────────────────────────

	var moveQueue:Array<CamMove>      = [];
	var currentMove:CamMove           = null;
	var moveTween:FlxTween            = null;

	// ─── Cinematic Bars ──────────────────────────────────────────────────

	var topBar:flixel.FlxSprite    = null;
	var bottomBar:flixel.FlxSprite = null;
	var barsShown:Bool             = false;

	// ─── State ───────────────────────────────────────────────────────────

	public var bpm:Float = 100;

	public function new(camera:FlxCamera)
	{
		cam = camera;
		baseZoom = camera.zoom;
	}

	// ─── BEAT HIT ────────────────────────────────────────────────────────

	public function onBeat(beat:Int):Void
	{
		if (!beatZoomEnabled) return;
		if (beat % beatZoomInterval != 0) return;

		cam.zoom += beatZoomAmount;
		if (hudCamera != null) hudCamera.zoom += hudBeatZoomAmount;

		// Process move queue
		if (currentMove == null && moveQueue.length > 0)
			startNextMove();
	}

	// ─── UPDATE ──────────────────────────────────────────────────────────

	public function update(elapsed:Float):Void
	{
		// Lerp camera zoom back to base
		cam.zoom = lerp(cam.zoom, baseZoom, zoomLerpSpeed * elapsed);
		if (hudCamera != null)
			hudCamera.zoom = lerp(hudCamera.zoom, 1.0, zoomLerpSpeed * elapsed);
	}

	// ─── SCRIPTED MOVES ──────────────────────────────────────────────────

	/**
	 * Push a camera move to the queue.
	 * It will execute when the current move finishes (or immediately if idle).
	 */
	public function pushMove(move:CamMove):Void
	{
		moveQueue.push(move);
		if (currentMove == null)
			startNextMove();
	}

	/** Immediately execute a camera move (interrupts current) */
	public function forceMove(move:CamMove):Void
	{
		if (moveTween != null) { moveTween.cancel(); moveTween = null; }
		currentMove = null;
		moveQueue.unshift(move);
		startNextMove();
	}

	function startNextMove():Void
	{
		if (moveQueue.length == 0) { currentMove = null; return; }
		currentMove = moveQueue.shift();

		var ease = resolveEase(currentMove.ease ?? "linear");
		var props:Dynamic = {};

		if (currentMove.zoom != null) { baseZoom = currentMove.zoom; props.zoom = currentMove.zoom; }

		if (currentMove.x != null || currentMove.y != null)
		{
			// Camera offset (scroll)
			if (currentMove.x != null) props.scrollX = currentMove.x;
			if (currentMove.y != null) props.scrollY = currentMove.y;
		}

		moveTween = FlxTween.tween(cam, props, currentMove.duration ?? 1.0, {
			ease:      ease,
			onComplete: function(_) {
				currentMove = null;
				moveTween = null;
				startNextMove();
			}
		});
	}

	function resolveEase(name:String):Float->Float
	{
		return switch (name)
		{
			case "quadIn":    FlxEase.quadIn;
			case "quadOut":   FlxEase.quadOut;
			case "quadInOut": FlxEase.quadInOut;
			case "cubeIn":    FlxEase.cubeIn;
			case "cubeOut":   FlxEase.cubeOut;
			case "elasticOut":FlxEase.elasticOut;
			case "bounceOut": FlxEase.bounceOut;
			case "sineIn":    FlxEase.sineIn;
			case "sineOut":   FlxEase.sineOut;
			default:          FlxEase.linear;
		};
	}

	// ─── CINEMATIC BARS ──────────────────────────────────────────────────

	/**
	 * Show/hide letterbox bars.
	 * duration: time in seconds for bars to slide in/out
	 */
	public function showBars(show:Bool, duration:Float = 0.5):Void
	{
		if (show == barsShown) return;
		barsShown = show;

		if (topBar == null) initBars();

		var targetTop:Float    = show ? 0 : -topBar.height;
		var targetBottom:Float = show ? flixel.FlxG.height - bottomBar.height : flixel.FlxG.height;

		FlxTween.tween(topBar,    {y: targetTop},    duration, {ease: FlxEase.quadOut});
		FlxTween.tween(bottomBar, {y: targetBottom}, duration, {ease: FlxEase.quadOut});
	}

	function initBars():Void
	{
		var barHeight = 60;
		topBar    = new flixel.FlxSprite(0, -barHeight).makeGraphic(flixel.FlxG.width, barHeight, flixel.util.FlxColor.BLACK);
		bottomBar = new flixel.FlxSprite(0, flixel.FlxG.height).makeGraphic(flixel.FlxG.width, barHeight, flixel.util.FlxColor.BLACK);
		topBar.scrollFactor.set(0, 0);
		bottomBar.scrollFactor.set(0, 0);
		topBar.cameras    = [cam];
		bottomBar.cameras = [cam];
		if (PlayState.instance != null)
		{
			PlayState.instance.add(topBar);
			PlayState.instance.add(bottomBar);
		}
	}

	// ─── QUICK EFFECTS ───────────────────────────────────────────────────

	public function flash(color:Int = 0xFFFFFFFF, duration:Float = 0.5):Void
	{
		cam.flash(color, duration);
	}

	public function shake(intensity:Float = 0.01, duration:Float = 0.3):Void
	{
		cam.shake(intensity, duration);
	}

	/** Dramatic slow zoom to a target then snap back */
	public function dramaticZoom(target:Float, holdTime:Float, snapBack:Bool = true):Void
	{
		pushMove({zoom: target, duration: 0.8, ease: "cubeIn"});
		if (snapBack)
			new FlxTimer().start(holdTime, function(_) {
				pushMove({zoom: baseZoom, duration: 0.4, ease: "elasticOut"});
			});
	}

	inline function lerp(a:Float, b:Float, t:Float):Float
		return a + (b - a) * Math.min(t, 1.0);
}

typedef CamMove =
{
	@:optional var x:Float;
	@:optional var y:Float;
	@:optional var zoom:Float;
	@:optional var duration:Float;
	@:optional var ease:String;
}
