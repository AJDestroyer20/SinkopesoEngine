package scripting.backends;

import scripting.IScriptBackend;
import scripting.ScriptManager;
import scripting.backends.LuaHelper;

#if LUA_ALLOWED
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
#end

/**
 * LuaScriptBackend — SinkopesoEngine
 *
 * Ejecuta scripts .lua con una API compatible con Psych Engine.
 * Usa linc_luajit (github.com/superpowers04/linc_luajit).
 *
 * ─── Bugs corregidos ──────────────────────────────────────────────────────
 *   Fix A: Lua_helper no existe en linc_luajit. Reemplazado por
 *          LuaHelper.add_callback() definido en LuaHelper.hx propio.
 *
 *   Fix B: destroy() no limpiaba los callbacks de LuaHelper antes de cerrar
 *          el State — leak en el mapa estático. Añadido LuaHelper.cleanup().
 *
 *   Fix C: Lua.close() no estaba en try/catch — si onDestroy lanzaba
 *          excepción, el State quedaba sin cerrar. Ahora envuelto en try.
 */
class LuaScriptBackend implements IScriptBackend
{
	public var path:String;
	public var destroyed:Bool = false;

	#if LUA_ALLOWED
	var lua:State;
	#end

	// ─── Constructor ─────────────────────────────────────────────────────────

	public function new(path:String)
	{
		this.path = path;
	}

	// ─── Load ────────────────────────────────────────────────────────────────

	public function load():Void
	{
		#if LUA_ALLOWED
		try
		{
			lua = LuaL.newstate();
			LuaL.openlibs(lua);

			injectVariables();
			injectFunctions();

			var result = LuaL.dofile(lua, path);
			if (result != 0)
			{
				var err = Lua.tostring(lua, -1);
				Lua.pop(lua, 1);
				trace('[Lua] ERROR cargando $path: $err');
				Lua.close(lua);
				lua = null;
			}
			else
			{
				trace('[Lua] Cargado: $path');
			}
		}
		catch (e:Dynamic)
		{
			trace('[Lua] EXCEPCIÓN cargando $path: $e');
			if (lua != null) { try { Lua.close(lua); } catch (_:Dynamic) {} lua = null; }
		}
		#else
		trace('[LuaScriptBackend] LUA_ALLOWED no definido — omitiendo $path');
		#end
	}

	// ─── Variable injection ──────────────────────────────────────────────────

	#if LUA_ALLOWED
	function injectVariables():Void
	{
		var game = gameplay.PlayState.instance;

		// ── Constantes de flujo ───────────────────────────────────────────────
		set("Function_Stop",     "Function_Stop");
		set("Function_Continue", "Function_Continue");
		set("Function_StopAll",  "Function_StopAll");
		set("Function_StopLua",  "Function_StopLua");

		// ── Build / versión ───────────────────────────────────────────────────
		set("buildTarget", getBuildTarget());
		set("version",     context.GameContext.ENGINE_VERSION);
		set("scriptName",  path);
		set("scriptPath",  path);

		// ── Pantalla ──────────────────────────────────────────────────────────
		set("screenWidth",  flixel.FlxG.width);
		set("screenHeight", flixel.FlxG.height);

		// ── Conductor / canción ───────────────────────────────────────────────
		set("curBpm",      gameplay.Conductor.bpm);
		set("crochet",     gameplay.Conductor.crochet);
		set("stepCrochet", gameplay.Conductor.stepCrochet);

		if (flixel.FlxG.sound.music != null)
			set("songLength", flixel.FlxG.sound.music.length);

		if (game != null)
		{
			@:privateAccess
			{
				set("bpm",         game.SONG != null ? game.SONG.bpm : 0);
				set("scrollSpeed", game.SONG != null ? game.SONG.speed : 1.0);
				set("songName",    game.SONG != null ? (game.SONG.songName ?? game.SONG.song ?? "") : "");
				set("curSection",  game.curSection);
				set("curBeat",     game.curBeat);
				set("curStep",     game.curStep);
				set("score",       game.songScore);
				set("misses",      game.songMisses);
				set("hits",        game.songHits);
				set("combo",       game.combo);
				set("rating",      game.ratingPercent);
				set("ratingName",  game.ratingName);
				set("ratingFC",    game.ratingFC);
				set("health",      game.health);
				set("botPlay",     game.cpuControlled);
				set("practice",    game.practiceMode);
				set("isStoryMode", gameplay.PlayState.isStoryMode);
			}
		}

		// ── Preferencias ──────────────────────────────────────────────────────
		if (flixel.FlxG.save.data != null)
		{
			set("downscroll",   flixel.FlxG.save.data.downscroll  ?? false);
			set("middlescroll", flixel.FlxG.save.data.middlescroll ?? false);
		}
	}

