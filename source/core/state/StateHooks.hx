package core.state;

class StateHooks
{
	private var state:Dynamic;

	public function new(state:Dynamic)
	{
		this.state = state;
	}

	public inline function onCreate():Void run("onCreate", []);
	public inline function onUpdate(elapsed:Float):Void run("onUpdate", [elapsed]);
	public inline function onBeat(beat:Int):Void run("onBeatHit", [beat]);
	public inline function onPause():Void run("onPause", []);
	public inline function onResume():Void run("onResume", []);
	public inline function onSongSelected(song:String):Void run("onSongSelected", [song]);
	public inline function onOptionSelected(option:String):Void run("onOptionSelected", [option]);
	public inline function onGameEnd():Void run("onGameEnd", []);

	private function run(name:String, args:Array<Dynamic>):Void
	{
		if (state == null || !Reflect.hasField(state, name))
			return;
		Reflect.callMethod(state, Reflect.field(state, name), args);
	}
}
