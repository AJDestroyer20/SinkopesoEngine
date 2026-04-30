# Troubleshooting

## Quick checks
- Run in-game diagnostics with `F3` in PlayState.
- Ensure `assets/data/data.json` has valid JSON.
- Verify mod folders include expected metadata (`mod.json`, `pack.json`, or `_polymod_meta.json`).

## Error handling approach
- Services initialize with fallbacks where possible.
- Missing state resolution falls back to `TitleState`.
- Mod scanning skips invalid folders instead of crashing startup.
