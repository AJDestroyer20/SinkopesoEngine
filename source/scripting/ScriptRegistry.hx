package scripting;

/**
 * ScriptRegistry
 * 
 * Bridge between string class names and actual Class<T> references.
 * Used by ModRegistry, ScriptableState, and HaxeScriptBackend.
 * 
 * ─── Registration ────────────────────────────────────────────────────────
 *   // In a script file (HaxeScript):
 *   class MyCoolMenu extends ScriptableState { ... }
 *   registerClass("MyCoolMenu", MyCoolMenu);  // injected function
 * 
 *   // In data.json:
 *   "mainMenuState": "MyCoolMenu"
 * 
 * ─── Resolution ──────────────────────────────────────────────────────────
 *   var cls = ScriptRegistry.resolve("PlayState");
 *   // Checks: script classes → engine short names → full package paths
 */
class ScriptRegistry
{
    // ─── Script-defined classes ──────────────────────────────────────────

    static var _scriptClasses:Map<String, Dynamic> = new Map();

    /**
     * Register a class from a script so it can be resolved by name.
     * Called automatically when HaxeScriptBackend sees a class definition.
     */
    public static function register(name:String, cls:Dynamic):Void
    {
        _scriptClasses.set(name, cls);
        trace('[ScriptRegistry] Registered: $name');
    }

    /**
     * Remove a script-defined class (e.g. when its script is unloaded).
     */
    public static function unregister(name:String):Void
    {
        _scriptClasses.remove(name);
    }

    /**
     * Resolve a class name to its Class reference.
     * Search order:
     *   1. Script-defined classes (registered via register())
     *   2. Type.resolveClass() with the exact name
     *   3. Known engine package prefixes
     * Returns null if not found.
     */
    public static function resolve(name:String):Dynamic
    {
        if (name == null || name == "") return null;

        // 1. Script-registered
        if (_scriptClasses.exists(name))
            return _scriptClasses.get(name);

        // 2. Exact class path
        var cls:Dynamic = Type.resolveClass(name);
        if (cls != null) return cls;

        // 3. Known engine packages
        for (pkg in ENGINE_PACKAGES)
        {
            cls = Type.resolveClass(pkg + name);
            if (cls != null) return cls;
        }

        return null;
    }

    /**
     * Try to resolve a class and instantiate it with no arguments.
     * Returns null if unresolvable.
     */
    public static function createInstance(name:String, ?args:Array<Dynamic>):Dynamic
    {
        var cls = resolve(name);
        if (cls == null) return null;
        return Type.createInstance(cls, args ?? []);
    }

    /**
     * Returns all engine classes available for injection into scripts.
     * Used by HaxeScriptBackend to mass-inject globals.
     */
    public static function getAllEngineClasses():Array<{ name:String, ref:Dynamic }>
    {
        var result = [];

        // Core flixel
        result.push({ name: "FlxG",         ref: flixel.FlxG });
        result.push({ name: "FlxSprite",     ref: flixel.FlxSprite });
        result.push({ name: "FlxText",       ref: flixel.text.FlxText });
        result.push({ name: "FlxCamera",     ref: flixel.FlxCamera });
        result.push({ name: "FlxTimer",      ref: flixel.util.FlxTimer });
        result.push({ name: "FlxTween",      ref: flixel.tweens.FlxTween });
        result.push({ name: "FlxEase",       ref: flixel.tweens.FlxEase });
        result.push({ name: "FlxColor",      ref: flixel.util.FlxColor });
        result.push({ name: "FlxMath",       ref: flixel.math.FlxMath });
        result.push({ name: "FlxSound",      ref: flixel.sound.FlxSound });
        result.push({ name: "FlxBasic",      ref: flixel.FlxBasic });
        result.push({ name: "FlxObject",     ref: flixel.FlxObject });
        result.push({ name: "FlxGroup",      ref: flixel.group.FlxGroup });
        result.push({ name: "FlxSpriteGroup",ref: flixel.group.FlxSpriteGroup });

        // Engine core
        result.push({ name: "Paths",           ref: core.Paths });
        result.push({ name: "CoolUtil",        ref: core.CoolUtil });
        result.push({ name: "Debug",           ref: core.Debug });
        result.push({ name: "GameDimensions",  ref: core.GameDimensions });
        result.push({ name: "HelperFunctions", ref: core.HelperFunctions });

        // Gameplay — frozen files, safe to expose
        result.push({ name: "Conductor",       ref: gameplay.Conductor });
        result.push({ name: "PlayState",       ref: gameplay.PlayState });
        result.push({ name: "Note",            ref: gameplay.notes.Note });

        // Context
        result.push({ name: "GameContext",     ref: context.GameContext });
        result.push({ name: "AudioManager",    ref: context.AudioManager });
        result.push({ name: "EventBus",        ref: context.EventBus });
        result.push({ name: "BusEvents",       ref: context.BusEvents });

        // Scripting
        result.push({ name: "ScriptRegistry",  ref: scripting.ScriptRegistry });
        result.push({ name: "ScriptManager",   ref: scripting.ScriptManager });

        // Stdlib
        result.push({ name: "Math",            ref: Math });
        result.push({ name: "Std",             ref: Std });
        result.push({ name: "StringTools",     ref: StringTools });
        result.push({ name: "Type",            ref: Type });
        result.push({ name: "Reflect",         ref: Reflect });
        result.push({ name: "Json",            ref: haxe.Json });

        // openfl
        result.push({ name: "Assets",          ref: openfl.Assets });
        result.push({ name: "Lib",             ref: openfl.Lib });

        // Script base classes (for extending in scripts)
        result.push({ name: "ScriptableState",    ref: scripting.ScriptableState });
        result.push({ name: "ScriptableSubstate", ref: scripting.ScriptableSubstate });

        return result;
    }

    // ─── Package search order ────────────────────────────────────────────

    static final ENGINE_PACKAGES:Array<String> = [
        "",                 // bare name (already tried above but belt-and-suspenders)
        "ui.menu.",
        "ui.",
        "gameplay.",
        "gameplay.notes.",
        "gameplay.characters.",
        "gameplay.stage.",
        "gameplay.ai.",
        "gameplay.cinematic.",
        "gameplay.events.",
        "gameplay.systems.",
        "audio.",
        "gfx.",
        "core.",
        "data.song.",
        "input.",
        "api.",
        "scripting.",
        "context.",
        "mods.",
        "plugins.",
        "editor.",
    ];
}
