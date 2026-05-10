package gameplay.notes;

import core.enums.CharacterType;
import systems.rendering.ColorSwap;

class Strum extends FlxSprite
{
	public var noteData:Int = 0;
	public var characterType:CharacterType;
	public var resetAnim:Float = 0;
	public var downScroll:Bool = false;
	
	public var colorSwap:ColorSwap;
	
	private var player:Int;
	
	public var texture(default, set):String;
	
	private function set_texture(value:String):String
	{
		if (texture != value)
		{
			texture = value;
			reloadNote();
		}
		return value;
	}
	
	public function new(x:Float, y:Float, noteData:Int, characterType:CharacterType)
	{
		super(x, y);
		
		this.noteData = noteData;
		this.characterType = characterType;
		this.player = characterType == PLAYER ? 1 : 0;
		
		colorSwap = new ColorSwap();
		
		var skin:String = 'NOTE_assets';
		if (PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1)
			skin = PlayState.SONG.arrowSkin;
			
		texture = skin;
		
		scrollFactor.set();
	}
	
	public function reloadNote()
	{
		var lastAnim:String = null;
		if (animation.curAnim != null)
			lastAnim = animation.curAnim.name;
			
		if (PlayState.curStage.startsWith('school'))
		{
			loadGraphic(Paths.image('weeb/pixelUI/arrows-pixels', 'week6'), true, 17, 17);
			
			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purple', [4]);
			
			setGraphicSize(Std.int(width * CoolUtil.daPixelZoom));
			updateHitbox();
			antialiasing = false;
			
			animation.add('static', [noteData]);
			animation.add('pressed', [4 + noteData, 8 + noteData], 12, false);
			animation.add('confirm', [12 + noteData, 16 + noteData], 24, false);
		}
		else
		{
			frames = Paths.getSparrowAtlas(texture);
			
			animation.addByPrefix('green', 'arrowUP');
			animation.addByPrefix('blue', 'arrowDOWN');
			animation.addByPrefix('purple', 'arrowLEFT');
			animation.addByPrefix('red', 'arrowRIGHT');
			
			antialiasing = Preferences.data.antialiasing;
			setGraphicSize(Std.int(width * 0.7));
			
			switch (Math.abs(noteData))
			{
				case 0:
					animation.addByPrefix('static', 'arrowLEFT');
					animation.addByPrefix('pressed', 'left press', 24, false);
					animation.addByPrefix('confirm', 'left confirm', 24, false);
				case 1:
					animation.addByPrefix('static', 'arrowDOWN');
					animation.addByPrefix('pressed', 'down press', 24, false);
					animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 2:
					animation.addByPrefix('static', 'arrowUP');
					animation.addByPrefix('pressed', 'up press', 24, false);
					animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					animation.addByPrefix('static', 'arrowRIGHT');
					animation.addByPrefix('pressed', 'right press', 24, false);
					animation.addByPrefix('confirm', 'right confirm', 24, false);
			}
		}
		
		updateHitbox();
		
		if (lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}
	
	public function playAnim(anim:String, ?force:Bool = false)
	{
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		
		if (animation.curAnim == null || animation.curAnim.name == 'static')
		{
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		}
		else
		{
			colorSwap.hue = 0;
			colorSwap.saturation = -20;
			colorSwap.brightness = 0;
			
			if (animation.curAnim.name == 'confirm' && !PlayState.curStage.startsWith('school'))
			{
				centerOrigin();
			}
		}
	}
	
	override function update(elapsed:Float)
	{
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;
			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}
		
		super.update(elapsed);
	}
}
