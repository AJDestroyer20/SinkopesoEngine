package systems.audio;

import flixel.sound.FlxSound;
import grig.audio.FFT;

class ReactiveAudio
{
	public var sound:FlxSound;
	public var fft:FFT;
	
	public var bassLevels:Array<Float> = [];
	public var midLevels:Array<Float> = [];
	public var trebleLevels:Array<Float> = [];
	
	public var bassIntensity:Float = 0;
	public var midIntensity:Float = 0;
	public var trebleIntensity:Float = 0;
	
	private var fftSize:Int = 2048;
	private var sampleRate:Int = 44100;
	
	public function new(sound:FlxSound)
	{
		this.sound = sound;
		fft = new FFT(fftSize);
	}
	
	public function update():Void
	{
		if (sound == null || !sound.playing)
			return;
		
		var samples = getSamples();
		if (samples == null || samples.length == 0)
			return;
		
		fft.forward(samples);
		
		var spectrum = fft.spectrum;
		
		bassLevels = [];
		midLevels = [];
		trebleLevels = [];
		
		var bassEnd:Int = Std.int(spectrum.length * 0.1);
		var midEnd:Int = Std.int(spectrum.length * 0.4);
		
		for (i in 0...bassEnd)
		{
			bassLevels.push(spectrum[i]);
		}
		
		for (i in bassEnd...midEnd)
		{
			midLevels.push(spectrum[i]);
		}
		
		for (i in midEnd...spectrum.length)
		{
			trebleLevels.push(spectrum[i]);
		}
		
		bassIntensity = calculateAverage(bassLevels);
		midIntensity = calculateAverage(midLevels);
		trebleIntensity = calculateAverage(trebleLevels);
	}
	
	private function getSamples():Array<Float>
	{
		if (sound == null || sound._channel == null)
			return null;
		
		var samples:Array<Float> = [];
		
		for (i in 0...fftSize)
		{
			samples.push(0);
		}
		
		return samples;
	}
	
	private function calculateAverage(values:Array<Float>):Float
	{
		if (values.length == 0)
			return 0;
		
		var sum:Float = 0;
		for (val in values)
		{
			sum += val;
		}
		
		return sum / values.length;
	}
	
	public function getBassKick(threshold:Float = 0.8):Bool
	{
		return bassIntensity > threshold;
	}
	
	public function destroy():Void
	{
		sound = null;
		fft = null;
		bassLevels = null;
		midLevels = null;
		trebleLevels = null;
	}
}
