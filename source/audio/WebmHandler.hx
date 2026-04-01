package audio;

/**
 * WebmHandler — REMOVED in SinkopesoEngine
 *
 * extension-webm is dead and unmaintained. All video playback now goes
 * through VideoHandler (hxvlc 2.0.1), which supports the same .webm files
 * plus every other format libvlc handles.
 *
 * If you hit this file during compilation:
 *   - Find every `new WebmHandler()` → replace with `new VideoHandler()`
 *   - Find `GlobalVideo.setWebm(x)` → replace with `GlobalVideo.setVid(x)`
 *   - Find `FEATURE_WEBM` → replace with `FEATURE_VIDEO`
 *   - In `backgroundVideo()` — already migrated in PlayState.hx
 *   - Install: haxelib install hxvlc 2.0.1
 */
@:deprecated("WebmHandler removed. Use audio.VideoHandler (hxvlc) instead.")
class WebmHandler
{
	public function new()
	{
		throw "WebmHandler is removed. Use audio.VideoHandler + hxvlc 2.0.1 instead.";
	}
}
