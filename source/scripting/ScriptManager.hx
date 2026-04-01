package scripting;

import scripting.backends.HaxeScriptBackend;
import scripting.backends.LuaScriptBackend;
import scripting.backends.XMLScriptBackend;
import scripting.backends.JSONScriptBackend;
import scripting.backends.TXTScriptBackend;
import scripting.IScriptBackend;

/**
 * ScriptManager — Central hub for the multi-language scripting system.
 *
 * Supports: .hx / .hscript | .lua | .xml | .json | .txt
 *
 * ─── Fixes ────────────────────────────────────────────────────────────────
 *   Fix A: loadScript() and loadFolder() called sys.FileSystem unconditionally.
 *          On web/Switch (no FEATURE_FILESYSTEM) this caused compile errors.
 *          Both methods now have #if FEATURE_FILESYSTEM guards with openfl.Assets
 *          fallbacks where meaningful.
 *   Fix B: call() iterated a live array and destroyed scripts during iteration
 *          (Function_StopAll path). Switched to iterating a snapshot copy.
 *   Fix C: clearAll() mutated scripts[] while iterating it. Fixed with a copy.
 */
class ScriptManager
{
	/** All loaded script instances */
	public static var scripts:Array<IScriptBackend> = [];

	/** Shared variable table accessible from ALL scripts */
	public static var globalVars:Map<String, Dynamic> = new Map();

	public static function init():Void
	{
		scripts    = [];
		globalVars = new Map();
		trace("[ScriptManager] Initialized.");
	}

	/**
	 * Load a single script file. Auto-detects backend by extension.
	 * Fix A: guarded by FEATURE_FILESYSTEM; falls back to openfl.Assets for text.
	 */
	public static function loadScript(path:String):Void
	{
		#if FEATURE_FILESYSTEM
		if (!sys.FileSystem.exists(path))
		{
			trace('[ScriptManager] WARNING: Script not found: $path');
			return;
		}
		#end

		var ext = path.split(".").pop().toLowerCase();
		var backend:IScriptBackend = switch (ext)
		{
			case "hx", "hscript": new HaxeScriptBackend(path);
			case "lua":           new LuaScriptBackend(path);
			case "xml":           new XMLScriptBackend(path);
			case "json":          new JSONScriptBackend(path);
			case "txt":           new TXTScriptBackend(path);
			default:
			{
				trace('[ScriptManager] Unknown extension: $ext — skipping $path');
				null;
			}
		};

		if (backend != null)
		{
			backend.load();
			scripts.push(backend);
			trace('[ScriptManager] Loaded: $path');
		}
	}

	/**
	 * Load all scripts inside a folder (non-recursive, top level only).
	 * Fix A: guarded by FEATURE_FILESYSTEM.
	 */
	public static function loadFolder(folder:String):Void
	{
		#if FEATURE_FILESYSTEM
		if (!sys.FileSystem.exists(folder)) return;
		for (file in sys.FileSystem.readDirectory(folder))
		{
			var full = folder + "/" + file;
			if (sys.FileSystem.isDirectory(full))
				loadFolder(full);
			else
				loadScript(full);
		}
		#end
	}

	/**
	 * Call a callback in ALL loaded scripts.
	 * Fix B: iterates a snapshot to avoid mutation during iteration.
	 * Respects Function_Stop / Function_StopAll return values.
	 */
	public static function call(func:String, args:Array<Dynamic>):Map<String, Dynamic>
	{
		var results:Map<String, Dynamic> = new Map();
		var snapshot = scripts.copy(); // Fix B
		for (s in snapshot)
		{
			if (s.destroyed) continue;
			var r = s.call(func, args);
			if (r != null) results.set(s.path, r);
			if (r == "Function_StopAll") break;
		}
		return results;
	}

	/**
	 * Set a variable in ALL loaded scripts + globalVars.
	 */
	public static function setVar(name:String, value:Dynamic):Void
	{
		globalVars.set(name, value);
		for (s in scripts)
			if (!s.destroyed) s.setVar(name, value);
	}

	/**
	 * Get a variable (checks globalVars first, then first script that has it).
	 */
	public static function getVar(name:String):Dynamic
	{
		if (globalVars.exists(name)) return globalVars.get(name);
		for (s in scripts)
			if (!s.destroyed)
			{
				var v = s.getVar(name);
				if (v != null) return v;
			}
		return null;
	}

	/**
	 * Destroy all scripts (call on state switch).
	 * Fix C: iterates a copy to avoid mutating scripts[] while looping.
	 */
	public static function clearAll():Void
	{
		var copy = scripts.copy(); // Fix C
		for (s in copy) s.destroy();
		scripts = [];
		trace("[ScriptManager] All scripts cleared.");
	}

	/**
	 * Destroy scripts loaded from a specific folder only.
	 */
	public static function clearFolder(folder:String):Void
	{
		var keep:Array<IScriptBackend> = [];
		for (s in scripts)
		{
			if (s.path.startsWith(folder))
				s.destroy();
			else
				keep.push(s);
		}
		scripts = keep;
	}
}
