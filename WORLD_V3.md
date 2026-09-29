# VALBRUME — WORLD V3

## Intent

World V3 is a geographic and artistic rebuild of Valbrume that preserves the existing gameplay contracts while replacing the prototype-like world stitching.

The six existing regions remain the canonical gameplay regions:

- A2 — Val d'Astréa
- H2 — Terres cendrées de Khar
- S3 — Sylvebrume
- N4 — Caps de Nacre
- O5 — Forges d'Ormefer
- V6 — Profondeurs de l'Écho

The rebuild may change terrain, silhouettes, roads, coastlines, props, lighting and landmarks. It must not silently change combat balance, quest identifiers, mob identifiers, profile schema, remote contracts or dungeon rules.

## World identity

Valbrume should read as one authored world, not six arenas placed next to each other.

The global composition is built around two opposing home continents separated by the Mer d'Obsidienne:

- Elyndra / western landmass: A2, S3, N4
- Varkhûn / eastern landmass: H2, O5, V6

The sea is a deliberate visual and narrative separator. The ferry remains meaningful rather than becoming a teleport disguised as scenery.

## Region silhouettes

### A2 — Val d'Astréa

Readable green valley, inhabited and welcoming, with layered ridgelines rather than a flat square.

Visual anchors:
- inhabited camp / village;
- river cut;
- wooden bridge;
- old sanctuary;
- distant high ground.

Gameplay:
- safest readability;
- generous traversal widths;
- establishes the visual language of roads and quest POIs.

### H2 — Terres cendrées de Khar

Dry ochre land, broad rock shelves, canyons and basalt.

Visual anchors:
- expedition outpost;
- canyon bridge;
- Titan arena;
- smoke-colored ridgelines.

Gameplay:
- more vertical than A2 but never dependent on accidental terrain cliffs.

### S3 — Sylvebrume

Dense green basin, fog, giant roots and ancient stone.

Visual anchors:
- tree silhouettes;
- Veilleur circle;
- wet lowlands;
- root passage to A2.

Gameplay:
- enclosed sightlines and readable forest lanes.

### N4 — Caps de Nacre

Wind-cut coast, slate shelves, bright water and exposed bridges.

Visual anchors:
- sea cliffs;
- waterfall;
- wind bridge;
- beacon silhouettes.

Gameplay:
- dramatic elevation while maintaining safe playable paths.

### O5 — Forges d'Ormefer

Industrial ruin embedded in dark rock.

Visual anchors:
- Grand Fourneau;
- forge court;
- basalt / iron silhouettes;
- controlled lava hazards.

Gameplay:
- hazards are authored spaces, never accidental terrain traps.

### V6 — Profondeurs de l'Écho

Alien crystalline fracture zone.

Visual anchors:
- large crystal families;
- resonance well;
- fractured stone shelves;
- purple/cyan light language.

Gameplay:
- visually strange, mechanically readable.

## Traversal rules

1. A main route must never contain a terrain void.
2. Main route grade must be deliberately bounded.
3. Route width must support groups of five players fighting while travelling.
4. Every route has shoulders so stepping one character-width off the road is not fatal.
5. Transition seams must be wider than the visible road.
6. Docks must physically overlap their shoreline terrain.
7. A cliff may be visually extreme, but the intended player route must remain readable.
8. Lava and water hazards must be intentional and detectable by gameplay code.
9. No route may rely on a decorative non-collidable Part to hide missing Terrain.
10. Every world pass is validated by an automated server-side continuity scan.

## Compatibility contracts

The V3 pass currently keeps these runtime names for compatibility:

- ValbrumeWorld
- OpenWorldV28
- OpenWorldV28.Roads
- OpenWorldV28.POI
- OpenWorldV28.SeaTravel
- OpenWorldV28.Hazards
- ExpansionV25
- existing home and expansion spawn names

OpenWorldV28 receives the attribute WorldRevision = V3.

## Development rule

The baseline branch is frozen.

All V3 work happens on world/valbrume-rebuild-v3.

Nothing is merged to main until:

- generation reaches Ready;
- V2.8 structural QA passes or is deliberately superseded;
- terrain continuity scan passes intended traversal corridors;
- A2/H2 story flow still works;
- expansion story objects remain addressable;
- mob population counts remain correct;
- dungeon entry/return remains correct;
- PC and mobile traversal are manually tested.

## First V3 pass

The first implementation replaces the old sparse route stitching in OpenWorldContinentsV28.server.lua with:

- continuous graded terrain ribbons;
- broad rock shoulders;
- carved route headroom;
- continuous visual road strips;
- overlapping shores;
- explicit dock causeways;
- retained Mer d'Obsidienne;
- retained compatibility hierarchy.

This is intentionally the geography foundation. Art-set replacement comes after topology is proven stable.
