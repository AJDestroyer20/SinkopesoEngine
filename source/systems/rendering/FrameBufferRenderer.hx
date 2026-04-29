package systems.rendering;

import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.filters.ShaderFilter;

class FrameBufferRenderer
{
	public var buffer:BitmapData;
	public var graphic:FlxGraphic;
	
	public var width:Int;
	public var height:Int;
	
	private var tempPoint:Point;
	private var tempRect:Rectangle;
	
	public var shaderFilters:Array<ShaderFilter> = [];
	
	public function new(width:Int, height:Int)
	{
		this.width = width;
		this.height = height;
		
		buffer = new BitmapData(width, height, true, 0x00000000);
		graphic = FlxGraphic.fromBitmapData(buffer);
		
		tempPoint = new Point();
		tempRect = new Rectangle(0, 0, width, height);
	}
	
	public function clear(?color:Int = 0x00000000):Void
	{
		buffer.fillRect(tempRect, color);
	}
	
	public function copyPixels(source:BitmapData, sourceRect:Rectangle, destPoint:Point):Void
	{
		buffer.copyPixels(source, sourceRect, destPoint, null, null, true);
	}
	
	public function draw(source:openfl.display.IBitmapDrawable, ?matrix:openfl.geom.Matrix):Void
	{
		buffer.draw(source, matrix, null, null, null, true);
	}
	
	public function applyShader(shader:openfl.display.Shader):Void
	{
		buffer.applyFilter(buffer, tempRect, tempPoint, new ShaderFilter(shader));
	}
	
	public function applyFilters():Void
	{
		if (shaderFilters.length == 0)
			return;
		
		for (filter in shaderFilters)
		{
			buffer.applyFilter(buffer, tempRect, tempPoint, filter);
		}
	}
	
	public function addShaderFilter(shader:openfl.display.Shader):Void
	{
		shaderFilters.push(new ShaderFilter(shader));
	}
	
	public function clearFilters():Void
	{
		shaderFilters = [];
	}
	
	public function getSprite():FlxSprite
	{
		var sprite:FlxSprite = new FlxSprite();
		sprite.loadGraphic(graphic);
		return sprite;
	}
	
	public function resize(newWidth:Int, newHeight:Int):Void
	{
		width = newWidth;
		height = newHeight;
		
		if (buffer != null)
		{
			buffer.dispose();
		}
		
		buffer = new BitmapData(width, height, true, 0x00000000);
		graphic = FlxGraphic.fromBitmapData(buffer);
		
		tempRect = new Rectangle(0, 0, width, height);
	}
	
	public function dispose():Void
	{
		if (buffer != null)
		{
			buffer.dispose();
			buffer = null;
		}
		
		graphic = null;
		shaderFilters = null;
	}
}
