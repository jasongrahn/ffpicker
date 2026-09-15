# ffdraft Handoff #24: draft over. Official results in, log rebuilt, rounds bug fixed. Draft engine done.

**Local**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: 2026-09-08, post-draft (draft ran 6:00pm ET; Week 1 opens Wed 2026-09-09)
**Prior**: `ffdraft-handoff-20260908-16-DRAFT-DAY-CLOSE.md` (#23)
**Git**: branch `draft-day-official-results`, commit `422676e`, pushed. **PR not opened — user opens it.**
**Working tree**: clean at commit time. This doc + README row are the only new files after.

**Draft is over. Nothing in this repo's draft path runs again until a 2027 draft.**
Next work is a different project — see §6.

---

## 1. What shipped. Do not re-derive.

All of it is in `422676e`. Read the commit message before this section — it carries
the mechanics. Only the judgement calls are here.

- **Draft was 15 rounds / 150 picks.** Not 17. 9 starters + 6 bench = 15; the 2 IR
  slots are not drafted. `config/league.json` had `rounds: 17` since day one.
  Every round-count assumption in every prior handoff inherits this error.
- **`data/official_draft_results.csv`** — authoritative. 150 rows,
  `Pick,Player,Position,Team,Bye,DraftedBy,Status`. `DraftedBy = "Your Team"` is us.
  `Team` col carries **2026** teams; the Draft Pool does not. Never join on team.
- **`data/pick_log.jsonl` rebuilt, not reconciled.** `dev/rebuild_pick_log_official.R`
  is idempotent — re-run it and it re-archives + re-writes from the CSV.

### Provenance question from #23 §5: ANSWERED, and #23 overstated the damage

Live log was **142/150 correct**, not broadly corrupt. Divergence is 8 slots:

| slots | cause |
|---|---|
| 58-61 | one-pick **offset drift** — Fairbairn inserted at 58, realigned by 62. Not substitution. |
| 135, 139, 144, 145 | genuine off-board / wrong-player entries under the clock |

**Our own 15 picks: 15/15 identical.** #23 §8 item 4 closed — **Jacobs at 71 is real.**

Archived pre-official log: `dev/pick_log_archive/pick_log-20260908-184420-PRE-OFFICIAL.jsonl`.
**`dev/pick_log_archive/` is gitignored (`.gitignore:13`) — that file lives on this
machine only.** Only surviving evidence of the substitution failure mode. Do not wipe.

### Off-board escape hatch: still not built, but now has a shape

Two real picks had no Draft Pool row at all (Tyler Loop K BAL, Harrison Mevis K LAR).
Given synthetic keys `-910001`/`-910002` (distinct from the `-900xxx` DST block),
recorded in `data/off_board_picks.csv`. That is a **rebuild-time workaround**, not the
app-time hatch #23 §9 asked for. Pattern works though: negative key + typed name.

---

## 2. Roster, and the two defects it proves

15 picks at slot 10. Full list in `data/official_draft_results.csv`
(`DraftedBy == "Your Team"`). Counts: **RB 7 (at cap), WR 4, QB 2 (at cap), TE 1,
DST 1, K 0.**

**Defect 1 — zero kickers. Config bug, not selector bug.**
`defer_until_round K: 16` in a 15-round draft = never. Only team of 10 with no K.
Board's #1 K (Jason Myers SEA, VOR 61.4) was the **highest-VOR player available on our
own board at picks 90, 91, 110, 111, 130 and 131**, went at 138. Cost ~46 VOR vs best
K left free (Chase McLaughlin TB, VOR 15.4). Fixed in `422676e`:
`rounds: 15`, `defer_until_round: {K: 14, DST: 14, QB: 7}`. Targets rebuilt, 533/0 green.
**Root cause is that no test asserted `rounds` against the roster arithmetic.** Still true.

**Defect 2 — Josh Jacobs at 71, status `CEL`.** On `data/inactive_do_not_draft.csv`
row 20. Status column **still not wired to `inst/app/app.R`**. Board showed him clean
at RB VOR 63.8 = top available. Predicted by #22, cost now realized: dead round-8 spot.
**Fourth time this has been named. It is no longer worth wiring — the draft is over.**
Log it as the lesson, not the backlog item.

**Defect 3 (soft) — WR 4 for 2 WR + FLEX.** Fewest-tied in league. `max_at_position`
RB 7 absorbed picks 90/111/130 at VOR 31/17/12 while WR sat thin. Recurred in both
mocks and the real draft -> `target_position()` issue, not slot luck. Unchased.

---

## 3. What the app got right

- **QB fade (`defer_until_round QB: 7`) is the strongest verified result this repo has.**
  Stafford at 70 = board's **#1 QB by VOR (44.95)**, ahead of Josh Allen (43.0, gone at 21).
  Mahomes = board's #4 (40.6) at 110. Eight QBs went before Stafford. One-line config
  change, zero R code, delivered #1 and #4 QB at picks 70 and 110.
- **Board discipline.** 10 of 15 picks were top non-K available on our board at that moment.
- `max_at_position` capped RB and QB without user attention.

**Do not cite the VOR total.** Roster sums 658 board-VOR vs next team's 232. Scored
against our own board -> circular. Proves we followed the board, nothing about outcomes.
The only honest test is season points, available from ~week 4.

---

## 4. QB board miscalibration — now looks like the opposite of a defect

#22 flagged QB as our worst column (VOR Spearman +0.45 vs ECR +0.80) and #23 parked it
as "real defect, undiagnosed." **Reconsider.** The divergence is exactly what produced
the QB fade win — our VOR ranked Stafford #1 and Caleb Williams #3 where ECR had them
106th and 65th, and the market (real Yahoo drafters, not a sim) left both there.
Low correlation to ECR is not evidence of error when ECR is the thing we beat.
Genuinely unresolved, and **only resolvable with 2026 season results**. Revisit ~week 8.

---

## 5. State of the tree

- Tests **533 pass / 0 fail** after the config change.
- `tar_make()` run for `league_config_file`, `league_config`, `draft_board`. Store current.
- App may still be running on port **4321** — kill it, it reads a stale board and the
  draft is over. `inst/app/app.R:16` trap (`tar_read`, not `load_config()`) still stands
  for anyone who reopens it.
- Two sessions of carried uncommitted work are now committed: both #22/#23 handoffs,
  `inactive_do_not_draft.csv`, `yahoo_rankings_v2.csv`, `docs/uploads/` consolidation,
  `R/95_export.R`, `dev/rebuild_yahoo_export.R`.

**Open action for user, not agent:** open the PR at
`https://github.com/jasongrahn/ffpicker/pull/new/draft-day-official-results`.

---

## 6. Next project: in-season weekly start/sit picker

Scoped in **#21** (`ffdraft-handoff-20260907-14-INJURY-SIGNAL-START-HERE.md`) — read it,
it holds verified 2024+2025 data availability, the `load_participation()` route trap,
the pre-registered gate, and a ~1hr test that can kill the injury-severity idea cheap.

**Nothing in the draft engine transfers.** Waivers have no turn order; Yahoo XRank is
preseason and stale by ~week 3. Do not reach for `R/80_opponent_sim.R`, `R/81_vona.R`,
or `R/78_turn.R`.

Dead, do not revive:
- **VONA as pick selector** — all three framings closed (#19, #20, #21).
- **`p_available` / `survival_display()`** (`R/81_vona.R`) — draft-only display, window
  closed 2026. Still unwired. Leave it.
- **Status column wiring** — see §2, no longer worth it.
- **Yahoo/ESPN/Sleeper API re-investigation** — see `CLAUDE.md` hard constraints.

First real decision for #25: the picker needs a **new in-season data source**, and
`CLAUDE.md`'s constraints were all written against draft-time needs. Re-check what
`nflreadr` gives weekly before scoping anything.

---

## 7. CLAUDE.md needs an edit

`## Current status` still reads *"Nothing built yet. Next action is Phase 0."* Wrong for
many sessions; now wrong in a way that matters, since the draft engine is finished. The
league facts block also says **17 rounds** (§1) — same error as the config had.
**Fix both before starting #25.**

---

## Suggested skills

- **`caveman`** — repo doc rule, any doc this or a later session writes
- **`to-prd`** — the weekly picker is a new project, not a continuation; scope it as a PRD before code
- **`handoff`** — close #25
- **`session-close`**
