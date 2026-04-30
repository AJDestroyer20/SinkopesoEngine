package systems.plugins;

interface PluginAPI
{
	public function onLoad():Void;
	public function onUnload():Void;
}
