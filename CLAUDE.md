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

**Sleeper API evaluated and rejected 2026-09-06 — do not re-investigate `search_rank`.**
Access is clean (read-only HTTP, no token, terms fine); usefulness is not. `search_rank` is
search-autocomplete popularity, and it is genuinely independent of FantasyPros ECR in the tail
(rho 0.166) while still predicting 2025 PPG there (-0.314 vs ECR's -0.104). But that edge lives
only where `ecr > 290`, and a 10-team 17-round draft removes 170 players — our own 17 picks
bottom out at `ecr` 219. Reordering all 160 matched tail players by `search_rank` changed
**0 of 17 picks and 0.0 starter points**. Real signal, wrong region. Numbers and harness in
`docs/handoff/ffdraft-handoff-20260906-9.md` and `dev/sleeper/`. The `trending/add` endpoint is a
different signal aimed at the Yahoo-ADP blind spot and remains unprobed — this closure does not
cover it.

**Yahoo XRank/ADP ACQUIRED 2026-09-06 — `docs/yahoo_fantasy_football_adp.csv`.**
User-harvested from Yahoo, Gemini-cleaned. Cols `Player,Position,Team,Bye Week,XRank,ADP`.
332 rows, XRank on all 332, ADP on 227, defenses coded `DEF`. Name-joins to the pool at
**170/170 of the top-170-by-ECR** (42.5% of the full 764-row pool — the misses are all
undraftable tail). No `yahoo_id` to join on: 100% NA in the `redraft-overall` slice, so
this is a `normalize_player_name()` join by necessity.

**Gate PASSED 2026-09-06** (`dev/yahoo_gate.R`). Correct use of the data is an **opponent
model, not a board reorder**. Swapping the nine simulated opponents from best-available-by-ECR
to best-available-by-Yahoo-XRank changes **5 of 17 picks** (bar was >= 3) and drops starter
Extra pts **568.5 -> 536.0 (-32.5)**. Read: every strategy conclusion drawn against ECR
opponents is optimistic, because ECR opponents leave value on the board that real Yahoo
drafters take. Our top-70 vs Yahoo XRank: Spearman **0.709**.

Superseded prior claim: an earlier audit concluded "no Yahoo ranking data exists in this
repo." True at the time. `data/yahoo_rankings.csv` remains **our own board exported** by
`export_yahoo_rankings()` (`R/95_export.R:68`) for upload *into* Yahoo — Spearman 0.9976
against our board, a mirror. Do not confuse the two files.

**VONA as a pick selector — three framings tried, all closed 2026-09-07. Do not
re-run.** VONA(X) = vor(X) - E[best vor at pos(X) at my next turn]. Idea sound,
every attempt to make it *choose the pick* failed. Evidence in
`docs/handoff/ffdraft-handoff-20260907-{12,13}.md` and `dev/PREREG_B.md`;
harnesses `dev/bars_a*.R`, `dev/bars_b*.R`; arms live behind `my_rule` in
`simulate_draft()` (`R/80_opponent_sim.R`), reachable only from `dev/`.

- `"vona"` — argmax VONA across all positions. **Rejected #19.** Drafts zero K,
  zero DST at every tau. Correct VONA logic (kickers near-identical -> replacement
  sits right behind -> tiny VONA) applied to slots the league makes mandatory.
- `"vona_fill"` — same, plus `forced_positions()` closing mandatory slots once
  rounds left <= slots open. **Only positive result.** Pre-registered bar A2
  (single frozen seed) FAILED at tau=3; 30 seeds CRN then showed +7..+81, 93% win
  rate, loses at no tau. FAIL stands as recorded, bar was underpowered. Measured,
  never wired to the app.
- `"vona_tiebreak"` — position from `target_position()` as today, VONA orders
  candidates within it. **No-op by algebra, not by measurement.** The subtracted
  term is keyed on position alone, so within one position it is a constant and
  argmax-VONA == argmax-VOR. 0 picks changed across 124 drafts, 1920/1920
  tiebreak picks identical, CI [0.0, 0.0], sd 0.0. Mutation M1 (negate the key ->
  16/17 picks change) proves the branch live. No seed count changes this.

**Not closed: `simulate_forward()`'s `p_available`.** Survival probability per
player over the horizon to my next turn. Never failed a bar because it was never
a selector -- it is a *display*. "12% he survives to your next pick" is the
question a human has on the clock, and it is orthogonal to every VONA verdict
above. `survival_display()` and `VONA_LOW_SURVIVAL` (`R/81_vona.R`) already
format it. Unwired to `inst/app/app.R` only because the draft was hours out.
This is the piece worth reviving.

**Draft-only, does not transfer mid-season.** VONA and the opponent model both
assume snake turn order and run on Yahoo *preseason* XRank. Waivers have no turn
structure and XRank is stale by ~week 3. Do not reach for this code in-season
without a new data source.

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
- **Prefer not to join players on name.** Use `load_ff_playerids()` to build the crosswalk
  and a surrogate key in `dim_player`. Name collisions and mid-season roster churn will bite.
  Name-joining is allowed only when name is genuinely all the source gives you (Yahoo's
  exported ADP/XRank file, for one) — and when you do it, say so at the point of use and
  report the match rate.
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
