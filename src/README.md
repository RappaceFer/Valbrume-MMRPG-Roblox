# Valbrume source baseline

This directory is an exact source capture of the Roblox Studio snapshot audited on 2026-09-29.

No gameplay code was refactored, reformatted, fixed or otherwise changed during this capture.

## Layout

Paths mirror the Roblox DataModel hierarchy:

- `src/ServerScriptService/...`
- `src/ReplicatedStorage/...`
- `src/StarterPlayer/...`

File suffixes preserve source-container type:

- `.lua` = ModuleScript
- `.server.lua` = Script
- `.client.lua` = LocalScript

No Studio/Git synchronization system (such as a Rojo project file) is enabled by this baseline commit. That is a later workflow decision.

See `SOURCE_MANIFEST.md` for the exact Roblox-to-Git mapping and Git blob identifiers.
