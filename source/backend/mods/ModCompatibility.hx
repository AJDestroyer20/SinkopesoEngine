package backend.mods;

import haxe.io.Path;
import sys.FileSystem;

enum abstract ModFlavor(String)
{
	var Native = 'native';
	var Psych = 'psych';
	var AlePsych = 'ale-psych';
	var Codename = 'codename';
	var VSlice = 'v-slice';
}

typedef ModManifest =
{
	var id:String;
	var root:String;
	var flavor:ModFlavor;
	var chartsPath:String;
	var scriptsPath:String;
	var assetsPath:String;
	var wrappers:ModWrapperSet;
}

typedef ModWrapperSet =
{
	var pathResolver:IPathResolver;
	var scriptApi:IScriptApiWrapper;
}

class ModCompatibility
{
	public static function detect(modRoot:String):ModManifest
	{
		var id = Path.withoutDirectory(modRoot);
		var flavor = detectFlavor(modRoot);
		var wrappers = ModWrappers.create(flavor);

		return {
			id: id,
			root: modRoot,
			flavor: flavor,
			chartsPath: wrappers.pathResolver.chartsPath(),
			scriptsPath: wrappers.pathResolver.scriptsPath(),
			assetsPath: wrappers.pathResolver.assetsPath(),
			wrappers: wrappers
		};
	}

	private static function detectFlavor(modRoot:String):ModFlavor
	{
		if (FileSystem.exists(Path.join([modRoot, 'mods', 'stages'])))
			return ModFlavor.Codename;
		if (FileSystem.exists(Path.join([modRoot, 'example_mods'])))
			return ModFlavor.VSlice;
		if (FileSystem.exists(Path.join([modRoot, 'data', 'scripts'])))
			return ModFlavor.AlePsych;
		if (FileSystem.exists(Path.join([modRoot, 'data'])) && FileSystem.exists(Path.join([modRoot, 'images'])))
			return ModFlavor.Psych;
		return ModFlavor.Native;
	}
}
