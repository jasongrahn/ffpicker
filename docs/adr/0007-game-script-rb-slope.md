# Game script: RB slope from the spread; WR and QB flat

Question: does the Vegas spread move fantasy points, and for whom? Measured on 2024-25
starter-calibre player-weeks, scored as points **relative to each player's own season
average** so player quality cancels out. Harness `dev/weekly/mult_measure.R`, rerunnable.

Decided (2026-10-07): RB multiplier = `1 + 0.00799 * favouredness`. WR and QB get **1.0**; do
not apply a WR multiplier at all, in either direction. Use the slope to describe and report an
RB's expected week — **never as a start/sit tiebreak** (ADR 0008). Kill condition:
`mult_measure.R` 2026 rerun at season end.

| position | n | slope / pt of spread | p | implied at 7-pt dog |
|---|---|---|---|---|
| **RB** | 779 | **+0.00799** | **0.0109** | **0.944** |
| WR | 1132 | -0.00129 | 0.679 | ~1.00, flat |
| QB | 398 | +0.00562 | 0.102 | ~1.00, flat |

RB-vs-WR interaction coefficient **-0.00928, p = 0.0406** -> the two positions genuinely
respond differently. Strongest game-script evidence in the log. Slope is linear -> **extends
past the measured buckets** — why it replaced them: the old table stopped at dog 3-7 and had
nothing to say about a 7-point dog, exactly the wk5 case (Gordon II, MIA -7.0).

**Considered and rejected**: the 2026-09-23 bucket table (below). Buckets run n=24-40 per
cell; **only 1 of 22 cells significantly different from 1.0** (RB fav3-7, 1.081, CI [1.013,
1.148]). Published WR fav3-7 1.059 did not survive the rebuild (came back 1.006) — noise.

## Bucket table, 2026-09-23. Reference only.

| position | dog 3-7 | fav 0-3 | **fav 3-7** | fav 10+ |
|---|---|---|---|---|
| RB | 0.945 | 1.036 | **1.078** | 1.134 |
| WR | 0.975 | 0.935 | 1.059 | ~1.00 |
| QB | — | 0.939 | 1.028 | **1.120** |

- **RB is the position that cares.** Leading teams run to kill the clock. Back on a 3-7 point
  favorite = peak bucket; on a 3-7 point dog he loses ~5%.
- **WR flat across every bucket.** Trailing teams pass more, offsetting lost possessions ->
  "his team is an underdog" is **not** a reason to bench a receiver, and being on a favorite
  is not a reason to start one. Let the projection decide.
- **No blowout tax.** QBs favored by 10+ score **1.120x** own average (n=37); RBs favored 13+
  hit 1.311 (n=24). A big spread mostly means a **bad opponent**, outweighing the risk of
  resting starters late. Killed a "Mahomes' ceiling is capped at -11.5" argument that was
  about to become advice.
- High game total helps RBs (47+ -> 1.061 vs 0.939 at 41-44).

## Backtest on our own rosters, 2026-10-06. Inconclusive by construction.

Harness `dev/weekly/mult_backtest.R`, rerunnable, all four frozen `_myteam.csv` /
`_opponent.csv` files, both rosters, n=45 player-weeks. MAE 6.444 raw -> 6.595 adjusted, delta
**+0.151**, 95% bootstrap CI **[-0.084, +0.397]**, p=0.226. No sign error, no bucket
mis-assignment — the only things n=4 weeks could have caught. A multiplier moves a projection
~5%, ~0.60 pts on a typical 12-pt projection, against per-player-week error of **6.44** ->
signal:noise ~1:10; resolving it needs ~1,000 player-weeks. **The table was measured on
2024-25 league-wide data — the right instrument. Our weekly logs are not. Do not score "do the
multipliers work" in a retro.**

Double-counting checked, not found at the time: Pearson(favouredness, Yahoo proj / own ppg) =
+0.129, n=39 -> Yahoo does not visibly price the spread, so applying ours is not #33's "one
source counted twice". Re-run at n=190 in ADR 0008: r = -0.036 — the +0.129 was noise; the
conclusion held.

What the backtest *did* establish: **decision impact is 2.3%** — 5 of 220 FLEX-eligible pairs
reordered across wks 1-4. The adjustment only changes a choice when two players sit within ~5%
of each other. Same shape as the QB cliff: a half-point line move swinging a number 9.5% is
not measuring anything.
