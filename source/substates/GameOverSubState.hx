package substates;

import backend.MusicBeatSubState;
import gameplay.characters.CharacterSprite;

class GameOverSubState extends MusicBeatSubState
{
	var bf:CharacterSprite;
	var camFollow:FlxObject;
	
	var stageSuffix:String = "";
	var deathSoundName:String = 'fnf_loss_sfx';
	var loopSoundName:String = 'gameOver';
	var endSoundName:String = 'gameOverEnd';
	
	var isEnding:Bool = false;
	
	public function new(x:Float, y:Float)
	{
		super();
		
		Conductor.songPosition = 0;
		
		bf = new CharacterSprite(x, y, 'bf-dead', PLAYER);
		add(bf);
		
		camFollow = new FlxObject(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y, 1, 1);
		add(camFollow);
		
		FlxG.sound.play(Paths.sound(deathSoundName));
		Conductor.changeBPM(100);
		
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;
		
		bf.playAnim('firstDeath');
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (controls.ACCEPT)
		{
			endBullshit();
		}
		
		if (controls.BACK)
		{
			FlxG.sound.music.stop();
			
			if (PlayState.isStoryMode)
				FlxG.switchState(new states.TitleState());
			else
				FlxG.switchState(new states.TitleState());
		}
		
		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished)
		{
			FlxG.sound.playMusic(Paths.music(loopSoundName));
		}
		
		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
	}
	
	override function beatHit()
	{
		super.beatHit();
	}
	
	var isFollowingAlready:Bool = false;
	
	function coolStartDeath(?volume:Float = 1):Void
	{
		FlxG.sound.playMusic(Paths.music(loopSoundName), volume);
	}
	
	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			bf.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					FlxG.resetState();
				});
			});
		}
	}
}
