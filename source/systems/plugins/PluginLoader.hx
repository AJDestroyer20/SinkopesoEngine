package systems.plugins;

class PluginLoader
{
	public var plugins:Array<PluginAPI> = [];

	public function new() {}

	public function register(plugin:PluginAPI):Void
	{
		plugins.push(plugin);
		plugin.onLoad();
	}

	public function unloadAll():Void
	{
		for (p in plugins) p.onUnload();
		plugins = [];
	}
}
