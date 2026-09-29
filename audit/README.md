# Initial Roblox Studio Audit

This directory is reserved for factual audit material captured from the existing Roblox place.

## Current phase

The project is in **inventory / measurement mode**.

No gameplay refactor, rewrite, balancing pass, or architectural migration should be inferred from this branch.

## Studio audit

Run `tools/roblox/StudioAudit.lua` from Roblox Studio's **Command Bar** while the existing Valbrume place is open in Edit mode.

The script is intentionally read-only. It:

- traverses the main gameplay services;
- records names, classes, hierarchy, Attributes, CollectionService tags;
- records BasePart / Model transforms;
- inventories scripts, LocalScripts and ModuleScripts;
- attempts to include Script.Source when Studio security permits it;
- inventories RemoteEvents / RemoteFunctions;
- captures NPC/Humanoid, spawn, Tool, prompt, animation, sound and GUI metadata;
- identifies DataStore-related and remote-API patterns in readable source;
- prints a chunked JSONL export between explicit BEGIN / END markers.

It does **not** mutate the DataModel and does **not** call any DataStore.

## Next step

Return the complete Studio export before creating PROJECT.md, ARCHITECTURE.md, SYSTEMS.md, KNOWN_BUGS.md or BACKLOG.md. Those files must describe the measured game, not assumptions.
