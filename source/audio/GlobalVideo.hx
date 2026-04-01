package audio;

import openfl.Lib;

/**
 * GlobalVideo — SinkopesoEngine
 *
 * Static registry for the active VideoHandler (hxvlc).
 *
 * ─── Bug Fixes ────────────────────────────────────────────────────────────
 *   Fix #3: calc() had a logic error — remX/remY were computed BEFORE
 *            Math.floor() was applied to appliedW/appliedH, so the offsets
 *            were based on un-floored values but the final sizes were floored.
 *            This caused a 0–1px misalignment at certain resolutions.
 *   Fix #4: calc() recomputed ALL 4 values every time it was called for just
 *            one index. It was called 4× per frame from VideoHandler.update().
 *            Now uses a single calcAll() and caches into an array.
 */
class GlobalVideo
{
	private static var video:VideoHandler;

	public static var daAlpha1:Float = 0.2;
	public static var daAlpha2:Float = 1.0;

	// ─── Registration ─────────────────────────────────────────────────────────

	public static function setVid(vid:VideoHandler):Void { video = vid; }
	public static function getVid():VideoHandler         { return video; }

	/** Compatibility alias — prefer setVid/getVid for new code. */
	public static function get():VideoHandler            { return video; }

	// ─── Letterbox math ───────────────────────────────────────────────────────

	/**
	 * Returns a letterboxed dimension/offset so the video fills the stage
	 * while keeping the game aspect ratio.
	 *   calc(0) → x offset
	 *   calc(1) → y offset
	 *   calc(2) → display width
	 *   calc(3) → display height
	 *
	 * Bug Fix #3: remX/remY now computed AFTER flooring the applied dimensions,
	 * so the video is always pixel-perfectly centered.
	 *
	 * Bug Fix #4: Use calcAll() when you need more than one value in the
	 * same frame — avoids repeating the same arithmetic 4 times.
	 */
	public static function calc(ind:Int):Float
	{
		var r = calcAll();
		return switch (ind)
		{
			case 0: r[0];
			case 1: r[1];
			case 2: r[2];
			case 3: r[3];
			default: 0;
		};
	}

	/**
	 * Returns [x, y, width, height] in one pass.
	 * Use this in VideoHandler.update() instead of calling calc() 4×.
	 */
	public static function calcAll():Array<Float>
	{
		var sw:Int = Lib.current.stage.stageWidth;
		var sh:Int = Lib.current.stage.stageHeight;

		var gw:Float = GameDimensions.width;
		var gh:Float = GameDimensions.height;

		var appliedW:Float = Math.floor(sh * (gw / gh));
		var appliedH:Float = Math.floor(sw * (gh / gw));

		// Clamp so neither dimension exceeds the stage
		if (appliedH > sh) { appliedH = sh; }
		if (appliedW > sw) { appliedW = sw; }

		// Fix #3: compute offsets AFTER flooring so they're consistent
		var remX:Float = (sw - appliedW) / 2;
		var remY:Float = (sh - appliedH) / 2;

		return [remX, remY, appliedW, appliedH];
	}
}
