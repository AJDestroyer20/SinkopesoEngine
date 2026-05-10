package states;

import backend.MusicBeatState;

class MenuState extends MusicBeatState
{
	var menuItems:Array<String> = ['story mode', 'freeplay', 'options', 'credits'];
	var grpMenuShit:FlxTypedGroup<FlxSprite>;
	
	var curSelected:Int = 0;
	var bg:FlxSprite;
	var magenta:FlxSprite;
	
	override function create()
	{
		super.create();
		
		#if FEATURE_DISCORD
		Discord.changePresence("In the Menus", null);
		#end
		
		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}
		
		bg = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.set(0, 0.18);
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = Preferences.data.antialiasing;
		add(bg);
		
		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set(0, 0.18);
		magenta.setGraphicSize(Std.int(magenta.width * 1.1));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = Preferences.data.antialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);
		
		grpMenuShit = new FlxTypedGroup<FlxSprite>();
		add(grpMenuShit);
		
		for (i in 0...menuItems.length)
		{
			var menuItem:FlxSprite = new FlxSprite(0, 60 + (i * 160));
			menuItem.frames = Paths.getSparrowAtlas('FNF_main_menu_assets');
			menuItem.animation.addByPrefix('idle', menuItems[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', menuItems[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			grpMenuShit.add(menuItem);
			menuItem.scrollFactor.set();
			menuItem.antialiasing = Preferences.data.antialiasing;
		}
		
		changeSelection();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
		}
		
		if (controls.UP_P)
		{
			changeSelection(-1);
		}
		
		if (controls.DOWN_P)
		{
			changeSelection(1);
		}
		
		if (controls.ACCEPT)
		{
			selectItem();
		}
	}
	
	function changeSelection(change:Int = 0):Void
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		
		curSelected += change;
		
		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;
		
		var bullShit:Int = 0;
		
		for (item in grpMenuShit.members)
		{
			item.animation.play('idle');
			item.updateHitbox();
			
			if (item.ID == curSelected)
			{
				item.animation.play('selected');
				item.centerOffsets();
			}
			
			bullShit++;
		}
	}
	
	function selectItem():Void
	{
		var selectedItem:String = menuItems[curSelected];
		
		switch (selectedItem)
		{
			case 'story mode':
				FlxG.switchState(new StoryMenuState());
				
			case 'freeplay':
				FlxG.switchState(new FreeplayState());
				
			case 'options':
				FlxG.switchState(new OptionsState());
				
			case 'credits':
				FlxG.switchState(new CreditsState());
		}
	}
}
