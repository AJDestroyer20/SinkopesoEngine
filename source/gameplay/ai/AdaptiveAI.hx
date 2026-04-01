package gameplay.ai;

/**
 * AdaptiveAI
 * 
 * Replaces the static CPU player with one that reads the player's
 * performance and adjusts its behavior accordingly.
 * 
 * ─── Integration in PlayState.hx ────────────────────────────────────────
 * 
 * Add at top of PlayState:
 *   var adaptiveAI:AdaptiveAI;
 * 
 * In create():
 *   adaptiveAI = new AdaptiveAI(AdaptiveAI.PERSONALITY_ADAPTIVE);
 *   adaptiveAI.onNoteHit   = (n) -> { ... }  // optional
 *   adaptiveAI.onNoteMiss  = (n) -> { ... }  // optional
 * 
 * In the note hit logic (where CPU hits notes), replace:
 *   cpuStrums.forEach(...)
 * with:
 *   if (adaptiveAI.shouldHitNote(note, Conductor.songPosition))
 *       { ... play note animation ... }
 * 
 * In update():
 *   adaptiveAI.update(accuracy, combo, health, elapsed);
 * 
 * When player hits/misses:
 *   adaptiveAI.reportPlayerHit(note);
 *   adaptiveAI.reportPlayerMiss(note);
 */
class AdaptiveAI
{
	// ─── Built-in personality presets ────────────────────────────────────

	/** Never misses, instant reaction — basically auto-play */
	public static var PERSONALITY_BOT:AIPersonality     = {name:"Bot",     missChance:0.000, reactionMs:0,   speedMult:1.0, recovers:false};

	/** Easy CPU — misses often, slow reaction */
	public static var PERSONALITY_EASY:AIPersonality    = {name:"Easy",    missChance:0.35,  reactionMs:150, speedMult:0.8, recovers:true};

	/** Medium CPU — balanced */
	public static var PERSONALITY_MEDIUM:AIPersonality  = {name:"Medium",  missChance:0.18,  reactionMs:80,  speedMult:1.0, recovers:true};

	/** Hard CPU — rarely misses */
	public static var PERSONALITY_HARD:AIPersonality    = {name:"Hard",    missChance:0.05,  reactionMs:30,  speedMult:1.0, recovers:true};

	/** Adapts to player skill in real time */
	public static var PERSONALITY_ADAPTIVE:AIPersonality = {name:"Adaptive", missChance:0.1, reactionMs:60,  speedMult:1.0, recovers:true};

	// ─── State ───────────────────────────────────────────────────────────

	public var personality:AIPersonality;

	/** Current effective miss chance (0 = never miss, 1 = always miss) */
	public var missChance(default, null):Float = 0.1;

	/** Reaction delay in ms — how early the AI "sees" a note */
	public var reactionMs(default, null):Float = 60;

	/** Running stats from player */
	var playerHits:Int   = 0;
	var playerMisses:Int = 0;
	var playerCombo:Int  = 0;
	var playerAccuracy:Float = 1.0;
	var playerHealth:Float   = 1.0;

	/** Notes that the AI has queued to hit (time → should hit) */
	var queuedNotes:Map<Int, Bool> = new Map();

	/** Callbacks */
	public var onNoteHit:Dynamic  = null;
	public var onNoteMiss:Dynamic = null;

	var rng:flixel.math.FlxRandom = new flixel.math.FlxRandom();

	// Adaptive difficulty tracking
	var adjustTimer:Float  = 0;
	var adjustInterval:Float = 5.0; // Re-evaluate every 5 seconds
	var isAdaptive:Bool    = false;

	public function new(personality:AIPersonality)
	{
		this.personality = personality;
		this.missChance  = personality.missChance;
		this.reactionMs  = personality.reactionMs;
		this.isAdaptive  = (personality.name == "Adaptive");
	}

	/**
	 * Call this every update() in PlayState.
	 * elapsed: seconds since last frame
	 * accuracy: player's current accuracy (0-1)
	 * combo: player's current combo
	 * health: player's current health (0-2 in vanilla FNF)
	 */
	public function update(accuracy:Float, combo:Int, health:Float, elapsed:Float):Void
	{
		playerAccuracy = accuracy;
		playerCombo    = combo;
		playerHealth   = health;

		if (!isAdaptive) return;

		adjustTimer += elapsed;
		if (adjustTimer >= adjustInterval)
		{
			adaptDifficulty();
			adjustTimer = 0;
		}
	}

	/**
	 * Should the AI hit this note right now?
	 * Call in CPU note processing loop.
	 * note: the Note object
	 * songPosition: Conductor.songPosition
	 */
	public function shouldHitNote(note:Dynamic, songPosition:Float):Bool
	{
		// Note isn't in reaction window yet
		if ((note.strumTime:Float) - songPosition > reactionMs) return false;

		// Check if we already decided for this note
		var noteId:Int = Std.int(note.strumTime * 1000 + note.noteData);
		if (queuedNotes.exists(noteId)) return queuedNotes.get(noteId);

		// Decide: hit or miss
		var willHit = rng.float() > missChance;
		queuedNotes.set(noteId, willHit);
		return willHit;
	}

	/** Call when the player hits a note */
	public function reportPlayerHit(note:Dynamic):Void
	{
		playerHits++;
		if (personality.recovers && missChance > personality.missChance)
			missChance = Math.max(personality.missChance, missChance - 0.005);
	}

	/** Call when the player misses a note */
	public function reportPlayerMiss(note:Dynamic):Void
	{
		playerMisses++;
	}

	/** Recalculate AI difficulty based on player performance */
	function adaptDifficulty():Void
	{
		// If player is doing well (high accuracy, high combo), make AI harder
		// If player is struggling, ease up
		var totalNotes = playerHits + playerMisses;
		if (totalNotes == 0) return;

		var recentAccuracy = playerHits / totalNotes;

		if (recentAccuracy > 0.90)
		{
			// Player doing great — AI should be harder
			missChance  = Math.max(0.02, missChance  - 0.03);
			reactionMs  = Math.max(10,   reactionMs  - 10);
		}
		else if (recentAccuracy < 0.60)
		{
			// Player struggling — AI should back off
			missChance  = Math.min(0.40, missChance  + 0.05);
			reactionMs  = Math.min(200,  reactionMs  + 15);
		}

		// Health-based emergency easing
		if (playerHealth < 0.3)
			missChance = Math.min(0.50, missChance + 0.10);

		trace('[AdaptiveAI] Adjusted — missChance: ${missChance}, reactionMs: ${reactionMs} (accuracy: ${Math.round(recentAccuracy * 100)}%)');

		// Reset counters for next window
		playerHits   = 0;
		playerMisses = 0;
	}

	/** Change personality at runtime (e.g. via script) */
	public function setPersonality(p:AIPersonality):Void
	{
		personality = p;
		missChance  = p.missChance;
		reactionMs  = p.reactionMs;
		isAdaptive  = (p.name == "Adaptive");
		queuedNotes.clear();
	}

	public function reset():Void
	{
		queuedNotes.clear();
		playerHits = playerMisses = playerCombo = 0;
		adjustTimer = 0;
		missChance  = personality.missChance;
		reactionMs  = personality.reactionMs;
	}
}

/** Data structure for AI personalities */
typedef AIPersonality =
{
	var name:String;
	var missChance:Float;   // 0 = never miss, 1 = always miss
	var reactionMs:Float;   // how many ms before the note the AI reacts
	var speedMult:Float;    // multiplier on animation speed
	var recovers:Bool;      // whether missChance recovers after a streak
}
