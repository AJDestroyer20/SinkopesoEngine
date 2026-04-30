package systems.mods.porting;

import systems.mods.compat.EngineModFormat;

class ModPorter
{
	public static function exportMod(sourceFolder:String, targetFolder:String, target:EngineModFormat):Void
	{
		ensureDir(targetFolder);
		switch (target)
		{
			case PSYCH | ALE_PSYCH:
				copyIfExists(sourceFolder, targetFolder, ["data", "songs", "images", "scripts", "characters", "stages", "weeks"]);
			case VSLICE:
				copyIfExists(sourceFolder, targetFolder, ["_polymod_meta.json", "_append", "_merge", "_override", "data", "images", "songs"]);
			case KADE:
				copyIfExists(sourceFolder, targetFolder, ["assets", "data", "songs"]);
			case CODENAME:
				copyIfExists(sourceFolder, targetFolder, ["pack.json", "data", "songs", "images", "scripts"]);
		}
	}

	static function copyIfExists(source:String, target:String, entries:Array<String>):Void
	{
		for (entry in entries)
		{
			var from = haxe.io.Path.join([source, entry]);
			if (sys.FileSystem.exists(from))
			{
				var to = haxe.io.Path.join([target, entry]);
				copyRecursive(from, to);
			}
		}
	}

	static function copyRecursive(source:String, target:String):Void
	{
		if (sys.FileSystem.isDirectory(source))
		{
			ensureDir(target);
			for (name in sys.FileSystem.readDirectory(source))
				copyRecursive(haxe.io.Path.join([source, name]), haxe.io.Path.join([target, name]));
		}
		else
		{
			ensureDir(haxe.io.Path.directory(target));
			sys.io.File.saveBytes(target, sys.io.File.getBytes(source));
		}
	}

	static inline function ensureDir(path:String):Void
	{
		if (path != null && path.length > 0 && !sys.FileSystem.exists(path))
			sys.FileSystem.createDirectory(path);
	}
}
