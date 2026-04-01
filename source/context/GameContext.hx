package context;

import haxe.Json;
import mods.ModMeta;
import mods.ModRegistry;

#if FEATURE_FILESYSTEM
import sys.io.File;
import sys.FileSystem;
#end

/**
 * GameContext — SinkopesoEngine
 *
 * Central singleton hub. Call GameContext.init() once in Main.setupGame()
 * BEFORE new FlxGame().
 *
 * ─── Bug Fix #15 ──────────────────────────────────────────────────────────
 *   GameContext.init() called ModMeta.fromDynamic() but ModMeta is a typedef
 *   — it has NO static methods. The methods belong to ModMetaHelper.
 *   Calling ModMeta.fromDynamic() / ModMeta.defaults() would produce a
 *   compile error "Unknown identifier: fromDynamic".
 *   Fix: call ModMetaHelper.fromDynamic() / ModMetaHelper.defaults().
 */
class GameContext
{
	// ─── Singleton ──────────────────────────────────────────────────────

	public static var instance(default, null):GameContext;

	// ─── Managers ───────────────────────────────────────────────────────

	/** Audio playback — music, vocals, SFX */
	public static var audio(default, null):AudioManager;

	/** Mod metadata from data.json */
	public static var mods(default, null):ModRegistry;

	/** Typed publish/subscribe event bus */
	public static var events(default, null):EventBus;

	/** Engine version string */
	public static inline final ENGINE_NAME    = "SinkopesoEngine";
	public static inline final ENGINE_VERSION = "1.0.0-beta1";

	// ─── Init ────────────────────────────────────────────────────────────

	/**
	 * Call once in Main.setupGame() BEFORE new FlxGame().
	 * Reads data.json, initialises all managers.
	 */
	public static function init():Void
	{
		instance = new GameContext();

		// Fix #15: ModMeta is a typedef — static methods are on ModMetaHelper
		var meta:ModMeta = loadMeta();

		mods   = new ModRegistry(meta);
		audio  = new AudioManager();
		events = new EventBus();

		trace('[${ENGINE_NAME}] GameContext initialised. Version: ${ENGINE_VERSION}');
		trace('[${ENGINE_NAME}] Mod: ${meta.title} v${meta.version}');
	}

	/**
	 * Call on state switch to reset transient audio/event state.
	 * Does NOT re-read data.json.
	 */
	public static function reset():Void
	{
		if (audio  != null) audio.reset();
		if (events != null) events.reset();
		trace('[${ENGINE_NAME}] GameContext reset.');
	}

	// ─── Private ─────────────────────────────────────────────────────────

	function new() {}

	static function loadMeta():ModMeta
	{
		var raw:String = null;

		#if FEATURE_FILESYSTEM
		// Desktop: look for data.json next to the executable
		var paths = ["data.json", "assets/data/data.json"];
		for (p in paths)
		{
			if (FileSystem.exists(p))
			{
				raw = File.getContent(p);
				trace('[GameContext] Loaded data.json from: $p');
				break;
			}
		}
		#end

		if (raw == null)
		{
			// Fall back to embedded asset
			try { raw = openfl.Assets.getText("assets/data/data.json"); }
			catch (_:Dynamic) {}
		}

		if (raw != null)
		{
			try
			{
				var parsed:Dynamic = Json.parse(raw);
				return ModMetaHelper.fromDynamic(parsed); // Fix #15
			}
			catch (e:Dynamic)
			{
				trace('[GameContext] WARNING: Failed to parse data.json — $e');
			}
		}

		trace('[GameContext] WARNING: data.json not found or invalid — using defaults.');
		return ModMetaHelper.defaults(); // Fix #15
	}
}
