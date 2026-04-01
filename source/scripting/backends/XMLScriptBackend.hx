package scripting.backends;

import scripting.IScriptBackend;
import haxe.xml.Access;
import scripting.backends.LuaAPI;

/**
 * XMLScriptBackend
 * 
 * Declarative scripting via XML. Great for modcharts, UI layouts,
 * week definitions, event timelines, and simple game logic.
 * 
 * ─── Full XML script example (song_events.xml) ──────────────────────────
 * 
 * <?xml version="1.0"?>
 * <script>
 *   <!-- Called when the song starts -->
 *   <callback name="onSongStart">
 *     <action type="cameraFlash" color="0xFFFFFFFF" duration="0.5"/>
 *     <action type="setProperty" name="health" value="1.0"/>
 *     <action type="playSound" sound="confirmMenu" volume="0.8"/>
 *   </callback>
 * 
 *   <!-- Called every beat -->
 *   <callback name="onBeatHit">
 *     <condition arg="beat" op="mod" value="4" result="0">
 *       <action type="cameraZoom" zoom="1.05"/>
 *     </condition>
 *   </callback>
 * 
 *   <!-- Called on note hit -->
 *   <callback name="onNoteHit">
 *     <action type="setProperty" name="health" expr="health + 0.023"/>
 *   </callback>
 * 
 *   <!-- Timed events (ms from song start) -->
 *   <timedEvent time="4000" type="cameraFlash" color="0xFF0000FF" duration="0.3"/>
 *   <timedEvent time="8000" type="setProperty" name="defaultCamZoom" value="1.2"/>
 *   <timedEvent time="12000" type="tweenProperty" name="defaultCamZoom" to="0.9" duration="1.0"/>
 * 
 *   <!-- Variables -->
 *   <set name="myVar" value="42"/>
 *   <set name="myString" value="hello"/>
 * </script>
 * 
 * ─── Supported action types ──────────────────────────────────────────────
 *   cameraFlash         color, duration
 *   cameraZoom          zoom
 *   setProperty         name, value  OR  name, expr (arithmetic)
 *   tweenProperty       name, to, duration
 *   playSound           sound, volume
 *   playMusic           music, volume
 *   triggerEvent        name, value1, value2
 *   addSprite           tag, x, y, image
 *   removeSprite        tag
 *   tweenSprite         tag, x, y, duration
 *   showText            text, x, y, size, color, duration
 *   trace               message
 */
class XMLScriptBackend implements IScriptBackend
{
	public var path:String;
	public var destroyed:Bool = false;

	var callbacks:Map<String, Array<Xml>> = new Map();
	var timedEvents:Array<{time:Float, node:Xml}> = [];
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
			var xml = Xml.parse(content);
			var root = new Access(xml.firstElement());

			// Parse <set> variables
			for (el in root.nodes.set)
				vars.set(el.att.name, el.att.value);

			// Parse <callback> blocks
			for (cb in root.nodes.callback)
			{
				var name = cb.att.name;
				callbacks.set(name, [for (child in cb.x) child]);
			}

			// Parse <timedEvent> nodes
			for (te in root.nodes.timedEvent)
				timedEvents.push({time: Std.parseFloat(te.att.time), node: te.x});

