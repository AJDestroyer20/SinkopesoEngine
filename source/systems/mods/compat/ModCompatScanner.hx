package systems.mods.compat;

class ModCompatScanner
{
	public static function detectFormat(modFolder:String):EngineModFormat
	{
		if (sys.FileSystem.exists(haxe.io.Path.join([modFolder, "pack.json"])))
			return CODENAME;
		if (sys.FileSystem.exists(haxe.io.Path.join([modFolder, "_polymod_meta.json"])))
			return VSLICE;
		if (sys.FileSystem.exists(haxe.io.Path.join([modFolder, "weeks"])) || sys.FileSystem.exists(haxe.io.Path.join([modFolder, "scripts"])))
			return PSYCH;
		if (sys.FileSystem.exists(haxe.io.Path.join([modFolder, "data", "songList.txt"])))
			return KADE;
		if (sys.FileSystem.exists(haxe.io.Path.join([modFolder, "data", "huds"])))
			return ALE_PSYCH;
		return PSYCH;
	}
}
