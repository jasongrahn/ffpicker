# ffdraft — Handoff #22: draft day. Availability signal shipped, mocks now the open thread

**Local**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: 2026-09-08 — **DRAFT DAY**. Draft 6:00pm ET.
**Prior**: `docs/handoff/ffdraft-handoff-20260907-14-INJURY-SIGNAL-START-HERE.md` (#21)
**Git**: `main`. Working tree DIRTY — see "Uncommitted" below.

**START HERE. Next session receives mock draft #2 results.**

---

## What next session does

User runs mock draft #2 against the rebuilt `data/yahoo_rankings_v2.csv`, pastes
round-by-round results. Job: read them, then answer the standing question —
**what can mock drafts teach us that improves actual picks?**

First, one binary check. Mock #1 had Yahoo autodraft take a DEF at **pick 78**
(our rank then 142) and a K at **83** (our 162). Export now sinks DEF to 252,
K to 284.

- DEF/K land round 13+ -> rank controls slot-filling. Lever exists.
- DEF still ~pick 78 -> Yahoo's need-filling ignores rank entirely. Lever does
  not exist. Record it and stop tuning the file.

---

## Shipped today

### 1. Data refreshed

`tar_invalidate(c(ff_rankings_raw, players_raw, ff_playerids_raw))` then
`tar_make()`. Skipped `player_stats` + `ff_opportunity` on purpose — cover
2015-2025, 2026 season opens 09-09, frozen.

**ECR is 2026-09-04 and that is the ceiling.** dynastyprocess scrapes
FantasyPros **weekly**, not daily (`Automated FP scrape Fri Sep 4` /
`Fri Aug 28`). Re-running gains nothing.
`ingest_ff_rankings()` roxygen still claims "Refreshes daily" —
**wrong, fix it** (`R/10_ingest.R`).

### 2. Availability signal — new, and it matters

Board had **no injury/roster status at all**. VOR is built from historical
opportunity, so an unavailable player keeps full value.

Two sources, unioned, Yahoo wins ties:

| Source | Coverage | Latency |
|---|---|---|
| `players.parquet$status` (nflreadr) | 170/170 of top 170 | lags >= 1 day |
| `docs/uploads/{injured_reserve,active_inactive}_list.csv` | narrow window | same-day |

Caught, all inside draftable range:

```
#20  Josh Jacobs        RB GB   EXE (exempt list)   ecr 148   <- nflreadr
#44  Zach Charbonnet    RB SEA  PUP                 ecr 156   <- nflreadr
#50  TreVeyon Henderson RB NE   IR 09-08            ecr  71   <- YAHOO ONLY
#168 Darius Slayton     WR NYG  Deactivated                   <- YAHOO ONLY
#181 AJ Barner          TE SEA  IR 09-08                      <- YAHOO ONLY
```

nflreadr had Henderson as `ACT` on the day he went to IR. **Yahoo roster pages
beat nflreadr by a day. Re-pull them before any future draft.**

Mock #1 proved the cost: autodraft took Jacobs R10 and Charbonnet R13 straight
off our list. Two dead bench spots of six.

### 3. Yahoo export rebuilt — `dev/rebuild_yahoo_export.R`

Re-runnable. Reads `draft_board`, writes `data/yahoo_rankings_v2.csv` (300 rows)
+ `data/inactive_do_not_draft.csv`.

Does: adopt Yahoo team codes -> drop players Yahoo does not know -> drop 129
unavailable -> **sink DEF (252-283) and K (284-300) below all skill** -> re-rank.

**Trap, hit once already:** trim skill FIRST, then append K/DEF. Capping the
combined frame at 300 truncated both off the end. Both are mandatory starters.

### 4. Name sources consolidated

`docs/yahoo-player-names.txt` had been **deleted in `e634f12`** and never
restored. Without it, alignment was 7/154 on top-170 skill. Restored from
`e634f12^` -> **154/154**.

All six files now in `docs/uploads/`; `YAHOO_NAME_SOURCES`
(`R/95_export.R:7`) repointed. Added `docs/uploads/def.csv` (32 DEF) — the
`yahoo_defense_name()` rule alone covered only 25, and the 7 misses were the
only export rows with no Yahoo name source. Rows with no source now **0**.

---

## Yahoo import — reopened, partly

#14 claimed the thread closed at 508/510. **Does not reproduce.**

| File | Rows | Imported |
|---|---|---|
| v1 (today) | 764 | 292 |
| v2 pre-availability | 300 | 255 |

292 is **not** a cap — just the match count. Rate 38% -> 85% came from filling
56 blank teams and correcting 19 team codes (`JAC`->`JAX`, `LA`->`LAR`).

**Unexplained: Troy Franklin, rank 59.** On Yahoo's XRank board, name/team/pos
(`DEN`/`Den`/`WR`) all match, still rejected. Ruled out: naming, team column,
unknown-player, row-count cap.

Only live lead: **Darius Slayton was deactivated 09-07 and was a named
rejection.** Yahoo may refuse ranking rows for deactivated players. Untested.
Cheap test = 5-row CSV of named failures at ranks 1-5; if they match there it is
rank-position dependent, not player dependent.

---

## Mock draft #1 — what it gave us

Slot 3, 15 rounds, 150 picks. Full results in conversation, not re-pasted.

**Yahoo autodraft follows the uploaded list.** Every skill pick was the top
remaining name on it. Correlation our-rank vs overall pick **0.581**; deviations
were Yahoo slot-filling, not bad ranks.

**Autodraft cost ~5 of 15 picks**: DEF at 78 and K at 83 (both ~6 rounds early),
a 2nd QB (Mahomes R11), a 2nd DEF (R15 — violates `max_at_position DST: 1`),
plus Jacobs. Uploaded list is disconnect insurance, **not** a strategy.

### Board vs market, by position

Spearman against actual pick order, n=138 matched:

| Pos | our VOR rank | ECR |
|---|---|---|
| RB | +0.68 | **+0.97** |
| WR | +0.66 | **+0.95** |
| TE | +0.36 | **+0.91** |
| QB | +0.45 | **+0.80** |

**QB is the worst column on the board.** Stafford our #30 / ecr 106 / went 58.
Lamar Jackson our #166 / ecr 32 / went 44. Burrow our #273 / ecr 45 / went 68.
Not an edge — a miss. Root cause not diagnosed.

**Caveat, do not skip it.** Mock rooms are autodraft-heavy, so mock order *is*
consensus ranking. ECR predicting it is partly tautological. Proves ECR predicts
**when a player goes**, NOT that ECR predicts points. Divergence is supposed to
be the edge. Distinguishing real edge from VOR bug is the open work.

---

## The standing question: what can mocks teach us

Candidates, roughly by value:

1. **Empirical Yahoo ADP.** CLAUDE.md's named blind spot — `player_owned_yahoo`
   is 100% NA. Mocks give behavioral draft position, not just XRank. N mocks ->
   mean + variance per player.
2. **Feed `p_available`.** `simulate_forward()` / `survival_display()`
   (`R/81_vona.R`) are built and **unwired** — the one survivor of the closed
   VONA thread (#21). Mocks are the natural validation set for
   "P(available at your next pick)". Strongest tie-in to existing code.
3. **Position-run structure.** Mock #1: WR run R5, QB/TE run R12, K/DEF R14-15.
   Runs are what makes slot-aware advice actionable.
4. **Autodraft override model.** When does Yahoo ignore our rank to fill a slot?
   Mock #2's DEF timing is the first datapoint.
5. **Separate VOR edge from VOR bug.** Where board and ECR disagree 100+, did
   waiting actually work? Needs several mocks.

**Sampling reality:** 1 mock = 1 draw. #20 already established single-seed
results here are underpowered (delta sd 36-43 pts). Do not conclude from one
mock. Pre-register a bar before shipping anything into the app.

**Bias to state:** mock rooms lean autodraft; real league is 10 casual company
drafters. Those may be closer to each other than a sharp room would be — that
makes mock ADP *more* useful here than usual, but it is an assumption, not a
finding.

---

## App state

- Running: `Rscript -e 'shiny::runApp("inst/app", port=4321, ...)'`. Stale
  instance may linger on **7645** — kill it.
- Reads `tar_read(draft_board)` at `inst/app/app.R:16`, so a pipeline-level
  board change reaches the app with no app.R edit — needs `tar_make()` + restart.
- **Status column NOT wired.** Offered twice, user never said go. App still shows
  Josh Jacobs #20 and TreVeyon Henderson #50 unflagged. Paper card used instead.
  If wiring it: **do not remove inactives from `draft_board`** — opponents draft
  them and they must stay searchable via `combined_selectable_pool()` or picks
  cannot be recorded. Flag, never filter.
- `data/pick_log.jsonl` cleared on request. Backup:
  `dev/pick_log_archive/pick_log_20260908-1621.jsonl`. Held
  `my_slot: 7` — **placeholder, not real.** Real slot came at t-30.
- `my_slot` stays `null` in `config/league.json` by design — captured in the log
  at session start (`R/76_pick_log.R:69`).

## League

10 teams confirmed, 0 open. User = **JGrahnasaurs**. Nine opponents named in
conversation. User is **not** the co-manager of "Jason's Jazzy Team" — opponent
model's nine-independent-drafters assumption holds.

---

## Uncommitted

Nothing committed today. Working tree carries:

- `R/95_export.R` — `YAHOO_NAME_SOURCES` repointed to `docs/uploads/`, `def.csv`
  added, comment corrected
- `dev/rebuild_yahoo_export.R` — new
- `docs/uploads/` — six name files (5 moved by user, `yahoo-player-names.txt`
  restored from `e634f12^` and moved)
- `data/yahoo_rankings_v2.csv`, `data/inactive_do_not_draft.csv` — new
- `dev/pick_log_archive/` — cleared log backup

**Tests not run this session.** Run before committing — `R/95_export.R` changed
and 443 tests were green at #14.

---

## Do not redo

- Yahoo API — gated, verified 2026-09-06 (CLAUDE.md)
- `ffscrapr` / `espn-api` / ESPN MCP — league-scoped, no cross-league ADP
- Sleeper `search_rank` — real signal, wrong region (#16)
- VONA as pick selector — all three framings closed (#19, #20, #21)
- ECR freshness — weekly upstream, 09-04 is the ceiling
- Import cause: naming, team column, unknown-player, row-count cap — all dead

## Suggested skills

- **`caveman`** — repo doc rule, applies to any doc this session writes
- **`handoff`** — close the next session with one; this is #22
- **`to-prd`** — if mock-derived ADP or `p_available` graduates to a build.
  Repo culture is pre-registered bars before shipping (#19, #20)
- **`tdd`** — `dev/rebuild_yahoo_export.R` has no tests; so does any board change
- **`session-close`** — working tree is dirty and untested

## First actions

1. Read mock #2 results. Answer the DEF/K binary above.
2. `git status` — decide what to commit. Run tests first.
3. If draft already happened: ask how it went, then pivot. The in-season
   weekly start/sit picker (#21) is the next project and mock work is
   **draft-only** — does not transfer, no turn order in waivers.
