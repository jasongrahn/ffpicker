# ffdraft — Handoff #14: import thread closed, bench phase now recommends

**Repo**: `https://github.com/jasongrahn/ffpicker`
**Local**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: 2026-09-06
**Draft**: Tuesday, Sept 8, 2026, 6:00pm ET — **~2 days out**
**Prior**: `docs/handoff/ffdraft-handoff-20260906-6.md` (#13)
**Git**: `main`, clean at `9b7a7d8`. 443 tests pass (was 424).

---

## Import thread: CLOSED. Do not reopen.

Probe uploaded. **25 of 25 matched.** Per #13's own table that means the
players were never the problem. User also re-uploaded the full
`data/yahoo_rankings.csv` — **508 of 510 matched**, 2 unmatched, both past
rank 470.

So #13's "292 imported / 218 failed" is dead as a number, not just as a
hypothesis. Whatever caused it did not survive the re-export. All three
candidate causes are now falsified:

| Hypothesis | Status |
|---|---|
| Team column validated (#12) | Dead — killed in #13 by arithmetic |
| Our spelling was wrong (#12) | Dead — killed in #13, 473/510 confirmed |
| Player outside Yahoo's importable pool (#13) | Dead — probe matched 25/25 |
| Row-count / rank-range cap (#13) | Dead — 510-row file matched 508 |

`data/yahoo_rankings.csv` imports. The 37 unconfirmed names from #13's
"Known gaps" cost 2 rows out of 510 and are not worth chasing. **No further
Yahoo name, export, or import work has value.** Delete that thread.

---

## What shipped

### 1. Bench-phase recommendations — `R/79_scarcity.R`, `R/90_explain.R`

The bug, from #13's carried-forward list. Starter need ran out in round 8 of
the 17-round dry run. `draftable_now()` returned nothing ->
`target_position()` returned NA -> `recommend_picks()` returned zero rows ->
**rounds 8-14 named no player.** Nine picks of seventeen with a blank advice
pane under a 1-minute clock. Unsteered, those picks went to whoever sat
highest on the board — which put **three quarterbacks** on a roster that
starts one.

Fix: `draftable_now()` now falls through to new `bench_open()` when no
starter slot is draftable. Two filters make a bench pick mean something.

- `bench_room > 0` — drops positions already at their roster cap. A third QB
  can never enter a lineup, so his VOR is unspendable however large it is.
- `tier_supply > 0` — drops positions with nobody left.

What survives is ranked by the same `rank_positions()` starter needs use, so
a position whose tier empties before your next turn still sorts first.
Deferred positions stay excluded, so this cannot recommend a kicker in round
8 through the back door.

`starter_needs()` split out of `draftable_now()` so `explain_scarcity()` can
tell which phase it is in and stop saying "you still need one" when the
lineup is set. Bench sentence names the player: *"Starters set apart from
defense (round 15) and kicker (round 16). Best bench value is Josh Jacobs
(RB, GB)."*

New report columns: `roster_count`, `bench_room`. A report predating them
degrades to the old no-recommendation behaviour rather than erroring —
same rule as `vor_best_or_na()`.

### 2. `roster.max_at_position` — `config/league.json` + schema

`{ QB: 2, RB: 7, WR: 7, TE: 2, K: 1, DST: 1 }`. Config, not code — it is a
league rule. Omit a position to leave it uncapped (`bench_room` = `Inf`).

### 3. `renv::snapshot()`

`shiny`, `httpuv`, `later`, `promises`, `sourcetools`, `xtable` recorded.
The out-of-sync warning that printed on every `Rscript` call is gone.
`renv::status()` clean.

---

## Dry run, before vs after

`Rscript dev/dryrun.R`, slot 5, 17 rounds.

| | Before | After |
|---|---|---|
| Rounds 8-14 advice | blank | names a player every round |
| QBs drafted | 3 | 2 |
| Kickers drafted | 2 | 1 |
| Starter Extra pts | 568.5 | 568.5 |

Starter total unchanged is correct, not a null result — the fix only touches
picks made *after* every starter slot is full. It buys bench quality and
stops waste.

**Gotcha that cost a cycle:** `dev/dryrun.R` reads `league_config` from the
`_targets` store, not from `config/league.json`. Editing config alone changes
nothing. Run `targets::tar_make(names = "league_config")` first.

---

## Known gaps

- **`draft_pool` misses 281 players.** They sit in `redraft-{qb,rb,…}` but
  not `redraft-overall`, so they never reach the Board. ~20 min. Biggest
  open item.
- **Yahoo ADP unconsumed.** `parse_yahoo_names()` returns `xrank`/`adp` for
  the 300 paste players. CLAUDE.md calls Yahoo ADP the one unfilled blind
  spot in the Phase 6 opponent model. Nothing reads it yet.
- **`max_at_position` values are judgement, not measurement.** QB 2 / TE 2
  are near-certain in a 1-QB 1-TE league. RB 7 / WR 7 are loose enough to
  bind rarely. Nothing tunes them.
- **DST scoring still unconsumed** by `score_player_week()` (per CLAUDE.md).

---

## Do next

1. **Union position slices into `draft_pool`.** ~20 min. 281 players
   currently invisible to the Board.
2. **Print `data/yahoo_rankings.csv`.** Offline backup for the night the app
   will not start. ~2 min, do it before Tuesday.
3. Everything else is optional before the draft.

---

## Draft-night facts

- Draft room opens **30 min before** 6:00pm ET Tuesday. Team names and draft
  order visible there — `my_slot` in `league.json` stays null until then, and
  is entered in the app's setup screen, not the config file.
- 1-minute pick clock.
- Relaunch the app with `dev/relaunch.sh`.
- `data/yahoo_rankings.csv` imports into Yahoo's pre-draft rankings cleanly.