	function injectFunctions():Void
	{
		// Fix A: LuaHelper.add_callback en lugar del inexistente Lua_helper

		// ── Propiedades ───────────────────────────────────────────────────────
		LuaHelper.add_callback(lua, "setProperty", function(name:String, value:Dynamic) {
			setProp(name, value);
		});
		LuaHelper.add_callback(lua, "getProperty", function(name:String):Dynamic {
			return getProp(name);
		});
		LuaHelper.add_callback(lua, "callMethod", function(name:String, ?args:Array<Dynamic>):Dynamic {
			var target = resolveTarget(name);
			if (target == null) return null;
			var parts = name.split(".");
			var fn = Reflect.getProperty(target, parts[parts.length - 1]);
			if (fn == null) return null;
			return Reflect.callMethod(target, fn, args ?? []);
		});

		// ── Variables compartidas ─────────────────────────────────────────────
		LuaHelper.add_callback(lua, "setVar", function(name:String, value:Dynamic) {
			ScriptManager.globalVars.set(name, value);
		});
		LuaHelper.add_callback(lua, "getVar", function(name:String):Dynamic {
			return ScriptManager.globalVars.get(name);
		});
		LuaHelper.add_callback(lua, "setOnScripts", function(name:String, value:Dynamic) {
			ScriptManager.setVar(name, value);
		});
		LuaHelper.add_callback(lua, "callOnScripts", function(func:String, ?args:Array<Dynamic>):Dynamic {
			ScriptManager.call(func, args ?? []);
			return null;
		});

		// ── Carga de canciones ────────────────────────────────────────────────
		LuaHelper.add_callback(lua, "loadSong", function(?name:String = null, ?diff:Int = -1) {
			if (name == null || name.length < 1)
				name = gameplay.PlayState.instance?.SONG?.song ?? "";
			if (diff < 0) diff = gameplay.PlayState.storyDifficulty;
			var poop = data.Highscore.formatSong(name, diff);
			data.song.Song.loadFromJson(poop, name);
			gameplay.PlayState.storyDifficulty = diff;
			flixel.FlxG.state.persistentUpdate = false;
			core.LoadingState.loadAndSwitchState(new gameplay.PlayState());
		});

		// ── Debug ────────────────────────────────────────────────────────────
		LuaHelper.add_callback(lua, "debugPrint", function(text:Dynamic, ?color:String = "WHITE") {
			var ps = gameplay.PlayState.instance;
			if (ps != null)
				ps.addTextToDebug(Std.string(text), core.CoolUtil.colorFromString(color));
			else
				trace('[Lua] $text');
		});

		// ── Auto-descarga ─────────────────────────────────────────────────────
		LuaHelper.add_callback(lua, "close", function() {
			destroyed = true;
			return true;
		});

		// ── Gestión de scripts ────────────────────────────────────────────────
		LuaHelper.add_callback(lua, "addLuaScript", function(luaFile:String) {
			ScriptManager.loadScript(findScript(luaFile, ".lua"));
		});
		LuaHelper.add_callback(lua, "addHScript", function(hsFile:String) {
			ScriptManager.loadScript(findScript(hsFile, ".hx"));
		});

		// ── Puente HScript ────────────────────────────────────────────────────
		LuaHelper.add_callback(lua, "runHaxeCode", function(code:String, ?vars:Dynamic, ?funcName:String, ?funcArgs:Array<Dynamic>):Dynamic {
			#if HSCRIPT_ALLOWED
			var backend = new HaxeScriptBackend(code);
			backend.load();
			if (funcName != null && funcName.length > 0)
				return backend.call(funcName, funcArgs ?? []);
			return backend.getVar("returnValue");
			#else
			trace('[Lua] runHaxeCode: HSCRIPT_ALLOWED no definido');
			return null;
			#end
		});

		// ── Cámara ────────────────────────────────────────────────────────────
		LuaHelper.add_callback(lua, "cameraFlash", function(color:Int, duration:Float) {
			flixel.FlxG.camera.flash(color, duration);
		});
		LuaHelper.add_callback(lua, "cameraShake", function(intensity:Float, duration:Float) {
			flixel.FlxG.camera.shake(intensity, duration);
		});
		LuaHelper.add_callback(lua, "cameraZoom", function(zoom:Float, ?lerp:Float = 0.05) {
			// Delegado a CameraController en Session 2
			flixel.FlxG.camera.zoom = zoom;
		});
	}

