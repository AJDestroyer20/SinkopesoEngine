package core.structures;

typedef Stage =
{
	var name:String;
	var objects:Array<StageObject>;
	var defaultZoom:Float;
	var cameraSpeed:Float;
	var boyfriend:Array<Float>;
	var girlfriend:Array<Float>;
	var opponent:Array<Float>;
}

typedef StageObject =
{
	var type:String;
	var image:String;
	var position:Array<Float>;
	var scrollFactor:Array<Float>;
	var scale:Array<Float>;
	var antialiasing:Bool;
	var layer:Int;
	var ?animation:String;
	var ?fps:Int;
	var ?color:String;
}
