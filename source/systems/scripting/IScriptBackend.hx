package systems.scripting;

interface IScriptBackend
{
	public var active(default, null):Bool;
	public function call(func:String, args:Array<Dynamic>):Dynamic;
	public function set(name:String, value:Dynamic):Void;
	public function get(name:String):Dynamic;
	public function stop():Void;
}
