package core;

import flixel.math.FlxMath;

class HelperFunctions
{
	public static function truncateFloat(number:Float, precision:Int):Float
	{
		var multiplier = Math.pow(10, precision);
		return Math.round(number * multiplier) / multiplier;
	}

	public static function GCD(a:Int, b:Int):Int
	{
		var valueA = FlxMath.absInt(a);
		var valueB = FlxMath.absInt(b);

		while (valueB != 0)
		{
			var remainder = valueA % valueB;
			valueA = valueB;
			valueB = remainder;
		}

		return valueA;
	}
}
