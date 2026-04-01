package scripting.backends;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;

/**
 * LuaAPI
 * 
 * Centralized API exposed to Lua scripts.
 * Also usable from XML and JSON scripts as "action" targets.
 * 
 * ─── Sprite system ───────────────────────────────────────────────────────
 * Scripts can create, move, and destroy named sprites at runtime.
 * 
 * ─── Property reflection ─────────────────────────────────────────────────
 * setProperty / getProperty use Haxe Reflect to access any public field
 * on PlayState.instance at runtime — no hardcoding needed.
 */
class LuaAPI
{
	/** Named sprites created by scripts */
	static var managedSprites:Map<String, FlxSprite> = new Map();

	// ─── PROPERTIES ──────────────────────────────────────────────────────

	public static function setProperty(name:String, value:Dynamic):Void
	{
		if (PlayState.instance == null) return;
		try
		{
			Reflect.setProperty(PlayState.instance, name, value);
		}
		catch (e:Dynamic)
		{
			trace('[LuaAPI] setProperty failed: $name = $value ($e)');
		}
	}

	public static function getProperty(name:String):Dynamic
	{
		if (PlayState.instance == null) return null;
		try
		{
			return Reflect.getProperty(PlayState.instance, name);
		}
		catch (e:Dynamic)
		{
			trace('[LuaAPI] getProperty failed: $name ($e)');
			return null;
		}
	}

	// ─── SONG PROPERTIES ─────────────────────────────────────────────────

	public static function getSongProperty(name:String):Dynamic
	{
		if (PlayState.SONG == null) return null;
		return Reflect.getProperty(PlayState.SONG, name);
	}

	public static function setSongProperty(name:String, value:Dynamic):Void
	{
		if (PlayState.SONG == null) return;
		Reflect.setProperty(PlayState.SONG, name, value);
	}

	// ─── SPRITES ─────────────────────────────────────────────────────────

	public static function addSprite(tag:String, x:Float, y:Float, imagePath:String):Void
	{
		if (PlayState.instance == null) return;
		var spr = new FlxSprite(x, y);
		if (imagePath != null && imagePath != "")
			spr.loadGraphic(Paths.image(imagePath));
		else
			spr.makeGraphic(100, 100, flixel.util.FlxColor.WHITE);
		PlayState.instance.add(spr);
		managedSprites.set(tag, spr);
	}

	public static function removeSprite(tag:String):Void
	{
		if (!managedSprites.exists(tag)) return;
		var spr = managedSprites.get(tag);
		if (PlayState.instance != null) PlayState.instance.remove(spr);
		spr.destroy();
		managedSprites.remove(tag);
	}

	public static function setSpriteProperty(tag:String, prop:String, value:Dynamic):Void
	{
		if (!managedSprites.exists(tag)) return;
		Reflect.setProperty(managedSprites.get(tag), prop, value);
	}

	public static function tweenSprite(tag:String, props:Dynamic, duration:Float):Void
	{
		if (!managedSprites.exists(tag)) return;
		FlxTween.tween(managedSprites.get(tag), props, duration);
	}

	// ─── CAMERA ──────────────────────────────────────────────────────────

	public static function tweenCameraZoom(zoom:Float, lerpSpeed:Float):Void
	{
		if (PlayState.instance != null)
			PlayState.instance.defaultCamZoom = zoom;
	}

	// ─── CLEANUP ─────────────────────────────────────────────────────────

	public static function destroyAll():Void
	{
		for (tag => spr in managedSprites)
		{
			if (PlayState.instance != null) PlayState.instance.remove(spr);
			spr.destroy();
		}
		managedSprites.clear();
	}
}
