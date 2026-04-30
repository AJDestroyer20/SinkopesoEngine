# Architecture

Core runtime is managed by `GameContext`:
- Config (`ConfigService` / `GameConfig`)
- Events (`EventBus`)
- Scripting (`ScriptManager`)
- Audio (`AudioManager`)
- Mods (`ModManager`)
- Plugins (`PluginLoader`)
- Scheduler (`SystemScheduler`)

This design keeps systems composable and easier to debug.
