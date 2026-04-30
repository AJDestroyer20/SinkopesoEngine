package gameplay.ai;

import gameplay.notes.Note;

class AIDriver
{
	public var hitWindowMs:Float = 45;

	public function new() {}

	public function shouldHit(note:Note, songPosition:Float):Bool
	{
		return Math.abs(note.strumTime - songPosition) <= hitWindowMs;
	}
}
