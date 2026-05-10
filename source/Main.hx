package;

import lime.app.Application;
import haxe.io.Path;
import flixel.FlxGame;
import openfl.display.Sprite;
import openfl.Lib;
import openfl.events.Event;
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import states.TitleState;
import backend.Preferences;

#if (windows && cpp)
@:buildXml('
<target id="haxe">
	<lib name="wininet.lib" if="windows" />
	<lib name="dwmapi.lib" if="windows" />
</target>
')

@:cppFileCode('
#include <windows.h>
#include <winuser.h>
#pragma comment(lib, "Shell32.lib")
extern "C" HRESULT WINAPI SetCurrentProcessExplicitAppUserModelID(PCWSTR AppID);
')
#end

#if linux
import lime.graphics.Image;
#end

class Main extends Sprite
{
	private static var game = {
		width: 1280,
		height: 720,
		initialState: TitleState,
		zoom: -1.0,
		framerate: 120,
		skipSplash: true,
		startFullscreen: false
	};

	public static function main():Void
	{
		Lib.current.addChild(new Main());

		Lib.application.window.onClose.add(function()
		{
			Preferences.save();
		});
	}

	public function new()
	{
		super();

		#if (windows && cpp)
		untyped __cpp__("SetProcessDPIAware();");

		FlxG.stage.window.borderless = true;
		FlxG.stage.window.borderless = false;

		Application.current.window.x = Std.int((Application.current.window.display.bounds.width - Application.current.window.width) / 2);
		Application.current.window.y = Std.int((Application.current.window.display.bounds.height - Application.current.window.height) / 2);
		#end

		if (stage == null)
			addEventListener(Event.ADDED_TO_STAGE, init);
		else
			init();
	}

	private function init(?event:Event):Void
	{
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);

		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (game.zoom == -1.0)
		{
			var ratioX:Float = stageWidth / game.width;
			var ratioY:Float = stageHeight / game.height;

			game.zoom = Math.min(ratioX, ratioY);
			game.width = Math.ceil(stageWidth / game.zoom);
			game.height = Math.ceil(stageHeight / game.zoom);
		}

		#if !cpp
		game.framerate = 60;
		#end

		#if LUA_ALLOWED
		llua.Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(systems.scripting.LuaCallbackHandler.call));
		#end

		addChild(new FlxGame(game.width, game.height, game.initialState, game.framerate, game.framerate, game.skipSplash, game.startFullscreen));
		
		#if linux
		openfl.Lib.current.stage.window.setIcon(lime.graphics.Image.fromFile(utils.Paths.getPath('images/appIcon.png')));
		#end

		#if html5
		FlxG.autoPause = false;
		#end

		FlxG.mouse.useSystemCursor = true;
		
		#if !mobile
		var fpsCounter:utils.FPSCounter = new utils.FPSCounter(10, 3);
		addChild(fpsCounter);
		#end

		FlxG.signals.gameResized.add(function (width:Float, height:Float)
		{
			if (FlxG.cameras != null)
			{
				for (cam in FlxG.cameras.list)
				{
					if (cam != null && cam.filters != null)
					{
						resetSpriteCache(cam.flashSprite);
					}
				}
			}

			if (FlxG.game != null)
				resetSpriteCache(FlxG.game);
		});
	}
	
	private static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess
		{
		    sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}
	
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: " + e.error;
	
		#if (windows && cpp)
		cpp.WindowsAPI.showMessageBox('Engine Crash', errMsg, cpp.MessageBoxIcon.ERROR);
		#else
		Application.current.window.alert(errMsg, 'Engine Crash');
		#end

		trace(errMsg);

		#if FEATURE_DISCORD
		backend.Discord.shutdown();
		#end

		Sys.exit(1);
	}
}
