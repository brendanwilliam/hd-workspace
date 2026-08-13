# Hands Diff v2 implementation status

Last reviewed: 2026-08-10

This is the cross-repository implementation checklist for v2. The product and
contract documents in this directory remain authoritative; update this status
after each focused implementation commit.

## Current checkpoint

- OBS: `feature/hands-diff-v2` at `4f57340` (`refactor: remove legacy report heatmap telemetry`).
- Web: `feature/hands-diff-v2` at `2e579b5` (`fix: bootstrap v2 identity schema in migration`).
- OBS validation: the macOS RelWithDebInfo build and full CTest suite pass (7/7 tests).
- Configure troubleshooting: the prior CoreSimulatorService failure recovered.
  If macOS code signing fails on a generated plugin bundle because of a
  `com.apple.FinderInfo` extended attribute, remove that attribute from the
  generated bundle and rebuild; do not change tracked source files for it.

## Checklist

### Contracts and fixtures

- [x] Define the v2 report, binding, reconciliation, and retention contracts.
- [x] Reconcile the stale linked-account-PUUID language with per-report Riot-ID
  resolution in the reconciliation contract.
- [x] Add sanitized Account-V1, Match-ID-list, parsed-binding, metric-stream,
  and reconciliation-outcome fixtures. Reconciliation normalization has focused
  tests; fixture wiring to endpoint stubs remains for integration coverage.

### OBS capture and retained sessions

- [x] Replace legacy collection with supported-game, one-second Live Client
  detection and `0:00` anchors. The state machine and anchors use verified
  `gameQueueConfigId`; legacy report dwell/hexbin telemetry has been removed.
  A real live-game compatibility pass remains.
- [x] Restrict capture to frontmost League and discard focus-loss backlog.
- [x] Add atomic completed v2 session files and newest-20 retention.
- [x] Retain local gameplay detail only; exclude literal keys from persistence.
  Retained events carry strict sequence, monotonic time, derived game time,
  normalized pointer state, and only resolved bound actions/chords; upload
  serialization excludes the local event array entirely.
- [x] Implement the isolated three-second rolling metric engine.
- [x] Connect rolling metrics to live collection and v2 serialization.
- [x] Parse base/champion `input.ini` bindings and ambiguous chords.
- [x] Watch the selected sibling `input.ini` and connect bindings to capture.
  The active champion now atomically selects its override map; invalid reloads
  retain the last known-good map.

### OBS upload and dashboard

- [x] Emit a v2-shaped upload envelope and handle accepted/duplicate/rejected
  responses without opening a recap browser.
- [x] Upload real captured aggregate values and restore retained unconfirmed
  sessions after application restart. The remaining manual verification is a
  full linked-account upload against the deployed service.
- [x] Replace heatmap/dwell behavior with pointer plus a 20-event fading trail.
  The retained report path no longer contains hexbin or dwell telemetry.
- [x] Add Input Analysis controls, safe-area anchors, and privacy-scoped
  bound-key display controls.

### Web ingestion, reconciliation, and recap

- [x] Replace public profile storage with account-owned v2 reports and a
  destructive migration.
- [x] Add strict v2 ingestion, account-scoped idempotency, and private routes.
- [x] Add fixture-driven validation and authorization route tests.
- [x] Complete bounded reconciliation outcome handling and normalized timeline
  event/player/team data. Identity-not-found and ambiguity are terminal;
  input-only reports remain retryable and transient failures use capped backoff.
- [x] Render matched player/team summary, chronological Riot events, and the
  input-only/needs-attention states.

### Release validation

- [ ] Run OBS configure, build, CTest, source-size check, and manual
  Accessibility/focus verification after dashboard changes. Capture changes:
  source-size, build, and CTest passed on 2026-08-10; manual verification remains.
- [x] Run web file-size check, lint, tests, build, and disposable migration.
  File-size, lint, 15 tests, and build passed on 2026-08-10; the destructive
  migration was applied and verified against the disposable Compose database.
- [ ] Validate one complete private recap end-to-end.
