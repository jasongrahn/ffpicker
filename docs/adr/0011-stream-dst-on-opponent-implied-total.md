# Stream DST on opponent implied total; K on own implied total

K and DST: one roster spot each, no opportunity cost, both slots forced — so a matchup swap
costs nothing but the claim. **DST scoring is dominated by points allowed**
(`config/scoring.json` tiers: 0 allowed = 10, 1-6 = 7, 7-13 = 4, 14-20 = 1, 21-27 = 0).

Decided: rank DST candidates by **opponent implied total** (`total/2 - spread/2`), lowest
first. Rank kickers by **own implied total**, highest first.

## Evidence, DST — validated league-wide 2026-10-06. No longer under test.

All 32 teams, weeks 1-4, **n=128** team-weeks, DST points derived from `load_team_stats()` +
`config/scoring.json` tiers. Harness `dev/weekly/dst_test.R`.

- opponent implied total -> DST pts: **r = -0.275, p = 0.0017**, CI [-0.428, -0.107]
- own implied total -> DST pts: r = -0.021, **p = 0.81** — correctly irrelevant, which
  confirms we rank on the right side of the line
- edge **+1.92 pts/wk** over a random DST; within-week Spearman +0.308

**Considered and rejected**: lowest quartile scoring below the second — noise (p = 0.291);
game total on top of opponent implied total — adds nothing (coef p = 0.200). Rank on
opponent implied total alone.

Ceiling: opp_implied explains only **7.6%** of DST variance — the rest is turnovers and
return TDs, not forecastable. The edge is **0.39 sd**, so the rule will look wrong in
individual weeks and still be right. **Do not kill it on a bad week**; the >3 pt kill bar is
retired for DST.

## K side: untested

No league-wide K harness yet. The K rule rests on reasoning only.
