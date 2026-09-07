# PRD 001 — MC opponent model + survival -> VONA

**Source**: `docs/handoff/ffdraft-handoff-20260906-11.md` Scope items 1 + 2, and its
pre-registered bars. Those are binding. Not restated here. Read them first.

**Executor**: Haiku. Every step below has exact signature, file home, and its own
verification command. Do steps in order. Do not start step N+1 until step N verifies.

**Standing rule**: `dev/dryrun.R` is READ-ONLY for this whole PRD. Do not edit it.
It is the reference the golden test reproduces.

---

## Decisions already made — do not re-open

| decision | value |
|---|---|
| golden test | committed fixture in testthat + full-store verifier in `dev/mc_golden.R` |
| `dev/mc_dryrun.R` defaults | `n_sims = 200`, `tau = c(0,3,6,12)`, `cores = detectCores()-1`, CLI-overridable |
| VONA app surface | column on **Board**, read-only, next to `Yahoo gap` |

---

## New files

| file | holds |
|---|---|
| `R/80_opponent_sim.R` | noise, sampler, `sim_context()`, `simulate_draft()`, `starter_value()`, `paired_bootstrap_ci()` |
| `R/81_vona.R` | `simulate_forward()`, `vona()`, `vona_display()`, `survival_display()` |
| `tests/testthat/helper-opponent-sim.R` | sources `R/*.R` deps, builds fixture ctx |
| `tests/testthat/fixtures/mc_pool.csv` | 48-row committed pool |
| `tests/testthat/fixtures/mc_league.json` | 4-team 6-round league for fixture |
| `tests/testthat/fixtures/dryrun_tau0_fixture.rds` | golden snapshot, step 3 |
| `tests/testthat/test-opponent-sim.R` | steps 1-3 |
| `tests/testthat/test-vona.R` | steps 6-7 |
| `dev/mc_golden.R` | real `_targets` store, tau=0 == `dev/dryrun.R` |
| `dev/mc_dryrun.R` | tau sweep, CRN, paired CIs |
| `dev/vona_gate.R` | bars 1-3 measurement |

Touched: `inst/app/app.R` (step 8 only). Nothing else.

---

# PHASE A — golden test first

Goal: `simulate_draft(tau = 0)` provably identical to `dev/dryrun.R`. Nothing
probabilistic ships until this holds.

## Step 1 — `sim_context()`

`R/80_opponent_sim.R`:

```r
#' Bundle the four board objects dev/dryrun.R builds inline (its lines 14-19).
#' @param draft_board  from targets `draft_board`; has player_key, player, pos,
#'   team, tier, vor, ecr, xrank, value_source.
#' @param draft_fallback from targets `draft_fallback`; no tier, no vor.
#' @return list(pool, scarcity_board, board, fallback). `pool` is
#'   combined_selectable_pool() plus ecr/vor/xrank columns, fallback vor = NA.
sim_context <- function(draft_board, draft_fallback)
```

Body must be byte-equivalent logic to `dev/dryrun.R:14-19`. Copy it. `board` and
`fallback` are `as.data.frame()` of the args.

**Verify**: `dev/mc_golden.R` step-1 block prints
`identical(sim_context(b, f)$pool, <pool built dryrun's way>)` -> `TRUE`.

## Step 2 — noise + sampler

Same file.

```r
#' Gumbel(0,1) noise indexed by (player row, overall pick number).
#'
#' Indexed by pick number, not by draw order, so common random numbers survive
#' scenario divergence: player i at pick n always gets the same shock even when
#' two scenarios have diverged upstream.
#' @return numeric matrix, n_players x n_picks.
sim_noise <- function(n_players, n_picks, seed)

#' One opponent pick under Plackett-Luce.
#'
#' score_i = -xrank_i / tau + noise_i, argmax. tau == 0 -> deterministic
#' argmin(xrank), NA last in original row order -- exactly order(xrank)[1].
#' NA xrank -> score -Inf, so unlisted players are only reachable once every
#' listed player is gone. A 170-pick draft never gets there.
#' @param xrank numeric, may contain NA.
#' @param tau non-negative scalar.
#' @param noise numeric, length(xrank). Ignored when tau == 0.
#' @return single integer index into xrank.
draw_opponent_pick <- function(xrank, tau, noise = NULL)
```

