# Weekly actuals — backtest cases for the start/sit picker

One file per week: `2026_week{NN}_myteam.csv`. Whole roster, starters and bench,
projection and actual. Source = Yahoo matchup page, hand-entered.

Point: picker must beat **what was actually started**. Bench rows are the
counterfactual. Without them there is no bar.

## Columns

| col | note |
|---|---|
| `slot` | Yahoo lineup slot. `BN` = bench. |
| `started` | TRUE for the 9 that scored. |
| `proj` | Yahoo projection at lock, not preseason. |
| `actual` | Yahoo half-PPR final. |

## Metric

`regret = (best legal lineup from full roster) - (lineup actually started)`.
Picker earns its keep only if it closes regret across many weeks, not one.

## Cases so far

| week | result | started | optimal | regret | opp |
|---|---|---|---|---|---|
| 1 | L vs Bone Crushers | 101.80 | **121.56** | **19.76** | 118.96 |

## Week 1 notes

Optimal lineup beats the opponent by 2.60. Two swaps, nothing else:

| swap | gain |
|---|---|
| Mahomes 22.66 over Stafford 5.10 | **+17.56** |
| W. Robinson 6.30 over Adams 4.10 | +2.20 |

Mahomes alone flips the result: 101.80 + 17.56 = 119.36 > 118.96. Swap was legal —
Stafford locked Thu 9/10 20:35, Mahomes played Mon 9/14.

**This week is NOT evidence a picker helps.** Yahoo projected Stafford 18.06 vs
Mahomes 16.39. Handoff #26 checked that swap and priced it at 0.35 pts. A picker
maximizing projected points makes the same wrong call. Ex-ante correct, ex-post wrong.

**The one learnable signal — same-game correlation.** Stafford and Adams were both
LAR vs SF. Rams lost 7-27. Two starting slots, one game script, both of them the
bad ones. Required picker feature: penalize stacking non-QB/WR-correlated players
in a single game, or at minimum surface the exposure. Nothing else this week is
distinguishable from variance.

Kicker note: McLaughlin 11.00 on proj 7.03, second week running he beats his number.
Not signal yet. Revisit at week 4.
