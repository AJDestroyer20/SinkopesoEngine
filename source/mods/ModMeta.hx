package mods;

/**
 * ModMeta
 * 
 * Typed representation of data.json.
 * Loaded once at startup by GameContext.init().
 * 
 * All fields are optional — missing fields fall back to defaults.
 * See ModMeta.defaults() for the baseline values.
 */
typedef ModMeta =
{
    // ─── Identity ─────────────────────────────────────────────────────────
    @:optional var title:String;
    @:optional var version:String;
    @:optional var engineVersion:String;
    @:optional var icon:String;
    @:optional var description:String;
    @:optional var author:String;

    // ─── Window ───────────────────────────────────────────────────────────
    @:optional var width:Int;
    @:optional var height:Int;

    // ─── Music ────────────────────────────────────────────────────────────
    @:optional var bpm:Float;

    // ─── State overrides (class names resolved via ScriptRegistry) ─────────
    @:optional var initialState:String;
    @:optional var mainMenuState:String;
    @:optional var freeplayState:String;
    @:optional var storyMenuState:String;
    @:optional var masterEditorMenu:String;
    @:optional var pauseSubState:String;
    @:optional var gameOverScreen:String;
    @:optional var transition:String;

    // ─── Content flags ────────────────────────────────────────────────────
    @:optional var loadDefaultWeeks:Bool;

    // ─── Dev flags ────────────────────────────────────────────────────────
    @:optional var developerMode:Bool;
    @:optional var mobileDebug:Bool;
    @:optional var scriptsHotReloading:Bool;

    // ─── API keys ─────────────────────────────────────────────────────────
    @:optional var discordID:String;

    // ─── Free-form mod settings ───────────────────────────────────────────
    // Access via GameContext.mods.getSetting("key")
    @:optional var settings:Dynamic;
}

/**
 * Helper functions for ModMeta.
 */
class ModMetaHelper
{
    /**
     * Build a ModMeta from a Dynamic (parsed JSON).
     * Fills in any missing fields with defaults.
     */
    public static function fromDynamic(raw:Dynamic):ModMeta
    {
        var def = defaults();
        var result:ModMeta = {};

        // Copy all fields from raw, fill gaps from defaults
        for (field in Reflect.fields(def))
        {
            var val = Reflect.getProperty(raw, field);
            Reflect.setProperty(result, field, val != null ? val : Reflect.getProperty(def, field));
        }

        // Copy any extra fields from raw (custom settings, etc.)
        for (field in Reflect.fields(raw))
        {
            if (Reflect.getProperty(result, field) == null)
                Reflect.setProperty(result, field, Reflect.getProperty(raw, field));
        }

        return result;
    }

    /**
     * Default ModMeta matching the original Kade Engine / SinkopesoEngine baseline.
     */
    public static function defaults():ModMeta
    {
        return {
            title:              "SinkopesoEngine",
            version:            "1.0.0",
            engineVersion:      "1.0.0-beta1",
            icon:               "appIcon",
            description:        "",
            author:             "",
            width:              1280,
            height:             720,
            bpm:                102,
            initialState:       "TitleState",
            mainMenuState:      "MainMenuState",
            freeplayState:      "FreeplayState",
            storyMenuState:     "StoryMenuState",
            masterEditorMenu:   "MasterEditorMenu",
            pauseSubState:      "PauseSubState",
            gameOverScreen:     "GameOverSubState",
            transition:         "FadeTransition",
            loadDefaultWeeks:   true,
            developerMode:      false,
            mobileDebug:        false,
            scriptsHotReloading:false,
            discordID:          "",
            settings:           {},
        };
    }
}
