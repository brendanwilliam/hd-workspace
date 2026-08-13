# v2 raw-data fixtures

These files are sanitized development fixtures for the Hands Diff v2 contracts.
They are not a complete specification of Riot responses and must not contain
credentials, personal account data, or unredacted local configuration.

| File | Use |
| --- | --- |
| `activeplayer.json` | Captured-at-start Riot ID and active-player fields. |
| `allgamedata.json` | Live Client game-time, mode, map, players, and events. |
| `allgamedata-supported-queue.json` | Sanitized supported-game start with the authoritative `gameQueueConfigId`. |
| `game.cfg` | Game-frame and HUD layout configuration. |
| `input.ini` | Binding parser input, including modifiers and champion overrides. |
| `match-v5.json` | Completed-match response fixture. |
| `match-v5-timeline.json` | Completed-match event/frame timeline fixture. |
| `swagger_openapi.json` | Snapshot of the local Game Client API description. |

The Account-V1, match-ID-list, parsed-binding-map, three-second-metrics, and
reconciliation-outcome fixtures use fictitious identities and identifiers.

Name fixtures by endpoint or behavior, not a real player's identity. Pair every
non-trivial fixture with a test that demonstrates the expected contract.

## Refreshing fixtures

When League changes, capture fixtures only from a development account and
sanitize them before committing. Record the game/client patch version and
capture date in the fixture or its adjacent test. Review affected contracts
when the local Swagger description, `game.cfg`, `input.ini`, or Match-V5 shape
changes.
