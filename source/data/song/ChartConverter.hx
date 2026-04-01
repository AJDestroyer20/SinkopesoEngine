package data.song;

import haxe.Json;

/**
 * ChartConverter
 * 
 * Reads chart files from Psych Engine, V-Slice (FNF 2.0), or Kade Engine
 * and converts them to Kade's internal SwagSong format.
 * 
 * Usage:
 *   var song:SwagSong = ChartConverter.load("mySong", "hard");
 * 
 * Auto-detection priority:
 *   1. Check JSON structure for V-Slice markers ("scrollSpeed" as object, "version" field)
 *   2. Check for Psych markers (events array, custom sections)
 *   3. Fall back to Kade format
 */
class ChartConverter
{
	/** Load a song chart, auto-detecting the source format */
	public static function load(songId:String, difficulty:String):SwagSong
	{
		var path = Paths.json('${songId.toLowerCase()}/${songId.toLowerCase()}${difficulty != "normal" ? "-" + difficulty : ""}');
		
		if (!sys.FileSystem.exists(path))
		{
			trace('[ChartConverter] Chart not found: $path');
			return null;
		}

		var raw:String = sys.io.File.getContent(path);
		var data:Dynamic = Json.parse(raw);

		var format = detect(data);
		trace('[ChartConverter] Detected format: $format for $songId ($difficulty)');

		return switch (format)
		{
			case "vslice": fromVSlice(data);
			case "psych":  fromPsych(data);
			default:       fromKade(data);
		};
	}

	/** Detect which engine format a parsed JSON belongs to */
	public static function detect(data:Dynamic):String
	{
		// V-Slice: has "version" string and "scrollSpeed" as object (not Float)
		if (Reflect.hasField(data, "version") && Reflect.hasField(data, "scrollSpeed"))
		{
			var ss = Reflect.field(data, "scrollSpeed");
			if (Reflect.isObject(ss) && !Reflect.isFunction(ss))
				return "vslice";
		}
		// Psych: has "song.events" array or "song.gfVersion"
		if (Reflect.hasField(data, "song"))
		{
			var s:Dynamic = data.song;
			if (Reflect.hasField(s, "events") || Reflect.hasField(s, "gfVersion"))
				return "psych";
		}
		return "kade";
	}

	// ─── KADE (native) ───────────────────────────────────────────────────

	public static function fromKade(data:Dynamic):SwagSong
	{
		// Already in native format — just cast it
		return cast(data.song ?? data, SwagSong);
	}

	// ─── PSYCH ENGINE ────────────────────────────────────────────────────

	public static function fromPsych(data:Dynamic):SwagSong
	{
		var ps:Dynamic = data.song ?? data;
		var song:SwagSong = new SwagSong();

		song.song           = ps.song ?? "Unknown";
		song.bpm            = ps.bpm ?? 100;
		song.speed          = ps.speed ?? 1.0;
		song.needsVoices    = ps.needsVoices ?? true;
		song.player1        = ps.player1 ?? "bf";
		song.player2        = ps.player2 ?? "dad";
		song.gfVersion      = ps.gfVersion ?? ps.player3 ?? "gf";
		song.stage          = ps.stage ?? "stage";
		song.validScore     = true;

		song.notes = [];

		var sections:Array<Dynamic> = ps.notes ?? [];
		for (sec in sections)
		{
			var section:SwagSection = {
				sectionNotes:  [],
				mustHitSection: sec.mustHitSection ?? true,
				bpm:            sec.bpm ?? song.bpm,
				changeBPM:      sec.changeBPM ?? false,
				altAnim:        sec.altAnim ?? false,
				lengthInSteps:  sec.lengthInSteps ?? 16
			};

			var notes:Array<Dynamic> = sec.sectionNotes ?? [];
			for (n in notes)
			{
				// Psych note format: [time, data, length, type]
				var time:Float   = n[0];
				var data:Int     = n[1];
				var length:Float = n[2] ?? 0;
				var type:String  = n[3] ?? "";

				section.sectionNotes.push([time, data, length]);
			}
			song.notes.push(section);
		}

		// Convert Psych events to Kade events
		if (Reflect.hasField(ps, "events"))
		{
			var events:Array<Dynamic> = ps.events;
			// Kade stores events inline in notes; we'll use a dedicated list
			// attached to the song object via a dynamic field
			Reflect.setField(song, "events", events);
		}

		return song;
	}

	// ─── V-SLICE (FNF 2.0) ───────────────────────────────────────────────

	public static function fromVSlice(data:Dynamic):SwagSong
	{
		var song:SwagSong = new SwagSong();

		// V-Slice metadata
		var meta:Dynamic = data.metadata ?? data;
		song.song        = meta.songName ?? data.songName ?? "Unknown";
		song.bpm         = meta.timeChanges != null ? (meta.timeChanges[0].bpm ?? 100) : 100;
		song.player1     = meta.playData?.characters?.player ?? "bf";
		song.player2     = meta.playData?.characters?.opponent ?? "dad";
		song.gfVersion   = meta.playData?.characters?.girlfriend ?? "gf";
		song.stage       = meta.playData?.stage ?? "stage";
		song.needsVoices = true;
		song.validScore  = true;

		// V-Slice scrollSpeed is per-difficulty object
		var ss:Dynamic = data.scrollSpeed;
		if (Reflect.isObject(ss))
		{
			// Try to get any speed value
			var fields = Reflect.fields(ss);
			song.speed = fields.length > 0 ? (Reflect.field(ss, fields[0]):Float) : 1.0;
		}
		else song.speed = (ss:Float) ?? 1.0;

		song.notes = [];

		// V-Slice notes are in data.notes (array of NoteData)
		// They're NOT section-based, so we group by time into 16-step sections
		var allNotes:Array<Dynamic> = data.notes ?? [];
		var stepCrochet:Float = (60 / song.bpm) * 1000 / 4;
		var sectionLength:Float = stepCrochet * 16;

		// Determine total sections needed
		var maxTime:Float = 0;
		for (n in allNotes) if ((n.t:Float) > maxTime) maxTime = n.t;
		var numSections = Math.ceil(maxTime / sectionLength) + 1;

		// Create empty sections
		for (i in 0...numSections)
			song.notes.push({
				sectionNotes:   [],
				mustHitSection: true,
				bpm:            song.bpm,
				changeBPM:      false,
				altAnim:        false,
				lengthInSteps:  16
			});

		// Place notes in sections
		for (n in allNotes)
		{
			var time:Float = n.t ?? n.time ?? 0;
			var data:Int   = n.d ?? n.data ?? 0;
			var len:Float  = n.l ?? n.length ?? 0;

			var sIdx = Math.floor(time / sectionLength);
			if (sIdx >= song.notes.length) continue;

			// V-Slice: data 0-3 = opponent, 4-7 = player
			// Convert to Kade: mustHitSection true means player=0-3, opp=4-7
			var kadeData = data;
			var mustHit  = data >= 4;
			if (mustHit) kadeData = data - 4;

			song.notes[sIdx].mustHitSection = mustHit;
			song.notes[sIdx].sectionNotes.push([time, kadeData, len]);
		}

		return song;
	}
}
