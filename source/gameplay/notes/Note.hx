package gameplay.notes;

import core.enums.NoteType;
import core.enums.NoteState;
import core.enums.CharacterType;

class Note extends FlxSprite
{
	public var strumTime:Float = 0;
	public var noteData:Int = 0;
	
	public var mustPress:Bool = false;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;
	
	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var isSustainEnd:Bool = false;
	
	public var noteType:NoteType = NORMAL;
	public var noteState:NoteState = NEUTRAL;
	
	public var noteVariant:String = '';
	public var characterType:CharacterType;
	
	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
	
	public var noteScore:Float = 350;
	
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	
	public var multAlpha:Float = 1;
	
	public static var swagWidth:Float = 160 * 0.7;
	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;

	public var texture(default, set):String;
	
	private function set_texture(value:String):String
	{
		if (texture != value)
		{
			reloadNote(value);
		}
		texture = value;
		return value;
	}
	
	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?noteVariant:String = '', ?characterType:CharacterType)
	{
		super();
		
		if (prevNote == null)
			prevNote = this;
			
		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.noteVariant = noteVariant;
		this.characterType = characterType != null ? characterType : OPPONENT;
		
		x += 50;
		y -= 2000;
		
		this.strumTime = strumTime;
		this.noteData = noteData;
		
		if (this.characterType == PLAYER)
			mustPress = true;
		
		var daStage:String = PlayState.curStage;
		
		switch (daStage)
		{
			case 'school' | 'schoolEvil':
				loadGraphic(Paths.image('weeb/pixelUI/arrows-pixels', 'week6'), true, 17, 17);
				
				animation.add('greenScroll', [6]);
				animation.add('redScroll', [7]);
				animation.add('blueScroll', [5]);
				animation.add('purpleScroll', [4]);
				
				if (isSustainNote)
				{
					loadGraphic(Paths.image('weeb/pixelUI/arrowEnds', 'week6'), true, 7, 6);
					
					animation.add('purpleholdend', [4]);
					animation.add('greenholdend', [6]);
					animation.add('redholdend', [7]);
					animation.add('blueholdend', [5]);
					
					animation.add('purplehold', [0]);
					animation.add('greenhold', [2]);
					animation.add('redhold', [3]);
					animation.add('bluehold', [1]);
				}
				
				setGraphicSize(Std.int(width * CoolUtil.daPixelZoom));
				updateHitbox();
				
			default:
				frames = Paths.getSparrowAtlas('NOTE_assets');
				
				animation.addByPrefix('greenScroll', 'green0');
				animation.addByPrefix('redScroll', 'red0');
				animation.addByPrefix('blueScroll', 'blue0');
				animation.addByPrefix('purpleScroll', 'purple0');
				
				animation.addByPrefix('purpleholdend', 'pruple end hold');
				animation.addByPrefix('greenholdend', 'green hold end');
				animation.addByPrefix('redholdend', 'red hold end');
				animation.addByPrefix('blueholdend', 'blue hold end');
				
				animation.addByPrefix('purplehold', 'purple hold piece');
				animation.addByPrefix('greenhold', 'green hold piece');
				animation.addByPrefix('redhold', 'red hold piece');
				animation.addByPrefix('bluehold', 'blue hold piece');
				
				setGraphicSize(Std.int(width * 0.7));
				updateHitbox();
				antialiasing = Preferences.data.antialiasing;
		}
		
		var color:Array<String> = ['purple', 'blue', 'green', 'red'];
		
		x += swagWidth * noteData;
		animation.play(color[noteData] + 'Scroll');
		
		if (isSustainNote && prevNote != null)
		{
			noteScore * 0.2;
			alpha = 0.6;
			multAlpha = 0.6;
			
			offsetX += width / 2;
			
			animation.play(color[noteData] + 'holdend');
			
			updateHitbox();
			
			offsetX -= width / 2;
			
			if (PlayState.curStage.startsWith('school'))
				offsetX += 30;
			
			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(color[prevNote.noteData] + 'hold');
				
				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * PlayState.SONG.speed;
				prevNote.updateHitbox();
			}
		}
	}
	
	private function reloadNote(texture:String = '')
	{
		if (texture == null || texture.length < 1)
			texture = 'NOTE_assets';
			
		var lastAnim:String = null;
		if (animation.curAnim != null)
			lastAnim = animation.curAnim.name;
			
		var arraySkin:Array<String> = texture.split('/');
		arraySkin[arraySkin.length - 1] = arraySkin[arraySkin.length - 1];
		
		var blahblah:String = arraySkin.join('/');
		
		if (PlayState.curStage.startsWith('school'))
		{
			loadGraphic(Paths.image('weeb/pixelUI/arrows-pixels', 'week6'), true, 17, 17);
			
			animation.add('greenScroll', [6]);
			animation.add('redScroll', [7]);
			animation.add('blueScroll', [5]);
			animation.add('purpleScroll', [4]);
			
			if (isSustainNote)
			{
				loadGraphic(Paths.image('weeb/pixelUI/arrowEnds', 'week6'), true, 7, 6);
				
				animation.add('purpleholdend', [4]);
				animation.add('greenholdend', [6]);
				animation.add('redholdend', [7]);
				animation.add('blueholdend', [5]);
				
				animation.add('purplehold', [0]);
				animation.add('greenhold', [2]);
				animation.add('redhold', [3]);
				animation.add('bluehold', [1]);
			}
			
			setGraphicSize(Std.int(width * CoolUtil.daPixelZoom));
			updateHitbox();
		}
		else
		{
			frames = Paths.getSparrowAtlas(blahblah);
			
			animation.addByPrefix('greenScroll', 'green0');
			animation.addByPrefix('redScroll', 'red0');
			animation.addByPrefix('blueScroll', 'blue0');
			animation.addByPrefix('purpleScroll', 'purple0');
			
			animation.addByPrefix('purpleholdend', 'pruple end hold');
			animation.addByPrefix('greenholdend', 'green hold end');
			animation.addByPrefix('redholdend', 'red hold end');
			animation.addByPrefix('blueholdend', 'blue hold end');
			
			animation.addByPrefix('purplehold', 'purple hold piece');
			animation.addByPrefix('greenhold', 'green hold piece');
			animation.addByPrefix('redhold', 'red hold piece');
			animation.addByPrefix('bluehold', 'blue hold piece');
			
			setGraphicSize(Std.int(width * 0.7));
			updateHitbox();
			antialiasing = Preferences.data.antialiasing;
		}
		
		if (lastAnim != null)
		{
			animation.play(lastAnim, true);
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (mustPress)
		{
			canBeHit = (strumTime > Conductor.songPosition - Conductor.safeZoneOffset
				&& strumTime < Conductor.songPosition + Conductor.safeZoneOffset);
				
			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;
			
			if (strumTime <= Conductor.songPosition)
				wasGoodHit = true;
		}
		
		if (tooLate)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}
}
