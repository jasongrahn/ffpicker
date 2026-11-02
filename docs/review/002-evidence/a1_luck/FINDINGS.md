# A1 (luck v roster + calibration) — FINDINGS, 2026-11-02. Saved by lead from the agent's hand-back. Wk8 PROVISIONAL.

Scripts (a1_luck/): q1_luck.R, q2_decomp.R, q3_wk4_reconcile.R, q4_wk8_prov.R, q4b_setlineup_forensics.R, q4_sim.R (env GAPMODE), q5_calib.R, q5b_our_variance.R. N 20000, seed 20261021, CRN; +5 seeds where noted.

## 1. Headline
- NOT unlucky — slightly lucky: 4-3 v 3.33 expected wins from scores (+0.67, z +0.57). All-play 30-33, 8th of 10.
- Deficit = roster: mean ceiling 105.0 (9th), -6.4/wk v opponents = 69% of cumulative margin.
- 0 of 4 losses winnable by any pre-kickoff decision. Wk4 real final 123.98 > our best legal 120.10.
- Wk8 provisional, all 10 fixed: P(top 4) 2.84% (2.2-3.3% under lineup noise). Other wk8 results move it <= 0.3pp.
- Need 5-2: P(top 4 | 9 W) 76%, | 8 W 7%.
- Risk flag: our sd around ceiling 8.3 (n 6) = league lowest v sim's 21.1. If real, P ≈ 1.0%; underdog wants variance (sd 28 -> 4.4%, 35 -> 6.4%). Not established: p ≈ 0.20 after 10-team correction.

## 2. Numbers
Q1 luck, wks 1-7 Yahoo finals (n 70): expW = sum weekly (teams outscored)/9.
| team | W-L | all-play | expW | luck | PF rk | PA rk |
|---|---|---|---|---|---|---|
| Owl Out | 6-1 | 46-17 | 5.11 | +0.89 | 2 | 8 |
| Sunday Kevin | 4-3 | 43-20 | 4.78 | -0.78 | 3 | 2 |
| Max's | 5-2 | 42-21 | 4.67 | +0.33 | 1 | 10 |
| Michelle | 2-5 | 35-28 | 3.89 | -1.89 | 4 | 1 |
| Dave's | 4-3 | 34-29 | 3.78 | +0.22 | 8 | 3 |
| Mitchell | 3-4 | 33-30 | 3.67 | -0.67 | 5 | 9 |
| Jazzy | 5-2 | 32-31 | 3.56 | +1.44 | 6 | 6 |
| us | 4-3 | 30-33 | 3.33 | +0.67 | 7 | 7 |
| Steel City | 1-6 | 19-44 | 2.11 | -1.11 | 9 | 4 |
| Madison | 1-6 | 1-62 | 0.11 | +0.89 | 10 | 5 |
Our weekly score rank 7,1,6,7,7,5,7. Opponents' rank v us 4,4,9,4,9,3,10 -> neutral-to-soft schedule. With wk8 prov: us 4-4 v 3.44 (+0.56). Jazzy = most over-performing contender; Michelle (best future roster 116.7) + SK under-performing. Luck only lives in banked wins -> no sim change.

Q2 decomposition (margin = gap + our miss - their spike; ceilings wks 3-8 only):
| wk | opp | res | margin | gap | our miss | their spike | pre P(W) | best possible - opp |
|---|---|---|---|---|---|---|---|---|
| 1 | Dave's | L | -17.2 | — | (+0.3) | — | — | +2.6 (ex post) |
| 2 | SK | W | +40.5 | — | (+51.7) | — | — | +43.0 |
| 3 | Mitchell | W | +12.0 | -11.8 | +2.7 | -21.1 | .35 | +37.1 |
| 4 | Jazzy | L | -31.0 | -7.7 | -9.5 | +13.8 | .40 | -3.9 |
| 5 | Max's | W | +6.6 | -3.0 | +2.1 | -7.5 | .46 | +29.9 |
| 6 | Owl Out | L | -19.5 | -6.6 | -14.5 | -1.7 | .41 | -16.1 |
| 7 | Madison | W | +28.4 | +4.7 | -6.0 | -29.7 | .56 | +33.1 |
| 8p | Michelle | L | -51.6 (Love: -31.7) | -13.7 | -17.1 | +20.8 | .32 | ~-19..-39 |
Wks 3-8: margin -55.1 = gap -38.2 + our miss -42.2 - their spike (-25.3). Opp -4.2/wk (league norm), us -7.0/wk -> net noise -2.8/wk against. Roster expected 2.50 W, got 3. League wks 3-7 (n 25): ceiling gap R² 0.29; favourites 15/25 v 15.5 exp; mean |gap| 9.6 v |noise| 23.9. With wk8 (n 30): R² 0.34, 18/30 v 18.7. -> one game ≈ 30% roster, 70% noise; roster = only lever that compounds.
Winnable pre-kickoff: 0/4 (wk1 only via Mahomes>Stafford, proj said Stafford, 0.35 ex ante; wk4 best 120.10 < 123.98; wk6 95.08 < 111.14; wk8 best ~100 < >= 119).

Q3 wk4: 123.98 = Yahoo final (Schedule tab both sides; schedule_check reproduces Standings). 98.58 = frozen Wed replay with Achane (IR, 0.00) at RB2. 123.98 - 98.58 = 25.40 = Chuba Hubbard exact (bench). 2 of 520 legal lineups hit 123.98; one = frozen + Hubbard for Achane. Proposed text: README row 4 -> `| 4 | L vs Jason's Jazzy Team | 93.00 | **120.10** | **27.10** | 123.98 |`; row 5 opp -> `100.44`. Append to wk4 log retro + README wk4 note: "CORRECTION 2026-11-02. Wk4 final 93.00-123.98, L by 30.98 ... best legal 120.10 loses by 3.88 -> not winnable by any lineup. Withdrawn: 'beats them by 21.52', 'winnable game, lost on three swaps'. Swap gains stand as regret, not a lost win." Handoff rows 35/36 = history; carry in #52.

