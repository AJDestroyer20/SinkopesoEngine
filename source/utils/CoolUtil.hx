package utils;

import flixel.util.FlxColor;
import lime.utils.Assets;

class CoolUtil
{
	public static var daPixelZoom:Float = 6;
	
	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];
		
		if (sys.FileSystem.exists(path))
			daList = sys.io.File.getContent(path).trim().split('\n');
		else if (Assets.exists(path))
			daList = Assets.getText(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = string.trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function dominantColor(sprite:flixel.FlxSprite):FlxColor
	{
		var countByColor:Map<Int, Int> = [];
		
		for (col in 0...sprite.frameWidth)
		{
			for (row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:FlxColor = sprite.pixels.getPixel32(col, row);
				if (colorOfThisPixel.alpha > 200)
				{
					var count:Int = countByColor.exists(colorOfThisPixel) ? countByColor.get(colorOfThisPixel) : 0;
					countByColor.set(colorOfThisPixel, count + 1);
				}
			}
		}

		var maxCount = 0;
		var maxKey:FlxColor = 0x0;
		
		for (key in countByColor.keys())
		{
			if (countByColor.get(key) >= maxCount)
			{
				maxCount = countByColor.get(key);
				maxKey = key;
			}
		}

		return maxKey;
	}

	public static function boundTo(value:Float, min:Float, max:Float):Float
	{
		return Math.max(min, Math.min(max, value));
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if (decimals < 1)
			return Math.floor(value);

		var tempMult:Float = 1;
		for (i in 0...decimals)
			tempMult *= 10;

		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}

	public static function formatTime(time:Float, ?showMS:Bool = false):String
	{
		var seconds:Int = Math.floor(time / 1000);
		var minutes:Int = Math.floor(seconds / 60);
		
		var result:String = '';
		result += (minutes < 10 ? '0' : '') + minutes + ':';
		result += ((seconds % 60) < 10 ? '0' : '') + (seconds % 60);
		
		if (showMS)
		{
			var ms:Int = Math.floor((time % 1000));
			result += '.' + (ms < 100 ? (ms < 10 ? '00' : '0') : '') + ms;
		}
		
		return result;
	}

	public static function getSizeString(size:Float):String
	{
		var labels:Array<String> = ['B', 'KB', 'MB', 'GB'];
		var rSize:Float = size;
		var label:Int = 0;
		
		while (rSize > 1024 && label < labels.length - 1)
		{
			rSize /= 1024;
			label++;
		}
		
		return '${floorDecimal(rSize, 2)} ${labels[label]}';
	}

	public static function difficultyString():String
	{
		return CoolUtil.difficulties[PlayState.storyDifficulty];
	}

	public static var difficulties:Array<String> = ['Easy', 'Normal', 'Hard'];
}
