package backend;

import flixel.FlxSubState;

class MusicBeatSubState extends FlxSubState
{
	private var curSection:Int = 0;
	private var curBeat:Int = 0;
	private var curStep:Int = 0;

	private var controls(get, never):Controls;
	private inline function get_controls():Controls
		return Controls.instance;

	public function new()
	{
		super();
	}

	override function update(elapsed:Float)
	{
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep >= 0)
			stepHit();

		super.update(elapsed);
	}

	private function updateCurStep():Void
	{
		curStep = Conductor.curStep;
	}

	private function updateBeat():Void
	{
		curBeat = Conductor.curBeat;
		curSection = Conductor.curSection;
	}

	public function stepHit():Void
	{
		if (curStep % stepsPerBeat == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		if (curBeat % beatsPerSection == 0)
			sectionHit();
	}

	public function sectionHit():Void
	{
	}

	private var stepsPerBeat(get, never):Int;
	private function get_stepsPerBeat():Int
		return Conductor.stepsPerBeat;

	private var beatsPerSection(get, never):Int;
	private function get_beatsPerSection():Int
		return Conductor.beatsPerSection;
}
