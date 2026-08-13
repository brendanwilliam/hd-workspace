# Hands Diff v2 report contract

This document defines the plugin-to-service boundary for v2. It supplements
[`v2.md`](v2.md), which remains the primary product reference. The service and
plugin support exactly this contract; they do not read, migrate, or emit older
report versions.

## Transport and ownership

- The plugin uploads to the authenticated Hands Diff service over HTTPS.
- The service, not the plugin, owns Riot API credentials and all Account-V1 or
  Match-V5 requests.
- The plugin submits one report per locally retained session. Retrying the same
  report must be safe.
- The authenticated Hands Diff account owns every accepted report. A report
  cannot name a target account in its JSON body.

## Report envelope

The initial v2 payload is logically shaped as follows. Field naming may use the
project's implementation convention, but meaning and privacy constraints must
not change without a new schema version.

```json
{
  "schema_version": 2,
  "report_id": "a0f59d84-9d21-4d07-b903-2ec435ee0c1e",
  "capture_policy_version": 1,
  "payload_hash": "sha256-of-canonical-payload",
  "capture": {
    "started_at_utc": "2026-08-10T19:30:00Z",
    "duration_ms": 1357000,
    "game_mode": "CLASSIC",
    "map_number": 11,
    "riot_id": { "game_name": "Player", "tag_line": "NA1" },
    "frontmost_capture": true,
    "complete": true,
    "event_detail_truncated": false
  },
  "input": {
    "left_clicks": 840,
    "right_clicks": 1732,
    "gameplay_key_actions": 504,
    "intensity_by_second": [],
    "summary": {
      "peak_apm": 280,
      "median_apm": 112,
      "peak_mouse_velocity": 0.42,
      "median_mouse_velocity": 0.08
    }
  },
  "live_context": { "changes": [] }
}
```

`payload_hash` is calculated from the canonical payload excluding the hash
field itself. It detects an accidental changed retry for the same `report_id`.

## Field rules

| Area | Required rules |
| --- | --- |
| `report_id` | A UUID created once at session creation and unchanged across retries. |
| `schema_version` | Must equal `2`; all other values are rejected. |
| `riot_id` | Captured from Active Player at session start; not refreshed from current profile data during upload. |
| `started_at_utc` | Local wall-clock observation used only for bounded Match-V5 reconciliation. |
| `duration_ms` | Positive duration derived from monotonic capture/session time. |
| `intensity_by_second` | Ordered, one value per game-time second, with no duplicate seconds. See [`v2.md`](v2.md#measurement-definitions). |
| `live_context` | Compact changes only; never repeated full Live Client payloads. |

The server rejects malformed identifiers, out-of-order time buckets, impossible
negative counts, oversized payloads, or a hash that conflicts with a previous
successful submission for the same report ID.

## Prohibited payload data

The report must never contain:

- arbitrary literal keys or typed text;
- raw keyboard/mouse event records;
- clipboard data, window titles, desktop coordinates, or input captured while
  League was not frontmost;
- full `input.ini`, `game.cfg`, or full Live Client response objects;
- Riot API keys, League local credentials, or other secrets.

The service treats unknown fields as an error for v2 rather than silently
persisting potentially sensitive telemetry.

## Submission response and lifecycle

The response returns the stable report URL/ID and one status:

| Status | Meaning | Plugin behavior |
| --- | --- | --- |
| `accepted` | Payload is stored; reconciliation may still be pending. | Mark this payload hash uploaded. |
| `duplicate` | Same account, report ID, and hash already accepted. | Mark uploaded. |
| `rejected` | Payload cannot be accepted. | Keep local session and show actionable error; do not retry until the data/version changes. |
| `retry_later` | Temporary server/network/Riot dependency failure. | Keep local session for automatic retry. |

The plugin retries all retained, unconfirmed sessions after each completed
session when **Upload game data** is enabled. It must use bounded exponential
backoff within a run; a later completed game is another retry opportunity. The
20-session cap still evicts the oldest report, even if that report is pending.

## Reconciliation result

Reconciliation is asynchronous to payload acceptance. The service records one
of `pending`, `matched`, `input_only`, or `needs_attention`:

- `matched`: a verified Match-V5 record and timeline are attached.
- `input_only`: no matching game is currently available; retry remains allowed.
- `needs_attention`: captured Riot ID cannot be resolved or candidates are
  ambiguous. Each report resolves its captured Riot ID independently; Hands
  Diff does not permanently link a PUUID to an account or prior report.

The service enriches the existing report after a match is found; it never
creates a second report for the same local session.
