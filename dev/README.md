# dev/ — measurement scripts, not shipped code

Nothing here is loaded by the package or by `inst/app/app.R`. These are the
harnesses that decided what does and does not go into the app.

## VONA experiments — all closed 2026-09-07

Read `CLAUDE.md`'s VONA block first. Short version: three framings tried, none
shipped, one left unresolved on purpose.

| script | what it gates | verdict |
|---|---|---|
| `vona_gate.R` | VONA plumbing | superseded by the bars below |
| `bars.R` | pre-VONA baseline | **#19's tau>0 table does not reproduce — re-run before using as a baseline** |
| `bars_a.R` | A1/A2: `vona_fill` vs `recommend`, frozen seed | A1 PASS, **A2 FAIL** (tau=3) |
| `bars_a_seeds.R` | A2 effect size, 30 seeds CRN | +7..+81, 93% win, loses nowhere |
| `bars_a_mutation.R` | can A1/A2 fail at all | OK, 22s |
| `bars_b.R` | B1/B4: `vona_tiebreak` vs `recommend` | B1 PASS, **B4 FAIL — 0 picks changed** |
| `bars_b_seeds.R` | B2, 30 seeds CRN | CI [0.0, 0.0], sd 0.0 — vacuous |
| `bars_b_mutation.R` | can B's bars fail at all | OK, 24s. M1 proves the branch is live |
| `mc_golden.R` | `simulate_draft(tau=0)` == `dryrun.R` | 3/3, must stay 3/3 |

`PREREG_B.md` is Experiment B's pre-registration *and* its results, in that
order, written in that order.

## House rules these encode

1. **Pre-register the bars AND the read** before running. A threshold without a
   stated interpretation invites tuning after the fact.
2. **Mutation-test any gate before trusting a PASS.** A gate that cannot fail is
   not a gate. Both A and B caught real problems this way; #19 shipped a circular
   golden that this would have caught.
3. **>= 30 seeds with common random numbers, paired CI.** Starter totals run
   536-665 with sd ~37 draft-to-draft; effects worth detecting are +7..+30. One
   seed measures the *draft*, not the *rule*.
4. **Report the failure.** A2's FAIL stands as recorded even though 30 seeds
   contradicted it. The bar was underpowered; the result was still the result.
