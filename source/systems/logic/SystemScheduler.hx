package systems.logic;

class SystemScheduler
{
	public var logicSystems:Array<LogicSystem> = [];
	public var renderSystems:Array<RenderSystem> = [];

	public function new() {}

	public function addLogic(system:LogicSystem):Void logicSystems.push(system);
	public function addRender(system:RenderSystem):Void renderSystems.push(system);

	public function update(elapsed:Float):Void
	{
		for (s in logicSystems) s.updateLogic(elapsed);
	}

	public function render():Void
	{
		for (s in renderSystems) s.renderFrame();
	}
}
