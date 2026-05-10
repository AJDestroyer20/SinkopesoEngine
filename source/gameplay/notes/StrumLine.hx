package gameplay.notes;

import core.enums.CharacterType;
import flixel.group.FlxGroup.FlxTypedGroup;

class StrumLine extends FlxTypedGroup<Strum>
{
	public var characterType:CharacterType;
	
	public static var STRUM_SIZE:Int = 4;
	
	public function new(characterType:CharacterType)
	{
		super(STRUM_SIZE);
		
		this.characterType = characterType;
		
		for (i in 0...STRUM_SIZE)
		{
			var babyArrow:Strum = new Strum(0, 0, i, characterType);
			
			babyArrow.downScroll = Preferences.data.downScroll;
			
			if (characterType == PLAYER)
			{
				babyArrow.x += Note.swagWidth * i;
				babyArrow.x += 50;
				babyArrow.x += ((FlxG.width / 2) * 1);
			}
			else
			{
				babyArrow.x += Note.swagWidth * i;
				babyArrow.x += 50;
			}
			
			if (Preferences.data.middleScroll)
			{
				babyArrow.x -= 320;
				if (characterType == OPPONENT)
					babyArrow.visible = false;
			}
			
			babyArrow.y = 50;
			babyArrow.playAnim('static');
			
			add(babyArrow);
		}
	}
	
	public function playAnim(index:Int, anim:String, ?force:Bool = false):Void
	{
		if (members[index] != null)
			members[index].playAnim(anim, force);
	}
}
