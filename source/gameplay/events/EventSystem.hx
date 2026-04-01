package gameplay.events;

import scripting.ScriptManager;
import scripting.ScriptCallbacks;
/**
 * EventSystem
 * 
 * A flexible event pipeline that sits between chart events and the engine.
 * Supports conditional logic, chaining, cooldowns, and scripted overrides.
 * 
 * Chart events get routed through here before hitting PlayState,
 * so scripts can intercept, modify, or cancel them.
 * 
 * ─── Built-in event handlers ─────────────────────────────────────────────
 *   All vanilla FNF/Kade events are pre-registered.
 *   Mods can add custom events via EventSystem.register().
 * 
 * ─── Custom event in script (song.hx) ────────────────────────────────────
 *   function onEvent(name, value1, value2) {
 *     if (name == "MyCustomEvent") {
 *       FlxG.camera.flash(0xFF00FFFF, 0.3);
 *     }
 *   }
 * 
 * ─── Custom event in chart ────────────────────────────────────────────────
 *   Just use the chart editor to add an event named "MyCustomEvent".
 */
class EventSystem
{
	/** Registered event handlers: name → handler function */
	static var handlers:Map<String, Array<EventHandler>> = new Map();

	/** Event history (last 100 fired events) */
	static var history:Array<{name:String, v1:String, v2:String, time:Float}> = [];

	/** Cooldown tracker: event name → last fire time (ms) */
	static var cooldowns:Map<String, Float> = new Map();

	public static function init():Void
	{
		handlers = new Map();
		history  = [];
		cooldowns = new Map();
		registerBuiltins();
		trace('[EventSystem] Initialized.');
	}

	// ─── REGISTRATION ────────────────────────────────────────────────────

	/**
	 * Register a handler for a named event.
	 * Multiple handlers per event are supported (executed in order).
	 * 
	 * @param name       Event name (e.g. "Hey!", "Change Character")
	 * @param fn         Handler: (value1:String, value2:String) -> Bool
	 *                   Return FALSE to cancel further handlers.
	 * @param priority   Higher priority = executes first (default 0)
	 * @param cooldownMs Minimum ms between fires (0 = no cooldown)
	 */
	public static function register(name:String, fn:String->String->Bool, priority:Int = 0, cooldownMs:Float = 0):Void
	{
		if (!handlers.exists(name)) handlers.set(name, []);
		handlers.get(name).push({fn: fn, priority: priority, cooldownMs: cooldownMs});
		// Sort by priority descending
		handlers.get(name).sort((a, b) -> b.priority - a.priority);
	}

	/** Remove all handlers for an event */
	public static function unregister(name:String):Void
	{
		handlers.remove(name);
	}

	// ─── FIRE ────────────────────────────────────────────────────────────

	/**
	 * Fire a named event. Call this from PlayState instead of
	 * the old inline switch/if chains.
	 */
	public static function fire(name:String, value1:String = "", value2:String = ""):Void
	{
		var now:Float = PlayState.instance != null ? PlayState.instance.songPosition : 0;

		// Log to history
		history.push({name: name, v1: value1, v2: value2, time: now});
		if (history.length > 100) history.shift();

		// Dispatch to script system first (scripts can cancel)
		var results = ScriptManager.call(ScriptCallbacks.ON_EVENT, [name, value1, value2]);

		// Check if any script returned false (cancel)
		for (result in results)
			if (result == false) return;

		// Now fire registered handlers
		if (!handlers.exists(name)) return;

		for (handler in handlers.get(name))
		{
			// Cooldown check
			if (handler.cooldownMs > 0)
			{
				var key = name + "_cooldown";
				if (cooldowns.exists(key) && now - cooldowns.get(key) < handler.cooldownMs)
					continue;
				cooldowns.set(key, now);
			}

			// Execute handler; if returns false, stop chain
			var cont = handler.fn(value1, value2);
			if (!cont) break;
		}
	}

	// ─── QUERY ───────────────────────────────────────────────────────────

	/** Check if an event fired recently within the last N ms */
	public static function firedRecently(name:String, withinMs:Float):Bool
	{
		var now:Float = PlayState.instance != null ? PlayState.instance.songPosition : 0;
		for (ev in history)
			if (ev.name == name && now - ev.time <= withinMs) return true;
		return false;
	}

