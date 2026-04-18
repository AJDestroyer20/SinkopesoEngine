package gameplay;

import openfl.events.KeyboardEvent;
import openfl.Lib;

import flixel.group.FlxGroup;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxObject;

#if FEATURE_LUAMODCHART
import scripting.LuaClass.LuaCamera;
import scripting.LuaClass.LuaCharacter;
import scripting.LuaClass.LuaNote;
#end

#if FEATURE_STEPMANIA
import smTools.SMFile;
#end

#if FEATURE_FILESYSTEM
import sys.io.File;
import sys.FileSystem;
#end

#if FEATURE_DISCORD
import api.Discord.DiscordClient;
#end

import gameplay.Section.SwagSection;
import data.song.Song.SongData;
import data.song.Song.Event;
import data.replay.Replay.Ana;
import data.replay.Replay.Analysis;

import scripting.ScriptManager;
import scripting.ScriptCallbacks;
import scripting.WindowConfig;
import gameplay.ai.AdaptiveAI;
import audio.ReactiveAudio;
import gameplay.cinematic.CinematicCamera;
import gameplay.events.EventSystem;
import gfx.ShaderManager;
import gfx.WiggleEffect.WiggleEffectType;

import gameplay.characters.Boyfriend;
import gameplay.notes.StaticArrow;
using StringTools;

/**
 * when: reescribes el playstate
 */
class PlayState extends scripting.ScriptableState
{
	// ── All coments may or may not help for scripting ─────────────────────────────────────────────────────────────

	public static var instance:PlayState = null;

	// ── Static song / session ─────────────────────────────────────────────────

	public static var SONG:SongData;
	public static var isStoryMode:Bool    = false;
	public static var storyWeek:Int       = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public static var weekSong:Int        = 0;
	public static var songMultiplier:Float = 1.0;
	public static var startTime:Float      = 0.0;
	public static var songOffset:Float     = 0;
	public static var offsetTesting:Bool  = false;
	public static var stageTesting:Bool   = false;

	// Campaign / per-run counters (reset in create)
	public static var campaignScore:Int  = 0;
	public static var campaignMisses:Int = 0;
	public static var campaignSicks:Int  = 0;
	public static var campaignGoods:Int  = 0;
	public static var campaignBads:Int   = 0;
	public static var campaignShits:Int  = 0;
	public static var misses:Int         = 0;
	public static var shits:Int          = 0;
	public static var bads:Int           = 0;
	public static var goods:Int          = 0;
	public static var sicks:Int          = 0;
	public static var highestCombo:Int   = 0;
	public static var repPresses:Int     = 0;
	public static var repReleases:Int    = 0;

	// ── Replay ────────────────────────────────────────────────────────────────

	public static var rep:data.replay.Replay;
	public static var loadRep:Bool         = false;
	public static var inResults:Bool       = false;
	private var saveNotes:Array<Dynamic>   = [];
	private var saveJudge:Array<String>    = [];
	private var replayAna:Analysis         = new Analysis();
	private var mashing:Int                = 0;
	private var mashViolations:Int         = 0;

	// ── Characters ────────────────────────────────────────────────────────────

	public static var dad:Character;
	public static var gf:Character;
	public static var boyfriend:Boyfriend;

	// ── Notes / strums ────────────────────────────────────────────────────────

	public var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note>             = [];
	public static var noteskinSprite:FlxAtlasFrames;
	public static var noteskinPixelSprite:openfl.display.BitmapData;
	public static var noteskinPixelSpriteEnds:openfl.display.BitmapData;
	public static var strumLineNotes:FlxTypedGroup<StaticArrow> = null;
	public static var playerStrums:FlxTypedGroup<StaticArrow>   = null;
	public static var cpuStrums:FlxTypedGroup<StaticArrow>      = null;
	public static var noteBools:Array<Bool>          = [false, false, false, false];
	private var strumLine:FlxSprite;
	private var laneunderlay:FlxSprite;
	private var laneunderlayOpponent:FlxSprite;
	private var pastScrollChanges:Array<Event>       = [];
	private var currentLuaIndex:Int                  = 0;
	private var updateFrame:Int                      = 0;

	// ── Cameras ───────────────────────────────────────────────────────────────

	public var camHUD:DaCamera;
	public var camSustains:DaCamera;
	public var camNotes:DaCamera;
	private var camGame:DaCamera;
	private var camFollow:FlxObject;
	private static var prevCamFollow:FlxObject;

	// ── HUD ───────────────────────────────────────────────────────────────────

	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	private var scoreTxt:FlxText;
	private var judgementCounter:FlxText;
	private var replayTxt:FlxText;
	private var botPlayState:FlxText;
	private var kadeEngineWatermark:FlxText;
	public var bar:FlxSprite;
	private var songName:FlxText;
	public static var songPosBar:FlxBar;
	public static var songPosBG:FlxSprite;

	// ── Scoring ───────────────────────────────────────────────────────────────

	public var health:Float             = 1;
	public var songScore:Int            = 0;
	public var accuracy:Float           = 0.0;
	private var accuracyDefault:Float   = 0.0;
	private var totalNotesHit:Float     = 0;
	private var totalNotesHitDefault:Float = 0;
	private var totalPlayed:Int         = 0;
	private var songScoreDef:Int        = 0;
	private var combo:Int               = 0;
	private var nps:Int                 = 0;
	private var maxNPS:Int              = 0;
	private var notesHitArray:Array<Date> = [];
	private var fc:Bool                 = true;
	private var ss:Bool                 = false;

	// ── Song state ────────────────────────────────────────────────────────────

	public var vocals:FlxSound;
	public static var inDaPlay:Bool     = false;
	public static var currentSong:String = "";
	public static var isSM:Bool         = false;

	#if FEATURE_STEPMANIA
	public static var sm:SMFile;
	public static var pathToSm:String;
	#end

	private var curSong:String          = "";
	private var songLength:Float        = 0;
	private var songPositionBar:Float   = 0;
	private var generatedMusic:Bool     = false;
	private var startingSong:Bool       = false;
	private var endingSong:Bool         = false;
	private var songStarted:Bool        = false;
	private var startedCountdown:Bool   = false;
	private var paused:Bool             = false;
	private var canPause:Bool           = true;
	private var inCutscene:Bool         = false;
	private var talking:Bool            = true;
	private var removedVideo:Bool       = false;
	private var stopUpdate:Bool         = false;
	private var addedBotplay:Bool       = false;

	// ── Skip intro ────────────────────────────────────────────────────────────

	private var needSkip:Bool           = false;
	private var skipActive:Bool         = false;
	private var skipText:FlxText;
	private var skipTo:Float            = 0;
	private var offsetTest:Float        = 0;

	// ── Scene ─────────────────────────────────────────────────────────────────

	public static var Stage:Stage;
	private var gfSpeed:Int             = 1;
	private var camZooming:Bool         = false;
	private var camPos:FlxPoint;
	private var currentSection:SwagSection;
	private var altSuffix:String        = "";
	private var dialogue:Array<String>  = [];
	private var idleToBeat:Bool         = true;
	private var idleBeat:Int            = 2;
	private var forcedToIdle:Bool       = false;
	private var allowedToHeadbang:Bool  = true;
	private var allowedToCheer:Bool     = false;
	private var previousRate:Float      = 1.0;
	private var startTimer:FlxTimer;
	private var perfectMode:Bool        = false;
	private var wiggleShit:WiggleEffect = new WiggleEffect();
	private var cleanedSong:SongData;

	// ── Video ─────────────────────────────────────────────────────────────────

	public var useVideo:Bool            = false;
	#if FEATURE_VIDEO
	public var videoHandler:VideoHandler;
	#end

	// ── Lua modchart ─────────────────────────────────────────────────────────

	public var executeModchart:Bool     = false;
	#if FEATURE_LUAMODCHART
	public static var luaModchart:ModchartState = null;
	#end

	// ── New systems ───────────────────────────────────────────────────────────

	public var adaptiveAI:AdaptiveAI;
	public var reactiveAudio:ReactiveAudio;
	public var camCinematic:CinematicCamera;

	// ── Misc ──────────────────────────────────────────────────────────────────

