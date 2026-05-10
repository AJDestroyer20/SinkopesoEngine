package gameplay.characters;

import core.enums.CharacterType;

class CharacterManager
{
	public var boyfriend:CharacterSprite;
	public var dad:CharacterSprite;
	public var gf:CharacterSprite;
	
	public function new()
	{
	}
	
	public function loadCharacters(bfChar:String, dadChar:String, gfChar:String):Void
	{
		boyfriend = new CharacterSprite(770, 450, bfChar, PLAYER);
		dad = new CharacterSprite(100, 100, dadChar, OPPONENT);
		gf = new CharacterSprite(400, 130, gfChar, GIRLFRIEND);
	}
	
	public function addCharactersToState(state:FlxState):Void
	{
		state.add(gf);
		state.add(dad);
		state.add(boyfriend);
	}
	
	public function dance():Void
	{
		if (gf != null)
			gf.dance();
		if (dad != null)
			dad.dance();
		if (boyfriend != null)
			boyfriend.dance();
	}
	
	public function beatHit():Void
	{
		if (gf != null && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith('sing'))
			gf.dance();
			
		if (dad != null && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing'))
			dad.dance();
			
		if (boyfriend != null && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing'))
			boyfriend.dance();
	}
}