No `exp()` anywhere. Gumbel-max in log space only. Ties in the -Inf group break
to lowest index (`which.max` default) so NA order matches `order()`.

**Verify** — `tests/testthat/test-opponent-sim.R`:
1. `tau = 0` on 200 random xranks with NAs: `draw_opponent_pick(x, 0)` ==
   `order(x)[1]` for 50 random vectors.
2. NA-only vector -> returns `1L`.
3. `tau = 1e-9` with any noise -> same answer as `tau = 0`.
4. `tau = 1e6`, 10 listed players, 20000 draws -> each index chosen within
   `[0.08, 0.12]` share (near-uniform).
5. `sim_noise(5, 4, 7)` twice -> `identical()`. Different seed -> not identical.
6. Player-row noise stability: `sim_noise(...)[3, 9]` unchanged when only the
   set of remaining players changes (i.e. caller indexes the matrix by original
   row id, not by position in `remaining`). Assert this in `simulate_draft()`
   by construction: keep a `row_id` column on `pool`.

`Rscript -e 'testthat::test_file("tests/testthat/test-opponent-sim.R")'` green.

## Step 3 — `simulate_draft()` + the tau=0 golden

```r
#' Full T x R draft. Generalises dev/dryrun.R: opponents sample rather than
#' always taking argmin(xrank). tau = 0 reproduces it exactly.
#'
#' @param ctx from sim_context().
#' @param league_config list; `draft$defer_until_round` is overwritten by `defer`.
#' @param my_slot integer.
#' @param defer named list e.g. list(K = 16, DST = 15, QB = 7).
#' @param tau non-negative scalar. 0 = deterministic.
#' @param noise matrix from sim_noise(), nrow == nrow(ctx$pool),
#'   ncol == teams * rounds. NULL allowed only when tau == 0.
#' @param my_team character, default "JGrahnasaurs".
#' @return list(picks, advice, defer, tau). `picks` columns and types EXACTLY
#'   as dev/dryrun.R:73-77: round, overall, player, pos, team, ecr, vor, xrank,
#'   source. `advice` character vector, same sprintf format.
#' @param my_rule "recommend" (take recommend_picks()[1], today's behaviour) or
#'   "vona" (take argmax vona among the remaining board). Step 11 uses "vona";
#'   everything before it uses the default, so the golden is unaffected.
simulate_draft <- function(ctx, league_config, my_slot, defer,
                           tau = 0, noise = NULL, my_team = "JGrahnasaurs",
                           my_rule = c("recommend", "vona"))
```

Loop body is `dev/dryrun.R:41-85` verbatim, with ONE substitution: the opponent
branch

```r
pick_key <- remaining$player_key[order(remaining$xrank)][1]
```

becomes

```r
idx <- draw_opponent_pick(remaining$xrank, tau, noise[remaining$row_id, n])
pick_key <- remaining$player_key[idx]
```

My-pick branch, `scarcity_report()`, `recommend_picks()`, `explain_scarcity()`,
the bench fallback, the `length(hit) != 1` stop — all unchanged. Still uses a
real `tempfile()` pick log and `append_pick_event()`, so the simulation drives
the same code path the app does. That is the point of the whole harness.

Also move (copy, do not cut) `dev/dryrun.R:93-117` in as:

```r
#' Greedy starter fill -> total starters' Extra pts. Same logic as
#' dev/dryrun.R's local copy; dev/mc_golden.R asserts they agree.
starter_value <- function(picks, league_config)
```

**Fixtures.** `tests/testthat/fixtures/mc_pool.csv`: 48 rows —
8 QB, 14 RB, 14 WR, 6 TE, 3 K, 3 DST. Columns `player_key, player, pos, team,
tier, vor, ecr, xrank, value_source`. Make ~12 rows have `xrank = NA` so the
NA path is exercised. Values hand-written, not sampled — this file is a golden
input and must never change. `mc_league.json`: 4 teams, 6 rounds, starters
QB 1 / RB 1 / WR 1 / TE 1 / FLEX 1 / K 0 / DST 0, flex_eligible RB,WR,TE,
half-PPR scoring block copied from `config/league.json` shape so
`scarcity_report()` accepts it.

