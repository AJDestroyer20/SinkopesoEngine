package scripting.backends;

import scripting.IScriptBackend;
import scripting.backends.LuaAPI;

/**
 * TXTScriptBackend
 * 
 * Ultra-simple line-by-line scripting for non-coders.
 * Perfect for: quick config, splash texts, dialogue scripts,
 * unlock conditions, and simple event triggers.
 * 
 * ─── Syntax ──────────────────────────────────────────────────────────────
 *   # Comment lines (ignored)
 *   BLANK LINES are ignored
 * 
 *   KEY = VALUE             → config/variable assignment
 *   ON eventName: COMMAND   → callback registration
 *   AT 4000: COMMAND        → timed event (ms)
 * 
 * ─── Commands ────────────────────────────────────────────────────────────
 *   SET property value         → setProperty on PlayState
 *   FLASH color duration       → camera flash
 *   ZOOM value                 → camera zoom
 *   SOUND name volume          → play sound
 *   MUSIC name volume          → play music
 *   SHAKE intensity duration   → camera shake
 *   TRACE message              → print to console
 *   HEALTH value               → set health directly
 *   SPEED value                → set scroll speed
 *   EVENT name value1 value2   → trigger in-game event
 * 
 * ─── Example (song_quick.txt) ────────────────────────────────────────────
 * 
 *   # Quick config
 *   title = My Sick Song
 *   author = Me
 * 
 *   ON onSongStart: FLASH 0xFFFFFFFF 0.4
 *   ON onSongStart: ZOOM 0.9
 *   ON onGameOver: SOUND gameOver 1.0
 * 
 *   AT 4000: FLASH 0xFF0000FF 0.2
 *   AT 8000: SHAKE 10 0.5
 *   AT 16000: SPEED 3.5
 *   AT 32000: ZOOM 1.2
 *   AT 60000: SOUND confirmMenu 0.7
 */
class TXTScriptBackend implements IScriptBackend
{
	public var path:String;
	public var destroyed:Bool = false;

	var callbacks:Map<String, Array<String>>  = new Map();
	var timedEvents:Array<{time:Float, cmd:String}> = [];
	var vars:Map<String, String>              = new Map();
	var firedTimedEvents:Array<Int>           = [];

	public function new(path:String)
	{
		this.path = path;
	}

	public function load():Void
	{
		try
		{
			var lines = sys.io.File.getContent(path).split("\n");
			for (rawLine in lines)
			{
				var line = StringTools.trim(rawLine);
				if (line == "" || line.startsWith("#")) continue;

				// KEY = VALUE
				if (line.contains("=") && !line.startsWith("ON ") && !line.startsWith("AT "))
				{
					var parts = line.split("=");
					vars.set(StringTools.trim(parts[0]), StringTools.trim(parts.slice(1).join("=")));
					continue;
				}

				// ON eventName: COMMAND
				if (line.startsWith("ON "))
				{
					var colonIdx = line.indexOf(":");
					if (colonIdx == -1) continue;
					var eventName = StringTools.trim(line.substring(3, colonIdx));
					var cmd       = StringTools.trim(line.substring(colonIdx + 1));
					if (!callbacks.exists(eventName)) callbacks.set(eventName, []);
					callbacks.get(eventName).push(cmd);
					continue;
				}

				// AT time: COMMAND
				if (line.startsWith("AT "))
				{
					var colonIdx = line.indexOf(":");
					if (colonIdx == -1) continue;
					var timeStr = StringTools.trim(line.substring(3, colonIdx));
					var cmd     = StringTools.trim(line.substring(colonIdx + 1));
					timedEvents.push({time: Std.parseFloat(timeStr), cmd: cmd});
					continue;
				}
			}
			trace('[TXTScript] Loaded: $path (${Lambda.count(callbacks)} callbacks, ${timedEvents.length} timed events, ${Lambda.count(vars)} vars)');
		}
		catch (e:Dynamic)
		{
			trace('[TXTScript] ERROR loading $path: $e');
		}
	}

	public function call(func:String, args:Array<Dynamic>):Dynamic
	{
		if (destroyed) return null;

		// Timed events via "update"
		if (func == "update" && args.length > 0)
		{
			var pos:Float = args[0];
			for (i in 0...timedEvents.length)
				if (!firedTimedEvents.contains(i) && pos >= timedEvents[i].time)
				{
					executeCommand(timedEvents[i].cmd);
					firedTimedEvents.push(i);
				}
			return null;
		}

		if (!callbacks.exists(func)) return null;
		for (cmd in callbacks.get(func))
			executeCommand(cmd);
		return null;
	}

	function executeCommand(cmd:String):Void
	{
		var parts = cmd.split(" ");
		var op    = parts[0].toUpperCase();
		switch (op)
		{
			case "SET":
				if (parts.length >= 3) LuaAPI.setProperty(parts[1], parts[2]);

			case "FLASH":
				var color = parts.length > 1 ? (Std.parseInt(parts[1]) ?? 0xFFFFFFFF) : 0xFFFFFFFF;
				var dur   = parts.length > 2 ? (Std.parseFloat(parts[2])) : 0.5;
				flixel.FlxG.camera.flash(color, dur);

			case "ZOOM":
				if (parts.length > 1 && PlayState.instance != null)
					PlayState.instance.defaultCamZoom = Std.parseFloat(parts[1]);

			case "SOUND":
				var snd = parts.length > 1 ? parts[1] : "";
				var vol = parts.length > 2 ? Std.parseFloat(parts[2]) : 1.0;
				if (snd != "") flixel.FlxG.sound.play(Paths.sound(snd), vol);

			case "MUSIC":
				var mus = parts.length > 1 ? parts[1] : "";
				var vol = parts.length > 2 ? Std.parseFloat(parts[2]) : 0.7;
				if (mus != "") flixel.FlxG.sound.playMusic(Paths.music(mus), vol);

			case "SHAKE":
				var intensity = parts.length > 1 ? Std.parseFloat(parts[1]) : 5.0;
				var dur       = parts.length > 2 ? Std.parseFloat(parts[2]) : 0.5;
				flixel.FlxG.camera.shake(intensity / 1000, dur);

			case "HEALTH":
				if (parts.length > 1) LuaAPI.setProperty("health", Std.parseFloat(parts[1]));

			case "SPEED":
				if (parts.length > 1) LuaAPI.setProperty("songSpeed", Std.parseFloat(parts[1]));

			case "EVENT":
				if (parts.length >= 2 && PlayState.instance != null)
					PlayState.instance.triggerEventNote(parts[1], parts.length > 2 ? parts[2] : "", parts.length > 3 ? parts[3] : "");

			case "TRACE":
				trace('[TXTScript] ${parts.slice(1).join(" ")}');

			default:
				trace('[TXTScript] Unknown command: $op');
		}
	}

	public function setVar(name:String, value:Dynamic):Void
	{
		vars.set(name, Std.string(value));
	}

	public function getVar(name:String):Dynamic
	{
		return vars.exists(name) ? vars.get(name) : null;
	}

	public function destroy():Void
	{
		call("onDestroy", []);
		destroyed = true;
		callbacks.clear();
		timedEvents = [];
	}
}
