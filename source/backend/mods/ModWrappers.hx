package backend.mods;

interface IPathResolver
{
	function chartsPath():String;
	function scriptsPath():String;
	function assetsPath():String;
}

interface IScriptApiWrapper
{
	function normalizeCallback(name:String):String;
	function normalizeProperty(name:String):String;
}

class ModWrappers
{
	public static function create(flavor:ModFlavor):ModWrapperSet
	{
		return switch (flavor)
		{
			case Native: makeNative();
			case Psych | AlePsych: makePsych();
			case Codename: makeCodename();
			case VSlice: makeVSlice();
		};
	}

	static function makeNative():ModWrapperSet
	{
		return {
			pathResolver: new StaticPathResolver('data', 'scripts', 'assets'),
			scriptApi: new PassThroughApiWrapper()
		};
	}

	static function makePsych():ModWrapperSet
	{
		return {
			pathResolver: new StaticPathResolver('data', 'scripts', 'images'),
			scriptApi: new PsychApiWrapper()
		};
	}

	static function makeCodename():ModWrapperSet
	{
		return {
			pathResolver: new StaticPathResolver('songs', 'scripts', 'mods'),
			scriptApi: new CodenameApiWrapper()
		};
	}

	static function makeVSlice():ModWrapperSet
	{
		return {
			pathResolver: new StaticPathResolver('songs', 'scripts', 'assets'),
			scriptApi: new VSliceApiWrapper()
		};
	}
}

private class StaticPathResolver implements IPathResolver
{
	var charts:String;
	var scripts:String;
	var assets:String;

	public function new(charts:String, scripts:String, assets:String)
	{
		this.charts = charts;
		this.scripts = scripts;
		this.assets = assets;
	}

	public function chartsPath():String return charts;
	public function scriptsPath():String return scripts;
	public function assetsPath():String return assets;
}

private class PassThroughApiWrapper implements IScriptApiWrapper
{
	public function new() {}
	public function normalizeCallback(name:String):String return name;
	public function normalizeProperty(name:String):String return name;
}

private class PsychApiWrapper extends PassThroughApiWrapper
{
	override public function normalizeCallback(name:String):String
	{
		return switch (name)
		{
			case 'onSongStart': 'onCreatePost';
			default: name;
		};
	}
}

private class CodenameApiWrapper extends PassThroughApiWrapper {}
private class VSliceApiWrapper extends PassThroughApiWrapper {}
