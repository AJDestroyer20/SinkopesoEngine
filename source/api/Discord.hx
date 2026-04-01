package api;

#if FEATURE_DISCORD
import Sys.sleep;
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;

using StringTools;

class DiscordClient
{
	/** Override via data.json "discordID" before calling initialize(). */
	public static var clientID:String = "557069829501091850";
	public static var isRunning:Bool  = false;

	public function new()
	{
		trace("Discord Client starting...");

		var handlers:DiscordEventHandlers = {};
		handlers.ready        = cpp.Function.fromStaticFunction(onReady);
		handlers.errored      = cpp.Function.fromStaticFunction(onError);
		handlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);

		Discord.initialize(clientID, cpp.RawPointer.addressOf(handlers), 1, null);
		isRunning = true;
		trace("Discord Client started.");

		while (isRunning)
		{
			Discord.runCallbacks();
			sleep(2);
		}

		Discord.shutdown();
	}

	public static function shutdown():Void
	{
		isRunning = false;
		Discord.shutdown();
	}

	static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void
	{
		var activity:DiscordRichPresence = {};
		activity.details        = "In the Menus";
		activity.largeImageKey  = "icon";
		activity.largeImageText = "SinkopesoEngine";
		Discord.updateActivity(activity, null);
	}

	static function onError(_code:Int, _message:cpp.ConstCharStar):Void
	{
		trace('Error! $_code : $_message');
	}

	static function onDisconnected(_code:Int, _message:cpp.ConstCharStar):Void
	{
		trace('Disconnected! $_code : $_message');
	}

	public static function initialize()
	{
		#if FEATURE_MOD_META
		var modId = context.GameContext.mods?.meta?.discordID;
		if (modId != null && modId.length > 0) clientID = modId;
		#end
		var DiscordDaemon = sys.thread.Thread.create(() ->
		{
			new DiscordClient();
		});
		trace("Discord Client initialized");
	}

	/**
	 * Fix #10: hasStartTimestamp is optional (?Bool) so it defaults to null,
	 * NOT false. The old code used `if (hasStartTimestamp)` which evaluates
	 * null as false — correct but fragile. The real bug is:
	 *   endTimestamp = startTimestamp + endTimestamp
	 * This runs when endTimestamp > 0 even if hasStartTimestamp is false/null,
	 * meaning endTimestamp was added to 0 (startTimestamp = 0), giving a
	 * relative duration from epoch instead of an absolute Unix timestamp.
	 * The fix: only offset endTimestamp when hasStartTimestamp is actually true.
	 *
	 * Fix #11: The activity.state field was set to "" when state == null.
	 * hxdiscord_rpc treats "" the same as null internally, but some Discord
	 * client versions show a blank status line instead of hiding it. Use null.
	 */
	public static function changePresence(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float)
	{
		var startTimestamp:Float = (hasStartTimestamp == true) ? Date.now().getTime() : 0;

		// Fix #10: only offset endTimestamp relative to start when both are present
		if (hasStartTimestamp == true && endTimestamp != null && endTimestamp > 0)
		{
			endTimestamp = startTimestamp + endTimestamp;
		}

		var activity:DiscordRichPresence = {};
		activity.details        = details;
		// Fix #11: pass null instead of "" so Discord hides the state line
		activity.state          = (state != null && state.length > 0) ? state : null;
		activity.largeImageKey  = "icon";
		activity.largeImageText = "SinkopesoEngine";
		if (smallImageKey != null && smallImageKey.length > 0)
			activity.smallImageKey = smallImageKey;
		if (hasStartTimestamp == true)
			activity.startTimestamp = Std.int(startTimestamp / 1000);
		if (endTimestamp != null && endTimestamp > 0)
			activity.endTimestamp = Std.int(endTimestamp / 1000);
		Discord.updateActivity(activity, null);

		// trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
	}
}
#end
