# VONA does not choose the pick; `p_available` survives as a display

VONA(X) = vor(X) - E[best vor at pos(X) at my next turn]. Idea sound — every attempt to make
it *choose the pick* failed. Three framings, all closed 2026-09-07. Arms live behind `my_rule`
in `simulate_draft()` (`R/80_opponent_sim.R`), reachable only from `dev/`. Evidence:
`docs/handoff/drafting/ffdraft-handoff-20260907-{12,13}.md` and `dev/PREREG_B.md`; harnesses
`dev/bars_a*.R`, `dev/bars_b*.R`.

Decided: draft picks stay on `target_position()` + VOR. Do not re-run any framing below.

**Considered and rejected**:
- `"vona"` — argmax VONA across all positions. **Rejected #19.** Drafts zero K, zero DST at
  every tau. Correct VONA logic (kickers near-identical -> replacement sits right behind ->
  tiny VONA) applied to slots the league makes mandatory.
- `"vona_fill"` — same, plus `forced_positions()` closing mandatory slots once rounds left <=
  slots open. **Only positive result.** Pre-registered bar A2 (single frozen seed) FAILED at
  tau=3; 30 seeds CRN then showed +7..+81, 93% win rate, loses at no tau. FAIL stands as
  recorded, bar was underpowered (below). Measured, never wired to the app.
- `"vona_tiebreak"` — position from `target_position()` as today, VONA orders candidates
  within it. **No-op by algebra, not by measurement.** Subtracted term keyed on position
  alone -> constant within one position -> argmax-VONA == argmax-VOR. 0 picks changed across
  124 drafts, 1920/1920 tiebreak picks identical, CI [0.0, 0.0], sd 0.0. Bar 4 (>= 3/17 picks
  changed) FAILED; bars 1-3 passed only vacuously. Mutation M1 (negate the key -> 16/17 picks
  change) proves the branch live — the zero is degeneracy, not dead code. No seed count, tau,
  or `n_sims` changes this.

## Single-seed bars are underpowered — measured here, applies everywhere

`dev/bars_a_seeds.R`, 30 seeds x 4 taus, common random numbers: paired delta between two arms
on `starter_value()$total` has **sd 36-43 pts** at tau > 0, against totals ~550-660 and
effects worth detecting of +7 to +30. Bar A2 failed at tau=3 (-23.0 on the frozen seed) while
the 30-seed paired CI was [+17.6, +43.3] — the frozen draw sat ~1.4 sd below its own mean. One
seed measures the draft, not the rule.

-> Pre-register arm comparisons on the paired bootstrap CI over >= 30 seeds
(`paired_bootstrap_ci()`, `R/80_opponent_sim.R`). tau = 0 is deterministic: a CRN wiring
check, not a sample. Not permission to re-seed until a bar passes — seeds and rule fixed
before the run.

## Not closed: `simulate_forward()`'s `p_available`

Survival probability per player over the horizon to my next turn. Never failed a bar because
it was never a selector — it is a *display*. "12% he survives to your next pick" is the
question a human has on the clock, orthogonal to every verdict above. `survival_display()`
and `VONA_LOW_SURVIVAL` (`R/81_vona.R`) already format it. Unwired to `inst/app/app.R` only
because the draft was hours out. **The piece worth reviving for the 2027 draft.**

Draft-only: VONA assumes snake turn order; waivers have none.