	/** Get how many times an event has fired total in this song */
	public static function fireCount(name:String):Int
	{
		var count = 0;
		for (ev in history) if (ev.name == name) count++;
		return count;
	}

	// ─── BUILT-IN EVENTS ─────────────────────────────────────────────────

	static function registerBuiltins():Void
	{
		// ── Hey! ──────────────────────────────────────────────────────────
		register("Hey!", function(v1, v2) {
			if (PlayState.instance == null) return true;
			var who = v1.toLowerCase();
			if (who == "bf" || who == "both")
				PlayState.instance.boyfriend.playAnim("hey", true);
			if (who == "gf" || who == "both")
				PlayState.instance.gf?.playAnim("cheer", true);
			if (who == "dad")
				PlayState.instance.dad.playAnim("hey", true);
			return true;
		}, 10);

		// ── Set GF Speed ──────────────────────────────────────────────────
		register("Set GF Speed", function(v1, v2) {
			var spd = Std.parseInt(v1) ?? 1;
			if (PlayState.instance != null)
				PlayState.instance.gf?.danceEveryNumBeats = spd;
			return true;
		}, 10);

		// ── Add Camera Zoom ───────────────────────────────────────────────
		register("Add Camera Zoom", function(v1, v2) {
			if (PlayState.instance == null) return true;
			var camZoom = Std.parseFloat(v1) ?? 0.015;
			var hudZoom = Std.parseFloat(v2) ?? 0.03;
			PlayState.instance.defaultCamZoom       += camZoom;
			PlayState.instance.camHUD?.zoom         += hudZoom;
			return true;
		}, 10);

		// ── Change Character ──────────────────────────────────────────────
		register("Change Character", function(v1, v2) {
			if (PlayState.instance == null) return true;
			var which = v1.toLowerCase();
			var newChar = v2;
			// Character swapping logic
			trace('[EventSystem] Change Character: $which -> $newChar');
			// TODO: plug into your character system
			return true;
		}, 10);

		// ── Play Animation ────────────────────────────────────────────────
		register("Play Animation", function(v1, v2) {
			if (PlayState.instance == null) return true;
			switch (v2.toLowerCase()) {
				case "bf":  PlayState.instance.boyfriend.playAnim(v1, true);
				case "dad": PlayState.instance.dad.playAnim(v1, true);
				case "gf":  PlayState.instance.gf?.playAnim(v1, true);
			}
			return true;
		}, 10);

		// ── Camera Flash ──────────────────────────────────────────────────
		register("Camera Flash", function(v1, v2) {
			var color = Std.parseInt(v1) ?? 0xFFFFFFFF;
			var dur   = Std.parseFloat(v2) ?? 0.5;
			flixel.FlxG.camera.flash(color, dur);
			return true;
		}, 10);

		// ── Camera Shake ──────────────────────────────────────────────────
		register("Camera Shake", function(v1, v2) {
			var intensity = Std.parseFloat(v1) ?? 0.01;
			var dur       = Std.parseFloat(v2) ?? 0.5;
			flixel.FlxG.camera.shake(intensity, dur);
			return true;
		}, 10);

		// ── Screen Fade ───────────────────────────────────────────────────
		register("Screen Fade", function(v1, v2) {
			var color = Std.parseInt(v1) ?? 0xFF000000;
			var dur   = Std.parseFloat(v2) ?? 1.0;
			flixel.FlxG.camera.fade(color, dur);
			return true;
		}, 10);

		// ── Set Scroll Speed ──────────────────────────────────────────────
		register("Set Scroll Speed", function(v1, v2) {
			var speed = Std.parseFloat(v1) ?? 1.0;
			if (PlayState.instance != null)
				PlayState.instance.songSpeed = speed;
			return true;
		}, 10);

		trace('[EventSystem] Registered ${Lambda.count(handlers)} built-in event types.');
	}

	public static function destroy():Void
	{
		handlers.clear();
		history  = [];
		cooldowns.clear();
	}
}

typedef EventHandler =
{
	var fn:String->String->Bool;
	var priority:Int;
	var cooldownMs:Float;
}
