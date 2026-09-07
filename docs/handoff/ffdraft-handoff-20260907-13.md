# Handoff #20 — Experiment A run. Bar FAILED, then 30 seeds said bar was wrong.

**Date**: 2026-09-07. **Draft**: Tue 2026-09-08 6:00pm ET. **Hours out.**
**Git**: `2644e66`, working tree DIRTY, nothing committed this session.
**533 tests passing** (was 526, +7).

Prior: `docs/handoff/ffdraft-handoff-20260907-12.md` (#19). Spec:
`docs/prd/001-mc-survival-vona.md`. Do not restate either. Read them.

Scope this session: **Experiment A only.** B not started.

---

## Verdict — two-layer, do not collapse to one word

| bar | pre-registered as | result |
|---|---|---|
| A1 — zero unfilled starter slots, every tau | #19 | **PASS** |
| A2 — starters >= `recommend` arm, every tau | #19 | **FAIL** (tau=3 only) |
| A3 — golden still 3/3 | #19 | **PASS** |

Then, **after** A2 failed and pre-registered before running:
30 seeds per tau, paired CI. tau=3 loss -> **single-draw artifact**.

**A2 FAIL stands as recorded.** Bar was specified on frozen seed, run on frozen
seed, failed. Not overturned. But bar was **underpowered** — see Lessons.

Honest one-line summary of A: **constrained arm wins tau 0/3/6, ties tau 12,
loses nowhere.** Stronger than "FAIL". Weaker than "PASS".

---

## Numbers

### A1 + A2, `dev/bars_a.R`. Slot 5, defer K16/DST15, seed = tau+1 (frozen from #19)

| tau | picks changed | recommend | vona_fill | delta | unfilled |
|---|---|---|---|---|---|
| 0 | 12 | 536.0 | 555.3 | **+19.3** | none |
| 3 | 13 | 638.4 | 615.4 | **-23.0** | none |
| 6 | 15 | 545.1 | 626.1 | **+81.0** | none |
| 12 | 13 | 629.7 | 664.6 | **+34.9** | none |

A1 PASS every tau. A2 FAIL on one cell.

### Supplementary, `dev/bars_a_seeds.R`. 30 seeds x 4 taus, CRN, `paired_bootstrap_ci()`

| tau | mean delta | 95% CI | sd | win rate | verdict |
|---|---|---|---|---|---|
| 0 | +19.3 | [+19.3, +19.3] | 0.0 | 100% | fill WINS |
| 3 | **+30.1** | **[+17.6, +43.3]** | 37.2 | 93% | fill WINS |
| 6 | +21.4 | [+8.7, +34.0] | 36.0 | 77% | fill WINS |
| 12 | +7.0 | [-8.3, +22.2] | 43.3 | 67% | **indistinguishable** |

Read: frozen seed at tau=3 drew **-23.0 from mean +30.1, sd 37.2** -> 1.4 sd
low, ~7% tail, matches 93% win rate exactly.

**Cuts both ways.** Frozen seed at tau=12 drew **+34.9**; true mean **+7.0**,
CI spans zero. Single seeds were wrong in *both* directions. Only the
pessimistic error got noticed.

tau=0 row is the **CRN wiring check**, not a sample. Opponents deterministic,
`simulate_forward()` deterministic -> noise matrix never read -> sd must be 0.
It was 0, and the point matches `dev/bars_a.R` exactly. Any spread there =
randomness leaking, distrust whole table.

---

## Shipped, all uncommitted

| file | status |
|---|---|
| `R/81_vona.R` | + `forced_positions()` |
| `R/80_opponent_sim.R` | + `my_rule = "vona_fill"` branch |
| `tests/testthat/test-vona.R` | +4 tests, written **before** the arm |
| `dev/bars_a.R` | A1 + A2 harness, writes `dev/bars_a_results.rds` |
| `dev/bars_a_mutation.R` | **mutation test of that harness** |
| `dev/bars_a_seeds.R` | 30-seed paired CI, writes `dev/bars_a_seeds.rds` |
| `inst/app/app.R` | **UNTOUCHED.** Clean at HEAD. Nothing changed what app renders. |

`forced_positions()` reads open slots two ways, both existing code:
`scarcity_report()$still_needed` -> *which* positions can close a slot;
`nrow(starter_value()$lineup)` vs `sum(unlist(starters))` -> *how many* open.
Fires when `rounds_remaining <= slots_unfilled`. Deferral loses by construction
— constraint only fires when no round left to wait.

Candidates drawn from full remaining pool, not just board. Off-board fallback
players carry `vor` NA -> `vona()` returns NA -> vor sort drops them last, which
is right order among them. Position exhausted league-wide -> constraint releases.

---

## Mutation test — `dev/bars_a_mutation.R`, 22s

Gate that cannot fail is not gate. #19 caught a circular golden; same discipline
applied here **before** trusting any PASS.

| | mutation | required | got |
|---|---|---|---|
| M1 | fill arm -> unconstrained `"vona"` | A1 FAIL | FAIL, `K 0/1, DST 0/1` |
| M2 | fill arm -> `"recommend"` (self-compare) | A1+A2 PASS, delta 0 | PASS |
| M3 | M2 docked 0.1 pt | A2 FAIL | FAIL |

M1 also **independently reproduces #19's diagnosis** — unconstrained VONA arm
drafts zero K, zero DST.

`dev/bars_a_seeds.R` carries its own self-check: `paired_bootstrap_ci()` on
constant +5 must give `lo > 0`, on constant -5 must give `hi < 0`. Stops the
script otherwise.

---

## UNRESOLVED — #19's table does not reproduce

`Rscript dev/bars.R` at `2644e66`, `_targets` store untouched since Sep 6 21:13:

| tau | #19 recorded rec | reproduces as | #19 recorded vona | reproduces as |
|---|---|---|---|---|
| 0 | 536.0 | **536.0** | 493.9 | **493.9** |
| 3 | 542.5 | 638.4 | 565.9 | 554.0 |
| 6 | 662.4 | 545.1 | 589.0 | 564.7 |
| 12 | 664.6 | 629.7 | 646.4 | 603.2 |

tau=0 matches both arms exactly. tau>0 matches neither. Ran `dev/bars.R` twice,
identical both times -> deterministic now, so drift is not in current code.

Recommend arm has **no RNG dependence** beyond `sim_noise(seed = tau+1)`. So
#19's tau>0 numbers were produced by code that is not what got committed, or
were mis-transcribed. **Not chased.** Did not affect this session's verdict —
both arms ran in same process on same noise.

Consequence for next session: **#19's tau>0 table is not a baseline.** Do not
diff against it. Re-run `dev/bars.R` if a baseline is needed.

---

## Lessons — apply to B

### 1. Single-seed bars are underpowered. This is the big one.

Paired delta on `starter_value()$total` has **sd 36-43 pts** at tau > 0, against
totals 536-665. Effects worth detecting: **+7 to +30**.

One draw cannot resolve that. One draw measures the *draft*, not the *rule*.
#19 set the bar this way, this session inherited it, and it produced a FAIL that
30 seeds contradicted at 93% win rate.

**Do for B:** pre-register bars on paired bootstrap CI over **>= 30 seeds**, not
a frozen seed. `paired_bootstrap_ci()` already exists in `R/80_opponent_sim.R`.
Cost measured: 240 sims ~= 7 min wall.

**Not permission to re-seed until a bar passes.** Seed formula, seed count, and
decision rule fixed and written down *before* the run. This session did that —
transcript records the rule before the numbers existed.

### 2. Pre-register the *read*, not just the threshold

A2's threshold was clear; its *interpretation under noise* was not, so the
follow-up risked looking like tuning. Fixed by writing the rule first:
CI contains 0 or above -> artifact; CI entirely below 0 -> real loss; **either
way A2 FAIL stands.** Do the same for B.

### 3. Report the mutation test, always

Both bars proved able to fail before either PASS was believed. Cheap (22s).
#19's circular-golden rejection says why.

### 4. tau is not a hyperparameter

Asked whether an ML model could find the optimal tau. No. `tau` is a claim about
how noisy real Yahoo drafters are, not a knob. Fitting it to make a bar pass is
exactly what #19 forbids. `n_sims` buys precision, not a different answer. There
is no optimum to search. Right tool was always the paired estimate.

### 5. A does not subsume B, and B may still subsume A

A's constraint only binds in the last rounds. Rounds 1-~14 remain **argmax-VONA
across all positions** — the untested half. B tests exactly that half.

---

## Next — Experiment B, unchanged in shape from #19

VONA as within-position tiebreak. `target_position()` keeps choosing position;
VONA only orders candidates *within* it. Hypothesis: VONA answers "which RB",
not "which position".

**Pre-register BEFORE running**, revised per Lesson 1:

1. Zero unfilled starter slots, every tau.
2. Paired CI lower bound **>= 0 at every tau**, 30 seeds, CRN.
3. Golden still 3/3.
4. Picks changed vs current **>= 3/17** (else tiebreak never binds -> no-op).
5. Mutation test of the B harness passes before any PASS is reported.

Note bar 2 as restated: **A itself would fail it** — tau=12 lo = -8.3.

### Do not do

- Do not tune `tau`, `n_sims`, seeds, or candidate set to make a bar pass.
- Do not build roster-need into *simulated opponents*. Out of scope, #18.
- Do not touch `inst/app/app.R` before the draft.

---

## Open decision for the user

Working tree dirty, draft is tonight. Nothing committed. `vona_fill` is measured
but **not wired into the app** and should not be — A2 as pre-registered failed,
and app behaviour changes hours before a live draft are their own risk.

Decide: commit the measurement infra as-is, or leave dirty until after the draft.

---

## Suggested skills

- **`/caveman`** — all docs. Repo rule, `CLAUDE.md`.
- **`/to-prd`** — spec Experiment B before building it. PRD-first is what caught
  #19's circular gate.
- **`/tdd`** — B's bars as tests, written before the arm. Done that way here.
- **`/handoff`** — close next session. Write to `docs/handoff/`, **not `/tmp`**
  (`docs/handoff/README.md`).

## Carried forward — do not investigate

All closed. See #18 and `CLAUDE.md`: Yahoo API (gated), Sleeper `search_rank`
(REJECT), ffscrapr / ESPN / fantasy MCP (league-scoped), `data/yahoo_rankings.csv`
(our own board exported *into* Yahoo, not a source).
