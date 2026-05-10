package gameplay.characters;

import core.enums.CharacterType;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.Json;

class CharacterSprite extends FlxSprite
{
	public var animOffsets:Map<String, Array<Float>>;
	public var debugMode:Bool = false;
	
	public var isPlayer:Bool = false;
	public var curCharacter:String = 'bf';
	public var characterType:CharacterType;
	
	public var holdTimer:Float = 0;
	public var idleTimer:Float = 0;
	
	public var animationNotes:Array<Dynamic> = [];
	
	public var danceIdle:Bool = false;
	public var skipDance:Bool = false;
	
	public var singDuration:Float = 4;
	public var danceEveryNumBeats:Int = 2;
	private var danced:Bool = false;
	
	public var healthIcon:String = 'face';
	public var healthColorArray:Array<Int> = [255, 0, 0];
	
	public function new(x:Float, y:Float, character:String = 'bf', characterType:CharacterType = PLAYER)
	{
		super(x, y);
		
		animOffsets = new Map<String, Array<Float>>();
		curCharacter = character;
		this.characterType = characterType;
		this.isPlayer = characterType == PLAYER;
		
		antialiasing = Preferences.data.antialiasing;
		
		switch (curCharacter)
		{
			case 'bf' | 'bf-car' | 'bf-christmas' | 'bf-pixel':
				loadCharacterFile(curCharacter);
				
			case 'dad' | 'spooky' | 'mom' | 'mom-car' | 'monster' | 'pico':
				loadCharacterFile(curCharacter);
				
			case 'gf' | 'gf-christmas' | 'gf-car' | 'gf-pixel':
				loadCharacterFile(curCharacter);
				danceIdle = true;
				
			default:
				loadCharacterFile(curCharacter);
		}
		
		if (isPlayer)
		{
			flipX = !flipX;
		}
	}
	
	public function loadCharacterFile(character:String):Void
	{
		var characterPath:String = 'data/characters/' + character + '.json';
		
		var rawJson:String = null;
		
		if (sys.FileSystem.exists(Paths.json(characterPath)))
		{
			rawJson = sys.io.File.getContent(Paths.json(characterPath));
		}
		else if (sys.FileSystem.exists(characterPath))
		{
			rawJson = sys.io.File.getContent(characterPath);
		}
		
		if (rawJson != null)
		{
			var json:Character = cast Json.parse(rawJson);
			
			if (json.image != null)
			{
				var tex:FlxAtlasFrames = Paths.getSparrowAtlas(json.image);
				frames = tex;
			}
			
			if (json.scale != null)
			{
				setGraphicSize(Std.int(width * json.scale));
				updateHitbox();
			}
			
			if (json.animations != null)
			{
				for (anim in json.animations)
				{
					if (anim.indices != null && anim.indices.length > 0)
					{
						animation.addByIndices(anim.name, anim.prefix, anim.indices, '', anim.fps, anim.loop);
					}
					else
					{
						animation.addByPrefix(anim.name, anim.prefix, anim.fps, anim.loop);
					}
					
					if (anim.offsets != null && anim.offsets.length >= 2)
					{
						addOffset(anim.name, anim.offsets[0], anim.offsets[1]);
					}
				}
			}
			
			if (json.healthIcon != null)
				healthIcon = json.healthIcon;
				
			if (json.singDuration != null)
				singDuration = json.singDuration;
				
			if (json.healthColorArray != null)
				healthColorArray = json.healthColorArray;
				
			if (json.flipX != null)
				flipX = json.flipX;
				
			antialiasing = json.antialiasing != null ? json.antialiasing : true;
			
			if (animation.getByName('danceLeft') != null && animation.getByName('danceRight') != null)
				danceIdle = true;
		}
		else
		{
			trace('Character file not found: $characterPath');
		}
		
		if (animation.getByName('idle') != null)
			playAnim('idle');
		else if (animation.getByName('danceLeft') != null)
			playAnim('danceLeft');
	}
	
	override function update(elapsed:Float)
	{
		if (!debugMode)
		{
			if (animation.curAnim != null)
			{
				if (animation.curAnim.name.startsWith('sing'))
				{
					holdTimer += elapsed;
				}
				
				if (holdTimer >= Conductor.stepCrochet * singDuration * 0.001)
				{
					dance();
					holdTimer = 0;
				}
			}
		}
		
		super.update(elapsed);
	}
	
	public function dance()
	{
		if (!debugMode && !skipDance)
		{
			if (danceIdle)
			{
				danced = !danced;
				
				if (danced)
					playAnim('danceRight');
				else
					playAnim('danceLeft');
			}
			else
			{
				playAnim('idle');
			}
		}
	}
	
	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		animation.play(AnimName, Force, Reversed, Frame);
		
		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			offset.set(0, 0);
	}
	
	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}
}
