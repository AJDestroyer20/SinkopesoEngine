package audio;

import flixel.FlxG;

#if FEATURE_VIDEO
import hxvlc.flixel.FlxVideoSprite;
#end

/**
 * VideoHandler — SinkopesoEngine
 *
 * Cross-platform video player backed by hxvlc 2.0.1 (libvlc).
 *
 * ─── Bug Fixes ────────────────────────────────────────────────────────────
 *   Fix #5: update() was directly setting sprite.width / sprite.height.
 *            In HaxeFlixel, width/height on FlxSprite are read-only aliases
 *            for the frame size — they are NOT the display scale. Writing to
 *            them has NO effect at runtime. The correct call is setGraphicSize().
 *   Fix #6: update() called GlobalVideo.calc() 4× per frame (once per index).
 *            Now uses GlobalVideo.calcAll() — single calculation per frame.
 *   Fix #7: stop() set stopped = true OUTSIDE the #if FEATURE_VIDEO guard,
 *            so on non-video platforms the bool state got corrupted even though
 *            no actual stop happened. Moved inside the guard consistently.
 *   Fix #8: restart() called stop() then play() but stop() hid the sprite.
 *            play() made it visible again, but for one frame the sprite was
 *            invisible — causing a flicker. Reorder: play() then visibility.
 *   Fix #9: clearPause() called sprite.resume() even when the video was
 *            never paused. hxvlc resume() on a playing video is a no-op on
 *            most platforms but causes a seek-to-start on some. Added guard.
 */
class VideoHandler
{
	// ─── Public state ─────────────────────────────────────────────────────────

	public var vidPath:String    = "";
	public var initialized:Bool = false;

	public var stopped:Bool   = false;
	public var restarted:Bool = false;
	public var played:Bool    = false;
	public var ended:Bool     = false;
	public var paused:Bool    = false;

	/** Callback fired when video finishes. Set before play(). */
	public var onEnd:Void->Void = null;

	#if FEATURE_VIDEO
	/** The hxvlc sprite. Add this to your FlxState with add(). */
	public var sprite:FlxVideoSprite;
	#end

	// ─── Constructor ──────────────────────────────────────────────────────────

	public function new() {}

	// ─── Source ───────────────────────────────────────────────────────────────

	public function source(?vPath:String):Void
	{
		if (vPath != null && vPath.length > 0)
			vidPath = vPath;
	}

	// ─── Lifecycle ────────────────────────────────────────────────────────────

	/**
	 * Create the FlxVideoSprite. Call before play().
	 * After this, add sprite to your state: add(videoHandler.sprite)
	 */
	public function makePlayer():Void
	{
		#if FEATURE_VIDEO
		sprite = new FlxVideoSprite(0, 0);
		sprite.antialiasing = true;
		sprite.visible      = false;

		sprite.bitmap.onEndReached.add(() -> {
			ended = true;
			if (onEnd != null) onEnd();
		});
		sprite.bitmap.onOpening.add(() -> { played = true; });
		sprite.bitmap.onStopped.add(() -> { stopped = true; });

		initialized = true;
		#else
		trace("[VideoHandler] FEATURE_VIDEO not set — video disabled on this target.");
		#end
	}

	/**
	 * Update position/size to match letterbox. Call in update().
	 *
	 * Fix #5: Use setGraphicSize() — NOT sprite.width = / sprite.height =.
	 * Fix #6: Use calcAll() for one math pass instead of four.
	 */
	public function update(elapsed:Float):Void
	{
		#if FEATURE_VIDEO
		if (sprite == null) return;
		var r = GlobalVideo.calcAll();
		sprite.x = r[0];
		sprite.y = r[1];
		sprite.setGraphicSize(Std.int(r[2]), Std.int(r[3]));
		sprite.updateHitbox();
		#end
	}

	// ─── Playback ─────────────────────────────────────────────────────────────

	public function play():Void
	{
		#if FEATURE_VIDEO
		if (!initialized || sprite == null) return;
		sprite.load(vidPath);
		sprite.play();
		sprite.visible = true;
		stopped = false; // Fix #7: reset stopped state when playing
		ended   = false;
		#end
	}

	public function stop():Void
	{
		#if FEATURE_VIDEO
		if (sprite == null) return;
		sprite.stop();
		sprite.visible = false;
		stopped = true; // Fix #7: only set inside guard
		#end
	}

	/**
	 * Fix #8: Avoid one-frame invisible flicker.
	 * Load the new media before showing, then mark restarted.
	 */
	public function restart():Void
	{
		#if FEATURE_VIDEO
		if (sprite == null) return;
		sprite.stop();
		sprite.load(vidPath);
		sprite.play();
		sprite.visible = true;
		stopped   = false;
		ended     = false;
		restarted = true;
		#end
	}

	public function pause():Void
	{
		#if FEATURE_VIDEO
		if (sprite == null) return;
		sprite.pause();
		#end
		paused = true;
	}

	public function resume():Void
	{
		#if FEATURE_VIDEO
		if (sprite == null) return;
		sprite.resume();
		#end
		paused = false;
	}

	public function togglePause():Void
	{
		if (paused) resume() else pause();
	}

	/**
	 * Fix #9: Only call sprite.resume() if we were actually paused,
	 * to avoid triggering a seek-to-start on some libvlc versions.
	 */
	public function clearPause():Void
	{
		if (paused)
		{
			paused = false;
			#if FEATURE_VIDEO
			if (sprite != null) sprite.resume();
			#end
		}
	}

	// ─── Visibility / alpha ───────────────────────────────────────────────────

	public function show():Void
	{
		#if FEATURE_VIDEO
		if (sprite != null) sprite.visible = true;
		#end
	}

	public function hide():Void
	{
		#if FEATURE_VIDEO
		if (sprite != null) sprite.visible = false;
		#end
	}

	public function alpha():Void
	{
		#if FEATURE_VIDEO
		if (sprite != null) sprite.alpha = GlobalVideo.daAlpha1;
		#end
	}

	public function unalpha():Void
	{
		#if FEATURE_VIDEO
		if (sprite != null) sprite.alpha = GlobalVideo.daAlpha2;
		#end
	}

	// ─── Cleanup ──────────────────────────────────────────────────────────────

	public function destroy():Void
	{
		#if FEATURE_VIDEO
		if (sprite != null) { sprite.stop(); sprite.destroy(); sprite = null; }
		#end
		initialized = false;
		onEnd = null;
	}
}
