# Valbrume — Architecture

## High-level model

Valbrume is currently a runtime-generated Roblox experience. A large part of the playable world is reconstructed by server scripts when the server starts rather than being treated as authored static `Workspace` content.

The saved editor hierarchy is therefore useful evidence, but it is not identical to the runtime hierarchy.

## Roblox service layout

### ServerScriptService

Runtime server code is grouped under:

`ServerScriptService.ValbrumeServer`

The audit found 22 server-side Script/ModuleScript source containers there.

Important modules/services include:

- `WorldBuilder`
- `WorldGeneration`
- `PlayerDataService`
- `Main`
- `DungeonPartyService`
- `StoryQuestServiceV23`
- `ExpansionStoryServiceV26`
- `ZoneExpansionService`
- `OpenWorldContinentsV28`
- `OpenWorldBiomeV28`
- `SafeSpawnDirectorV26`
- `WeaponToolServiceV27`
- QA and world-stability services.

### ReplicatedStorage

`ReplicatedStorage.Valbrume` contains:

- `Config` ModuleScript;
- `StoryConfigV23` ModuleScript;
- `Request` RemoteEvent;
- `State` RemoteEvent;
- `Effects` RemoteEvent;
- `PartyRemote` RemoteEvent;
- `StoryRemoteV23` RemoteEvent;
- `ExpansionStoryRemoteV26` RemoteEvent;
- `JournalSyncRemoteV27` RemoteEvent.

No RemoteFunction was found.

### ServerStorage

ServerStorage contains two distinct categories:

1. runtime assets:
   - `WeaponLibrary`
   - weapon models for Bastion, Éclaireur, Arcaniste and Luminar;

2. historical Studio backups:
   - V1/V2/V2.2/V2.3/V2.4/V2.5/V2.6/V2.7/V2.8 source snapshots stored primarily as folders and StringValues.

These backups do not execute, but they currently duplicate historical source outside Git.

### StarterPlayer

Client runtime code is in `StarterPlayer.StarterPlayerScripts`:

- `ValbrumeClient`
- `ValbrumePartyClient`
- `ValbrumeInterfaceV27`
- `OpenWorldAtmosphereClientV28`

`StarterGui` is empty in the audited editor snapshot because the UI is built dynamically by LocalScripts.

## Runtime world generation pipeline

`WorldGeneration` defines an ordered stage coordinator.

Observed stage order:

1. `Core` — `Main` after `WorldBuilder.Build()`
2. `Expansion` — `ZoneExpansionService`
3. `Continents` — `OpenWorldContinentsV28`
4. `Biome` — `OpenWorldBiomeV28`
5. `Content` — `ExpansionWorldContentV26`
6. `Polish` — `WorldPolishV23`
7. `Grounding` — `ZoneGroundingService`
8. `SafeSpawns` — `SafeSpawnDirectorV26`
9. `Population` — `Main`
10. `Story` — `StoryQuestServiceV23`
11. `ExpansionStory` — `ExpansionStoryServiceV26`
12. `Dungeon` — `DungeonPartyService`
13. `Ready` — `DungeonPartyService`

`A2MicroArtPassC1` waits for `Ready` and then performs a small terrain-material art pass.

## Important runtime behavior

`WorldBuilder` contains a later `W.Build()` definition that replaces the earlier definition. The active definition deletes any existing `Workspace.ValbrumeWorld` and rebuilds the runtime world.

Consequences:

- static objects manually placed under `Workspace.ValbrumeWorld` are not automatically authoritative at runtime;
- generated terrain, NPCs, collectibles, spawns and world folders are primarily code-driven;
- authored staging/art-pass folders outside `ValbrumeWorld` can survive and be consumed by later systems.

This is a workflow constraint to preserve until an explicit migration is approved.

## Authority boundaries

### Server-authoritative

The audited code keeps the following decisions on the server:

- class and zone selection;
- equipped-item validation;
- ability validation;
- cooldown/resource validation;
- target range validation;
- damage calculation;
- enemy AI and threat;
- XP/gold rewards;
- item grants;
- home-story progression;
- dungeon membership/state;
- DataStore writes.

`Main.Request` also uses a token-bucket request limiter.

### Client-owned presentation/input

Clients handle:

- keyboard/touch input;
- target selection presentation;
- HUD and journal rendering;
- visual effects;
- local atmosphere/color correction;
- responsive UI layout.

## Persistence architecture

`PlayerDataService` uses DataStoreService with `UpdateAsync` and a server-session lock token.

Store names are separated between Studio and live environments.

The profile schema currently includes:

- Zone
- Class
- Level
- XP
- Gold
- Inventory
- Equipment
- legacy quest fields
- home-region Story state.

Saving is currently gated by the `EnableSaving` attribute and was disabled in the audited snapshot.

## World topology

Home zones:

- A2 — Val d'Astréa
- H2 — Terres cendrées de Khar

Expansion zones:

- S3 — Sylvebrume
- N4 — Caps de Nacre
- O5 — Forges d'Ormefer
- V6 — Profondeurs de l'Écho

V2.8 removes the older expansion travel folder at runtime and builds open-world routes, biome content, sea travel/ferry content and region detection.
