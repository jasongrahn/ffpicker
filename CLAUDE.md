# ffdraft

Local, config-driven fantasy football engine in R for one Yahoo league. Objective: maximize
championship probability for this league, not generic rankings. Draft engine done
(2026-09-08); in-season work = weekly decisions + league-wide sims.

This file = standing rules, each with its key number. Full evidence, history and closed
investigations: `docs/adr/`. Draft-era build plan + architecture: `PLAN_1.md`. Live season
state: newest doc in `docs/handoff/`. New facts go here (rule + key number) or in a new ADR —
never in auto-memory.

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

Yahoo "TKWW2K26 League 5" (ID #1541392). Settings page read 2026-09-04; real values in
`config/league.json` and `config/scoring.json`.
- Company league, organizer Pete Gentile. Our team: **JGrahnasaurs**, drafted from slot 10.
- 10 teams, snake draft, **15 rounds** (9 starters + 6 bench). IR 2 exists but is **not
  drafted** — a 17-round assumption cost us the Week 1 kicker (handoff #24).
- Roster: QB 1, RB 2, WR 2, TE 1, FLEX (RB/WR/TE) 1, K 1, DST 1, bench 6, IR 2. **Only 2 WR
  starters, not 3** — the third receiver-eligible slot is the FLEX.
- Scoring: half-PPR (0.5/reception), 0.04/pass yard, 4/pass TD, **-1/INT** (not -2), 0.1 per
  rush/rec yard, 6/rush or rec TD, no first-down bonus, no 300-yard passing bonus, standard
  Yahoo kicker tiers, full DST scoring (sack/INT/fumble/points-allowed tiers — in
  `config/scoring.json` but not yet consumed by `score_player_week()`, which is still
  per-player only; see `R/30_scoring.R`).
- Season: regular weeks 1-15; playoffs **4 teams, weeks 16-17**. Schedule = round robin wks
  1-9, then wks 10-15 replay wks 1-6. Full grid (no Yahoo export carries it):
  `data/weekly/2026_league_schedule.csv`.
- Standings tiebreak = points for. Inferred, not read off settings: every W-L tie is ordered
  by PF; head-to-head ruled out (a wk4 winner ranks below the team it beat).
- Waivers: continual rolling list, **no FAAB** — never reason about bids. Each drop clears 2
  days later (`W (Oct 7)` = clears Oct 7), so the pool refreshes daily. Weekly waivers
  setting: "Game Time - Tuesday". Injured players can be added straight to IR; the 2 IR
  slots sit outside the 15-man roster -> an empty IR slot is a free stash.
- `config/league.json` `max_at_position` K 1 / DST 1 = our draft-time cap, **not** a league
  rule (we carried 2 K). Waiver settings are not in that file — its schema has
  `additionalProperties: false`.
- 10 teams x 1 QB slot -> starting-calibre QBs sit on the wire (3 at 16+ pts, 2026-10-21) ->
  a QB surplus is weak trade currency (best partner gain from any of ours: +1.2/wk).

---

## Season objective. Win matchups, not points.

User, 2026-10-21: "We don't need to dominate, we just need to win each remaining matchup -
even by 1 point." Target = P(top 4). 4 pts added to a 20-pt win = 0; 2 pts added to a 1-pt
loss = the season.
- Price every move and score every test **in wins**: `dev/weekly/playoff_odds.R` (P(top 4),
  per-game leverage, exchange rate), `dev/weekly/trade_finder.R`. Margin only where near 0.
- Exchange rate shrinks as weeks run out — rerun, never quote a stale one. 2026-10-21:
  +1 pt/wk ≈ +0.09 wins, +0.7pp P(top 4).
- **Lineup layer is at its ceiling -> the lever is roster quality + the two free streaming
  slots.** Wks 1-4 regret: 0.80 from our choices, 73.62 from projection error (ADR 0010).
- Run tests across all 10 rosters, not just ours — ours is n=1 per week.

## League-wide sim — `dev/weekly/`

`read_yahoo_week.R` <- `league_sim.R` <- `playoff_odds.R`, `trade_finder.R`,
`predictions.R`. `ceiling_vs_margin.R` = gate test + noise constants.
- **Gate PASSED** (wks 3-6, n=20 matchups): roster-ceiling diff -> margin r +0.49, p 0.028,
  slope +1.17, resid sd 30.0. Prior-weeks PPG weaker (r +0.36, p 0.12). Favourite wins only
  10-12 of 20: typical gaps 5-10 pts vs ~30 pts of margin noise.
- **Noise constants — every sim number rests on them:** per-team weekly sd(actual − ceiling)
  **22.0**, mean gap **−3.88**, team-score sd 26.3. `ceiling_vs_margin.R` adds each week
  once its scores are entered.
- Rosters = clean export (`clean_tmpl()`: latest pull with every Game cell unstarted) +
  `TXN` (moves logged after it). Env: `CUR_WEEK`, `BASE` (default `mean`), `GAPMODE`
  (default `uniform`).
- Base projection: zero in both of the last two applicable exports -> base 0. **No
  injury-tag exception** — an injured backup carries a tag too (Mariota read as a 17.8-pt
  starter).
- Fill **empty** slots only (bye holes). Filling weak starters too makes every FA add score
  0 by construction. Without the fill, a sim fakes bye holes (one wk14 P(win) read 46%;
  with the fill, 25%).
- Drop logic is blind to trade value -> protect trade chips explicitly (auto-drop cut
  Mahomes, the trade chip, for McLaurin).
- Shortlist trades **per partner**. A league-wide top-k by strength gain = one partner, and
  never tries non-contenders, where arming the partner costs nothing.

---

## Hard constraints

**Yahoo API: Fantasy access DENIED 2026-10-27 ("not enough information"); user chose not to
re-apply -> manual paste is the only path. Not an open item.** Settings: user reads the Yahoo settings page -> `config/league.json`. Weekly
data: user-pulled exports -> `docs/uploads/week_NN_data/`. Our app's
`401 additional_authorization_required` = never provisioned (12 probes, 2026-09-15). **Do
not re-run the probes; they cannot change the answer.** Scraping prohibited by Yahoo terms.
If access is ever granted: thin `httr2` OAuth2 client, never live sync as a dependency.
History, probe table, form facts: `docs/adr/0002-yahoo-api-manual-paste.md`.

**Draft-era investigations are closed: `docs/adr/0003`-`0006`** (third-party libs, Sleeper
`search_rank`, Yahoo XRank opponent model, VONA). Snake turn math + sweep mode: `PLAN_1.md`.
Read all of it before the 2027 draft. **None of it transfers mid-season:** VONA and the
opponent model assume snake turn order and run on *preseason* XRank; waivers have no turn
structure; XRank is stale by ~week 3. Do not reach for draft code in-season without a new
data source.

**Config-driven or it doesn't ship.** Anything that could vary by league lives in
`config/*.json`, validated against JSON Schema. No league rule is ever hardcoded.

---

## Football primer

Six scoring positions: QB, RB, WR, TE, K, DST. Nothing else exists in this format.
Typical lineup: 1 QB / 2 RB / 2-3 WR / 1 TE / 1 FLEX (RB/WR/TE) / 1 K / 1 DST + bench.

32 teams, 17 games + 1 bye each. This league: regular season weeks 1-15, playoffs 16-17,
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
do. This principle governs feature selection in Layer 2 and shrinkage in Layer 3
(`PLAN_1.md`).

### Game script. RB slope only, never a tiebreak. ADRs 0007, 0008.

The spread moves fantasy points **for RBs only**. RB multiplier = `1 + 0.00799 *
favouredness` (n 779, p 0.0109; 2024-25 starter-calibre player-weeks, points relative to
each player's own season average; `dev/weekly/mult_measure.R`). WR and QB = **1.0** — no
multiplier in either direction (WR -0.00129 p 0.68, QB +0.00562 p 0.10; RB-vs-WR interaction
p 0.041). Use the slope, not the 09-23 buckets (1 of 22 cells significant); it is linear, so
it extends past them (7-pt dog -> 0.944).
- **No blowout tax.** QBs favoured by 10+ score 1.120x their own average (n 37). A big
  spread mostly means a bad opponent.
- WR: an underdog team is not a reason to bench, a favourite not a reason to start. Let the
  projection decide.
- High game total helps RBs (47+ -> 1.061 vs 0.939 at 41-44).
- **Inside a ~5% projection gap NOTHING arbitrates — start the higher raw Yahoo projection
  and stop.** Spread tiebreak retired 2026-10-13: 215 discordant pairs, spread pick right
  48.8%, CI [0.420, 0.557], -0.488 pts/decision. A 0.6-pt edge cannot arbitrate a 9-pt coin
  flip. Do not revert to usage either.
- Use the slope to describe an RB's expected week, never to pick between two players.
- **Do not score "do the multipliers work" in a weekly retro** — signal:noise ~1:10,
  resolving it needs ~1,000 player-weeks.
- Kill condition: `mult_measure.R` rerun on 2026 data at season end.

### Streaming K and DST. The only near-free weekly lever. ADR 0011.

One roster spot each, both slots forced -> a matchup swap costs only the claim.
- **DST: rank by opponent implied total** (`total/2 - spread/2`), lowest first — points
  allowed dominate DST scoring (`config/scoring.json` tiers: 0 allowed = 10, 1-6 = 7,
  7-13 = 4, 14-20 = 1, 21-27 = 0). **Validated** 2026-10-06, 32 teams wks 1-4, n 128:
  r -0.275, p 0.0017, edge **+1.92 pts/wk** over a random DST (`dev/weekly/dst_test.R`). Own
  implied total irrelevant (p 0.81). Rejected add-ons: game total (p 0.20), bottom-quartile
  kink (p 0.29).
- Explains only 7.6% of DST variance (edge 0.39 sd) -> it will look wrong in single weeks.
  **Do not kill it on a bad week**; the >3-pt kill bar is retired for DST.
- **K: rank by own implied total**, highest first. Untested — no league-wide K harness yet.

---

## Stack

- R 4.4+, package structure. **Load with `pkgload::load_all(".")`** — `devtools` is not
  installed. `renv` is out of sync: a warning on every `Rscript`, cosmetic; inspect with
  `renv::status()`.
- `targets` for the DAG, DuckDB as the local warehouse, parquet (`arrow`) for raw
- `nflreadr` (1.5.1+) for all NFL data. `ffsimulator` as a reference implementation only
- `jsonlite` + `jsonvalidate` for config, `pointblank` for data validation
- `data.table` / matrices in hot paths, `Rcpp` only if profiling demands it
- Plain `shiny` for the draft app (`inst/app/app.R`)
- Python 3 for `dev/weekly/leaguewide_retro.py` (+ two week-2-era helpers)

## Commands

```bash
Rscript -e 'pkgload::load_all("."); testthat::test_dir("tests/testthat")'   # tests
Rscript -e 'targets::tar_make()'                                             # pipeline
Rscript dev/weekly/pull_nflreadr.R         # refresh nflreadr data -> data/nflreadr/
Rscript dev/weekly/predictions.R freeze    # before first kickoff; refuses after it, or overwrite
Rscript dev/weekly/predictions.R score     # every frozen week whose scores are entered
Rscript dev/weekly/playoff_odds.R          # P(top 4), per-game leverage, exchange rate
Rscript dev/weekly/trade_finder.R          # trades vs all 9 rosters, scored in wins
python3 dev/weekly/leaguewide_retro.py WEEK PROJ_DATE ACT_DATE   # or --pool WEEK:PROJ:ACT ...
```

After MNF, in order: exports (`yahoo-ff-collector` skill) -> `pull_nflreadr.R` -> enter
scores in `data/weekly/2026_league_schedule.csv` -> `schedule_check.R` -> the week's
`score_weekNN.R` -> `ceiling_vs_margin.R` -> `predictions.R score` ->
`leaguewide_retro.py` -> `trade_finder.R`.

## Layout, in-season

- `docs/uploads/week_NN_data/` — raw Yahoo exports, one folder per week. Read through
  `dev/weekly/read_yahoo_week.R`, never ad hoc.
- `data/weekly/` — decision logs (`2026_weekNN_decisions.md`), frozen lineups
  (`_myteam.csv`, `_opponent.csv`), frozen predictions, schedule grid, regret log
  (`README.md`).
- `dev/weekly/` — rerunnable harnesses. Each ADR names the one behind its numbers.
- `R/41_weekly.R` (weekly mart), `R/42_deadlines.R` (lineup deadlines) — packaged.
- `docs/adr/` — decisions + evidence. `docs/handoff/` — session state, index `README.md`.

---

## Conventions

### Data and joins

- Layer like dbt: `raw` -> `stage` -> `mart`. Numbered files in `R/` follow pipeline order.
- **Prefer not to join players on name.** Use `load_ff_playerids()` to build the crosswalk
  and a surrogate key in `dim_player`. Name collisions and mid-season roster churn will
  bite. Name-joining is allowed only when name is genuinely all the source gives you
  (Yahoo's exported ADP/XRank file) — then say so at the point of use and report the match
  rate.
- **Align by key, never by position across two sorts.** dplyr `arrange()` sorts in the C
  locale, base `sort()` in the system one -> "JGrahnasaurs" and "Jason's Jazzy Team" swapped
  -> matrix rows mislabeled, P(top 4) read 33% vs truth 4.4%, no error.
  `stopifnot(identical(rownames(M), teams))`.
- **Team names are byte-exact.** "Dave’s Bone Crushers", "Max’s TD Bombers" = U+2019;
  "Jason's Jazzy Team" = straight apostrophe. Same in `Roster Status`. Never normalise one
  side only.
- **Multi-position eligibility exists** (`RB,TE`, `WR,RB`, `WR,TE`; 8 players in wk7).
  `pos %in% p` fills no slot for them, silently — the `optimal()` copies in
  `league_ceiling.R`, `ceiling_vs_margin.R`, `regret_decomp.R`, `roster_error.R` all do
  this. `league_sim.R` stops loudly. None rostered wks 3-7, so no past number is wrong.
- Scoring must be a pure vectorized function of (stat line, config). Golden-test it.
  **`score_player_week()` is validated 26/26** vs Yahoo box scores wks 1-2, incl. 2-pt
  conversions and kicker FG bands. Do not re-validate. **DST is the only gap** — per-player
  by design; worth 21.00 (14% of the total) in Week 2.
- **nflreadr name gotchas are silent.** `Kenny` not `Kenneth` Gainwell; the column is
  `passing_interceptions`, not `interceptions`. A miss returns `NA` through a join, not an
  error.
- **`yahoo_id` coverage collapses by draft class**: 2022 85.6%, 2023 75.4%, 2024 32.3%,
  **2025 0.3%, 2026 0%** -> an **id-only join silently drops every rookie**.
  `attach_nfl_ids()` falls back to name and records which key was used in `method`. Do not
  "fix" it to id-only.
- **`load_schedules()` `temp`/`wind` are NA for every unplayed game** — backfilled post-game
  only. Use the market total as the weather proxy.

### Yahoo exports

- **Weekly exports (week 3 format onward) carry a `Player ID`** -> join it to
  `load_ff_playerids()$yahoo_id`, not names. Reader: `dev/weekly/read_yahoo_week.R`. Its
  three silent traps are handled; do not simplify them out:
  (a) **headers hold invisible private-use-area characters** — "Fantasy Fan Pts" really
  ends in U+E002, a sort-arrow glyph, so `d[["Fantasy Fan Pts"]]` returns **NULL rather
  than erroring**;
  (b) the file glob must **whitelist the six position files** — `gamedaycalls` and
  `injuries` share the prefix but not the schema;
  (c) the stat columns are **projections for the upcoming week** (decimal TD counts are
  the tell) — **only before kickoff.** Sat/Sun pulls list games `Final` or live, and for
  those players `Fantasy Fan Pts` = points SCORED (wk3/4/5 Sunday pulls: 77/149/138
  players). Clean export = latest pull with every Game cell unstarted (`clean_tmpl()`).
- **`*_actual_*` exports: `-` = did not play -> NA, not 0.** Every player (FA included) is
  in the file; a started inactive player scores 0.
- **No export has a started/bench flag.** Opponent starters are not recoverable after the
  fact, only bounded (week 5: 47 of 84 legal lineups lose). Why freezing **both** lineups
  pre-kickoff is load-bearing.
- **Rosters come from the six position exports** (`_qb_`, `_rb_`, `_wr_`, `_te_`, `_k_`,
  `_def_`). `*_actual_*` exports carry owners in `Roster Status` -> all ten rosters rebuild
  cleanly. **No `rosterchanges_*` file is a roster snapshot:** `rosterchanges_league_team`
  disagreed with the frozen week-5 lineup on 3 of 15 slots (mid-transaction, not stale);
  `rosterchanges_injured_reserve.csv` listed 15% of one day's rows as both "On" and "Off"
  IR. Injuries: the `injuries` + `gamedaycalls` exports (skill positions only); defenders ->
  `nflreadr::load_injuries()`.
- **DEF never joins on name — team names change with export vintage.** City in some projection exports
  (`Jacksonville|Jax|6.90`), nickname in others (wk7 projection: `Browns`) and in actuals
  (`Jaguars|Jax|2.00`); one projection file emitted `New York` twice (NYJ, NYG). **Join DEF
  on the `Team` abbrev and `stopifnot()` the map.**
- Position pages and the matchup page disagree by ~0.02 for the same player-week. Pick one
  surface and say which; the **matchup page** is what a lineup decision is made against.
- **A Yahoo injury `O` is a state, not an event.** Diff it against last week's usage before
  reading it as news — a player long out reads identically to one just ruled out.
- **A Yahoo live win probability mid-week is not a forecast** — banked points plus a stale
  projection, most wrong when the opponent's early players spiked. Compute remaining vs
  remaining instead (it inverted the Week 2 read).

### Roster decisions. ADR 0009.

- **Start/sit: read the Yahoo projection and stop.** Best one-week estimate we have: MAE
  4.29 vs 6.71 opportunity-based, 7.32 season ppg (`dev/weekly/proj_benchmark.R`, wk4,
  n 221). Never override it with our numbers.
- **Opportunity / snap analysis has three jobs, start/sit is not one:** rank the wire,
  catch a role change the projection has not absorbed, choose the drop.
- **Need before candidates. Never infer a positional need from a candidate looking good.**
  Add/drop runs in order: (1) roster counts by position + bye week per player, byes as
  `setdiff(all_weeks, weeks_played)` from `load_schedules(2026)`; (2) per bye week, *am I
  actually short a startable body at that slot?* — FLEX absorbs a lot, 4 RBs for 2 RB
  slots is depth, not a hole; (3) only then rank the pool; (4) pick the drop by usage
  trend. Writing "X is your hole" requires the depth + bye tables already on screen
  (2026-09-29: called RB the hole; the real holes were K and TE).
- **The drop ranks like the add: snap share + target trend, never ppg.** ppg embeds the
  efficiency the core principle regresses, so it mis-ranks your own bench both ways
  (2026-10-06: Sutton vs Raymond — the user caught it, not the analysis). Pull
  `load_snap_counts()` before naming any drop. Snaps also catch fresh injuries a base
  projection cannot see (McLaurin snaps 75 -> 58 -> 10).
- **A handoff doc is a prior claim, not a source.** Re-derive from `load_player_stats()`,
  `load_snap_counts()` and the newest `docs/uploads/week_NN_data/` export before acting on
  an add/drop or quoting a number.
- **The decision log beats `_myteam.csv` for who is rostered.** The csv is written at
  freeze time and not rewritten when a decision reverses; the log's `LIVE` / `CANCELLED` /
  `NEW` rows are authoritative. The csv is authoritative only for what was projected.
- **The wire has two phases per week.** After Sunday games every unowned player goes to
  waivers; they clear Wednesday. Before the clear, priority gates everything; after it,
  first-come, priority irrelevant -> **a Thursday/Friday second look is free**. Any
  availability filter must treat `FA` *and* `W (...)` as available (a `^W \(`-only filter
  hid 360 week-4 WRs). A successful claim drops us to the bottom of the rolling list -> at
  low priority, spending it costs ~nothing: stack claims on several targets; contested
  ones mostly fail.
- **A replacement level is only as good as its pool.** A Yahoo FA export's median ppg is
  ~1.5-2.3 for RB/WR/TE (mostly inactive bodies) -> every waiver body shows a fake VOR.
  Rank the wire on opportunity and its week-over-week trend; bar anyone under ~5 opp/g.
- **Log the opponent's lineup pre-kickoff**, not just ours. Makes projection error
  measurable on both sides, and exposes head-to-head structure (our RB and their QB as
  teammates damps the margin).
- **Correlation is not the thing to avoid — paying for it is.** A stack that costs
  projected points to buy shared upside loses; concentration that arrives free while
  *gaining* points is fine. Flag it either way, with a kill condition.

### Method

- Every model outputs a distribution, not a point estimate.
- Validate the config early and fail loudly. A bad `league.json` should not reach a model
  fit.
- **n is tiny. Fit nothing on our own weekly logs.** Power comes from league-wide data (all
  10 rosters, all 32 teams, 2024-25 history).
- **Pre-register.** Kill condition per decision, before kickoff. `predictions.R freeze`
  refuses after kickoff and refuses overwrite; scorers print `WAITING`, never a silent pass.
- **Common random numbers for every delta** — without them +1 pt/wk drowned in MC noise.
  Arm comparisons: paired bootstrap CI over >= 30 seeds, never one frozen seed (ADR 0006).
- **Monotonicity checks catch silent bugs** — "more points cannot lower our odds" caught
  the locale swap above.
- **Validate hand transcription by redundancy** — mirror check + Standings reproduced to
  the cent (`schedule_check.R`). **Verify refactors by output diff** (byte-identical).
- **Docs written in `/caveman` style.** Repo rule. Applies to `PLAN_1.md`, `CONTEXT.md`,
  handoff docs, ADRs, roxygen blocks. Drop articles, filler, hedging. Fragments fine.
  Arrows for causality (X -> Y). Technical terms, code blocks, error strings stay exact.
  Exception per skill: full prose for security warnings, destructive-action confirms,
  ordered multi-step sequences where fragment order risks misread.

---

## Live state

Not kept here — anything that changes weekly rots in this file. Read the newest doc in
`docs/handoff/` (index `docs/handoff/README.md`). Roster truth = decision log rows.

Weekly loop, as practiced — it works, keep it:
1. **Freeze a decision log before kickoff** (`data/weekly/2026_weekNN_decisions.md`) with
   a **pre-registered kill condition** per decision. Record holds too: "tested all 16
   swaps, none help" is a result, and without it the retro cannot tell a considered hold
   from an unconsidered one.
2. Log **both lineups** (`_myteam.csv`, `_opponent.csv`) at freeze-time projections.
3. After Monday, append to `## Retro` — never edit above it. Score each kill condition
   y/n and **separate "decision wrong" from "outcome bad"**; Week 1 proved they differ.
4. `regret = best legal lineup - started` -> `data/weekly/README.md`. It measures the
   projection, not us.

**Lineup deadlines are not a player's own kickoff.** The real deadline for a slot is
`min(kickoff of that player's legal replacements)`. Week 2: Adams locked Monday, but every
WR who could replace him played Sunday 1:00pm, so the call was due 31h earlier than the
lock table said.
