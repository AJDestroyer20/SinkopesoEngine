package states;

import backend.MusicBeatState;

class TitleState extends MusicBeatState
{
	var titleText:FlxText;
	var pressEnter:FlxText;
	var creditsText:FlxText;
	
	var transitioning:Bool = false;
	
	override function create()
	{
		super.create();
		
		backend.Preferences.init();
		backend.Controls.init();
		backend.Mods.init();
		backend.Discord.init();
		
		Conductor.changeBPM(102);
		
		#if FEATURE_DISCORD
		Discord.changePresence("In the Title Screen", null);
		#end
		
		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			FlxG.sound.music.fadeIn(4, 0, 0.7);
		}
		
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);
		
		var logo:FlxSprite = new FlxSprite().loadGraphic(Paths.image('logo'));
		logo.screenCenter();
		logo.y -= 50;
		logo.antialiasing = Preferences.data.antialiasing;
		add(logo);
		
		titleText = new FlxText(0, 0, FlxG.width, "FNF ENGINE", 64);
		titleText.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER);
		titleText.setBorderStyle(OUTLINE, FlxColor.BLACK, 4);
		titleText.screenCenter();
		titleText.y = logo.y + logo.height + 20;
		add(titleText);
		
		pressEnter = new FlxText(0, FlxG.height - 80, FlxG.width, "Press ENTER to start", 32);
		pressEnter.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		pressEnter.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(pressEnter);
		
		creditsText = new FlxText(10, FlxG.height - 40, 0, "Engine v1.0", 16);
		creditsText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		creditsText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		add(creditsText);
		
		FlxTween.tween(logo, {y: logo.y + 10}, 1, {ease: FlxEase.quadInOut, type: PINGPONG});
	}
	
	var timer:Float = 0;
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		Conductor.songPosition = FlxG.sound.music.time;
		
		timer += elapsed;
		pressEnter.alpha = Math.abs(Math.sin(timer * 2));
		
		if (FlxG.keys.justPressed.ENTER && !transitioning)
		{
			transitioning = true;
			FlxG.camera.flash(FlxColor.WHITE, 1);
			FlxG.sound.play(Paths.sound('confirmMenu'));
			
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				FlxG.switchState(new MenuState());
			});
		}
	}
	
	override function beatHit()
	{
		super.beatHit();
		
		titleText.scale.set(1.05, 1.05);
		FlxTween.tween(titleText.scale, {x: 1, y: 1}, 0.3);
	}
}
