package states;

import backend.MusicBeatState;
import core.structures.Song;
import haxe.Json;
import sys.io.File;

class ChartingState extends MusicBeatState
{
	var curSection:Int = 0;
	var curBeat:Int = 0;
	
	var vocals:FlxSound;
	
	var strumLine:FlxSprite;
	var curRenderedNotes:FlxTypedGroup<FlxSprite>;
	var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	
	var gridBG:FlxSprite;
	var gridBlackLine:FlxSprite;
	
	var dummyArrow:FlxSprite;
	
	var bpmTxt:FlxText;
	var strumLineTxt:FlxText;
	
	var GRID_SIZE:Int = 40;
	
	override function create()
	{
		super.create();
		
		curRenderedNotes = new FlxTypedGroup<FlxSprite>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();
		
		if (PlayState.SONG == null)
			PlayState.SONG = SongLoader.loadFromJson('tutorial', 1);
		
		Conductor.changeBPM(PlayState.SONG.bpm);
		Conductor.mapBPMChanges(PlayState.SONG);
		
		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);
		add(gridBG);
		
		gridBlackLine = new FlxSprite(gridBG.x + gridBG.width / 2).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);
		add(gridBlackLine);
		
		add(curRenderedNotes);
		add(curRenderedSustains);
		
		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);
		
		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(FlxG.width / 2), 4);
		add(strumLine);
		
		bpmTxt = new FlxText(1000, 50, 0, "", 16);
		bpmTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);
		
		strumLineTxt = new FlxText(0, 0, 0, "time", 16);
		strumLineTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.RED, LEFT);
		strumLineTxt.scrollFactor.set();
		add(strumLineTxt);
		
		loadSong(PlayState.SONG.song);
		
		updateGrid();
	}
	
	function loadSong(songName:String):Void
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
		}
		
		FlxG.sound.playMusic(Paths.inst(songName), 0.6);
		FlxG.sound.music.pause();
		FlxG.sound.music.onComplete = function() {};
		
		vocals = new FlxSound();
		if (Paths.voices(songName) != null)
		{
			vocals.loadEmbedded(Paths.voices(songName));
		}
		FlxG.sound.list.add(vocals);
		vocals.pause();
		
		FlxG.sound.music.time = 0;
		vocals.time = 0;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		Conductor.songPosition = FlxG.sound.music.time;
		
		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) % (Conductor.stepCrochet * 16)) / (Conductor.stepCrochet * 16) * (GRID_SIZE * 16);
		
		if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
		{
			FlxG.sound.music.pause();
			vocals.pause();
			
			var daTime:Float = 700 * elapsed;
			if (FlxG.keys.pressed.W)
			{
				FlxG.sound.music.time -= daTime;
			}
			else
				FlxG.sound.music.time += daTime;
			
			vocals.time = FlxG.sound.music.time;
		}
		
		if (FlxG.keys.justPressed.SPACE)
		{
			if (FlxG.sound.music.playing)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}
			else
			{
				vocals.play();
				FlxG.sound.music.play();
			}
		}
		
		if (FlxG.keys.justPressed.R)
		{
			FlxG.sound.music.time = 0;
			vocals.time = 0;
		}
		
		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.switchState(new MenuState());
		}
		
		bpmTxt.text = 
			'Time: ' + Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2)) + ' / ' + Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2)) +
			'\nSection: ' + curSection +
			'\nBeat: ' + curBeat +
			'\nStep: ' + curStep;
	}
	
	function updateGrid():Void
	{
		curRenderedNotes.clear();
		curRenderedSustains.clear();
		
		var sectionInfo:Array<Dynamic> = PlayState.SONG.notes[curSection].sectionNotes;
		
		if (sectionInfo == null)
			return;
		
		for (i in sectionInfo)
		{
			var daNoteInfo = i[1];
			var daStrumTime = i[0];
			var daSus = i[2];
			
			var note:FlxSprite = new FlxSprite(0, 0).makeGraphic(GRID_SIZE, GRID_SIZE);
			note.x = Math.floor(daNoteInfo) * GRID_SIZE;
			note.y = Math.floor(getYfromStrum(daStrumTime - sectionStartTime()));
			
			curRenderedNotes.add(note);
			
			if (daSus > 0)
			{
				var sustainVis:FlxSprite = new FlxSprite(note.x + (GRID_SIZE / 2), note.y + GRID_SIZE).makeGraphic(8, Math.floor(getYfromStrum(daSus)));
				sustainVis.color = FlxColor.YELLOW;
				curRenderedSustains.add(sustainVis);
			}
		}
	}
	
	private function getYfromStrum(strumTime:Float):Float
	{
		return strumTime * 0.45;
	}
	
	private function sectionStartTime():Float
	{
		var daBPM:Float = PlayState.SONG.bpm;
		var daPos:Float = 0;
		
		for (i in 0...curSection)
		{
			daPos += 4 * (1000 * 60 / daBPM);
		}
		
		return daPos;
	}
}
