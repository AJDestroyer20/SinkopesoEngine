package states;

import core.structures.SongLoader;
import backend.MusicBeatState;
import gameplay.notes.*;
import gameplay.characters.*;
import gameplay.events.*;
import gameplay.stage.*;
import flixel.group.FlxGroup.FlxTypedGroup;

class PlayState extends MusicBeatState
{
	public static var SONG:Song;
	public static var storyDifficulty:Int = 1;
	public static var storyWeek:Int = 0;
	public static var isStoryMode:Bool = false;
	public static var storyPlaylist:Array<String> = [];
	public static var curStage:String = 'stage';
	
	public static var instance:PlayState;
	
	public var noteManager:NoteManager;
	public var characterManager:CharacterManager;
	public var eventManager:EventManager;
	public var stageBuilder:StageBuilder;
	
	public var adaptiveAI:systems.AdaptiveAI;
	
	public var vocals:FlxSound;
	
	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;
	
	public var health:Float = 1;
	public var combo:Int = 0;
	
	public var healthBar:FlxSprite;
	public var healthBarBG:FlxSprite;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	
	public var scoreTxt:FlxText;
	
	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;
	
	public var songScore:Int = 0;
	public var songMisses:Int = 0;
	public var accuracy:Float = 0.00;
	
	public var totalNotesHit:Float = 0;
	public var totalPlayed:Int = 0;
	
	public var defaultCamZoom:Float = 1.05;
	public var camZooming:Bool = false;
	
	override function create()
	{
		instance = this;
		
		super.create();
		
		if (SONG == null)
			SONG = SongLoader.loadFromJson('tutorial', 1);
		
		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);
		
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		
		FlxCamera.defaultCameras = [camGame];
		
		curStage = SONG.stage;
		
		stageBuilder = new StageBuilder();
		stageBuilder.buildStage(curStage);
		stageBuilder.addLayersToState(this);
		
		defaultCamZoom = stageBuilder.defaultCamZoom;
		
		characterManager = new CharacterManager();
		characterManager.loadCharacters(SONG.player1, SONG.player2, SONG.gfVersion);
		characterManager.addCharactersToState(this);
		
		noteManager = new NoteManager();
		add(noteManager.opponentStrums);
		add(noteManager.playerStrums);
		add(noteManager.noteSplashes);
		add(noteManager);
		
		noteManager.noteSplashes.cameras = [camHUD];
		noteManager.opponentStrums.cameras = [camHUD];
		noteManager.playerStrums.cameras = [camHUD];
		noteManager.cameras = [camHUD];
		
		noteManager.generateSong(SONG);
		
		eventManager = new EventManager();
		if (SONG.events != null)
			eventManager.loadEvents(SONG.events);
		
		adaptiveAI = new systems.AdaptiveAI();
		adaptiveAI.enabled = false;
		
		var aiModes:Array<systems.AdaptiveAI.AIMode> = [AUTO, EASY, NORMAL, HARD, EXTREME];
		adaptiveAI.setMode(aiModes[Preferences.data.aiDifficulty]);
		
		generateUI();
		
