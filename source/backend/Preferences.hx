package backend;

import flixel.util.FlxSave;

class Preferences
{
	public static var data:PreferencesData;
	private static var save:FlxSave;

	public static function init():Void
	{
		save = new FlxSave();
		save.bind('preferences');

		if (save.data.preferences != null)
		{
			data = save.data.preferences;
		}
		else
		{
			data = {
				downScroll: false,
				middleScroll: false,
				ghostTapping: true,
				antialiasing: true,
				framerate: 120,
				noteSplashes: true,
				lowQuality: false,
				flashing: true,
				camZooms: true,
				hideHud: false,
				noteOffset: 0,
				arrowRGB: [
					[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
					[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
					[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
					[0xFFF9393F, 0xFFFFFFFF, 0xFF651038]
				],
				scrollSpeed: 1.0,
				healthBarAlpha: 1.0,
				controllerMode: false
			};
		}
	}

	public static function save():Void
	{
		if (save != null)
		{
			save.data.preferences = data;
			save.flush();
		}
	}

	public static function reset():Void
	{
		if (save != null)
		{
			save.erase();
		}
		init();
	}
}

typedef PreferencesData =
{
	var downScroll:Bool;
	var middleScroll:Bool;
	var ghostTapping:Bool;
	var antialiasing:Bool;
	var framerate:Int;
	var noteSplashes:Bool;
	var lowQuality:Bool;
	var flashing:Bool;
	var camZooms:Bool;
	var hideHud:Bool;
	var noteOffset:Float;
	var arrowRGB:Array<Array<FlxColor>>;
	var scrollSpeed:Float;
	var healthBarAlpha:Float;
	var controllerMode:Bool;
}
