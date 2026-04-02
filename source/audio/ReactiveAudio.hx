package audio;

import flixel.sound.FlxSound;
import flixel.FlxG;

/**
 * ReactiveAudio
 * 
 * Multi-stem audio system that layers tracks dynamically based on
 * player performance. Instruments fade in/out, intensity changes,
 * and alternate mixes can trigger based on health, combo, or accuracy.
 * 
 * ─── Folder structure for a reactive song ───────────────────────────────
 * 
 *   assets/songs/mySong/
 *     Inst.ogg           ← base instrumental (always plays)
 *     Voices.ogg         ← vocal stems (always plays)
 *     Inst-intense.ogg   ← high-energy layer (fades in at high combo)
 *     Inst-calm.ogg      ← ambient layer (fades in at low health)
 *     Voices-extra.ogg   ← extra vocals (fades in at perfect accuracy)
 *     Inst-lowhealth.ogg ← danger layer (fades in near death)
 * 
 * ─── Stem config in song JSON (optional) ────────────────────────────────
 * 
 *   "stems": [
 *     {"file": "Inst",           "volume": 1.0, "trigger": "always"},
 *     {"file": "Voices",         "volume": 1.0, "trigger": "always"},
 *     {"file": "Inst-intense",   "volume": 0.0, "trigger": "combo",   "threshold": 30},
 *     {"file": "Inst-calm",      "volume": 0.0, "trigger": "health",  "threshold": 0.4, "below": true},
 *     {"file": "Voices-extra",   "volume": 0.0, "trigger": "accuracy","threshold": 0.95},
 *     {"file": "Inst-lowhealth", "volume": 0.0, "trigger": "health",  "threshold": 0.25,"below": true}
 *   ]
 * 
 * ─── Usage in PlayState ──────────────────────────────────────────────────
 * 
 *   // In create():
 *   reactiveAudio = new ReactiveAudio(PlayState.SONG.songId);
 *   reactiveAudio.loadStems();
 *   reactiveAudio.play();
 * 
 *   // Replace FlxG.sound.playMusic() calls with ReactiveAudio.play()
 * 
 *   // In update():
 *   reactiveAudio.update(accuracy, combo, health, elapsed);
 * 
 *   // Pause/resume:
 *   reactiveAudio.pause();
 *   reactiveAudio.resume();
 *   reactiveAudio.stop();
 */
class ReactiveAudio
{
	var songId:String;
	var stems:Array<StemTrack> = [];
	var isPlaying:Bool = false;

	// Smoothing speed for volume transitions
	public var lerpSpeed:Float = 2.0;

	public function new(songId:String)
	{
		this.songId = songId;
	}

	/**
	 * Load stems from song JSON config or auto-detect files.
	 * Call before play().
	 */
	public function loadStems():Void
	{
		stems = [];

		// Try to read stem config from song JSON
		var stemConfig = getStemConfig();

		if (stemConfig != null && stemConfig.length > 0)
		{
			for (cfg in stemConfig)
			{
				var stem = loadStem(cfg.file, cfg.volume ?? 1.0, cfg.trigger ?? "always", cfg.threshold ?? 0, cfg.below ?? false);
				if (stem != null) stems.push(stem);
			}
		}
		else
		{
			// Auto-detect: load Inst + Voices as always-on, then probe for extras
			addAutoStem("Inst",           1.0, "always",   0,    false);
			addAutoStem("Voices",         1.0, "always",   0,    false);
			addAutoStem("Inst-intense",   0.0, "combo",    30,   false);
			addAutoStem("Inst-calm",      0.0, "health",   0.35, true);
			addAutoStem("Voices-extra",   0.0, "accuracy", 0.95, false);
			addAutoStem("Inst-lowhealth", 0.0, "health",   0.2,  true);
		}

		trace('[ReactiveAudio] Loaded ${stems.length} stems for $songId');
	}

