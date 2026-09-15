# ffdraft — Handoff #5: Pick Log + tiering + minimal pick-entry loop built and verified live

**Project**: `/Users/jasongrahn/R-projects/ffootballer` (not a git repo — no commits/diffs to
reference; everything below is a plain file-path reference)
**Date**: 2026-09-05
**Draft**: Tuesday, Sept 8, 2026, 6:00pm ET — **3 days away**
**Previous handoff**: `/tmp/ffdraft-handoff-20260905.md` (Handoff #4 — Phase 3.5 design fully
resolved via `grill-with-docs`, no code written yet at that point)

Read in order: this doc → `PLAN_1.md`'s Phase 3.5 section (design spec, unchanged since
Handoff #4) → `CONTEXT.md` (Pick / Pick Log / Draft Pool / Draft Board vocabulary) →
`docs/adr/0001-event-sourced-pick-log.md` (why the log is append-only .jsonl).

## What happened this session

First implementation session for Phase 3.5. Used `tdd` skill throughout (one behavior at a
time, RED confirmed before every GREEN). All work is uncommitted (no git repo).

**New/changed files**:
- `R/76_pick_log.R` — new. `append_pick_event(log_path, event)` appends one JSON line.
  `replay_pick_log(log_path)` replays `draft_started` / `pick_made` / `pick_corrected` events
  into `list(rosters, drafted_players)`, keyed by draft slot so a `pick_corrected` naturally
  overwrites/undoes the matching `pick_made` — no separate undo-stack logic needed.
  `remaining_draft_pool(draft_pool, pick_log_state)` filters a pool/board down to undrafted
  players.
- `R/75_value.R` — added `assign_tiers(vor_table, gap_multiplier = 1)`. Tiers are gap-based,
  not fixed-size: within each position, sorts by VOR descending and starts a new tier wherever
  the drop to the next player exceeds `gap_multiplier × sd(that position's VOR)`. This was a
  user decision this session (asked via AskUserQuestion: relative-to-position-spread beat a
  flat VOR gap or a fixed rank cut, since RB/WR/QB/K all sit on different VOR scales).
- `_targets.R` — `draft_board` target now pipes through `assign_tiers()`, not just
  `compute_vor()`.
- `inst/app/app.R` — new. Minimal Shiny pick-entry loop per explicit user scope choice (not
  the full session-start-screen/undo-button/readout skeleton — that's still ahead): team text
  input + player selectize (searches full `draft_board`) + "Make Pick" button → appends a
  `pick_made` event → board `reactable`-free `tableOutput` re-renders via
  `remaining_draft_pool()` + tier/VOR sort. Root-path resolution note: since
  `shiny::runApp()` changes the working directory to the app's own directory for the
  duration of the run, `app.R` derives the project root as two levels up from `getwd()`
  rather than assuming the launch-time cwd — no new package dependency needed for this.
- `tests/testthat/test-pick_log.R` — new, 6 tests (single pick, multi-team isolation, undo,
  drafted-players set, remaining-pool filtering).
- `tests/testthat/test-value.R` — +1 test for `assign_tiers`.
- Full suite: **40/40 passing** (`Rscript -e "library(testthat); test_dir('tests/testthat')"`).

## Bug found and fixed during live verification

Browser-extension tooling wasn't connected this session, so the app was driven headlessly via
a one-off `chromote` script (installed fresh this session — not yet a project dependency,
was only used as a verification tool, not wired into the app or test suite). First real run
threw `Error in order: argument 1 is not a vector` on the board render. Root cause:
`_targets.R` had been edited to add `assign_tiers()`, but `tar_make()` was never re-run, so
`tar_read(draft_board)` was serving a **stale cached target** without a `tier` column. Fixed
by running `targets::tar_make(draft_board)`. **Lesson for next session: any `_targets.R` or
upstream `R/*.R` edit needs a `tar_make()` before the app (or anything using `tar_read()`)
will see it** — this bit us once already, watch for it again after any pipeline edit.

After the fix, re-verified live: picked "Jason Myers" (K) through the actual running app,
confirmed `data/pick_log.jsonl` got the `pick_made` event and the player was excluded from
the re-rendered board.

## Cleanup needed next session (small, do first)

- `data/pick_log.jsonl` currently holds this session's **test picks** (Jason Myers logged
  twice — one from an initial verification run before a restart, one after). Delete this
  file before real draft day, and probably before doing more dev work, so it doesn't get
  mistaken for real draft state: `rm data/pick_log.jsonl`.
