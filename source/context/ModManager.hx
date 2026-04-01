package context;

import mods.ModMeta;
import scripting.ScriptRegistry;

/**
 * ModManager
 * 
 * Exposes the loaded data.json metadata to all engine systems.
 * Used by GameContext as GameContext.mods.
 * 
 * ─── Usage ──────────────────────────────────────────────────────────────
 *   var title  = GameContext.mods.meta.title;
 *   var cls    = GameContext.mods.getStateClass("mainMenuState");
 *   var val    = GameContext.mods.getSetting("myKey");
 */
class ModManager
{
    // ─── State ───────────────────────────────────────────────────────────

    public var meta(default, null):ModMeta;

    // ─── Constructor ─────────────────────────────────────────────────────

    public function new(meta:ModMeta)
    {
        this.meta = meta;
    }

    // ─── State class resolution ──────────────────────────────────────────

    /**
     * Resolve a state class from a data.json key.
     * Falls back to the engine default if the override is null or unresolvable.
     * 
     * @param key       Field name in ModMeta (e.g. "mainMenuState")
     * @param fallback  Default class name string (e.g. "ui.menu.MainMenuState")
     * @return          The resolved class, or null
     */
    public function getStateClass(key:String, fallback:String = ""):Class<Dynamic>
    {
        var name:String = Reflect.getProperty(meta, key);
        if (name == null || name.length == 0)
            name = fallback;

        if (name == null || name.length == 0)
            return null;

        var cls = ScriptRegistry.resolve(name);
        if (cls == null)
            trace('[ModManager] WARNING: Could not resolve state class "$name" for key "$key"');
        return cls;
    }

    // ─── Settings ────────────────────────────────────────────────────────

    /**
     * Get a value from the mod's custom settings object in data.json.
     * Returns null if the key doesn't exist.
     */
    public function getSetting(key:String):Dynamic
    {
        if (meta.settings == null) return null;
        return Reflect.getProperty(meta.settings, key);
    }

    /**
     * Get a setting with a default fallback.
     */
    public function getSettingOr(key:String, defaultVal:Dynamic):Dynamic
    {
        var v = getSetting(key);
        return v != null ? v : defaultVal;
    }

    /**
     * Check a boolean setting (safe — returns false if missing).
     */
    public function flag(key:String):Bool
    {
        var v = getSetting(key);
        if (v == null) return false;
        if (Std.is(v, Bool)) return cast(v, Bool);
        return v == "true" || v == "1";
    }

    // ─── Shorthands ──────────────────────────────────────────────────────

    public var title(get,   never):String; inline function get_title()   return meta.title   ?? "SinkopesoEngine";
    public var version(get, never):String; inline function get_version() return meta.version ?? "1.0.0";
    public var bpm(get,     never):Float;  inline function get_bpm()     return meta.bpm     > 0 ? meta.bpm : 102;
    public var width(get,   never):Int;    inline function get_width()   return meta.width   > 0 ? meta.width : 1280;
    public var height(get,  never):Int;    inline function get_height()  return meta.height  > 0 ? meta.height : 720;
    public var devMode(get, never):Bool;   inline function get_devMode() return meta.developerMode;
}
