package systems.debug;

class DebugInspector
{
	public static function inspectObject(label:String, obj:Dynamic):Void
	{
		trace('[Inspector] ' + label + ': ' + haxe.Json.stringify(obj));
	}
}