- No `.gitignore` exists yet and the project isn't even a git repo yet. Worth deciding this
  session or next: if `data/pick_log.jsonl` is meant to hold the *real* live draft log
  eventually, it should not be committed if/when this becomes a git repo (roster identity is
  session-specific, and users will regenerate it each draft).

## Nothing else changed

`R/` numbering still stops at `76_` (this session's addition) — no `77_`+ files. Rookie
fallback section (below) hasn't started. Session-start setup screen, undo button, and
picks-until-your-turn readout — all still explicitly future work per the ordering the user
gave this session (item 2 was scoped down to "minimal pick-entry loop" only, by explicit
choice via AskUserQuestion).

## Immediate next step (near-certain — user already queued this order: 1, 2, then 3)

Item 3, the last of the three: **wire the no-current-data (mostly-rookie) fallback section**
into the Board. Per `PLAN_1.md` Phase 3.5 (search "un-tiered, ECR-sorted fallback section"):
players with an ECR but `has_current_data = FALSE` (see `R/75_value.R`'s
`build_player_value()`) must NOT be silently dropped by `compute_vor()`'s filtering — they
need to surface in a separate, un-tiered, ECR-sorted section below the main VOR Board, since
"no VOR" and "no data" are different things (this exact distinction is in `CONTEXT.md`'s
Draft Pool / Draft Board definitions — read those two entries again before starting).

Concretely, likely means:
- A new function (maybe in `R/75_value.R` alongside `assign_tiers`, maybe in a new
  `R/77_*.R`) that takes the *full* `draft_pool` and `player_value` table, and returns
  the players present in `draft_pool` but absent from (or `has_current_data = FALSE` in)
  the tiered `draft_board` — sorted by `ecr` ascending, no `tier` column.
- TDD it the same way as `assign_tiers` and the Pick Log: synthetic fixture with a couple of
  `has_current_data = TRUE` players and one rookie with `has_current_data = FALSE`, confirm
  the rookie lands in the fallback set and not the main one.
- Then wire it into `inst/app/app.R` as a second `tableOutput` below the existing board,
  filtered through `remaining_draft_pool()` the same way the main board is (a fallback-section
  player can still get drafted and needs to disappear too).
- Re-verify live the same way this session did (chromote headless driver script is gone —
  it was a one-off in `/tmp/drive_app.R`, not saved into the repo — rebuild a similar script,
  or ask the user to check in their own browser if the extension is connected by then).

## Suggested skills next session

- **`tdd`** — for the fallback-section function, same pattern as `assign_tiers` and
  `76_pick_log.R`: one behavior at a time, confirm RED before GREEN, small synthetic
  fixtures.
- **`run`** — to launch `inst/app/app.R` again and verify item 3 live in a browser before
  calling it done, per this project's CLAUDE.md UI-testing rule. Check first whether the
  `claude-in-chrome` browser extension is connected this time (it wasn't last session) —
  if so, use it directly instead of standing up a throwaway `chromote` script again.
- Do **not** re-run `grill-with-docs` — Phase 3.5's design questions are all closed (see
  Handoff #4). Only open a new design question if something genuinely new surfaces that
  isn't already answered in `PLAN_1.md`'s Phase 3.5 addendum.

## Time check

**3 days to draft** (Tue Sept 8, 6pm ET). Two of three Phase 3.5 backend pieces are now done
and verified (Pick Log + gap-based tiering); the pick-entry loop runs end-to-end. What's left
before Phase 3.5 is complete: the rookie fallback section (item 3, next), then the remaining
UI polish PLAN_1.md calls for (session-start setup screen, undo button, picks-until-your-turn
readout, static pre-draft PDF export) — none of which are started. If time runs out, the
fallback is still manual pick tracking on paper or Yahoo's own draft log; the app is a
convenience layer, not a hard dependency for the draft to happen.
