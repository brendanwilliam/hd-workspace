# Hands Diff v2: concrete change outline

> **Superseded:** [`v2.md`](v2.md) is the primary implementation reference for
> v2. This document is retained as a record of the intermediate proposal.

This document turns [v2 draft 1](v2-draft1.md) into an implementable product
outline. Draft 1 remains the statement of intent; where this document is more
specific, it is the proposed v2 contract.

## 1. Decisions and boundaries

v2 is two connected products:

1. An OBS plugin that provides a dependable League stream layout and captures
   input only while a League game is active.
2. A web recap that joins the captured session to Riot match data and lets a
   player explore input activity against game events.

The primary v2 experience is an individual player's completed Summoner's Rift
game. Other maps and queues must fail closed (no analysis session) until they
are explicitly supported. The existing overlay must remain usable when the
web service, Riot APIs, or Live Client Data are unavailable.

### Pre-release migration policy

Hands Diff has no active users or production data that must be retained. v2 is
therefore a clean break: it may replace the current local-session format,
report schema, database tables, API routes, plugin settings, and presentation
sources without backward compatibility, import tooling, dual reads, or legacy
renderers. Remove superseded code and test fixtures as part of the relevant v2
change instead of maintaining parallel paths. Existing development data may be
discarded and recreated from the v2 fixtures.

The only compatibility constraint is operational: a v2 plugin and v2 web
service released together must agree on one current contract. During local
development, a schema mismatch should fail explicitly with an upgrade/rebuild
message rather than attempting to interpret legacy data.

### Privacy decision

Draft 1's event stream includes key values. That is incompatible with the
current service promise that it stores aggregate telemetry and never individual
keystrokes. v2 should retain detailed input events locally only, and upload a
privacy-preserving derived report by default:

- Mouse events may include normalized pointer coordinates and button class.
- Keyboard events are reduced into configured, non-text gameplay categories
  (for example `ability`, `summoner_spell`, `camera`, `other`) before upload.
- No typed characters, raw key names, clipboard contents, application/window
  titles, desktop coordinates, or data captured outside an active game are
  uploaded.
- An explicit future opt-in is required before any raw event export or upload.

This preserves local click-trail rendering while keeping the public service's
privacy boundary intact. The report schema must state whether it contains
`aggregate` or `local-event-derived` telemetry; the server accepts only the
former in the initial v2 release.

## 2. Deliverables and release order

| Release | Deliverable | Depends on | Done when |
| --- | --- | --- | --- |
| 2.0a | Layout sources and settings reorganization | existing safe-area calibration | A streamer can place a map cover and one of two camera anchors without input analysis enabled. |
| 2.0b | Local input-event pipeline and click trail | 2.0a | The trail and activity widgets are generated from one event stream during a live game. |
| 2.0c | Live Client session collector | 2.0b | A completed local session has an aligned game ID, player identity, input aggregates, and live snapshots. |
| 2.0d | Web report schema and recap | 2.0c | Replace the current report/storage contract; a linked user can open a recap with timeline-aligned input and verified match data. |
| 2.1 | Optional richer comparisons and insights | 2.0d | New metrics are added without changing the 2.0 event or report contract. |

Each release is independently shippable. Do not block the core overlay on the
Riot Match-V5 fetch, which happens after the game has completed.

## 3. Unified local capture model

### 3.1 Session lifecycle

The collector owns a session state machine:

```text
idle → detecting → active → finalizing → complete
                 ↘ discarded
```

- **idle:** no League game is detected; no input is retained.
- **detecting:** Live Client Data confirms a supported active game and supplies
  an identity/game-time baseline. Do not create a session until validation
  succeeds.
- **active:** record input events and periodic Live Client snapshots. An event
  must satisfy the selected game-frame scope.
- **finalizing:** stop input capture when the game ends, flush local aggregates,
  and resolve the Match-V5 record using the active player's PUUID.
