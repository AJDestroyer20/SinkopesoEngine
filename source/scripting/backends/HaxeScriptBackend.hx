package scripting.backends;

import scripting.IScriptBackend;
import scripting.ScriptManager;

#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
import crowplexus.iris.IrisConfig;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

/**
 * HaxeScriptBackend — SinkopesoEngine
 *
 * Ejecuta archivos .hx / .hscript con hscript-iris 1.1.3.
 *   Instalar: haxelib git hscript-iris https://github.com/crowplexus/hscript-iris
 *
 * ─── Bugs corregidos ──────────────────────────────────────────────────────
 *   Fix A: destroy() ponía destroyed=true ANTES de call("onDestroy"), lo
 *          que hacía que el guard `if (destroyed)` bloqueara el call y
 *          onDestroy nunca se ejecutara. Orden correcto:
 *          call("onDestroy") → destroyed=true → iris.destroy().
 *
 *   Fix B: _resolvePath() sin null guard en el objeto raíz — crash si
 *          PlayState.instance y FlxG.state son ambos null en boot temprano.
 *
 *   Fix C: state/game inyectados como getters dinámicos, no referencias
 *          stale capturadas en load-time.
 */
class HaxeScriptBackend implements IScriptBackend
{
	public var path:String;
	public var destroyed:Bool = false;

	#if HSCRIPT_ALLOWED
	var iris:Iris;
	#end

	public function new(path:String)
	{
		this.path = path;
	}

	// ─── Load ─────────────────────────────────────────────────────────────────

	public function load():Void
	{
		#if HSCRIPT_ALLOWED
		try
		{
			var code:String = null;

			if (path != null && !path.contains("\n"))
			{
				#if FEATURE_FILESYSTEM
				if (sys.FileSystem.exists(path))
					code = sys.io.File.getContent(path);
				else
				#end
				try { code = openfl.Assets.getText(path); } catch (_:Dynamic) {}
			}
			else
			{
				code = path; // ejecución inline
			}

			if (code == null || code.length == 0)
			{
				trace('[HaxeScriptBackend] WARNING: script vacío o inexistente: $path');
				return;
			}

			iris = new Iris(code, new IrisConfig(path, false, false));
			preset();
			iris.execute();
		}
		catch (e:IrisError)
		{
			trace('[HaxeScriptBackend] PARSE ERROR en $path:\n  ' + Printer.errorToString(e, false));
			iris = null;
		}
		catch (e:Dynamic)
		{
			trace('[HaxeScriptBackend] ERROR cargando $path: $e');
			iris = null;
		}
		#else
		trace('[HaxeScriptBackend] HSCRIPT_ALLOWED no definido — omitiendo $path');
		#end
	}

	// ─── Preset ───────────────────────────────────────────────────────────────

