# Valbrume — Systems Inventory

This file records what exists in the audited Studio snapshot. It is not a redesign proposal.

## Player progression

Status: implemented in server code.

Current model:

- MaxLevel: 10
- XP requirement: `80 + 40 * (level - 1)`
- Gold
- class choice
- home-zone choice
- inventory
- equipment
- story progression.

Configured classes:

| Class | Role intent | Base HP | Armor | Power |
|---|---|---:|---:|---:|
| Bastion | tank/guard | 210 | 8 | 10 |
| Éclaireur | ranged/control | 155 | 3 | 13 |
| Arcaniste | caster/AoE | 135 | 2 | 16 |
| Luminar | support/heal | 170 | 4 | 12 |

Each class currently has 4 skills.

## Combat

Status: implemented server-side, runtime playtest still required.

`Main` controls:

- skill resource costs;
- cooldowns;
- cast timing;
- target validation;
- range checks;
- player/enemy damage;
- armor mitigation;
- guard/haste/stun/taunt style effects;
- enemy threat;
- boss telegraphed area attacks;
- XP/gold/drop rewards.

The client sends ability intent; the server performs the authoritative validation and result.

## Enemies and spawning

The configuration contains 32 mob definitions across:

- legacy/base mobs;
- A2-specific mobs;
- H2-specific mobs;
- dungeon mobs;
- S3/N4/O5/V6 expansion mobs.

The edit-mode `Enemies` folder is empty because enemies are generated at runtime.

The V2.8 QA code expects the open world to contain:

- 15 A2 world enemies;
- 15 H2 world enemies;
- 9 enemies in each expansion region S3/N4/O5/V6;

for 66 open-world enemies before dungeon instances.

## Quests / story

### Home-region story

Status: implemented and stored inside `PlayerDataService.Profile.Story`.

`StoryConfigV23` contains:

- 8 A2 narrative quests;
- 8 H2 narrative quests.

Objective types include:

- Explore
- Kill
- Collect
- Interact.

`StoryQuestServiceV23` disables the older quest prompts and takes over the home-region narrative flow.

### Legacy quest arc

`Config` still contains 6 older quests and `Main` still contains the older quest engine.

The V2.3 story system explicitly disables the legacy quest state for initialized players and suppresses old prompts.

Treat this as retained compatibility/dead-path code until a later migration decision. Do not remove it during the audit milestone.

### Expansion story

Status: implemented for the current server session.

`ExpansionStoryServiceV26` contains 16 quests:

- 4 S3;
- 4 N4;
- 4 O5;
- 4 V6.

See `KNOWN_BUGS.md` for the persistence limitation discovered by the audit.

## Inventory and equipment

Status: implemented.

`Config` generates:

- 4 classes;
- 3 equipment tiers;
- Weapon + Armor slots;

for 24 configured equipment items.

Tier level requirements are currently 1, 4 and 7.

Equipping is validated server-side for:

- item existence;
- ownership;
- class;
- required level;
- out-of-combat state.

## Weapon visuals / tools

Status: implemented.

`ServerStorage.WeaponLibrary` contains 8 audited weapon asset roots, two per class.

`WeaponToolServiceV27` creates runtime Roblox Tools and validates native `RightGrip` behavior. It also removes the older primitive equipment visual when the V2.7 weapon tool is active.

`StarterPack` is empty because these weapons are created/equipped at runtime.

## Parties and dungeons

Status: implemented structurally; full multiplayer runtime test still required.

`DungeonPartyService` currently defines:

- maximum 5 players per party;
- 4 spatial dungeon slots per home zone;
- A2 and H2 dungeon entry points;
- staged dungeon waves;
- dungeon-specific mob markers;
- leader start flow;
- party leave handling;
- server-side spatial dungeon isolation.

The dungeon boss is `EchoLord`.

## World generation

Status: implemented as staged runtime generation.

Key responsibilities are split across:

- WorldBuilder
- ZoneExpansionService
- OpenWorldContinentsV28
- OpenWorldBiomeV28
- ExpansionWorldContentV26
- WorldPolishV23
- ZoneGroundingService
- SafeSpawnDirectorV26.

This is already modularized enough that the audit does not justify a rewrite.

## Open world

V2.8 adds:

- land routes between regions;
- biome-specific world content;
- water/lava/crystal features;
- ferry traversal between the two sides of the world;
- region detection through player attributes;
- per-region atmosphere changes on the client.

## UI

Status: programmatically generated.

Primary client code:

- `ValbrumeClient`: gameplay HUD, target/ability UI, story presentation, input;
- `ValbrumePartyClient`: party UI;
- `ValbrumeInterfaceV27`: character/inventory/journal modal interface;
- `OpenWorldAtmosphereClientV28`: regional visual atmosphere.

Mobile support is visible in code through:

- touch input;
- `Activated` button handlers;
- viewport-based responsive layouts;
- mobile-specific layout sizing.

A real-device playtest has not yet been performed in this audit.

## DataStores

Status: code exists, disabled in audited snapshot.

`PlayerDataService` uses:

- DataStoreService;
- UpdateAsync;
- schema validation;
- lock token + lock expiry;
- retry loops;
- explicit close/release;
- separate Studio/live store names.

Current `EnableSaving` value: `false`.

## QA / guard systems

The project already contains several runtime validation scripts:

- ValbrumeQARuntime
- ValbrumeQAV26
- ValbrumeQAV27
- ValbrumeQAV28
- CharacterStabilityService
- SafeSpawnDirectorV26.

These should be preserved during early source migration. They encode useful runtime assumptions.
