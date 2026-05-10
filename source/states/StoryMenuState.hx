package states;

import backend.MusicBeatState;

class StoryMenuState extends MusicBeatState
{
	var curWeek:Int = 0;
	var curDifficulty:Int = 1;
	
	var weekNames:Array<String> = ['Tutorial', 'Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5', 'Week 6'];
	var weekData:Array<Array<String>> = [
		['Tutorial'],
		['Bopeebo', 'Fresh', 'Dadbattle'],
		['Spookeez', 'South', 'Monster'],
		['Pico', 'Philly', 'Blammed'],
		['Satin-Panties', 'High', 'Milf'],
		['Cocoa', 'Eggnog', 'Winter-Horrorland'],
		['Senpai', 'Roses', 'Thorns']
	];
	
	var grpWeekText:FlxTypedGroup<FlxText>;
	var difficultySelectors:FlxGroup;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;
	var sprDifficulty:FlxSprite;
	
	var txtWeekTitle:FlxText;
	var txtTracklist:FlxText;
	
	override function create()
	{
		super.create();
		
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		bg.antialiasing = Preferences.data.antialiasing;
		add(bg);
		
		grpWeekText = new FlxTypedGroup<FlxText>();
		add(grpWeekText);
		
		for (i in 0...weekNames.length)
		{
			var weekThing:FlxText = new FlxText(0, 400 + (i * 20), 0, weekNames[i], 24);
			weekThing.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
			weekThing.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
			weekThing.screenCenter(X);
			weekThing.ID = i;
			grpWeekText.add(weekThing);
			weekThing.antialiasing = Preferences.data.antialiasing;
		}
		
		txtTracklist = new FlxText(FlxG.width * 0.05, 100, 0, "Tracks", 32);
		txtTracklist.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		txtTracklist.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(txtTracklist);
		
		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		txtWeekTitle.alpha = 0.7;
		add(txtWeekTitle);
		
		difficultySelectors = new FlxGroup();
		add(difficultySelectors);
		
		leftArrow = new FlxSprite(grpWeekText.members[0].x + grpWeekText.members[0].width + 10, grpWeekText.members[0].y + 10);
		leftArrow.frames = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);
		
		sprDifficulty = new FlxSprite(leftArrow.x + 130, leftArrow.y);
		sprDifficulty.frames = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		sprDifficulty.animation.addByPrefix('easy', 'EASY');
		sprDifficulty.animation.addByPrefix('normal', 'NORMAL');
		sprDifficulty.animation.addByPrefix('hard', 'HARD');
		sprDifficulty.animation.play('normal');
		difficultySelectors.add(sprDifficulty);
		
		rightArrow = new FlxSprite(sprDifficulty.x + sprDifficulty.width + 50, leftArrow.y);
		rightArrow.frames = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);
		
		changeWeek();
		changeDifficulty();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (controls.UP_P)
			changeWeek(-1);
		if (controls.DOWN_P)
			changeWeek(1);
		
		if (controls.RIGHT_P)
			changeDifficulty(1);
		if (controls.LEFT_P)
			changeDifficulty(-1);
		
		if (controls.ACCEPT)
		{
			selectWeek();
		}
		
		if (controls.BACK)
		{
			FlxG.switchState(new MenuState());
		}
	}
	
	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;
		
		if (curWeek >= weekNames.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = weekNames.length - 1;
		
		var bullShit:Int = 0;
		
		for (item in grpWeekText.members)
		{
			item.targetY = bullShit - curWeek;
			
			if (item.ID == curWeek)
				item.alpha = 1;
			else
				item.alpha = 0.6;
			
			bullShit++;
		}
		
		FlxG.sound.play(Paths.sound('scrollMenu'));
		
		updateText();
	}
	
	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;
		
		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;
		
		sprDifficulty.offset.x = 0;
		
		switch (curDifficulty)
		{
			case 0:
				sprDifficulty.animation.play('easy');
				sprDifficulty.offset.x = 20;
			case 1:
				sprDifficulty.animation.play('normal');
				sprDifficulty.offset.x = 70;
			case 2:
				sprDifficulty.animation.play('hard');
				sprDifficulty.offset.x = 20;
		}
		
		sprDifficulty.alpha = 0;
		
		FlxTween.tween(sprDifficulty, {y: leftArrow.y + 15, alpha: 1}, 0.07);
	}
	
	function updateText():Void
	{
		txtWeekTitle.text = weekNames[curWeek].toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);
		
		var stringThing:Array<String> = weekData[curWeek];
		
		txtTracklist.text = "Tracks\n\n";
		for (i in 0...stringThing.length)
		{
			txtTracklist.text += stringThing[i] + "\n";
		}
		
		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;
	}
	
	function selectWeek():Void
	{
		var songs:Array<String> = weekData[curWeek];
		
		PlayState.storyPlaylist = songs;
		PlayState.isStoryMode = true;
		PlayState.storyDifficulty = curDifficulty;
		PlayState.storyWeek = curWeek;
		
		var songLowercase:String = songs[0].toLowerCase();
		PlayState.SONG = SongLoader.loadFromJson(songLowercase, curDifficulty);
		
		FlxG.switchState(new PlayState());
	}
}
