package systems.scripting;

#if LUA_ALLOWED
import llua.Lua;
import llua.State;
#end

class LuaCallbackHandler
{
	#if LUA_ALLOWED
	public static function call(L:State):Int
	{
		var functionName:String = Lua.tostring(L, -1);
		
		trace('Lua callback: $functionName');
		
		return 0;
	}
	#end
}
