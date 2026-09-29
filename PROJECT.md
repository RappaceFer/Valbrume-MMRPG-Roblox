# Valbrume — Project Baseline

## Status

Valbrume is an existing Roblox MMORPG project. The current task is to preserve and understand the existing game before making architectural or gameplay changes.

This document is based on the non-destructive Roblox Studio audit captured on 2026-09-29.

## Source-of-truth status

GitHub is the target source of truth, but it is **not yet the complete source of truth for the game code**.

At this audit milestone:

- `main` contains only the initial repository README.
- the audit branch contains audit tooling and factual documentation;
- the actual Luau runtime source still lives in the Roblox Studio place;
- historical source snapshots also exist inside `ServerStorage` as backup `StringValue` objects.

No gameplay code has been rewritten or migrated in this milestone.

## Audited Studio snapshot

The audit completed successfully with:

- 580 descendant instances inspected;
- 345 BaseParts inspected;
- 28 Lua source containers;
- 28/28 script sources readable;
- 7 RemoteEvents;
- 0 RemoteFunctions;
- 0 audit errors.

The snapshot was opened as a local Studio recovery file. The audit reported `PlaceId = 0` and `GameId = 0`, so this snapshot must not be treated as proof of the currently published Roblox experience state.

## Current project version markers

`ServerScriptService.ValbrumeServer` exposes:

- `Version = 2.8`
- `UIVersion = 2.7`
- `StoryVersion = 2.3`
- `V21Revision = fixed-1`
- `EnableSaving = false`

## Product constraints

These rules are project constraints, not refactor targets:

- preserve working systems unless a blocking defect is demonstrated;
- keep economy, combat, progression and persistence server-authoritative;
- maintain mobile and PC usability;
- treat completed features as completed;
- record non-blocking improvements in `BACKLOG.md`;
- verify repository state before material changes;
- verify written GitHub files after every important GitHub mutation;
- prefer scoped systems over monolithic rewrites.

## Current verified gameplay scope

The audited code contains:

- 4 player classes: Bastion, Éclaireur, Arcaniste, Luminar;
- 4 abilities per class;
- player levels and XP with a current cap of 10;
- gold, inventory and equipment;
- generated weapon/armor tiers;
- 32 configured mob definitions including dungeon and expansion mobs;
- two home regions: A2 and H2;
- four expansion regions: S3, N4, O5 and V6;
- home-region narrative quest arcs;
- expansion narrative quest arcs;
- parties and instanced spatial dungeons;
- runtime-generated open world content;
- server-side enemy AI, combat rewards and progression;
- responsive client UI and touch support;
- a server-side persistence service, currently disabled.

## Audit milestone definition

This milestone changes documentation only. It does not change gameplay behavior.

The next implementation milestone should not begin until the audit findings and unknowns are accepted.
