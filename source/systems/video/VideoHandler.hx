package systems.video;

#if FEATURE_HXVLC
import hxvlc.flixel.FlxVideo;
import hxvlc.flixel.FlxVideoSprite;
#end

class VideoHandler
{
	#if FEATURE_HXVLC
	public var video:FlxVideoSprite;
	public var finishCallback:Void->Void;
	
	public function new()
	{
	}
	
	public function playVideo(path:String, ?callback:Void->Void):Void
	{
		finishCallback = callback;
		
		if (video != null)
		{
			video.destroy();
		}
		
		video = new FlxVideoSprite();
		video.antialiasing = Preferences.data.antialiasing;
		
		video.load(path);
		video.play();
		
		FlxG.state.add(video);
		
		video.bitmap.onEndReached.add(onVideoEnd);
	}
	
	private function onVideoEnd():Void
	{
		if (video != null)
		{
			video.destroy();
			video = null;
		}
		
		if (finishCallback != null)
		{
			finishCallback();
		}
	}
	
	public function pauseVideo():Void
	{
		if (video != null)
		{
			video.pause();
		}
	}
	
	public function resumeVideo():Void
	{
		if (video != null)
		{
			video.resume();
		}
	}
	
	public function stopVideo():Void
	{
		if (video != null)
		{
			video.stop();
			video.destroy();
			video = null;
		}
	}
	
	public function destroy():Void
	{
		stopVideo();
		finishCallback = null;
	}
	
	#else
	
	public function new() {}
	public function playVideo(path:String, ?callback:Void->Void):Void 
	{
		trace('Video playback not available - FEATURE_HXVLC not defined');
		if (callback != null) callback();
	}
	public function pauseVideo():Void {}
	public function resumeVideo():Void {}
	public function stopVideo():Void {}
	public function destroy():Void {}
	
	#end
}
