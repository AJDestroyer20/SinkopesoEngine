package systems.audio;

import flixel.FlxG;
import flixel.sound.FlxSound;
import core.events.EventBus;
import flixel.tweens.FlxTween;

class AudioManager
{
	public var eventBus(default, null):EventBus;
	public var reactiveAudio:ReactiveAudio;
	public var musicLayers:Map<String, FlxSound> = [];

	public function new(eventBus:EventBus)
	{
		this.eventBus = eventBus;
	}

	public function playMusicWithReactive(sound:openfl.media.Sound, volume:Float = 1):Void
	{
		FlxG.sound.playMusic(sound, volume);
		reactiveAudio = new ReactiveAudio(FlxG.sound.music);
	}

	public function addLayer(id:String, sound:FlxSound):Void
	{
		musicLayers.set(id, sound);
		FlxG.sound.list.add(sound);
	}

	public function setLayerVolume(id:String, to:Float, duration:Float = 0):Void
	{
		var layer = musicLayers.get(id);
		if (layer == null)
			return;
		if (duration <= 0) layer.volume = to; else FlxTween.num(layer.volume, to, duration, {onUpdate: function(v) layer.volume = v});
	}

	public function update():Void
	{
		if (reactiveAudio != null)
		{
			reactiveAudio.update();
			eventBus.publish("audio.reactive", {
				bass: reactiveAudio.bassIntensity,
				mid: reactiveAudio.midIntensity,
				treble: reactiveAudio.trebleIntensity
			});
		}
	}
}
