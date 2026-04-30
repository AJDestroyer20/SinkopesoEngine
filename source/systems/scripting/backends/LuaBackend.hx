package systems.scripting.backends;

import systems.scripting.IScriptBackend;
import systems.scripting.LuaScript;

class LuaBackend implements IScriptBackend
{
	public var active(get, never):Bool;
	private var script:LuaScript;

	public function new(path:String)
	{
		script = new LuaScript(path);
	}

	private function get_active():Bool return script != null && script.active;
	public function call(func:String, args:Array<Dynamic>):Dynamic return script.call(func, args);
	public function set(name:String, value:Dynamic):Void script.set(name, value);
	public function get(name:String):Dynamic return script.get(name);
	public function stop():Void script.stop();
}
