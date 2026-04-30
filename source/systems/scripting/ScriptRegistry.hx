package systems.scripting;

class ScriptRegistry
{
	private var constructors:Map<String, String->IScriptBackend> = [];

	public function new() {}

	public function register(backendName:String, ctor:String->IScriptBackend):Void
	{
		constructors.set(backendName, ctor);
	}

	public function create(backendName:String, path:String):IScriptBackend
	{
		return constructors.exists(backendName) ? constructors.get(backendName)(path) : null;
	}
}
