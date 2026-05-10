package systems.scripting;

interface IScriptRuntime
{
	public var active(default, null):Bool;
	public var path(default, null):String;

	function call(functionName:String, ?args:Array<Dynamic>):Dynamic;
	function set(variable:String, value:Dynamic):Void;
	function stop():Void;
}
