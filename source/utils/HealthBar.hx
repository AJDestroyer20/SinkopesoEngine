package utils;

class HealthBar extends FlxSprite
{
	public var leftColor:FlxColor = FlxColor.RED;
	public var rightColor:FlxColor = FlxColor.LIME;
	
	public var percent:Float = 0;
	
	private var barWidth:Int = 0;
	private var barHeight:Int = 0;
	
	public function new(x:Float = 0, y:Float = 0, width:Int = 100, height:Int = 10)
	{
		super(x, y);
		
		barWidth = width;
		barHeight = height;
		
		makeGraphic(width, height, FlxColor.BLACK);
		
		updateBar();
	}
	
	public function updateBar():Void
	{
		makeGraphic(barWidth, barHeight, FlxColor.BLACK);
		
		var leftBarWidth:Int = Std.int(barWidth * percent);
		
		for (i in 0...barHeight)
		{
			for (j in 0...leftBarWidth)
			{
				pixels.setPixel32(j, i, leftColor);
			}
			
			for (j in leftBarWidth...barWidth)
			{
				pixels.setPixel32(j, i, rightColor);
			}
		}
	}
	
	public function setColors(left:FlxColor, right:FlxColor):Void
	{
		leftColor = left;
		rightColor = right;
		updateBar();
	}
	
	public function setPercent(value:Float):Void
	{
		percent = FlxMath.bound(value, 0, 1);
		updateBar();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
