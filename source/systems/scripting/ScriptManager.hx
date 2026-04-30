package systems.scripting;

import systems.scripting.backends.LuaBackend;
import systems.scripting.backends.HaxeScriptBackend;

class ScriptManager
{
	public var scripts:Array<IScriptBackend> = [];
	public var registry(default, null):ScriptRegistry;

	public function new()
	{
		registry = new ScriptRegistry();
		registry.register("lua", function(path) return new LuaBackend(path));
		registry.register("hscript", function(path) return new HaxeScriptBackend(path));
	}

	public function loadScript(path:String, backend:String = "lua"):IScriptBackend
	{
		if (!sys.FileSystem.exists(path)) return null;
		var script = registry.create(backend, path);
		if (script == null || !script.active) return null;
		if (!sys.FileSystem.exists(path))
		{
			trace('Script not found: $path');
			return null;
		}

		var script = registry.create(backend, path);
		if (script == null)
		{
			trace('Unsupported backend: $backend');
			return null;
		}

		scripts.push(script);
		return script;
	}

	public function loadByPriority(basePathNoExt:String):IScriptBackend
	{
		var hx = basePathNoExt + ".hx";
		var hxc = basePathNoExt + ".hxc";
		var lua = basePathNoExt + ".lua";

		var backend = loadScript(hx, "hscript");
		if (backend == null) backend = loadScript(hxc, "hscript");
		if (backend == null) backend = loadScript(lua, "lua");
		return backend;
	}

	public function loadScriptsFromFolder(folder:String):Void
	{
		if (!sys.FileSystem.exists(folder)) return;
		for (file in sys.FileSystem.readDirectory(folder))
		{
			var fullPath = haxe.io.Path.join([folder, file]);
			if (file.endsWith('.hx') || file.endsWith('.hxc')) loadScript(fullPath, "hscript");
		}
		for (file in sys.FileSystem.readDirectory(folder))
		{
			var fullPath = haxe.io.Path.join([folder, file]);
			if (file.endsWith('.lua')) loadScript(fullPath, "lua");
	public function loadScriptsFromFolder(folder:String, backend:String = "lua"):Void
	{
		if (!sys.FileSystem.exists(folder)) return;
		for (file in sys.FileSystem.readDirectory(folder))
		{
			if (file.endsWith('.lua') || file.endsWith('.hx'))
			{
				var fullPath = haxe.io.Path.join([folder, file]);
				loadScript(fullPath, backend);
			}
		}
	}

	public function callOnScripts(func:String, args:Array<Dynamic>):Void
	{
		for (script in scripts) if (script.active) script.call(func, args);
		for (script in scripts)
			if (script.active)
				script.call(func, args);
	}

	public function setOnScripts(variable:String, value:Dynamic):Void
	{
		for (script in scripts) if (script.active) script.set(variable, value);
		for (script in scripts)
			if (script.active)
				script.set(variable, value);
	}

	public function stopAll():Void
	{
		for (script in scripts) script.stop();
		scripts = [];
	}

	public function removeScript(script:IScriptBackend):Void
	{
		script.stop();
		scripts.remove(script);
	}
}
