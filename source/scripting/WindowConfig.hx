package scripting;

import openfl.Lib;
import lime.app.Application;

/**
 * WindowConfig
 * 
 * Controls ALL window-level properties at runtime.
 * Called from JSON config scripts, Lua, HaxeScript, etc.
 * 
 * ─── JSON config example (assets/data/window.json) ──────────────────────
 * {
 *   "type": "config",
 *   "window": {
 *     "title":        "Friday Night Funkin': My Fork",
 *     "width":        1280,
 *     "height":       720,
 *     "fps":          60,
 *     "icon":         "icon",
 *     "transparent":  false,
 *     "borderless":   false,
 *     "alwaysOnTop":  false,
 *     "resizable":    true,
 *     "x":            -1,
 *     "y":            -1,
 *     "background":   "0xFF000000"
 *   }
 * }
 * 
 * ─── Lua example ─────────────────────────────────────────────────────────
 *   WindowConfig.setTitle("New Title")
 *   WindowConfig.setSize(1920, 1080)
 *   WindowConfig.setAlpha(0.95)
 * 
 * ─── HaxeScript example ──────────────────────────────────────────────────
 *   WindowConfig.setTitle("Custom Title");
 *   WindowConfig.setBorderless(true);
 */
class WindowConfig
{
	static var _window(get, never):lime.ui.Window;
	static function get_window():lime.ui.Window
		return Application.current.window;

	// ─── TITLE ───────────────────────────────────────────────────────────

	public static function setTitle(title:String):Void
	{
		_window.title = title;
	}

	public static function getTitle():String
	{
		return _window.title;
	}

	// ─── SIZE ────────────────────────────────────────────────────────────

	public static function setSize(width:Int, height:Int):Void
	{
		_window.resize(width, height);
		flixel.FlxG.resizeWindow(width, height);
	}

	public static function setWidth(width:Int):Void  { setSize(width, _window.height); }
	public static function setHeight(height:Int):Void { setSize(_window.width, height); }

	public static function getWidth():Int  { return _window.width; }
	public static function getHeight():Int { return _window.height; }

	// ─── POSITION ────────────────────────────────────────────────────────

	public static function setPosition(x:Int, y:Int):Void
	{
		_window.move(x, y);
	}

	public static function centerWindow():Void
	{
		var screen = lime.system.System.screens[0];
		var x = Std.int((screen.bounds.width  - _window.width)  / 2);
		var y = Std.int((screen.bounds.height - _window.height) / 2);
		_window.move(x, y);
	}

	// ─── TRANSPARENCY / ALPHA ────────────────────────────────────────────

	/**
	 * Set window transparency (0.0 = fully transparent, 1.0 = fully opaque).
	 * Note: requires the window to have been created with transparent=true in Project.xml
	 * OR use the platform API (Windows only via WinAPI, macOS via NSWindow).
	 */
	public static function setAlpha(alpha:Float):Void
	{
		alpha = Math.max(0.0, Math.min(1.0, alpha));
		#if windows
		setWindowAlphaWindows(alpha);
		#elseif mac
		setWindowAlphaMac(alpha);
		#else
		trace('[WindowConfig] Alpha not supported on this platform.');
		#end
	}