**Golden test**:

```r
test_that("tau = 0 reproduces the deterministic draft", {
  ctx <- fixture_ctx()
  got <- simulate_draft(ctx, fixture_league(), my_slot = 2,
                        defer = list(), tau = 0)
  expect_equal(got$picks, readRDS(test_path("fixtures/dryrun_tau0_fixture.rds")))
})
```

Generate the snapshot ONCE, by hand-inspecting the output first. Commit it.
Also assert in the same file that `tau = 0` is noise-invariant:
`simulate_draft(..., tau = 0, noise = sim_noise(48, 24, 1))$picks` equals the
same snapshot.

**Verify**: test file green.

## Step 4 — full-store verifier `dev/mc_golden.R`

The bar the user actually set: reproduce `dev/dryrun.R` exactly, real 764-row pool.

Script does, for each of dryrun's three scenarios:
1. `tar_read()` the real objects, build `ctx <- sim_context(...)`.
2. Run `simulate_draft(ctx, league_config, my_slot = 5, defer = scen, tau = 0)`.
3. Get the reference by `env <- new.env(); capture.output(sys.source("dev/dryrun.R", env))`.
   Sourcing runs dryrun's own three-scenario loop (~3s, all printed — swallow it),
   and leaves `env$run_draft`, `env$starter_value`, `env$pool` defined. Then call
   `ref <- env$run_draft(scen)` for each scenario. Do not edit dryrun.R to make
   this cleaner.
4. `stopifnot(identical(sim$picks, ref$picks), identical(sim$advice, ref$advice))`
5. `stopifnot(all.equal(starter_value(sim$picks, cfg)$total, env$starter_value(ref$picks)$total))`

Prints `GOLDEN OK — 3/3 scenarios identical` or dies.

**Verify**: `Rscript dev/mc_golden.R` prints `GOLDEN OK`. **Phase A gate. Stop
here and report if it fails — do not proceed to Phase B.**

---

# PHASE B — item 1, the sweep

## Step 5 — `paired_bootstrap_ci()`

`R/80_opponent_sim.R`:

```r
#' Paired bootstrap CI on a per-sim difference vector.
#' @param delta numeric, one entry per sim replicate (scenario A total minus B).
#' @param n_boot integer, default 10000.
#' @param conf default 0.95.
#' @return list(mean, lo, hi, p_a_gt_b, n). p_a_gt_b = mean(delta > 0).
paired_bootstrap_ci <- function(delta, n_boot = 10000L, conf = 0.95)
```

**Verify**, in `test-opponent-sim.R`:
- `delta = rep(2, 100)` -> `mean == 2`, `lo == hi == 2`, `p_a_gt_b == 1`.
- `delta = rnorm(2000)` with seed -> CI contains 0, `p_a_gt_b` in `[0.45,0.55]`.

## Step 6 — `dev/mc_dryrun.R`

```
Rscript dev/mc_dryrun.R [--n_sims 200] [--tau 0,3,6,12] [--cores N] [--slot 5]
```

Defaults: `n_sims = 200`, `tau = c(0,3,6,12)`, `cores = max(1, detectCores()-1)`,
`slot = 5`. Parse with `commandArgs(trailingOnly = TRUE)`, no extra deps.

Scenarios: the same three named in `dev/dryrun.R:119-123`. Do not invent others.

**Common random numbers.** One `sim_noise(nrow(pool), teams*rounds, seed = s)`
per replicate `s in 1:n_sims`, REUSED across every scenario and every tau in that
replicate. Never regenerate per scenario.

Parallel over replicates with `parallel::mclapply` (`mc.cores = cores`).
Fork-based, so no export ceremony. On a non-fork platform fall back to serial —
this repo is macOS, do not build a PSOCK path.

Output per tau block:

```
=== tau = 3 (n_sims = 200) ===
scenario                 mean starters   sd
baseline (K16, DST15)           531.2   8.4
QB deferred to rd 7             534.9   9.1
QB deferred to rd 8             533.0   8.8

paired deltas
A vs B                              mean      95% CI        P(A>B)
rd7 - baseline                      +3.7   [+1.1, +6.2]      0.83
rd8 - baseline                      +1.8   [-0.9, +4.4]      0.61   INDISTINGUISHABLE
rd8 - rd7                           -1.9   [-3.8, +0.1]      0.47   INDISTINGUISHABLE
```

