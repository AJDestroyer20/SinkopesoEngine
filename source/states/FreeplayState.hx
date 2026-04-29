package states;

import backend.MusicBeatState;
import core.structures.Song;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];
	
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;
	
	var scoreText:FlxText;
	var diffText:FlxText;
	var grpSongs:FlxTypedGroup<FlxText>;
	
	var bg:FlxSprite;
	
	override function create()
	{
		super.create();
		
		loadSongList();
		
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = Preferences.data.antialiasing;
		add(bg);
		
		grpSongs = new FlxTypedGroup<FlxText>();
		add(grpSongs);
		
		for (i in 0...songs.length)
		{
			var songText:FlxText = new FlxText(0, (70 * i) + 30, 0, songs[i].songName, 32);
			songText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT);
			songText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
			songText.ID = i;
			grpSongs.add(songText);
		}
		
		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		scoreText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(scoreText);
		
		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, CENTER);
		diffText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(diffText);
		
		changeSelection();
		changeDiff();
	}
	
	function loadSongList():Void
	{
		songs = [
			new SongMetadata('Tutorial', 'gf', 0),
			new SongMetadata('Bopeebo', 'dad', 1),
			new SongMetadata('Fresh', 'dad', 1),
			new SongMetadata('Dadbattle', 'dad', 1),
			new SongMetadata('Spookeez', 'spooky', 2),
			new SongMetadata('South', 'spooky', 2),
			new SongMetadata('Monster', 'monster', 2),
			new SongMetadata('Pico', 'pico', 3),
			new SongMetadata('Philly', 'pico', 3),
			new SongMetadata('Blammed', 'pico', 3),
		];
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (controls.UP_P)
			changeSelection(-1);
		if (controls.DOWN_P)
			changeSelection(1);
		
		if (controls.LEFT_P)
			changeDiff(-1);
		if (controls.RIGHT_P)
			changeDiff(1);
		
		if (controls.BACK)
		{
			FlxG.switchState(new MenuState());
		}
		
		if (controls.ACCEPT)
		{
			var songLowercase:String = songs[curSelected].songName.toLowerCase();
			
			PlayState.SONG = SongLoader.loadFromJson(songLowercase, curDifficulty);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;
			
			FlxG.switchState(new PlayState());
		}
	}
	
	function changeSelection(change:Int = 0):Void
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		
		curSelected += change;
		
		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;
		
		var bullShit:Int = 0;
		
		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;
			
			item.alpha = 0.6;
			
			if (item.ID == curSelected)
			{
				item.alpha = 1;
			}
		}
		
		var color:FlxColor = songs[curSelected].color;
		if (color != null)
			bg.color = color;
	}
	
	function changeDiff(change:Int = 0):Void
	{
		curDifficulty += change;
		
		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;
		
		diffText.text = '< ' + CoolUtil.difficulties[curDifficulty].toUpperCase() + ' >';
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var icon:String = "";
	public var week:Int = 0;
	public var color:FlxColor = FlxColor.WHITE;
	
	public function new(song:String, icon:String, week:Int)
	{
		this.songName = song;
		this.icon = icon;
		this.week = week;
	}
}
