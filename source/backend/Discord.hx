package backend;

#if FEATURE_DISCORD
import discord_rpc.DiscordRpc;
#end

class Discord
{
	#if FEATURE_DISCORD
	private static var initialized:Bool = false;

	public static function init():Void
	{
		if (initialized) return;

		var handlers = DiscordRpc.discordEventHandlers_create();
		DiscordRpc.discordInitialize('APPLICATION_ID_HERE', cpp.RawPointer.addressOf(handlers), 1, null);
		
		initialized = true;
	}

	public static function changePresence(details:String, state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float):Void
	{
		if (!initialized) return;

		var presence = DiscordRpc.discordRichPresence_create();
		presence.details = details;
		presence.state = state;
		presence.largeImageKey = 'icon';
		presence.largeImageText = 'Engine';

		if (smallImageKey != null)
			presence.smallImageKey = smallImageKey;

		if (hasStartTimestamp)
			presence.startTimestamp = Std.int(Sys.time());

		if (endTimestamp != null)
			presence.endTimestamp = Std.int(endTimestamp);

		DiscordRpc.discordUpdatePresence(cpp.RawConstPointer.addressOf(presence));
	}

	public static function shutdown():Void
	{
		if (!initialized) return;
		DiscordRpc.discordShutdown();
		initialized = false;
	}
	#else
	public static function init():Void {}
	public static function changePresence(details:String, state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float):Void {}
	public static function shutdown():Void {}
	#end
}
