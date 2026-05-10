package substates;

import backend.MusicBeatSubState;

class StickersSubState extends MusicBeatSubState
{
	public var targetState:Class<FlxState>;
	
	private var stickers:FlxTypedGroup<FlxSprite>;
	private var stickerCount:Int = 8;
	
	private var isComplete:Bool = false;
	
	public function new(?targetState:Class<FlxState>)
	{
		super();
		
		this.targetState = targetState;
		
		stickers = new FlxTypedGroup<FlxSprite>();
		add(stickers);
		
		createStickers();
		animateStickersIn();
	}
	
	private function createStickers():Void
	{
		var stickerTypes:Array<String> = ['cool', 'good', 'great', 'loss', 'miss', 'shit', 'sick', 'combo'];
		
		for (i in 0...stickerCount)
		{
			var sticker:FlxSprite = new FlxSprite();
			
			var stickerType:String = FlxG.random.getObject(stickerTypes);
			
			sticker.loadGraphic(Paths.image('ui/stickers/$stickerType'));
			
			sticker.setGraphicSize(Std.int(sticker.width * FlxG.random.float(0.5, 1.5)));
			sticker.updateHitbox();
			
			sticker.x = FlxG.random.float(-200, FlxG.width + 200);
			sticker.y = FlxG.random.float(-200, FlxG.height + 200);
			
			sticker.angle = FlxG.random.float(-30, 30);
			sticker.alpha = 0;
			
			sticker.antialiasing = Preferences.data.antialiasing;
			
			stickers.add(sticker);
		}
	}
	
	private function animateStickersIn():Void
	{
		for (i in 0...stickers.length)
		{
			var sticker:FlxSprite = stickers.members[i];
			
			FlxTween.tween(sticker, {alpha: 1}, 0.5, {
				ease: FlxEase.elasticOut,
				startDelay: i * 0.1,
				onComplete: function(twn:FlxTween)
				{
					if (i == stickers.length - 1)
					{
						new FlxTimer().start(0.5, function(tmr:FlxTimer)
						{
							animateStickersOut();
						});
					}
				}
			});
			
			FlxTween.tween(sticker, {angle: sticker.angle + FlxG.random.float(-10, 10)}, 0.5, {
				ease: FlxEase.elasticOut,
				startDelay: i * 0.1
			});
		}
	}
	
	private function animateStickersOut():Void
	{
		for (i in 0...stickers.length)
		{
			var sticker:FlxSprite = stickers.members[i];
			
			var targetX:Float = FlxG.random.bool() ? -sticker.width : FlxG.width + sticker.width;
			var targetY:Float = FlxG.random.float(-sticker.height, FlxG.height + sticker.height);
			
			FlxTween.tween(sticker, {x: targetX, y: targetY, alpha: 0}, 0.6, {
				ease: FlxEase.backIn,
				startDelay: i * 0.05,
				onComplete: function(twn:FlxTween)
				{
					if (i == stickers.length - 1)
					{
						finishTransition();
					}
				}
			});
			
			FlxTween.tween(sticker.scale, {x: 0.1, y: 0.1}, 0.6, {
				ease: FlxEase.backIn,
				startDelay: i * 0.05
			});
		}
	}
	
	private function finishTransition():Void
	{
		isComplete = true;
		
		if (targetState != null)
		{
			FlxG.switchState(Type.createInstance(targetState, []));
		}
		else
		{
			close();
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
