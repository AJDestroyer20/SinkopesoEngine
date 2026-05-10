package gameplay.stage;

import core.structures.Stage;
import flixel.group.FlxGroup.FlxTypedGroup;

class StageBuilder
{
	public var curStage:String = 'stage';
	
	public var defaultCamZoom:Float = 1.05;
	
	public var layers:Map<Int, FlxTypedGroup<FlxSprite>>;
	
	public var bfPosition:Array<Float> = [770, 450];
	public var dadPosition:Array<Float> = [100, 100];
	public var gfPosition:Array<Float> = [400, 130];
	
	public function new()
	{
		layers = new Map<Int, FlxTypedGroup<FlxSprite>>();
	}
	
	public function buildStage(stageName:String):Void
	{
		curStage = stageName;
		
		switch (stageName)
		{
			case 'stage':
				buildDefaultStage();
			case 'spooky':
				buildSpookyStage();
			case 'philly':
				buildPhillyStage();
			case 'limo':
				buildLimoStage();
			case 'mall':
				buildMallStage();
			case 'school' | 'schoolEvil':
				buildSchoolStage(stageName == 'schoolEvil');
			default:
				buildDefaultStage();
		}
	}
	
	private function buildDefaultStage():Void
	{
		defaultCamZoom = 0.9;
		
		var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('stageback'));
		bg.antialiasing = Preferences.data.antialiasing;
		bg.scrollFactor.set(0.9, 0.9);
		bg.active = false;
		addToLayer(0, bg);
		
		var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image('stagefront'));
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		stageFront.antialiasing = Preferences.data.antialiasing;
		stageFront.scrollFactor.set(0.9, 0.9);
		stageFront.active = false;
		addToLayer(1, stageFront);
		
		var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(Paths.image('stagecurtains'));
		stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
		stageCurtains.updateHitbox();
		stageCurtains.antialiasing = Preferences.data.antialiasing;
		stageCurtains.scrollFactor.set(1.3, 1.3);
		stageCurtains.active = false;
		addToLayer(2, stageCurtains);
	}
	
	private function buildSpookyStage():Void
	{
		defaultCamZoom = 1.05;
		
		var bg:FlxSprite = new FlxSprite(-200, -100).loadGraphic(Paths.image('halloween_bg', 'week2'));
		bg.antialiasing = Preferences.data.antialiasing;
		addToLayer(0, bg);
	}
	
	private function buildPhillyStage():Void
	{
		defaultCamZoom = 1.05;
		
		var bg:FlxSprite = new FlxSprite(-100).loadGraphic(Paths.image('philly/sky', 'week3'));
		bg.scrollFactor.set(0.1, 0.1);
		addToLayer(0, bg);
		
		var city:FlxSprite = new FlxSprite(-10).loadGraphic(Paths.image('philly/city', 'week3'));
		city.scrollFactor.set(0.3, 0.3);
		city.setGraphicSize(Std.int(city.width * 0.85));
		city.updateHitbox();
		addToLayer(1, city);
	}
	
	private function buildLimoStage():Void
	{
		defaultCamZoom = 0.9;
		
		var skyBG:FlxSprite = new FlxSprite(-120, -50).loadGraphic(Paths.image('limo/limoSunset', 'week4'));
		skyBG.scrollFactor.set(0.1, 0.1);
		addToLayer(0, skyBG);
	}
	
	private function buildMallStage():Void
	{
		defaultCamZoom = 0.8;
		
		var bg:FlxSprite = new FlxSprite(-1000, -500).loadGraphic(Paths.image('christmas/bgWalls', 'week5'));
		bg.antialiasing = Preferences.data.antialiasing;
		bg.scrollFactor.set(0.2, 0.2);
		bg.active = false;
		bg.setGraphicSize(Std.int(bg.width * 0.8));
		bg.updateHitbox();
		addToLayer(0, bg);
	}
	
	private function buildSchoolStage(evil:Bool = false):Void
	{
		defaultCamZoom = 1.05;
		
		var bgSky:FlxSprite = new FlxSprite().loadGraphic(Paths.image('weeb/weebSky', 'week6'));
		bgSky.scrollFactor.set(0.1, 0.1);
		addToLayer(0, bgSky);
		
		var bgSchool:FlxSprite = new FlxSprite(-200, 0).loadGraphic(Paths.image('weeb/weebSchool', 'week6'));
		bgSchool.scrollFactor.set(0.6, 0.90);
		addToLayer(1, bgSchool);
	}
	
	public function addToLayer(layerIndex:Int, sprite:FlxSprite):Void
	{
		if (!layers.exists(layerIndex))
		{
			layers.set(layerIndex, new FlxTypedGroup<FlxSprite>());
		}
		
		layers.get(layerIndex).add(sprite);
	}
	
	public function addLayersToState(state:FlxState):Void
	{
		var sortedKeys:Array<Int> = [];
		for (key in layers.keys())
		{
			sortedKeys.push(key);
		}
		sortedKeys.sort(function(a:Int, b:Int):Int { return a - b; });
		
		for (key in sortedKeys)
		{
			state.add(layers.get(key));
		}
	}
}
