# Hands Diff v2 input binding contract

This document defines how v2 turns League's `input.ini` into privacy-scoped
gameplay actions. It supplements [`v2.md`](v2.md); use
[`raw-data/input.ini`](raw-data/input.ini) as the parser fixture.

## Discovery and safety

`input.ini` is the sibling of the user-selected `game.cfg`. Read only that
file's binding declarations. The plugin must not scan unrelated configuration
files, upload the file, or log its contents.

An absent, unreadable, blank, or temporarily invalid file leaves the last valid
binding map active and exposes a settings/status warning. A fresh installation
without a valid map may still track left/right click metrics, but it does not
count keys as gameplay actions or upload key-action totals.

## Parsing rules

1. Read `[GameEvents]` as the base mapping.
2. Read `[GameEvents.<Champion>]` for the active champion. A valid
   champion-specific entry overrides the base entry with the same event name.
3. Treat comma-separated entries as separate bindings for the same action.
4. Parse bracketed tokens into modifiers plus one final non-modifier trigger.
   Examples: `[q]`, `[Alt][q]`, and `[Cmd][Left Arrow]`.
5. Discard blank and `[<Unbound>]` entries.
6. Normalize key names and modifier ordering for comparison and display. The
   project must choose one presentation order, for example `Cmd+Shift+Q`.
7. A chord produces one action when its final non-modifier trigger is pressed
   while every required modifier is down. Do not count modifier press/release
   events as separate actions.

If two candidate actions share a chord, use the most specific current-champion
mapping. If the conflict remains, mark the chord ambiguous: it may be displayed
locally but must not count toward gameplay key actions until the conflict is
resolved by an explicit deterministic rule and test.

## Action registry

| Action family | Base declaration | Examples in fixture |
| --- | --- | --- |
| Ability 1–4 | `evtCastSpell1`–`evtCastSpell4` | `Q`, `W`, `E`, `R` |
| Summoner spell 1–2 | `evtCastAvatarSpell1`–`evtCastAvatarSpell2` | `D`, `F` |
| Item 1–6 | `evtUseItem1`–`evtUseItem6` | `1`–`6`, modifier variants |
| Trinket | `evtUseVisionItem` | configured binding if present |
| Role-bound / role quest | `evtCastRoleBound` | `Shift+V` in fixture |
| Recall | `evtUseItem7` | `B` in fixture |
| Shop | `evtOpenShop` | `P` or `N` in fixture |

For every applicable family above, resolve valid `evtSelfCast*`,
`evtNormalCast*`, and `evtSmartCast*` variants. Preserve the semantic action ID
(`spell_1`, `self_cast_spell_1`, `normal_cast_spell_1`, and so on) and the
literal configured chord. That allows the overlay to show `Alt+Q` without
storing a generic arbitrary-key event for upload.

## Display and metric behavior

Live Keys and Top Keys have **Show bound keys only**, enabled by default.

| Mode | Overlay | Upload and metrics |
| --- | --- | --- |
| Enabled | Show resolved action bindings/chords only. | Resolved gameplay keys count toward total keys and APM. |
| Disabled | Also show arbitrary literal frontmost League keys locally. | Arbitrary literal keys never upload and never affect totals, APM, or Top Keys ranking. |

Left/right physical clicks count in the initial APM definition regardless of
binding-map availability. Middle clicks are local presentation detail and do
not count in initial APM/KPM metrics.

## Required golden tests

Add a small expected parsed-map JSON fixture next to `input.ini`. It must cover:

- base mappings such as Q/W/E/R and D/F;
- multiple entries such as shop P/N;
- modifier chords such as Alt+Q and Cmd+Left Arrow;
- unbound declarations;
- a champion-specific override; and
- ambiguous duplicate chords.

Tests must also prove that a modifier chord increments once, an unbound literal
key can appear locally only when the filter is disabled, and no arbitrary
literal key can reach the v2 report payload.
