package core.state;

import backend.MusicBeatState;

class ScriptableState extends MusicBeatState
{
	public var hooks:StateHooks;

	override function create():Void
	{
		hooks = new StateHooks(this);
		super.create();
		hooks.onCreate();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		hooks.onUpdate(elapsed);
	}

	override function beatHit():Void
	{
		super.beatHit();
		hooks.onBeat(curBeat);
	}
}
