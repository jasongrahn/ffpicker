# Yahoo projection for start/sit; usage trend for the wire and the drop; never ppg

Three sources compete for every roster call: Yahoo's weekly projection, our opportunity
(usage) analysis, and season ppg. Two costly mistakes forced the split below.

Decided:
- **Start/sit between two rostered players: read the Yahoo projection and stop.** It is the
  best one-week point estimate available to us. Do not override it with our own numbers.
- **Opportunity / snap-share analysis has three jobs, and start/sit is not one of them:**
  (1) rank the wire, where projections are thin or absent; (2) catch a role change the
  projection has not absorbed yet — a backfield vacated mid-week, a rookie taking over a
  route tree; (3) **choose the drop**, a question about future role, not this week's points.
- **ppg never ranks a roster.** It embeds exactly the efficiency the core principle says to
  regress, so it mis-ranks your own bench in both directions at once.
- **Need before candidates; a handoff doc is a prior claim, not a source.** Cost cases below.

## Evidence: projection benchmark, 2026-10-06

`dev/weekly/proj_benchmark.R`, week 4, 221 startable players. MAE: Yahoo **4.29**, opportunity
x position rate 6.71, season ppg 7.32, last week only 7.70. Paired t-test vs the best baseline
**-2.42, p < 0.0001**, CI [-3.22, -1.63]. Yahoo wins at every position (QB 3.50 vs 7.18, RB
4.29 vs 6.51, TE 4.29 vs 4.95, WR 4.69 vs 7.25). **Season ppg is the worst non-trivial
baseline** — the Sutton/Raymond error quantified.

## Cost case 1: the drop, 2026-10-06 (Sutton vs Raymond)

Handoff #36 called **Sutton** the drop at 3.28 ppg, "worst on roster by 2.5x," and a session
relayed it. The real drop was **Raymond** at 9.63 ppg — snap share **60/62/75/51**, third in
the CHI room behind rookie Luther Burden III, 91% catch rate on aDOT 5.7 that regresses
*down*. Sutton held **73-87%** snaps and a 5.5 tgt/g #1 boundary role at aDOT 11.5 on a
**41%** catch rate that regresses *up*. Yahoo's own wk5 projections had them 8.96 vs
**5.71**. Identical byes (CHI and DEN both wk10), so byes did not discriminate — usage did.
**The user caught this, not the analysis.**

Same handoff, same error: #36 §4's FLEX line (Raymond 9.62 / Odunze 7.58) was **season ppg,
not a week-5 projection**, so its "we trail by 1.61" figure inherited the ppg error. -> A
handoff doc's rankings, drop candidates, projections and ppg figures come from data that has
since moved, by the reasoning now under review. Re-derive before acting. Same failure shape as
treating `load_schedules()` output as fact rather than a snapshot.

## Cost case 2: the need, 2026-09-29

Ranked the FA pool, saw Etienne/Marks with falling opportunity, called RB the hole with a
Week 8 double-bye argument. Wrong — Henry + J. Williams covered both RB slots and FLEX came
from six WRs. Real holes: **K (wk5, zero kickers)** and **TE (1-deep at the time, zero in
wk14)**. The user: "I have 4 RBs right now already. Is that _MY_ hole?" The bye computation
that disproved it was one call away. Same session, same root error twice more — asserting from
the nearest number instead of the authoritative one: a VOR table whose replacement baseline
was the median of 280 mostly inactive players, and a roster read off a stale `_myteam.csv`
still listing three reversed moves.

## Snaps before ppg, third catch, 2026-10-21

McLaurin (W, base projection 9.85) topped the wire in the league-wide sim. Status `O`/knee,
snaps 75 -> 58 -> 10. A base projection cannot see a fresh injury; the snap series can.
