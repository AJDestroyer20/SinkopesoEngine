package scripting;

/**
 * IScriptBackend
 * 
 * Common interface that every scripting backend must implement.
 * Backends: HaxeScript, Lua, XML, JSON, TXT
 */
interface IScriptBackend
{
	/** Absolute or relative path to the script file */
	public var path:String;

	/** Whether this script has been destroyed */
	public var destroyed:Bool;

	/** Load and parse the script from disk */
	public function load():Void;

	/** Call a named function/callback in this script */
	public function call(func:String, args:Array<Dynamic>):Dynamic;

	/** Set a variable in this script's scope */
	public function setVar(name:String, value:Dynamic):Void;

	/** Get a variable from this script's scope */
	public function getVar(name:String):Dynamic;

	/** Cleanup resources */
	public function destroy():Void;
}
