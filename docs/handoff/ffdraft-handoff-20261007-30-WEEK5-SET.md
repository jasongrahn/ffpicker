# Handoff #37 — Week 5 SET. Game script remeasured. Two standing rules reversed.

Date: 2026-10-07 **Wednesday**, waivers cleared. Branch `week3-gameday`,
**5 ahead of origin, unpushed**, tree clean through `936754e`.
Next session: **do not re-plan week 5. Gameday check Sunday, then retro Monday.**

Prior: #36 `20261006-29-WEEK5-PREP.md`. Methodology authority still #33 (§1
`Rankings Actual`). **#36 §0's game-script numbers are superseded — see §2.**

---

## 0. Week 5 lineup is FINAL. Confirmed on screen 10-07.

| slot | player | proj | note |
|---|---|---|---|
| QB | Stafford | 19.67 | Mon 20:15 vs BUF |
| RB | Javonte Williams | 15.07 | **Thu 20:15, first lock** |
| RB | Derrick Henry | 14.54 | BAL 3.5-pt dog |
| WR | Davante Adams | 13.12 | |
| WR | **Carnell Tate** | 9.73 | swapped in, see §2 |
| TE | Hockenson | 7.16 | |
| W/R/T | **Denzel Boston** | 9.68 | swapped in, see §2 |
| K | Bates | 8.76 | DET own implied #1 |
| DEF | Jaguars | 6.98 | opp implied **17.8, #1 of 22** |

Raw **104.67**, spread-adjusted **105.28**. Pre-swap was 103.84 / 104.45.
Bench: Sutton, Mahomes (bye), Odunze, Gordon II, Higbee. IR: Etienne.
**Roster 15/15. IR does not count.**

**Yahoo's "Start Active Players" button reverted the lineup once.** It restored
Boston to WR2 and Sutton to FLEX. Caught on a re-screenshot. **Re-verify the lineup
visually after any Yahoo auto-action — do not trust a prior confirmation.**

---

## 1. Waivers: 2 of 3 landed. The miss and the mis-drop both matter.

- **Bengals claim FAILED** — went to "Steel City". Priority was 9 of 10. #36 called
  CIN the pick on a 4-of-4 points-allowed band; irrelevant now.
