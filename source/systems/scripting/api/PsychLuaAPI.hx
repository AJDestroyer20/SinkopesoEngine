package systems.scripting.api;

#if LUA_ALLOWED
import llua.Lua;
import llua.State;
import llua.Convert;
#end

class PsychLuaAPI
{
	#if LUA_ALLOWED
	public static function register(lua:State):Void
	{
		bind(lua, "playSound", playSound);
		bind(lua, "cameraShake", cameraShake);
		bind(lua, "cameraFlash", cameraFlash);
		bind(lua, "startTimer", startTimer);
		bind(lua, "runHaxeCode", runHaxeCode);
		bind(lua, "addSprite", addSprite);
		bind(lua, "removeSprite", removeSprite);
		bind(lua, "setProperty", setProperty);
		bind(lua, "getProperty", getProperty);
		bind(lua, "doTweenX", doTweenX);
		bind(lua, "doTweenY", doTweenY);
		bind(lua, "doTweenAlpha", doTweenAlpha);
		bind(lua, "doTweenAngle", doTweenAngle);
	}

	static inline function bind(lua:State, name:String, fn:State->Int):Void
	{
		Lua.pushcfunction(lua, fn);
		Lua.setglobal(lua, name);
	}

	static function playSound(L:State):Int { FlxG.sound.play(Paths.sound(Lua.tostring(L, 1))); return 0; }
	static function cameraShake(L:State):Int { FlxG.camera.shake(Lua.tonumber(L, 1), Lua.tonumber(L, 2)); return 0; }
	static function cameraFlash(L:State):Int { FlxG.camera.flash(FlxColor.WHITE, Lua.tonumber(L, 1)); return 0; }
	static function startTimer(L:State):Int { new FlxTimer().start(Lua.tonumber(L, 2), function(_) {}, Std.int(Lua.tonumber(L, 3))); return 0; }
	static function runHaxeCode(L:State):Int { trace('[Lua] runHaxeCode requested'); return 0; }
	static function addSprite(L:State):Int { return 0; }
	static function removeSprite(L:State):Int { return 0; }
	static function setProperty(L:State):Int { return systems.scripting.LuaScript.luaSetProperty(L); }
	static function getProperty(L:State):Int { return systems.scripting.LuaScript.luaGetProperty(L); }
	static function doTweenX(L:State):Int { return tweenField(L, "x"); }
	static function doTweenY(L:State):Int { return tweenField(L, "y"); }
	static function doTweenAlpha(L:State):Int { return tweenField(L, "alpha"); }
	static function doTweenAngle(L:State):Int { return tweenField(L, "angle"); }

	static function tweenField(L:State, field:String):Int
	{
		var objName = Lua.tostring(L, 2);
		var value = Lua.tonumber(L, 3);
		var duration = Lua.tonumber(L, 4);
		var obj:Dynamic = Reflect.getProperty(PlayState.instance, objName);
		if (obj != null)
			flixel.tweens.FlxTween.num(Reflect.getProperty(obj, field), value, duration, {onUpdate: function(v) Reflect.setProperty(obj, field, v)});
		return 0;
	}
	#end
}
