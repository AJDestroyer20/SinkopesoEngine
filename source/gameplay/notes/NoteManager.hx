package gameplay.notes;

import flixel.group.FlxGroup.FlxTypedGroup;
import core.enums.CharacterType;

class NoteManager extends FlxTypedGroup<Note>
{
	public var playerStrums:StrumLine;
	public var opponentStrums:StrumLine;
	
	public var unspawnNotes:Array<Note> = [];
	
	public var noteSplashes:FlxTypedGroup<NoteSplash>;
	
	public function new()
	{
		super();
		
		playerStrums = new StrumLine(PLAYER);
		opponentStrums = new StrumLine(OPPONENT);
		
		noteSplashes = new FlxTypedGroup<NoteSplash>();
		
		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		noteSplashes.add(splash);
		splash.alpha = 0.0;
	}
	
	public function generateSong(songData:Song):Void
	{
		var noteData:Array<Section>;
		noteData = songData.notes;
		
		var daBeats:Int = 0;
		
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var gottaHitNote:Bool = section.mustHitSection;
				
				if (songNotes[1] > 3)
					gottaHitNote = !section.mustHitSection;
				
				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;
				
				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, '', gottaHitNote ? PLAYER : OPPONENT);
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);
				
				var susLength:Float = swagNote.sustainLength;
				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);
				
				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					
					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true, '', gottaHitNote ? PLAYER : OPPONENT);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);
					
					sustainNote.mustPress = gottaHitNote;
					
					if (sustainNote.mustPress)
						sustainNote.x += FlxG.width / 2;
				}
				
				swagNote.mustPress = gottaHitNote;
				
				if (swagNote.mustPress)
					swagNote.x += FlxG.width / 2;
			}
			
			daBeats += 1;
		}
		
		unspawnNotes.sort(sortByShit);
	}
	
	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}
	
	public function spawnNotes():Void
	{
		while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < 1800)
		{
			var dunceNote:Note = unspawnNotes[0];
			add(dunceNote);
			
			unspawnNotes.shift();
		}
	}
	
	public function updateNotes(elapsed:Float):Void
	{
		forEachAlive(function(daNote:Note)
		{
			var strumGroup:StrumLine = daNote.mustPress ? playerStrums : opponentStrums;
			var strum:Strum = strumGroup.members[daNote.noteData];
			
			daNote.y = (strum.y + (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(PlayState.SONG.speed, 2)));
			
			if (Preferences.data.downScroll)
				daNote.y = strum.y - (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(PlayState.SONG.speed, 2));
			
			if (daNote.isSustainNote)
			{
				if (daNote.y + daNote.offset.y <= strum.y + Note.swagWidth / 2
					&& (!Preferences.data.downScroll || daNote.y + daNote.offset.y >= strum.y + Note.swagWidth / 2))
				{
					var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
					swagRect.height = (strum.y + Note.swagWidth / 2 - daNote.y) / daNote.scale.y;
					swagRect.y = daNote.frameHeight - swagRect.height;
					
					daNote.clipRect = swagRect;
				}
			}
			
			if (!daNote.mustPress && daNote.wasGoodHit)
			{
				var altAnim:String = "";
				
				if (PlayState.SONG.notes[Std.int(curStep / 16)] != null)
				{
					if (PlayState.SONG.notes[Std.int(curStep / 16)].altAnim)
						altAnim = '-alt';
				}
				
				opponentNoteHit(daNote);
				
				opponentStrums.members[Math.abs(daNote.noteData)].playAnim('confirm', true);
				
				remove(daNote, true);
				daNote.destroy();
			}
			
			if (daNote.tooLate || daNote.wasGoodHit)
			{
				if (daNote.tooLate)
				{
					noteMiss(daNote.noteData);
				}
				
				daNote.active = false;
				daNote.visible = false;
				
				remove(daNote, true);
				daNote.destroy();
			}
		});
	}
	
	public var curStep:Int = 0;
	
	public function opponentNoteHit(note:Note):Void
	{
	}
	
	public function noteMiss(direction:Int):Void
	{
	}
	
	public function goodNoteHit(note:Note):Void
	{
	}
}
