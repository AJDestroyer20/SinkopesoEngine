package scripting;

import context.GameContext;
import context.EventBus.BusEvents;
import scripting.ScriptContext;
import gameplay.MusicBeatSubstate;

/**
 * ScriptableSubstate — MusicBeatSubstate with full scripting support.
 *
 * ─── Fixed bugs ───────────────────────────────────────────────────────────
 *   Fix K: STATE_DESTROY emitted before scripts.destroy().
 *   Fix L: destroy() no longer manually calls onDestroy (ScriptContext does it).
 *   Fix P: GameContext.events null-guarded.
 */
class ScriptableSubstate extends MusicBeatSubstate
{
	public var scripts:ScriptContext;

	override function create():Void
	{
		scripts = new ScriptContext(substateId());
		injectSubstateVars();
		scripts.loadFolder("assets/scripts/states/" + substateId());
		super.create();
		scripts.call("onCreate", []);
	}

	override function update(elapsed:Float):Void
	{
		scripts.setVar("elapsed", elapsed);
		scripts.setVar("curBeat", curBeat);
		scripts.setVar("curStep", curStep);
		scripts.call("onUpdate",  [elapsed]);
		super.update(elapsed);
		scripts.call("onUpdatePost", [elapsed]);
	}

	override function destroy():Void
	{
		// Fix K: emit while scripts still alive
		if (GameContext.events != null)
			GameContext.events.emit(BusEvents.SUBSTATE_CLOSE, { name: substateId() });
		// Fix L: destroy() handles onDestroy exactly once internally
		scripts.destroy();
		super.destroy();
	}

	override public function beatHit():Void
	{
		super.beatHit();
		scripts.call("onBeatHit", [curBeat]);
	}

	override public function stepHit():Void
	{
		super.stepHit();
		scripts.call("onStepHit", [curStep]);
	}

	// ─── Helpers ─────────────────────────────────────────────────────────

	public function substateId():String
	{
		return Type.getClassName(Type.getClass(this)).split(".").pop();
	}

	function injectSubstateVars():Void
	{
		scripts.setVar("substate", this);
		scripts.setVar("state",    flixel.FlxG.state);
		scripts.setVar("game",     gameplay.PlayState.instance);
	}
}
