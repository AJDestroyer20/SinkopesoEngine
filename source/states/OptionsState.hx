package states;

import backend.MusicBeatState;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [
		'Down Scroll',
		'Middle Scroll',
		'Ghost Tapping',
		'Note Splashes',
		'Flashing Lights',
		'Camera Zooms',
		'Low Quality',
		'Antialiasing',
		'Framerate',
		'AI Difficulty'
	];
	
	var curSelected:Int = 0;
	var grpOptions:FlxTypedGroup<FlxText>;
	
	var descText:FlxText;
	var valueText:FlxText;
	
	override function create()
	{
		super.create();
		
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.antialiasing = Preferences.data.antialiasing;
		add(bg);
		
		grpOptions = new FlxTypedGroup<FlxText>();
		add(grpOptions);
		
		for (i in 0...options.length)
		{
			var optionText:FlxText = new FlxText(20, 50 + (i * 50), 0, options[i], 32);
			optionText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT);
			optionText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
			optionText.ID = i;
			grpOptions.add(optionText);
		}
		
		descText = new FlxText(20, FlxG.height - 60, FlxG.width - 40, "", 20);
		descText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT);
		descText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(descText);
		
		valueText = new FlxText(FlxG.width - 200, 50, 180, "", 32);
		valueText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		valueText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(valueText);
		
		changeSelection();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (controls.UP_P)
			changeSelection(-1);
		if (controls.DOWN_P)
			changeSelection(1);
		
		if (controls.LEFT_P || controls.RIGHT_P)
			changeValue(controls.RIGHT_P ? 1 : -1);
		
		if (controls.BACK)
		{
			Preferences.save();
			FlxG.switchState(new MenuState());
		}
	}
	
	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;
		
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;
		
		for (item in grpOptions.members)
		{
			item.alpha = 0.6;
			
			if (item.ID == curSelected)
			{
				item.alpha = 1;
			}
		}
		
		updateDescription();
		updateValue();
		
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}
	
	function changeValue(change:Int):Void
	{
		switch (options[curSelected])
		{
			case 'Down Scroll':
				Preferences.data.downScroll = !Preferences.data.downScroll;
			case 'Middle Scroll':
				Preferences.data.middleScroll = !Preferences.data.middleScroll;
			case 'Ghost Tapping':
				Preferences.data.ghostTapping = !Preferences.data.ghostTapping;
			case 'Note Splashes':
				Preferences.data.noteSplashes = !Preferences.data.noteSplashes;
			case 'Flashing Lights':
				Preferences.data.flashing = !Preferences.data.flashing;
			case 'Camera Zooms':
				Preferences.data.camZooms = !Preferences.data.camZooms;
			case 'Low Quality':
				Preferences.data.lowQuality = !Preferences.data.lowQuality;
			case 'Antialiasing':
				Preferences.data.antialiasing = !Preferences.data.antialiasing;
			case 'Framerate':
				Preferences.data.framerate += change * 10;
				if (Preferences.data.framerate < 60)
					Preferences.data.framerate = 60;
				if (Preferences.data.framerate > 240)
					Preferences.data.framerate = 240;
				FlxG.drawFramerate = Preferences.data.framerate;
				FlxG.updateFramerate = Preferences.data.framerate;
			case 'AI Difficulty':
				Preferences.data.aiDifficulty += change;
				if (Preferences.data.aiDifficulty < 0)
					Preferences.data.aiDifficulty = 4;
				if (Preferences.data.aiDifficulty > 4)
					Preferences.data.aiDifficulty = 0;
		}
		
		updateValue();
	}
	
	function updateDescription():Void
	{
		var desc:String = switch (options[curSelected])
		{
			case 'Down Scroll': 'Notes scroll from top to bottom';
			case 'Middle Scroll': 'Notes scroll in the center';
			case 'Ghost Tapping': 'Press notes without penalty';
			case 'Note Splashes': 'Show splash effects on perfect hits';
			case 'Flashing Lights': 'Toggle flashing lights';
			case 'Camera Zooms': 'Camera zooms on beat';
			case 'Low Quality': 'Disable some visual effects';
			case 'Antialiasing': 'Smooth sprites';
			case 'Framerate': 'Change game framerate';
			case 'AI Difficulty': 'Bot difficulty: Auto/Easy/Normal/Hard/Extreme';
			default: '';
		}
		
		descText.text = desc;
	}
	
	function updateValue():Void
	{
		var val:String = switch (options[curSelected])
		{
			case 'Down Scroll': Preferences.data.downScroll ? 'ON' : 'OFF';
			case 'Middle Scroll': Preferences.data.middleScroll ? 'ON' : 'OFF';
			case 'Ghost Tapping': Preferences.data.ghostTapping ? 'ON' : 'OFF';
			case 'Note Splashes': Preferences.data.noteSplashes ? 'ON' : 'OFF';
			case 'Flashing Lights': Preferences.data.flashing ? 'ON' : 'OFF';
			case 'Camera Zooms': Preferences.data.camZooms ? 'ON' : 'OFF';
			case 'Low Quality': Preferences.data.lowQuality ? 'ON' : 'OFF';
			case 'Antialiasing': Preferences.data.antialiasing ? 'ON' : 'OFF';
			case 'Framerate': Std.string(Preferences.data.framerate);
			case 'AI Difficulty': ['Auto', 'Easy', 'Normal', 'Hard', 'Extreme'][Preferences.data.aiDifficulty];
			default: '';
		}
		
		valueText.text = val;
		valueText.y = grpOptions.members[curSelected].y;
	}
}
	
	var curSelected:Int = 0;
	var grpOptions:FlxTypedGroup<FlxText>;
	
	var descText:FlxText;
	var valueText:FlxText;
	
	override function create()
	{
		super.create();
		
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.antialiasing = Preferences.data.antialiasing;
		add(bg);
		
		grpOptions = new FlxTypedGroup<FlxText>();
		add(grpOptions);
		
		for (i in 0...options.length)
		{
			var optionText:FlxText = new FlxText(20, 50 + (i * 50), 0, options[i], 32);
			optionText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT);
			optionText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
			optionText.ID = i;
			grpOptions.add(optionText);
		}
		
		descText = new FlxText(20, FlxG.height - 60, FlxG.width - 40, "", 20);
		descText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT);
		descText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(descText);
		
		valueText = new FlxText(FlxG.width - 200, 50, 180, "", 32);
		valueText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		valueText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(valueText);
		
		changeSelection();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (controls.UP_P)
			changeSelection(-1);
		if (controls.DOWN_P)
			changeSelection(1);
		
		if (controls.LEFT_P || controls.RIGHT_P)
			changeValue(controls.RIGHT_P ? 1 : -1);
		
		if (controls.BACK)
		{
			Preferences.save();
			FlxG.switchState(new MenuState());
		}
	}
	
	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;
		
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;
		
		for (item in grpOptions.members)
		{
			item.alpha = 0.6;
			
			if (item.ID == curSelected)
			{
				item.alpha = 1;
			}
		}
		
		updateDescription();
		updateValue();
		
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}
	
	function changeValue(change:Int):Void
	{
		switch (options[curSelected])
		{
			case 'Down Scroll':
				Preferences.data.downScroll = !Preferences.data.downScroll;
			case 'Middle Scroll':
				Preferences.data.middleScroll = !Preferences.data.middleScroll;
			case 'Ghost Tapping':
				Preferences.data.ghostTapping = !Preferences.data.ghostTapping;
			case 'Note Splashes':
				Preferences.data.noteSplashes = !Preferences.data.noteSplashes;
			case 'Flashing Lights':
				Preferences.data.flashing = !Preferences.data.flashing;
			case 'Camera Zooms':
				Preferences.data.camZooms = !Preferences.data.camZooms;
			case 'Low Quality':
				Preferences.data.lowQuality = !Preferences.data.lowQuality;
			case 'Antialiasing':
				Preferences.data.antialiasing = !Preferences.data.antialiasing;
			case 'Framerate':
				Preferences.data.framerate += change * 10;
				if (Preferences.data.framerate < 60)
					Preferences.data.framerate = 60;
				if (Preferences.data.framerate > 240)
					Preferences.data.framerate = 240;
				FlxG.drawFramerate = Preferences.data.framerate;
				FlxG.updateFramerate = Preferences.data.framerate;
		}
		
		updateValue();
	}
	
	function updateDescription():Void
	{
		var desc:String = switch (options[curSelected])
		{
			case 'Down Scroll': 'Notes scroll from top to bottom';
			case 'Middle Scroll': 'Notes scroll in the center';
			case 'Ghost Tapping': 'Press notes without penalty';
			case 'Note Splashes': 'Show splash effects on perfect hits';
			case 'Flashing Lights': 'Toggle flashing lights';
			case 'Camera Zooms': 'Camera zooms on beat';
			case 'Low Quality': 'Disable some visual effects';
			case 'Antialiasing': 'Smooth sprites';
			case 'Framerate': 'Change game framerate';
			default: '';
		}
		
		descText.text = desc;
	}
	
	function updateValue():Void
	{
		var val:String = switch (options[curSelected])
		{
			case 'Down Scroll': Preferences.data.downScroll ? 'ON' : 'OFF';
			case 'Middle Scroll': Preferences.data.middleScroll ? 'ON' : 'OFF';
			case 'Ghost Tapping': Preferences.data.ghostTapping ? 'ON' : 'OFF';
			case 'Note Splashes': Preferences.data.noteSplashes ? 'ON' : 'OFF';
			case 'Flashing Lights': Preferences.data.flashing ? 'ON' : 'OFF';
			case 'Camera Zooms': Preferences.data.camZooms ? 'ON' : 'OFF';
			case 'Low Quality': Preferences.data.lowQuality ? 'ON' : 'OFF';
			case 'Antialiasing': Preferences.data.antialiasing ? 'ON' : 'OFF';
			case 'Framerate': Std.string(Preferences.data.framerate);
			default: '';
		}
		
		valueText.text = val;
		valueText.y = grpOptions.members[curSelected].y;
	}
}