Rule, enforced in code not prose: if the CI straddles 0, print
`INDISTINGUISHABLE` and do NOT rank. No "best scenario" line ever printed.

Also write `dev/mc_results.rds` — `list(config, per_sim_totals, ci_table)` — so
the numbers can be re-read without a re-run.

**Verify**: `Rscript dev/mc_dryrun.R --n_sims 4 --tau 0 --cores 1` completes,
and its tau=0 per-sim totals are all identical to each other and equal
`dev/mc_golden.R`'s totals. Then one real run at defaults; record wall time.

---

# PHASE C — item 2, survival + VONA

## Step 7 — `simulate_forward()`

`R/81_vona.R`:

```r
#' Roll the draft forward from the current state to my next turn only.
#'
#' Opponents pick, I do not -- horizon ends the pick before I am on the clock.
#' One pass yields both outputs: survival per player and the positional-best
#' distribution VONA needs.
#'
#' @param ctx from sim_context().
#' @param state from replay_pick_log().
#' @param horizon integer, picks_until_my_turn(state). 0 -> everyone survives.
#' @param tau non-negative scalar.
#' @param n_sims integer, default 1000.
#' @param seed integer, default 1L.
#' @return list(
#'   p_available = data.frame(player_key, p_available),   # every remaining player
#'   pos_best    = data.frame(pos, mean_best_vor, sd_best_vor),
#'   n_sims, horizon, tau, elapsed_sec)
simulate_forward <- function(ctx, state, horizon, tau, n_sims = 1000L, seed = 1L)
```

Implementation notes that matter for the latency bar:
- Work on plain numeric vectors pulled out of `ctx$pool` ONCE, before the loop.
  No data.frame subsetting inside the inner loop.
- Per replicate: copy a `logical` alive mask, draw `horizon` picks, mark dead.
  `horizon` is 9-19, so this is ~19 `which.max` calls on a shrinking score vector.
- Accumulate survival as an integer counter vector, divide at the end.
- `pos_best`: after each replicate, for each of the 6 positions take
  `max(vor[alive & pos == p], na.rm = TRUE)`. Precompute the per-position row
  index vectors outside the loop. `-Inf` if a position is wiped -> record `NA`
  and count it; if any position hits NA in >0 sims, report the count.
- `elapsed_sec` from `system.time()` around the sim loop. Return it. The bar is
  measured, not estimated.

**Verify** — `tests/testthat/test-vona.R`, fixture ctx:
1. `horizon = 0` -> all `p_available == 1`, `pos_best$mean_best_vor` ==
   the actual current per-position max vor.
2. `tau = 0`, `n_sims = 5` -> all replicates identical, so every
   `p_available` is exactly 0 or 1, and exactly `horizon` players have 0.
3. `p_available` sums: `sum(1 - p_available) == horizon` within float tolerance,
   for any tau. (Exactly `horizon` players die per replicate.)
4. Monotone in tau at the top: the argmin-xrank player's `p_available` is
   non-decreasing as tau goes 0 -> 12.
5. Same `seed` twice -> identical output.

## Step 8 — `vona()` + display

```r
#' VONA(X) = vor(X) - E[ vor of best player at pos(X) available at my next turn ].
#' @param board_remaining data.frame with pos, vor.
#' @param pos_best from simulate_forward().
#' @return numeric, length nrow(board_remaining). NA where vor is NA or the
#'   position has no pos_best entry.
vona <- function(board_remaining, pos_best)

#' Board cell for VONA. Plain signed number.
vona_display <- function(v)

#' Board cell for survival. "18%" / "" when NA. Bold red under
#' VONA_LOW_SURVIVAL (= 0.25) with the plain-English tag, mirroring
#' yahoo_gap_display()'s "takes him early" pattern -- a bare "0.18" is not
#' decodable on a 1-minute clock.
survival_display <- function(p)
```

Add `VONA_LOW_SURVIVAL <- 0.25` as a constant beside `YAHOO_EARLY_GAP`.

**Verify** — `test-vona.R`:
- Hand-built `pos_best` and 5-row board -> `vona()` returns exact hand-computed
  values.
