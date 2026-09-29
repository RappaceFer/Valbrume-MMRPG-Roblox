# Valbrume — Backlog

This backlog captures work discovered by the audit. It does not authorize implementation.

## Audit / source-of-truth blockers

- [ ] Confirm that the audited AutoRecovery snapshot is the Studio version that should become the migration baseline.
- [ ] Capture the authoritative current Luau source from Studio into Git without behavior changes.
- [ ] Define a Studio ↔ Git synchronization workflow before editing gameplay code.
- [ ] Preserve the current runtime paths and Instance names during source capture.
- [ ] Preserve runtime QA scripts during migration.
- [ ] Decide how non-code Roblox assets should be backed up/versioned.

## Confirmed defect

- [ ] Persist S3/N4/O5/V6 expansion story state instead of keeping it only in `ExpansionStoryServiceV26.sessions`.

## Validation before feature work

- [ ] Run Play Solo and capture the complete server/client Output through `GenerationReady`.
- [ ] Run a two-client Start Server test for party and dungeon behavior.
- [ ] Validate first-login zone/class selection.
- [ ] Validate all four classes' abilities.
- [ ] Validate A2 and H2 story arcs.
- [ ] Validate one full expansion story arc.
- [ ] Validate inventory/equip/weapon Tool behavior after respawn.
- [ ] Validate ferry and open-world region detection.
- [ ] Validate mobile touch controls and responsive UI on at least one phone-size viewport.

## Persistence validation

- [ ] Publish/use a dedicated test place before enabling saving.
- [ ] Verify DataStore schema-1 load/save/release behavior.
- [ ] Verify lock-loss behavior and reconnect flow.
- [ ] Verify server shutdown save behavior.
- [ ] Decide migration policy for future profile schema versions.

## Progression design questions

- [ ] Confirm whether level 10 is intentionally the permanent/current cap.
- [ ] Reconcile expansion mob levels 11–18 with the intended player cap.
- [ ] Confirm whether equipment tiers 1/4/7 are intended to cover all expansion content.

## Repository hygiene — later, not during baseline capture

- [ ] After Git source capture is proven, decide whether historical `ServerStorage` StringValue source backups can be retired.
- [ ] Document authored assets versus generated runtime content.
- [ ] Add a repeatable audit/export procedure for future milestones.
- [ ] Consider automated static checks once the Studio source exists in Git.

## Performance — non-blocking until measured

- [ ] Profile server cost of 66 open-world enemies plus dungeon mobs.
- [ ] Profile repeated server loops used for grounding, region detection, hazards and QA.
- [ ] Profile terrain generation startup time.
- [ ] Profile UI and effects on low-end mobile hardware.

No optimization/refactor should be started without measurements.
