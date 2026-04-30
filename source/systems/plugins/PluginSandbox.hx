package systems.plugins;

class PluginSandbox
{
	public static function isAllowedCall(symbol:String):Bool
	{
		var blocked = ["sys.io.Process", "sys.net.Socket"];
		return !blocked.contains(symbol);
	}
}