- **Gordon II landed** (drop Marks). **Tate landed** (drop Wan'Dale).
- **Move 3 was not executed as written.** The drop taken was **Ferguson, not Butker**.
  That did not close the wk14 TE hole — it **moved the hole to wk6**, which was the
  one week Hockenson could not cover. Closed later by Higbee (§3).

**Two-phase wire, confirmed and now a standing rule in CLAUDE.md.** Yahoo dumps every
unowned player onto waivers after Sunday games; they clear Wednesday. Wk4 WR export
(Sat): FA 360 / W 51. Wk5 WR export (Mon): FA 0 / W 412. **Before the clear, priority
gates everything; after it, the pool is first-come and priority is irrelevant.**
A Thursday/Friday second look spends no priority — take it.

**Availability filter must be `grepl("^W [(]", status) | status == "FA"`.** A
`^W \(`-only filter understated the wk4 pool by **360 WRs** and corrupted the first
roster-error run.

---

## 2. Game script REMEASURED as a slope. Buckets retired. Two rules reversed.

**Trigger: the user challenged the FLEX call.** "gordon ii is miami and they're going
up against the bengals ... are we SURE that's the play we want to make?" **They were
right, and the challenge exposed that the recommendation had no measured basis** —
MIA sits at **-7.0**, and the published table stopped at dog 3-7. I had extrapolated
past the data without saying so.

Rebuilt on 2024-25 starter-calibre player-weeks, `dev/weekly/mult_measure.R`:

| pos | n | slope / pt of spread | p | 7-pt dog |
|---|---|---|---|---|
| **RB** | 779 | **+0.00799** | **0.0109** | **0.944** |
| WR | 1132 | -0.00129 | 0.679 | flat |
| QB | 398 | +0.00562 | 0.102 | flat |

RB x WR interaction **-0.00928, p = 0.0406** -> the positions genuinely differ.

**Buckets are retired as the instrument.** Only **1 of 22** position x bucket cells is
significantly different from 1.0 (RB fav3-7, 1.081, CI [1.013, 1.148]). dog7-10 vs
dog3-7 differ by -0.039, **p = 0.689** — buckets cannot resolve this at n=24-40/cell.
The slope pools every bucket, **is linear so it extends past the measured range**, and
is the reason the wk5 case was answerable at all.

**Use `1 + 0.00799 * favouredness` for RB. WR and QB get 1.0.** The published WR
fav3-7 = 1.059 came back **1.006** in the rebuild and was noise. **#36 §0's "Henry
0.945x, 21.82 -> 20.62" is superseded** — the slope gives BAL -3.5 -> 0.972x. Same
direction, smaller, and now with a p-value. **#36's "QB cliff at 3 points" is dead:
there are no cliffs, because there are no buckets.**

### RULE REVERSED: inside the ~5% band, break the tie on the SPREAD, not on usage.

The old rule said usage. **That double-counts.** Yahoo's projection already prices
usage — that is most of what a projection *is*, and it is why a back with 15.5
opportunities and a receiver with 10.5 project **9.80 vs 9.77**. Reaching for usage
again to break that tie counts one input twice (#33's error in a third costume). The
spread is the one input the backtest showed Yahoo does **not** price (Pearson +0.129,
n=39). **RB only** — the WR slope is flat, so a WR tie stays a tie and projection wins.

Worked case: **Gordon II (RB, MIA -7.0, 9.80) vs Tate (WR, TEN -7.5, 9.77).** Raw gap
0.3%. RB penalty 5.6% -> **9.25 vs 9.77**. Started Tate. **Note the deeper dog was the
right start** — that is the whole content of the WR-flat result, and it is why
"his team is getting blown out" is a reason to bench a back and never a receiver.

**Sutton benched.** His +3.5 favorite status buys nothing once the WR multiplier is 1.0.

---

## 3. Roster moves. Higbee in, Butker held.

**Tyler Higbee (LAR TE, bye 11) is rostered** — closes the wk6 TE hole §1 created.
Not a backup: wks 3-4 he ran **8.5 tgt/g and 12.7 half-PPR/g** vs Hockenson's
**8.5 / 10.2**. Byes complement exactly (6 and 11). **His 4.70 wk5 projection is
noise — do not start him over Hockenson.**

**Butker HELD, and #35/#36's "not droppable" was right for a reason neither stated
cleanly: KC's bye is wk5, Bates' is wk6, so Butker IS the wk6 kicker.** The wk6
free-kicker kill condition is moot. **Week 6 is fully pre-covered: Higbee at TE,
Butker at K, Gordon II's bye absorbed by bench.**

---

## 4. Three method tests, run 2026-10-06. All logged in the wk5 decision doc §6b.

**(a) DST streaming VALIDATED league-wide.** `dev/weekly/dst_test.R`, n=128
team-weeks, DST points derived from `load_team_stats(summary_level="week")` + the
`config/scoring.json` tiers. opp_implied **r = -0.275, p = 0.0017**, CI
[-0.428, -0.107]; own_implied r = -0.021, p = 0.81. Edge **+1.92 pts/wk**.
**Both refinements REJECTED**: lowest quartile vs second is noise (p = 0.291), game
total adds nothing on top (p = 0.200). **Rank on opponent implied total alone.**
Ceiling: opp_implied explains **7.6%** of DST variance, edge **0.39 sd** — the rule
will look wrong in individual weeks and still be right. **>3pt kill bar retired for
DST.** K side still untested.

**(b) Yahoo's projection beats every baseline we can build, at every position.**
`dev/weekly/proj_benchmark.R`, wk4, 221 startable. MAE: Yahoo **4.29**, opportunity x
position 6.71, **season ppg 7.32**, last week 7.70, zero 8.52. Paired t **-2.42,
p < 0.0001**, CI [-3.22, -1.63]. Wins at QB, RB, TE, WR separately. **Season ppg is
the worst non-trivial baseline** — the wk4 Sutton/Raymond error, quantified.
-> **Opportunity analysis has three jobs and start/sit is not one of them**: rank the
wire, catch role changes, choose the drop. **For a start/sit between two rostered
players, read the projection and stop.**

**(c) The lineup layer is already at its ceiling.** `dev/weekly/proj_vs_choice.R`,
wks 1-4: started **456.12**, projection-optimal **456.92**, hindsight **530.54**.
Our deviations cost **+0.80 (1%)**; projection error costs **+73.62 (99%)**.
**Leverage is roster quality and the two free streaming slots, not weekly lineup
optimization.** Keep logging regret — it measures the projection, not us.
Wk4 scale: lineup error **27.10**, roster error **66.76**.

---

## 5. The Jets theory: tested, rejected on its stated mechanism, right by accident.

User: "the new york jets look like theyre 2nd in league for the least points against."
**Season points allowed does not predict DST fantasy points**: prior pts-allowed
r = **+0.081, p = 0.43**; adding defensive quality moves adj R2 **0.0492 -> 0.0495**.
It is already inside the opponent's implied total (#36 §same finding, now with n).

**But NYJ is genuinely the #2 DEF play this week** — because Cleveland's implied total
is **18.5**, second-lowest on the board. **Right conclusion, wrong mechanism.** We hold
JAX at **17.8, rank 1 of 22 available**. No change.

---

## 6. New silent trap: DEF never joins on name.

Yahoo's DEF export `Player` column **changed format mid-week** — nickname on 10-06
(`Ravens`), city on 10-07 (`Baltimore`). `attach_nfl_ids()` name-matched the city form
to a skill player and mapped **all 32 defenses to ATL / bye 11** without erroring.
Worse: **"New York" is not unique** — NYG and NYJ are indistinguishable by name.

**Join DEF on the `Team` abbreviation. Always. `stopifnot()` the map.**
Pattern is in `dev/weekly/roster_vs_wire.R`.

---

## 7. Open. Nothing here is this week's work.

1. **Push.** 5 commits ahead of origin on `week3-gameday`, no PR.
2. **wk13 zero DEF** — flagged since #34, still unlogged, still unsolved.
3. **wk11 loses four at once**: Stafford, Adams, Boston, Higbee. TE is covered
   (Hockenson). **QB is covered by Mahomes. WR1 and WR2 are not.** Solve before wk9.
4. **wk10 loses Odunze + Sutton**; Sutton is droppable, so this may solve itself.
5. **Etienne IR reactivation** — NO, bye 8, unexamined since #34.

**Deadlines.** First lock **Thu 10-08 20:15 TB @ DAL** (Javonte). Per
`min(kickoff of legal replacements)`, **DEF is due Sun 09:30** (JAX plays London) and
**QB/WR1 are due Sun 09:30 despite Monday kickoffs**.

**n = 5. Fit nothing.**
