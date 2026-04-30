package systems.camera;

class CameraController
{
	public var camera:FlxCamera;
	public var target:FlxObject;
	public var baseZoom:Float = 1;
	public var beatZoomAmount:Float = 0.015;

	public function new(camera:FlxCamera)
	{
		this.camera = camera;
	}

	public function followTarget(target:FlxObject):Void
	{
		this.target = target;
		camera.follow(target, LOCKON, 0.08);
	}

	public function beatZoom(mult:Float = 1):Void
	{
		camera.zoom += beatZoomAmount * mult;
	}

	public function shake(intensity:Float = 0.01, duration:Float = 0.15):Void
	{
		camera.shake(intensity, duration);
	}

	public function flash(color:FlxColor = FlxColor.WHITE, duration:Float = 0.2):Void
	{
		camera.flash(color, duration);
	}

	public function tweenZoom(to:Float, duration:Float = 0.2):Void
	{
		flixel.tweens.FlxTween.num(camera.zoom, to, duration, {onUpdate: function(v) camera.zoom = v});
	}
}