		startingSong = true;
		startCountdown();
	}
	
	private function generateUI():Void
	{
		healthBarBG = new FlxSprite(0, FlxG.height * 0.9).makeGraphic(Std.int(FlxG.width), 10, FlxColor.BLACK);
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.cameras = [camHUD];
		add(healthBarBG);
		
		healthBar = new FlxSprite(healthBarBG.x + 4, healthBarBG.y + 4).makeGraphic(Std.int(healthBarBG.width - 8), 2, FlxColor.LIME);
		healthBar.scrollFactor.set();
		healthBar.cameras = [camHUD];
		add(healthBar);
		
		iconP1 = new HealthIcon(characterManager.boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		iconP1.cameras = [camHUD];
		add(iconP1);
		
		iconP2 = new HealthIcon(characterManager.dad.healthIcon, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		iconP2.cameras = [camHUD];
		add(iconP2);
		
		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.cameras = [camHUD];
		add(scoreTxt);
		
		updateScore();
	}
	
	private function startCountdown():Void
	{
		generatedMusic = true;
		
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;
		
		var countdown:Int = 0;
		
		new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			characterManager.beatHit();
			
			countdown++;
			
			switch (countdown)
			{
				case 1:
					FlxG.sound.play(Paths.sound('intro3'), 0.6);
				case 2:
					FlxG.sound.play(Paths.sound('intro2'), 0.6);
				case 3:
					FlxG.sound.play(Paths.sound('intro1'), 0.6);
				case 4:
					FlxG.sound.play(Paths.sound('introGo'), 0.6);
					startSong();
			}
		}, 5);
	}
	
	private function startSong():Void
	{
		startingSong = false;
		
		FlxG.sound.playMusic(Paths.inst(SONG.song), 1, false);
		FlxG.sound.music.onComplete = endSong;
		
		vocals = new FlxSound();
		if (Paths.voices(SONG.song) != null)
		{
			vocals.loadEmbedded(Paths.voices(SONG.song));
		}
		FlxG.sound.list.add(vocals);
		vocals.play();
		
		Conductor.songPosition = 0;
	}
	
	private function endSong():Void
	{
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		
		if (isStoryMode)
		{
			storyPlaylist.remove(storyPlaylist[0]);
			
			if (storyPlaylist.length <= 0)
			{
				FlxG.switchState(new MenuState());
			}
			else
			{
				var nextSong:String = storyPlaylist[0].toLowerCase();
				SONG = SongLoader.loadFromJson(nextSong, storyDifficulty);
				FlxG.switchState(new PlayState());
			}
		}
		else
		{
			FlxG.switchState(new FreeplayState());
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (controls.PAUSE && !startingSong)
		{
			openSubState(new substates.PauseSubState());
			return;
		}
		
		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.switchState(new TitleState());
			return;
		}
		
		if (generatedMusic && FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
			
			if (vocals.time > FlxG.sound.music.time + 20 || vocals.time < FlxG.sound.music.time - 20)
			{
				vocals.pause();
				vocals.time = FlxG.sound.music.time;
				vocals.play();
			}
		}
		
		if (generatedMusic)
		{
			noteManager.curStep = curStep;
			noteManager.spawnNotes();
			noteManager.updateNotes(elapsed);
			
			eventManager.checkEvents(Conductor.songPosition);
			
			if (adaptiveAI.enabled)
			{
				handleAIInput();
			}
			else
			{
				handleInput();
			}
			
			if (FlxG.keys.justPressed.SEVEN)
			{
				adaptiveAI.enabled = !adaptiveAI.enabled;
			}
		}
		
		updateHealthBar();
		updateCamera();
		
		characterManager.boyfriend.update(elapsed);
		characterManager.dad.update(elapsed);
		characterManager.gf.update(elapsed);
	}
	
	private function handleInput():Void
	{
		controls.update();
		
		var pressed:Array<Bool> = [controls.LEFT_P, controls.DOWN_P, controls.UP_P, controls.RIGHT_P];
		var released:Array<Bool> = [controls.LEFT_R, controls.DOWN_R, controls.UP_R, controls.RIGHT_R];
		
		if (pressed.contains(true))
		{
			for (i in 0...pressed.length)
			{
				if (pressed[i])
				{
					noteManager.playerStrums.playAnim(i, 'pressed', true);
					checkNoteHit(i);
				}
			}
		}
		
		for (i in 0...released.length)
		{
			if (released[i])
			{
				noteManager.playerStrums.playAnim(i, 'static', true);
			}
		}
	}
	
	private function handleAIInput():Void
	{
		adaptiveAI.adaptToPlayer(accuracy, songMisses, totalPlayed);
		
		noteManager.forEachAlive(function(note:Note)
		{
			if (note.mustPress && !note.wasGoodHit && !note.isSustainNote)
			{
				if (adaptiveAI.shouldHitNote(note, Conductor.songPosition))
				{
					goodNoteHit(note);
					noteManager.playerStrums.playAnim(note.noteData, 'confirm', true);
				}
			}
		});
	}
	
	private function checkNoteHit(noteData:Int):Void
	{
		var possibleNotes:Array<Note> = [];
		
		noteManager.forEachAlive(function(note:Note)
		{
			if (note.mustPress && note.noteData == noteData && note.canBeHit && !note.tooLate && !note.wasGoodHit)
			{
				possibleNotes.push(note);
			}
		});
		
		possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
		
		if (possibleNotes.length > 0)
		{
			var note:Note = possibleNotes[0];
			goodNoteHit(note);
		}
		else
		{
			if (!Preferences.data.ghostTapping)
				noteMiss(noteData);
		}
	}
	
	private function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			note.wasGoodHit = true;
			vocals.volume = 1;
			
			characterManager.boyfriend.playAnim('sing' + ['LEFT', 'DOWN', 'UP', 'RIGHT'][note.noteData], true);
			characterManager.boyfriend.holdTimer = 0;
			
			noteManager.playerStrums.playAnim(note.noteData, 'confirm', true);
			
			if (!note.isSustainNote)
			{
				combo++;
				popUpScore(note);
			}
			
			health += note.hitHealth;
			songScore += Std.int(note.noteScore);
			
			totalNotesHit += 1;
			
			note.kill();
			noteManager.remove(note, true);
			note.destroy();
			
			updateScore();
		}
	}
	
	private function noteMiss(direction:Int):Void
	{
		health -= 0.04;
		songScore -= 10;
		songMisses++;
		combo = 0;
		
		characterManager.boyfriend.playAnim('sing' + ['LEFT', 'DOWN', 'UP', 'RIGHT'][direction] + 'miss', true);
		
		vocals.volume = 0;
		
		updateScore();
	}
	
	private function popUpScore(note:Note):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition);
		
		var rating:String = "sick";
		
		if (noteDiff > Conductor.safeZoneOffset * 0.9)
			rating = 'shit';
		else if (noteDiff > Conductor.safeZoneOffset * 0.75)
			rating = 'bad';
		else if (noteDiff > Conductor.safeZoneOffset * 0.2)
			rating = 'good';
		
		totalPlayed++;
		
		if (rating == 'sick')
		{
			totalNotesHit += 1;
		}
		else if (rating == 'good')
		{
			totalNotesHit += 0.75;
		}
		else if (rating == 'bad')
		{
			totalNotesHit += 0.5;
		}
		
		accuracy = totalNotesHit / totalPlayed * 100;
	}
	
	private function updateHealthBar():Void
	{
		health = FlxMath.bound(health, 0, 2);
		
		if (health <= 0)
		{
			var bfX:Float = characterManager.boyfriend.getGraphicMidpoint().x;
			var bfY:Float = characterManager.boyfriend.getGraphicMidpoint().y;
			openSubState(new substates.GameOverSubState(bfX, bfY));
		}
		
		var healthPercent:Float = health / 2;
		healthBar.scale.x = (healthBarBG.width - 8) * healthPercent;
		
		iconP1.x = healthBar.x + healthBar.width - 75;
		iconP2.x = healthBar.x - 75;
	}
	
	private function updateCamera():Void
	{
		if (Preferences.data.camZooms && camZooming && FlxG.camera.zoom < 1.35)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}
		
		FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
	}
	
	private function updateScore():Void
	{
		var accuracyStr:String = Std.string(FlxMath.roundDecimal(accuracy, 2)) + '%';
		
		scoreTxt.text = 'Score: $songScore | Misses: $songMisses | Accuracy: $accuracyStr';
	}
	
	override function beatHit()
	{
		super.beatHit();
		
		characterManager.beatHit();
		
		if (curBeat % 4 == 0)
		{
			camZooming = true;
		}
	}
}

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	public var isPlayer:Bool = false;
	public var character:String = '';
	
	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		
		this.isPlayer = isPlayer;
		this.character = char;
		
		loadGraphic(Paths.image('iconGrid'), true, 150, 150);
		
		animation.add('bf', [0, 1], 0, false, isPlayer);
		animation.add('dad', [4, 5], 0, false, isPlayer);
		animation.add('gf', [2], 0, false, isPlayer);
		
		animation.play(char);
		scrollFactor.set();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