			trace('[XMLScript] Loaded: $path (${callbacks.keys().array().length} callbacks, ${timedEvents.length} timed events)');
		}
		catch (e:Dynamic)
		{
			trace('[XMLScript] ERROR loading $path: $e');
		}
	}

	public function call(func:String, args:Array<Dynamic>):Dynamic
	{
		if (destroyed) return null;

		// Check timed events (func == "update", args[0] == songPosition)
		if (func == "update" && args.length > 0)
		{
			var pos:Float = args[0];
			for (i in 0...timedEvents.length)
			{
				if (!firedTimedEvents.contains(i) && pos >= timedEvents[i].time)
				{
					executeAction(timedEvents[i].node, args);
					firedTimedEvents.push(i);
				}
			}
			return null;
		}

		if (!callbacks.exists(func)) return null;

		// Inject callback args into vars
		if (args.length > 0) vars.set("arg0", args[0]);
		if (args.length > 1) vars.set("arg1", args[1]);
		// Named aliases
		if (func == "onBeatHit" && args.length > 0) vars.set("beat", args[0]);
		if (func == "onStepHit" && args.length > 0) vars.set("step", args[0]);

		for (node in callbacks.get(func))
			processNode(node, args);

		return null;
	}

	function processNode(node:Xml, args:Array<Dynamic>):Void
	{
		if (node.nodeType != Xml.Element) return;

		switch (node.nodeName)
		{
			case "action":
				executeAction(node, args);

			case "condition":
				if (evalCondition(node))
					for (child in node) processNode(child, args);

			case "set":
				vars.set(node.get("name"), node.get("value"));

			case "trace":
				trace('[XMLScript:$path] ${node.get("message")}');
		}
	}

	function evalCondition(node:Xml):Bool
	{
		var argName = node.get("arg");
		var op      = node.get("op");
		var value   = Std.parseFloat(node.get("value"));
		var result  = node.exists("result") ? Std.parseFloat(node.get("result")) : 0;

		var argVal:Float = Std.parseFloat(Std.string(resolveValue(argName)));

		return switch (op)
		{
			case "mod":     (argVal % value) == result;
			case "eq":      argVal == value;
			case "neq":     argVal != value;
			case "gt":      argVal > value;
			case "lt":      argVal < value;
			case "gte":     argVal >= value;
			case "lte":     argVal <= value;
			default:        false;
		};
	}

	function executeAction(node:Xml, args:Array<Dynamic>):Void
	{
		var type = node.get("type");
		if (type == null && node.nodeName != "action")
			type = node.nodeName;

		switch (type)
		{
			case "cameraFlash":
				var color = Std.parseInt(node.get("color")) ?? 0xFFFFFFFF;
				var dur   = Std.parseFloat(node.get("duration") ?? "0.5");
				flixel.FlxG.camera.flash(color, dur);

			case "cameraZoom":
				var zoom = Std.parseFloat(node.get("zoom") ?? "1.0");
				if (PlayState.instance != null)
					PlayState.instance.defaultCamZoom = zoom;

			case "setProperty":
				var name  = node.get("name");
				var value = node.exists("expr")
					? evalExpr(node.get("expr"))
					: resolveValue(node.get("value"));
				LuaAPI.setProperty(name, value);

			case "tweenProperty":
				var name = node.get("name");
				var to   = Std.parseFloat(node.get("to") ?? "1.0");
				var dur  = Std.parseFloat(node.get("duration") ?? "0.5");
				var obj  = PlayState.instance;
				if (obj != null)
					flixel.tweens.FlxTween.tween(obj, [name => to], dur);

			case "playSound":
				var snd = node.get("sound");
				var vol = Std.parseFloat(node.get("volume") ?? "1.0");
				flixel.FlxG.sound.play(Paths.sound(snd), vol);

			case "playMusic":
				var mus = node.get("music");
				var vol = Std.parseFloat(node.get("volume") ?? "0.7");
				flixel.FlxG.sound.playMusic(Paths.music(mus), vol);

			case "triggerEvent":
				if (PlayState.instance != null)
					PlayState.instance.triggerEventNote(node.get("name"), node.get("value1") ?? "", node.get("value2") ?? "");

			case "addSprite":
				LuaAPI.addSprite(node.get("tag"), Std.parseFloat(node.get("x") ?? "0"), Std.parseFloat(node.get("y") ?? "0"), node.get("image") ?? "");

			case "removeSprite":
				LuaAPI.removeSprite(node.get("tag"));

			case "tweenSprite":
				var tag = node.get("tag");
				var dur = Std.parseFloat(node.get("duration") ?? "0.5");
				LuaAPI.tweenSprite(tag, {x: Std.parseFloat(node.get("x") ?? "0"), y: Std.parseFloat(node.get("y") ?? "0")}, dur);

			case "trace":
				trace('[XMLScript] ${node.get("message")}');

			default:
				trace('[XMLScript] Unknown action type: $type');
		}
	}

	/** Resolves a value string: checks vars map, then tries parseFloat */
	function resolveValue(v:String):Dynamic
	{
		if (v == null) return null;
		if (vars.exists(v)) return vars.get(v);
		var f = Std.parseFloat(v);
		if (!Math.isNaN(f)) return f;
		return v;
	}

	/** Very simple arithmetic expression evaluator (e.g. "health + 0.023") */
	function evalExpr(expr:String):Dynamic
	{
		// Supports: property OP number
		var ops = ["+", "-", "*", "/"];
		for (op in ops)
		{
			if (expr.contains(op))
			{
				var parts = expr.split(op);
				var left:Float  = Std.parseFloat(Std.string(resolveValue(StringTools.trim(parts[0]))));
				var right:Float = Std.parseFloat(Std.string(resolveValue(StringTools.trim(parts[1]))));
				if (Math.isNaN(left))
					left = Std.parseFloat(Std.string(LuaAPI.getProperty(StringTools.trim(parts[0]))));
				return switch (op)
				{
					case "+": left + right;
					case "-": left - right;
					case "*": left * right;
					case "/": left / right;
					default:  0;
				};
			}
		}
		return resolveValue(expr);
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
		call("onDestroy", []);
		destroyed = true;
		callbacks.clear();
		timedEvents = [];
		firedTimedEvents = [];
	}
}
