package scripting;

import scripting.ScriptManager;
import scripting.IScriptBackend;

/**
 * ScriptContext — per-state script container.
 *
 * ─── Fixed bugs ───────────────────────────────────────────────────────────
 *   Fix D: owns backends directly; no fragile index math on ScriptManager.scripts.
 *   Fix E: onDestroy fired once; individual backends skip it via destroyed flag.
 *   Fix F: _localVars replayed on every late-loaded script.
 *   Fix G: reload() removes from ScriptManager.scripts correctly.
 *   Fix Q: loadScript() no longer registers in ScriptManager.scripts.
 *          ScriptContext is the sole owner. ScriptManager.clearAll() from
 *          PlayState.create() won't reach context-owned scripts.
 *          Global ScriptManager is only for PlayState's direct script loads.
 */
class ScriptContext
{
	public var stateId(default, null):String;

	var _scripts:Array<IScriptBackend>  = [];
	var _localVars:Map<String, Dynamic> = new Map();

	public function new(stateId:String)
	{
		this.stateId = stateId;
	}

	// ─── Loading ─────────────────────────────────────────────────────────

	public function loadFolder(folder:String):Void
	{
		#if FEATURE_FILESYSTEM
		if (!sys.FileSystem.exists(folder)) return;
		for (file in sys.FileSystem.readDirectory(folder))
		{
			var full = folder + "/" + file;
			if (!sys.FileSystem.isDirectory(full))
				loadScript(full);
		}
		#end
	}

	/**
	 * Load a single script. ScriptContext owns the backend exclusively.
	 * Fix Q: NOT registered in ScriptManager.scripts — immune to clearAll().
	 * Fix F: _localVars replayed so late-loaded scripts get all prior vars.
	 */
	public function loadScript(path:String):Void
	{
		#if FEATURE_FILESYSTEM
		if (!sys.FileSystem.exists(path))
		{
			trace('[ScriptContext:$stateId] Not found: $path');
			return;
		}
		#end

		var ext = path.split(".").pop().toLowerCase();
		var backend:IScriptBackend = switch (ext)
		{
			case "hx", "hscript": new scripting.backends.HaxeScriptBackend(path);
			case "lua":           new scripting.backends.LuaScriptBackend(path);
			case "xml":           new scripting.backends.XMLScriptBackend(path);
			case "json":          new scripting.backends.JSONScriptBackend(path);
			case "txt":           new scripting.backends.TXTScriptBackend(path);
			default: null;
		};

		if (backend == null)
		{
			trace('[ScriptContext:$stateId] Unknown ext: $path');
			return;
		}

		// Inject engine globals
		for (entry in ScriptRegistry.getAllEngineClasses())
			backend.setVar(entry.name, entry.ref);

		_injectHelpers(backend);

		// Replay all vars set so far (Fix F)
		for (key in _localVars.keys())
			backend.setVar(key, _localVars.get(key));

		backend.setVar("stateId",    stateId);
		backend.setVar("scriptPath", path);

		backend.load();
		_scripts.push(backend);
		trace('[ScriptContext:$stateId] Loaded: $path');
	}

	// ─── Callbacks ───────────────────────────────────────────────────────

	public function call(func:String, ?args:Array<Dynamic>):Dynamic
	{
		if (_scripts.length == 0) return null;
		if (args == null) args = [];

		var lastResult:Dynamic = null;
		var snapshot = _scripts.copy();

		for (script in snapshot)
		{
			if (script.destroyed) continue;
			var r = script.call(func, args);
			if (r != null) lastResult = r;
			if (r == "Function_Stop" || r == "Function_StopAll") break;
		}
		return lastResult;
	}

	// ─── Variables ───────────────────────────────────────────────────────

	public function setVar(name:String, value:Dynamic):Void
	{
		_localVars.set(name, value);
		for (s in _scripts)
			if (!s.destroyed) s.setVar(name, value);
	}

	public function getVar(name:String):Dynamic
	{
		if (_localVars.exists(name)) return _localVars.get(name);
		for (s in _scripts)
			if (!s.destroyed)
			{
				var v = s.getVar(name);
				if (v != null) return v;
			}
		return null;
	}

	// ─── Hot reload ──────────────────────────────────────────────────────

	public function reload(path:String):Void
	{
		#if FEATURE_HOT_RELOAD
		var i = _scripts.length - 1;
		while (i >= 0)
		{
			if (_scripts[i].path == path)
			{
				_scripts[i].destroyed = true;
				_scripts[i].destroy();
				_scripts.splice(i, 1);
			}
			i--;
		}
		loadScript(path);
		call("onCreate", []);
		trace('[ScriptContext:$stateId] Hot reloaded: $path');
		#end
	}

	// ─── Cleanup ─────────────────────────────────────────────────────────

	/**
	 * Fire onDestroy to scripts, then tear them down.
	 * Fix E: onDestroy fired here BEFORE marking destroyed, so scripts run cleanly.
	 *        Each backend's own destroy() checks the flag and won't double-fire.
	 */
	public function destroy():Void
	{
		// Fire while still alive
		for (s in _scripts)
		{
			if (!s.destroyed)
				s.call("onDestroy", []);
		}

		for (s in _scripts)
		{
			s.destroyed = true;
			s.destroy();
		}
		_scripts   = [];
		_localVars = new Map();
	}

	// ─── Helpers ─────────────────────────────────────────────────────────

	function _injectHelpers(backend:IScriptBackend):Void
	{
		backend.setVar("registerClass", ScriptRegistry.register);

		backend.setVar("switchState", function(name:String) {
			var cls = ScriptRegistry.resolve(name);
			if (cls != null)
				flixel.FlxG.switchState(Type.createInstance(cls, []));
			else
				trace('[ScriptContext:$stateId] switchState: cannot resolve "$name"');
		});

		backend.setVar("openSubState", function(name:String, ?args:Array<Dynamic>) {
			var cls = ScriptRegistry.resolve(name);
			if (cls != null)
				flixel.FlxG.state.openSubState(Type.createInstance(cls, args ?? []));
			else
				trace('[ScriptContext:$stateId] openSubState: cannot resolve "$name"');
		});

		backend.setVar("getState", function():Dynamic return flixel.FlxG.state);
		backend.setVar("getGame",  function():Dynamic return gameplay.PlayState.instance);
	}
}
