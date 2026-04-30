package core.config;

import haxe.Json;
import utils.Paths;

class ConfigService
{
	public static function loadFromDataJson():GameConfig
	{
		var path = Paths.json("data");
		if (!sys.FileSystem.exists(path))
			return new GameConfig();

		try
		{
			var parsed:GameConfigData = cast Json.parse(sys.io.File.getContent(path));
			return new GameConfig(parsed);
		}
		catch (e)
		{
			trace('Invalid config at $path: $e');
		}

		return new GameConfig();
	}
}