- **complete:** persist/upload the derived report once; retain a retryable local
  queue on failure. **discarded** means the match was unsupported, incomplete,
  or could not be safely identified.

Input timestamps use a monotonic local clock in milliseconds. The collector
also stores a series of synchronization anchors: `(local_monotonic_ms,
game_time_ms)`. Each event's `game_time_ms` is calculated from the latest
anchor; the report includes the observed synchronization error. Wall-clock time
is diagnostic-only and is never used to align gameplay.

### 3.2 Canonical local event

Every captured action produces exactly one local event. It is the source for
the trail, counts, rates, distance, and upload aggregates.

```json
{
  "schema_version": 1,
  "session_id": "uuid",
  "sequence": 1842,
  "local_monotonic_ms": 483920,
  "game_time_ms": 321650,
  "pointer": { "x": 0.5274, "y": 0.8431, "in_game_frame": true },
  "kind": "mouse_button",
  "value": "left"
}
```

Rules:

- `sequence` is strictly increasing within one session; it permits deterministic
  ordering when timestamps are equal.
- `pointer.x` and `.y` are normalized to the League game frame in `[0, 1]`,
  using the coordinate conversion in the
  [League HUD layout contract](../hd-obs/docs/league-of-legends-layout.md).
- `kind` is `mouse_button` or `key`; pointer-motion samples are separate,
  rate-limited samples used only for distance and velocity.
- `value` is `left`, `right`, or `middle` for mouse buttons. For keys it is a
  local-only configured category, never a text character or raw key name.
- Events outside the game frame are dropped rather than clamped.

Store events only in a bounded local session file. Cap both duration and size;
when the cap is reached, continue calculating aggregates and mark the session
as `event_detail_truncated` so no visual or recap implies complete detail.

### 3.3 Derived measures

All product metrics are calculations over the event stream, not separately
collected sources:

| Measure | Definition |
| --- | --- |
| Clicks / keys / actions | Counts of `mouse_button`, `key`, and their union in the selected window. |
| CPM / KPM / APM | Corresponding count in a trailing 60-second window. |
| Mouse distance | Sum of Euclidean distance between consecutive valid pointer-motion samples, in normalized-frame units; display a calibrated physical unit only when DPI and frame mapping are known. |
| Mouse velocity | Distance over elapsed monotonic time, smoothed over a documented trailing window. |
| Top keys | Highest count among the user's locally selected display categories; ties use first occurrence. |
| Click trail | Latest 20 included button/key events, ordered newest-first. Each older event is 5% less opaque than its successor. |

The event stream is immutable after finalization. New metrics are versioned
derivations, so they can be recomputed without changing raw local capture.

## 4. Plugin UI and source changes

### 4.1 Source composition

Keep the existing input activity source compatible. Add or extend dedicated
League presentation sources rather than coupling scene-item manipulation to the
collector:

| Area | Default | Required behavior |
| --- | --- | --- |
| Map cover | Enabled | Cover the minimap side derived from `FlipMiniMap`; use the bundled image unless a custom image is selected. |
| Camera anchor | Enabled | Offer `bottom-center` and `minimap-adjacent`; expose a camera-source selector and transform controls. The user keeps the camera source above Hands Diff in the scene. |
| Top HUD | Disabled | One to four independent widgets in columns. |
| Left HUD | Disabled | One to four independent widgets in rows. |
| Right HUD | Disabled | One to four independent widgets in rows. |

The authoritative geometry is the existing
[League HUD layout contract](../hd-obs/docs/league-of-legends-layout.md). All
new placement is expressed in normalized game-frame coordinates and avoids its
reserved regions. It must work with an offset or ultrawide capture, not only a
full-screen 16:9 desktop.

### 4.2 Widget catalog and defaults

Use a single widget registry with an ID, display name, placement eligibility,
configuration schema, and renderer. Initial registry:

