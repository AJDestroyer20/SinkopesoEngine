package systems.mods;

import systems.mods.layout.ModLayout;
import systems.mods.layout.ModLayoutResolver;
import systems.mods.compat.EngineModFormat;
import systems.mods.compat.ModCompatScanner;
import systems.mods.porting.ModPorter;

class ModManager
{
	public var enabledMods:Array<String> = [];
	public var modMetadata:Map<String, Dynamic> = [];
	public var modFormats:Map<String, EngineModFormat> = [];
	public var modLayouts:Map<String, ModLayout> = [];
	public var modsRoot:String = "mods";

	public function new() {}

	public function scanMods(root:String = "mods"):Void
	{
		modsRoot = root;
		modMetadata = [];
		modFormats = [];
		modLayouts = [];
		if (!sys.FileSystem.exists(root)) return;

		for (entry in sys.FileSystem.readDirectory(root))
		{
			var modFolder = haxe.io.Path.join([root, entry]);
			if (!sys.FileSystem.isDirectory(modFolder)) continue;

			modLayouts.set(entry, ModLayoutResolver.psychLike(root, entry));
			modFormats.set(entry, ModCompatScanner.detectFormat(modFolder));

			var metaCandidates = [
				haxe.io.Path.join([modFolder, "mod.json"]),
				haxe.io.Path.join([modFolder, "pack.json"]),
				haxe.io.Path.join([modFolder, "_polymod_meta.json"])
			];
			for (candidate in metaCandidates)
			{
				if (sys.FileSystem.exists(candidate))
				{
					modMetadata.set(entry, haxe.Json.parse(sys.io.File.getContent(candidate)));
					break;
				}
			}
		}
	}

	public function enableMod(id:String):Void if (!enabledMods.contains(id)) enabledMods.push(id);
	public function disableMod(id:String):Void enabledMods.remove(id);


	public function resolveAssetPath(relativePath:String):String
	{
		for (i in 0...enabledMods.length)
		{
			var id = enabledMods[enabledMods.length - 1 - i];
			var candidate = haxe.io.Path.join([modsRoot, id, relativePath]);
			if (sys.FileSystem.exists(candidate)) return candidate;
		}
		return haxe.io.Path.join(["assets", relativePath]);
	}

	public function exportModTo(id:String, targetFormat:EngineModFormat, outputRoot:String = "exports"):String
	{
		var sourceFolder = haxe.io.Path.join([modsRoot, id]);
		var outFolder = haxe.io.Path.join([outputRoot, targetFormat, id]);
		ModPorter.exportMod(sourceFolder, outFolder, targetFormat);
		return outFolder;
	}
}
