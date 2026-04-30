package gameplay.events.graph;

typedef EventGraphNode = {
	id:String,
	type:String,
	params:Dynamic,
	next:Array<String>
}

class EventGraph
{
	public var nodes:Map<String, EventGraphNode> = [];

	public function new() {}

	public function load(raw:Array<Dynamic>):Void
	{
		nodes = [];
		if (raw == null) return;
		for (n in raw)
		{
			var node:EventGraphNode = {
				id: n.id,
				type: n.type,
				params: n.params,
				next: n.next != null ? cast n.next : []
			};
			nodes.set(node.id, node);
		}
	}

	public function execute(startId:String, trigger:EventGraphNode->Void):Void
	{
		var current = nodes.get(startId);
		while (current != null)
		{
			trigger(current);
			if (current.next == null || current.next.length == 0) break;
			current = nodes.get(current.next[0]);
		}
	}
}
