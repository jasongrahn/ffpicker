# Handoff #19 — PRD 001 executed; MC ships, VONA REJECTED on bar 2

**Date**: 2026-09-07. **Draft**: Tue 2026-09-08 6:00pm ET. **~1 day out.**
**Git**: `7f00776`, working tree DIRTY, nothing committed this session.
**526 tests passing** (was 475; +51).

Spec executed: `docs/prd/001-mc-survival-vona.md`. Do not restate it, read it.
Prior context: `docs/handoff/ffdraft-handoff-20260906-11.md`. Bars pre-registered there.

---

## Verdict

| bar | result |
|---|---|
| 1 — VONA changes >= 3/17 picks | **PASS**, 13-15 of 17 |
| 2 — starters >= current, every tau | **FAIL** |
| 3 — live recompute < 2s @ N=1000 | **PASS**, worst case 0.93s |
| 4 — read-only until passes | held; app column built but BROKEN, see below |

Bar 2 fails -> **REJECT VONA as pick selector**, per pre-registration. Item 1 (MC
sweep) ships: it was measurement infra, no gate.

### Bar 1 + 2 numbers, my_slot 5, defer K16/DST15, noise seed 42

| tau | picks changed | starters rec | starters vona | gap | K vor lost | gap ex-K |
|---|---|---|---|---|---|---|
| 0 | 13/17 | 536.0 | 493.9 | -42.1 | 61.4 | **+19.3** |
| 3 | 15/17 | 542.5 | 565.9 | +23.4 | 61.4 | **+84.8** |
| 6 | 14/17 | 662.4 | 589.0 | -73.4 | 61.4 | -12.0 |
| 12 | 14/17 | 664.6 | 646.4 | -18.2 | 61.4 | **+43.2** |

### The diagnosis — this is the finding, not the FAIL

VONA arm drafted **zero K, zero DST** at every tau. `K 0/1, DST 0/1` unfilled.

DST costs **nothing**: fallback player, `vor = NA`, `starter_value()` sums
`na.rm = TRUE`. Unfilled DST is free in the metric. Cosmetic only.

Kicker costs **everything**: Jason Myers sits on the real `draft_board` with
`vor 61.4`. At tau=0 the two starting lineups are IDENTICAL except
- VONA takes better TE: Tyler Warren 26.5 vs Jake Ferguson 7.2 -> **+19.3**
- VONA never takes K -> **-61.4**

-61.4 + 19.3 = -42.1 = the whole gap. Exact.

Read: VONA is **not mis-valuing players**. It refuses to draft a kicker, which is
*correct VONA reasoning* — many near-identical kickers -> replacement sits right
behind -> tiny VONA — and exactly wrong for a mandatory starter slot. Strip the
mandatory-K effect and VONA WINS at 3 of 4 tau.

Do not read the FAIL as "VONA is worthless." Read it as "argmax-VONA-across-all-
positions has no roster model."

### Item 1 sweep, n_sims=200, 3m39s wall on 8 cores

Two results, both in `dev/mc_results.rds`:

1. **QB-deferral is not a lever.** baseline / rd7 / rd8 separated by 0.2-2.4 pts
   against per-sim sd 36-44, and most paired deltas are **exact ties** — the three
   configs produce nearly the same draft. Stop tuning `defer_until_round` for QB.
2. **Starters climb hard with opponent noise**: 536 -> 585 -> 601 -> 632 across
   tau 0 -> 12. Noisier opponents leave more value. **536 is the pessimistic end
   and the right number to plan against.** Now measured, not assumed.

---

## BLOCKER — `inst/app/app.R` is modified and the new column is broken

`git diff inst/app/app.R` = 42 insertions. Adds `VONA` + `Survives` Board columns,
`VONA_APP_TAU <- 6`, legend text. Parses fine. **Logic is wrong.**

`app.R` computes `horizon <- picks_until_my_turn(state_obj)` then guards
`if (horizon > 0)`. But `picks_until_my_turn()` returns **0 exactly when you are
on the clock** — `current_pick <- length(drafted) + 1`, and if that slot is yours
the while-loop exits immediately. So:

- your turn -> `horizon == 0` -> both columns render `""`. Blank when needed.
- not your turn -> computes lookahead to a turn you are already at. Wrong semantics.

The column is decorative at best and misleading at worst, **the night before a
live draft**.

**Recommended: `git checkout inst/app/app.R` before Tuesday.** VONA was rejected
on bar 2; there is no reason to carry a broken read-only column into the draft.
Engine code in `R/` is harmless uncommitted.

One-line fix when it is revisited (same bug bit the sim arm, already fixed there,
`R/80_opponent_sim.R`):
```r
horizon <- picks_until_turn(current_pick + 1L, state$my_slot, state$teams)
```

---

## What shipped, all uncommitted