| Widget ID | Eligible areas | Default configuration |
| --- | --- | --- |
| `cumulative_totals` | top, left, right | Clicks, keys, actions |
| `live_key_row` | top, left, right | Current selected gameplay categories |
| `mouse_distance` | top, left, right | Session total |
| `input_intensity` | top, left, right | APM; user may choose CPM, KPM, or velocity |
| `mouse_activity_map` | left, right | Last 20 qualifying events |
| `top_keys` | left, right | Eight selected categories |

Default enabled layout after opting into Input Analysis:

- Top: two columns — `input_intensity` set to velocity, then APM.
- Left: three rows — `mouse_activity_map`, `cumulative_totals` set to clicks,
  then `mouse_distance`.
- Right: two rows — `live_key_row` (maximum four) and `top_keys` (maximum
  eight).

Each region owns only its enable flag, count, ordered widget IDs, and
widget-specific settings. A widget cannot be selected twice within one region.
Unknown or unavailable widgets render a concise placeholder in settings and
are omitted from the live overlay.

### 4.3 Click-trail controls

The activity map replaces dwell-time hexbins for v2. Its settings are:

- **Show left/right clicks** — enabled by default and required for a trail.
- **Show middle click** — disabled by default.
- **Show keys** — disabled by default.
- **Advanced key filter** — disabled by default; when enabled, choose
  allow-list or block-list of local display categories.

Render left/right/middle as red/blue/yellow. A qualifying key is a labelled
point only when local display policy permits it. Never render a literal typed
character. The map shows the current pointer position plus the fading trail;
it does not recreate the retired dwell-time visualization.

### 4.4 Settings flow

1. **General:** map cover; custom cover picker; camera enable/source/anchor and
   existing transform defaults; automatic game/client switching; optional
   advanced game-frame offset with detected `Width × Height` displayed.
2. **Input Analysis:** master opt-in, account-link state, and top/left/right
   layout controls. Disabled analysis must stop collection and hide its widget
   controls.
3. **Privacy and diagnostics:** a plain-language statement of local vs uploaded
   data, session capture status, sync quality, and a development-log action.

Settings must migrate current camera spacing, colors, and typography to the
new defaults. Do not silently overwrite an existing custom value.

## 5. Game-data collection and reconciliation

### 5.1 Live Client Data during a session

Use Live Client Data only for currently running game context. Poll at a
documented, bounded cadence (initial proposal: once per second) and record
changes rather than duplicating identical payloads.

| Need | Endpoint/data | Persisted v2 field |
| --- | --- | --- |
| Session identity and active-player state | `activeplayer` | Riot ID, current gold, level, abilities, one-time rune snapshot |
| Team state | `playerlist` | player identity, team, position, level, dead/respawn state |
| Active inventory | `playeritems?riotId=…` | item ID and observed inventory transition |
| In-game events | `eventdata` | event ID, name, and game-time timestamp |

The collector must deduplicate event IDs and must tolerate an unavailable or
malformed endpoint without ending overlay rendering. It records endpoint
availability in diagnostics, never raw key data or full endpoint payloads.

### 5.2 Post-game Match-V5

After finalization, resolve one exact match by PUUID and a bounded game-start
time window. Fetch both artifacts:

- [`match-v5.json`](match-v5.md) supplies final participant/team outcomes,
  champion, runes, final economy, and validation totals.
- [`match-v5-timeline.json`](match-v5-timeline.md) supplies exact post-game
  events and 60-second player-state snapshots.

Join the active player to Match-V5 by PUUID, then retain the returned
`participantId` for timeline lookups. Match an input event's `game_time_ms` to
timeline events by each event's own `timestamp`, not the enclosing frame time.
Use the first snapshot at or after a time only for state context; it is not an
exact event record.

The recap must label each datum by source:

| Recap data | Authority |
| --- | --- |
| Input counts, trail, distance, and intensity | local event-derived report |
| Current-game gold, items, ability levels, respawns | Live Client observations |
| Kills, objectives, purchases, wards, timeline positions | Match-V5 timeline |
| Final score, result, final inventory, final gold | Match-V5 match record |