	#if HSCRIPT_ALLOWED
	function preset():Void
	{
		if (iris == null) return;

		// ── Flixel ────────────────────────────────────────────────────────────
		iris.set("FlxG",           flixel.FlxG);
		iris.set("FlxSprite",      flixel.FlxSprite);
		iris.set("FlxText",        flixel.text.FlxText);
		iris.set("FlxCamera",      flixel.FlxCamera);
		iris.set("FlxTimer",       flixel.util.FlxTimer);
		iris.set("FlxTween",       flixel.tweens.FlxTween);
		iris.set("FlxEase",        flixel.tweens.FlxEase);
		iris.set("FlxColor",       flixel.util.FlxColor);
		iris.set("FlxMath",        flixel.math.FlxMath);
		iris.set("FlxSound",       flixel.sound.FlxSound);
		iris.set("FlxBasic",       flixel.FlxBasic);
		iris.set("FlxGroup",       flixel.group.FlxGroup);
		iris.set("FlxSpriteGroup", flixel.group.FlxSpriteGroup);

		// ── Engine ────────────────────────────────────────────────────────────
		iris.set("Paths",     core.Paths);
		iris.set("CoolUtil",  core.CoolUtil);
		iris.set("Conductor", gameplay.Conductor);
		iris.set("PlayState", gameplay.PlayState);
		iris.set("Note",      gameplay.notes.Note);

		// ── Context ───────────────────────────────────────────────────────────
		iris.set("GameContext",  context.GameContext);
		iris.set("AudioManager", context.AudioManager);
		iris.set("EventBus",     context.EventBus);
		iris.set("BusEvents",    context.EventBus.BusEvents);

		// Fix C: getters dinámicos — siempre retornan la instancia actual
		iris.set("getState", function():Dynamic return flixel.FlxG.state);
		iris.set("getGame",  function():Dynamic return gameplay.PlayState.instance);
		// Alias legacy (pueden quedar stale tras cambio de estado)
		iris.set("state", flixel.FlxG.state);
		iris.set("game",  gameplay.PlayState.instance);

		// ── Stdlib ────────────────────────────────────────────────────────────
		iris.set("Math",        Math);
		iris.set("Std",         Std);
		iris.set("StringTools", StringTools);
		iris.set("Type",        Type);
		iris.set("Reflect",     Reflect);
		iris.set("Json",        haxe.Json);
		iris.set("Assets",      openfl.Assets);

		// ── Registro de clases ────────────────────────────────────────────────
		iris.set("registerClass", function(name:String, cls:Dynamic) {
			ScriptManager.globalVars.set("_class_" + name, cls);
			scripting.ScriptRegistry.register(name, cls);
			trace('[HScript] Clase registrada: $name');
		});

		// ── Navegación de estados ─────────────────────────────────────────────
		iris.set("switchState", function(name:String) {
			var cls = Type.resolveClass(name);
			if (cls == null) cls = ScriptManager.globalVars.get("_class_" + name);
			if (cls != null) flixel.FlxG.switchState(Type.createInstance(cls, []));
			else trace('[HScript] switchState: no se puede resolver "$name"');
		});
		iris.set("openSubState", function(name:String, ?args:Array<Dynamic>) {
			var cls = Type.resolveClass(name);
			if (cls == null) cls = ScriptManager.globalVars.get("_class_" + name);
			if (cls != null) flixel.FlxG.state.openSubState(Type.createInstance(cls, args != null ? args : []));
		});

		// ── Helpers estilo Psych ──────────────────────────────────────────────
		iris.set("setProperty", function(dotPath:String, value:Dynamic) {
			var t = _resolvePath(dotPath);
			if (t != null) Reflect.setProperty(t.obj, t.field, value);
		});
		iris.set("getProperty", function(dotPath:String):Dynamic {
			var t = _resolvePath(dotPath);
			return t != null ? Reflect.getProperty(t.obj, t.field) : null;
		});
		iris.set("callMethod", function(dotPath:String, ?args:Array<Dynamic>):Dynamic {
			var t = _resolvePath(dotPath);
			if (t == null) return null;
			var fn = Reflect.getProperty(t.obj, t.field);
			return fn != null ? Reflect.callMethod(t.obj, fn, args != null ? args : []) : null;
		});
		iris.set("addObject", function(tag:String, obj:flixel.FlxBasic) {
			ScriptManager.globalVars.set(tag, obj);
			flixel.FlxG.state.add(obj);
		});
		iris.set("removeObject", function(tag:String) {
			var obj = ScriptManager.globalVars.get(tag);
			if (obj != null) { flixel.FlxG.state.remove(obj); ScriptManager.globalVars.remove(tag); }
		});
		iris.set("createInstance", function(name:String, ?args:Array<Dynamic>):Dynamic {
			var cls = Type.resolveClass(name);
			if (cls == null) cls = ScriptManager.globalVars.get("_class_" + name);
			return cls != null ? Type.createInstance(cls, args != null ? args : []) : null;
		});

		// ── Variables compartidas ─────────────────────────────────────────────
		iris.set("setVar", function(name:String, v:Dynamic) ScriptManager.globalVars.set(name, v));
		iris.set("getVar", function(name:String):Dynamic   return ScriptManager.globalVars.get(name));

		// ── Debug ────────────────────────────────────────────────────────────
		iris.set("trace", function(msg:Dynamic) {
			var ps = gameplay.PlayState.instance;
			if (ps != null) ps.addTextToDebug(Std.string(msg), flixel.util.FlxColor.WHITE);
			else haxe.Log.trace(Std.string(msg), null);
		});

		// ── Constantes de flujo ───────────────────────────────────────────────
		iris.set("Function_Stop",     "Function_Stop");
		iris.set("Function_Continue", "Function_Continue");
		iris.set("Function_StopAll",  "Function_StopAll");

		iris.set("scriptPath", path);
		iris.set("scriptName", path);
	}

	// Fix B: null guard en el objeto raíz
	static function _resolvePath(dotPath:String):Null<{ obj:Dynamic, field:String }>
	{
		var parts = dotPath.split(".");
		var obj:Dynamic = gameplay.PlayState.instance != null
			? gameplay.PlayState.instance
			: flixel.FlxG.state;

		if (obj == null) return null;

		for (i in 0...parts.length - 1)
		{
			obj = Reflect.getProperty(obj, parts[i]);
			if (obj == null) return null;
		}
		return { obj: obj, field: parts[parts.length - 1] };
	}
	#end

	// ─── Call ─────────────────────────────────────────────────────────────────

	public function call(func:String, args:Array<Dynamic>):Dynamic
	{
		#if HSCRIPT_ALLOWED
		if (destroyed || iris == null) return null;
		try
		{
			if (!iris.exists(func)) return null;
			var result = iris.call(func, args);
			return result != null ? result.returnValue : null;
		}
		catch (e:IrisError)
		{
			trace('[HaxeScriptBackend] ERROR llamando $func en $path:\n  ' + Printer.errorToString(e, false));
		}
		catch (e:Dynamic)
		{
			trace('[HaxeScriptBackend] EXCEPCIÓN llamando $func en $path: $e');
		}
		#end
		return null;
	}

	// ─── Variables ────────────────────────────────────────────────────────────

	public function setVar(name:String, value:Dynamic):Void
	{
		#if HSCRIPT_ALLOWED
		if (destroyed || iris == null) return;
		iris.set(name, value);
		#end
	}

	public function getVar(name:String):Dynamic
	{
		#if HSCRIPT_ALLOWED
		if (destroyed || iris == null) return null;
		return iris.exists(name) ? iris.get(name) : null;
		#else
		return null;
		#end
	}

	// ─── Destroy ──────────────────────────────────────────────────────────────

	/**
	 * Fix A: orden correcto — call("onDestroy") primero, destroyed=true después.
	 * El orden anterior impedía que onDestroy se ejecutara por el guard de call().
	 */
	public function destroy():Void
	{
		call("onDestroy", []);
		destroyed = true;
		#if HSCRIPT_ALLOWED
		if (iris != null) { iris.destroy(); iris = null; }
		#end
	}
}