	public var cannotDie:Bool            = false;
	public var randomVar:Bool            = false;
	public static var theFunne:Bool      = true;
	private var previousFrameTime:Int    = 0;
	private var lastReportedPlayheadPosition:Int = 0;
	private final dataSuffix:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];

	#if FEATURE_DISCORD
	private var storyDifficultyText:String = "";
	private var detailsText:String         = "";
	private var detailsPausedText:String   = "";
	private var iconRPC:String             = "";
	#end

	// ── Script exposure ───────────────────────────────────────────────────────

	public var songPosition(get, never):Float;
	inline function get_songPosition():Float return Conductor.songPosition;

	public function addObject(o:FlxBasic)    add(o);
	public function removeObject(o:FlxBasic) remove(o);

	override function injectStateVars():Void
	{
		super.injectStateVars();
		scripts.setVar("game",     this);
		scripts.setVar("instance", this);
	}

	// ═════════════════════════════════════════════════════════════════════════
	// CREATE
	// ═════════════════════════════════════════════════════════════════════════

	override public function create()
	{
		FlxG.mouse.visible = false;
		instance = this;
		inDaPlay = true;

		if (currentSong != SONG.songName)
		{
			currentSong = SONG.songName;
			Main.dumpCache();
		}

		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		if (FlxG.save.data.fpsCap > 290) (cast(Lib.current.getChildAt(0), Main)).setFPSCap(800);
		if (isStoryMode) songMultiplier = 1;
		previousRate = songMultiplier > 1.05 ? songMultiplier - 0.05 : 1;

		_resetCounters();
		_applyChangeables();
		_syncFreeplayMeta();
		_initScripting();
		_initCameras();
		_initStage();
		_initCharacters();
		_initSong();
		_initHUD();
		_initSystems();

		#if FEATURE_DISCORD
		_initDiscord();
		#end

		super.create();
	}

	// ── Create helpers ────────────────────────────────────────────────────────

	private inline function _resetCounters():Void
	{
		sicks = bads = shits = goods = misses = 0;
		highestCombo = repPresses = repReleases = 0;
		inResults = false;
	}

	private inline function _applyChangeables():Void
	{
		PlayStateChangeables.reset();
		var d = FlxG.save.data;
		if (d == null) return;
		PlayStateChangeables.useDownscroll = d.downscroll ?? false;
		PlayStateChangeables.safeFrames    = d.frames ?? 10;
		PlayStateChangeables.scrollSpeed   = (d.scrollSpeed ?? 1.0) * songMultiplier;
		PlayStateChangeables.botPlay       = d.botplay ?? false;
		PlayStateChangeables.Optimize      = d.optimize ?? false;
		PlayStateChangeables.zoom          = d.zoom ?? 1.0;
		PlayStateChangeables.mirrorMode    = d.mirrorMode   ?? false;
		PlayStateChangeables.opponentMode  = d.opponentMode ?? false;
		PlayStateChangeables.darkMode      = d.darkMode     ?? false;
	}

	private inline function _syncFreeplayMeta():Void
	{
		GameplayCustomizeState.freeplayBf        = SONG.player1;
		GameplayCustomizeState.freeplayDad       = SONG.player2;
		GameplayCustomizeState.freeplayGf        = SONG.gfVersion;
		GameplayCustomizeState.freeplayNoteStyle = SONG.noteStyle;
		GameplayCustomizeState.freeplayStage     = SONG.stage;
		GameplayCustomizeState.freeplaySong      = SONG.songId;
		GameplayCustomizeState.freeplayWeek      = storyWeek;
	}

	private function _initScripting():Void
	{
		ScriptManager.init();
		EventSystem.init();
		ShaderManager.init();
		ScriptManager.loadFolder("mods/scripts/global");
		if (SONG != null)
		{
			ScriptManager.loadFolder('mods/scripts/songs/${SONG.songId.toLowerCase()}');
			ScriptManager.loadFolder('assets/data/${SONG.songId.toLowerCase()}/scripts');
		}
	}

	private function _initCameras():Void
	{
		camGame     = new DaCamera();
		camHUD      = new DaCamera();
		camSustains = new DaCamera();
		camNotes    = new DaCamera();
		for (c in [camHUD, camSustains, camNotes]) c.bgColor.alpha = 0;
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camSustains);
		FlxG.cameras.add(camNotes);
		camHUD.zoom = PlayStateChangeables.zoom;
		DaCamera.defaultCameras = [camGame];

		camCinematic = new CinematicCamera(camGame);
		camCinematic.hudCamera = camHUD;
		camCinematic.baseZoom  = PlayStateChangeables.zoom;
		camCinematic.bpm       = SONG != null ? SONG.bpm : 100;
		persistentUpdate = persistentDraw = true;
	}

	private function _initStage():Void
	{
		if (SONG == null) SONG = Song.loadFromJson('tutorial', '');
		if (SONG.eventObjects == null)
			SONG.eventObjects = [new Song.Event("Init BPM", 0, SONG.bpm, "BPM Change")];

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		TimingStruct.clearTimings();
		var idx = 0;
		for (ev in SONG.eventObjects)
			if (ev.type == "BPM Change")
			{
				var bpm = ev.value * songMultiplier;
				TimingStruct.addTiming(ev.position, bpm, Math.POSITIVE_INFINITY, 0);
				if (idx != 0)
				{
					var prev = TimingStruct.AllTimings[idx - 1];
					prev.endBeat = ev.position;
					prev.length  = ((prev.endBeat - prev.startBeat) / (prev.bpm / 60)) / songMultiplier;
					var step     = ((60 / prev.bpm) * 1000) / 4;
					TimingStruct.AllTimings[idx].startStep = Math.floor((((prev.endBeat / (prev.bpm / 60)) * 1000) / step) / songMultiplier);
					TimingStruct.AllTimings[idx].startTime = prev.startTime + prev.length / songMultiplier;
				}
				idx++;
			}

		recalculateAllSectionTimes();

		// Stage
		var stageCheck = SONG.stage ?? switch (storyWeek) {
			case 2: 'halloween'; case 3: 'philly'; case 4: 'limo';
			case 5: SONG.songId == 'winter-horrorland' ? 'mallEvil' : 'mall';
			case 6: SONG.songId == 'thorns' ? 'schoolEvil' : 'school';
			default: 'stage';
		};
		Stage = new Stage(stageCheck);
		for (obj in Stage.toAdd) add(obj);
		for (layer in Stage.layInFront) for (obj in layer) add(obj);

		// Dialogue
		var dialoguePath = Paths.txt('data/songs/${SONG.songId}/dialogue');
		if (Paths.doesTextAssetExist(dialoguePath))
			dialogue = CoolUtil.coolTextFile(dialoguePath);
	}

	private function _initCharacters():Void
	{
		var gfCheck = SONG.gfVersion ?? switch (storyWeek) {
			case 4: 'gf-car'; case 5: 'gf-christmas'; case 6: 'gf-pixel'; default: 'gf';
		};

		if (!stageTesting)
		{
			gf        = new Character(400, 130, gfCheck);
			if (gf.frames == null) gf = new Character(400, 130, 'gf');
			boyfriend = new Boyfriend(770, 450, SONG.player1);
			if (boyfriend.frames == null) boyfriend = new Boyfriend(770, 450, 'bf');
			dad       = new Character(100, 100, SONG.player2);
			if (dad.frames == null) dad = new Character(100, 100, 'dad');
		}

		camPos = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);
		Stage.setCharacters(gf, boyfriend, dad);
	}

	private function _initSong():Void
	{
		curSong = SONG.songId ?? '';

		noteskinSprite          = NoteskinHelpers.generateNoteskinSprite(FlxG.save.data.noteskin);
		noteskinPixelSprite     = NoteskinHelpers.generatePixelSprite(FlxG.save.data.noteskin);
		noteskinPixelSpriteEnds = NoteskinHelpers.generatePixelSprite(FlxG.save.data.noteskin, true);

		strumLine = new FlxSprite(0, PlayStateChangeables.useDownscroll ? FlxG.height - 165 : 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		laneunderlayOpponent = _makeLane();
		laneunderlay         = _makeLane();
		if (FlxG.save.data.laneUnderlay && !PlayStateChangeables.Optimize)
		{
			if (!FlxG.save.data.middleScroll || executeModchart) add(laneunderlayOpponent);
			add(laneunderlay);
		}

		strumLineNotes = new FlxTypedGroup<StaticArrow>();
		playerStrums   = new FlxTypedGroup<StaticArrow>();
		cpuStrums      = new FlxTypedGroup<StaticArrow>();
		add(strumLineNotes);

		generateStaticArrows(0);
		generateStaticArrows(1);
		laneunderlay.x         = playerStrums.members[0].x - 25;
		laneunderlayOpponent.x = cpuStrums.members[0].x - 25;
		laneunderlay.screenCenter(Y);
		laneunderlayOpponent.screenCenter(Y);

		generateSong(SONG.songId);

		#if FEATURE_LUAMODCHART
		var luaPath = Paths.lua('songs/${SONG.songId.toLowerCase()}/modchart');
		#if !cpp
		executeModchart = false;
		#elseif FEATURE_FILESYSTEM
		executeModchart = FileSystem.exists(luaPath);
		#end
		if (executeModchart)
		{
			luaModchart = ModchartState.createModchartState(isStoryMode);
			luaModchart.executeState('start', [SONG.songId]);
			new LuaCamera(camGame,     "camGame").Register(ModchartState.lua);
			new LuaCamera(camHUD,      "camHUD").Register(ModchartState.lua);
			new LuaCamera(camSustains, "camSustains").Register(ModchartState.lua);
			new LuaCamera(camNotes,    "camNotes").Register(ModchartState.lua);
			new LuaCharacter(dad,      "dad").Register(ModchartState.lua);
			new LuaCharacter(gf,       "gf").Register(ModchartState.lua);
			new LuaCharacter(boyfriend,"boyfriend").Register(ModchartState.lua);
		}
		#end

		if (startTime != 0)
		{
			unspawnNotes = unspawnNotes.filter(function(n) return n.strumTime > startTime);
		}

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		if (prevCamFollow != null) { camFollow = prevCamFollow; prevCamFollow = null; }
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.04 * (30 / (cast(Lib.current.getChildAt(0), Main)).getFPS()));
		FlxG.camera.zoom = Stage.camZoom;
		FlxG.camera.focusOn(camFollow.getPosition());
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		FlxG.fixedTimestep = false;
	}

	private inline function _makeLane():FlxSprite
	{
		var s = new FlxSprite(0, 0).makeGraphic(Std.int(110 * 4 + 50), Std.int(FlxG.height * 2));
		s.alpha = FlxG.save.data.laneTransparency;
		s.color = FlxColor.BLACK;
		s.scrollFactor.set();
		return s;
	}

	private function _initHUD():Void
	{
		var isDown = PlayStateChangeables.useDownscroll;
		var barY   = isDown ? 50.0 : FlxG.height * 0.9;

		healthBarBG = new FlxSprite(0, barY).loadGraphic(Paths.loadImage('healthBar'));
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT,
			Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this, 'health', 0, 2);
		healthBar.scrollFactor.set();

		kadeEngineWatermark = new FlxText(4, healthBarBG.y + 50, 0,
			SONG.songName + (FlxMath.roundDecimal(songMultiplier, 2) != 1.00 ? ' (${FlxMath.roundDecimal(songMultiplier, 2)}x)' : '')
			+ ' - ' + CoolUtil.difficultyFromInt(storyDifficulty), 16);
		kadeEngineWatermark.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		kadeEngineWatermark.scrollFactor.set();
		if (isDown) kadeEngineWatermark.y = FlxG.height * 0.9 + 45;
		add(kadeEngineWatermark);

		scoreTxt = new FlxText(0, healthBarBG.y + 50, FlxG.width, "", 16);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.screenCenter(X);
		scoreTxt.scrollFactor.set();
		if (!FlxG.save.data.healthBar) scoreTxt.y = healthBarBG.y;
		scoreTxt.text = Ratings.CalculateRanking(songScore, songScoreDef, nps, maxNPS, accuracy);
		add(scoreTxt);

		judgementCounter = new FlxText(20, 0, 0, "", 20);
		judgementCounter.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		judgementCounter.borderSize = judgementCounter.borderQuality = 2;
		judgementCounter.scrollFactor.set();
		judgementCounter.screenCenter(Y);
		judgementCounter.text = 'Sicks: ${sicks}\nGoods: ${goods}\nBads: ${bads}\nShits: ${shits}\nMisses: ${misses}';
		if (FlxG.save.data.judgementCounter) add(judgementCounter);

		var labelY = healthBarBG.y + (isDown ? 100 : -100);
		replayTxt    = _makeLabel(healthBarBG.x + healthBarBG.width / 2 - 75, labelY, "REPLAY");
		botPlayState = _makeLabel(healthBarBG.x + healthBarBG.width / 2 - 75, labelY, "BOTPLAY");
		if (loadRep)                                    add(replayTxt);
		if (PlayStateChangeables.botPlay && !loadRep)   add(botPlayState);
		addedBotplay = PlayStateChangeables.botPlay;

		iconP1 = new HealthIcon(boyfriend.curCharacter, true);
		iconP2 = new HealthIcon(dad.curCharacter, false);
		iconP1.y = iconP2.y = healthBar.y - 75;

		if (FlxG.save.data.healthBar)
		{
			add(healthBarBG);
			add(healthBar);
			add(iconP1);
			add(iconP2);
			if (FlxG.save.data.colour)
				healthBar.createFilledBar(dad.barColor, boyfriend.barColor);
			else
				healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		}

		var hudCam = [camHUD];
		for (s in [strumLineNotes, notes, healthBar, healthBarBG, iconP1, iconP2,
				   scoreTxt, judgementCounter, replayTxt, botPlayState, kadeEngineWatermark,
				   laneunderlay, laneunderlayOpponent])
			if (s != null) s.cameras = hudCam;

		startingSong = true;
		dad.dance(); boyfriend.dance(); gf.dance();
		if (!loadRep) rep = new data.replay.Replay("na");

		if (isStoryMode)
			_storyModeIntro();
		else
			new FlxTimer().start(1, function(_) startCountdown());
	}

	private inline function _makeLabel(x:Float, y:Float, text:String):FlxText
	{
		var t = new FlxText(x, y, 0, text);
		t.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		t.borderSize = 4; t.borderQuality = 2;
		t.scrollFactor.set(); t.cameras = [camHUD];
		return t;
	}

	private function _storyModeIntro():Void
	{
		var song = StringTools.replace(curSong, " ", "-").toLowerCase();
		switch (song)
		{
			case "winter-horrorland":
				var black = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				add(black); black.scrollFactor.set(); camHUD.visible = false;
				new FlxTimer().start(0.1, function(_)
				{
					remove(black);
					FlxG.sound.play(Paths.sound('Lights_Turn_On'));
					camFollow.y = -2050; camFollow.x += 200;
					FlxG.camera.focusOn(camFollow.getPosition());
					FlxG.camera.zoom = 1.5;
					new FlxTimer().start(1, function(_)
					{
						camHUD.visible = true;
						FlxTween.tween(FlxG.camera, {zoom: Stage.camZoom}, 2.5,
							{ease: FlxEase.quadInOut, onComplete: function(_) startCountdown()});
					});
				});
			case 'senpai':
				schoolIntro(new ui.DialogueBox(false, dialogue));
			case 'roses':
				FlxG.sound.play(Paths.sound('ANGRY'));
				schoolIntro(new ui.DialogueBox(false, dialogue));
			case 'thorns':
				schoolIntro(new ui.DialogueBox(false, dialogue));
			default:
				new FlxTimer().start(1, function(_) startCountdown());
		}
	}

	private function _initSystems():Void
	{
		FlxG.keys.preventDefaultKeys = [];
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, handleInput);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP,   releaseInput);

		adaptiveAI    = new AdaptiveAI(AdaptiveAI.PERSONALITY_ADAPTIVE);
		reactiveAudio = new ReactiveAudio(SONG.songId);
		reactiveAudio.loadStems();

		ScriptManager.setVar("health",      health);
		ScriptManager.setVar("combo",       combo);
		ScriptManager.setVar("accuracy",    accuracy);
		ScriptManager.setVar("songScore",   songScore);
		ScriptManager.setVar("songName",    SONG.songId);
		ScriptManager.setVar("bpm",         Conductor.bpm);
		ScriptManager.setVar("isStoryMode", isStoryMode);
		ScriptManager.setVar("botPlay",     PlayStateChangeables.botPlay);
	}

	#if FEATURE_DISCORD
	private function _initDiscord():Void
	{
		storyDifficultyText = ["Easy","Normal","Hard"][storyDifficulty];
		iconRPC             = "icon";
		detailsText         = isStoryMode ? "Story Mode: " + WeekData.getWeekData(storyWeek).name : "Freeplay";
		detailsPausedText   = "Paused — " + detailsText;
		DiscordClient.changePresence(detailsText, SONG.songName + ' ($storyDifficultyText)', iconRPC);
	}
	#end

	// ═════════════════════════════════════════════════════════════════════════
	// UPDATE
	// ═════════════════════════════════════════════════════════════════════════

	override public function update(elapsed:Float)
	{
		#if !debug
		perfectMode = false;
		#end

		ScriptManager.setVar("health",       health);
		ScriptManager.setVar("songPosition", Conductor.songPosition);
		ScriptManager.setVar("combo",        combo);
		ScriptManager.setVar("accuracy",     accuracy);
		ScriptManager.setVar("songScore",    songScore);
		ScriptManager.setVar("misses",       misses);
		ScriptManager.call(ScriptCallbacks.UPDATE, [elapsed, Conductor.songPosition]);

		if (songStarted) { reactiveAudio.update(accuracy, combo, health / 2.0, elapsed); adaptiveAI.update(accuracy, combo, health, elapsed); }
		camCinematic.update(elapsed);
		if (!PlayStateChangeables.Optimize) Stage.update(elapsed);

		if (!addedBotplay && FlxG.save.data.botplay) { PlayStateChangeables.botPlay = true; addedBotplay = true; add(botPlayState); }

		_spawnNotes();
		#if cpp _pitchAudio(); #end
		_handleBPMEvents();
		_handleScrollEvents();
		if (PlayStateChangeables.botPlay && FlxG.keys.justPressed.ONE) camHUD.visible = !camHUD.visible;
		_handleVideo();
		#if FEATURE_LUAMODCHART _tickLua(elapsed); #end
		_handleCamera();
		if (camZooming) _tickCameraZoom();

		FlxG.watch.addQuick("curBPM",   Conductor.bpm);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (curSong == 'Fresh') _freshUpdate();

		if (FlxG.save.data.cpuStrums)
			cpuStrums.forEach(function(s:StaticArrow) { if (s.animation.finished) { s.playAnim('static'); s.centerOffsets(); } });

		if (health > 2) health = 2;

		_updateIcons();
		_updateSongPosition();

		if (generatedMusic) _tickNotes();
		if (!inCutscene && songStarted) keyShit();

		#if debug if (FlxG.keys.justPressed.ONE) endSong(); #end

		super.update(elapsed);
	}

	// ── Update helpers ────────────────────────────────────────────────────────

	private inline function _spawnNotes():Void
	{
		if (unspawnNotes[0] == null) return;
		if (unspawnNotes[0].strumTime - Conductor.songPosition < 14000 * songMultiplier)
		{
			var dunceNote = unspawnNotes[0];
			notes.add(dunceNote);
			#if FEATURE_LUAMODCHART
			if (executeModchart) { new LuaNote(dunceNote, currentLuaIndex); dunceNote.luaID = currentLuaIndex; }
			#end
			dunceNote.cameras = [executeModchart ? (dunceNote.isSustainNote ? camSustains : camNotes) : camHUD];
			unspawnNotes.splice(unspawnNotes.indexOf(dunceNote), 1);
			currentLuaIndex++;
		}
	}

	#if cpp
	private inline function _pitchAudio():Void
	{
		@:privateAccess if (FlxG.sound.music.playing)
		{
			lime.media.openal.AL.sourcef(FlxG.sound.music._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, songMultiplier);
			if (vocals.playing)
				lime.media.openal.AL.sourcef(vocals._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, songMultiplier);
		}
	}
	#end

	private inline function _handleBPMEvents():Void
	{
		if (!FlxG.sound.music.playing) return;
		var seg = TimingStruct.getTimingAtBeat(curDecimalBeat);
		if (seg != null && seg.bpm != Conductor.bpm)
		{
			Conductor.changeBPM(seg.bpm, false);
			Conductor.crochet     = (60 / seg.bpm * 1000) / songMultiplier;
			Conductor.stepCrochet = Conductor.crochet / 4;
		}
	}

	private inline function _handleScrollEvents():Void
	{
		if (!FlxG.sound.music.playing) return;
		for (ev in SONG.eventObjects)
			if (ev.type == "Scroll Speed Change" && ev.position <= curDecimalBeat && !pastScrollChanges.contains(ev))
			{
				pastScrollChanges.push(ev);
				PlayStateChangeables.scrollSpeed *= ev.value;
			}
	}

	private inline function _handleVideo():Void
	{
		if (!useVideo || GlobalVideo.get() == null || stopUpdate) return;
		if (GlobalVideo.get().ended && !removedVideo)
		{
			#if FEATURE_VIDEO if (videoHandler != null) remove(videoHandler.sprite); #end
			removedVideo = true;
		}
	}

	#if FEATURE_LUAMODCHART
	private inline function _tickLua(elapsed:Float):Void
	{
		if (executeModchart && luaModchart != null && songStarted)
		{
			luaModchart.setVar('songPos',         Conductor.songPosition);
			luaModchart.setVar('curBeat',         HelperFunctions.truncateFloat(curDecimalBeat, 3));
			luaModchart.setVar('hudZoom',         camHUD.zoom);
			luaModchart.setVar('cameraZoom',      FlxG.camera.zoom);
			luaModchart.setVar('cameraX',         camFollow.x);
			luaModchart.setVar('cameraY',         camFollow.y);
			luaModchart.setVar('health',          health);
			luaModchart.setVar('score',           songScore);
			luaModchart.setVar('misses',          misses);
			luaModchart.setVar('accuracy',        accuracy);
			luaModchart.setVar('isPaused',        paused);
			luaModchart.setVar('downscroll',      PlayStateChangeables.useDownscroll);
			luaModchart.executeState('update',    [elapsed]);
		}
	}
	#end

	private function _handleCamera():Void
	{
		if (currentSection == null) return;
		var offX = 0.0; var offY = 0.0;
		#if FEATURE_LUAMODCHART
		if (luaModchart != null) { offX = luaModchart.getVar("followXOffset", "float"); offY = luaModchart.getVar("followYOffset", "float"); }
		#end
		if (!currentSection.mustHitSection)
		{
			camFollow.setPosition(dad.getMidpoint().x + 150 + offX, dad.getMidpoint().y - 100 + offY);
			switch (dad.curCharacter)
			{
				case 'mom' | 'mom-car': camFollow.y = dad.getMidpoint().y;
				case 'senpai' | 'senpai-angry': camFollow.y = dad.getMidpoint().y - 430; camFollow.x = dad.getMidpoint().x - 100;
			}
			#if FEATURE_LUAMODCHART if (luaModchart != null) luaModchart.executeState('playerTwoTurn', []); #end
		}
		else
		{
			camFollow.setPosition(boyfriend.getMidpoint().x - 100 + offX, boyfriend.getMidpoint().y - 100 + offY);
			#if FEATURE_LUAMODCHART if (luaModchart != null) luaModchart.executeState('playerOneTurn', []); #end
			if (!PlayStateChangeables.Optimize)
				switch (Stage.curStage)
				{
					case 'limo': camFollow.x = boyfriend.getMidpoint().x - 300;
					case 'mall': camFollow.y = boyfriend.getMidpoint().y - 200;
					case 'school' | 'schoolEvil': camFollow.x = boyfriend.getMidpoint().x - 200; camFollow.y = boyfriend.getMidpoint().y - 200;
				}
		}
	}

	private inline function _tickCameraZoom():Void
	{
		var zoom = FlxMath.bound(FlxG.save.data.zoom, 0.8, 1.2);
		if (!executeModchart)
		{
			FlxG.camera.zoom = FlxMath.lerp(Stage.camZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom      = FlxMath.lerp(zoom, camHUD.zoom, 0.95);
		}
		else
		{
			FlxG.camera.zoom = FlxMath.lerp(Stage.camZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom      = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}
		camNotes.zoom = camSustains.zoom = camHUD.zoom;
	}

	private inline function _freshUpdate():Void
	{
		switch (curBeat)
		{
			case 16: camZooming = true; gfSpeed = 2;
			case 48 | 112: gfSpeed = 1;
			case 80: gfSpeed = 2;
		}
	}

	private inline function _updateIcons():Void
	{
		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.50)));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 0.50)));
		iconP1.updateHitbox(); iconP2.updateHitbox();
		var pct = FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0);
		iconP1.x = healthBarBG.x + healthBarBG.width * pct * 0.01 - iconP1.width / 2;
		iconP2.x = healthBarBG.x + healthBarBG.width * pct * 0.01 - iconP2.width / 2;
		iconP1.animation.curAnim.curFrame = healthBar.percent < 20 ? 1 : 0;
		iconP2.animation.curAnim.curFrame = healthBar.percent > 80 ? 1 : 0;
		if (health <= 0 && !cannotDie) { health = 0; healthBar.updateBar(); }
	}

	private inline function _updateSongPosition():Void
	{
		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				Conductor.rawPosition   = Conductor.songPosition;
				if (Conductor.songPosition >= 0) startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;
			Conductor.rawPosition   = FlxG.sound.music.time;
			songPositionBar         = (Conductor.songPosition - songLength) / 1000;
			currentSection          = getSectionByTime(Conductor.songPosition);
		}
	}

	private function _tickNotes():Void
	{
		if (songStarted && !endingSong
			&& unspawnNotes.length == 0 && notes.length == 0
			&& FlxG.sound.music.time / songMultiplier > songLength - 100)
		{
			endingSong = true;
			new FlxTimer().start(2, function(_) endSong());
		}

		notes.sort(FlxSort.byY, PlayStateChangeables.useDownscroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		var holdArray = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];

		notes.forEachAlive(function(daNote:Note)
		{
			// Position note
			var strumRef = daNote.mustPress
				? playerStrums.members[Math.floor(Math.abs(daNote.noteData))]
				: strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))];
			var speed = FlxMath.roundDecimal(PlayStateChangeables.scrollSpeed == 1 ? SONG.speed : PlayStateChangeables.scrollSpeed, 2);
			daNote.y = strumRef.y - 0.45 * ((Conductor.songPosition - daNote.strumTime) / songMultiplier) * speed + daNote.noteYOff;

			if (PlayStateChangeables.useDownscroll && daNote.isSustainNote)
			{
				daNote.y -= daNote.height - Note.swagWidth / 2;
				var clip = (PlayStateChangeables.botPlay || !daNote.mustPress || daNote.wasGoodHit || holdArray[Math.floor(Math.abs(daNote.noteData))]);
				if (clip && daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= strumLine.y + Note.swagWidth / 2)
				{
					var r = new FlxRect(0, 0, daNote.frameWidth * 2, daNote.frameHeight * 2);
					r.height = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y + Note.swagWidth / 2 - daNote.y) / daNote.scale.y;
					r.y = daNote.frameHeight - r.height;
					daNote.clipRect = r;
				}
			}
			else if (daNote.isSustainNote)
			{
				var clip = (PlayStateChangeables.botPlay || !daNote.mustPress || daNote.wasGoodHit || holdArray[Math.floor(Math.abs(daNote.noteData))]);
				if (clip && daNote.y + daNote.offset.y * daNote.scale.y <= strumLine.y + Note.swagWidth / 2)
				{
					var r = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
					r.y = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y + Note.swagWidth / 2 - daNote.y) / daNote.scale.y;
					r.height -= r.y;
					daNote.clipRect = r;
				}
			}

			// Hitbox window
			daNote.canBeHit = daNote.strumTime > Conductor.songPosition - (166 * Math.floor((PlayStateChangeables.safeFrames / 60) * 1000) / 166)
				&& daNote.strumTime < Conductor.songPosition + (166 * Math.ceil((PlayStateChangeables.safeFrames / 60) * 1000) / 166);

			// CPU hit opponent notes
			if (!daNote.mustPress && Conductor.songPosition >= daNote.strumTime)
			{
				if (SONG.songId != 'tutorial') camZooming = true;
				var altAnim = daNote.isAlt ? '-alt' : '';
				var singData = Std.int(Math.abs(daNote.noteData));
				if (!daNote.isParent && daNote.parent != null && daNote.spotInLine != daNote.parent.children.length - 1)
					dad.playAnim('sing' + dataSuffix[singData] + '-hold' + altAnim, true);
				else
					dad.playAnim('sing' + dataSuffix[singData] + altAnim, true);
				dad.holdTimer = 0;
				if (SONG.needsVoices) vocals.volume = 1;
				cpuStrums.forEach(function(s:StaticArrow) pressArrow(s, s.ID, daNote));
				if (!daNote.isSustainNote && !daNote.isParent) { daNote.kill(); notes.remove(daNote, true); daNote.destroy(); }
				else if (daNote.isParent) { daNote.active = false; daNote.visible = false; }
				#if FEATURE_LUAMODCHART if (luaModchart != null) luaModchart.executeState('playerTwoSing', [Math.abs(daNote.noteData), Conductor.songPosition]); #end
			}

			// Bot play hits player notes
			if (PlayStateChangeables.botPlay && daNote.mustPress && Conductor.songPosition >= daNote.strumTime)
				goodNoteHit(daNote);

			// Miss too-late notes
			if (daNote.tooLate || (daNote.wasGoodHit && !daNote.isSustainNote))
			{
				if (daNote.mustPress && !daNote.wasGoodHit && !daNote.tooLate) {}
				else if (daNote.mustPress && !PlayStateChangeables.botPlay && daNote.tooLate)
					noteMiss(daNote.noteData, daNote);
				daNote.active = daNote.visible = false;
				daNote.kill(); notes.remove(daNote, true);
			}

			// Sustain miss on hold drop
			if (!daNote.wasGoodHit && daNote.isSustainNote && daNote.sustainActive
				&& daNote.spotInLine != (daNote.parent?.children.length ?? 0)
				&& daNote.strumTime + (Conductor.stepCrochet * daNote.spotInLine) < Conductor.songPosition - Conductor.stepCrochet)
			{
				if (daNote.parent?.wasGoodHit == true) { misses++; totalNotesHit -= 1; }
				for (child in daNote.parent?.children ?? []) { child.alpha = 0.3; child.sustainActive = false; }
				updateAccuracy();
			}
		});
	}

	// ═════════════════════════════════════════════════════════════════════════
	// SONG START / END
	// ═════════════════════════════════════════════════════════════════════════

	public function startSong():Void
	{
		startingSong = false;
		songStarted  = true;
		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.music.play();
		vocals.play();

		if (allowedToHeadbang) gf.dance();
		if (idleToBeat && !boyfriend.animation.curAnim.name.startsWith("sing")) boyfriend.dance(forcedToIdle);
		if (idleToBeat && !dad.animation.curAnim.name.startsWith("sing")) dad.dance(forcedToIdle);

		switch (curSong)
		{
			case 'Bopeebo' | 'Philly Nice' | 'Blammed' | 'Cocoa' | 'Eggnog': allowedToCheer = true;
			default: allowedToCheer = false;
		}

		if (useVideo) GlobalVideo.get().resume();

		ScriptManager.call(ScriptCallbacks.ON_SONG_START, []);
		scripts.call(ScriptCallbacks.ON_SONG_START, []);
		#if FEATURE_LUAMODCHART if (executeModchart) luaModchart.executeState("songStart", [null]); #end

		#if FEATURE_DISCORD
		DiscordClient.changePresence(detailsText + " " + SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy),
			"\nAcc: " + HelperFunctions.truncateFloat(accuracy, 2) + "% | Score: " + songScore + " | Misses: " + misses, iconRPC);
		#end

		FlxG.sound.music.time = startTime;
		if (vocals != null) vocals.time = startTime;
		Conductor.songPosition = startTime;
		startTime = 0;

		#if cpp
		@:privateAccess
		{
			lime.media.openal.AL.sourcef(FlxG.sound.music._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, songMultiplier);
			if (vocals.playing)
				lime.media.openal.AL.sourcef(vocals._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, songMultiplier);
		}
		#end

		if (needSkip)
		{
			skipActive = true;
			skipText   = new FlxText(healthBarBG.x + 80, healthBarBG.y - 110, 500, "Press Space to Skip Intro", 30);
			skipText.color  = FlxColor.WHITE;
			skipText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2, 1);
			skipText.cameras = [camHUD];
			skipText.alpha   = 0;
			FlxTween.tween(skipText, {alpha: 1}, 0.2);
			add(skipText);
		}
	}

	public function endSong():Void
	{
		endingSong = true;
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, handleInput);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP,   releaseInput);
		ScriptManager.call(ScriptCallbacks.ON_SONG_END, []);
		scripts.call(ScriptCallbacks.ON_SONG_END, []);
		reactiveAudio.stop();
		ShaderManager.clearCamera(camGame);
		ShaderManager.clearCamera(camHUD);

		if (useVideo) { GlobalVideo.get().stop(); #if FEATURE_VIDEO if (videoHandler != null) remove(videoHandler.sprite); #end }
		if (!loadRep) rep.SaveReplay(saveNotes, saveJudge, replayAna);
		else { PlayStateChangeables.botPlay = false; PlayStateChangeables.scrollSpeed = 1 / songMultiplier; PlayStateChangeables.useDownscroll = false; }

		if (FlxG.save.data.fpsCap > 290) (cast(Lib.current.getChildAt(0), Main)).setFPSCap(290);
		#if FEATURE_LUAMODCHART if (luaModchart != null) { luaModchart.die(); luaModchart = null; } #end

		canPause                      = false;
		FlxG.sound.music.volume       = vocals.volume = 0;
		FlxG.sound.music.stop();
		vocals.stop();

		if (SONG.validScore)
		{
			#if !switch
			Highscore.saveScore(SONG.songId, Math.round(songScore), storyDifficulty);
			Highscore.saveCombo(SONG.songId, Ratings.GenerateLetterRank(accuracy), storyDifficulty);
			#end
		}

		if (offsetTesting)   { _endOffsetTest(); return; }
		if (stageTesting)    { _endStageTesting(); return; }
		if (isStoryMode)     _endStoryMode();
		else                 _endFreeplay();
	}

	private inline function _endOffsetTest():Void
	{
		FlxG.sound.playMusic(Paths.music('freakyMenu'));
		offsetTesting = false;
		LoadingState.loadAndSwitchState(new OptionsMenu());
		clean();
		FlxG.save.data.offset = offsetTest;
	}

	private function _endStageTesting():Void
	{
		new FlxTimer().start(0.3, function(_)
		{
			for (bg in Stage.toAdd) remove(bg);
			for (arr in Stage.layInFront) for (bg in arr) remove(bg);
			remove(boyfriend); remove(dad); remove(gf);
		});
		FlxG.switchState(new StageDebugState(Stage.curStage));
	}

	private function _endStoryMode():Void
	{
		campaignScore  += Math.round(songScore);
		campaignMisses += misses;
		campaignSicks  += sicks; campaignGoods += goods; campaignBads += bads; campaignShits += shits;
		storyPlaylist.remove(storyPlaylist[0]);

		if (storyPlaylist.length <= 0)
		{
			transIn = transOut = null;
			paused  = true;
			FlxG.sound.music.stop(); vocals.stop();
			if (FlxG.save.data.scoreScreen) { openSubState(new ResultsScreen()); new FlxTimer().start(1, function(_) inResults = true); }
			else { _resetFreeplayMeta(); FlxG.sound.playMusic(Paths.music('freakyMenu')); Conductor.changeBPM(102); FlxG.switchState(new StoryMenuState()); clean(); }
			#if FEATURE_LUAMODCHART if (luaModchart != null) { luaModchart.die(); luaModchart = null; } #end
			if (SONG.validScore) Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);
			StoryMenuState.unlockNextWeek(storyWeek);
		}
		else
		{
			var diff = ["-easy","","-hard"][storyDifficulty];
			if (StringTools.replace(storyPlaylist[0], " ", "-").toLowerCase() == 'eggnog')
			{
				var b = new FlxSprite(-FlxG.width * FlxG.camera.zoom, -FlxG.height * FlxG.camera.zoom)
					.makeGraphic(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.BLACK);
				b.scrollFactor.set(); add(b); camHUD.visible = false;
				FlxG.sound.play(Paths.sound('Lights_Shut_off'));
			}
			FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
			prevCamFollow = camFollow;
			PlayState.SONG = Song.loadFromJson(storyPlaylist[0], diff);
			FlxG.sound.music.stop();
			LoadingState.loadAndSwitchState(new PlayState());
			clean();
		}
	}

	private function _endFreeplay():Void
	{
		paused = true;
		FlxG.sound.music.stop(); vocals.stop();
		if (FlxG.save.data.scoreScreen) { openSubState(new ResultsScreen()); new FlxTimer().start(1, function(_) inResults = true); }
		else { FlxG.switchState(new FreeplayState()); clean(); }
	}

	private inline function _resetFreeplayMeta():Void
	{
		GameplayCustomizeState.freeplayBf = GameplayCustomizeState.freeplayDad = GameplayCustomizeState.freeplayGf = '';
		GameplayCustomizeState.freeplayNoteStyle = 'normal'; GameplayCustomizeState.freeplayStage = 'stage';
		GameplayCustomizeState.freeplaySong = 'bopeebo'; GameplayCustomizeState.freeplayWeek = 1;
	}

	function clean():Void
	{
		ScriptManager.clearAll();
		#if FEATURE_LUAMODCHART if (luaModchart != null) { luaModchart.die(); luaModchart = null; } #end
	}

	// ═════════════════════════════════════════════════════════════════════════
	// NOTE HIT / MISS / ACCURACY
	// ═════════════════════════════════════════════════════════════════════════

	public function goodNoteHit(note:Note, resetMashViolation:Bool = true):Void
	{
		if (mashing != 0) mashing = 0;

		var noteDiff = -(note.strumTime - Conductor.songPosition);
		if (loadRep) { noteDiff = findByTime(note.strumTime)[3]; note.rating = rep.replay.songJudgements[findByTimeIndex(note.strumTime)]; }
		else note.rating = Ratings.judgeNote(noteDiff);

		if (note.rating == "miss") return;

		adaptiveAI.reportPlayerHit(note);
		ScriptManager.call(ScriptCallbacks.ON_NOTE_HIT, [note]);
		scripts.call(ScriptCallbacks.ON_NOTE_HIT, [note]);

		if (!note.isSustainNote) notesHitArray.unshift(Date.now());
		if (!resetMashViolation && mashViolations >= 1) mashViolations--;
		if (mashViolations < 0) mashViolations = 0;
		if (note.wasGoodHit) return;

		if (!note.isSustainNote) { combo++; popUpScore(note); }

		boyfriend.playAnim('sing' + dataSuffix[note.noteData] + (note.isAlt ? '-alt' : ''), true);

		#if FEATURE_LUAMODCHART if (luaModchart != null) luaModchart.executeState('playerOneSing', [note.noteData, Conductor.songPosition]); #end

		if (!loadRep && note.mustPress)
		{
			var arr = [note.strumTime, note.sustainLength, note.noteData, noteDiff];
			if (note.isSustainNote) arr[1] = -1;
			saveNotes.push(arr); saveJudge.push(note.rating);
		}

		if (!PlayStateChangeables.botPlay || FlxG.save.data.cpuStrums)
			playerStrums.forEach(function(spr:StaticArrow) pressArrow(spr, spr.ID, note));

		if (!note.isSustainNote) { note.kill(); notes.remove(note, true); note.destroy(); }
		else note.wasGoodHit = true;

		if (!note.isSustainNote) updateAccuracy();
	}

	public function noteMiss(direction:Int = 1, daNote:Note):Void
	{
		if (boyfriend.stunned) return;
		adaptiveAI.reportPlayerMiss(daNote);
		ScriptManager.call(ScriptCallbacks.ON_NOTE_MISS, [daNote]);
		scripts.call(ScriptCallbacks.ON_NOTE_MISS, [daNote]);

		if (combo > 5 && gf.animOffsets.exists('sad')) gf.playAnim('sad');
		if (combo != 0) { combo = 0; popUpScore(null); }
		misses++;

		var safeMiss = -(166 * Math.floor((rep.replay.sf / 60) * 1000) / 166);
		if (!loadRep)
		{
			saveNotes.push(daNote != null ? [daNote.strumTime, 0, direction, safeMiss] : [Conductor.songPosition, 0, direction, safeMiss]);
			saveJudge.push("miss");
		}

		totalNotesHit -= 1;
		if (daNote != null && !daNote.isSustainNote) songScore -= 10;
		else if (daNote == null) songScore -= 10;

		if (FlxG.save.data.missSounds)
			FlxG.sound.play(Paths.soundRandom('missnote' + altSuffix, 1, 3), FlxG.random.float(0.1, 0.2));

		boyfriend.playAnim('sing' + dataSuffix[direction] + 'miss', true);
		#if FEATURE_LUAMODCHART if (luaModchart != null) luaModchart.executeState('playerOneMiss', [direction, Conductor.songPosition]); #end
		updateAccuracy();
	}

	public function updateAccuracy():Void
	{
		totalPlayed++;
		accuracy        = Math.max(0, totalNotesHit / totalPlayed * 100);
		accuracyDefault = Math.max(0, totalNotesHitDefault / totalPlayed * 100);
		scoreTxt.text   = Ratings.CalculateRanking(songScore, songScoreDef, nps, maxNPS, accuracy);
		judgementCounter.text = 'Sicks: ${sicks}\nGoods: ${goods}\nBads: ${bads}\nShits: ${shits}\nMisses: $misses';
	}

	// ═════════════════════════════════════════════════════════════════════════
	// POP-UP SCORE
	// ═════════════════════════════════════════════════════════════════════════

	private function popUpScore(daNote:Note):Void
	{
		var noteDiff = daNote != null ? -(daNote.strumTime - Conductor.songPosition) : 0.0;
		var rating   = Ratings.judgeNote(noteDiff);
		var score    = 0;
		var pixelSfx = SONG.noteStyle == 'pixel';

		while (notesHitArray.length > 0 && notesHitArray[0].getTime() + 1000 < Date.now().getTime())
			notesHitArray.pop();

		switch (rating)
		{
			case 'sick':  score = 350; sicks++;  totalNotesHit += 1.00;
			case 'good':  score = 200; goods++;  totalNotesHit += 0.75;
			case 'bad':   score = 50;  bads++;   totalNotesHit += 0.50; fc = false;
			case 'shit':  score = 20;  shits++;  totalNotesHit += 0.25; fc = ss = false;
		}
		songScore += score; songScoreDef += score;
		nps = notesHitArray.length;
		if (nps > maxNPS) maxNPS = nps;
		vocals.volume = 1;

		var sfx = pixelSfx ? '-pixel' : '';
		var lib = pixelSfx ? 'shared' : null;

		var r = new FlxSprite().loadGraphic(Paths.loadImage('sm4/$rating$sfx', lib));
		r.cameras = [camHUD]; r.screenCenter();
		r.x = r.x * 0.507 + (combo < 10 ? 50 : -40); r.y -= 60;
		r.acceleration.y = 550; r.velocity.y = -FlxG.random.int(140, 175); r.velocity.x = -FlxG.random.int(0, 10);
		if (pixelSfx) { r.setGraphicSize(Std.int(r.width * CoolUtil.daPixelZoom)); r.updateHitbox(); }
		r.scrollFactor.set(); add(r); r.cameras = [camHUD];
		FlxTween.tween(r, {alpha: 0}, 0.2, {startDelay: Conductor.crochet * 0.001, onComplete: function(_) r.destroy()});

		var c = new FlxSprite().loadGraphic(Paths.loadImage('sm4/combo$sfx', lib));
		c.cameras = [camHUD]; c.screenCenter(); c.x = r.x; c.y = r.y + 100;
		c.acceleration.y = 600; c.velocity.y = -150; c.velocity.x = FlxG.random.int(1, 10);
		if (pixelSfx) { c.setGraphicSize(Std.int(c.width * CoolUtil.daPixelZoom)); c.updateHitbox(); }
		c.scrollFactor.set(); add(c); c.cameras = [camHUD];
		FlxTween.tween(c, {alpha: 0}, 0.2, {startDelay: Conductor.crochet * 0.001, onComplete: function(_) c.destroy()});

		var comboStr = Std.string(combo);
		for (i in 0...comboStr.length)
		{
			var n = new FlxSprite().loadGraphic(Paths.loadImage('sm4/num${comboStr.charAt(i)}$sfx', lib));
			n.cameras = [camHUD]; n.screenCenter(); n.x = r.x + (43 * i); n.y = r.y + 100;
			n.acceleration.y = FlxG.random.int(200, 300); n.velocity.y = -FlxG.random.int(140, 160); n.velocity.x = FlxG.random.float(-5, 5);
			if (pixelSfx) { n.setGraphicSize(Std.int(n.width * CoolUtil.daPixelZoom)); n.updateHitbox(); }
			n.scrollFactor.set(); add(n); n.cameras = [camHUD];
			FlxTween.tween(n, {alpha: 0}, 0.2, {startDelay: Conductor.crochet * 0.002, onComplete: function(_) n.destroy()});
		}
	}

	// ═════════════════════════════════════════════════════════════════════════
	// INPUT
	// ═════════════════════════════════════════════════════════════════════════

	private function handleInput(evt:KeyboardEvent):Void
	{
		ScriptManager.call(ScriptCallbacks.ON_KEY_DOWN, [evt.keyCode]);
		var key = getKey(evt.keyCode);
		if (key < 0) return;
		noteBools[key] = true;
		if (!startedCountdown || paused || inCutscene || boyfriend.stunned || !generatedMusic || endingSong) return;

		var last = Conductor.songPosition;
		Conductor.songPosition = FlxG.sound.music.time;

		var sortedNotes = notes.members.filter(function(n:Note)
			return n != null && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.isSustainNote && n.noteData == key);
		sortedNotes.sort(function(a, b) return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime));

		if (sortedNotes.length > 0)
		{
			var fNote = sortedNotes[0];
			if (sortedNotes.length > 1 && Math.abs(sortedNotes[1].strumTime - fNote.strumTime) < 1.0)
				{ fNote.kill(); notes.remove(fNote, true); fNote.destroy(); fNote = sortedNotes[1]; }
			goodNoteHit(fNote);
		}
		else if (!FlxG.save.data.ghostTapping) noteMiss(key, null);

		Conductor.songPosition = last;
		var spr = playerStrums.members[key];
		if (spr != null && spr.animation.curAnim.name != 'confirm') { spr.playAnim('pressed'); spr.resetAnim = 0; }
		#if FEATURE_LUAMODCHART if (luaModchart != null) luaModchart.executeState('keyPressed', [['left','down','up','right'][key]]); #end
	}

	private function releaseInput(evt:KeyboardEvent):Void
	{
		ScriptManager.call(ScriptCallbacks.ON_KEY_UP, [evt.keyCode]);
		var key = getKey(evt.keyCode);
		if (key < 0) return;
		noteBools[key] = false;
		var spr = playerStrums.members[key];
		if (spr != null) { spr.playAnim('static'); spr.resetAnim = 0; }
		#if FEATURE_LUAMODCHART if (luaModchart != null) luaModchart.executeState('keyReleased', [['left','down','up','right'][key]]); #end
	}

	private function getKey(keyCode:Int):Int
	{
		var binds = [FlxG.save.data.leftBind, FlxG.save.data.downBind, FlxG.save.data.upBind, FlxG.save.data.rightBind];
		@:privateAccess var key = FlxKey.toStringMap.get(keyCode) ?? '';
		for (i in 0...binds.length)
		{
			if (binds[i].toLowerCase() == key.toLowerCase()) return i;
		}
		switch (keyCode) { case 37: return 0; case 40: return 1; case 38: return 2; case 39: return 3; }
		return -1;
	}

	private function keyShit():Void
	{
		var hold    = [controls.LEFT,   controls.DOWN,   controls.UP,   controls.RIGHT];
		var pressed = [controls.LEFT_P, controls.DOWN_P, controls.UP_P, controls.RIGHT_P];
		var release = [controls.LEFT_R, controls.DOWN_R, controls.UP_R, controls.RIGHT_R];

		#if FEATURE_LUAMODCHART
		if (luaModchart != null)
		{
			var names = ['left','down','up','right'];
			for (i in 0...pressed.length)  if (pressed[i])  luaModchart.executeState('keyPressed',  [names[i]]);
			for (i in 0...release.length)  if (release[i])  luaModchart.executeState('keyReleased', [names[i]]);
		}
		#end

		if (PlayStateChangeables.botPlay)
			hold = pressed = release = [false,false,false,false];

		var anas:Array<Ana> = [null,null,null,null];
		for (i in 0...pressed.length) if (pressed[i]) anas[i] = new Ana(Conductor.songPosition, null, false, "miss", i);

		// Hold sustains
		if (hold.contains(true) && generatedMusic)
			notes.forEachAlive(function(n:Note)
			{
				if (n.isSustainNote && n.canBeHit && n.mustPress && hold[n.noteData] && n.sustainActive)
					goodNoteHit(n);
			});

		// Presses — check for note hits
		if ((KeyBinds.gamepad && !FlxG.keys.justPressed.ANY)) return;

		if (pressed.contains(true) && generatedMusic)
		{
			boyfriend.holdTimer = 0;
			var possible:Array<Note>     = [];
			var dirList:Array<Int>       = [];
			var dumbNotes:Array<Note>    = [];
			var accounted:Array<Bool>    = [false,false,false,false];

			notes.forEachAlive(function(n:Note)
			{
				if (n.canBeHit && n.mustPress && !n.wasGoodHit && !accounted[n.noteData])
				{
					if (dirList.contains(n.noteData))
					{
						accounted[n.noteData] = true;
						for (other in possible)
							if (other.noteData == n.noteData && Math.abs(n.strumTime - other.strumTime) < 10)
								dumbNotes.push(n);
						possible.push(n);
					}
					else
					{
						possible.push(n);
						dirList.push(n.noteData);
					}
				}
			});

			for (n in dumbNotes) { n.kill(); notes.remove(n, true); n.destroy(); }

			for (i in 0...pressed.length)
			{
				if (!pressed[i]) continue;
				var note:Note = null;
				for (n in possible) if (n.noteData == i) { note = n; break; }
				if (note != null)
				{
					goodNoteHit(note);
					if (anas[i] != null) anas[i].hit = true;
					repPresses++;
				}
				else if (!FlxG.save.data.ghostTapping)
				{
					noteMiss(i, null);
					if (anas[i] != null) replayAna.anaArray.push(anas[i]);
					repPresses++;
				}
			}
		}

		for (i in 0...release.length)
		{
			if (!release[i]) continue;
			noteBools[i] = false;
			var spr = playerStrums.members[i];
			if (spr != null && spr.animation.curAnim.name != 'static') { spr.playAnim('static'); spr.resetAnim = 0; }
		}
	}

	// ═════════════════════════════════════════════════════════════════════════
	// COUNTDOWN
	// ═════════════════════════════════════════════════════════════════════════

	function startCountdown():Void
	{
		inCutscene = false;
		appearStaticArrows();
		talking = false;
		startedCountdown = true;
		Conductor.songPosition = -(Conductor.crochet * 5);
		if (FlxG.sound.music.playing) FlxG.sound.music.stop();
		if (vocals != null) vocals.stop();

		var isPixel = SONG.noteStyle == 'pixel';
		var images  = isPixel ? ['weeb/pixelUI/ready-pixel','weeb/pixelUI/set-pixel','weeb/pixelUI/date-pixel'] : ['ready','set','go'];
		var pixLib  = isPixel ? 'week6' : null;
		altSuffix   = isPixel ? '-pixel' : '';

		var counter = 0;
		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			if (allowedToHeadbang && counter % gfSpeed == 0) gf.dance();
			if (counter % idleBeat == 0)
			{
				if (idleToBeat && !boyfriend.animation.curAnim.name.endsWith("miss")) boyfriend.dance(forcedToIdle);
				if (idleToBeat) dad.dance(forcedToIdle);
			}
			else if (dad.curCharacter == 'spooky' || dad.curCharacter == 'gf') dad.dance();

			switch (counter)
			{
				case 0: FlxG.sound.play(Paths.sound('intro3$altSuffix'), 0.6);
				case 1: _showCountdownSprite(images[0], pixLib, isPixel); FlxG.sound.play(Paths.sound('intro2$altSuffix'), 0.6);
				case 2: _showCountdownSprite(images[1], pixLib, isPixel); FlxG.sound.play(Paths.sound('intro1$altSuffix'), 0.6);
				case 3: _showCountdownSprite(images[2], pixLib, isPixel); FlxG.sound.play(Paths.sound('introGo$altSuffix'), 0.6);
			}
			counter++;
		}, 4);
	}

	private function _showCountdownSprite(image:String, ?lib:String, isPixel:Bool):Void
	{
		var spr = new FlxSprite().loadGraphic(Paths.loadImage(image, lib));
		spr.scrollFactor.set(); spr.updateHitbox();
		if (isPixel) spr.setGraphicSize(Std.int(spr.width * CoolUtil.daPixelZoom));
		spr.screenCenter(); add(spr);
		FlxTween.tween(spr, {y: spr.y + 100, alpha: 0}, Conductor.crochet / 1000,
			{ease: FlxEase.cubeInOut, onComplete: function(_) spr.destroy()});
	}

	function schoolIntro(?dialogueBox:ui.DialogueBox):Void
	{
		var black = new FlxSprite(-100, -100).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
		black.scrollFactor.set(); add(black);

		if (dialogueBox != null)
		{
			inCutscene = true;
			if (curSong.toLowerCase() == 'thorns') dialogueBox.isEnigma = true;
			add(dialogueBox); dialogueBox.cameras = [camHUD];
			dialogueBox.finish = function()
			{
				inCutscene = false;
				remove(dialogueBox);
				FlxG.sound.play(Paths.sound('dialogueEnd'));
				startCountdown();
			};
		}
		else startCountdown();
	}

	// ═════════════════════════════════════════════════════════════════════════
	// BEAT / STEP / SECTION
	// ═════════════════════════════════════════════════════════════════════════

	override function stepHit()
	{
		super.stepHit();
		ScriptManager.call(ScriptCallbacks.ON_STEP_HIT, [curStep]);
		scripts.call(ScriptCallbacks.ON_STEP_HIT, [curStep]);
		if (SONG.needsVoices) resyncVocals();
	}

	override function beatHit()
	{
		super.beatHit();
		ScriptManager.call(ScriptCallbacks.ON_BEAT_HIT, [curBeat]);
		camCinematic.onBeat(curBeat);

		if (generatedMusic)
			notes.sort(FlxSort.byY, PlayStateChangeables.useDownscroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		#if FEATURE_LUAMODCHART if (executeModchart && luaModchart != null) luaModchart.executeState('beatHit', [curBeat]); #end

		if (currentSection != null)
		{
			if (curBeat % idleBeat == 0)
			{
				if (idleToBeat && !dad.animation.curAnim.name.startsWith('sing'))
					dad.dance(forcedToIdle, currentSection.CPUAltAnim);
				if (idleToBeat && !boyfriend.animation.curAnim.name.startsWith('sing'))
					boyfriend.dance(forcedToIdle, currentSection.playerAltAnim);
			}
			else if ((dad.curCharacter == 'spooky' || dad.curCharacter == 'gf') && !dad.animation.curAnim.name.startsWith('sing'))
				dad.dance(forcedToIdle, currentSection.CPUAltAnim);
		}

		wiggleShit.update(Conductor.crochet);

		if (FlxG.save.data.camzoom && songMultiplier == 1)
		{
			if (SONG.songId == 'milf' && curBeat >= 168 && curBeat < 200 && camZooming && FlxG.camera.zoom < 1.35)
			{
				FlxG.camera.zoom += 0.015 / songMultiplier;
				camHUD.zoom      += 0.03  / songMultiplier;
			}
			if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
			{
				FlxG.camera.zoom += 0.015 / songMultiplier;
				camHUD.zoom      += 0.03  / songMultiplier;
			}
		}

		var iconBump = songMultiplier == 1 ? 30 : 4;
		iconP1.setGraphicSize(Std.int(iconP1.width + iconBump)); iconP1.updateHitbox();
		iconP2.setGraphicSize(Std.int(iconP2.width + iconBump)); iconP2.updateHitbox();

		if (!endingSong && currentSection != null)
		{
			if (allowedToHeadbang) gf.dance();
			if (curBeat % 8 == 7 && curSong == 'Bopeebo') boyfriend.playAnim('hey', true);
			if (curBeat % 16 == 15 && SONG.songId == 'tutorial' && dad.curCharacter == 'gf' && curBeat > 16 && curBeat < 48)
			{
				if (vocals.volume != 0) { boyfriend.playAnim('hey', true); dad.playAnim('cheer', true); }
				else { dad.playAnim('sad', true); FlxG.sound.play(Paths.soundRandom('GF_', 1, 4, 'shared'), 0.3); }
			}
			if (PlayStateChangeables.Optimize && vocals.volume == 0 && !currentSection.mustHitSection)
				vocals.volume = 1;
		}

		scripts.call(ScriptCallbacks.ON_BEAT_HIT, [curBeat]);
	}

	// ═════════════════════════════════════════════════════════════════════════
	// SONG GENERATION
	// ═════════════════════════════════════════════════════════════════════════

	public function generateSong(dataPath:String):Void
	{
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);
		curSong = songData.songId;

		#if FEATURE_STEPMANIA
		vocals = SONG.needsVoices && !isSM ? new FlxSound().loadEmbedded(Paths.voices(SONG.songId)) : new FlxSound();
		#else
		vocals = SONG.needsVoices ? new FlxSound().loadEmbedded(Paths.voices(SONG.songId)) : new FlxSound();
		#end
		FlxG.sound.list.add(vocals);

		if (!paused)
		{
			#if FEATURE_STEPMANIA
			if (!isStoryMode && isSM)
			{
				var bytes = File.getBytes(pathToSm + "/" + sm.header.MUSIC);
				var snd   = new openfl.media.Sound();
				snd.loadCompressedDataFromByteArray(bytes.getData(), bytes.length);
				FlxG.sound.playMusic(snd);
			}
			else FlxG.sound.playMusic(Paths.inst(SONG.songId), 1, false);
			#else
			FlxG.sound.playMusic(Paths.inst(SONG.songId), 1, false);
			#end
		}
		FlxG.sound.music.pause();
		if (SONG.needsVoices && !isSM) FlxG.sound.cache(Paths.voices(SONG.songId));
		if (!isSM) FlxG.sound.cache(Paths.inst(SONG.songId));

		songLength = (FlxG.sound.music.length / songMultiplier) / 1000;
		Conductor.crochet     = (60 / SONG.bpm) * 1000;
		Conductor.stepCrochet = Conductor.crochet / 4;

		if (FlxG.save.data.songPosition)
		{
			songPosBG = new FlxSprite(0, PlayStateChangeables.useDownscroll ? FlxG.height * 0.9 + 35 : 10).loadGraphic(Paths.loadImage('healthBar'));
			songPosBG.screenCenter(X); songPosBG.scrollFactor.set();
			songPosBar = new FlxBar(640 - Std.int((songPosBG.width - 100) / 2), songPosBG.y + 4, LEFT_TO_RIGHT,
				Std.int(songPosBG.width - 100), Std.int(songPosBG.height + 6), this, 'songPositionBar', 0, songLength);
			songPosBar.scrollFactor.set();
			songPosBar.createFilledBar(FlxColor.BLACK, FlxColor.fromRGB(0, 255, 128));
			add(songPosBar);
			bar = new FlxSprite(songPosBar.x, songPosBar.y).makeGraphic(Std.int(songPosBar.width), Std.int(songPosBar.height), FlxColor.TRANSPARENT);
			add(bar);
			flixel.util.FlxSpriteUtil.drawRect(bar, 0, 0, songPosBar.width, songPosBar.height, FlxColor.TRANSPARENT, {thickness: 4, color: FlxColor.BLACK});
			songPosBG.width = songPosBar.width;
			songName = new FlxText(songPosBG.x + songPosBG.width / 2 - SONG.songName.length * 5, songPosBG.y - 15, 0, SONG.songName + ' (' + FlxStringUtil.formatTime(songLength, false) + ')', 16);
			songName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			songName.scrollFactor.set(); songName.y = songPosBG.y + songPosBG.height / 3;
			add(songName); songName.screenCenter(X);
			for (s in [songPosBG, bar, songPosBar, songName]) s.cameras = [camHUD];
		}

		notes = new FlxTypedGroup<Note>();
		add(notes);

		for (section in songData.notes)
		{
			if (section == null) continue;
			for (songNotes in section.sectionNotes)
			{
				var strumTime = songNotes[0] / songMultiplier;
				if (strumTime < 0) strumTime = 0;
				var noteData    = Std.int(songNotes[1] % 4);
				var mustHit     = songNotes[1] > 3 ? !section.mustHitSection : section.mustHitSection;

				if (!mustHit && PlayStateChangeables.Optimize) continue;

				if (PlayStateChangeables.mirrorMode) noteData = 3 - noteData;

				var oldNote:Note = unspawnNotes.length > 0 ? unspawnNotes[unspawnNotes.length - 1] : null;
				var swagNote     = new Note(strumTime, noteData, oldNote, false, false, false, songNotes[4]);
				swagNote.sustainLength = TimingStruct.getTimeFromBeat(TimingStruct.getBeatFromTime(songNotes[2] / songMultiplier));
				swagNote.scrollFactor.set(0, 0);
				swagNote.isAlt = songNotes[3] || ((section.altAnim || section.CPUAltAnim) && !mustHit) || (section.playerAltAnim && mustHit);
				swagNote.mustPress = mustHit;
				if (swagNote.sustainLength > 0) swagNote.isParent = true;
				unspawnNotes.push(swagNote);

				var susLen = swagNote.sustainLength / Conductor.stepCrochet;
				var type   = 0;
				for (susIdx in 0...Math.floor(susLen))
				{
					oldNote = unspawnNotes[unspawnNotes.length - 1];
					var sus = new Note(strumTime + (Conductor.stepCrochet * susIdx) + Conductor.stepCrochet, noteData, oldNote, true);
					sus.scrollFactor.set(); sus.mustPress = mustHit;
					sus.isAlt = swagNote.isAlt;
					if (sus.mustPress) sus.x += FlxG.width / 2;
					sus.parent = swagNote; swagNote.children.push(sus); sus.spotInLine = type++;
					unspawnNotes.push(sus);
				}

				if (swagNote.mustPress) swagNote.x += FlxG.width / 2;
			}
		}

		unspawnNotes.sort(sortByShit);
		generatedMusic = true;
	}

	public function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			var xPos  = player == 1 ? FlxG.width / 2 + 50.0 : 50.0;
			var yPos  = PlayStateChangeables.useDownscroll ? FlxG.height - 150.0 : 50.0;
			var arrow = new StaticArrow(xPos + 114.25 * i, yPos);
			arrow.frames = noteskinSprite;
			arrow.loadColorAnimation(['purple','blue','green','red'][i], false);
			arrow.scrollFactor.set(); arrow.ID = i;

			if (isStoryMode && !PlayStateChangeables.botPlay)
			{
				arrow.alpha = 0;
				FlxTween.tween(arrow, {alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + 0.2 * i});
			}

			if (player == 1) playerStrums.add(arrow);
			else             cpuStrums.add(arrow);
			strumLineNotes.add(arrow);
		}
	}

	public function appearStaticArrows():Void
	{
		strumLineNotes.forEach(function(s:StaticArrow) s.visible = true);
	}

	// ═════════════════════════════════════════════════════════════════════════
	// MISC HELPERS
	// ═════════════════════════════════════════════════════════════════════════

	public function resyncVocals():Void
	{
		if (Math.abs(FlxG.sound.music.time - Conductor.songPosition) > 20)
		{
			vocals.pause();
			FlxG.sound.music.play();
			Conductor.songPosition = FlxG.sound.music.time;
			if (Conductor.songPosition <= vocals.length) vocals.time = Conductor.songPosition;
			vocals.play();
		}
	}

	public function pressArrow(spr:StaticArrow, id:Int, note:Note):Void
	{
		if (!spr.animation.curAnim.name.startsWith('confirm') && note != null)
			spr.playAnim('confirm', true);
	}

	public function getSectionByTime(ms:Float):SwagSection
	{
		for (sec in SONG.notes)
			if (sec != null && ms >= sec.startTime && ms < sec.endTime)
				return sec;
		return null;
	}

	public function recalculateAllSectionTimes():Void
	{
		for (i in 0...SONG.notes.length)
		{
			var sec   = SONG.notes[i];
			if (sec == null) continue;
			var time  = TimingStruct.getTimeFromBeat(i * 4);
			sec.startTime = time;
			sec.endTime   = TimingStruct.getTimeFromBeat((i + 1) * 4);
		}
	}

	public function triggerEventNote():Void
	{
		if (currentSection?.sectionEvents == null) return;
		for (ev in currentSection.sectionEvents)
			EventSystem.fire(ev.name, ev.value, ev.value2);
	}

	public function addTextToDebug(text:String, color:FlxColor):Void
		Debug.addText(text, color);

	public static function NearlyEquals(a:Float, b:Float, margin:Float = 10):Bool
		return Math.abs(a - b) < margin;

	public function findByTime(time:Float):Array<Dynamic>
	{
		for (n in rep.replay.songNotes) if (n[0] == time) return n;
		return null;
	}

	public function findByTimeIndex(time:Float):Int
	{
		for (i in 0...rep.replay.songNotes.length) if (rep.replay.songNotes[i][0] == time) return i;
		return -1;
	}

	public static function sortByShit(a:Note, b:Note):Int
		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);

	// ═════════════════════════════════════════════════════════════════════════
	// SUBSTATE
	// ═════════════════════════════════════════════════════════════════════════

	override function openSubState(subState:FlxSubState):Void
	{
		if (paused) { FlxG.sound.music?.pause(); vocals.pause(); }
		super.openSubState(subState);
	}

	override function closeSubState():Void
	{
		super.closeSubState();
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong) resyncVocals();
			paused = false;
			ScriptManager.call(ScriptCallbacks.ON_RESUME, []);
			#if FEATURE_DISCORD DiscordClient.changePresence(detailsText, SONG.songName + ' ($storyDifficultyText)', iconRPC); #end
		}
	}

	// ═════════════════════════════════════════════════════════════════════════
	// DESTROY
	// ═════════════════════════════════════════════════════════════════════════

	override public function destroy():Void
	{
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, handleInput);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP,   releaseInput);
		ScriptManager.call(ScriptCallbacks.ON_DESTROY, []);
		scripts.call(ScriptCallbacks.ON_DESTROY, []);
		reactiveAudio?.destroy();
		#if FEATURE_LUAMODCHART if (luaModchart != null) { luaModchart.die(); luaModchart = null; } #end
		instance = null;
		super.destroy();
	}
}
