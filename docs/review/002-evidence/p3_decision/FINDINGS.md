# P3 (decision scientist) — FINDINGS, 2026-11-02. Saved by lead from the agent's hand-back.

Scripts (p3_decision/): sim2.R, 01_objective.R, 02_variance.R, 03_trades_seq.R (+.out), 04_stack_corr.R (+.out), 05_checkpoints.R (+.out), .rds results. N 20000 x 10 seeds (SEED+0:9), CRN within seed; ± = sd across seeds. sim2() = simulate_cond() exactly (checked) + playoffs wks 16-17 (1v4, 2v3, final), per-team weekly sd, separate streams for gambles.

## 1. Headline
- Send TR1 + TR2 Tue, both at once. Waiting has no option value; each week of delay ≈ -0.8pp (23% of their value).
- P(top 4) convex where we sit -> risk-seeking: stack every trade, overpay partners (arming cheap), prefer upside players with uncertain roles.
- Stop rule: lose wks 9 AND 10 (4-6) -> P ≈ 1% even after trades -> 15-min weekly routine.
- Honest ceiling ≈ 10-12% P(top 4), ≈ 1% P(champ).

## 2. Numbers
Baseline (01_objective.R): P(top 4) 2.64% ±0.15; exp W 6.08; P(champ) 0.22%; P(champ | top 4) 7.6%. If in: 4th seed 64%; P(win semi | in) 0.30; P(win final | in final) 0.25.
Exchange (+x/wk wks 9-15 -> ΔP pp): 1 -> 0.49; 2 -> 1.06; 3 -> 1.68; 4 -> 2.38; 5 -> 3.19; 10 -> 9.26; 15 -> 18.7; 18.5 (pack avg) -> 27.5; 25 -> 47.2.
Q1 objective (5 seeds): +5 wks 9-15 only -> ΔP(champ) +0.26pp; +5 wks 16-17 only -> +0.105pp; both +0.49pp. Per point-week, playoff week = 1.42x regular for P(champ); wks 16-17 = 21% of value of even full-season gain.
Q2 risk (02_variance.R, 10 seeds):
| bet | ΔP(top 4) | ΔP(champ) | ΔW |
|---|---|---|---|
| sure +5 | +3.19 ±0.15 | +0.49 | +0.42 |
| persistent 50/50 {0, +10} | +4.57 ±0.12 | +0.92 | +0.43 |
| sure +3 | +1.68 | — | — |
| persistent 50/50 {-4, +10} (mean +3) | +3.89 ±0.13 | +0.85 | — |
| weekly-independent 50/50 {0, +10} | +3.28 ±0.26 | — | +0.43 |
Certainty equivalents: {0, +10} ≈ sure +6.1; {-4, +10} ≈ sure +5.6. Persistent mean-zero uncertainty sd 3/6/10 -> +0.29/+1.24/+3.53pp ≈ sure +0.6/+2.3/+5.3 (holds with tau 6 for all: +0.33/+1.29/+3.46). Weekly: +1 team-score sd ≈ +0.39 pts/wk mean (stable sd 23-30; brief said 0.47).
Stacks (04_stack_corr.R, 2024-25 REG, own-season-mean deviations): QB+WR1 rho 0.377 [0.316, 0.434] n 808 -> +0.86 sd -> +0.34 pts/wk; QB+WR2 0.422 n 715 -> +0.32; QB+TE1 0.303 -> +0.20; QB+RB1 -0.006 -> 0. Opposing QBs same game rho 0.215 (n 442).
Q3 sequencing (03_trades_seq.R, 05_checkpoints.R, 10 seeds; 10-28 rosters): TR1 +1.67pp, TR2 +1.28pp, BOTH +3.64 ±0.16 (+0.47 W) -> 2.64% -> 6.28%; synergy +0.69pp (23%). Tate-out bound: baseline 2.10%, both +4.21pp -> 6.3%. Delay (first week counted): wk9 +3.64, wk10 +2.81, wk11 +2.37, wk12 +2.00, wk13 +1.42pp. Waiting to wk11 breaks even only if later deal +7.7/wk v +5.84 now (+32%).
Checkpoints P(top 4 | results):
| state | P(state) w/ trades | no trades | TR1+TR2 from wk9 |
|---|---|---|---|
| won wk9 | 0.42 | 5.8% | 11.1% |
| lost wk9 | 0.58 | 1.1% | 2.9% |
| 6-4 (won 9+10) | ~0.13 | 13.9% | 22.7% |
| 5-5 | ~0.47 | 2.6/3.2% | 5.6/7.0% |
| 4-6 (lost 9+10) | 0.40 | 0.34% | 0.98% |
| 4-7 | — | 0.04% | 0.16% |
At 4-6 with trades + further +5/+10/+15 from wk11: 2.1/4.3/8.2%. Trades beat no trades in every state -> wk9-10 results carry no decision value for TR1/TR2.
Q5 arming (rival +5/wk wks 9-15 -> ΔP us): Dave's -0.44, SK -0.44, Jazzy -0.38, Max's -0.32, Mitchell -0.32, Owl Out -0.15, Steel City -0.08, Michelle -0.04, Madison +0.21 (plays a rival every remaining week, never us). Same +5 to us = +3.19pp -> arming costs 0-14% of equal gain. Max's +2.5 wk14 only (Mahomes v us) -0.14pp. Root for: Madison over Dave's wk9 (1.0pp), Max's over Jazzy wk10 (0.9), Madison over Michelle wk15, Madison over SK wk10.
Q4 sweeteners (cost of giving away, post-trades, 10 seeds): Strange 0.00; Tucker +0.05 (bye-fill artifact, ≈ replacement); Odunze -0.07; Gordon -0.57; Chiefs DEF -0.62 (≈ 0 real: we stream); Boston -0.77.

