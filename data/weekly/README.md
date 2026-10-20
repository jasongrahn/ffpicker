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

## Decision log — second file per week, from Week 2 on

`2026_week{NN}_decisions.md`. Written **before first kickoff, frozen at kickoff**,
retro appended below a line that is never edited.

Why: regret scores the *lineup*. It cannot score the *reasoning*. Week 1 notes were
written post-game, so every rationale in them is reconstructed and unfalsifiable.

Each decision records call -> reason -> **kill condition** stated up front. Kill
condition must be a result that proves the reasoning wrong, not merely a bad score.
Wk1 is the proof they differ: Mahomes-over-Stafford was worth 0.35 pts ex-ante and
17.56 ex-post. Right process, wrong outcome. Log both, never collapse them.

Also log contrarian calls explicitly (`% started` vs our call) — those are the only
ones where being right is informative.

## Cases so far

| week | result | started | optimal | regret | opp |
|---|---|---|---|---|---|
| 1 | L vs Bone Crushers | 101.80 | **121.56** | **19.76** | 118.96 |
| 2 | **W** vs Sunday Kevin | 152.58 | **155.08** | **2.50** | 112.08 |
| 3 | **W** vs Maybe Mitchell | 108.74 | **133.80** | **25.06** | 96.70 |
| 4 | L vs Jason's Jazzy Team | 93.00 | **120.10** | **27.10** | 98.58 |
| 5 | **W** vs Max's TD Bombers | 107.02 | **130.32** | **23.30** | 100–106.4 (est) |

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

## Week 3 notes

**Won by 12.04 while leaving 25.06 on the bench.** Worst regret of the three weeks, in a
week we won. Opposite of Week 1, where the decisions were defensible and the result was a
loss. Won because the opponent missed projection by **-20.24**, not because the lineup was
good — we beat our own projection by only +4.75.

Three of four live choices wrong: QB (Stafford 22.90 benched for Mahomes 16.94), WR2
(Raymond 18.00 benched for Sutton 6.10), FLEX (Robinson 15.20 benched for Etienne 8.00).

**Structural finding, not a start/sit error.** Two benched pass-catchers outscored two of
three starting receiver-eligible slots. Raymond/Robinson/Odunze/Sutton target counts are
converging (9-5-7, 5-4-7, 3-4-6). The WR/FLEX depth chart is mis-ranked and Yahoo's
projections are not separating these players.

**Streaming test (D6) split, net +3.00.** DST worked as theorised: Chiefs 8.00 vs dropped
Patriots **-1.00**, because Jacksonville hung 35 on New England and points-allowed tiers
dominate DST scoring — the exact mechanism the bet was placed on. Kicker lost: Butker 6.00
vs dropped McLaughlin 12.00, who has now beaten his projection three weeks running.
Compound kill bar (**both** by >3) not met, so the method stands. Halves should be scored
separately from Week 4 on.

**QB call now wrong in both directions**, -17.56 in Week 1 and -5.96 in Week 3, combined
**23.52**. Both times the projection was followed. Largest recurring leak.

`score_player_week()` reproduced all 9 Yahoo starter scores exactly. Validation **35/35**
across weeks 1-3. DST still hand-scored from `config/scoring.json`.

## Week 5 notes

**Won, barely. Regret 23.30, and 88% of it is projection error.**

```
started               107.02
projection-optimal    109.72   -> regret from OUR deviation    +2.70  (12%)
hindsight-optimal     130.32   -> regret from projection error +20.60 (88%)
```

Cumulative deviation regret **3.50 over 5 weeks (0.70/wk)**, up from 0.80 over 4. The
entire increase is one deviation: Boston over Gordon II on the spread tiebreak.

**`opp` is a range, not a number.** Yahoo's export carries no started/bench flag and no
opponent CSV was frozen pre-kickoff. Max's TD Bombers had 84 legal lineups (D. Smith ruled
out, Walker on bye); **47 lose to 107.02**. Their projection-optimal lineup scores only
95.64 — it benches Likely's 26.90. `2026_week05_opponent.csv` ships `slot = UNK` for all
15 rows. **Do not back-fill it by guess.** Loop step 2 — freeze both lineups *before*
kickoff — is what prevents this; it was skipped in week 5.

