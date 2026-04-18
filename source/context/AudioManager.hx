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
    var _currentSongId:String  = "";
    var _vocals:FlxSound       = null;
    var _musicVolume:Float     = 1.0;
    var _vocalsVolume:Float    = 1.0;

    public function new() {}

    /**
     * Load and play the instrumental for a song.
     * @param songId  Internal song ID (e.g. "bopeebo", "tutorial")
     * @param volume  0.0 – 1.0 (default 1.0)
     */
    public function playMusic(songId:String, volume:Float = 1.0):Void
    {
        _currentSongId = songId;
        _musicVolume   = normalizeVolume(volume);

        var path = Paths.inst(songId);
        FlxG.sound.playMusic(path, _musicVolume, false);
        trace('[AudioManager] Playing music: $songId');
    }

    /**
     * Load and play vocals for a song.
     * Call AFTER playMusic so the streams stay in sync.
     */
    public function playVocals(songId:String, volume:Float = 1.0):Void
    {
        _vocalsVolume = normalizeVolume(volume);

        destroyVocals();

        var path = Paths.voices(songId);
        if (path == null || path == "")
            return;

        _vocals = FlxG.sound.load(path, _vocalsVolume, false);
        if (_vocals != null)
            _vocals.play();
        trace('[AudioManager] Playing vocals: $songId');
    }

    public function stop():Void
    {
        if (FlxG.sound.music != null) FlxG.sound.music.stop();
        if (_vocals != null)          _vocals.stop();
    }

    public function pause():Void
    {
        if (FlxG.sound.music != null) FlxG.sound.music.pause();
        if (_vocals != null)          _vocals.pause();
    }

    public function resume():Void
    {
        if (FlxG.sound.music != null) FlxG.sound.music.resume();
        if (_vocals != null)          _vocals.resume();
    }

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

    public function getTime():Float
    {
        return FlxG.sound.music != null ? FlxG.sound.music.time : 0;
    }

    public function setTime(ms:Float):Void
    {
        if (FlxG.sound.music != null) FlxG.sound.music.time = ms;
        if (_vocals != null)          _vocals.time = ms;
    }

    public function setMusicVolume(v:Float):Void
    {
        _musicVolume = normalizeVolume(v);
        if (FlxG.sound.music != null) FlxG.sound.music.volume = _musicVolume;
    }

    public function setVocalsVolume(v:Float):Void
    {
        _vocalsVolume = normalizeVolume(v);
        if (_vocals != null) _vocals.volume = _vocalsVolume;
    }

    public function fadeOut(duration:Float, toVolume:Float = 0.0):Void
    {
        if (FlxG.sound.music != null)
            FlxG.sound.music.fadeOut(duration, toVolume);
    }

    public var vocals(get, never):FlxSound;
    inline function get_vocals():FlxSound return _vocals;

    public var isPlaying(get, never):Bool;
    inline function get_isPlaying():Bool
        return FlxG.sound.music != null && FlxG.sound.music.playing;

    public function reset():Void
    {
        stop();
        destroyVocals();
        _currentSongId = "";
    }

    inline function normalizeVolume(v:Float):Float
    {
        return Math.max(0, Math.min(1, v));
    }

    function destroyVocals():Void
    {
        if (_vocals == null)
            return;
        _vocals.stop();
        _vocals.destroy();
        _vocals = null;
    }
}
