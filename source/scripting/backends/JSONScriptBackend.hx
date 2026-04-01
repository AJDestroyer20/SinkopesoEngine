package scripting.backends;

import scripting.IScriptBackend;
import haxe.Json;
import scripting.WindowConfig;
import scripting.backends.LuaAPI;

/**
 * JSONScriptBackend
 * 
 * Data-driven scripting via JSON.
 * Perfect for: song metadata, week definitions, character configs,
 * stage configs, UI themes, and event timelines.
 * 
 * ─── Supported JSON script types (detected by "type" field) ─────────────
 *
 *  "callbacks"  — function-like event system
 *  "timeline"   — timed events by ms
 *  "config"     — key/value pairs that auto-apply on load
 *  (none)       — treated as raw config
 * 
 * ─── Callbacks example (song_hooks.json) ────────────────────────────────
 * {
 *   "type": "callbacks",
 *   "callbacks": {
 *     "onSongStart": [
 *       {"action": "cameraFlash", "color": "0xFFFFFFFF", "duration": 0.5},
 *       {"action": "setProperty", "name": "health", "value": 1.0}
 *     ],
 *     "onBeatHit": [
 *       {"action": "cameraZoom", "zoom": 1.05, "condition": {"arg": "beat", "op": "mod", "value": 4, "result": 0}}
 *     ]
 *   }
 * }
 * 
 * ─── Timeline example (song_timeline.json) ──────────────────────────────
 * {
 *   "type": "timeline",
 *   "events": [
 *     {"time": 4000, "action": "cameraFlash", "color": "0xFF0000FF", "duration": 0.3},
 *     {"time": 8000, "action": "setProperty", "name": "defaultCamZoom", "value": 1.2},
 *     {"time": 16000, "action": "playSound", "sound": "confirmMenu", "volume": 0.8}
 *   ]
 * }
 * 
 * ─── Config example (engine_config.json) ────────────────────────────────
 * {
 *   "type": "config",
 *   "window": {
 *     "title": "My FNF Fork",
 *     "width": 1280,
 *     "height": 720,
 *     "icon": "assets/images/icon.png",
 *     "fps": 60,
 *     "transparent": false
 *   },
 *   "gameplay": {
 *     "scrollSpeed": 2.8,
 *     "noteOffset": 0,
 *     "botPlay": false,
 *     "downscroll": false
 *   }
 * }
 */
class JSONScriptBackend implements IScriptBackend
{
	public var path:String;
	public var destroyed:Bool = false;

	var data:Dynamic;
	var vars:Map<String, Dynamic> = new Map();
	var firedTimedEvents:Array<Int> = [];

	public function new(path:String)
	{
		this.path = path;
	}

	public function load():Void
	{
		try
		{
			var content = sys.io.File.getContent(path);
			data = Json.parse(content);

			var scriptType:String = Reflect.hasField(data, "type") ? data.type : "config";

			switch (scriptType)
			{
				case "config":
					applyConfig(data);
				case "callbacks":
					trace('[JSONScript] Loaded callbacks from $path');
				case "timeline":
					trace('[JSONScript] Loaded timeline from $path (${(data.events:Array<Dynamic>).length} events)');
				default:
					applyConfig(data);
			}
		}
		catch (e:Dynamic)
		{
			trace('[JSONScript] ERROR loading $path: $e');
		}
	}

	/** Auto-apply a "config" type JSON to engine/window settings */
	function applyConfig(cfg:Dynamic):Void
	{
		// Window settings
		if (Reflect.hasField(cfg, "window"))
		{
			var win:Dynamic = cfg.window;
			WindowConfig.apply(win);
		}
		// Gameplay defaults
		if (Reflect.hasField(cfg, "gameplay"))
		{
			var gp:Dynamic = cfg.gameplay;
			if (Reflect.hasField(gp, "scrollSpeed"))
				PlayStateChangeables.scrollSpeed = gp.scrollSpeed;
			if (Reflect.hasField(gp, "downscroll"))
				PlayStateChangeables.useDownscroll = gp.downscroll;
			if (Reflect.hasField(gp, "botPlay"))
				PlayStateChangeables.botPlay = gp.botPlay;
		}
	}

