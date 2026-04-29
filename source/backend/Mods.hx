package backend;

import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;

class Mods
{
	public static var currentModDirectory:String = '';
	public static var loadedMods:Array<String> = [];
	
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
		
		if (FileSystem.exists(modsPath))
		{
			for (folder in FileSystem.readDirectory(modsPath))
			{
				var fullPath:String = Path.join([modsPath, folder]);
				if (FileSystem.isDirectory(fullPath))
				{
					loadedMods.push(folder);
				}
			}
		}
	}
	
	public static function setCurrentMod(modName:String):Void
	{
		if (loadedMods.contains(modName))
			currentModDirectory = modName;
		else
			currentModDirectory = '';
	}
	
	public static function exists(path:String):Bool
	{
		if (currentModDirectory != '')
		{
			var modPath:String = Path.join([modsPath, currentModDirectory, path]);
			if (FileSystem.exists(modPath))
				return true;
		}
		
		return FileSystem.exists(path);
	}
	
	public static function getContent(path:String):String
	{
		if (currentModDirectory != '')
		{
			var modPath:String = Path.join([modsPath, currentModDirectory, path]);
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
			var modPath:String = Path.join([modsPath, currentModDirectory, path]);
			if (FileSystem.exists(modPath))
				return modPath;
		}
		
		return path;
	}
}
