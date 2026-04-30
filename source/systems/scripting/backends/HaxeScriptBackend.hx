package systems.scripting.backends;

import systems.scripting.IScriptBackend;

class HaxeScriptBackend implements IScriptBackend
{
	public var active(default, null):Bool = true;
	public var scriptPath(default, null):String;

	public function new(path:String)
	{
		scriptPath = path;
	}

	public function call(func:String, args:Array<Dynamic>):Dynamic return null;
	public function set(name:String, value:Dynamic):Void {}
	public function get(name:String):Dynamic return null;
	public function stop():Void active = false;
}