	function addAutoStem(file:String, volume:Float, trigger:String, threshold:Float, below:Bool):Void
	{
		var path = Paths.inst(songId) // adjust to actual path helper
			.split("Inst.").join('${file}.');
		// Check with sys.FileSystem if the variant exists
		var fullPath = "assets/songs/" + songId.toLowerCase() + "/" + file + ".ogg";
		if (sys.FileSystem.exists(fullPath))
		{
			var stem = loadStem(file, volume, trigger, threshold, below);
			if (stem != null) stems.push(stem);
		}
	}

	function loadStem(file:String, startVolume:Float, trigger:String, threshold:Float, below:Bool):StemTrack
	{
		try
		{
			var sound = new FlxSound();
			var path  = "assets/songs/" + songId.toLowerCase() + "/" + file + ".ogg";
			sound.loadEmbedded(openfl.Assets.getSound(path), true);
			sound.volume = startVolume;

			return {
				sound:       sound,
				file:        file,
				targetVol:   startVolume,
				currentVol:  startVolume,
				trigger:     trigger,
				threshold:   threshold,
				below:       below
			};
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	/** Start all stems simultaneously */
	public function play(startTime:Float = 0):Void
	{
		for (s in stems)
		{
			s.sound.play(false);
			if (startTime > 0) s.sound.time = startTime;
		}
		isPlaying = true;
	}

	/** Update volumes based on player performance */
	public function update(accuracy:Float, combo:Int, health:Float, elapsed:Float):Void
	{
		if (!isPlaying) return;

		for (stem in stems)
		{
			// Calculate target volume based on trigger condition
			var active = isConditionMet(stem, accuracy, combo, health);
			stem.targetVol = active ? 1.0 : 0.0;

			// Smooth lerp to target
			stem.currentVol = lerp(stem.currentVol, stem.targetVol, lerpSpeed * elapsed);
			stem.sound.volume = stem.currentVol;
		}

		// Keep all stems in sync (resync if drift > 50ms)
		syncStems();
	}

	function isConditionMet(stem:StemTrack, accuracy:Float, combo:Int, health:Float):Bool
	{
		return switch (stem.trigger)
		{
			case "always":
				true;
			case "combo":
				stem.below ? combo < stem.threshold : combo >= stem.threshold;
			case "health":
				stem.below ? health < stem.threshold : health >= stem.threshold;
			case "accuracy":
				stem.below ? accuracy < stem.threshold : accuracy >= stem.threshold;
			case "never":
				false;
			default:
				true;
		};
	}

	function syncStems():Void
	{
		if (stems.length < 2) return;
		var masterTime = stems[0].sound.time;
		for (i in 1...stems.length)
		{
			if (Math.abs(stems[i].sound.time - masterTime) > 50)
				stems[i].sound.time = masterTime;
		}
	}

	public function pause():Void
	{
		for (s in stems) s.sound.pause();
		isPlaying = false;
	}

	public function resume():Void
	{
		for (s in stems) s.sound.resume();
		isPlaying = true;
	}

	public function stop():Void
	{
		for (s in stems) { s.sound.stop(); s.sound.destroy(); }
		stems = [];
		isPlaying = false;
	}

	/** Set a specific stem's volume directly (bypasses trigger system) */
	public function setStemVolume(file:String, volume:Float):Void
	{
		for (s in stems)
			if (s.file == file) { s.targetVol = volume; s.currentVol = volume; s.sound.volume = volume; }
	}

	function getStemConfig():Array<Dynamic>
	{
		try
		{
			var path = "assets/data/" + songId.toLowerCase() + "/stems.json";
			if (sys.FileSystem.exists(path))
				return haxe.Json.parse(sys.io.File.getContent(path));
		}
		catch (_) {}
		return null;
	}

	inline function lerp(a:Float, b:Float, t:Float):Float
		return a + (b - a) * Math.min(t, 1.0);
}

typedef StemTrack =
{
	var sound:FlxSound;
	var file:String;
	var targetVol:Float;
	var currentVol:Float;
	var trigger:String;     // "always" | "combo" | "health" | "accuracy" | "never"
	var threshold:Float;
	var below:Bool;         // true = active when value is BELOW threshold
}
