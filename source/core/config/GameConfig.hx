package core.config;

typedef GameConfigData = {
	?initialState:String,
	?windowWidth:Int,
	?windowHeight:Int,
	?framerate:Int,
	?skipSplash:Bool,
	?startFullscreen:Bool
}

class GameConfig
{
	public var initialState:String = "states.TitleState";
	public var windowWidth:Int = 1280;
	public var windowHeight:Int = 720;
	public var framerate:Int = 120;
	public var skipSplash:Bool = true;
	public var startFullscreen:Bool = false;

	public function new(?data:GameConfigData)
	{
		if (data == null)
			return;

		if (data.initialState != null) initialState = data.initialState;
		if (data.windowWidth != null) windowWidth = data.windowWidth;
		if (data.windowHeight != null) windowHeight = data.windowHeight;
		if (data.framerate != null) framerate = data.framerate;
		if (data.skipSplash != null) skipSplash = data.skipSplash;
		if (data.startFullscreen != null) startFullscreen = data.startFullscreen;
	}
}
