package core.structures;

import core.enums.CharacterType;

typedef Character =
{
	var animations:Array<CharacterAnimation>;
	var image:String;
	var scale:Float;
	var position:Array<Float>;
	var cameraPosition:Array<Float>;
	var healthIcon:String;
	var flipX:Bool;
	var antialiasing:Bool;
	var singDuration:Float;
	var healthColorArray:Array<Int>;
}

typedef CharacterAnimation =
{
	var name:String;
	var prefix:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Float>;
}
