package core.structures;

import haxe.Json;
import sys.io.File;
import sys.FileSystem;

typedef Song =
{
	var song:String;
	var notes:Array<Section>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var speed:Float;
	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
	var validScore:Bool;
	var ?arrowSkin:String;
}

typedef Section =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
	var changeBPM:Bool;
	var bpm:Float;
	var ?altAnim:Bool;
}

class SongLoader
{
	public static function loadFromJson(songName:String, ?difficulty:Int = 1):Song
	{
		var diffSuffix:String = '';
		
		switch (difficulty)
		{
			case 0:
				diffSuffix = '-easy';
			case 2:
				diffSuffix = '-hard';
		}
		
		var formattedSong:String = formatSongName(songName);
		var jsonPath:String = Paths.json('songs/$formattedSong/$formattedSong$diffSuffix');
		
		var rawJson:String = null;
		
		if (FileSystem.exists(jsonPath))
		{
			rawJson = File.getContent(jsonPath);
		}
		else
		{
			trace('Song file not found: $jsonPath');
			return getDefaultSong();
		}
		
		var songData:Dynamic = Json.parse(rawJson);
		
		if (songData.song != null)
			return cast songData.song;
		else
			return cast songData;
	}
	
	public static function formatSongName(song:String):String
	{
		return song.toLowerCase().replace(' ', '-');
	}
	
	private static function getDefaultSong():Song
	{
		return {
			song: 'Tutorial',
			notes: [],
			events: [],
			bpm: 100,
			speed: 1,
			player1: 'bf',
			player2: 'dad',
			gfVersion: 'gf',
			stage: 'stage',
			validScore: false
		};
	}
}
