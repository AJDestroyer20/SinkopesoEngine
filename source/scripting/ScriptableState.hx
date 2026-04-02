package scripting;

import flixel.FlxG;
import context.GameContext;
import context.EventBus;
import context.EventBus.BusEvents;
import scripting.ScriptContext;
import gameplay.MusicBeatState;

/**
 * ScriptableState — MusicBeatState with full scripting support.
 *
 * Every game state extends this instead of MusicBeatState directly.
 * Scripts are loaded from:
 *   assets/scripts/states/<ClassName>/   (state-specific)
 *   assets/scripts/global/               (runs on every state)
 *
 * ─── Fixed bugs ───────────────────────────────────────────────────────────
 *   Fix H: curBeat/curStep refreshed live every update() frame.
 *   Fix I: STATE_DESTROY emitted before scripts.destroy() so EventBus
 *          listeners in scripts can still fire.
 *   Fix J: "state" var refreshed after openSubState().
 *   Fix N: onKeyDown/onKeyUp are NOT overridable on FlxUIState — removed.
 *          Key capture is done via FlxG.keys polling inside update().
 *   Fix O: destroy() no longer calls scripts.call("onDestroy") manually;
 *          ScriptContext.destroy() does it exactly once.
 *   Fix P: GameContext.events null-guarded throughout.
 */
class ScriptableState extends MusicBeatState
{
	/** Per-state script context. Accessible from subclasses. */
	public var scripts:ScriptContext;

	// ─── Lifecycle ───────────────────────────────────────────────────────

	override function create():Void
	{
		scripts = new ScriptContext(stateId());
		injectStateVars();

		scripts.loadFolder("assets/scripts/states/" + stateId());
		scripts.loadFolder("assets/scripts/global");

		super.create();

		scripts.call("onCreate", []);
		if (GameContext.events != null) // Fix P
			GameContext.events.emit(BusEvents.STATE_CREATE, { state: stateId() });
	}

	override function update(elapsed:Float):Void
	{
		// Fix H: keep live vars visible to scripts every frame
		scripts.setVar("elapsed",      elapsed);
		scripts.setVar("curBeat",      curBeat);
		scripts.setVar("curStep",      curStep);
		scripts.setVar("songPosition", gameplay.Conductor.songPosition);

		scripts.call("onUpdate", [elapsed]);
		super.update(elapsed);
		scripts.call("onUpdatePost", [elapsed]);
	}

	override function destroy():Void
	{
		// Fix I: emit BEFORE destroy so scripts still alive when event fires
		if (GameContext.events != null) // Fix P
			GameContext.events.emit(BusEvents.STATE_DESTROY, { state: stateId() });
		// Fix O: do NOT call scripts.call("onDestroy") here — ScriptContext.destroy() does it once
		scripts.destroy();
		super.destroy();
	}

	// ─── Beat / Step ────────────────────────────────────────────────────

	override public function beatHit():Void
	{
		super.beatHit();
		scripts.call("onBeatHit", [curBeat]);
		if (GameContext.events != null)
			GameContext.events.emit(BusEvents.BEAT_HIT, { beat: curBeat });
	}

	override public function stepHit():Void
	{
		super.stepHit();
		scripts.call("onStepHit", [curStep]);
		if (GameContext.events != null)
			GameContext.events.emit(BusEvents.STEP_HIT, { step: curStep });
	}

	// ─── Substates ───────────────────────────────────────────────────────

	override function openSubState(sub:flixel.FlxSubState):Void
	{
		var name = Type.getClassName(Type.getClass(sub));
		scripts.call("onSubstateOpen", [name]);
		if (GameContext.events != null)
			GameContext.events.emit(BusEvents.SUBSTATE_OPEN, { name: name });
		super.openSubState(sub);
		scripts.setVar("state", this); // Fix J
	}

	override function closeSubState():Void
	{
		scripts.call("onSubstateClose", []);
		if (GameContext.events != null)
			GameContext.events.emit(BusEvents.SUBSTATE_CLOSE, {});
		super.closeSubState();
	}

	// ─── Focus ───────────────────────────────────────────────────────────

	override function onFocusLost():Void
	{
		scripts.call("onFocusLost", []);
		super.onFocusLost();
	}

	override function onFocus():Void
	{
		scripts.call("onFocus", []);
		super.onFocus();
	}

	// ─── Helpers ─────────────────────────────────────────────────────────

	public function stateId():String
	{
		return Type.getClassName(Type.getClass(this)).split(".").pop();
	}

	function injectStateVars():Void
	{
		scripts.setVar("state",   this);
		scripts.setVar("curBeat", curBeat);
		scripts.setVar("curStep", curStep);
		scripts.setVar("game",    null); // overridden in PlayState
	}
}
