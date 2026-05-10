# Sinkopeso Engine

Sinkopeso Engine is a Friday Night Funkin' engine focused on long-term maintainability, deep modding extensibility, and cross-engine compatibility.

## Core goals

- Build a modular scripting stack with Lua + HScript-Iris support.
- Let modders extend states, substates, objects, menus, classes, and shaders without recompiling.
- Load and adapt mods from multiple FNF ecosystems with minimal manual migration.

## Requirements

- Haxe 4.3+
- Haxelib
- Lime + OpenFL
- HaxeFlixel
- Libraries listed in `Project.xml`

## Installation

1. Clone this repository.
2. Install dependencies.
3. Run setup for your platform:
   - Linux/macOS: `setup/setup.sh`
   - Windows: `setup/setup.bat`
   - Windows (MSVC tools): `setup/windows-msvc.bat`

## Build

```bash
lime test cpp
```

```bash
lime test html5
```

## Scripting system

### Supported script extensions

- Lua: `.lua`
- HScript-Iris: `.hx`, `.hscript`, `.hxc`

### Runtime model

- `ScriptManager` routes scripts by extension.
- Each runtime implements a common interface (`IScriptRuntime`).
- Engine callbacks can be dispatched to all active scripts through one API.

### Cross-engine script API wrappers

`backend.mods.ModWrappers` includes script API adapters per engine flavor.

Current wrappers provide the base normalization entry points:

- callback normalization (`normalizeCallback`)
- property normalization (`normalizeProperty`)

This is where per-engine behavior translation is centralized.

## Mod compatibility system

The engine scans `mods/` and creates manifests for each mod with:

- detected flavor (`native`, `psych`, `ale-psych`, `codename`, `v-slice`)
- normalized chart/script/asset path mappings
- wrapper set for path resolution and script API adaptation

## Project structure

- `source/backend`: core systems, preferences, mod loading, wrappers.
- `source/systems`: scripting, rendering, audio/video, utilities.
- `source/states`: top-level game states.
- `source/substates`: child state flows.
- `source/gameplay`: notes, characters, stages, events.

## Modder quickstart

1. Create a folder under `mods/`.
2. Keep your original engine structure when possible.
3. Add charts/assets/scripts.
4. Use Lua or HScript (`.hxc` supported) for custom logic.
5. Let wrappers handle compatibility translation first, then patch only edge cases.

## Contributing

1. Branch from `main`.
2. Keep commits focused.
3. Document behavior changes.
4. Add checks/tests when possible.

## Credits

- Friday Night Funkin' community
- Psych Engine, ALE Psych, Codename Engine, and Funkin' teams
- Sinkopeso Engine contributors
