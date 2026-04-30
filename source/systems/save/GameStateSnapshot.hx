package systems.save;

typedef SnapshotData = {
	song:String,
	songPosition:Float,
	health:Float,
	score:Int,
	misses:Int
}

class GameStateSnapshot
{
	public static function capture(playState:Dynamic):SnapshotData
	{
		return {
			song: playState.SONG != null ? playState.SONG.song : "",
			songPosition: backend.Conductor.songPosition,
			health: playState.health,
			score: playState.songScore,
			misses: playState.songMisses
		};
	}

	public static function restore(playState:Dynamic, data:SnapshotData):Void
	{
		if (data == null) return;
		playState.health = data.health;
		playState.songScore = data.score;
		playState.songMisses = data.misses;
		backend.Conductor.songPosition = data.songPosition;
	}
}
