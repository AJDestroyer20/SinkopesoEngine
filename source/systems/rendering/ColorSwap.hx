package systems.rendering;

import openfl.display.Shader;
import flixel.system.FlxAssets.FlxShader;

class ColorSwap
{
	public var hue:Float = 0;
	public var saturation:Float = 0;
	public var brightness:Float = 0;
	public var enabled:Bool = true;
	
	public var shader:ColorSwapShader;
	
	public function new()
	{
		shader = new ColorSwapShader();
	}
	
	public function update(elapsed:Float):Void
	{
		shader.uHue.value = [hue];
		shader.uSaturation.value = [saturation];
		shader.uBrightness.value = [brightness];
		shader.uEnabled.value = [enabled];
	}
}

class ColorSwapShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		
		uniform float uHue;
		uniform float uSaturation;
		uniform float uBrightness;
		uniform bool uEnabled;
		
		vec3 rgb2hsv(vec3 c)
		{
			vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
			vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
			vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
			
			float d = q.x - min(q.w, q.y);
			float e = 1.0e-10;
			return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
		}
		
		vec3 hsv2rgb(vec3 c)
		{
			vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
			vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
			return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
		}
		
		void main()
		{
			vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
			
			if (!uEnabled)
			{
				gl_FragColor = color;
				return;
			}
			
			vec3 hsv = rgb2hsv(color.rgb);
			
			hsv.x += uHue / 360.0;
			hsv.y *= 1.0 + uSaturation / 100.0;
			hsv.z *= 1.0 + uBrightness / 100.0;
			
			hsv.x = mod(hsv.x, 1.0);
			hsv.y = clamp(hsv.y, 0.0, 1.0);
			hsv.z = clamp(hsv.z, 0.0, 1.0);
			
			color.rgb = hsv2rgb(hsv);
			
			gl_FragColor = color;
		}
	')
	
	public function new()
	{
		super();
	}
}
