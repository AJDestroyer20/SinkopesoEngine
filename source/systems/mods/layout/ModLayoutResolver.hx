package systems.mods.layout;

class ModLayoutResolver
{
	public static function psychLike(modRoot:String, modId:String):ModLayout
	{
		// Psych style: mods/<modId>/{data,songs,scripts,images,stages,characters,weeks}
		return {
			id: modId,
			root: modRoot,
			assets: haxe.io.Path.join([modRoot, modId]),
			data: haxe.io.Path.join([modRoot, modId, "data"]),
			songs: haxe.io.Path.join([modRoot, modId, "songs"]),
			scripts: haxe.io.Path.join([modRoot, modId, "scripts"]),
			images: haxe.io.Path.join([modRoot, modId, "images"]),
			weeks: haxe.io.Path.join([modRoot, modId, "weeks"]),
			stages: haxe.io.Path.join([modRoot, modId, "stages"]),
			characters: haxe.io.Path.join([modRoot, modId, "characters"]),
		};
	}

	public static function aleLikeAssets(baseAssets:String = "assets"):Array<String>
	{
		// Keep compatibility aliases inspired by ALE/Psych softcoded organization.
		return [
			haxe.io.Path.join([baseAssets, "data"]),
			haxe.io.Path.join([baseAssets, "images"]),
			haxe.io.Path.join([baseAssets, "songs"]),
			haxe.io.Path.join([baseAssets, "shared"]),
			haxe.io.Path.join([baseAssets, "stages"]),
			haxe.io.Path.join([baseAssets, "characters"]),
			haxe.io.Path.join([baseAssets, "weeks"])
		];
	}
}
