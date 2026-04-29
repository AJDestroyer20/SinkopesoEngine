package systems.scripting;

class ScriptManager
{
	public var scripts:Array<LuaScript> = [];
	
	public function new()
	{
	}
	
	public function loadScript(path:String):LuaScript
	{
		if (!sys.FileSystem.exists(path))
		{
			trace('Script not found: $path');
			return null;
		}
		
		var script:LuaScript = new LuaScript(path);
		scripts.push(script);
		
		return script;
	}
	
	public function loadScriptsFromFolder(folder:String):Void
	{
		if (!sys.FileSystem.exists(folder))
			return;
		
		for (file in sys.FileSystem.readDirectory(folder))
		{
			if (file.endsWith('.lua'))
			{
				var fullPath:String = haxe.io.Path.join([folder, file]);
				loadScript(fullPath);
			}
		}
	}
	
	public function callOnScripts(func:String, args:Array<Dynamic>):Void
	{
		for (script in scripts)
		{
			if (script.active)
			{
				script.call(func, args);
			}
		}
	}
	
	public function setOnScripts(variable:String, value:Dynamic):Void
	{
		for (script in scripts)
		{
			if (script.active)
			{
				script.set(variable, value);
			}
		}
	}
	
	public function stopAll():Void
	{
		for (script in scripts)
		{
			script.stop();
		}
		
		scripts = [];
	}
	
	public function removeScript(script:LuaScript):Void
	{
		script.stop();
		scripts.remove(script);
	}
}
