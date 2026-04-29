package utils;

class Alphabet extends FlxSpriteGroup
{
	public var text:String = "";
	
	public var bold:Bool = false;
	public var letters:Array<AlphaCharacter> = [];
	
	public var isMenuItem:Bool = false;
	public var targetY:Float = 0;
	
	public var distancePerItem:FlxPoint = new FlxPoint(20, 120);
	public var startPosition:FlxPoint = new FlxPoint(0, 0);
	
	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = false, typed:Bool = false)
	{
		super(x, y);
		
		startPosition.x = x;
		startPosition.y = y;
		
		this.bold = bold;
		this.text = text;
		
		if (text != "")
		{
			addText();
		}
	}
	
	public function addText()
	{
		doSplitWords();
	}
	
	function doSplitWords():Void
	{
		var xPos:Float = 0;
		for (character in text.split(''))
		{
			if (character == " ")
			{
				xPos += 40;
				continue;
			}
			
			if (AlphaCharacter.alphabet.indexOf(character.toLowerCase()) != -1)
			{
				var letter:AlphaCharacter = new AlphaCharacter(xPos, 0);
				letter.createLetter(character);
				
				add(letter);
				
				letters.push(letter);
				
				xPos += letter.width;
			}
		}
	}
	
	override function update(elapsed:Float)
	{
		if (isMenuItem)
		{
			var scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);
			
			y = FlxMath.lerp(y, (scaledY * distancePerItem.y) + startPosition.y, 0.16);
			x = FlxMath.lerp(x, (targetY * distancePerItem.x) + startPosition.x, 0.16);
		}
		
		super.update(elapsed);
	}
}

class AlphaCharacter extends FlxSprite
{
	public static var alphabet:String = "abcdefghijklmnopqrstuvwxyz|~#$%()*+-:;<=>@[]^_.,'!?0123456789";
	
	public var row:Int = 0;
	
	public function new(x:Float, y:Float)
	{
		super(x, y);
		
		var tex = Paths.getSparrowAtlas('alphabet');
		frames = tex;
		
		antialiasing = Preferences.data.antialiasing;
	}
	
	public function createLetter(character:String):Void
	{
		var letterCase:String = "lowercase";
		if (character.toLowerCase() != character)
		{
			letterCase = 'capital';
		}
		
		animation.addByPrefix(character, character + " " + letterCase, 24);
		animation.play(character);
		updateHitbox();
	}
}
