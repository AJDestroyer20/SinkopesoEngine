package backend;

import backend.mods.ModCompatibility;
import backend.mods.ModManifest;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

class Mods
{
	public static var currentModDirectory:String = '';
	public static var loadedMods:Array<String> = [];
	public static var manifests(default, null):Map<String, ModManifest> = [];

	private static var modsPath:String = 'mods/';

	public static function init():Void
	{
		if (!FileSystem.exists(modsPath))
			FileSystem.createDirectory(modsPath);

		scanMods();
	}

	public static function scanMods():Void
	{
		loadedMods = [];
		manifests = [];

		if (!FileSystem.exists(modsPath))
			return;

		for (folder in FileSystem.readDirectory(modsPath))
		{
			var fullPath = Path.join([modsPath, folder]);
			if (!FileSystem.isDirectory(fullPath))
				continue;

			loadedMods.push(folder);
			manifests.set(folder, ModCompatibility.detect(fullPath));
		}
	}

	public static function setCurrentMod(modName:String):Void
	{
		currentModDirectory = loadedMods.contains(modName) ? modName : '';
	}

	public static function getCurrentManifest():Null<ModManifest>
	{
		if (currentModDirectory == '')
			return null;
		return manifests.get(currentModDirectory);
	}


	public static function resolveModPath(assetType:String, fileName:String):String
	{
		var manifest = getCurrentManifest();
		if (manifest == null)
			return fileName;

		var baseFolder = switch (assetType)
		{
			case 'chart': manifest.wrappers.pathResolver.chartsPath();
			case 'script': manifest.wrappers.pathResolver.scriptsPath();
			case 'asset': manifest.wrappers.pathResolver.assetsPath();
			default: '';
		};

		var relative = baseFolder == '' ? fileName : Path.join([baseFolder, fileName]);
		return Path.join([modsPath, currentModDirectory, relative]);
	}

	public static function exists(path:String):Bool
	{
		if (currentModDirectory != '')
		{
			var modPath = Path.join([modsPath, currentModDirectory, path]);
			if (FileSystem.exists(modPath))
				return true;
		}

		return FileSystem.exists(path);
	}

	public static function getContent(path:String):String
	{
		if (currentModDirectory != '')
		{
			var modPath = Path.join([modsPath, currentModDirectory, path]);
			if (FileSystem.exists(modPath))
				return File.getContent(modPath);
		}

		if (FileSystem.exists(path))
			return File.getContent(path);

		return null;
	}

	public static function getPath(path:String):String
	{
		if (currentModDirectory != '')
		{
			var modPath = Path.join([modsPath, currentModDirectory, path]);
			if (FileSystem.exists(modPath))
				return modPath;
		}

		return path;
	}
}
