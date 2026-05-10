package systems;

import gameplay.notes.Note;

enum AIMode
{
	AUTO;
	EASY;
	NORMAL;
	HARD;
	EXTREME;
}

class AdaptiveAI
{
	public var mode:AIMode = NORMAL;
	public var enabled:Bool = false;
	
	private var playerAccuracy:Float = 0;
	private var playerMisses:Int = 0;
	private var totalNotes:Int = 0;
	
	private var hitWindow:Float = 160;
	private var missChance:Float = 0;
	private var earlyLateBias:Float = 0;
	
	public function new()
	{
		updateAIParams();
	}
	
	public function setMode(newMode:AIMode):Void
	{
		mode = newMode;
		updateAIParams();
	}
	
	private function updateAIParams():Void
	{
		switch (mode)
		{
			case AUTO:
				hitWindow = 5;
				missChance = 0;
				earlyLateBias = 0;
				
			case EASY:
				hitWindow = 100;
				missChance = 0.15;
				earlyLateBias = FlxG.random.float(-30, 30);
				
			case NORMAL:
				hitWindow = 50;
				missChance = 0.05;
				earlyLateBias = FlxG.random.float(-15, 15);
				
			case HARD:
				hitWindow = 25;
				missChance = 0.02;
				earlyLateBias = FlxG.random.float(-8, 8);
				
			case EXTREME:
				hitWindow = 10;
				missChance = 0;
				earlyLateBias = FlxG.random.float(-3, 3);
		}
	}
	
	public function shouldHitNote(note:Note, songPosition:Float):Bool
	{
		if (!enabled)
			return false;
		
		var noteDiff:Float = Math.abs(note.strumTime - songPosition);
		
		if (FlxG.random.float(0, 1) < missChance)
			return false;
		
		if (noteDiff < hitWindow + earlyLateBias)
			return true;
		
		return false;
	}
	
	public function adaptToPlayer(accuracy:Float, misses:Int, total:Int):Void
	{
		playerAccuracy = accuracy;
		playerMisses = misses;
		totalNotes = total;
		
		if (mode != AUTO)
		{
			if (accuracy < 70 && mode == HARD)
				setMode(NORMAL);
			else if (accuracy < 50 && mode == NORMAL)
				setMode(EASY);
			else if (accuracy > 95 && mode == NORMAL)
				setMode(HARD);
			else if (accuracy > 98 && mode == HARD)
				setMode(EXTREME);
		}
	}
	
	public function reset():Void
	{
		playerAccuracy = 0;
		playerMisses = 0;
		totalNotes = 0;
		updateAIParams();
	}
}
