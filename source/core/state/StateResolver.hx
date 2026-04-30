package core.state;

import flixel.FlxState;

class StateResolver
{
	public static function resolve(className:String):Class<FlxState>
	{
		var resolved = Type.resolveClass(className);
		if (resolved == null)
		{
			trace('StateResolver: class not found $className, using states.TitleState');
			return cast Type.resolveClass("states.TitleState");
		}
		return cast resolved;
	}
}
