# Valbrume — Canonical Studio Baseline

## Decision

The Roblox Studio snapshot audited on 2026-09-29 is selected as the working baseline for the next development phase.

This baseline was opened from the AutoRecovery file audited in Studio. It is the reference snapshot from which cleanup, source capture, testing and later implementation decisions will proceed.

## Freeze rule

Before deleting old project copies or historical in-place backups:

1. keep one untouched local copy of this baseline;
2. capture the active Luau source into GitHub without behavior changes;
3. verify the GitHub copy against the Studio source;
4. run a baseline Play/Start Server smoke test;
5. only then classify old material as safe to archive/delete.

## Scope of the decision

"Old material" does **not** automatically mean objects inside the current place.

Do not delete folders or Instances from this baseline solely because they look old. The audited code uses runtime generation and contains historical/compatibility paths, staging assets and art-pass content whose dependencies must be checked first.

In particular, cleanup of the current Studio hierarchy is a separate milestone from selecting the baseline.

## Branches

- `main`: untouched repository root until baseline acceptance.
- `audit/initial-studio-inventory`: initial inventory and audit documentation.
- `baseline/studio-2026-09-29`: canonical baseline preparation.

## No gameplay changes

No gameplay behavior, balancing, architecture or runtime system is changed by this decision.
