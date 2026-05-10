package systems.scripting;

import haxe.io.Path;
import sys.FileSystem;

enum abstract ScriptRuntimeKind(String)
{
	var Lua = 'lua';
	var HScript = 'hscript';
}

class ScriptManager
{
	public var scripts(default, null):Array<IScriptRuntime> = [];

	public function new() {}

	public function loadScript(path:String):IScriptRuntime
	{
		if (!FileSystem.exists(path))
		{
			trace('Script not found: $path');
			return null;
		}

		var extension = Path.extension(path).toLowerCase();
		var script:IScriptRuntime = switch (extension)
		{
			case 'lua': new LuaScript(path);
			case 'hx' | 'hscript' | 'hxc': new HScriptIrisRuntime(path);
			default: null;
		};

		if (script != null)
			scripts.push(script);

		return script;
	}

	public function loadScriptsFromFolder(folder:String):Void
	{
		if (!FileSystem.exists(folder))
			return;

		for (file in FileSystem.readDirectory(folder))
		{
			if (file.endsWith('.lua') || file.endsWith('.hx') || file.endsWith('.hscript') || file.endsWith('.hxc'))
			{
				var fullPath = Path.join([folder, file]);
				loadScript(fullPath);
			}
		}
	}

	public function callOnScripts(func:String, ?args:Array<Dynamic>):Void
	{
		for (script in scripts)
		{
			if (script.active)
				script.call(func, args);
		}
	}

	public function setOnScripts(variable:String, value:Dynamic):Void
	{
		for (script in scripts)
		{
			if (script.active)
				script.set(variable, value);
		}
	}

	public function stopAll():Void
	{
		for (script in scripts)
			script.stop();

		scripts = [];
	}

	public function removeScript(script:IScriptRuntime):Void
	{
		script.stop();
		scripts.remove(script);
	}
}