## 3. Levers
- L1 Send TR1 + TR2 Tue 11-3 in parallel, free sweetener ready: +5.84/wk, +3.64pp, +0.47 W if both land; EV +1.65pp at 50/50 acceptance, +2.05pp at 70/50. ~45 min user. No shared players -> both offerable at once. Not accepted by Thu 11-5 -> re-offer + Strange or Odunze (<= 0.07pp); worth it if lifts TR2 acceptance >= 5.5 points. Kills (role, wks 9-11; trigger action, not grade): Jacobs snaps < 50% in 2 of 3 -> bench/flip; Burden tgt share < 15% avg over 3 -> bench for Tucker/Odunze; Likely snaps < 60% -> same.
- L2 Risk-seeking posture wks 9-15 ≈ sure +0.6..+2.3/wk (+0.3..+1.2pp): (a) within ~0.5/wk ROS mean, take the uncertain role (rookie rising snaps, RB one injury from lead, IR returner); (b) all-in — 2nd trade worth more than 1st (+23% synergy); (c) in-band QB+WR1 stack = legit but tiny tiebreak (+0.34), never spend user time. Kill: upside player < 50% snaps 2 straight games after acquisition -> next upside player.
- L3 Generous offers to non-rivals + near-locks: partner pt/wk costs us <= 0.09pp (Dave's, SK), ~0.03 (Owl Out, Michelle, Steel City), gain for Madison (+0.04); our pt/wk +0.64pp -> loosen trade_finder `d_them >= 0`/`>= -2` filters; let partners win on paper by 2-5/wk if it buys acceptance. Third-trade targets: Madison again, or near-locks Owl Out, Max's. Kill: 2 rejections or 1 veto from a manager -> stop offering them.
- L4 Checkpoint stop rule, pre-registered now. After wk10 MNF: 4-6 -> P ≈ 1% (even +10/wk -> 4.3%) -> stop analysis; routine = Yahoo-proj lineup + DST stream, <= 15 min. 5-5 -> 6-7% -> one more trade push before ~11-26. 6-4 -> 23% -> full effort to deadline. Kill on rule: post-wk10 re-run > 3% despite 4-6 (rivals lost) -> resume.
- L5 Stop: 15%-band lineup debates (wk8 QB 3 rounds for 0.20 ≈ 0.1pp); retros/grades on irreversible trades; calibration that can't change a remaining decision (T4 needs n 30 -> after season); wk16-17 schedule shopping (no lines; ±1-2 x 2 wks < 0.05pp P(champ)). Keep: DST streaming (+1.92/wk ≈ +1.0pp; ~10 min/wk ≈ 0.9pp/hour). Defer 2027 builds to offseason.
Value of an hour now: Tue trade sends ≈ 2-3pp/hour (expected); DST ≈ 0.9pp/hour; lineup debates, retros, calibration ≈ 0.
Honest ceiling: TR1+TR2 + DST + third ~+2 trade ≈ +10/wk -> ~11-12% if all lands; expected ≈ 6-8%; P(champ) ≈ 0.5-1%. Closing full 18-pt deficit -> 30%; trades can't get there before deadline.

## 4. Assumptions challenged
- C1 Objective P(top 4): VERIFIED near-sufficient for even-paying moves. Under-weights late-loaded assets (playoff point-week 1.42x) -> Adams worth ~1.2x what P(top 4) says. Wk16-17 schedule buying REJECTED (no lines, tiny). Variance matters more under P(champ) ({0, +10} = 1.9x sure +5).
- C2 Convexity -> risk-seeking: VERIFIED. Persistent variance pays (CE +1.1..+2.6/wk over mean); weekly variance barely (+0.39 per sd pt). WEAKENS CLAUDE.md "a stack that costs projected points to buy shared upside loses": holds for weekly stacks costing > 0.34/wk; false as a general rule while underdog. Persistent role uncertainty = asset (Burden's uncertain role = upside).
- C3 Timing: VERIFIED act now. Same decision win or lose wks 9-10 -> waiting buys no info; delay -0.8pp/wk; later desperate partner must offer +32%. PLAUSIBLE-UNTESTED such partner appears; wire QBs (Stroud 18.3) cap QB prices -> injury elsewhere won't inflate Mahomes/Kyler. 10-28 -> 11-03 deferral cheap only because wk8 value ~0.
- C4 Parallel offers: VERIFIED free option (no shared players), +23% together. PLAUSIBLE-UNTESTED: Yahoo behaviour with shared-player offers (likely auto-cancel), League Votes veto threshold, reputational cost of backing out (repeat-play company league) -> never same player in two offers. Veto risk low (win-win on paper; partners out of race or near-locks).
- C5 Arming: VERIFIED cheap (<= 14% of equal gain), positive for Madison. trade_finder win-win filter too strict for our position (L3). Max's wk14 Mahomes -0.14pp ≈ 11% of TR2 -> accept.
- C6 Time: VERIFIED ranking. 51 sessions sunk. REJECTED: more analysis lifts season much past ~10%. Exchange fell 0.8 -> 0.49pp per pt/wk since wk8 L; each loss shrinks every lever.

## 5. Open
TR1/TR2 priced on 10-28 export, wk8 partly simulated -> Tue wk9 re-run supersedes levels; structural results (convexity premium, delay %, break-even, arming discount, synergy, stop rule) should survive. 03_trades_seq.R conditional rows (c_*, t_*, pW*) mislabeled (include wk8) -> use 05_checkpoints.R. Acceptance odds + Yahoo veto/overlap mechanics: no data (user/commissioner check). Per-player persistent-variance sizing not estimated. IR returns outside sim (P(champ) weighting raises their value). Playoff seeding assumed 1v4/2v3 (Yahoo default, not read from settings); playoff weeks use regular-season SIG/GAP. Stack rho from simple half-PPR formula; sd approximate.
