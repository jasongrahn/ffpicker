# ffdraft — Handoff: Phases 0-2 done, starting Phase 3

**Project**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: 2026-08-29
**Next session focus**: Phase 3 — VOR draft board

Read `CLAUDE.md` and `PLAN_1.md` in the repo root first. They hold full league
context, conventions, and the phased plan — this doc does not repeat them,
only what they're missing or what's gone stale.

## Known gap in the source-of-truth files

`CLAUDE.md`'s "Current status" section still says **"Nothing built yet."**
That's now false — Phases 0, 1, and 2 are complete and verified. Whoever picks
this up should probably correct that line once Phase 3 lands, so the repo's
own docs don't contradict its state.

## What's built (Phases 0-2), not described in PLAN_1.md at implementation level

- `config/league.json`, `config/scoring.json` + JSON Schemas in
  `config/schema/`. `league.json` has `teams`/`my_slot` as `null` —
  intentional (Pete hasn't set the draft), not a bug. `scoring.json` covers
  passing/rushing/receiving/misc/kicking, all placeholder values pending
  Pete's real Yahoo settings.
- `R/00_config.R` — `load_config(name)`: loads + validates against schema,
  fails loudly (`stop()`) on violation. Tested in `tests/testthat/test-config.R`.
- `R/10_ingest.R` — `ingest_player_stats()`, `ingest_ff_playerids()`,
  `ingest_players()`: pull nflverse data to `data/raw/*.parquet`.
- `R/20_stage.R` — `build_dim_player()` (crosswalk via `load_ff_playerids()`
  joined to `load_players()` on `gsis_id`, surrogate key `player_key`, never
  joined on name) and `build_fct_player_week()` (weekly stats 2015-2025,
  filtered to QB/RB/WR/TE/K). Both have `pointblank` validators
  (`validate_dim_player`, `validate_fct_player_week`) that fail loudly.
- `R/30_scoring.R` — `score_player_week(stats, scoring)`: pure, vectorized,
  stat line × scoring config → fantasy points. Golden-tested (9 hand-computed
  cases) in `tests/testthat/test-scoring.R`. Sanity-checked against real data:
  top-scoring player-weeks 2015-2025 are real, known performances (e.g.
  Kamara's 6-TD game, 2020 wk16).
- `_targets.R` wires all of the above. `renv.lock` is in sync
  (`renv::status()` clean). Installed: nflreadr, jsonlite, jsonvalidate,
  duckdb, DBI, targets, arrow, pointblank, testthat, shiny, bslib, reactable.

## DST scoring is explicitly out of scope so far

Yahoo scores defense/special-teams at the **team** level (points allowed,
sacks, turnovers), not from individual player rows. `fct_player_week` is
filtered to QB/RB/WR/TE/K only — DST needs a separate team-level data source
and hasn't been started. Don't assume it's covered.

## Bugs hit and fixed this session (useful if similar symptoms recur)

1. **`data.table` class-dispatch trap**: `arrow::read_parquet()` round-trips
   preserve a stale `data.table` class tag from the original nflverse objects.
   When the `data.table` package is *attached* (it's in `tar_option_set`'s
   `packages` list), `[.data.table` dispatch silently hijacks plain
   `df[, cols]`-style subsetting that works fine in an interactive session
   without `data.table` attached. Fix: wrap freshly-read parquet objects in
   `as.data.frame()` at the top of any function that will run inside the
   `targets` pipeline.
2. **`targets` dependency blindness on config files**: `scoring_config` /
   `league_config` targets called `load_config()` with a hardcoded path
   instead of taking the corresponding `*_config_file` target as an argument.
   Editing `scoring.json` silently didn't invalidate the cached config because
   `targets` had no DAG edge to know the file changed. Fixed by threading
   `config_dir = dirname(scoring_config_file)` through. Watch for this pattern
   anywhere a target reads a file path that isn't itself a declared target
   input.
3. **`load_ff_rankings(type="draft")` returns mixed `page_type`s** in one call
   (standard, best-ball, DST-only, etc., ~5,500 rows) — must filter to the
   right slice before use, not consumed as-is anywhere yet.

## Decisions made this session not written into PLAN_1.md/CLAUDE.md

- Phase 3.5's pick-entry UI will be built in **Shiny** (not a lighter
  console-based alternative), so it's a stripped-down version of the eventual
  Phase 7 app rather than throwaway work. Phase 3's VOR board output should be
  shaped so a Shiny `reactable` can consume it directly later — but the app
  itself is not part of Phase 3.
- Phase 3.5 must capture picks as **(team, player)**, not just "player gone,"
  since Phase 6's opponent-need model (`L8`) requires per-team roster state to
  compute positional need live. This was added to `PLAN_1.md` already (see
  Phase 3.5 section) — flagging here only because it's easy to under-build if
  skimming.
- Considered a "Claude Design" MCP (`DesignSync`) for UI styling — concluded
  it's built for HTML/CSS component-system syncing, not native to Shiny/`bslib`
  theming, so at most useful as an external style-reference step later, not
  for Phase 3 or Phase 3.5.

## Phase 3 task itself

Already fully scoped in `PLAN_1.md` under "Phase 3 — Draft board v0": ECR +
ADP + your scoring → VOR board with dynamic replacement level. The carry-over
prompt for starting this (see below) has the concrete step list; not repeated
here.

## Suggested skills for the next session

- **`diagnose`** — if `tar_make()` errors again with an opaque data.table/
  targets interaction, don't re-derive from scratch; this skill's
  reproduce→minimise→hypothesise loop is exactly how both bugs above got
  isolated (small standalone Rscript reproductions outside the `targets`
  subprocess).
- **`tdd`** — Phase 3's VOR formula has hand-verifiable expected output on a
  small synthetic example (like the scoring golden tests did); write that test
  first, the same pattern that worked cleanly for `R/30_scoring.R`.
- **`grill-with-docs`** — before committing to a specific VOR/replacement-level
  formula, worth a quick adversarial pass against `PLAN_1.md`'s L7 description
  to make sure the sweep-mode parameterization (10/12 teams × every slot) is
  actually threaded through correctly rather than assumed fixed.
