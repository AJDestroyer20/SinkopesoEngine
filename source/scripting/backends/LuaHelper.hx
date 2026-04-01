package scripting.backends;

#if LUA_ALLOWED
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
#end

/**
 * LuaHelper — SinkopesoEngine
 *
 * Reemplazo propio de Lua_helper, que NO existe en linc_luajit.
 * linc_luajit (github.com/superpowers04/linc_luajit) solo expone:
 *   Lua, LuaL, State, Convert.
 *
 * Implementa add_callback(state, name, fn):
 *   Registra una función Haxe como global invocable desde Lua.
 *
 * ─── Mecanismo ────────────────────────────────────────────────────────────
 *   Los callbacks se almacenan en el mapa estático _callbacks con clave
 *   "<stateId>:<nombre>". Un dispatcher C estático (_dispatch) se registra
 *   como closure con ese key como upvalue. Cuando Lua llama la función,
 *   el dispatcher recupera la función Haxe desde _callbacks y la ejecuta
 *   con los argumentos del stack.
 *
 * ─── Uso ──────────────────────────────────────────────────────────────────
 *   LuaHelper.add_callback(lua, "myFunc", function(a:Dynamic, b:Dynamic) {
 *       return a + b;
 *   });
 *   LuaHelper.cleanup(lua); // llamar en destroy()
 */
class LuaHelper
{
	#if LUA_ALLOWED

	/** Mapa global: "<stateId>:<name>" → función Haxe */
	public static var _callbacks:Map<String, Dynamic> = new Map();

	static var _stateCounter:Int = 0;
	static var _stateIds:Map<Int, Int> = new Map();

	/**
	 * Registra una función Haxe como global Lua con el nombre dado.
	 * Usa Lua.pushcclosure con un dispatcher estático + upvalue string.
	 */
	public static function add_callback(lua:State, name:String, fn:Dynamic):Void
	{
		var stateId = _getStateId(lua);
		var key = '$stateId:$name';
		_callbacks.set(key, fn);

		// Empujar el key como upvalue para que _dispatch lo recupere
		Convert.toLua(lua, key);
		// Registrar el dispatcher C con 1 upvalue
		Lua.pushcclosure(lua, cpp.Function.fromStaticFunction(_dispatch), 1);
		Lua.setglobal(lua, name);
	}

	/**
	 * Dispatcher estático: Lua → Haxe.
	 * Lee el upvalue (key), recupera fn, recolecta args, llama fn.
	 */
	@:keep
	static function _dispatch(l:cpp.RawPointer<State>):Int
	{
		var state:State = cast l;

		// Upvalue 1 = key string
		Lua.pushvalue(state, Lua.upvalueindex(1));
		var key:String = Lua.tostring(state, -1);
		Lua.pop(state, 1);

		var fn:Dynamic = _callbacks.get(key);
		if (fn == null) return 0;

		// Recolectar argumentos
		var nargs = Lua.gettop(state);
		var args:Array<Dynamic> = [];
		for (i in 1...(nargs + 1))
			args.push(Convert.fromLua(state, i));

		// Llamar la función Haxe
		var ret:Dynamic = null;
		try
		{
			ret = switch (args.length)
			{
				case 0: fn();
				case 1: fn(args[0]);
				case 2: fn(args[0], args[1]);
				case 3: fn(args[0], args[1], args[2]);
				case 4: fn(args[0], args[1], args[2], args[3]);
				case 5: fn(args[0], args[1], args[2], args[3], args[4]);
				case 6: fn(args[0], args[1], args[2], args[3], args[4], args[5]);
				case 7: fn(args[0], args[1], args[2], args[3], args[4], args[5], args[6]);
				default: Reflect.callMethod(null, fn, args);
			};
		}
		catch (e:Dynamic)
		{
			Lua.pushstring(state, Std.string(e));
			Lua.error(state);
			return 0;
		}

		if (ret == null) return 0;
		Convert.toLua(state, ret);
		return 1;
	}

	/** Devuelve (o crea) el ID entero para este State de Lua. */
	static function _getStateId(lua:State):Int
	{
		var h = lua.hashCode();
		if (!_stateIds.exists(h))
			_stateIds.set(h, _stateCounter++);
		return _stateIds.get(h);
	}

	/**
	 * Limpia todos los callbacks de un State.
	 * Llamar desde LuaScriptBackend.destroy() antes de Lua.close().
	 */
	public static function cleanup(lua:State):Void
	{
		var h = lua.hashCode();
		if (!_stateIds.exists(h)) return;
		var stateId = _stateIds.get(h);
		var prefix = '$stateId:';
		var toRemove = [for (k in _callbacks.keys()) if (k.startsWith(prefix)) k];
		for (k in toRemove) _callbacks.remove(k);
		_stateIds.remove(h);
	}

	#end
}
