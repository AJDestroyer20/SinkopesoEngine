package systems.scripting;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

#if hscript_iris
import iris.Iris;
#end

class HScriptIrisRuntime implements IScriptRuntime
{
	public var active(default, null):Bool = true;
	public var path(default, null):String;

	#if hscript_iris
	private var interpreter:Iris;
	private var scriptScope:Dynamic;
	#else
	private var scriptScope:Map<String, Dynamic>;
	#end

	public function new(path:String)
	{
		this.path = path;

		if (!FileSystem.exists(path))
		{
			active = false;
			return;
		}

		#if hscript_iris
		interpreter = new Iris();
		scriptScope = {};
		var source = File.getContent(path);
		interpreter.execute(source, scriptScope, Path.withoutDirectory(path));
		#else
		scriptScope = new Map<String, Dynamic>();
		#end
	}

	public function call(functionName:String, ?args:Array<Dynamic>):Dynamic
	{
		if (!active)
			return null;

		if (args == null)
			args = [];

		#if hscript_iris
		var fn:Dynamic = Reflect.field(scriptScope, functionName);
		return fn != null ? Reflect.callMethod(scriptScope, fn, args) : null;
		#else
		return null;
		#end
	}

	public function set(variable:String, value:Dynamic):Void
	{
		if (!active)
			return;

		#if hscript_iris
		Reflect.setField(scriptScope, variable, value);
		#else
		scriptScope.set(variable, value);
		#end
	}

	public function stop():Void
	{
		active = false;
	}
}
