package systems.rendering;

import flixel.math.FlxMatrix;
import openfl.geom.Matrix;
import openfl.geom.Point;

class Pseudo25DRenderer
{
	public var perspective:Float = 500;
	public var fov:Float = 60;
	
	public var cameraX:Float = 0;
	public var cameraY:Float = 0;
	public var cameraZ:Float = 0;
	
	public var rotationX:Float = 0;
	public var rotationY:Float = 0;
	public var rotationZ:Float = 0;
	
	private var centerX:Float;
	private var centerY:Float;
	
	public function new(centerX:Float, centerY:Float)
	{
		this.centerX = centerX;
		this.centerY = centerY;
	}
	
	public function project3DTo2D(x:Float, y:Float, z:Float):Point
	{
		var translatedX:Float = x - cameraX;
		var translatedY:Float = y - cameraY;
		var translatedZ:Float = z - cameraZ;
		
		var rotatedX:Float = translatedX;
		var rotatedY:Float = translatedY;
		var rotatedZ:Float = translatedZ;
		
		if (rotationY != 0)
		{
			var cosY:Float = Math.cos(rotationY);
			var sinY:Float = Math.sin(rotationY);
			
			var tempX:Float = rotatedX * cosY - rotatedZ * sinY;
			var tempZ:Float = rotatedX * sinY + rotatedZ * cosY;
			
			rotatedX = tempX;
			rotatedZ = tempZ;
		}
		
		if (rotationX != 0)
		{
			var cosX:Float = Math.cos(rotationX);
			var sinX:Float = Math.sin(rotationX);
			
			var tempY:Float = rotatedY * cosX - rotatedZ * sinX;
			var tempZ:Float = rotatedY * sinX + rotatedZ * cosX;
			
			rotatedY = tempY;
			rotatedZ = tempZ;
		}
		
		if (rotationZ != 0)
		{
			var cosZ:Float = Math.cos(rotationZ);
			var sinZ:Float = Math.sin(rotationZ);
			
			var tempX:Float = rotatedX * cosZ - rotatedY * sinZ;
			var tempY:Float = rotatedX * sinZ + rotatedY * cosZ;
			
			rotatedX = tempX;
			rotatedY = tempY;
		}
		
		var scale:Float = perspective / (perspective + rotatedZ);
		
		var screenX:Float = centerX + (rotatedX * scale);
		var screenY:Float = centerY + (rotatedY * scale);
		
		return new Point(screenX, screenY);
	}
	
	public function getScaleForZ(z:Float):Float
	{
		var translatedZ:Float = z - cameraZ;
		return perspective / (perspective + translatedZ);
	}
	
	public function applyPerspective(sprite:FlxSprite, x:Float, y:Float, z:Float):Void
	{
		var projected:Point = project3DTo2D(x, y, z);
		var scale:Float = getScaleForZ(z);
		
		sprite.x = projected.x;
		sprite.y = projected.y;
		sprite.scale.set(scale, scale);
		sprite.updateHitbox();
	}
	
	public function setCamera(x:Float, y:Float, z:Float):Void
	{
		cameraX = x;
		cameraY = y;
		cameraZ = z;
	}
	
	public function setRotation(x:Float, y:Float, z:Float):Void
	{
		rotationX = x * (Math.PI / 180);
		rotationY = y * (Math.PI / 180);
		rotationZ = z * (Math.PI / 180);
	}
	
	public function rotateCamera(deltaX:Float, deltaY:Float, deltaZ:Float):Void
	{
		rotationX += deltaX * (Math.PI / 180);
		rotationY += deltaY * (Math.PI / 180);
		rotationZ += deltaZ * (Math.PI / 180);
	}
	
	public function moveCamera(deltaX:Float, deltaY:Float, deltaZ:Float):Void
	{
		cameraX += deltaX;
		cameraY += deltaY;
		cameraZ += deltaZ;
	}
	
	public function lerpCamera(targetX:Float, targetY:Float, targetZ:Float, ratio:Float):Void
	{
		cameraX = FlxMath.lerp(cameraX, targetX, ratio);
		cameraY = FlxMath.lerp(cameraY, targetY, ratio);
		cameraZ = FlxMath.lerp(cameraZ, targetZ, ratio);
	}
	
	public function reset():Void
	{
		cameraX = 0;
		cameraY = 0;
		cameraZ = 0;
		rotationX = 0;
		rotationY = 0;
		rotationZ = 0;
	}
}

class Pseudo25DSprite extends FlxSprite
{
	public var x3D:Float = 0;
	public var y3D:Float = 0;
	public var z3D:Float = 0;
	
	public var renderer:Pseudo25DRenderer;
	
	public function new(renderer:Pseudo25DRenderer, x:Float = 0, y:Float = 0, z:Float = 0)
	{
		super();
		
		this.renderer = renderer;
		this.x3D = x;
		this.y3D = y;
		this.z3D = z;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (renderer != null)
		{
			renderer.applyPerspective(this, x3D, y3D, z3D);
		}
	}
	
	public function setPosition3D(x:Float, y:Float, z:Float):Void
	{
		this.x3D = x;
		this.y3D = y;
		this.z3D = z;
	}
	
	public function move3D(deltaX:Float, deltaY:Float, deltaZ:Float):Void
	{
		x3D += deltaX;
		y3D += deltaY;
		z3D += deltaZ;
	}
}