	#if windows
	@:functionCode("
		HWND hwnd = (HWND)lime::utils::NativePointer::getInt( window );
		SetLayeredWindowAttributes( hwnd, 0, (BYTE)(alpha * 255), LWA_ALPHA );
		SetWindowLong( hwnd, GWL_EXSTYLE, GetWindowLong(hwnd, GWL_EXSTYLE) | WS_EX_LAYERED );
	")
	static function setWindowAlphaWindows(alpha:Float):Void {}
	#end

	#if mac
	@:functionCode("
		NSWindow* win = (__bridge NSWindow*)window;
		[win setAlphaValue:alpha];
	")
	static function setWindowAlphaMac(alpha:Float):Void {}
	#end

	// ─── BORDERLESS ──────────────────────────────────────────────────────

	public static function setBorderless(borderless:Bool):Void
	{
		_window.borderless = borderless;
	}

	public static function isBorderless():Bool { return _window.borderless; }

	// ─── ALWAYS ON TOP ───────────────────────────────────────────────────

	public static function setAlwaysOnTop(value:Bool):Void
	{
		#if windows
		setAlwaysOnTopWindows(value);
		#end
	}

	#if windows
	@:functionCode("
		HWND hwnd = (HWND)lime::utils::NativePointer::getInt( window );
		SetWindowPos(hwnd, value ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
	")
	static function setAlwaysOnTopWindows(value:Bool):Void {}
	#end

	// ─── RESIZABLE ───────────────────────────────────────────────────────

	public static function setResizable(value:Bool):Void
	{
		_window.resizable = value;
	}

	// ─── ICON ────────────────────────────────────────────────────────────

	/**
	 * Change the window icon at runtime from a PNG file.
	 * path = path relative to assets/ (no extension needed for preloaded assets)
	 */
	public static function setIcon(path:String):Void
	{
		try
		{
			var bytes = openfl.Assets.getBytes(path);
			if (bytes == null) bytes = openfl.Assets.getBytes("assets/preload/images/" + path + ".png");
			if (bytes != null)
			{
				var image = new lime.graphics.Image();
				image.loadFromBytes(bytes);
				_window.setIcon(image);
			}
			else trace('[WindowConfig] Icon not found: $path');
		}
		catch (e:Dynamic)
		{
			trace('[WindowConfig] Error setting icon: $e');
		}
	}

	// ─── FPS ─────────────────────────────────────────────────────────────

	public static function setFPSCap(fps:Int):Void
	{
		_window.frameRate = fps;
		flixel.FlxG.updateFramerate = fps;
		flixel.FlxG.drawFramerate   = fps;
	}

	// ─── FULLSCREEN ──────────────────────────────────────────────────────

	public static function setFullscreen(value:Bool):Void
	{
		_window.fullscreen = value;
	}

	public static function toggleFullscreen():Void
	{
		_window.fullscreen = !_window.fullscreen;
	}

	public static function isFullscreen():Bool { return _window.fullscreen; }

	// ─── APPLY FROM DYNAMIC (used by JSONScriptBackend) ─────────────────

	public static function apply(cfg:Dynamic):Void
	{
		if (cfg == null) return;

		if (Reflect.hasField(cfg, "title"))
			setTitle(cfg.title);

		if (Reflect.hasField(cfg, "width") && Reflect.hasField(cfg, "height"))
			setSize(cfg.width, cfg.height);
		else if (Reflect.hasField(cfg, "width"))
			setWidth(cfg.width);
		else if (Reflect.hasField(cfg, "height"))
			setHeight(cfg.height);

		if (Reflect.hasField(cfg, "fps"))
			setFPSCap(cfg.fps);

		if (Reflect.hasField(cfg, "icon"))
			setIcon(cfg.icon);

		if (Reflect.hasField(cfg, "borderless"))
			setBorderless(cfg.borderless);

		if (Reflect.hasField(cfg, "alwaysOnTop"))
			setAlwaysOnTop(cfg.alwaysOnTop);

		if (Reflect.hasField(cfg, "resizable"))
			setResizable(cfg.resizable);

		if (Reflect.hasField(cfg, "fullscreen"))
			setFullscreen(cfg.fullscreen);

		if (Reflect.hasField(cfg, "transparent"))
		{
			// Note: full transparency requires Project.xml change:
			// <window transparent="true" background="0x00000000" />
			// Runtime alpha uses setAlpha() instead
		}

		if (Reflect.hasField(cfg, "alpha"))
			setAlpha(cfg.alpha);

		if (Reflect.hasField(cfg, "x") && Reflect.hasField(cfg, "y"))
		{
			var x:Int = cfg.x;
			var y:Int = cfg.y;
			if (x == -1 && y == -1) centerWindow();
			else setPosition(x, y);
		}

		trace('[WindowConfig] Applied window config.');
	}
}
