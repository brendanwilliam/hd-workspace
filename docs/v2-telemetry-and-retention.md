# Hands Diff v2 telemetry and retention policy

This document is the implementation and user-copy reference for v2 data
handling. It supplements [`v2.md`](v2.md).

## Data lifecycle

| Data | Captured when | Local retention | Uploaded | Purpose |
| --- | --- | --- | --- | --- |
| Left/right clicks and in-frame pointer movement | Supported game; League frontmost | Up to 20 sessions | Derived totals and one-second intensity only | Click and velocity metrics |
| Resolved gameplay binding action/chord | Supported game; League frontmost | Up to 20 sessions | Aggregate action counts only | Key totals, APM, local key display |
| Arbitrary literal frontmost keys | Only when key filter is disabled | Ephemeral/local overlay detail only | Never | Optional local Live Keys display |
| Active Player Riot ID and game context | Session start | Up to 20 sessions | Yes, for reconciliation | Resolve the correct completed match |
| Compact Live Client changes | During tracking | Up to 20 sessions | Yes, only when needed by recap contract | Future recap context |
| Full configs, raw API payloads, clipboard, app titles, chat | Never | Never | Not collected |

## User controls

- **Input analysis:** disabled by default. It enables input-analysis widgets and
  local capture behavior described by v2.
- **Upload game data:** enabled by default. It uploads a completed retained
  session and retries earlier retained sessions not confirmed uploaded.
- **Show bound keys only:** enabled by default per Live Keys/Top Keys. Turning
  it off broadens local overlay display only; it does not broaden uploads.

The UI must state that sessions are retained locally only for the newest 20
games. The oldest is deleted when a new completed session exceeds that limit,
including a session that was never uploaded.

## User-facing copy requirements

The upload setting must plainly communicate:

> Completed tracked games are uploaded automatically for web review. Hands Diff
> keeps the newest 20 games on this computer. It uploads gameplay summaries,
> not typed text or raw keyboard input.

The local key-filter setting must plainly communicate:

> Show bound keys only displays configured League actions. Turning it off can
> show other keys locally while League is focused; those keys are never uploaded
> or included in game statistics.

## Deletion and failure behavior

- Finalized session data may be deleted only through normal 20-session eviction
  or an explicit user deletion control.
- Failed/rejected uploads remain local until eviction. A rejection exposes a
  clear reason and is not retried unchanged.
- Disabling uploads stops automatic submission but does not erase retained
  sessions.
- Unlinking an account removes upload authorization and stops automatic
  submission; retained sessions follow the same 20-session eviction rule.

Do not promise recovery of a locally evicted session. Server-side report
retention/deletion is a separate web privacy policy and must be documented
before public release.
