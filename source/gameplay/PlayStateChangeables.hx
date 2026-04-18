package gameplay;

class PlayStateChangeables
{
	public static var useDownscroll:Bool = false;
	public static var safeFrames:Int = 10;
	public static var scrollSpeed:Float = 1.0;
	public static var botPlay:Bool = false;
	public static var Optimize:Bool = false;
	public static var zoom:Float = 1.0;
	public static var mirrorMode:Bool = false;
	public static var opponentMode:Bool = false;
	public static var darkMode:Bool = false;

	public static function reset():Void
	{
		useDownscroll = false;
		safeFrames = 10;
		scrollSpeed = 1.0;
		botPlay = false;
		Optimize = false;
		zoom = 1.0;
		mirrorMode = false;
		opponentMode = false;
		darkMode = false;
	}
}
