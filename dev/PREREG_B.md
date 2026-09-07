# Experiment B — pre-registration. Written BEFORE any run.

Date 2026-09-07. Baseline: dirty tree at `2644e66` + uncommitted Experiment A work
(`R/80_opponent_sim.R`, `R/81_vona.R`, `tests/testthat/test-vona.R`, `dev/bars_a*`).
No A files touched. `inst/app/app.R` not touched. `simulate_draft()` is called by
nothing under `inst/` or `R/` — verified — so a new arm cannot change app render.

## Arm under test

`my_rule = "vona_tiebreak"`. `target_position()` still chooses the position, exactly
as the `recommend` arm. VONA only orders candidates *within* that position.
Everything else — deferral, bench branch, fallback-by-ECR branch, advice string —
is the recommend arm byte-for-byte.

## Bars (from handoff #13 "Next", verbatim, not restated)

1. Zero unfilled starter slots, every tau.
2. Paired CI lower bound **>= 0 at every tau**, 30 seeds, CRN.
3. Golden still 3/3.
4. Picks changed vs current **>= 3/17**.
5. Mutation test of the B harness passes before any PASS is reported.

Fixed before running, not tunable: slot 5, defer `list(K=16, DST=15)`,
taus 0/3/6/12, frozen-seed formula `tau+1` (bars 1/4), 30-seed formula
`10000 + tau*100 + s` (bar 2) — both copied from Experiment A, unchanged.
`n_sims = 200L` inside `simulate_forward()`, unchanged.

## The read (Lesson 2 — pre-registered interpretation, not just thresholds)

- **B4 = 0/17** -> tiebreak never binds. B is a **no-op**. Bars 1/2/3 then pass
  *vacuously* (both arms are the same draft) and MUST NOT be cited as support.
  Verdict = B FAILS, and the thing that is wrong is the **hypothesis**, not the bar.
- **B4 in 1..2** -> bar 4 FAILS as written. Report the changed picks. Do not lower
  the bar to fit.
- **B4 >= 3 and any tau has CI lo < 0** -> tiebreak binds but does not pay.
  Hypothesis wrong on value.
- **B4 >= 3, CI lo >= 0 every tau, B1/B3/B5 pass** -> B PASSES.

## Stated prediction, recorded before running

`vona(X) = vor(X) - E[best vor at pos(X) next turn]`. The subtracted term is keyed
on position only. Within one fixed position it is a **constant**, so argmax-VONA
and argmax-VOR select the same player. Predict **B4 = 0/17 at every tau** and B a
no-op by construction.

If that prediction holds, the confound to rule out is "branch is dead code, so of
course nothing changed." Mutation M1 below is the discriminator and is the load-
bearing test of this session.

## Mutation tests (bar 5), required before believing any PASS

- **M1 — tiebreak key negated** (`-vona`, worst-first within the target position).
  MUST change >= 3 picks. If it changes 0, the branch is dead and every other B
  number is meaningless. This separates "degenerate ranking key" from "harness bug".
- **M2 — arm = `recommend`** (self-compare). MUST give 0 changed, delta exactly 0.
- **M3 — M2 docked 0.1 pt.** MUST fail the `>=` comparison, proving it is live.

## Instrumentation

At every one of my 17 picks the arm records the argmax under the VONA key and the
argmax under the VOR key. Direct evidence for the read, independent of the
aggregate pick-diff count.

---

# Results — run 2026-09-07, after the above was written

| bar | result | evidence |
|---|---|---|
| B1 zero unfilled starter slots, every tau | **PASS** (vacuous) | `dev/bars_b.R`, `dev/bars_b_seeds.R` |
| B2 paired CI lo >= 0, every tau, 30 seeds | **PASS** (vacuous) | CI `[0.0, 0.0]`, sd 0.0, all four taus |
| B3 golden 3/3 | **PASS** | `dev/mc_golden.R`, 3/3 identical |
| B4 picks changed >= 3/17 | **FAIL** | **0** changed, every tau, all 124 drafts |
| B5 mutation | **PASS** | `dev/bars_b_mutation.R`, 24s, M1/M2/M3 all killed |

**Verdict: Experiment B FAILS on bar 4. B is a no-op.** B1/B2/B3 pass only because
the two arms drafted the identical team; per the read above they are not support.

## Bar or hypothesis? — the hypothesis

Bar 4 was correctly specified and fired correctly. Four independent lines:

1. **Algebra.** `vona(X) = vor(X) - E[best vor at pos(X) next turn]`. The second
   term is keyed on position alone (`R/81_vona.R`, `pos_map[[player_pos]]`). Hold
   the position fixed -- which is precisely what "within-position tiebreak" means --
   and it is a constant. VONA is then VOR minus a constant: same order, same argmax.
   Not a near-tie, an identity.
2. **The branch is live.** M1 negates the ranking key and changes **16 of 17** picks
   at every tau. So 0-changed is degeneracy, not dead code. This was the one result
   that could have made the whole session meaningless, and it came back clean.
3. **Direct instrumentation.** 1920 picks routed through the tiebreak across the
   30-seed run. VONA argmax == VOR argmax on **1920 of 1920 (100.0%)**.
4. **Aggregate.** 0 picks changed across 124 drafts (4 frozen-seed + 120 seeded).

Handoff #13 Lesson 1 warned single-seed bars are underpowered. That is not what
happened here. sd is **0.0**, not 36-43 -- there is no noise to be underpowered
against. No seed count would change this answer.

## What this closes, and what it does not

Closed: **VONA cannot act as a within-position tiebreak.** Do not re-run B in any
seed/tau/n_sims variant; the result is algebraic, not empirical.

Still open, and #13 Lesson 5's "untested half" is *not* covered by this: VONA's
only non-degenerate use is **across** positions, where the subtracted term varies.
That is the unconstrained `"vona"` arm (rejected #19: drafts zero K, zero DST) and
`"vona_fill"` (Experiment A: A2 FAIL on frozen seed, +7..+81 over 30 seeds, 93% win).
B tested the one framing where VONA provably has nothing to say.

Nothing shipped to `inst/app/app.R`. App render unchanged.
