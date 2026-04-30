package core.context;

import core.config.ConfigService;
import core.config.GameConfig;
import core.events.EventBus;
import systems.audio.AudioManager;
import systems.scripting.ScriptManager;
import systems.mods.ModManager;
import systems.plugins.PluginLoader;
import systems.logic.SystemScheduler;

class GameContext
{
	public static var instance(default, null):GameContext;

	public var config(default, null):GameConfig;
	public var events(default, null):EventBus;
	public var scripts(default, null):ScriptManager;
	public var audio(default, null):AudioManager;
	public var mods(default, null):ModManager;
	public var plugins(default, null):PluginLoader;
	public var scheduler(default, null):SystemScheduler;

	public static function init():GameContext
	{
		if (instance == null)
			instance = new GameContext();
		return instance;
	}

	private function new()
	{
		config = ConfigService.loadFromDataJson();
		events = new EventBus();
		scripts = new ScriptManager();
		audio = new AudioManager(events);
		mods = new ModManager();
		mods.scanMods();
		plugins = new PluginLoader();
		scheduler = new SystemScheduler();
	}
}