When live and post-game values disagree, display Match-V5 as final authority
and preserve the live value only as an observed timestamped sample. A missing
Match-V5 result produces an input-only recap with an explicit “game data still
unavailable” status and retry path.

## 6. Upload and web changes

### 6.1 Versioned report boundary

Replace the current report contract with one v2 schema; do not introduce a
compatibility layer or accept prior report versions. The v2 upload contains:

```text
report id, schema version, capture-policy version
session identity: game ID (if known), PUUID-derived match lookup reference,
                  duration, sync-quality summary
input aggregates: time buckets, button counts, category counts, distance and
                  intensity series, truncation flags
live observations: compact item/ability/level/event changes
match reference: resolved Match-V5 ID and fetch status
```

The server validates the sole supported schema version, ownership/link
authorization, payload size, monotonically increasing time buckets, normalized
coordinate bounds (if coordinates are ever admitted), and no disallowed
raw-key fields. Submission is idempotent on `(account, report_id,
payload_hash)`. The plugin retains a locally encrypted/retryable queue and
reports whether the server accepted, rejected, or has not yet reconciled the
match.

### 6.2 Recap experience

Build one concrete recap route around these views:

1. **Match header:** champion, role, game duration, result, queue, and data
   completeness status.
2. **Input timeline:** APM/CPM/KPM/velocity series with an event lane for
   kills, deaths, objectives, purchases, and level-ups.
3. **Context inspector:** selecting a time range updates input totals and the
   closest valid player/team state.
4. **Mouse activity:** privacy-safe aggregate map or local-only replay data;
   never expose raw keyboard input.
5. **Summary:** final Match-V5 metrics alongside clearly labelled input
   measures, with no claim that input caused an outcome.

The first recap intentionally avoids player-vs-player benchmarking and causal
scores. Those require a sufficient, consented comparison dataset and a separate
methodology.

## 7. Acceptance criteria and tests

### Plugin

- A game starts and ends without retaining input before `active` or after
  `finalizing`.
- A normalized click at a known offset game frame lands at the expected trail
  coordinate; an outside-frame event is omitted.
- The 21st qualifying event removes the oldest trail entry, and opacity decays
  by 5% per click.
- Input totals and APM derived from fixture events match expected values at
  window boundaries.
- Every map-cover/camera/widget placement avoids the safe-area exclusions for
  both minimap sides and both camera anchors.
- A missing Live Client endpoint or failed upload keeps the overlay functional
  and produces a retryable, diagnosable outcome.

### Service and integration

- The service rejects every non-v2 report and payloads containing raw key names
  or text; no legacy report migration is attempted.
- Replaying the same report is idempotent.
- The supplied raw fixtures resolve the active PUUID to the expected Match-V5
  participant and align a selected input timestamp with a timeline event using
  `event.timestamp`.
- A Match-V5 failure yields an input-only recap; later reconciliation enriches
  that same report without duplicating it.
- The recap distinguishes final Match-V5 values from live observations and
  flags incomplete/truncated capture.

## 8. Open decisions before implementation

1. Confirm whether a local, user-exported raw event file is wanted at all; it
   should not be part of the default online product.
2. Define the supported queue/map matrix and the exact active-game detection
   signal for the first release.
3. Choose the report retention and local-session deletion policy.
4. Confirm whether the plugin obtains Match-V5 through the authenticated web
   service (recommended) rather than embedding a Riot API key in the client.
5. Specify how Data Dragon versions are chosen and cached when resolving item,
   champion, and rune IDs.
6. Establish the acceptable synchronization-error threshold and what UI state
   is shown when it is exceeded.

Until these are resolved, implement the local capture and presentation seams so
the choices remain configuration or service-policy changes, not changes to the
canonical event model.
