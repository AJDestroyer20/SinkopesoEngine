package systems.scripting;

#if LUA_ALLOWED
import llua.Lua;
import llua.State;
import llua.Convert;
#end

class LuaScript
{
	#if LUA_ALLOWED
	public var lua:State;
	public var scriptName:String = '';
	
	public var active:Bool = true;
	
	public function new(script:String)
	{
		lua = LuaL.newstate();
		LuaL.openlibs(lua);
		
		scriptName = script;
		
		var result:Int = LuaL.dofile(lua, script);
		
		if (result != 0)
		{
			trace('Lua Error: ' + Lua.tostring(lua, -1));
			lua = null;
			return;
		}
		
		trace('Lua script loaded: $script');
		
		setupGlobals();
	}
	
	private function setupGlobals():Void
	{
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);
		
		Lua.pushcfunction(lua, luaTrace);
		Lua.setglobal(lua, 'trace');
		
		Lua.pushcfunction(lua, luaGetProperty);
		Lua.setglobal(lua, 'getProperty');
		
		Lua.pushcfunction(lua, luaSetProperty);
		Lua.setglobal(lua, 'setProperty');
	}
	
	public function call(func:String, args:Array<Dynamic>):Dynamic
	{
		if (lua == null || !active)
			return null;
		
		Lua.getglobal(lua, func);
		
		for (arg in args)
		{
			Convert.toLua(lua, arg);
		}
		
		var status:Int = Lua.pcall(lua, args.length, 1, 0);
		
		if (status != 0)
		{
			var error:String = Lua.tostring(lua, -1);
			trace('Lua Error calling $func: $error');
			Lua.pop(lua, 1);
			return null;
		}
		
		var result:Dynamic = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);
		
		return result;
	}
	
	public function set(variable:String, value:Dynamic):Void
	{
		if (lua == null)
			return;
		
		Convert.toLua(lua, value);
		Lua.setglobal(lua, variable);
	}
	
	public function get(variable:String):Dynamic
	{
		if (lua == null)
			return null;
		
		Lua.getglobal(lua, variable);
		var result:Dynamic = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);
		
		return result;
	}
	
	private static function luaTrace(L:State):Int
	{
		var str:String = Lua.tostring(L, -1);
		trace('[LUA] ' + str);
		return 0;
	}
	
	private static function luaGetProperty(L:State):Int
	{
		var obj:String = Lua.tostring(L, 1);
		var field:String = Lua.tostring(L, 2);
		
		var value:Dynamic = Reflect.getProperty(PlayState.instance, obj);
		if (value != null && field != null)
			value = Reflect.getProperty(value, field);
		
		Convert.toLua(L, value);
		return 1;
	}
	
	private static function luaSetProperty(L:State):Int
	{
		var obj:String = Lua.tostring(L, 1);
		var field:String = Lua.tostring(L, 2);
		var value:Dynamic = Convert.fromLua(L, 3);
		
		var object:Dynamic = Reflect.getProperty(PlayState.instance, obj);
		if (object != null)
			Reflect.setProperty(object, field, value);
		
		return 0;
	}
	
	public function stop():Void
	{
		active = false;
		
		if (lua != null)
		{
			Lua.close(lua);
			lua = null;
		}
	}
	
	#else
	
	public var scriptName:String = '';
	public var active:Bool = false;
	
	public function new(script:String)
	{
		trace('Lua scripting not enabled');
	}
	
	public function call(func:String, args:Array<Dynamic>):Dynamic { return null; }
	public function set(variable:String, value:Dynamic):Void {}
	public function get(variable:String):Dynamic { return null; }
	public function stop():Void {}
	
	#end
}