	public function call(func:String, args:Array<Dynamic>):Dynamic
	{
		if (destroyed || data == null) return null;

		var scriptType:String = Reflect.hasField(data, "type") ? data.type : "config";

		// Timeline: check on update
		if (scriptType == "timeline" && func == "update" && args.length > 0)
		{
			var pos:Float = args[0];
			var events:Array<Dynamic> = data.events;
			for (i in 0...events.length)
			{
				if (!firedTimedEvents.contains(i) && pos >= (events[i].time:Float))
				{
					executeAction(events[i], args);
					firedTimedEvents.push(i);
				}
			}
			return null;
		}

		// Callbacks
		if (scriptType == "callbacks")
		{
			var cbs:Dynamic = data.callbacks;
			if (!Reflect.hasField(cbs, func)) return null;
			var list:Array<Dynamic> = Reflect.field(cbs, func);
			if (args.length > 0) vars.set("arg0", args[0]);
			if (func == "onBeatHit" && args.length > 0) vars.set("beat", args[0]);
			for (action in list)
				executeAction(action, args);
		}

		return null;
	}

	function executeAction(action:Dynamic, args:Array<Dynamic>):Void
	{
		// Check condition
		if (Reflect.hasField(action, "condition"))
		{
			if (!evalCondition(action.condition, args)) return;
		}

		var type:String = Reflect.hasField(action, "action") ? action.action : "";
		switch (type)
		{
			case "cameraFlash":
				var color = Std.parseInt(Std.string(action.color)) ?? 0xFFFFFFFF;
				var dur   = Reflect.hasField(action, "duration") ? (action.duration:Float) : 0.5;
				flixel.FlxG.camera.flash(color, dur);

			case "cameraZoom":
				if (PlayState.instance != null)
					PlayState.instance.defaultCamZoom = action.zoom;

			case "setProperty":
				LuaAPI.setProperty(action.name, action.value);

			case "tweenProperty":
				var obj = PlayState.instance;
				if (obj != null)
					flixel.tweens.FlxTween.tween(obj, [(action.name:String) => (action.to:Float)], action.duration ?? 0.5);

			case "playSound":
				flixel.FlxG.sound.play(Paths.sound(action.sound), action.volume ?? 1.0);

			case "addSprite":
				LuaAPI.addSprite(action.tag, action.x ?? 0, action.y ?? 0, action.image ?? "");

			case "removeSprite":
				LuaAPI.removeSprite(action.tag);

			case "trace":
				trace('[JSONScript] ${action.message}');

			default:
				if (type != "") trace('[JSONScript] Unknown action: $type');
		}
	}

	function evalCondition(cond:Dynamic, args:Array<Dynamic>):Bool
	{
		var argName:String = cond.arg;
		var op:String      = cond.op;
		var value:Float    = cond.value;
		var result:Float   = Reflect.hasField(cond, "result") ? (cond.result:Float) : 0;

		var argVal:Float = vars.exists(argName)
			? Std.parseFloat(Std.string(vars.get(argName)))
			: (args.length > 0 ? Std.parseFloat(Std.string(args[0])) : 0);

		return switch (op)
		{
			case "mod": (argVal % value) == result;
			case "eq":  argVal == value;
			case "gt":  argVal > value;
			case "lt":  argVal < value;
			default:    false;
		};
	}

	public function setVar(name:String, value:Dynamic):Void
	{
		vars.set(name, value);
	}

	public function getVar(name:String):Dynamic
	{
		return vars.exists(name) ? vars.get(name) : null;
	}

	public function destroy():Void
	{
		destroyed = true;
		data = null;
	}
}
