package context;

import flixel.FlxG;
import flixel.sound.FlxSound;
import core.Paths;

/**
 * AudioManager
 * 
 * Deterministic wrapper around FlxG.sound.
 * All music/vocal playback goes through here — never FlxG.sound.music directly.
 * This makes audio controllable by the logic system and resyncable cleanly.
 * 
 * ─── Usage ──────────────────────────────────────────────────────────────
 *   GameContext.audio.playMusic("bopeebo");
 *   GameContext.audio.playVocals("bopeebo");
 *   GameContext.audio.resync();
 *   var pos:Float = GameContext.audio.getTime();
 */
class AudioManager
{
    // ─── State ───────────────────────────────────────────────────────────

    var _currentSongId:String  = "";
    var _vocals:FlxSound       = null;
    var _musicVolume:Float     = 1.0;
    var _vocalsVolume:Float    = 1.0;

    // ─── Constructor ─────────────────────────────────────────────────────

    public function new() {}

    // ─── Music ───────────────────────────────────────────────────────────

    /**
     * Load and play the instrumental for a song.
     * @param songId  Internal song ID (e.g. "bopeebo", "tutorial")
     * @param volume  0.0 – 1.0 (default 1.0)
     */
    public function playMusic(songId:String, volume:Float = 1.0):Void
    {
        _currentSongId = songId;
        _musicVolume   = volume;

        var path = Paths.inst(songId);
        FlxG.sound.playMusic(path, volume, false);
        trace('[AudioManager] Playing music: $songId');
    }

    /**
     * Load and play vocals for a song.
     * Call AFTER playMusic so the streams stay in sync.
     */
    public function playVocals(songId:String, volume:Float = 1.0):Void
    {
        _vocalsVolume = volume;

        if (_vocals != null)
        {
            _vocals.stop();
            _vocals.destroy();
        }

        var path = Paths.voices(songId);
        _vocals = FlxG.sound.load(path, volume, false);
        if (_vocals != null)
            _vocals.play();
        trace('[AudioManager] Playing vocals: $songId');
    }

    // ─── Controls ────────────────────────────────────────────────────────

    /** Stop all audio streams (music + vocals). */
    public function stop():Void
    {
        if (FlxG.sound.music != null) FlxG.sound.music.stop();
        if (_vocals != null)          _vocals.stop();
    }

    /** Pause all audio streams. */
    public function pause():Void
    {
        if (FlxG.sound.music != null) FlxG.sound.music.pause();
        if (_vocals != null)          _vocals.pause();
    }

    /** Resume all audio streams. */
    public function resume():Void
    {
        if (FlxG.sound.music != null) FlxG.sound.music.resume();
        if (_vocals != null)          _vocals.resume();
    }

    /**
     * Force-resync vocals to match instrumental position.
     * Call when a desync is detected.
     */
    public function resync():Void
    {
        if (FlxG.sound.music == null || _vocals == null) return;

        var instTime = FlxG.sound.music.time;
        if (Math.abs(_vocals.time - instTime) > 20)
        {
            _vocals.pause();
            _vocals.time = instTime;
            _vocals.play();
        }
    }

    // ─── Position ────────────────────────────────────────────────────────

    /** Current playhead position of the instrumental in ms. */
    public function getTime():Float
    {
        return FlxG.sound.music != null ? FlxG.sound.music.time : 0;
    }

    /**
     * Seek both streams to a given position in ms.
     * Used by rollback / replay systems.
     */
    public function setTime(ms:Float):Void
    {
        if (FlxG.sound.music != null) FlxG.sound.music.time = ms;
        if (_vocals != null)          _vocals.time = ms;
    }

    // ─── Volume ──────────────────────────────────────────────────────────

    public function setMusicVolume(v:Float):Void
    {
        _musicVolume = v;
        if (FlxG.sound.music != null) FlxG.sound.music.volume = v;
    }

    public function setVocalsVolume(v:Float):Void
    {
        _vocalsVolume = v;
        if (_vocals != null) _vocals.volume = v;
    }

    /** Fade music out over duration seconds. */
    public function fadeOut(duration:Float, toVolume:Float = 0.0):Void
    {
        if (FlxG.sound.music != null)
            FlxG.sound.music.fadeOut(duration, toVolume);
    }

    // ─── Accessors ───────────────────────────────────────────────────────

    /** Direct reference to the vocals FlxSound (may be null). */
    public var vocals(get, never):FlxSound;
    inline function get_vocals():FlxSound return _vocals;

    /** Whether music is currently playing. */
    public var isPlaying(get, never):Bool;
    inline function get_isPlaying():Bool
        return FlxG.sound.music != null && FlxG.sound.music.playing;

    // ─── Cleanup ─────────────────────────────────────────────────────────

    /**
     * Reset transient state between songs.
     * Called by GameContext.reset().
     */
    public function reset():Void
    {
        stop();
        if (_vocals != null)
        {
            _vocals.destroy();
            _vocals = null;
        }
        _currentSongId = "";
    }
}
