# ffdraft — Handoff #3: Real Yahoo settings applied, ready for Phase 3.5

**Project**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: 2026-09-04
**Draft**: Tuesday, Sept 8, 2026, 6:00pm ET — **4 days away as of this handoff**
**Previous handoffs**: `/tmp/ffdraft-handoff-20260904.md` (Phase 3 build, decision
between Phase 3.5 vs. pulling real Yahoo settings), `/tmp/ffdraft-handoff-20260829.md`
(Phases 0-2 build details, data.table/targets gotchas). Both still valid, not repeated
here.

Read in this order: this doc → `CLAUDE.md` → `PLAN_1.md`. Both source-of-truth files are
now current (real league settings, no stale placeholder sections) — no need to re-derive
anything from them.

## Decision made this session

Handoff #2 ended with an open choice: build Phase 3.5 (Shiny pick-entry app) or pull real
Yahoo league settings first. User chose **pull real settings** — correct call, since the
VOR board was ranking on placeholder scoring/roster rules that turned out to be wrong in
ways that materially change the board (see below).

## What changed: real Yahoo settings now in config

User pasted the full settings + scoring tables from the live "TKWW2K26 League 5" page
(ID #1541392) — browser extension wasn't connected, so this was manual paste, not a live
page read. Applied to `config/league.json` and `config/scoring.json`, both JSON-Schema
validated. Full real values are documented in `CLAUDE.md`'s "League facts" section — not
repeated here, but the deltas from the old placeholder config that actually matter:

- **WR starters: 2, not 3.** The third receiver-eligible spot is FLEX, not a dedicated
  WR slot. This changes the replacement-level pool composition.
- **Playoffs: 4 teams, weeks 16-17** (not 6 teams / weeks 15-17). Regular season is now
  weeks 1-15, not 1-14.
- **INT: -1, not -2.** No first-down rushing bonus, no 300-yard passing bonus — Yahoo
  doesn't score either.
- Roster now includes `ir: 2` (added as a new optional field to
  `config/schema/league.schema.json`); draft rounds corrected 16 → 17 (9 starters + 6
  bench + 2 IR).
- Added a `dst` block to `config/scoring.json` (sack/INT/fumble-recovery/points-allowed
  tiers, etc.) and its schema. **Not yet consumed** by `score_player_week()` in
  `R/30_scoring.R` — that function is still per-player only and DST is team-level. This
  was already a known, documented gap (see handoff #1); the real scoring values are now
  captured in config so nothing is lost whenever DST modeling gets built.

## Bug found and fixed this session

`tests/testthat/test-scoring.R` was loading the **real** `config/scoring.json` directly
instead of a synthetic fixture. When the real config's passing bonus and rushing
first-down bonus were removed (because Yahoo doesn't score them), 3 golden tests broke.
This is the exact same bug pattern flagged in handoff #2, item 2 (test-config.R had done
the same thing with `league.json`). Fixed by giving `test-scoring.R` its own synthetic
scoring fixture that deliberately keeps the bonus/first_down fields, so it still exercises
those code paths in `score_player_week()` independent of what the real league does.

**Pattern to keep watching**: any test that calls `load_config()` on the real
`config/*.json` files rather than building its own fixture will break the next time the
real config changes for a legitimate reason. Worth a `grep -rl 'config/scoring.json\|config/league.json' tests/` sweep if this happens a third time.

## Verification done

- `load_config("league")` and `load_config("scoring")` both parse and validate cleanly
  against the updated schemas (checked via a standalone Rscript, not `devtools::load_all`
  — **`devtools` is not installed in this project's renv library**, use
  `for (f in list.files("R", pattern="[.]R$", full.names=TRUE)) source(f)` instead, or
  install devtools if that becomes a recurring friction).
- Full test suite: **32/32 passing** after the fix above.
- `targets::tar_make()` rebuilt cleanly (only `scoring_config`, `league_config`,
  `fct_player_week_scored`, `player_value`, `draft_board` re-ran — raw ingest targets
  stayed cached, ~2.5s total).
- Rebuilt `draft_board` inspected by hand: top of board is Bijan Robinson, Jahmyr Gibbs,
  Jaxon Smith-Njigba, Puka Nacua, James Cook III — real names, sane ordering, consistent
  with the injury-risk-weighted VOR approach described in handoff #1. Replacement level
  for the RB/WR/TE flex pool shifted as expected now that WR starters dropped from 3 to 2.

## Docs updated

`CLAUDE.md`'s "League facts" section rewritten — no more "Unknown until Pete confirms"
language, only draft slot remains unknown. `PLAN_1.md`'s config spine example block
(`scoring.json`/`league.json` jsonc snippets) replaced with the actual real values instead
of illustrative placeholders, with a one-line pointer back to `CLAUDE.md` for full detail.

## Still true from earlier handoffs (not re-verified this session, no reason to doubt)

- DST scoring is team-level and has no data source wired up yet — still out of scope for
  modeling, now just better-documented in config.
- ~19% of the draft pool (mostly 2026 rookies) has `has_current_data = FALSE` and is
  excluded from the ranked board entirely. Still an open call on whether that's acceptable
  for draft night or needs a fallback tier — not decided, not blocking.
- Browser extension (`claude-in-chrome`) was **not connected** this session — settings
  were pulled via manual copy-paste from the user, not a live page read. If future
  sessions want to re-pull Yahoo data live (e.g. to catch late roster/scoring changes
  before Sept 8), the extension will need to be reconnected first.

## Open decision for next session

Same two candidates as handoff #2, but now with real settings underneath so Phase 3.5
work won't be sitting on top of wrong numbers:

1. **Phase 3.5 — Shiny pick-entry app.** Already decided to use Shiny (not a lighter
   alternative, logged in handoff #1). Must capture picks as `(team, player)` for all ~10
   coaches, not just the user — needed by Phase 6's opponent-need model later. Full spec
   in `PLAN_1.md`'s Phase 3.5 section.
2. **Something else** — but given 4 days to draft and real settings now locked in, Phase
   3.5 is the obvious next step unless the user has a reason to deviate. Ask rather than
   assume, per this project's established pattern, but don't be surprised if the answer
   is just "yes, Phase 3.5."

## Suggested skills next session

- **`tdd`** — Phase 3.5's pick-entry state machine (marking a player drafted, attributing
  to a team, re-ranking remaining players against the now-real replacement levels) has
  hand-verifiable expected behavior, same pattern that worked cleanly for
  `R/75_value.R`'s VOR tests and `R/30_scoring.R`'s golden tests. Write the re-ranking
  test before wiring up Shiny reactivity.
- **`diagnose`** — if `tar_make()` misbehaves with an opaque targets/data.table
  interaction, reproduce with a small standalone Rscript outside the targets subprocess
  first (this is what isolated both prior bugs in handoff #1) — don't guess inside the
  pipeline.
- **`grill-with-docs`** — before finalizing Phase 3.5's UI shape, worth a quick
  adversarial pass against `PLAN_1.md`'s Phase 3.5 bullet list (tiered cheat sheet,
  per-team pick capture, one-line plain-English notes) to confirm nothing gets skipped
  under time pressure with 4 days left.
