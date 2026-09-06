# ffdraft

A local, config-driven fantasy football draft engine in R. Objective is to maximize
championship probability for a specific league, not to produce generic rankings.

See `PLAN.md` for the full architecture and phased build plan. This file is the
standing context for every session.

---

## Who you're working with

The user is a lead data/analytics engineer (dbt Core, Snowflake, R/tidyverse, Preset).
Assume deep fluency in data modeling, DAGs, warehouse layering, and R.

**Assume casual, not deep, football knowledge.** They know some things and are
semi-familiar with positions, but don't actively follow the sport — they should never
need to go do outside research to use this tool. This has two consequences:

1. When surfacing a player, name, team, role, and why he matters. Never assume a name
   carries meaning.
2. Plain-English explanation is a product feature of the app itself, not just a
   conversational habit. The "learn mode" pane is load-bearing.

Do not over-explain R, dbt patterns, or statistics. Do explain football.

---

## League facts

**Known — pulled from the real Yahoo settings page for "TKWW2K26 League 5" (ID #1541392)
on 2026-09-04:**
- Company league, organizer is Pete Gentile
- 10-team snake draft, 17 rounds (9 starters + 6 bench + 2 IR)
- Platform: Yahoo
- Draft date: **Tuesday, Sept 8, 2026, 6:00pm ET**, 1-minute pick clock (2026 NFL season
  opens Wed Sept 9 — this is the night before Week 1)
- Roster: QB 1, RB 2, WR 2, TE 1, FLEX (RB/WR/TE) 1, K 1, DST 1, bench 6, IR 2. **Note:
  only 2 WR starters, not 3** — the third receiver-eligible slot is the FLEX.
- Scoring: half-PPR (0.5/reception), 0.04/pass yard, 4/pass TD, **-1/INT** (not -2), 0.1
  per rush/rec yard, 6/rush or rec TD, no first-down bonus, no 300-yard passing bonus,
  standard Yahoo kicker tiers, full DST scoring (sack/INT/fumble/points-allowed tiers —
  recorded in `config/scoring.json` but not yet consumed by `score_player_week()`, which
  is still per-player only; see `R/30_scoring.R`).
- Playoffs: **4 teams, weeks 16-17** (not 6 teams / weeks 15-17) — regular season is
  weeks 1-15.
- `config/league.json` and `config/scoring.json` hold these real values now, not
  placeholders.

**Unknown:** draft slot only.

**Implication:** with team count fixed, sweep mode narrows from 22 (team x slot)
scenarios to **10** — one per possible draft slot in a 10-team snake draft. `my_slot` in
`league.json` stays nullable until the draft order is revealed.

---

## Hard constraints

**Yahoo API is gated. Verified empirically 2026-09-06 — do not re-investigate.**
`sports.yahoo.com/developer/docs/` still documents a self-serve flow instructing you to
"select either Read or Read/Write access for Fantasy Sports" when creating an app. **That
checkbox no longer exists.** The live form at `developer.yahoo.com/apps/create` offers
exactly two API Permissions: "OpenID Connect Permissions" and "TW Auction". You can create
an app and receive a consumer key/secret, but nothing grants the Fantasy Sports scope, so
the key cannot authorize `fantasysports.yahooapis.com/fantasy/v2` calls against a private
league — and this league is private. The docs are stale, not a path in.
Their terms prohibit reverse-engineering
or scraping. `ffscrapr` does NOT support Yahoo (MFL, Sleeper, Fleaflicker, ESPN only).
`YFAR` exists on GitHub but appears unmaintained.

Therefore: **manual pick entry is the primary path, not the fallback.** If API access is
granted, build a thin `httr2` OAuth2 client. Never build live sync as a dependency.

**League settings come from the user, not the API.** They read the Yahoo settings page
and paste values into `league.json`.

**Third-party fantasy libraries are all league-scoped — evaluated and rejected 2026-09-06.**
`ffscrapr` (MFL/Sleeper/Fleaflicker/ESPN, Yahoo only "perhaps eventually"), the Python
`espn-api` package, and ESPN-fantasy MCP servers all require a `league_id` for a league you
are a member of, and return that league's rosters/settings/transactions. **None expose
cross-league ADP, rankings, or projections**, so none of them help a Yahoo league. Do not
re-investigate this category. The gap they would fill — Yahoo's own ADP, i.e. what the nine
opponents will actually do — is real and remains unfilled: `yahoo_id`,
`player_owned_yahoo`, and `player_owned_espn` are 100% NA in `ff_rankings`'
`redraft-overall` slice. Carry that as the known blind spot in Phase 6's opponent model.

**Config-driven or it doesn't ship.** Anything that could vary by league lives in
`config/*.json`, validated against JSON Schema. No league rule is ever hardcoded.

---

## Football primer

Six scoring positions: QB, RB, WR, TE, K, DST. Nothing else exists in this format.
Typical lineup: 1 QB / 2 RB / 2-3 WR / 1 TE / 1 FLEX (RB/WR/TE) / 1 K / 1 DST + bench.

32 teams, 17 games + 1 bye each. Fantasy regular season is weeks 1-14, playoffs 15-17,
so byes and late-season schedules matter more than raw season totals suggest.

Scoring is roughly 0.1 pts per rushing/receiving yard, 0.04 per passing yard, 6 pts for
a rushing/receiving TD, 4 for a passing TD. PPR adds 1 point per reception, half-PPR
0.5. This single knob reorders the entire player pool.

**Scarcity drives everything.** 32 starting QBs and you start one. ~25 RBs get real
volume and you start 2-3. Value over replacement measures exactly this asymmetry.

Vocabulary: ADP (average draft position), ECR (expert consensus rank), targets (passes
thrown at a receiver), snap share, air yards, red zone touches.

### The core modeling principle

**Opportunity is sticky year to year. Efficiency is mostly noise.**

Target share and carry share predict themselves. Touchdown rate does not. Any model that
fails to aggressively regress efficiency is fooling itself, and most public projections
do. This principle governs feature selection in Layer 2 and shrinkage in Layer 3.

### Snake turn structure

For T teams, slot s (1-indexed), round r:
- odd r: `pick = (r-1)*T + s`
- even r: `pick = r*T - s + 1`

Gap structure varies sharply by slot and is the central strategic problem:

| Slot (of 12) | First five picks | Gaps |
|---|---|---|
| 1 | 1, 24, 25, 48, 49 | 23, 1, 23, 1 |
| 2 | 2, 23, 26, 47, 50 | 21, 3, 21, 3 |
| 6 | 6, 19, 30, 43, 54 | 13, 11, 13, 11 |
| 12 | 12, 13, 36, 37, 60 | 1, 23, 1, 23 |

Early slots wait long and then pick back-to-back, so they can punt a position and take
two at the turn. Middle slots have an even rhythm and are never far from their next pick,
so passing on a positional run costs less. Recommendations must be slot-aware.

---

## Stack

- R 4.4+, `renv` for pinning, package structure (`devtools::load_all()`)
- `targets` for the DAG, DuckDB as the local warehouse, parquet for raw
- `nflreadr` (1.5.1+) for all NFL data. `ffsimulator` as a reference implementation
- `jsonlite` + `jsonvalidate` for config, `pointblank` for data validation
- `data.table` / matrices in hot paths, `Rcpp` only if profiling demands it
- `shiny` + `bslib` + `reactable` for the app

## Conventions

- Layer like dbt: `raw` -> `stage` -> `mart`. Numbered files in `R/` follow pipeline order.
- **Never join players on name.** Use `load_ff_playerids()` to build the crosswalk and a
  surrogate key in `dim_player`. Name collisions and mid-season roster churn will bite.
- Scoring must be a pure vectorized function of (stat line, config). Golden-test it.
- Every model outputs a distribution, not a point estimate.
- Validate the config early and fail loudly. A bad `league.json` should not reach a model fit.
- **Docs written in `/caveman` style.** Repo rule. Applies to `PLAN_1.md`, `CONTEXT.md`,
  handoff docs, ADRs, roxygen blocks. Drop articles, filler, hedging. Fragments fine.
  Arrows for causality (X -> Y). Technical terms, code blocks, error strings stay exact.
  Exception per skill: full prose for security warnings, destructive-action confirms,
  ordered multi-step sequences where fragment order risks misread.

## Current status

Nothing built yet. Next action is Phase 0 (see `PLAN.md`).

**First task of Phase 0 is verification, not code.** Every claim in `PLAN.md` about what
nflverse returns is from documentation, unverified against a live session. Confirm actual
column names, 2026 data availability, and join keys before building on them.
