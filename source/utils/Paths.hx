package utils;

import flixel.graphics.frames.FlxAtlasFrames;
import openfl.media.Sound;
import openfl.utils.Assets;
import sys.FileSystem;
import haxe.io.Path;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	
	public static function getPath(file:String, ?library:String):String
	{
		if (library != null)
			return getLibraryPath(file, library);
		
		return getPreloadPath(file);
	}
	
	inline static public function getLibraryPath(file:String, library:String = 'preload'):String
	{
		return if (library == 'preload' || library == 'default') getPreloadPath(file); else getLibraryPathForce(file, library);
	}
	
	inline static function getLibraryPathForce(file:String, library:String):String
	{
		return '$library/$file';
	}
	
	inline static function getPreloadPath(file:String):String
	{
		return 'assets/$file';
	}
	
	inline static public function file(file:String, ?library:String):String
	{
		return getPath(file, library);
	}
	
	inline static public function txt(key:String, ?library:String):String
	{
		return getPath('data/$key.txt', library);
	}
	
	inline static public function xml(key:String, ?library:String):String
	{
		return getPath('data/$key.xml', library);
	}
	
	inline static public function json(key:String, ?library:String):String
	{
		return getPath('data/$key.json', library);
	}
	
	static public function sound(key:String, ?library:String):Sound
	{
		return Assets.getSound(getPath('sounds/$key.$SOUND_EXT', library));
	}
	
	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String):Sound
	{
		return sound(key + FlxG.random.int(min, max), library);
	}
	
	inline static public function music(key:String, ?library:String):Sound
	{
		return Assets.getSound(getPath('music/$key.$SOUND_EXT', library));
	}
	
	inline static public function voices(song:String, ?suffix:String = ''):Sound
	{
		var path:String = 'songs/${song.toLowerCase()}/Voices$suffix.$SOUND_EXT';
		if (FileSystem.exists(getPreloadPath(path)))
			return Assets.getSound(getPreloadPath(path));
		return null;
	}
	
	inline static public function inst(song:String, ?suffix:String = ''):Sound
	{
		return Assets.getSound(getPreloadPath('songs/${song.toLowerCase()}/Inst$suffix.$SOUND_EXT'));
	}
	
	inline static public function image(key:String, ?library:String):Dynamic
	{
		return Assets.getBitmapData(getPath('images/$key.png', library));
	}
	
	inline static public function font(key:String):String
	{
		return getPath('fonts/$key');
	}
	
	inline static public function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSparrow(
			image(key, library), 
			file('images/$key.xml', library)
		);
	}
	
	inline static public function getPackerAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSpriteSheetPacker(
			image(key, library), 
			file('images/$key.txt', library)
		);
	}
	
	inline static public function video(key:String):String
	{
		return getPreloadPath('videos/$key.mp4');
	}
}
