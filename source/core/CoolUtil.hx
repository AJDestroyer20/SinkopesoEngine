package core;

import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class CoolUtil
{
	public static var difficultyArray:Array<String> = ['Easy', "Normal", "Hard"];

	public static var daPixelZoom:Float = 6;

	public static function difficultyFromInt(difficulty:Int):String
	{
		if (difficulty < 0 || difficulty >= difficultyArray.length)
		{
			return difficultyArray[1];
		}

		return difficultyArray[difficulty];
	}

	public static function coolTextFile(path:String):Array<String>
	{
		return splitAndTrimLines(OpenFlAssets.getText(path));
	}

	public static function coolStringFile(path:String):Array<String>
	{
		return splitAndTrimLines(path);
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var result:Array<Int> = [];
		for (i in min...max)
		{
			result.push(i);
		}
		return result;
	}

	static inline function splitAndTrimLines(content:String):Array<String>
	{
		var lines:Array<String> = content.trim().split('\n');
		for (i in 0...lines.length)
		{
			lines[i] = lines[i].trim();
		}
		return lines;
	}
}
