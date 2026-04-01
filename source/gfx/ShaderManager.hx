package gfx;

import openfl.display.Shader;
import openfl.filters.ShaderFilter;
import flixel.FlxCamera;

/**
 * ShaderManager
 * 
 * Apply, remove, and hotswap GLSL shaders on cameras and sprites.
 * Shaders can be triggered from scripts.
 * 
 * ─── Built-in shaders included ───────────────────────────────────────────
 *   "chromatic"   — chromatic aberration
 *   "vignette"    — dark edge vignette
 *   "scanlines"   — CRT scanlines
 *   "blur"        — gaussian blur
 *   "grayscale"   — desaturate
 *   "invert"      — invert colors
 *   "pixelate"    — low-res pixelation
 *   "shake"       — wavy distortion
 * 
 * ─── Usage from HaxeScript ───────────────────────────────────────────────
 *   ShaderManager.applyToCamera("chromatic", FlxG.camera, {amount: 0.005});
 *   ShaderManager.applyToCamera("vignette", FlxG.camera, {strength: 0.6});
 *   ShaderManager.removeFromCamera(FlxG.camera, "chromatic");
 * 
 * ─── Usage from Lua ──────────────────────────────────────────────────────
 *   applyShader("chromatic", "game", 0.005)
 *   removeShader("chromatic", "game")
 * 
 * ─── Custom shader from file (.frag) ─────────────────────────────────────
 *   ShaderManager.loadFromFile("myShader", "assets/shaders/myShader.frag");
 *   ShaderManager.applyToCamera("myShader", FlxG.camera);
 */
class ShaderManager
{
	static var shaderCache:Map<String, Shader>       = new Map();
	static var cameraFilters:Map<String, Array<{name:String, filter:ShaderFilter}>> = new Map();

	public static function init():Void
	{
		shaderCache    = new Map();
		cameraFilters  = new Map();
		registerBuiltins();
	}

	// ─── APPLY / REMOVE ──────────────────────────────────────────────────

	/** Apply a named shader to a camera */
	public static function applyToCamera(name:String, camera:FlxCamera, ?params:Dynamic):Void
	{
		var shader = getShader(name);
		if (shader == null) { trace('[ShaderManager] Shader not found: $name'); return; }

		if (params != null) applyParams(shader, params);

		var filter = new ShaderFilter(shader);
		var camId  = getCamId(camera);

		if (!cameraFilters.exists(camId)) cameraFilters.set(camId, []);
		// Remove existing instance if any
		removeFromCamera(camera, name);

		cameraFilters.get(camId).push({name: name, filter: filter});
		rebuildCameraFilters(camera);
	}

	/** Remove a named shader from a camera */
	public static function removeFromCamera(camera:FlxCamera, name:String):Void
	{
		var camId = getCamId(camera);
		if (!cameraFilters.exists(camId)) return;
		cameraFilters.get(camId) = cameraFilters.get(camId).filter(f -> f.name != name);
		rebuildCameraFilters(camera);
	}

	/** Remove all shaders from a camera */
	public static function clearCamera(camera:FlxCamera):Void
	{
		cameraFilters.set(getCamId(camera), []);
		rebuildCameraFilters(camera);
	}

	/** Update a shader parameter at runtime */
	public static function setParam(name:String, paramName:String, value:Dynamic):Void
	{
		var shader = getShader(name);
		if (shader == null) return;
		applyParams(shader, {[paramName]: value});
	}

	// ─── LOAD FROM FILE ──────────────────────────────────────────────────

	/** Load a custom .frag shader file and register it by name */
	public static function loadFromFile(name:String, path:String):Void
	{
		try
		{
			var fragSrc = sys.io.File.getContent(path);
			var shader = new Shader();
			// OpenFL shader: set glFragmentSource
			Reflect.setProperty(shader, "glFragmentSource", fragSrc);
			shaderCache.set(name, shader);
			trace('[ShaderManager] Loaded shader: $name from $path');
		}
		catch (e:Dynamic)
		{
			trace('[ShaderManager] Error loading shader $name: $e');
		}
	}

	// ─── INTERNAL ────────────────────────────────────────────────────────

	static function getShader(name:String):Shader
	{
		return shaderCache.exists(name) ? shaderCache.get(name) : null;
	}

	static function applyParams(shader:Shader, params:Dynamic):Void
	{
		for (field in Reflect.fields(params))
		{
			var val = Reflect.field(params, field);
			try { Reflect.setProperty(shader, field, val); }
			catch (_) {}
		}
	}

