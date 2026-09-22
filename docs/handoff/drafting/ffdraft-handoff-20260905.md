# ffdraft — Handoff #4: Phase 3.5 UI shape fully resolved via `grill-with-docs`

**Project**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: 2026-09-05
**Draft**: Tuesday, Sept 8, 2026, 6:00pm ET — **3 days away at handoff**
**Previous handoff**: `/tmp/ffdraft-handoff-20260904-2.md` (real Yahoo settings applied,
decided Phase 3.5 is next). That doc's own previous-handoff chain (`-20260904.md`,
`-20260829.md`) is still valid background but not re-summarized here.

Read in this order: this doc → `CONTEXT.md` (new this session) →
`docs/adr/0001-event-sourced-pick-log.md` (new this session) → `PLAN_1.md`'s Phase 3.5
section (its "Resolved via `grill-with-docs`" addendum has the full decision list, not
repeated in this doc) → `CLAUDE.md` (one line changed, see below).

## What happened this session

No code was written. This was a `grill-with-docs` design-review pass (run on Opus, at
user's request — good call for adversarial/high-reasoning review work) over Phase 3.5's
UI shape before implementation starts. 15 design questions were asked and resolved
one-by-one; nothing is still open. Full decision list lives in `PLAN_1.md`'s Phase 3.5
section (search for "Resolved via `grill-with-docs`, 2026-09-05") — read it there, not
here, to avoid drift between two copies of the same list.

**New project artifacts**:
- `CONTEXT.md` (repo root, did not exist before) — domain glossary. Defines **Pick**,
  **Pick Log**, **Draft Pool** (every FantasyPros-ranked player, has an ECR), **Draft
  Board** (subset with real production data, VOR-ranked), **Roster** (derived by
  replaying the Pick Log, never stored directly). The Draft Pool vs. Draft Board
  distinction matters: "no VOR" (rookies, `has_current_data = FALSE` in `R/75_value.R`)
  is not the same as "no data" — those players still have an ECR and will show in a
  separate fallback section, not disappear.
- `docs/adr/0001-event-sourced-pick-log.md` — why the Pick Log is an append-only
  `.jsonl` event stream (`pick_made`/`pick_corrected`/`draft_started`), not a mutable
  picks table. Short version: supports one-undo-of-last-pick without destroying history,
  and a crash mid-write only risks the single in-flight line, not file corruption.

**Docs edited**:
- `CLAUDE.md` — "Assume near-zero football knowledge" softened to "Assume casual, not
  deep, football knowledge" (user corrected this: they know some things, are
  semi-familiar with positions, just don't actively follow the sport — the app still
  must never force outside research, that constraint is unchanged).
- `PLAN_1.md` — Phase 3.5 section got the full resolved-decisions addendum described
  above.

## Team name

User renamed their Yahoo team to **JGrahnasaurs** this session (saved to persistent
memory already, not just this doc). Phase 3.5's session-start setup screen should
pre-fill this as "your team," while the other 9 opponent team names stay lazy-created
(placeholder, renamed on each team's first pick) since those aren't known until Yahoo's
draft-order reveal Tuesday.

## Nothing was implemented yet

`inst/app/` does not exist. `R/` still only has files through `75_value.R` (VOR board,
Phase 3, previously built and tested). The next session is pure implementation of
Phase 3.5 against the now-fully-specified design — no more open design questions to
resolve first.

## Immediate next step (near-certain)

Start with **`tdd`** on the Pick Log replay logic — the core state machine underneath
everything else in Phase 3.5 (append a `pick_made`/`pick_corrected` event → derive
current Roster per team → derive remaining Draft Pool → recompute VOR/tiers on it). This
is hand-verifiable on a small synthetic event log the same way `R/75_value.R`'s VOR tests
and `R/30_scoring.R`'s golden tests were — write that test before wiring any Shiny
reactivity, per the pattern that's worked cleanly twice already in this project.

Concretely, that likely means a new `R/8x_pick_log.R` (numbering TBD — next after
`75_value.R`, so `76_` or `80_`) with something like:
- `append_pick_event(log_path, event)` — writes one `.jsonl` line
- `replay_pick_log(log_path)` — returns current per-team Roster + set of drafted
  `player_key`s
- Recompute wiring: drafted players excluded from `compute_vor()`'s input before
  re-ranking (function already exists in `R/75_value.R`, doesn't need to change — just
  needs its `value_table` input filtered by the log's drafted set first)

After that state machine is tested, build `inst/app/` (Shiny) around it: session-start
setup (your team name + `my_slot`), Board pane (VOR-tiered + ECR-fallback section,
`reactable`), click-to-pick and search-to-pick entry, undo-last button, picks-until-your-
turn readout, and — separately, only once, before draft day — the static pre-draft PDF
export of the frozen Board.

## Suggested skills next session

- **`tdd`** — as above, for the Pick Log replay logic specifically. This is the one
  piece of Phase 3.5 with genuinely hand-verifiable expected output; write it first.
- **`diagnose`** — if `tar_make()` or the new Shiny app misbehaves in a way that isn't
  obviously the reactive logic itself, reproduce in a small standalone Rscript outside
  both the `targets` subprocess and the Shiny reactive graph before guessing. This exact
  approach isolated two separate data.table/targets bugs in earlier sessions (see
  `-20260829.md`).
- Do **not** re-run `grill-with-docs` on the same Phase 3.5 UI questions — they're
  closed. If a genuinely new design ambiguity surfaces during implementation (not one of
  the 15 already listed in `PLAN_1.md`), it's fair game, but check that list first.

## Time check

3 days to draft (Tue Sept 8, 6pm ET). Phase 3.5 is the last thing that needs to exist
before then — Phase 3.75/4+ are explicitly not urgent per `PLAN_1.md`. If implementation
runs long, the fallback is manual pick tracking on paper/Yahoo's own draft log; the app
is a convenience layer, not a hard dependency for the draft to happen.