**The spread tiebreak was retired this week by a powered test.** Harness
`dev/weekly/spread_tiebreak_leaguewide.R`. All 10 rosters, weeks 4-5, 215 decidable
discordant within-5% pairs: the spread-adjusted pick is right **48.8%**, CI
[0.420, 0.557]. Not double-counting either — Pearson(favouredness, Yahoo proj / own ppg)
= -0.036 at n=190. See `2026_week05_decisions.md` §R2. The slope itself survives; using it
as a tiebreaker does not.

**DST streaming held league-wide** (n=30, r = -0.334, p = 0.071) while our own pick
returned 2.00. Decision right, outcome bad — the 0.39-sd edge behaving as predicted.

## Week 6 — regret **3.40** (lowest in the league, and that is luck)

```
started               91.68
projection-optimal    91.68   -> regret from OUR deviation    +0.00  (0%)
hindsight-optimal     95.08   -> regret from projection error +3.40  (100%)
```

Cumulative deviation regret **3.50 over 6 weeks (0.58/wk)** — unchanged from week 5. We
started the projection-optimal lineup exactly.

**New this week: the same regret computed for all ten rosters.** Harness
`dev/weekly/leaguewide_retro.py 6 2026-10-14 2026-10-20`. Each team scored *as if it had
followed the Yahoo projection*, which makes the numbers comparable. Range **3.40 (us) to
38.70**, mean 16.08, sd ~11, over ten rosters running the identical rule.

**-> A single week's regret measures the roster's projection error, not the manager.**
Ours was lowest because Henry -11.49 and Boston -7.81 cancelled against Tate +6.13,
Chiefs +7.25 and Butker +4.63. Stop reading a low weekly regret as a good week. Roster
quality is the comparable number: our projection-optimal 108.72 vs league mean 109.22 —
dead average.

**S1/S2 at scale, first powered look.** 427 within-roster RB/WR/TE pairs: the higher
Yahoo projection is right **67.6%** above a 15% gap (CI [62.5, 72.6], n=330) and
**46.6%** in the 5-15% band (CI [33.7, 59.4], n=58, mean **-1.17 pts**). The dead band
may be wider than 5%. **Not actioned** — the spread tiebreak needed 215 discordant pairs
to die. Pool wks 4-7, revisit week 8. Detail in `2026_week06_decisions.md` §R4.

**Yahoo projection error ran -1.79 low at every position** (n=135, MAE 5.23). One week,
uniform sign across six positions. Re-check wk7.

Conditions: **A4 PASS** (Strange 76% snaps), **W3 PASS** (Tate 7 tgt, 16.00 — the drop
case is void). S1/S2/D10/H1 logged as deposits, not verdicts.

**`opp` is again a replay, not an observation.** Owl Out Blitz's frozen Wed lineup scores
**106.54**; 408 of their 1,440 legal lineups beat our 91.68. They never filled the empty
bench slot §6c flagged — opponent headroom is an upper bound, not an expectation.

**CORRECTION, same day.** Final confirmed: **91.68 - 111.14**, lost by 19.46. The 106.54
above is a replay of their Wednesday lineup and is wrong. **111.14 is unreachable from
their Monday roster** — they streamed a 16th player and dropped him Sunday night; 19
candidates fit and none is identifiable. A post-game export cannot show an add-and-drop
inside the same week, so **streaming is invisible in arrears by construction** — same
class of defect as the missing started/bench flag, same fix: observe before kickoff.

This also caps R3's claim. Owl Out Blitz's projection-following counterfactual says 83.90
and regret 29.64; they actually scored **111.14**, beating the counterfactual by
**+27.24** with a regret of at most 2.40. **Do not rank teams by that column** — it
measures rosters under a rule nobody is known to follow. Our own 3.40 is observed and
stands. Detail: `2026_week06_decisions.md` §R8-R9.