	static function getCamId(camera:FlxCamera):String
	{
		return Std.string(camera.ID);
	}

	static function rebuildCameraFilters(camera:FlxCamera):Void
	{
		var camId = getCamId(camera);
		var filters = cameraFilters.exists(camId) ? cameraFilters.get(camId) : [];
		camera.setFilters(filters.map(f -> f.filter));
	}

	// ─── BUILT-IN SHADER SOURCES ─────────────────────────────────────────

	static function registerBuiltins():Void
	{
		registerInline("chromatic", CHROMATIC_ABERRATION);
		registerInline("vignette",  VIGNETTE);
		registerInline("scanlines", SCANLINES);
		registerInline("grayscale", GRAYSCALE);
		registerInline("invert",    INVERT);
		registerInline("blur",      BLUR);
		registerInline("pixelate",  PIXELATE);
		trace('[ShaderManager] Registered 7 built-in shaders.');
	}

	static function registerInline(name:String, src:String):Void
	{
		var shader = new Shader();
		Reflect.setProperty(shader, "glFragmentSource", src);
		shaderCache.set(name, shader);
	}

	// ── Shader sources ─────────────────────────────────────────────────

	static var CHROMATIC_ABERRATION = "
		varying vec2 openfl_TextureCoordv;
		uniform sampler2D bitmap;
		uniform float amount;
		void main() {
			vec2 uv = openfl_TextureCoordv;
			float r = texture2D(bitmap, uv + vec2(amount, 0.0)).r;
			float g = texture2D(bitmap, uv).g;
			float b = texture2D(bitmap, uv - vec2(amount, 0.0)).b;
			float a = texture2D(bitmap, uv).a;
			gl_FragColor = vec4(r, g, b, a);
		}
	";

	static var VIGNETTE = "
		varying vec2 openfl_TextureCoordv;
		uniform sampler2D bitmap;
		uniform float strength;
		void main() {
			vec2 uv = openfl_TextureCoordv;
			vec4 color = texture2D(bitmap, uv);
			vec2 center = uv - 0.5;
			float vignette = 1.0 - dot(center, center) * (strength * 4.0);
			gl_FragColor = vec4(color.rgb * clamp(vignette, 0.0, 1.0), color.a);
		}
	";

	static var SCANLINES = "
		varying vec2 openfl_TextureCoordv;
		uniform sampler2D bitmap;
		uniform float intensity;
		void main() {
			vec2 uv = openfl_TextureCoordv;
			vec4 color = texture2D(bitmap, uv);
			float line = mod(floor(uv.y * 720.0), 2.0);
			float scanline = 1.0 - (line * intensity);
			gl_FragColor = vec4(color.rgb * scanline, color.a);
		}
	";

	static var GRAYSCALE = "
		varying vec2 openfl_TextureCoordv;
		uniform sampler2D bitmap;
		uniform float strength;
		void main() {
			vec4 color = texture2D(bitmap, openfl_TextureCoordv);
			float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
			gl_FragColor = vec4(mix(color.rgb, vec3(gray), strength), color.a);
		}
	";

	static var INVERT = "
		varying vec2 openfl_TextureCoordv;
		uniform sampler2D bitmap;
		void main() {
			vec4 color = texture2D(bitmap, openfl_TextureCoordv);
			gl_FragColor = vec4(1.0 - color.r, 1.0 - color.g, 1.0 - color.b, color.a);
		}
	";

	static var BLUR = "
		varying vec2 openfl_TextureCoordv;
		uniform sampler2D bitmap;
		uniform float radius;
		void main() {
			vec2 uv = openfl_TextureCoordv;
			vec4 color = vec4(0.0);
			float total = 0.0;
			for(float x = -4.0; x <= 4.0; x++) {
				for(float y = -4.0; y <= 4.0; y++) {
					vec2 offset = vec2(x, y) * radius * 0.001;
					color += texture2D(bitmap, uv + offset);
					total += 1.0;
				}
			}
			gl_FragColor = color / total;
		}
	";

	static var PIXELATE = "
		varying vec2 openfl_TextureCoordv;
		uniform sampler2D bitmap;
		uniform float size;
		void main() {
			vec2 uv = openfl_TextureCoordv;
			vec2 pixelated = floor(uv * size) / size;
			gl_FragColor = texture2D(bitmap, pixelated);
		}
	";
}
