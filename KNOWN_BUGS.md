# Valbrume — Known Bugs and Verified Limitations

Only issues supported by the audit are recorded here. Suspected issues that require playtesting are kept as unknowns, not declared bugs.

## Confirmed — expansion story progression is not persisted

`ExpansionStoryServiceV26` stores progress in its own in-memory `sessions[player][zoneId]` table.

That state contains:

- QuestIndex
- Active
- Progress
- Completed.

It is removed on `PlayerRemoving` and is not represented in `PlayerDataService`'s persisted profile schema.

Impact:

- S3/N4/O5/V6 story progression resets on a new server session;
- enabling the existing DataStore system will not fix this by itself.

No fix has been applied during the audit.

## Confirmed — persistence is disabled in the audited build

`ServerScriptService.ValbrumeServer.EnableSaving = false`.

`Main` passes this attribute into `PlayerDataService.Configure()`.

Impact in the audited build:

- player progression is session-only;
- DataStore code exists but is intentionally bypassed.

This may be a test configuration rather than a defect. Do not enable it blindly.

## Confirmed — audited file is not a published place context

Audit metadata reported:

- `PlaceId = 0`
- `GameId = 0`.

The Studio title also showed an AutoRecovery `.rbxl` snapshot.

Impact:

- this audit describes the local recovered Studio snapshot;
- it does not prove that the published Roblox experience contains exactly the same code/content;
- live DataStore behavior could not be validated from this run.

## Verified workflow hazard — saved ValbrumeWorld is replaced at runtime

The active `WorldBuilder.W.Build()` deletes an existing `Workspace.ValbrumeWorld` and recreates it.

Impact:

- manual edits under the saved `ValbrumeWorld` hierarchy may disappear when runtime generation starts;
- the edit-mode hierarchy is not the final runtime world.

Do not move or delete generated/static content until the intended authoring workflow is decided.

## Verified mismatch to validate — level cap versus expansion difficulty

Current player cap:

- MaxLevel = 10.

Configured expansion mobs reach:

- S3 boss level 12;
- N4 boss level 14;
- O5 boss level 16;
- V6 boss level 18.

Configured equipment tiers currently require levels 1, 4 and 7 only.

This is recorded as a design/progression mismatch to validate, not yet as a gameplay defect. The intended endgame scaling is not documented in the audited source.

## Unknowns requiring runtime testing

Not yet classified as bugs:

- complete first-login flow;
- class/zone selection across respawns;
- 4-skill combat on PC;
- touch combat on a real mobile viewport;
- boss telegraphs and hit validation;
- party creation/join/leader transfer;
- simultaneous dungeon instances;
- dungeon death/respawn/leave edge cases;
- story progression end-to-end;
- expansion story end-to-end;
- ferry traversal;
- lava hazard cadence;
- server performance with full 66-mob population;
- client performance on mobile;
- published-place DataStore locking and recovery.

The existing V2.8 QA script itself states that the player journey still needs testing.