Q4 wk8 provisional (proj-optimal from 10-31 pull replayed w/ nflreadr; MNF CHI/SEA at projection; DST approx). Confidence uses lineup-deviation sd 13.1 (wk7 real sd of actual - if-followed):
| game | estimate | winner | conf |
|---|---|---|---|
| Owl Out v Dave's | 112.22 v 85.56 | Owl Out | .91 |
| Mitchell v Jazzy | 115.92 v 109.36 | Mitchell | .63 |
| Michelle v us | 119.2-139.1 v 87.50 | Michelle | ~1.00 |
| SK v Max's | 93.90 v 90.47 | SK | .57 |
| Steel City v Madison | 127.06 v 89.13 | Steel City | .955 |
Notes: Lamar Jackson 1 snap (0.00), Breece Hall DNP; Max's only K (Fairbairn) on bye; SK DEF on bye + bye/IR players in Thu set. Prov standings: Owl Out 7-1; Max's, SK, Jazzy 5-3; Mitchell, us, Dave's 4-4; Michelle 3-5; Steel City 2-6; Madison 1-7.
Our P(top 4): helper default 2.62%; all 10 fixed 2.84% (5 seeds 2.66-2.94); noise sd 8 -> 2.90% [2.56, 3.23]; sd 13.1 -> 2.87% [2.16, 3.28]. SK lost -> 3.16%; Jazzy beat Mitchell -> 2.59%. Exp wins 6.08; P(>= 9 W) 2.7%. Each game P(W) .27-.35, worth 4.7-6.2pp.
Exchange on 2.84%: +1 -> +0.47pp/+0.08 W; +3 -> +1.7/+0.24; +5 -> +3.5/+0.41; +10 -> +9.9/+0.86; +15 -> +19.7/+1.32.

Q5 calibration: frozen wk7+8 (n 10, wk8 prov): Brier 0.169 (coin 0.25; model-expected 0.229); favourites 8/10 v 6.17 exp (P(>= 8) 0.20) -> not over-confident. T4 wk8 (n 5): MAE margin Yahoo set-lineup 23.8 v ceiling 19.8 (Love variant 19.9 v 15.8); Thu set lineups carry bye players fixed by Sunday; no call (bar n >= 30). Too pessimistic about us? NO: lost wk8 by 32-52; our actual - ceiling wks 3-8: +2.7 (+2.4 league), -9.5 (-9.1), +2.1 (+5.9), -14.5 (-14.7), -6.0 (-5.7), -17.1 (-6.0) -> we track league weekly projection error. Our mean wks 3-7 -5.03 v -4.24 (p 0.93). Team gaps ANOVA F 1.54, p 0.17 -> TAU2 noise-level. GAPMODE=shrunk: our gap -4.87; P(top 4) 2.84% -> 1.63% (via harder opponents: wk13 Jazzy .27 -> .20, wk15 Owl Out .29 -> .20); exchange +1 -> +0.34pp.
Our sd around ceiling 8.3 (n 6), league lowest (F 0.15, one-sided p 0.022; ~0.20 multiplicity-corrected). Sim, only our sd changed (5 seeds): 8.3 -> 1.05%; 15 -> 1.73%; 21.1 -> 2.82%; 28 -> 4.44%; 35 -> 6.36%.

## 3. Levers (A1's)
1. Every hour on roster mean, not lineup/K/margin forensics (0/4 losses decision-winnable; roster 69%). Packages need >= +10/wk for ~13%. Kill: a wks 9-11 retro finds a loss a pre-kickoff rule-consistent lineup choice would have flipped.
2. Add variance (underdog every week): sd 21 -> 28 ≈ +1.6pp ≈ +3 pts/wk mean. Inside 15% band break ties toward higher-variance player (TD-dependent, deep targets, QB-WR stack). [Lead note: conflicts with P2/A2 — following projection in the band still earns +0.88 pts/pair; see A2.] Kill: pre-game P(win) > .50 -> no variance tiebreak; re-measure our sd at wk11 (n 9).
3. Quote odds as a range: uniform (2.8%) + shrunk-gap and our-sd-8 sensitivities (1.0-1.6%).
4. Data hygiene: README wk4 98.58 -> 123.98, wk5 -> 100.44; never quote a frozen-opponent replay or Thu set-lineup projection as opponent strength (wk4 replay error 25.4; T4 SK 28.5).

## 4. Assumptions challenged
Supports: gate (r .54 -> .58 with wk8 prov, n 30); noise constants calibrated (18/30 v 18.7); uniform GAP; ADR 0010 (0/4 decision-winnable).
Weakens: #51 "model too pessimistic" (lost wk8 by 32-52; ceiling beat Yahoo set-lineup on T4); helper's uniform SIG for us (our sd 8.3 -> may overstate ~1.8pp); helper's Michelle 120 (actual 119-139; PF only).
Breaks: README/wk4 "winnable, lost on three swaps" (real margin -30.98); "we're unlucky" (+0.5..+0.8 W lucky).

## 5. Open
Wks 1-2 ceilings absent (txt pastes, no Player ID). Wk8 provisional until Tue finals (MNF at projection: JSN, Swift, Burden, Darnold, Loveland, Myers, SEA DEF; DST approx unvalidated); re-run q4_sim.R, expect <= 0.3pp change. Our low variance structural or chance? -> needs player-level sd. Trades not re-priced on 2.84% (rough: TR1+TR2 +5.85/wk ≈ +4.3pp).