- `vona(board, pos_best)` where a pos is missing from `pos_best` -> `NA`, no error.
- `survival_display(c(NA, 0.9, 0.1))` -> `c("", "90%", <html with red>)`.

## Step 9 — latency measurement, before any app wiring

`dev/vona_gate.R`, part 1. On the REAL store, at a mid-draft state
(replay a 40-pick synthetic log), `horizon = picks_until_my_turn(state)`:

```
tau   n_sims   elapsed_sec
0     1000     ...
3     1000     ...
6     1000     ...
12    1000     ...
```

Print `LATENCY PASS` iff every row `< 2.0`. Else `LATENCY FAIL` and the max.

**This is bar 3. If it fails: stop, report, do not do step 10.** Handoff's
instruction on a bar-3 miss is offline-only, cut the app.

## Step 10 — Board column

`inst/app/app.R` only. Pattern-match the shipped `Yahoo gap` wiring
(`app.R:28`, `app.R:289`).

- Recompute inside the Board's `renderTable` reactive, on the CURRENT remaining
  board, after every pick. Unlike `yahoo_gap` this is state-dependent and MUST
  NOT be hoisted to load time.
- Guard: `picks_until_my_turn(state)` returns `NULL` pre-setup -> render `""`
  for both columns, do not call `simulate_forward()`.
- Two new columns after `Yahoo gap`: `VONA` and `Survives`.
- Fix `tau = 6` for the app (sweep midpoint). Named constant `VONA_APP_TAU`,
  one line, so it is changeable without hunting.
- `align` string in the `renderTable` call gains two `r`.
- Extend the Board legend to define both columns in plain English. Per
  `CLAUDE.md`, the reader does not follow football: "VONA — how much you lose
  by waiting. +12 means this player is 12 points better than who you would get
  at this position next turn." / "Survives — chance he is still there when you
  pick again."
- Read-only. `recommend_picks()` untouched. Bar 4.

**Verify**: `bash dev/relaunch.sh --slot 5 --force`, port 7645. Board renders,
columns populate, click through 12 picks, no error, subjectively instant.

## Step 11 — bars 1 and 2

`dev/vona_gate.R`, part 2. For each `tau in {0,3,6,12}`:

- Run a full 17-round `simulate_draft()` twice at that tau with the SAME noise:
  once with `my_rule = "recommend"` (today's behaviour), once with
  `my_rule = "vona"`. The `"vona"` arm calls `simulate_forward()` at my turn
  with `horizon = picks_until_my_turn(state)`, `n_sims = 200` (offline budget,
  not the live one), same tau, and picks `argmax vona` off the remaining board.
  Re-run `Rscript dev/mc_golden.R` after adding `my_rule` -- the default arm
  must still be byte-identical to `dev/dryrun.R`.
- **Bar 1**: count picks differing between arms. Need `>= 3 of 17`.
- **Bar 2**: `starter_value()` total, VONA arm `>=` recommend arm, at EVERY tau.

Print a table plus one of `BARS PASS` / `BAR 1 FAIL — deterministic model good
enough, ship nothing` / `BAR 2 FAIL — reordering costs points, REJECT`.

**Verify**: script runs, prints a verdict. Report the verdict. Do not act on it —
adopting VONA over `recommend_picks()` is a separate decision, not in this PRD.

---

## Out of scope — do not build

- Roster-need weighting for simulated opponents. Named in the handoff as a
  deliberate omission. Leave the note, leave the code alone.
- Fitting `tau`. It is unidentifiable. Sweep only.
- Replacing `R/79_scarcity.R:148`'s worst-case `survives`. Post-draft.
- Any change to `recommend_picks()`, `scarcity_report()`, `dev/dryrun.R`,
  or `docs/review/001-model-critique.md`.

## Done means

1. `Rscript dev/mc_golden.R` -> `GOLDEN OK`.
2. `Rscript -e 'testthat::test_dir("tests/testthat")'` -> all green, count > 475.
3. `dev/mc_dryrun.R` default run finished, `dev/mc_results.rds` written, wall
   time recorded.
4. `dev/vona_gate.R` verdict printed and reported verbatim.
5. Board shows `VONA` + `Survives`, or bar 3 failed and the app is untouched.
