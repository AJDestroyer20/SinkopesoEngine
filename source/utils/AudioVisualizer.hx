package utils;

import flixel.sound.FlxSound;
import systems.audio.ReactiveAudio;

class AudioVisualizer extends FlxSpriteGroup
{
	private var bars:Array<FlxSprite> = [];
	private var barCount:Int = 64;
	private var barWidth:Float = 8;
	private var barSpacing:Float = 2;
	private var maxBarHeight:Float = 200;
	
	private var reactiveAudio:ReactiveAudio;
	private var sound:FlxSound;
	
	public var smoothing:Float = 0.3;
	public var amplification:Float = 2.0;
	
	private var barHeights:Array<Float> = [];
	
	public function new(x:Float, y:Float, sound:FlxSound)
	{
		super(x, y);
		
		this.sound = sound;
		reactiveAudio = new ReactiveAudio(sound);
		
		for (i in 0...barCount)
		{
			var bar:FlxSprite = new FlxSprite();
			bar.makeGraphic(Std.int(barWidth), Std.int(maxBarHeight), FlxColor.WHITE);
			bar.x = i * (barWidth + barSpacing);
			bar.origin.y = bar.height;
			bar.scale.y = 0.1;
			bars.push(bar);
			add(bar);
			
			barHeights.push(0);
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (sound != null && sound.playing)
		{
			reactiveAudio.update();
			
			var spectrum = getSpectrum();
			
			for (i in 0...bars.length)
			{
				if (i < spectrum.length)
				{
					var targetHeight:Float = spectrum[i] * amplification;
					targetHeight = Math.min(targetHeight, 1.0);
					
					barHeights[i] = FlxMath.lerp(barHeights[i], targetHeight, smoothing);
					
					bars[i].scale.y = barHeights[i];
					bars[i].updateHitbox();
					
					var colorValue:Float = barHeights[i];
					bars[i].color = FlxColor.fromRGBFloat(colorValue, 0.5, 1.0 - colorValue);
				}
			}
		}
		else
		{
			for (i in 0...bars.length)
			{
				barHeights[i] = FlxMath.lerp(barHeights[i], 0.1, 0.1);
				bars[i].scale.y = barHeights[i];
				bars[i].updateHitbox();
			}
		}
	}
	
	private function getSpectrum():Array<Float>
	{
		var spectrum:Array<Float> = [];
		
		var bassAvg:Float = reactiveAudio.bassIntensity;
		var midAvg:Float = reactiveAudio.midIntensity;
		var trebleAvg:Float = reactiveAudio.trebleIntensity;
		
		var barsPerSection:Int = Std.int(barCount / 3);
		
		for (i in 0...barsPerSection)
		{
			spectrum.push(bassAvg + FlxG.random.float(-0.1, 0.1));
		}
		
		for (i in 0...barsPerSection)
		{
			spectrum.push(midAvg + FlxG.random.float(-0.1, 0.1));
		}
		
		for (i in 0...(barCount - barsPerSection * 2))
		{
			spectrum.push(trebleAvg + FlxG.random.float(-0.1, 0.1));
		}
		
		return spectrum;
	}
	
	override function destroy()
	{
		if (reactiveAudio != null)
		{
			reactiveAudio.destroy();
		}
		
		super.destroy();
	}
}
