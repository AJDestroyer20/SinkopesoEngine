# SinkopesoEngine
Kade Engine fork that aims to look more modern and better, and is also geared towards softcoding.


# Current Roadmap
### Beta 1: Core Infrastructure
- GameContext (singleton hub)
- AudioManager, ModManager, EventBus
- ScriptableState / ScriptableSubstate
- ScriptRegistry (class resolution)
- HaxeScriptBackend upgraded to Iris (full Psych API)
- LuaScriptBackend with Psych variables
- data.json drives startup (window size, initial state, mod settings)

---

### Beta 2: Gameplay Systems Integration
- InternalChart + adapters (Kade, Psych, VSlice)
- EventGraph (node-based event system)
- AIDriver (opponent AI)
- CameraController (beat-driven camera)
- LogicSystem / RenderSystem (separation of logic and rendering)
- LayeredTrack (multi-stem dynamic audio)
- GameStateSnapshot (serializable state)
- FrameBufferRenderer & Pseudo2.5D (advanced gfx)

---

### Beta 3: Full Scriptability & Editor
- Script templates for all states (PlayState, menus, substates)
- HScript: custom class definition and registration
- Lua: full FunkinLua API (setProperty, tweenCamera, soundFade, 40+ functions)
- Plugin system (PluginAPI, PluginLoader, PluginSandbox)
- Visual Editor (debug only) with Inspector, HotReload, DragDrop
- State hooks (onOptionSelected, onSongSelected, onTitleText, onGameOver, onPause, etc.)

---

**After that the engine will be ready for mod development**
