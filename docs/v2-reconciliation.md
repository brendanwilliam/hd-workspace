# Hands Diff v2 match reconciliation contract

This document defines how a completed local session attaches to Riot Match-V5.
It supplements [`v2.md`](v2.md) and must be implemented by the web service,
not the plugin.

## Inputs captured at session start

The plugin records the following Active Player/Live Client observations at
game-time `0:00`:

- `riotIdGameName` and `riotIdTagLine`;
- local UTC start observation;
- game mode, map number, and map name; and
- a monotonic/game-time synchronization anchor.

The Live Client fixtures do not provide a PUUID or guaranteed Match-V5 match
identifier. Treat captured Riot ID as the lookup input and do not attempt a
Match-V5 lookup until finalization.

## Server-side algorithm

1. Read the captured-at-start game name and tag line from the accepted report.
2. Call Account-V1 `GET /riot/account/v1/accounts/by-riot-id/{gameName}/{tagLine}`.
3. Treat the returned PUUID as this report's lookup input only. Hands Diff does
   not permanently link a PUUID to an account or compare it with a prior
   report.
4. Request Match-V5 IDs for that PUUID with
   `GET /lol/match/v5/matches/by-puuid/{puuid}/ids`.
5. Fetch only plausible candidate match records, ordered nearest to the local
   observed start time.
6. Verify a candidate against the local session: participant PUUID, supported
   map, supported queue, game mode, and a configured narrow start-time window.
7. On one verified candidate, persist `metadata.matchId`, `info.gameId`,
   participant ID, and the reconciliation evidence. Fetch its timeline.
8. If no candidate is available yet, leave the one report as `input_only` and
   retry later. If multiple candidates pass, set `needs_attention` and retain
   diagnostics explaining the ambiguity.

Use the candidate's `info.gameStartTimestamp` for the comparison. A local
wall-clock start is deliberately only a bounded lookup hint, not an event-time
authority.

## Matching outcomes

| Outcome | Required behavior |
| --- | --- |
| One verified candidate | Attach Match-V5 and timeline to existing report. |
| No account result | `needs_attention`; distinguish an invalid Riot ID from a temporary API failure. |
| No candidates yet | `input_only`; preserve retry eligibility. |
| Candidate metadata mismatch | Reject that candidate and continue only with plausible candidates. |
| Multiple verified candidates | `needs_attention`; do not choose arbitrarily. |

## Event alignment

Resolve the PUUID to the timeline participant ID using
`info.participants[]`. Timeline frames are snapshots. For an exact game event,
use the event object's `timestamp`, not its containing frame timestamp. For
state near an input time, use the first timeline snapshot at or after that
time and label it as a snapshot.

See [`match-v5.md`](match-v5.md) and
[`match-v5-timeline.md`](match-v5-timeline.md) for the local field guides.

## Operational controls

The service owns API keys, endpoint routing, rate-limit handling, and retries.
It must implement bounded retry/backoff for transient Riot errors, cache
successful Account-V1 identity resolutions appropriately, and never return its
Riot credentials to the plugin. Record only non-secret reconciliation outcomes
in user-visible diagnostics.