	// ─── Utilidades ──────────────────────────────────────────────────────────

	function set(name:String, value:Dynamic):Void
	{
		Convert.toLua(lua, value);
		Lua.setglobal(lua, name);
	}

	function setProp(dotPath:String, value:Dynamic):Void
	{
		var target = resolveTarget(dotPath);
		if (target == null) return;
		var parts = dotPath.split(".");
		Reflect.setProperty(target, parts[parts.length - 1], value);
	}

	function getProp(dotPath:String):Dynamic
	{
		var target = resolveTarget(dotPath);
		if (target == null) return null;
		var parts = dotPath.split(".");
		return Reflect.getProperty(target, parts[parts.length - 1]);
	}

	function resolveTarget(dotPath:String):Dynamic
	{
		var parts = dotPath.split(".");
		var obj:Dynamic = gameplay.PlayState.instance ?? flixel.FlxG.state;
		if (obj == null) return null;
		for (i in 0...parts.length - 1)
		{
			obj = Reflect.getProperty(obj, parts[i]);
			if (obj == null) return null;
		}
		return obj;
	}

	function findScript(file:String, ext:String = ".lua"):String
	{
		if (!file.endsWith(ext)) file += ext;
		#if FEATURE_FILESYSTEM
		if (sys.FileSystem.exists(file)) return file;
		var inAssets = "assets/" + file;
		if (sys.FileSystem.exists(inAssets)) return inAssets;
		#end
		return file;
	}

	static function getBuildTarget():String
	{
		#if windows  return "windows";
		#elseif mac  return "mac";
		#elseif linux return "linux";
		#elseif android return "android";
		#elseif ios  return "ios";
		#elseif html5 return "html5";
		#else        return "unknown";
		#end
	}
	#end

	// ─── Call ────────────────────────────────────────────────────────────────

	public function call(func:String, args:Array<Dynamic>):Dynamic
	{
		#if LUA_ALLOWED
		if (destroyed || lua == null) return null;
		try
		{
			Lua.getglobal(lua, func);
			if (!Lua.isfunction(lua, -1))
			{
				Lua.pop(lua, 1);
				return null;
			}
			for (a in args) Convert.toLua(lua, a);
			var result = Lua.pcall(lua, args.length, 1, 0);
			if (result != 0)
			{
				var err = Lua.tostring(lua, -1);
				Lua.pop(lua, 1);
				trace('[Lua] ERROR llamando $func en $path: $err');
				return null;
			}
			var ret = Convert.fromLua(lua, -1);
			Lua.pop(lua, 1);
			return ret;
		}
		catch (e:Dynamic)
		{
			trace('[Lua] EXCEPCIÓN llamando $func en $path: $e');
		}
		#end
		return null;
	}

	// ─── Variables ───────────────────────────────────────────────────────────

	public function setVar(name:String, value:Dynamic):Void
	{
		#if LUA_ALLOWED
		if (destroyed || lua == null) return;
		Convert.toLua(lua, value);
		Lua.setglobal(lua, name);
		#end
	}

	public function getVar(name:String):Dynamic
	{
		#if LUA_ALLOWED
		if (destroyed || lua == null) return null;
		Lua.getglobal(lua, name);
		var v = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);
		return v;
		#else
		return null;
		#end
	}

	// ─── Destroy ─────────────────────────────────────────────────────────────

	/**
	 * Fix B + C: LuaHelper.cleanup() limpia el mapa de callbacks antes de
	 * cerrar el State. Lua.close() envuelto en try/catch para garantizar
	 * limpieza aunque onDestroy falle.
	 */
	public function destroy():Void
	{
		call("onDestroy", []);
		destroyed = true;
		#if LUA_ALLOWED
		if (lua != null)
		{
			try
			{
				LuaHelper.cleanup(lua);
				Lua.close(lua);
			}
			catch (e:Dynamic)
			{
				trace('[Lua] ERROR cerrando state de $path: $e');
			}
			lua = null;
		}
		#end
	}
}
