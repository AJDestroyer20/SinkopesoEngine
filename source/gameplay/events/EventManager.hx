package gameplay.events;

class EventManager
{
	public var events:Array<ChartEvent> = [];
	
	public function new()
	{
	}
	
	public function loadEvents(songEvents:Array<Dynamic>):Void
	{
		events = [];
		
		if (songEvents == null || songEvents.length == 0)
			return;
			
		for (event in songEvents)
		{
			var chartEvent:ChartEvent = {
				time: event[0],
				name: event[1],
				value1: event[2],
				value2: event[3]
			};
			
			events.push(chartEvent);
		}
		
		events.sort(function(a:ChartEvent, b:ChartEvent):Int
		{
			if (a.time < b.time)
				return -1;
			else if (a.time > b.time)
				return 1;
			else
				return 0;
		});
	}
	
	public function checkEvents(songPosition:Float):Void
	{
		while (events.length > 0 && events[0].time <= songPosition)
		{
			var event:ChartEvent = events.shift();
			triggerEvent(event);
		}
	}
	
	public function triggerEvent(event:ChartEvent):Void
	{
		trace('Event triggered: ${event.name} at ${event.time}');
		
		switch (event.name)
		{
			case 'Camera Flash':
				flashCamera(event.value1);
			case 'Camera Zoom':
				zoomCamera(event.value1);
			case 'Change BPM':
				changeBPM(event.value1);
			default:
				trace('Unknown event: ${event.name}');
		}
	}
	
	private function flashCamera(intensity:Dynamic):Void
	{
		var color:FlxColor = FlxColor.WHITE;
		var duration:Float = 0.5;
		
		if (Std.string(intensity).length > 0)
		{
			duration = Std.parseFloat(Std.string(intensity));
		}
		
		FlxG.camera.flash(color, duration);
	}
	
	private function zoomCamera(amount:Dynamic):Void
	{
		var zoomAmount:Float = 0.015;
		
		if (Std.string(amount).length > 0)
		{
			zoomAmount = Std.parseFloat(Std.string(amount));
		}
		
		FlxG.camera.zoom += zoomAmount;
	}
	
	private function changeBPM(newBPM:Dynamic):Void
	{
		if (Std.string(newBPM).length > 0)
		{
			var bpm:Float = Std.parseFloat(Std.string(newBPM));
			Conductor.changeBPM(bpm);
		}
	}
}

typedef ChartEvent =
{
	var time:Float;
	var name:String;
	var value1:Dynamic;
	var value2:Dynamic;
}
