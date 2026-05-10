package utils;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System;

class FPSCounter extends TextField
{
	public var currentFPS(default, null):Int;
	public var memoryMegas(get, never):Float;
	
	private var times:Array<Float> = [];
	
	public function new(x:Float = 10, y:Float = 10)
	{
		super();
		
		this.x = x;
		this.y = y;
		
		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		
		defaultTextFormat = new TextFormat("_sans", 14, 0xFFFFFF);
		width = 300;
		height = 70;
		
		text = "FPS: 0\nMemory: 0 MB";
	}
	
	override function __enterFrame(deltaTime:Float):Void
	{
		var now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		
		while (times[0] < now - 1000)
		{
			times.shift();
		}
		
		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;
		
		if (visible)
		{
			text = 'FPS: $currentFPS / ${FlxG.updateFramerate}\n';
			text += 'Memory: ${CoolUtil.floorDecimal(memoryMegas, 2)} MB\n';
			
			#if debug
			text += 'State: ${Type.getClassName(Type.getClass(FlxG.state))}';
			#end
		}
	}
	
	private function get_memoryMegas():Float
	{
		return System.totalMemory / 1024 / 1024;
	}
}
