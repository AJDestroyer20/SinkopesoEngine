package core.events;

typedef EventHandler = Dynamic->Void;

class EventBus
{
	private var listeners:Map<String, Array<EventHandler>> = [];

	public function new() {}

	public function subscribe(eventName:String, handler:EventHandler):Void
	{
		if (!listeners.exists(eventName))
			listeners.set(eventName, []);
		listeners[eventName].push(handler);
	}

	public function unsubscribe(eventName:String, handler:EventHandler):Void
	{
		if (!listeners.exists(eventName))
			return;
		listeners[eventName].remove(handler);
	}

	public function publish(eventName:String, payload:Dynamic = null):Void
	{
		if (!listeners.exists(eventName))
			return;

		for (handler in listeners[eventName])
			handler(payload);
	}
}
