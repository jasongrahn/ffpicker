# ffdraft Handoff #28: draft phase closed. Weekly layer built. Yahoo API tangent proposed.

**Local**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: 2026-09-15 (Mon), after Week 1 completed
**Prior**: `docs/handoff/drafting/ffdraft-handoff-20260911-20-ODUNZE-CONTINGENCY.md` (#27)
**Git**: branch `week1-roster-handoff`, commit **`f4c2298`**, tree clean.
Read that commit message first — full rationale lives there, not repeated here.

**Phase boundary**: all 27 pre-draft handoffs moved -> `docs/handoff/drafting/`.
Draft engine done. Everything from here is in-season.

---

## 1. Week 1 result. Lost.

**101.80 vs Bone Crushers 118.96.** Record 0-1. Box score -> `data/weekly/2026_week01_myteam.csv`.

**Optimal lineup = 121.56. Regret = 19.76.** Optimal beats opponent by 2.60.
Two swaps, nothing else:

| swap | gain |
|---|---|
| Mahomes 22.66 over Stafford 5.10 | **+17.56** |
| W. Robinson 6.30 over Adams 4.10 | +2.20 |

Mahomes alone flips result. Swap was legal — Stafford locked Thu 9/10, Mahomes played Mon 9/14.

### Do not read this as "picker would have helped"

Yahoo projected **Stafford 18.06 vs Mahomes 16.39**. #27 §2 priced that swap at 0.35 pts
and was right to. Picker maximizing projected points makes same wrong call. Ex-ante
correct -> ex-post wrong. Variance, not error.

**One learnable signal: same-game correlation.** Stafford + Adams both LAR vs SF.
Rams lost 7-27. Two starting slots -> one game script -> both the bad ones. Required
picker feature. Everything else week 1 indistinguishable from noise.

Metric + notes -> `data/weekly/README.md`. Regret is the bar. Bench rows are the
counterfactual; without them no test case exists.

---

## 2. Built: in-season layer

New targets. Detail in `f4c2298`, code in `R/41_weekly.R`.

| target | what |
|---|---|
| `fct_player_week_current` | 389 skill rows, live season, + snap share + opponent. Snap match **99.2%** |
| `dim_injury_week` | every player on report, played or not. Wk1: 9 Out, 3 Doubtful, 9 Questionable |

**Scoring validated.** 12/12 roster players match Yahoo box score to the penny,
kicker included. `score_player_week()` + `config/scoring.json` confirmed correct
against real half-PPR output. First independent check of scoring since build.

### Two traps, both now documented in code — do not undo

**Trap 1 — injuries must stay out of the fact table.** Fact table derives from
`player_stats` -> player ruled Out records no stat -> no row to join onto. Measured:
left join retained **3 of 21** skill designations. Lost all 9 Out, all 3 Doubtful,
6 of 9 Questionable. Signal picker exists to use = exactly what stats-derived table
cannot hold. Hence separate `dim_injury_week`. Rationale in
`build_dim_injury_week()` roxygen.

**Trap 2 — targets served stale cache silently.** `ingest_*()` evaluate `season`
inside the function -> targets never sees arg change -> cache from 09-06 kept
reporting max season 2025 after Week 1 played. Only `tar_invalidate()` broke it.
Fixed: `cue = tar_cue(mode = "always")` on the five in-season raw pulls.
`ff_rankings_raw` deliberately excluded (preseason `season = "draft"` snapshot).

Steady-state no-change `tar_make()`: **~24-28s, 18 of 26 skipped**. `dim_player` and
`expected_stat_lines` rebuild every run — `ff_playerids_raw`/`ff_opportunity_raw`
parquet not byte-stable. Values hash identical -> cascade stops -> board and fact
tables skip. Accepted cost. Comment in `_targets.R` says do not "optimize" back.

Tests: **533 pass, 0 fail.**

---

## 3. Next session: Yahoo player API — READ THIS BEFORE STARTING

User asked to stop hand-harvesting Yahoo and build API pulls. Reasonable ask.
**Collides with a hard constraint. Resolve before writing code.**

`CLAUDE.md` -> "Yahoo API is gated. Verified empirically 2026-09-06 — do not
re-investigate." Finding was: `developer.yahoo.com/apps/create` offers only
"OpenID Connect Permissions" and "TW Auction". No Fantasy Sports scope checkbox.
Docs stale. League is private -> no scope -> no read.

**Nothing since has changed that.** No new evidence gathered this session. Constraint
stands as written.

### What would make a re-probe legitimate

Re-probe is cheap (~10 min: load create-app form, read the permissions list) and the
finding is 9 days old. But run it as a **falsification test with a stated bar**, per
repo habit — not as open-ended investigation:

- **Bar**: a Fantasy Sports scope appears on the live create-app form AND an issued
  key returns 200 on `fantasysports.yahooapis.com/fantasy/v2/game/nfl`.
- **Anything less = closed again.** Record result in `CLAUDE.md` either way, with date.
- Do **not** re-open ESPN / Sleeper `search_rank` / `ffscrapr`. All three closed with
  numbers, all three in `CLAUDE.md`. Sleeper `trending/add` remains the one unprobed
  endpoint and is NOT covered by those closures.
- Terms prohibit scraping / reverse-engineering. Not a fallback. Do not propose it.

### If gate still closed — what actually replaces hand-harvesting

Ask user which they want; do not assume:

1. **Nothing.** Start/sit needs only the 15 rostered players + nflreadr. Already
   have both. Yahoo adds nothing to the core loop.
2. **Waiver targets** need "who is unowned in league 1541392". nflreadr cannot know
   this. Genuinely Yahoo-only. One paste per week, same shape as
   `docs/yahoo_fantasy_football_adp.csv`.
3. **Yahoo weekly projections** as baseline to beat. Nice for measurement, not needed
   to build.

User is mid-collection of Yahoo player info for "data arbitrage" — ask what they
pulled before building an ingest for it.

---

## 4. Still open, carried from #26/#27

- **`CLAUDE.md` stale in two places.** `## Current status` says "Nothing built yet.
  Next action is Phase 0" — false, and now badly false. League facts block says
  **17 rounds**; real is **15**. Fix both.
- **`docs/backlog/README.md` line 8 is stale.** Says "No Yahoo ranking data exists in
  the repo." Superseded 2026-09-06 — `docs/yahoo_fantasy_football_adp.csv` exists and
  passed its gate. `CLAUDE.md` already records the supersession; backlog does not.
- Dead, do not revive: VONA as selector, status-column wiring, ESPN/Sleeper
  `search_rank`/`ffscrapr` re-investigation. See `CLAUDE.md`.
- Live but unbuilt: `p_available` / `survival_display()` (`R/81_vona.R`) — draft-only,
  **does not transfer to weekly**. No turn order in waivers. Leave it.

---

## 5. Week 2 mechanics

- `tar_make()` now self-refreshes. No `tar_invalidate()` needed.
- After Week 2 plays: add `data/weekly/2026_week02_myteam.csv`, same columns, bench
  actuals included. Update case table in `data/weekly/README.md`.
- Two backtest weeks is not a sample. Do not fit anything to it.

## 6. Suggested skills

- **`caveman`** — repo doc rule, any doc written
- **`to-prd`** — scope the picker before code; still not done, still the right next step
- **`claude-md-management:revise-claude-md`** — §4 stale blocks
- **`handoff`** / **`session-close`** — close next one. Note: skill defaults to `/tmp`;
  repo `docs/handoff/README.md` overrides — write here.
