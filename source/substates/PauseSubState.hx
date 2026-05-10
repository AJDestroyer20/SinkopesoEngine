package substates;

import backend.MusicBeatSubState;

class PauseSubState extends MusicBeatSubState
{
	var grpMenuShit:FlxTypedGroup<FlxText>;
	var menuItems:Array<String> = ['Resume', 'Restart Song', 'Exit to menu'];
	var curSelected:Int = 0;
	
	var pauseMusic:FlxSound;
	var bg:FlxSprite;
	var levelInfo:FlxText;
	var levelDifficulty:FlxText;
	
	public function new()
	{
		super();
		
		pauseMusic = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
		FlxG.sound.list.add(pauseMusic);
		
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);
		
		levelInfo = new FlxText(20, 15, 0, "", 32);
		levelInfo.text = PlayState.SONG.song;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();
		add(levelInfo);
		
		levelDifficulty = new FlxText(20, 15 + 32, 0, "", 32);
		levelDifficulty.text = CoolUtil.difficultyString();
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		add(levelDifficulty);
		
		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;
		
		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		
		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		
		grpMenuShit = new FlxTypedGroup<FlxText>();
		add(grpMenuShit);
		
		for (i in 0...menuItems.length)
		{
			var songText:FlxText = new FlxText(0, (70 * i) + 30, 0, menuItems[i], 32);
			songText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
			songText.updateHitbox();
			songText.screenCenter(X);
			songText.ID = i;
			grpMenuShit.add(songText);
		}
		
		changeSelection();
		
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;
		
		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;
		
		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}
		
		if (accepted)
		{
			var daSelected:String = menuItems[curSelected];
			
			switch (daSelected)
			{
				case "Resume":
					close();
				case "Restart Song":
					FlxG.resetState();
				case "Exit to menu":
					FlxG.switchState(new states.TitleState());
			}
		}
	}
	
	override function destroy()
	{
		if (pauseMusic != null)
		{
			pauseMusic.destroy();
		}
		
		super.destroy();
	}
	
	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;
		
		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;
		
		var bullShit:Int = 0;
		
		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;
			
			item.alpha = 0.6;
			
			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}
		
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}
}
