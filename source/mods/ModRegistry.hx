package mods;

import mods.ModMeta;
import scripting.ScriptRegistry;

/**
 * ModRegistry
 * 
 * Holds the active ModMeta and provides convenience accessors.
 * Exposed as GameContext.mods.
 * 
 * ─── Usage ──────────────────────────────────────────────────────────────
 *   var cls = GameContext.mods.getStateClass("mainMenuState", "ui.menu.MainMenuState");
 *   var v   = GameContext.mods.getSetting("myCustomKey");
 *   var bpm = GameContext.mods.bpm;
 */
class ModRegistry
{
    public var meta(default, null):ModMeta;

    public function new(meta:ModMeta)
    {
        this.meta = meta;
    }

    // ─── State class resolution ──────────────────────────────────────────

    /**
     * Resolve a state class from a data.json override key.
     * Falls back to the engine default class name if the override is missing.
     * Uses ScriptRegistry so mod-defined script classes work too.
     * 
     * @param key       ModMeta field name  (e.g. "mainMenuState")
     * @param fallback  Engine default name (e.g. "ui.menu.MainMenuState")
     */
    public function getStateClass(key:String, fallback:String = ""):Class<Dynamic>
    {
        var name:String = Reflect.getProperty(meta, key);
        if (name == null || name == "") name = fallback;
        if (name == null || name == "") return null;

        var cls:Dynamic = ScriptRegistry.resolve(name);
        if (cls == null)
            trace('[ModRegistry] WARNING: Cannot resolve "$name" for key "$key". Is the class compiled in?');

        return cls;
    }

    // ─── Custom settings ────────────────────────────────────────────────

    public function getSetting(key:String):Dynamic
    {
        if (meta.settings == null) return null;
        return Reflect.getProperty(meta.settings, key);
    }

    public function getSettingOr(key:String, fallback:Dynamic):Dynamic
    {
        var v = getSetting(key);
        return v != null ? v : fallback;
    }

    public function flag(key:String):Bool
    {
        var v = getSetting(key);
        if (v == null) return false;
        return v == true || v == "true" || v == "1";
    }

    // ─── Shorthands ──────────────────────────────────────────────────────

    public var title(get,   never):String; function get_title()   return meta.title   != null ? meta.title   : "SinkopesoEngine";
    public var version(get, never):String; function get_version() return meta.version != null ? meta.version : "1.0.0";
    public var bpm(get,     never):Float;  function get_bpm()     return meta.bpm     > 0     ? meta.bpm     : 102;
    public var width(get,   never):Int;    function get_width()   return meta.width   > 0     ? meta.width   : 1280;
    public var height(get,  never):Int;    function get_height()  return meta.height  > 0     ? meta.height  : 720;
    public var devMode(get, never):Bool;   function get_devMode() return meta.developerMode;
    public var hotReload(get,never):Bool;  function get_hotReload() return meta.scriptsHotReloading;
}