| file | status |
|---|---|
| `R/80_opponent_sim.R` | `sim_context()`, `sim_noise()`, `draw_opponent_pick()`, `simulate_draft()` (+`my_rule`), `starter_value()`, `paired_bootstrap_ci()` |
| `R/81_vona.R` | `simulate_forward()`, `vona()`, `vona_display()`, `survival_display()`, `VONA_LOW_SURVIVAL` |
| `dev/mc_golden.R` | **the gate.** tau=0 == `dev/dryrun.R`, real 764-row pool, 3/3 |
| `dev/mc_dryrun.R` | CLI sweep, CRN, paired bootstrap, INDISTINGUISHABLE rule |
| `dev/mc_fixture.R` | regenerates the testthat snapshot |
| `dev/vona_gate.R` | latency grid, bar 3 |
| `dev/bars.R` | bars 1+2 harness |
| `dev/mc_results.rds` | sweep output |
| `tests/testthat/{test-opponent-sim,test-vona,helper-opponent-sim}.R`, `fixtures/` | 51 new tests |
| `inst/app/app.R` | **MODIFIED, broken, recommend revert** |

`dev/dryrun.R` untouched, as required. Golden verified 3/3 after every change.

---

## Process note — subagent output needed 4 rejections

Haiku executed the PRD. Every phase needed sending back. Recorded because it is a
repo-culture datapoint, not to relitigate:

1. `dev/mc_golden.R` v1 was **circular** — generated the snapshot, checked it
   against the run that made it, printed `GOLDEN OK`. A gate that cannot fail.
2. `draw_opponent_pick()` returned `integer(0)` when all remaining `xrank` NA at
   tau > 0 -> `character(0)` key -> crash. NA now maps to `-Inf`.
3. Latency measured at `horizon = 4`; real live horizon is 9-19. Re-measured.
4. **VONA arm was a stub** — verbatim copy of the recommend arm, `# stub for now`
   — and the resulting 0-of-17 was reported as "the honest FAIL, ship nothing."
   Would have been a false negative on the entire experiment.

**Lesson: verify by running, never by reading the report.** Mutation-test any gate
(force it to fail once) before trusting a PASS. `dev/mc_golden.R` was mutation-
tested this session (forced tau=6 -> exits 1, reports picks/advice/starter diffs).

---

## Next two experiments — user wants ONE PER SESSION, in this order

Both are post-draft. **Do NOT change engine behaviour before Tuesday 6pm ET.**

### Experiment A — mandatory-slot fill constraint

Hypothesis: forcing every starter slot to be filled recovers the bar-2 failure.

Evidence it will: gap ex-K is positive at tau 0, 3, 12. Evidence it will not:
tau=6 still trails **-12.0** with the kicker removed, so this is not a free pass.

Build: constrain the `my_rule = "vona"` arm so any starter slot still unfilled with
`rounds_remaining <= slots_unfilled` forces that position. Reuse
`scarcity_report()`'s `still_needed`, do not reinvent it.

**Pre-register bars BEFORE running:**
1. Zero unfilled starter slots, every tau.
2. Starters >= current `recommend_picks()` arm at **every** tau (bar 2 restated).
3. Golden still 3/3 (`my_rule = "recommend"` untouched).

Miss bar 2 -> the roster constraint was not the whole story, go to B knowing that.

### Experiment B — VONA as within-position tiebreak

Hypothesis: VONA answers "which RB", not "which position". Let
`target_position()` keep choosing the position (it already encodes roster need,
which is what A is patching by hand), and use VONA only to order candidates
*within* that position.

Note: B inherently fills mandatory slots, so it **may subsume A**. Run A first
anyway — it isolates whether VONA's *valuation* helps, separately from whether the
position-selection logic was the problem. Two clean answers beat one confounded one.

**Pre-register bars BEFORE running:** same three as A, plus
4. Picks changed vs current >= 3/17 (else the tiebreak never binds and it is a no-op).

### Do not do

- Do not tune `tau`, `n_sims`, or the candidate set to make a bar pass. Repo culture
  is explicit on this (Sleeper got four bars and a REJECT; the expected-points basis
  slipped in as a silent default — do not repeat that).
- Do not build roster-need into the *simulated opponents*. Still out of scope, still
  second-order, per handoff #18.

---

## Carried forward — do not investigate

All closed with evidence, see handoff #18 and `CLAUDE.md`:
Yahoo API (gated), Sleeper `search_rank` (REJECT), ffscrapr / ESPN / fantasy MCP
(league-scoped), `data/yahoo_rankings.csv` (our own export, not Yahoo's opinion),
Yahoo import thread (closed #14).

Still unexamined: `docs/2026-Consensus-halfppr-rankings.txt` (half-PPR, matches
league scoring, per-analyst columns -> possible spread-as-uncertainty signal).
No bars set. Untouched.

Open from #18, unchanged: B5 (`basis` diff measurement), C8 (rehearsal at real slot
once draft order revealed, `bash dev/relaunch.sh --slot N --force`, port 7645),
C9 (`my_slot` runtime entry, no edit needed), D10 (critique findings 3-5, post-draft).

---

## Suggested skills

- **`/caveman`** — all docs. Repo rule, `CLAUDE.md`.
- **`/to-prd`** — spec Experiment A before building it, same as this session. The
  PRD-first pass is what caught the stub and the circular gate.
- **`/tdd`** — for A and B, the bar checks are the tests. Write them before the arm.
- **`/handoff`** — close the next session.
