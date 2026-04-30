package systems.scripting.backends;

import systems.scripting.IScriptBackend;

#if hscript_iris
import hscript.iris.Iris;
#end

class HaxeScriptBackend implements IScriptBackend
{
	public var active(default, null):Bool = true;
	public var scriptPath(default, null):String;
	private var runtime:Dynamic;

	public function new(path:String)
	{
		scriptPath = path;
		load();
	}

	private function load():Void
	{
		try
		{
			#if hscript_iris
			runtime = new Iris();
			runtime.execute(sys.io.File.getContent(scriptPath));
			#else
			trace('[HScript] hscript-iris is not installed. Backend is inactive for: ' + scriptPath);
			active = false;
			#end
		}
		catch (e)
		{
			trace('[HScript] Failed to load ' + scriptPath + ': ' + e);
			active = false;
		}
	}

	public function call(func:String, args:Array<Dynamic>):Dynamic
	{
		if (!active || runtime == null) return null;
		try
		{
			var fn = Reflect.field(runtime, func);
			if (fn != null) return Reflect.callMethod(runtime, fn, args);
		}
		catch (e)
		{
			trace('[HScript] call error ' + func + ': ' + e);
		}
		return null;
	}

	public function set(name:String, value:Dynamic):Void
	{
		if (runtime != null) Reflect.setProperty(runtime, name, value);
	}

	public function get(name:String):Dynamic
	{
		return runtime != null ? Reflect.getProperty(runtime, name) : null;
	}

	public function stop():Void
	{
		active = false;
		runtime = null;
	}
}
