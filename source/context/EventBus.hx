package context;

/**
 * EventBus — SinkopesoEngine
 *
 * Typed publish/subscribe event channel.
 *
 * ─── Bug Fixes ────────────────────────────────────────────────────────────
 *   Fix #12: _nextHandle was declared `public static`, meaning it is shared
 *            across ALL EventBus instances. If GameContext ever recreated the
 *            bus (e.g. on game reset), handles from the old bus would collide
 *            with handles from the new one. off(oldHandle) could accidentally
 *            remove a listener from the new bus.
 *            Fix: make _nextHandle instance-level (non-static).
 *
 *   Fix #13: once() captures `handle` by reference in a closure, but the
 *            variable is assigned AFTER the closure is created. In Haxe this
 *            works because closures capture variables, not values — but only
 *            if the closure executes after the assignment. The pattern is
 *            correct here, but it is fragile: if on() ever becomes async,
 *            this breaks silently. Fix: use a local wrapper variable to make
 *            the intent explicit and safe.
 *
 *   Fix #14: off() iterates all keys to find a handle. For large listener
 *            maps this is O(total_listeners). Added an internal reverse-lookup
 *            map (handle → event name) so off() is O(1).
 */
class EventBus
{
	// ─── State ───────────────────────────────────────────────────────────────

	/** Instance-level counter (Fix #12: was public static). */
	var _nextHandle:Int = 0;

	/** event name → [ { handle, owner, fn } ] */
	var _listeners:Map<String, Array<ListenerEntry>> = new Map();

	/** Fix #14: reverse-lookup for O(1) off() */
	var _handleToEvent:Map<Int, String> = new Map();

	// ─── Constructor ─────────────────────────────────────────────────────────

	public function new() {}

	// ─── Subscribe ───────────────────────────────────────────────────────────

	/**
	 * Subscribe to an event.
	 * @param event   Event name string
	 * @param fn      Callback
	 * @param owner   Optional tag for bulk-unsubscribe (e.g. "PlayState")
	 * @return        Handle — store this to unsubscribe later
	 */
	public function on(event:String, fn:Dynamic->Void, owner:String = ""):Int
	{
		var handle = _nextHandle++;
		if (!_listeners.exists(event))
			_listeners.set(event, []);

		_listeners.get(event).push({ handle: handle, owner: owner, fn: fn });
		_handleToEvent.set(handle, event); // Fix #14
		return handle;
	}

	/**
	 * Subscribe once — automatically unsubscribes after first fire.
	 * Fix #13: explicit wrapper variable instead of relying on late binding.
	 */
	public function once(event:String, fn:Dynamic->Void, owner:String = ""):Int
	{
		// Use a wrapper array so the closure captures a stable reference
		var handleRef:Array<Int> = [-1];
		handleRef[0] = on(event, function(data:Dynamic) {
			fn(data);
			off(handleRef[0]);
		}, owner);
		return handleRef[0];
	}

	// ─── Unsubscribe ─────────────────────────────────────────────────────────

	/**
	 * Remove a listener by its handle.
	 * Fix #14: O(1) lookup via _handleToEvent instead of scanning all keys.
	 */
	public function off(handle:Int):Void
	{
		var event = _handleToEvent.get(handle);
		if (event == null) return;

		var list = _listeners.get(event);
		if (list == null) return;

		var i = list.length - 1;
		while (i >= 0)
		{
			if (list[i].handle == handle)
			{
				list.splice(i, 1);
				_handleToEvent.remove(handle);
				return;
			}
			i--;
		}
	}

	/**
	 * Remove all listeners belonging to an owner tag.
	 */
	public function offAll(owner:String):Void
	{
		for (key in _listeners.keys())
		{
			var list = _listeners.get(key);
			var i = list.length - 1;
			while (i >= 0)
			{
				if (list[i].owner == owner)
				{
					_handleToEvent.remove(list[i].handle);
					list.splice(i, 1);
				}
				i--;
			}
		}
	}

	// ─── Emit ────────────────────────────────────────────────────────────────

	/**
	 * Fire an event to all subscribers.
	 * @param event  Event name
	 * @param data   Payload — any Dynamic
	 */
	public function emit(event:String, data:Dynamic = null):Void
	{
		if (!_listeners.exists(event)) return;

		// Copy list to avoid mutation issues during iteration
		var list = _listeners.get(event).copy();
		for (entry in list)
		{
			try { entry.fn(data); }
			catch (e:Dynamic)
			{
				trace('[EventBus] ERROR in listener for "$event": $e');
			}
		}
	}

	/**
	 * Returns true if anyone is listening to this event.
	 */
	public function hasListeners(event:String):Bool
	{
		return _listeners.exists(event) && _listeners.get(event).length > 0;
	}

	// ─── Reset ───────────────────────────────────────────────────────────────

	/** Clear all listeners and the reverse-lookup map. */
	public function reset():Void
	{
		_listeners     = new Map();
		_handleToEvent = new Map();
	}
}

// ─── Internal type ───────────────────────────────────────────────────────────

private typedef ListenerEntry =
{
	var handle:Int;
	var owner:String;
	var fn:Dynamic->Void;
}

// ─── Well-known event names ───────────────────────────────────────────────────

class BusEvents
{
	// Gameplay
	public static inline final NOTE_HIT        = "noteHit";
	public static inline final NOTE_MISS       = "noteMiss";
	public static inline final CPU_NOTE_HIT    = "cpuNoteHit";
	public static inline final NOTE_SPAWN      = "noteSpawn";
	public static inline final HEALTH_CHANGE   = "healthChange";
	public static inline final SCORE_UPDATE    = "scoreUpdate";
	public static inline final GAME_OVER       = "gameOver";
	public static inline final RETRY           = "retry";

	// Song
	public static inline final SONG_START      = "songStart";
	public static inline final SONG_END        = "songEnd";
	public static inline final BEAT_HIT        = "beatHit";
	public static inline final STEP_HIT        = "stepHit";
	public static inline final COUNTDOWN_START = "countdownStart";
	public static inline final COUNTDOWN_TICK  = "countdownTick";
	public static inline final CHART_EVENT     = "chartEvent";

	// States
	public static inline final STATE_CREATE    = "stateCreate";
	public static inline final STATE_DESTROY   = "stateDestroy";
	public static inline final STATE_SWITCH    = "stateSwitch";
	public static inline final SUBSTATE_OPEN   = "substateOpen";
	public static inline final SUBSTATE_CLOSE  = "substateClose";

	// Menus
	public static inline final MENU_SELECT     = "menuSelect";
	public static inline final SONG_SELECTED   = "songSelected";
	public static inline final WEEK_SELECTED   = "weekSelected";

	// Input
	public static inline final KEY_DOWN        = "keyDown";
	public static inline final KEY_UP          = "keyUp";
}
