# Week 5 Decisions — 2026, JGrahnasaurs (2-2)

Opened 2026-10-06 Tue. Opponent: **Max's TD Bombers (1st in league)**.
Frozen before Wed 10-07 waiver run. Nothing below the `## Retro` line edited after.

Source of record: `docs/uploads/week_5_data/*_2026-10-06.csv` (Yahoo), plus
`load_player_stats(2026)` / `load_snap_counts(2026)` re-pulled 10-06.

---

## 00. METHOD CORRECTION. Read before trusting handoff #36.

**#36 ranked the roster by ppg and named the wrong drop.** It called Sutton the drop at
3.28 ppg, "worst by 2.5x." Wrong player. ppg embeds the efficiency the project's core
principle says to regress, so it mis-ranks a bench in both directions at once.

| wks1-4 | tgt/g | snap % 1→4 | aDOT | catch % | yd/tgt | ppg |
|---|---|---|---|---|---|---|
| Sutton | 5.50 | 76/73/87/**73** | 11.5 | **0.41** | 3.91 | 3.28 |
| Raymond | 5.75 | 60/62/75/**51** | 5.7 | **0.91** | 9.57 | 9.63 |

Raymond is **third in the Chicago room** behind Odunze (89%) and rookie Luther Burden III
(56%), no injury row in `load_injuries(2026)` — role loss, not a bruise. His 91% catch
rate on aDOT 5.7 regresses down. Sutton holds a stable #1 boundary role on a 41% catch
rate that regresses up. Yahoo's own wk5 projections: Sutton 8.96, Raymond **5.71**.

**The user caught this, not the analysis.** Rules written into `CLAUDE.md` as a result:
drop is ranked by snap share and target trend, never ppg; a handoff doc is a prior claim,
not a source.

Second consequence: #36 §4's FLEX line (Raymond 9.62 / Odunze 7.58) is **season ppg, not
a week-5 projection**. The "we trail by 1.61" figure inherits the ppg error.

---

## 1. Roster moves. Three waiver claims, submitted 10-06, process **Wed 10-07**.

All unowned players in this league read `W (Oct 7)` — 121 QB / 217 RB / 407 WR / 222 TE /
45 K / 27 DEF in the 10-06 export. **There is no free-agent pool.** Nothing is addable
without a claim. Priority 9 of 10; a win moves to 10, so stacking costs ~nothing and
claim order is not worth optimising.

### W1. Add **Bengals DST**, drop **Kalif Raymond**.

Ravens opponent implied total wk5 is **23.50 — worst of all 27 available DSTs.** Bengals
@ Mia is **17.75, lowest in the league**, tied with Jacksonville.

Tiebreak is *variance of opponent realised scoring*, not opponent defensive quality —
defensive quality is already priced into the implied total (#33's "one source counted
twice"). Miami scored 10/10/13/13 → tier payout 4/4/4/4, mean **4.00**. Philadelphia
7/20/24/24 → 4/1/0/0, mean 1.25.

**Byes are complementary: Bengals 6, Ravens 13.** Carrying both closes the wk13 zero-DST
hole. `roster.max_at_position` saying `DST: 1` is our own draft-time cap, not a league
rule — we already carry two kickers.

**Correction to #36's queue:** it listed Jets second. Jets bye = **13, same as Ravens** —
fails the wk13 test. Correct fallback order is Jaguars (bye 7) then Commanders (bye 7).

**Kill condition:** Bengals opponent implied total > 21.0 in any future week → stream off
them, do not hold on name. Scored weekly, not once.

### W2. Add **Ollie Gordon II** (RB, Mia), drop **Woody Marks**.

**De'Von Achane is on IR, knee, ACL** (`yahoo_week5_injuries_2026-10-06.csv`). Season
over. Gordon inherited the backfield.

| opportunities | wk1 | wk2 | wk3 | wk4 | opp/g | trend |
|---|---|---|---|---|---|---|
| Achane | 16 | 26 | 4 | **IR** | — | — |
| **Gordon II** | — | 3 | **20** | **11** | 11.33 | **+12.5** |
| Marks (dropped) | 10 | 14 | 6 | 7 | 9.25 | **−5.5** |

Largest positive trend in the entire available pool. The ACL makes the role durable, not
a one-week fill-in.

**Kill condition:** Gordon under **10 opportunities in each of two consecutive weeks**
→ drop. Two weeks, not one — single player-weeks broke D3 and GD1.

**Accepted cost:** RB room becomes Henry / Javonte / Gordon, three bodies for two RB
slots. Depth, not a hole, but any Henry or Javonte injury forces a wire RB.

### W3. Add **Carnell Tate** (WR, Ten), drop **Wan'Dale Robinson**.

| TEN targets | wk1 | wk2 | wk3 | wk4 | opp/g | snap % 1→4 |
|---|---|---|---|---|---|---|
| **Tate** | 6 | 5 | 9 | **12** | 8.00 | — |
| Robinson (dropped) | 6 | 1 | 11 | 6 | 6.00 | 82/53/63/**67** |

Four straight weeks rising — a multi-player-week signal, not a spike. Same offense, so
holding both double-bets one target pool; Tate's rise comes out of Robinson's share.
Robinson's 6.00 opp/g is one wk3 outlier.

**Bye-neutral.** Both TEN, bye 9. wk10 and wk11 WR counts unchanged at 3 bodies.

**Kill condition:** Tate under **6 targets in each of two consecutive weeks** → he is the
drop for the next claim.

### W-HOLD. **Butker is not droppable.** Butker bye 5, Bates bye 6 — complementary.
Dropping him recreates the Week 1 zero-kicker failure (#24). Recorded because the advice
has been wrong on this twice before.

---

## 2. Lineup. Nine slots. Settled except FLEX and DST, both waiver-dependent.

Script multipliers from the CLAUDE.md game-script table, applied to our own ppg base.
**K and DST excluded from every total below — `score_team_week()` does not exist.**
Skill slots only, 7 of 9. Not comparable to Yahoo's number.

| slot | start | basis |
|---|---|---|
| QB | **Stafford** | forced, Mahomes on KC bye. LA −3.0 → QB fav 3-7 **1.028x** |
| RB1 | **Henry** | 3.5-point **dog** → RB dog **0.945x**, 21.82 → **20.62**. Worst script of any RB on either roster |
| RB2 | **Javonte** | DAL −8.5, own implied 28.00, RB fav 3-7 **1.078x** |
| WR1 | **Adams** | 15.50 |
| WR2 | **Boston** | 12.22 |
| TE | **Ferguson** | 1-deep. See §4 |
| FLEX | **pending Wed** | Tate 9.81 / Gordon 9.80 / Odunze 8.62 (Yahoo wk5). Decided by W2/W3 |
| K | **Bates** | Butker on KC bye |
| DST | **pending Wed** | Bengals if W1 lands, else Ravens (opp implied 23.50) |

### D-SPREAD. **Stafford sits 0.0 off a multiplier cliff. Flagged, not resolved.**

LA moved −2.5 → −3.0. **QB fav 0-3 = 0.939x; QB fav 3-7 = 1.028x** — a 9.5% jump on a
half-point. Stafford went 15.88 → 17.38 with nothing real changing. If the line moves back
inside 3, his number falls ~9.5%. **Do not quote his adjusted number to two decimals.**

Cliff edges: **QB at 3 and 10. RB at 0, 3, 10, 13. WR has none — flat across every
bucket.**

### D-WR-SCRIPT. **No WR is benched for being on a dog.** Robinson's TEN was a 7.5-point
dog before the drop; WR is flat across all spread buckets. That is a projection question,
never a script question.

---

## 3. Head-to-head. We trail. Re-run on complete lines 10-06.

| | ours | Max's TD Bombers |
|---|---|---|
| QB | Stafford 17.38 | Prescott 21.13 |
| RB1 | Henry **20.62** | Taylor 19.18 |
| RB2 | Javonte 20.03 | Jeanty 15.21 |
| WR1 | Adams 15.50 | D. Smith 13.00 |
| WR2 | Boston 12.22 | Deebo 12.72 |
| TE | Ferguson 7.58 | Likely 10.50 |
| FLEX | pending | Washington 10.78 |
| **total, skill only** | **~100.9–102.1** | **102.52** |

Structural reads: KC bye costs us Mahomes; Chicago targets are contested between Odunze
and Burden III; nothing on their roster is defensible against.

---

## 4. Open hole, not yet acted on: **TE.**

**Ferguson is at 3.75 opp/g — below the ~5 opp/g bar this project sets for even ranking a
wire body.** He is our only TE and Dallas byes in **wk14**.

T.J. Hockenson is available: 6.50 opp/g, trend +4.0, 9.12 ppg, bye 6. Not claimed this
week — his edge leans on a 13-opportunity wk4 spike, **n=1**, which is exactly the leg
that broke D3 and GD1.

**Pre-registered:** if Hockenson clears 8 opportunities again in wk5, claim him wk6 and
drop Sutton or Odunze, whichever has the lower snap share at that point.

---

## 5. Deadlines. Per slot: `min(kickoff of legal replacements)`.

| due | slot | why |
|---|---|---|
| **Wed 10-07** | waivers | claims process. No Wednesday NFL game exists in wk5 |
| **Thu 10-08 20:15** | RB2, TE | TB @ DAL — Javonte + Ferguson. Both auto-start; any reversal dies here |
| **Sun 09:30** | QB, WR1, DST | Stafford and Adams play Mon 20:15, but every legal replacement plays Sunday. PHI @ JAX is the 09:30 London game |
| Sun 13:00 | FLEX, WR2 | CHI @ GB, CLE @ NYJ |
| Sun 16:25 | K | DET @ ARI |
| Sun 20:20 | RB1 | BAL @ ATL — Henry. Latest on roster |

---

## 6. Byes ahead. Two real crises.

| wk | off | consequence |
|---|---|---|
| 6 | Bates | covered **only if Butker kept** |
| 8 | Etienne (IR) | no impact |
| 9 | Tate | WR room to 3 |
| **10** | **Odunze, Sutton** | WR falls to Adams, Boston, Tate — exactly 3 for WR1/WR2/FLEX |
| **11** | **Stafford, Adams, Boston** | Mahomes covers QB. **WR1 and WR2 both out.** Worst week of the season |
| 13 | Henry, Ravens | **DST covered iff W1 landed.** RB to Javonte + Gordon |
| **14** | **Javonte, Ferguson** | **zero TE.** See §4 |

---

## 6a. Method tests live this week. Score these in the retro.

Player kill conditions are in §1. These are the **method** trials — what a result teaches
beyond this week's roster.

| # | method under test | bar | week |
|---|---|---|---|
| 1 | DST streaming by **opponent** implied total | Ravens beat Bengals by >3 → strike | 3rd scored. Not fired wks 3, 4 |
| 2 | **Snap share and target trend outrank ppg** for naming a drop | Raymond outscores Sutton across wks 5-7 → the new rule is wrong | **1 of 3. New, out-of-sample** |
| 3 | D9, carried: Boston < Sutton wks 4-8 | — | 2 of 5. wk4 was 10.90 vs 0.90 |

Test 2 is the only one where a rule changed *because* of a measurement and is now exposed
to new data. It matters more than the other two.

### **The K rule change is NOT testable this week. Do not score it as a pass.**

Week 4's retro re-denominated the kicker hold bar in **own implied total** instead of
projected points — correct, and worth 18.00 forgone points across wks 3-4. Testing it
needs two live kickers to choose between:

- **wk5: Butker on KC bye** → forced to Bates
- **wk6: Bates on DET bye** → forced to Butker

**First real test is week 7.** A forced start is not evidence the rule works. Recorded
here so neither retro can read it as a passing week.

### Game-script multipliers: BACKTESTED 2026-10-06. Inconclusive by construction.

Ran it. Harness `dev/weekly/mult_backtest.R`. All four frozen `_myteam.csv` /
`_opponent.csv` files, wks 1-4, both rosters, n = **45** player-weeks the multipliers
touch (QB/RB/WR in a listed bucket). Spread matched 85/85.

| | raw | adjusted | delta |
|---|---|---|---|
| MAE | 6.444 | 6.595 | **+0.151** |
| RMSE | 8.449 | 8.483 | +0.034 |
| adjusted closer | — | — | 21 of 44 |

95% bootstrap CI on the MAE delta **[−0.084, +0.397]** — straddles zero. Paired t-test
**p = 0.226**. Pre-registered claim was that n=4 weeks could catch a **sign error or a
bucket mis-assignment, nothing more**. It found neither: bucket-level agreement between
multiplier direction and realised direction is 3 of 7 cells with n>=3, scattered across
positions rather than uniformly flipped. That is a coin flip, i.e. no detectable signal —
not evidence the table is wrong.

**This question cannot be answered from our logs, ever.** A multiplier moves a projection
~5%, about **0.60 pts on a typical 12-pt projection**, against per-player-week error of
**6.44**. Signal:noise ~1:10. Narrowing the CI to ±0.05 needs ≈ **1,000 player-weeks**, or
25+ weeks of both rosters. The table was measured on 2024-25 league-wide data with
thousands of player-weeks — the right instrument. **Retire "do the multipliers work" as a
retro question.** Same failure shape as `single-seed-bars-underpowered`.

Double-counting checked and **not found**: if Yahoo's projection already priced the
spread, applying ours on top would be #33's "one source counted twice". Pearson
(favouredness, Yahoo proj / own ppg) = **+0.129**, n=39 with a ppg>=5 floor — not clearly
positive. No evidence Yahoo prices game script into these numbers.

### What the backtest DID establish: decision impact is 2.3%.

The useful question is not accuracy, it is whether the adjustment ever changes a choice.
Across every FLEX-eligible pair on our roster, wks 1-4: **5 of 220 pairs reordered
(2.3%)**.

```
wk1  Odunze   9.51 -> 10.07  vs  Gainwell 10.44 -> 9.87
wk2  Sutton   8.98 ->  8.40  vs  Odunze    8.64 -> 9.15
wk2  Gainwell 8.01            vs  Marks     7.44 -> 8.02
wk4  Ferguson 6.87            vs  Raymond   6.49 -> 6.87
wk4  Robinson 7.85            vs  Marks     7.78 -> 8.39
```

A multiplier only changes a decision when two players sit within ~5% of each other.
**97.7% of the time it moves a number we report without moving a choice we make.**

**Rule adopted, wk5 on:** when a start/sit gap is under ~5%, the multiplier is **not** the
tiebreaker — it is noise at the same scale as the gap. Break the tie on usage. Same shape
as the Stafford cliff in §2: a half-point line move swinging his number 9.5% is not
measuring anything.

### Data defect found and repaired during the backtest.

`data/weekly/2026_week04_opponent.csv` carried a **stray empty 11th column**, so `actual`
sat in field 12 and any name-based reader returned NA for every opponent actual. Removed.
Starters now sum to **98.58**, matching the Week 4 retro exactly — the retro number was
right, the file was wrong. Backup taken before the edit.

---

## 7. Explicitly NOT being learned this week

- Whether the DST streaming method works. n too small; bar deliberately loose.
- Anything about Gordon from one week of Achane being out.
- Any model fit. **n = 5. Fit nothing.** These logs are honest test cases, not a
  training set.

---

## Retro

*Append after Monday 10-13. Never edit above this line.*
## §6b Method-test results, run 2026-10-06

Three tests, all complete. Harnesses: `dev/weekly/dst_test.R`,
`dev/weekly/proj_benchmark.R`, `dev/weekly/regret_decomp.R`,
`dev/weekly/proj_vs_choice.R`, `dev/weekly/roster_error.R`. All rerunnable.

### Test 1 — DST streaming rule. VALIDATED.
League-wide, all 32 teams, weeks 1-4 = **128 team-weeks**. DST points derived
from `load_team_stats(2026, summary_level="week")` + `config/scoring.json`
tiers (`score_player_week()` is per-player only).

| signal | r with DST pts | p | 95% CI |
|---|---|---|---|
| **opponent implied total** | **-0.275** | **0.0017** | [-0.428, -0.107] |
| own implied total | -0.021 | 0.81 | [-0.194, +0.153] |

- Rule edge **+1.92 pts/wk** over a random DST. Captures 41% of weekly best.
- Within-week Spearman(opp_implied, -dst_pts) = **+0.308**.
- `own_implied` is correctly irrelevant -> we are ranking on the right side
  of the line. This is the first statistically significant result in the log.
- q1 mean (6.12) < q2 mean (7.44) looked non-monotonic. **Noise**, p = 0.291.
- Game total adds nothing on top of opp_implied (coef p = 0.200, adj R2
  0.0685 -> 0.0734). **Do not add a total term.**
- Ceiling: opp_implied explains only **7.6%** of DST variance. The rest is
  turnovers and return TDs, unforecastable. Edge is 0.39 sd, so the rule will
  look wrong in individual weeks and still be right. Do not kill it on one week.

**Verdict: promote from "under test" to standing rule. Lowest opponent implied
total, no refinement.**

### Test 2 — Yahoo projection vs baselines. YAHOO WINS DECISIVELY.
Week 4 pool, 1,042 players joined on `Player ID`, 221 in the startable subset
(proj >= 5 or >= 5 opp/g).

| model | MAE | RMSE | r |
|---|---|---|---|
| **Yahoo projection** | **4.294** | 6.134 | 0.663 |
| opportunity x pos rate | 6.714 | 9.074 | 0.128 |
| season ppg wk1-3 | 7.319 | 9.380 | 0.215 |
| last week only | 7.695 | 9.932 | 0.206 |
| always predict 0 | 8.516 | 11.798 | — |

Paired t-test vs best baseline: **-2.421, p < 0.0001, CI [-3.215, -1.627]**.
Yahoo wins at **every** position (QB 3.50 vs 7.18, RB 4.29 vs 6.51,
TE 4.29 vs 4.95, WR 4.69 vs 7.25).

**Season ppg is the worst non-trivial baseline (MAE 7.32).** This is the
Sutton/Raymond error quantified: Yahoo's proj already had Sutton 8.96 vs
Raymond 5.71, i.e. the export encoded the right answer and the ppg ranking
destroyed it.

### Test 3 — Regret decomposition.
Optimizer reproduced all four recorded regret numbers exactly (19.76 / 2.50 /
25.06 / 27.10), so it is trustworthy.

Pooled leak by position: **WR 46.90, QB 23.52, K 12.00, DEF 0.00, TE 0.00,
RB -8.00** (RB negative is a FLEX-reallocation artifact). WR+QB = **95%**.
TE has leaked **zero** in four weeks — 1-deep means there was never a choice
to get wrong, so the "TE hole" has cost nothing to date.

### Capstone — is the regret ours or the projection's?
Compared three lineups per week against actuals: what we started, the
**projection-optimal** lineup, and the hindsight optimum.

| | 4-wk total |
|---|---|
| started | 456.12 |
| projection-optimal | 456.92 |
| hindsight-optimal | 530.54 |
| **regret from our deviations** | **+0.80 (1%)** |
| **regret from projection error** | **+73.62 (99%)** |

**We have been following the projection near-perfectly. Four weeks of
start/sit work has cost 0.80 points total — 0.20/wk.** The lineup layer is
already at its ceiling and cannot be improved. Reinterpreting test 3: the
WR/QB leak is not us picking the wrong bench player, it is the projection
being unable to say which WR would hit.

Week 4 roster error for scale (availability filter fixed to include `FA`,
which covered 360 of 465 WRs):
```
started                  93.00
best from OWN roster    120.10  -> lineup error 27.10
best from own + wire    186.86  -> roster error 66.76  (hindsight-maximal ceiling)
```

**Strategic consequence: leverage is in roster quality and the two free
streaming slots, not in weekly lineup optimization.** Stop spending the
week's effort on start/sit. Spend it on the wire and on K/DST.

### Operational finding — the wire has two phases
```
week 4 WR export (Sat 10-04): FA 360 | owned 54 | W(waivers)  51
week 5 WR export (Mon 10-06): FA   0 | owned 53 | W(waivers) 412
```
Yahoo dumps every unowned player onto waivers after Sunday games; they clear
Wednesday. **Before the clear, priority gates everything. After it, the pool
is first-come and priority is irrelevant.** A Thursday/Friday second look is
free and does not spend priority.

## 7. Game-script remeasurement, 2026-10-07

Trigger: user challenged the Gordon II FLEX call — "miami ... going up against the
bengals who are one of the top defensive picks for the week, are we SURE". Challenge was
correct. MIA sits at -7.0, which falls in a bucket the published table never measured
(it stopped at dog 3-7). The original recommendation had no measured basis.

Rebuilt on 2024-25 as a slope instead of buckets (`dev/weekly/mult_measure.R`):

| pos | n | slope/pt | p | 7-pt dog |
|---|---|---|---|---|
| RB | 779 | +0.00799 | 0.0109 | 0.944 |
| WR | 1132 | -0.00129 | 0.679 | flat |
| QB | 398 | +0.00562 | 0.102 | flat |

RB x WR interaction -0.00928, p = 0.0406. Only 1 of 22 bucket cells was significant
(RB fav3-7 1.081, CI [1.013, 1.148]); dog7-10 vs dog3-7 was indistinguishable
(diff -0.039, p = 0.689) — buckets cannot resolve this, the slope can.

**Second standing rule reversed:** inside the ~5% band the tiebreaker is the SPREAD, not
usage. Usage is already inside the Yahoo projection; the spread demonstrably is not
(Pearson +0.129, n=39). Using usage double-counts.

### Week 5 lineup, FINAL (set 2026-10-07)

QB Stafford | RB Javonte Williams, Derrick Henry | WR Davante Adams, Carnell Tate
TE Hockenson | FLEX Denzel Boston | K Bates | DEF Jaguars

Raw 104.67, spread-adjusted 105.28. Pre-swap lineup was 103.84 / 104.45.
Sutton benched (WR flat, so his +3.5 buys nothing). Gordon II benched (RB -5.6%).

**Kill condition:** if Gordon II out-scores Boston AND Tate this week, that is one
player-week and changes nothing — the rule was measured on n=779, not on wk5. Only a
sign flip in a rerun of `mult_measure.R` on 2026 data at season end kills it.

### Roster move

ADD Tyler Higbee (LAR TE, bye 11) into the one open spot. No drop. Closes the week-6 TE
hole created when Ferguson was dropped instead of Butker. Higbee 8.5 tgt/g and 12.7
half-PPR/g over wks 3-4 vs Hockenson's 8.5 / 10.2 — he is not a backup, he is a second
starter whose bye complements Hockenson's.

Butker HELD, not dropped. KC's bye is week 5, so he covers week 6 when Bates (DET) is
out. The earlier kill condition about week-6 free kickers is moot.

---

# RETRO — appended 2026-10-13 Tue. Nothing above the `## Retro` line touched.

**W, barely. Record 3-2.** Us **107.02**.

Vintages, stated per #38 §3. Actuals `docs/uploads/week_5_data/*_actual_2026-10-13.csv`.
Freeze proj `*_2026-10-07.csv` (DEF city-named, see R5). Gameday proj `*_2026-10-11.csv`.
Rosters rebuilt from `Roster Status` in the position **actual** exports — not from any
`rosterchanges_*` file. Lineup CSVs written this session: `2026_week05_myteam.csv`,
`2026_week05_opponent.csv` (closes #38 §2a).

## R0. Scoreboard

| slot | started | proj | actual |
|---|---|---|---|
| QB | Stafford | 19.69 | **27.32** |
| RB1 | Henry | 14.62 | 20.50 |
| RB2 | Javonte | 14.99 | 13.20 |
| WR1 | Adams | 13.13 | 19.60 |
| WR2 | Tate | 9.77 | **1.10** |
| TE | Hockenson | 7.18 | **1.20** |
| FLEX | Boston | 9.69 | 12.10 |
| K | Bates | 8.70 | 10.00 |
| DEF | Jaguars | 6.90 | 2.00 |
| | | **104.67** | **107.02** |

Bench: Gordon II **14.80**, Higbee **10.80**, Sutton 8.80, Odunze 3.50. Mahomes +
Butker KC bye. Etienne IR 0.00.

```
started               107.02
projection-optimal    109.72   -> regret from OUR deviation    +2.70  (12%)
hindsight-optimal     130.32   -> regret from projection error +20.60 (88%)
```

Regret **23.30**. Split holds the #37 capstone shape: lineup layer near ceiling,
projection carries the leak. Cumulative deviation regret **3.50 over 5 wks (0.70/wk)**,
up from 0.80 over 4 — the whole increase is R2 below.

## R0b. Opponent total NOT recoverable. Range only.

Yahoo export has **no started/bench flag**. Max's TD Bombers roster enumerated: 84
distinct legal lineups after dropping D. Smith (10-11 proj 0.00, ruled out) and Walker
(KC bye). **47 of 84 lose to 107.02.** Closest plausible loss:

```
Prescott, Taylor+Harvey, Washington+Burden, Likely TE, Deebo FLEX, Fairbairn, Steelers
  = 105.74 actual (proj 102.43)  -> we win by 1.28
```

Their **projection-optimal** lineup scores only **95.64** — it benches Likely 26.90 for
Kraft 9.55. They beat their own projection and still lost. `opponent.csv` ships
`slot = UNK` for all 15 rows. Do not back-fill it by guess. Also: week-5 `Roster Status`
is post-week ownership, so a late add/drop could mis-assign a fringe row.

## R1. Kill conditions scored. Seven. One fired, and it was pre-declared inert.

| # | condition | result | verdict |
|---|---|---|---|
| W1 | Bengals opp implied > 21.0 -> stream off | **MOOT.** Claim failed, never rostered | not scored |
| W2 | Gordon II < 10 opp in two consecutive wks | **18 opp.** wk3-5 = 20/11/18 | not fired. Role real |
| W3 | Tate < 6 tgt in two consecutive wks | **5 tgt.** One week | **ARMED.** < 6 in wk6 -> he is the drop |
| D9 | Boston < Sutton, wks 4-8 | Boston **12.10** > Sutton 8.80 | 3 of 5. no strike |
| T1 | Ravens beat Bengals by > 3 | Bengals 9.00, Ravens 6.00 | no strike. Both unrostered anyway |
| T2 | Raymond outscores Sutton wks 5-7 -> new drop rule wrong | Sutton **8.80**, Raymond **1.90** | 1 of 3. Rule survives |
| GS | Gordon II > Boston AND > Tate | **FIRED.** 14.80 > 12.10 > 1.10 | **inert by pre-registration.** See R2 |
| §4 | Hockenson clears 8 opp -> claim wk6 | **1 opp.** Already claimed 10-07 | caution was right, overridden |

K rule: **retired-untested**, not passed. Butker on KC bye, forced to Bates. First real
test wk7, per §6a.

## R2. THE SPREAD TIEBREAK IS DEAD. Killed by a powered test, not by this week.

Harness **`dev/weekly/spread_tiebreak_leaguewide.R`**, rerunnable.

Prior evidence = **5** reordered pairs, our roster, wks 1-4. Rebuilt all **10 rosters**
from the actual exports (191 rostered RB/WR/TE player-weeks, wks 4-5), paired every
within-5% RB/WR/TE combination, scored raw ordering vs spread-adjusted ordering against
actuals. Only **discordant** pairs — where the rule changes the pick — carry information.

| scope | pairs within 5% | discordant | spread pick correct | 95% CI | p |
|---|---|---|---|---|---|
| 10 rosters, wks 4-5 | 75 | 17 (22.7%) | 6 (35.3%) | [0.142, 0.617] | 0.33 |
| pool-wide, wks 4-5 | 1,497 | 240 (16.0%) | 114 (47.5%) | [0.410, 0.540] | 0.48 |
| pool-wide, excl. actual == 0 | — | **215** | **105 (48.8%)** | **[0.420, 0.557]** | 0.79 |

Points: **-0.488 per decision**, CI [-1.77, +0.80], p = 0.45. No bucket escapes chance —
dog7+ 43.6% (n=55), dog3-7 47.9% (73), dog0-3 56.2% (16), fav0-3 36.4% (11), fav3-7 51.7%
(58), fav7+ 44.4% (27). The 16% discordance rate replicates the 2.3%-of-all-pairs figure
from the 10-06 backtest.

**Not double-counting.** #33's "one source counted twice" re-run at scale:
Pearson(favouredness, Yahoo proj / own season ppg), **n = 190** (was 39) -> **r = -0.036,
p = 0.62, CI [-0.177, +0.107]**; RB -0.094 (58), WR +0.018 (93), TE -0.080 (39). The
10-06 **+0.129 at n=39 was noise**. Yahoo really does not price the spread. The 10-07
premise holds and the rule still fails.

Cause is arithmetic. 0.00799 x 7 = **5.6%, ~0.6 pts** on a 10-pt projection. Inside a 5%
band the two actuals differ by ~8-9 pts of variance. **A 0.6-pt edge cannot arbitrate a
9-pt coin flip at the pair level**, however real it is in the mean.

**KILLED:** standing rule "inside ~5%, break the tie on the SPREAD" (adopted 10-07 on
reasoning, never on a decision test). CI excludes accuracy above **55.7%**.

**NOT killed:** the slope itself (RB +0.00799/pt, p = 0.0109, n = 779, 2024-25). Note the
slope was measured on points **relative to own season average** — and season ppg is our
*worst* non-trivial baseline (MAE 7.32 vs Yahoo 4.29). A multiplier calibrated against a
weak baseline does not transfer onto a strong one. That mismatch is the bug, not the slope.

**NOT killed:** §7's pre-registered condition (sign flip from `mult_measure.R` on 2026
relative-to-own-average data, season end). RB coef here came back -0.0060 at p = 0.48 —
noise. **Do not read it as a flip.**

Our own wk5 case (Boston over Gordon II, **-2.70**) is now 1 of 240. Consistent with the
null, not evidence for it. The GS kill condition fired exactly as pre-declared and taught
nothing by itself — the league-wide test is what taught.

**Replacement rule: inside a ~5% gap nothing arbitrates. Start the higher raw Yahoo
projection and stop.**

## R3. DST rule HELD league-wide. Our pick still scored 2.00.

Week 5, all teams with a line, **n = 30**. Opponent implied total vs DST pts:
**r = -0.334, p = 0.071**, Spearman **-0.346**. Same sign and magnitude as the 4-wk
validation (-0.275). Eight lowest opp-implied averaged **9.00** vs league mean 6.47 ->
**+2.53 edge**.

Our Jaguars were the rule's **#2** (opp implied 17.00) and returned **2.00**. Rule's #1
(HOU, 15.50) returned 15. Textbook decision-right / outcome-bad, and exactly the 0.39-sd
behaviour #37 predicted. **Do not touch the rule.** Line drifted from the 17.75 tie quoted
at freeze to 17.00 — still top-2, so the pick was correct at freeze and at kickoff.

## R4. TE cost 9.60 and it was NOT a decision error.

Hockenson proj 7.18 vs Higbee 4.70. Projection said Hockenson; we followed it; Higbee
went 10.80 to 1.20. Hockenson's wk4 13-opportunity spike collapsed to **1**.

Two separate verdicts, do not collapse them:
- the **claim** was shaky — §4 flagged the n=1 spike as the risk and we claimed anyway;
- the **start** was correct given the projection, per the lineup-layer rule.

## R5. Data finding — DEF naming flips between vintages inside one week.

`yahoo_week5_def_2026-10-07.csv` names teams by **city**; `..._actual_2026-10-13.csv`
names them by **nickname**. Same week, different key:

```
10-07 proj   : Jacksonville | Jax | 6.90      Cincinnati | Cin | 7.53
10-13 actual : Jaguars      | Jax | 2.00      Bengals    | Cin | 9.00
10-07 proj   : New York | NYJ | 7.31   and   New York | NYG | 5.04   <- same string, two teams
```

This is #37 §6's DEF trap with a cause, and live proof of the `CLAUDE.md` rule: **DEF
joins on the `Team` abbrev, never on name.** `stopifnot()` the map.

Confirmed again: `rosterchanges_league_team` disagrees with the position exports. Rosters
come from the position exports. Both rosters rebuilt cleanly that way.

## R6. Decision wrong vs outcome bad — the ledger

| | decision | outcome |
|---|---|---|
| Boston over Gordon II (spread tiebreak) | **WRONG** — rule now dead at n=215 | bad, -2.70 |
| Hockenson over Higbee | right (followed projection) | bad, -9.60 |
| Tate started over Sutton | right (9.77 vs 8.94) | bad, -7.70 |
| Jaguars DEF | right (rule's #2) | bad, -4.90 vs HOU |
| Gordon II claim | right (18 opp) | good |
| Raymond dropped, Sutton held | right | good, +6.90 |
| Hockenson claim | **shaky** (n=1 spike, flagged) | bad |

Caveat on T2: Sutton won on points **while his own usage fell to 3 opportunities**, his
season low, vs Raymond's 5. The rule won on the scoreboard while its own underlying signal
weakened. 1 of 3 weeks. **Do not bank it.**

## R7. Still not learned

1. Exact margin of the win. No started/bench flag exists in the export. Structural.
2. DST rule at week granularity. p = 0.071, n = 30, 7.6% R2. Agrees; cannot confirm alone.
3. Whether the K hold rule works. Bye-forced both wks 5 and 6. First test **wk7**.
4. Multiplier *accuracy*. Retired as a retro question, 10-06. Unchanged.
5. Any model fit. **n = 5. Fit nothing.**


---
