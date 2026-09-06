# ffdraft — Handoff #2: Phase 3 done, decision pending on what's next

**Project**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: 2026-09-04
**Draft**: Tuesday, Sept 8, 2026, 6:00pm ET — **4 days away as of this handoff**
**Previous handoff**: `/tmp/ffdraft-handoff-20260829.md` (Phases 0-2 build details,
two targets/data.table gotchas, decisions log — still valid, not repeated here)

Read in this order: this doc → `CLAUDE.md` → `PLAN_1.md`. `CLAUDE.md`'s league-facts
section is now current (draft date, 10 teams confirmed) — no need to re-derive.

## What's new since the last handoff

- **10 teams confirmed** (was null/unknown). `config/league.json` updated,
  `CLAUDE.md` updated. Sweep-mode scope narrowed from 22 (team×slot) scenarios
  to 10 (slot only) — draft slot is still unknown.
- **Draft date confirmed**: Tue Sept 8, 6pm ET, night before Week 1. In both
  `CLAUDE.md` and `PLAN_1.md`.
- User now has a `football.fantasysports.yahoo.com` account and can see the
  actual league page: **"TKWW2K26 League 5" (ID #1541392)**. Real roster
  slots / PPR value / playoff structure have NOT been pulled from it yet —
  `league.json`/`scoring.json` still hold placeholder values from `PLAN_1.md`'s
  example config. This is a live, unresolved TODO, not forgotten.
- **Phase 3 (VOR draft board) is built and verified working.** See below.

## Phase 3 build (new files)

- `R/10_ingest.R` — added `ingest_ff_rankings()` (FantasyPros ECR/ADP via
  `load_ff_rankings(type="draft")`).
- `R/60_draft_pool.R` — `build_draft_pool()` + `validate_draft_pool()`.
  Filters the rankings dump to `page_type == "redraft-overall"` (NOT
  best-ball/dynasty/IDP — those come mixed together in one API response, ~30
  page_types total). Crosswalks to `dim_player` via FantasyPros' own ID
  (`id` column ↔ `dim_player$fantasypros_id`) — NOT `yahoo_id`, which is NA on
  this page_type despite being populated on some others. DST dropped (out of
  scope, team-level scoring). Result: 479 players.
- `R/75_value.R` — the core design decision this phase: **`build_player_value()`
  ranks players by 2025 points-per-game (under the league's own scoring, not
  generic PPR) × 17, discounted by a 3-year (2023-2025) availability rate.**
  ECR/ADP is used ONLY to define the 2026 draftable universe (in
  `build_draft_pool`), never as a ranking signal — this was an explicit user
  instruction ("I don't care about buzz, that's just commentary noise"; they
  wanted an injury-risk signal instead of ECR blending). `compute_vor()`
  computes dynamic replacement level from `league.json`: QB/K get their own
  replacement level; RB/WR/TE share ONE combined replacement level (pooled
  and ranked together) since FLEX blurs them in a real draft — this is a
  documented v0 approximation, a true assignment-problem solver is Phase 6 (L6),
  out of scope here.
- Wired into `_targets.R` as `draft_pool` → `player_value` → `draft_board`.
- 14 new golden tests in `tests/testthat/test-value.R`, hand-verified VOR math
  on synthetic examples. Full suite: 32/32 passing.

## Real output, verified

Top of the board: Bijan Robinson, Jahmyr Gibbs, James Cook — legitimately elite,
high-availability backs. Injury-risk signal works as intended: Skattebo,
Hampton, Rice, Nabers, Burrow, Daniels all show depressed VOR from low 2025
availability, which was the whole point of rejecting ECR-based ranking.

**Known gap, not a bug**: 90 of 479 draft-pool players (≈19%) have zero 2025
games — mostly 2026 rookies, plus a few (e.g. Travis Hunter) with minimal
offensive usage in their rookie year. These get `has_current_data = FALSE` and
are **excluded from the ranked board entirely**, not silently mis-ranked. On
draft night, if any of these 90 names come up, the board will have nothing to
say about them — worth deciding before the draft whether that's acceptable or
needs a fallback tier.

## New bugs hit and fixed this session (beyond the two in the previous handoff)

1. **`cfg$key <- NULL` deletes the list element in R** — it does not set the
   value to `NULL`, it removes the key. To construct a test fixture with an
   explicit JSON `null` for a key, use `cfg["key"] <- list(NULL)` instead. Bit
   `tests/testthat/test-config.R`'s null-fixture test when `teams` was still
   the real config's null value; had to fix when it stopped being copyable
   from the real file (see next item).
2. **A test that copies the real config file as its fixture breaks when the
   real config's placeholder values get filled in for real.** `test-config.R`
   originally copied the real `league.json` to test null-handling — broke the
   moment `teams` became `10`. Fixed by building a synthetic fixture instead
   of copying the real file. Worth remembering for any other test that reads
   from `config/` directly rather than constructing its own input.
3. **`aggregate()` errors (not empty-result) on a zero-row data frame.**
   `build_player_value()` needed an explicit `nrow() == 0` guard before calling
   `aggregate()`, for the case where no draft-pool player has any games in
   the target season (won't happen in practice yet, but will on a
   fresh/future season with no data).
4. **A loop/branch that runs unconditionally on config-declared categories
   produces spurious warnings when the data doesn't contain any rows in that
   category.** `compute_vor()`'s flex-pool block ran even when the input had
   zero flex-eligible rows (e.g. a QB-only test fixture), hitting
   `min(numeric(0))` → `Inf` with a warning. Fixed by guarding on
   `any(vt$pos %in% flex_positions)`. Watch for this pattern anywhere code
   iterates over config-declared categories rather than categories actually
   present in the data.

## Open decision for next session

Two candidate next steps, not yet chosen:
1. **Phase 3.5** — wrap `draft_board` in a Shiny pick-entry app (already
   decided: Shiny, not a lighter alternative — logged in the previous
   handoff). Needs to capture picks as `(team, player)` for all ~10 coaches,
   not just the user, per `PLAN_1.md`'s Phase 3.5 section.
2. **Pull real Yahoo league settings** — user can now read the actual
   "TKWW2K26 League 5" settings page directly. Would replace the placeholder
   values in `config/league.json` (roster slots, playoff structure) and
   `config/scoring.json` (all scoring values are still generic examples from
   `PLAN_1.md`, not this league's real rules). Since the whole system is
   config-driven, this is a data-entry task, not a code change — but it's
   the highest-leverage remaining unknown before the draft, since scoring.json
   directly determines every VOR ranking on the board.

Given 4 days to draft day, recommend deciding this explicitly with the user
rather than assuming — don't just pick one.

## Suggested skills for the next session

- **`tdd`** — if Phase 3.5 is chosen: the pick-entry state machine (marking a
  player drafted, attributing to a team, re-ranking remaining players) has
  clearly hand-verifiable expected behavior, same pattern that worked cleanly
  for `R/75_value.R`'s VOR tests. Write the re-ranking test before the Shiny
  reactivity.
- **`diagnose`** — if `tar_make()` misbehaves again with an opaque
  targets/data.table interaction, reproduce with a small standalone Rscript
  outside the targets subprocess first (this is what isolated both prior
  bugs), don't guess inside the pipeline.
- **`grill-with-docs`** — before finalizing Phase 3.5's UI shape, worth a
  quick adversarial pass against `PLAN_1.md`'s Phase 3.5 bullet list (tiered
  cheat sheet, re-ranking, one-line plain-English notes) to confirm nothing
  gets skipped under time pressure.
