package systems.debug;

import core.context.GameContext;

class EngineDiagnostics
{
	public static function runAll():Array<String>
	{
		var results:Array<String> = [];
		var ctx = GameContext.init();
		results.push(ctx.config != null ? "config:ok" : "config:fail");
		results.push(ctx.events != null ? "events:ok" : "events:fail");
		results.push(ctx.audio != null ? "audio:ok" : "audio:fail");
		results.push(ctx.scripts != null ? "scripts:ok" : "scripts:fail");
		results.push(ctx.mods != null ? "mods:ok" : "mods:fail");
		results.push(ctx.plugins != null ? "plugins:ok" : "plugins:fail");
		results.push(ctx.scheduler != null ? "scheduler:ok" : "scheduler:fail");
		for (r in results) trace('[Diagnostics] ' + r);
		return results;
	}
}
