# Inside a ~5% projection gap nothing arbitrates — spread tiebreak retired

**Updated 2026-10-27: band widened 5% -> 15%. Last section.** 10-13 evidence below = history,
unchanged.

2026-10-07: the RB spread multiplier (ADR 0007) was adopted as the tiebreak when two players
sit within ~5% of each other — on reasoning, never on a decision test. Then it got one.

Decided (2026-10-13): **inside that band NOTHING arbitrates — start the higher raw Yahoo
projection and stop.** Do not break the tie on the spread, and do not revert to usage either.

Evidence — harness `dev/weekly/spread_tiebreak_leaguewide.R`, rerunnable. All **10 rosters**
rebuilt from the `Roster Status` column of the week-4/5 position *actual* exports; every
within-5% RB/WR/TE pair scored raw ordering vs spread-adjusted ordering against actuals. Only
**discordant** pairs — where the rule changes the pick — carry information.

| scope | pairs within 5% | discordant | spread pick right | 95% CI | p |
|---|---|---|---|---|---|
| 10 rosters, wks 4-5 | 75 | 17 (22.7%) | 6 (35.3%) | [0.142, 0.617] | 0.33 |
| pool-wide, wks 4-5 | 1,497 | 240 (16.0%) | 114 (47.5%) | [0.410, 0.540] | 0.48 |
| pool-wide, excl. actual == 0 | — | **215** | **105 (48.8%)** | **[0.420, 0.557]** | 0.79 |

Points: **-0.488/decision**, CI [-1.77, +0.80]. No favouredness bucket escapes chance (dog7+
43.6% n=55 … fav7+ 44.4% n=27). The CI **excludes accuracy above 55.7%**. 16% discordance
replicates the 2.3%-of-all-pairs figure (ADR 0007).

**The double-count theory is dead too, in the other direction.** Pearson(favouredness, Yahoo
proj / own season ppg) re-run at **n = 190** (was 39): **r = -0.036, p = 0.62, CI [-0.177,
+0.107]** — RB -0.094, WR +0.018, TE -0.080. The 10-07 **+0.129 at n=39 was noise**. Yahoo
genuinely does not price the spread, *and* adding it still loses. 10-07 premise right,
conclusion still wrong — orthogonal information is not automatically usable information.

Cause is arithmetic, not a defect. 0.00799 x 7 = **5.6%, ~0.6 pts** on a 10-pt projection,
against ~8-9 pts of variance between two actuals inside a 5% band. **A 0.6-pt edge cannot
arbitrate a 9-pt coin flip at the pair level**, however real it is in the mean.

Why the slope does not transfer to a tiebreak: it was measured on points **relative to a
player's own season average**, and season ppg is our worst non-trivial baseline (MAE 7.32 vs
Yahoo's 4.29, ADR 0009). A multiplier calibrated against a weak baseline does not transfer
onto a strong one. That mismatch is the bug.

The RB coefficient in this check came back -0.0060 at p = 0.48 — **noise, not a sign flip.**
Do not read it as one. The slope's kill condition is still the `mult_measure.R` 2026 rerun at
season end.

**Considered and rejected**:
- Spread tiebreak — above.
- Usage tiebreak — never tested as a tiebreak; usage-based estimates lose to Yahoo overall
  (MAE 6.71 vs 4.29, ADR 0009).

## Worked case, wk5, closed

Gordon II (RB, MIA -7.0, proj 9.80 -> 9.25 adj) vs Boston (WR, proj 9.69). Started Boston on
the spread tiebreak. Gordon 14.80, Boston 12.10, **-2.70**. The user caught the original
Gordon/Tate framing on the grounds he faced a top defence, which triggered the slope rebuild —
good instinct, and the slope is real; it just cannot pick between two players. One
player-week is not what killed the rule. **The 215-pair test is.**

## 2026-10-27 — band widened 5% -> 15%

Different question from the spread test. That asked: does anything *beat* raw order inside
5%? This asks: is raw order *itself* informative between 5% and 15%? Pre-registered wk6 retro
§R4 (2026-10-20), carried in wk7 log §3.1: **5-15% band under 55% at n >= 200 decided ->
dead band widens to 15%.**

Harness `dev/weekly/leaguewide_retro.py --pool 4:2026-10-01:2026-10-05 5:2026-10-07:2026-10-13
6:2026-10-14:2026-10-20 7:2026-10-21:2026-10-27`. Within-roster RB/WR/TE pairs, all 10
rosters, wks 4-7: does the higher Yahoo projection outscore the lower?

| gap band | pairs | decided | higher proj right | 95% CI | mean pts |
|---|---|---|---|---|---|
| ALL | 1,885 | 1,835 | 1,223 (66.6%) | [64.5, 68.8] | +4.29 |
| <= 5% | 137 | 136 | 76 (55.9%) | [47.5, 64.2] | +1.55 |
| **5-15%** | 319 | **314** | 164 (**52.2%**) | **[46.7, 57.8]** | +0.88 |
| > 15% | 1,429 | 1,385 | 983 (71.0%) | [68.6, 73.4] | +5.33 |

**Fires as registered: 52.2% at n 314.** Wk6 alone 46.6% (n 58), wk7 alone 51.5% (n 68).

CI top 57.8 still reaches past the 55% bar — rule written on the point estimate, scored as
written. Band not proven worthless, only not proven useful. Mean edge +0.88 pts/pair, sign
still positive -> **pick unchanged**: higher raw projection starts. What changes: pairs under
15% stop being decisions. No kill condition, no retro verdict, no tiebreak hunt (spread,
usage, hedge, matchup).

Cliff at 15%: 52-56% below, 71% above. Same arithmetic as above — a 5-15% gap is 0.5-1.5 pts
on a 10-pt player against ~8-9 pts of pair noise.

Revisit: pooled rerun at season end. No mid-season trigger.
