package backend;

import core.structures.Song;

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

class Conductor
{
	public static var bpm:Float = 100;
	public static var beatsPerSection:Int = 4;
	public static var stepsPerBeat:Int = 4;
	
	public static var offset:Float = 0;
	
	public static var safeFrames:Int = 10;
	public static var safeZoneOffset:Float = 0;
	public static var timeScale:Float = 1.0;
	
	public static var bpmChangeMap:Array<BPMChangeEvent> = [];
	
	public static var crochet(get, never):Float;
	static function get_crochet():Float
		return (60 / bpm) * 1000;

	public static var stepCrochet(get, never):Float;
	static function get_stepCrochet():Float
		return crochet / stepsPerBeat;

	public static var sectionCrochet(get, never):Float;
	static function get_sectionCrochet():Float
		return crochet * beatsPerSection;

	public static var songLength(get, never):Float;
	private static function get_songLength():Float
		return FlxG.sound.music == null ? 0 : FlxG.sound.music.length;

	public static var songPosition(get, never):Float;
	private static function get_songPosition():Float
		return FlxG.sound.music == null ? 0 : FlxG.sound.music.time + offset;

	public static var rawPosition(get, never):Float;
	private static function get_rawPosition():Float
		return FlxG.sound.music == null ? 0 : FlxG.sound.music.time;

	public static var curStep(get, never):Int;
	private static function get_curStep():Int
		return Math.floor(songPosition / stepCrochet);

	public static var curBeat(get, never):Int;
	private static function get_curBeat():Int
		return Math.floor(curStep / stepsPerBeat);

	public static var curSection(get, never):Int;
	private static function get_curSection():Int
		return Math.floor(curBeat / beatsPerSection);

	public static function recalculateTimings():Void
	{
		safeZoneOffset = Math.floor((safeFrames / 60) * 1000);
		timeScale = safeZoneOffset / 166;
	}

	public static function mapBPMChanges(song:Song):Void
	{
		bpmChangeMap = [];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		
		for (i in 0...song.notes.length)
		{
			if (song.notes[i].changeBPM && song.notes[i].bpm != curBPM)
			{
				curBPM = song.notes[i].bpm;
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = song.notes[i].lengthInSteps;
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
	}

	public static function changeBPM(newBpm:Float):Void
	{
		bpm = newBpm;
	}
	
	public static function reset():Void
	{
		bpm = 100;
		offset = 0;
		bpmChangeMap = [];
	}
}
