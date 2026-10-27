# Lineup layer at its ceiling: leverage is roster quality + the two streaming slots

Four weeks of start/sit work raised the question: is the weekly lineup where points are lost?

Decided (2026-10-06): **do not spend session time on start/sit between two rostered
players** — read the projection and move on (ADR 0009). Spend it on the wire, trades, and the
two free streaming slots (K, DST). Keep logging regret — it measures the projection, not us.

## Evidence

`dev/weekly/proj_vs_choice.R`, weeks 1-4: what we started vs the projection-optimal lineup vs
the hindsight optimum.

| | 4-wk total |
|---|---|
| started | 456.12 |
| projection-optimal | 456.92 |
| hindsight-optimal | 530.54 |
| regret from **our deviations** | **+0.80 (1%)** |
| regret from **projection error** | **+73.62 (99%)** |

**Four weeks of start/sit work cost 0.80 points — 0.20/wk.** We follow the projection
near-perfectly already; 99% of the 74.42 regret is the projection being wrong, which we cannot
fix. The pooled positional leak (WR 46.90, QB 23.52, K 12.00, DEF 0.00, TE 0.00) therefore does
**not** mean we benched the right WR — it means the projection could not say which WR would
hit. TE leaking zero is the same artifact inverted: 1-deep means there was never a choice to
get wrong, so the "TE hole" had cost nothing to that date.

For scale, week 4: lineup error **27.10**, roster error **66.76**.

**Considered and rejected**: more start/sit modelling — the ceiling above is 0.80 pts over
four weeks.

## Follow-on, 2026-10-21: low regret is not surplus

League-wide (`ceiling_vs_margin.R`, wks 3-6): our actual-minus-ceiling gap −4.8 ≈ league mean
−3.88. Near-zero regret avoids loss; it buys no surplus. Best in league: Owl Out Blitz +13.8
(SE 5.3). Season objective is wins, not points — price roster moves in wins
(`dev/weekly/playoff_odds.R`).
