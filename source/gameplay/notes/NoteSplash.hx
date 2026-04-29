package gameplay.notes;

import systems.rendering.ColorSwap;

class NoteSplash extends FlxSprite
{
	public var colorSwap:ColorSwap;
	
	public function new(x:Float = 0, y:Float = 0, ?noteData:Int = 0)
	{
		super(x, y);
		
		frames = Paths.getSparrowAtlas('noteSplashes');
		
		animation.addByPrefix('note1-0', 'note splash purple 1', 24, false);
		animation.addByPrefix('note2-0', 'note splash purple 2', 24, false);
		animation.addByPrefix('note0-1', 'note splash blue 1', 24, false);
		animation.addByPrefix('note1-1', 'note splash blue 2', 24, false);
		animation.addByPrefix('note2-1', 'note splash blue 3', 24, false);
		animation.addByPrefix('note0-2', 'note splash green 1', 24, false);
		animation.addByPrefix('note1-2', 'note splash green 2', 24, false);
		animation.addByPrefix('note0-3', 'note splash red 1', 24, false);
		animation.addByPrefix('note1-3', 'note splash red 2', 24, false);
		
		setupNoteSplash(x, y, noteData);
		
		antialiasing = Preferences.data.antialiasing;
	}
	
	public function setupNoteSplash(x:Float, y:Float, noteData:Int = 0)
	{
		setPosition(x, y);
		alpha = 0.6;
		
		animation.play('note' + FlxG.random.int(0, 2) + '-' + noteData, true);
		animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
		updateHitbox();
		
		offset.set(width * 0.3, height * 0.3);
	}
	
	override function update(elapsed:Float)
	{
		if (animation.curAnim.finished)
			kill();
			
		super.update(elapsed);
	}
}
