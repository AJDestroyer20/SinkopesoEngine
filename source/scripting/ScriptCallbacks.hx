package scripting;

/**
 * ScriptCallbacks
 * 
 * ═══════════════════════════════════════════════════════════════════════
 *  MASTER LIST OF ALL ENGINE CALLBACKS
 *  Every single hook available to scripts (.hx, .lua, .xml, .json, .txt)
 * ═══════════════════════════════════════════════════════════════════════
 * 
 * HOW TO USE IN SCRIPTS:
 * 
 * ── HaxeScript (.hx) ──────────────────────────────────────────────────
 *   function onSongStart() { ... }
 *   function onNoteHit(note) { ... }
 * 
 * ── Lua (.lua) ────────────────────────────────────────────────────────
 *   function onSongStart() end
 *   function onNoteHit(noteData, noteType, isSustain) end
 * 
 * ── XML (.xml) ────────────────────────────────────────────────────────
 *   <callback name="onSongStart"> ... </callback>
 * 
 * ── JSON (.json) ──────────────────────────────────────────────────────
 *   "callbacks": { "onSongStart": [...] }
 * 
 * ── TXT (.txt) ────────────────────────────────────────────────────────
 *   ON onSongStart: FLASH 0xFFFFFFFF 0.5
 * 
 * ═══════════════════════════════════════════════════════════════════════
 */
class ScriptCallbacks
{
	// ─── GAMEPLAY ────────────────────────────────────────────────────────

	/** Song has fully started (intro done, notes incoming) */
	public static inline var ON_SONG_START        = "onSongStart";

	/** Song ended (completion, not game over) */
	public static inline var ON_SONG_END          = "onSongEnd";

	/** Every conductor beat (4 per measure by default) — arg: beat:Int */
	public static inline var ON_BEAT_HIT          = "onBeatHit";

	/** Every conductor step (16 per measure by default) — arg: step:Int */
	public static inline var ON_STEP_HIT          = "onStepHit";

	/** Every section change — arg: section:Int */
	public static inline var ON_SECTION_HIT       = "onSectionHit";

	/** Frame update — arg: elapsed:Float (seconds), songPosition:Float (ms) */
	public static inline var UPDATE               = "update";

	// ─── NOTES ───────────────────────────────────────────────────────────

	/** Player hit a note — arg: note:Note */
	public static inline var ON_NOTE_HIT          = "onNoteHit";

	/** Player missed a note — arg: note:Note */
	public static inline var ON_NOTE_MISS         = "onNoteMiss";

	/** CPU/bot hit a note — arg: note:Note */
	public static inline var ON_CPU_NOTE_HIT      = "onCpuNoteHit";

	/** A note is spawned — arg: note:Note */
	public static inline var ON_NOTE_SPAWN        = "onNoteSpawn";

	/** A sustain note tick — arg: note:Note */
	public static inline var ON_HOLD_NOTE         = "onHoldNote";

	// ─── HEALTH / SCORING ────────────────────────────────────────────────

	/** Health changed — args: newHealth:Float, delta:Float */
	public static inline var ON_HEALTH_CHANGE     = "onHealthChange";

	/** Player died (health reached 0) */
	public static inline var ON_GAME_OVER         = "onGameOver";

	/** Game over screen is shown (after death animation) */
	public static inline var ON_GAME_OVER_START   = "onGameOverStart";

	/** Player retried from game over */
	public static inline var ON_RETRY             = "onRetry";

	/** Score updated — arg: score:Int */
	public static inline var ON_SCORE_UPDATE      = "onScoreUpdate";

	// ─── COUNTDOWN ───────────────────────────────────────────────────────

	/** Countdown started (before song) */
	public static inline var ON_COUNTDOWN_START   = "onCountdownStart";

	/** Each countdown tick — arg: tick:Int (3=three, 2=two, 1=one, 0=go) */
	public static inline var ON_COUNTDOWN_TICK    = "onCountdownTick";

	// ─── EVENTS ──────────────────────────────────────────────────────────

	/** A chart event fired — args: eventName:String, value1:String, value2:String */
	public static inline var ON_EVENT             = "onEvent";

	// ─── CAMERA ──────────────────────────────────────────────────────────

	/** Camera focused on boyfriend */
	public static inline var ON_CAM_BF            = "onCamBF";

	/** Camera focused on opponent */
	public static inline var ON_CAM_DAD           = "onCamDad";

	// ─── CHARACTERS ──────────────────────────────────────────────────────

	/** Boyfriend animation changed — arg: animName:String */
	public static inline var ON_BF_ANIM           = "onBFAnim";

	/** Dad/opponent animation changed — arg: animName:String */
	public static inline var ON_DAD_ANIM          = "onDadAnim";

	/** GF animation changed — arg: animName:String */
	public static inline var ON_GF_ANIM           = "onGFAnim";

	// ─── MENUS ───────────────────────────────────────────────────────────

	/** Main menu state created */
	public static inline var ON_MAIN_MENU_CREATE  = "onMainMenuCreate";

	/** Main menu updated — arg: elapsed:Float */
	public static inline var ON_MAIN_MENU_UPDATE  = "onMainMenuUpdate";

	/** An option was selected in main menu — arg: option:String */
	public static inline var ON_MAIN_MENU_SELECT  = "onMainMenuSelect";

	/** Freeplay state created */
	public static inline var ON_FREEPLAY_CREATE   = "onFreeplayCreate";

	/** Song selected in freeplay — arg: songName:String */
	public static inline var ON_FREEPLAY_SELECT   = "onFreeplaySelect";

	/** Story menu created */
	public static inline var ON_STORY_CREATE      = "onStoryMenuCreate";

	/** Week selected — arg: weekIndex:Int */
	public static inline var ON_STORY_SELECT      = "onStoryWeekSelect";

	/** Title screen created */
	public static inline var ON_TITLE_CREATE      = "onTitleCreate";

	/** Title screen random Easter egg text — return String to override */
	public static inline var ON_TITLE_TEXT        = "onTitleText";

	// ─── STATE TRANSITIONS ───────────────────────────────────────────────

	/** Any state is about to be switched — arg: nextState:String */
	public static inline var ON_STATE_SWITCH      = "onStateSwitch";

	/** Script is being destroyed (state switched away) */
	public static inline var ON_DESTROY           = "onDestroy";

	// ─── INPUT ───────────────────────────────────────────────────────────

	/** A key was pressed — arg: keyCode:Int */
	public static inline var ON_KEY_DOWN          = "onKeyDown";

	/** A key was released — arg: keyCode:Int */
	public static inline var ON_KEY_UP            = "onKeyUp";

	// ─── MODDING ─────────────────────────────────────────────────────────

	/** A mod was loaded — arg: modName:String */
	public static inline var ON_MOD_LOADED        = "onModLoaded";

	/** Called when engine is fully initialized */
	public static inline var ON_ENGINE_READY      = "onEngineReady";
}
