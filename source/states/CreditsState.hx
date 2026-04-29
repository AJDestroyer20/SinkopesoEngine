package states;

import backend.MusicBeatState;

class CreditsState extends MusicBeatState
{
	var credits:Array<CreditPerson> = [];
	var grpCredits:FlxTypedGroup<FlxText>;
	var curSelected:Int = 0;
	
	override function create()
	{
		super.create();
		
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF9271fd;
		bg.antialiasing = Preferences.data.antialiasing;
		add(bg);
		
		credits = [
			new CreditPerson('Engine Fusion', 'Base engine developer', ''),
			new CreditPerson('Kade Engine', 'Original stable engine', ''),
			new CreditPerson('ALE Engine', 'Modular architecture base', ''),
			new CreditPerson('Friday Night Funkin\'', 'Original game by ninjamuffin99', '')
		];
		
		grpCredits = new FlxTypedGroup<FlxText>();
		add(grpCredits);
		
		for (i in 0...credits.length)
		{
			var creditText:FlxText = new FlxText(20, 50 + (i * 80), 0, credits[i].name, 32);
			creditText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT);
			creditText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
			creditText.ID = i;
			grpCredits.add(creditText);
			
			var descText:FlxText = new FlxText(20, 50 + (i * 80) + 36, 0, credits[i].description, 20);
			descText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT);
			descText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
			descText.alpha = 0.7;
			grpCredits.add(descText);
		}
		
		changeSelection();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (controls.UP_P)
			changeSelection(-1);
		if (controls.DOWN_P)
			changeSelection(1);
		
		if (controls.BACK)
		{
			FlxG.switchState(new MenuState());
		}
	}
	
	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;
		
		if (curSelected < 0)
			curSelected = credits.length - 1;
		if (curSelected >= credits.length)
			curSelected = 0;
		
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}
}

class CreditPerson
{
	public var name:String;
	public var description:String;
	public var link:String;
	
	public function new(name:String, description:String, link:String)
	{
		this.name = name;
		this.description = description;
		this.link = link;
	}
}
