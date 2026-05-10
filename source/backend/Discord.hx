package backend;

#if FEATURE_DISCORD
import Type;
#end

class Discord
{
	#if FEATURE_DISCORD
	private static var initialized:Bool = false;
	private static var rpc:Class<Dynamic>;

	public static function init():Void
	{
		if (initialized) return;
		rpc = Type.resolveClass("discord_rpc.DiscordRpc");
		if (rpc == null) return;
		initialized = true;
	}

	public static function changePresence(details:String, state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float):Void {}
	public static function shutdown():Void { initialized = false; }
	#else
	public static function init():Void {}
	public static function changePresence(details:String, state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float):Void {}
	public static function shutdown():Void {}
	#end
}
