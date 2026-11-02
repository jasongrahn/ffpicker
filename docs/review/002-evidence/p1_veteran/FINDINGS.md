# P1 (veteran practitioner) — FINDINGS, 2026-11-02. Saved by lead from the agent's hand-back.

Scripts (p1_veteran/): 03_variance_value.R, 06_trade_scan.R, 07_screen_read.R, 09_stature_filter.R, 10_sim_shortlist.R, 05_ir_detail.R, 08_stature_sched.R, trade_screen.rds.

## 1. Headline
- Trade problem = acceptance model, not the value model. "Win-win on projections" passes 18 of 58,698 trades adding >= 3/wk for us.
- TR1 + TR2 look like LOSSES to the partner on what Yahoo shows them (season + recent ppg): Madison -8.3/wk, Max's -6.1/wk -> expect rejection.
- Send TR1/TR2 anyway AND offer rivals our over-valued players (Tucker, J. Williams, Gordon) for under-performing-workload starters. If accepted: +2.7..+9.0pp alone; +9.8..+19.5pp stacked on TR1+TR2.
- At 2.7%, upside counts ~double: risky move ≈ 2x a sure gain of same mean.

## 2. Numbers
Baseline 2.77% (3 seeds), exp W 6.08; MC noise ΔP ~0.05-0.17pp small moves, ~0.3pp for +9pp moves.
Variance value (03_variance_value.R, 5 seeds; our mean fixed): tau_us 3/6/9/12 -> +0.29/+1.18 (sd 0.11)/+2.77/+4.94pp; weekly sd 21.1 -> 23/25/30 -> +0.42/+0.85/+1.93pp; mean +1/+3/+5 -> +0.52/+1.73/+3.26pp; lottery 25% x +10/wk else -0.5 (mean +2.1) -> +2.12pp v sure +2.1 -> +1.13pp.
Trade screen (06_trade_scan.R): 147,392 trades (1-3 of our 13 tradeable x 1-2 of each partner's RB/WR/TE base >= 8; 9 partners); 58,698 add >= 3/wk; projection win-win passes 18; "casual manager" filter passes 558 (partner lineup improves at 0.5 season ppg + 0.5 last-3 ppg; ppg we send >= 0.9x what we get; biggest name we send within 1.25x + 5 of theirs by Yahoo preseason rank); both filters: 0.
Over-valued (perceived - projection): Tucker (LV WR) +4.7 (12.5 v 7.8); Gordon (MIA RB) +2.6; Hockenson +1.1; J. Williams no gap but preseason rank-14 name, 15.9 ppg.
Buy-low (verified usage): Drake London ATL WR (29% tgt share, 92% snaps; 11.3 v 14.4); Chase Brown CIN RB (18 touches+tgt/g; 10.4 v 14.9); Justin Jefferson MIN WR (28%; 12.1 v 14.5); DK Metcalf PIT WR (28%; 7.7 v 10.5).
Priced (10_sim_shortlist.R, 3 seeds; settle() NOT fixed here — see A3):
| move | ΔP us | ΔW | pts/wk | rival ΔP |
|---|---|---|---|---|
| TR1 | +1.64 | +0.26 | +3.11 | |
| TR2 | +1.26 | +0.19 | +2.67 | |
| TR1 + TR2 | +3.62 | +0.46 | +5.84 | |
| Dave's: J. Williams + Tucker -> Jaylen Warren (PIT RB) + Drake London | +3.17 | +0.41 | +4.41 | Dave's -9.7 |
| Mitchell: Mahomes + Tucker + Odunze -> Michael Wilson (ARI WR) + Sam LaPorta (DET TE) | +3.21 | +0.42 | +4.61 | Mitchell -7.1 |
| Michelle: J. Williams + Tucker -> Kyren Williams (LA RB) + George Pickens (DAL WR, Q) | +2.67 | +0.37 | +4.47 | Michelle -7.6 |
| SK: J. Williams + Tucker -> Amon-Ra St. Brown (DET WR, Q) + Chris Olave (NO WR) | +9.01 | +0.83 | +8.40 | SK -19.7 |
| Steel City: J. Williams + Gordon + Tucker -> Chase Brown + Ja'Marr Chase | +6.71 | +0.80 | +8.23 | |
| TR1 + TR2 + Dave's | +9.81 | +0.90 | +10.20 | |
| TR1 + Steel City | +11.46 | +1.10 | +11.52 | |
| TR1 + TR2 + SK | +19.51 | +1.34 | +14.20 | |
| Adams back wk12 at 12.6 (sim values at 0) | +1.11 | +0.17 | +3.74 wks 12-15 | |
| Add Jonah Coleman (DEN RB), drop Chiefs DST, Coleman at 8.2/10.2/12.0 | -0.30/+0.09/+0.91 | | | |
Player facts (05_ir_detail.R): Coleman = DEN #1 RB on 11-02 depth chart; snaps 6 -> 40 -> 49 -> 66%; wk8 11 car + 5 tgt, 18.4 pts; Dobbins 52 -> 23 -> 21%; base 8.2 rests on 1 week (role change average can't see). Etienne = NO 4th RB (behind Kamara, K. Miller, Donaldson), 8.5 ppg wks 1-3. De'Von Achane (MIA RB, IR) = FA; Gordon = MIA #1 RB while Achane out. Stroud FA, proj 18.3 (20.5 last 3).
Playoff wks 16-17 (08_stature_sched.R; opp DEF pts allowed/g - 23.0; + = easier): hard LA (Stafford, Adams) -4.6 v SEA + TB; DAL (J. Williams) -3.6. Soft LV (Tucker) +4.3, CLE (Boston) +3.6, JAX (Strange) +3.3, NYG (Likely) +3.2. Lines posted wk9 only.

## 3. Levers (EV = P(accept) x ΔP; P(accept) = practitioner guesses)
- L1 Offer over-valued players to rivals Tue alongside TR1/TR2 (non-overlapping: TR1 Kyler + Hockenson, TR2 Mahomes + Tate, L1 J. Williams + Tucker). Priority 1 Dave's (J. Williams + Tucker -> Warren + London): 6 WRs rostered, London under draft slot (pre rank 16, 11.3 ppg), Tucker looks hot (14.3 last 3); P(accept) ~25% -> +0.8pp EV alone, +1.5pp on top of TR1+TR2. Priority 2 Michelle (3-5, desperate): same package for Kyren Williams + Pickens. Long shots: SK (1 move all season, P ~5%, +0.45pp EV); Steel City (wk9 opp; also takes Chase from them that game). If TR2 fails: Mitchell (Mahomes + Tucker + Odunze -> Michael Wilson + LaPorta; LaPorta spare behind McBride; Lamar missed 3 games -> backup QB worth something). Tucker value perishable — sell this week (wk8 0.00 on 1 tgt; big wks 6-7 drop out of last-3; T5 kill half-triggered). Pitch in THEIR numbers (season ppg, last 3, their bye/injury hole), never our projections; 2-for-2 > 3-for-1. Veto avoidance: ppg ratio 0.9-1.3, similar stature names (TR1 1.28 = we overpay, safe; TR2 0.90 and sends an OUT player -> state Tate's injury openly). Cost ~20 min. Check in Yahoo whether one player can sit in two pending offers; if accepting one cancels others, send one at a time with 24-48h expiry. Kills: process — 0 acceptances from >= 4 offers by 11-20 -> stop, keep TR1/TR2 only; per accepted trade (role, from wk10): London < 20% tgt share or Warren < 50% snaps over wks 10-12.
- L2 Clear dead slots, buy upside (cost ~0; priority already low): claim Coleman Tue, drop 2nd DST (streaming needs 1 slot; 19 DSTs on wire; sim's -0.7 for the drop = artifact of Chiefs' average projection). Coleman as DEN lead back +0.9pp; as lottery ticket ~double. Kill: Coleman < 50% snaps wks 9-10. Don't activate Etienne (NO 4th RB); drop when IR tag clears. Stash Achane in freed IR slot (free; hedges Gordon, same MIA backfield); kill: release if no practice by wk12. QBs: after trades carry Stafford only, claim best wire QB (Stroud-class) for wk11 bye. Don't chase Tyler Allgeier (ARI) after 33.6-pt week: Love back, Allgeier backup 47-59% snaps.
- L3 Underdog variance ~+0.4pp per +2 weekly sd: in-band ties toward higher ceiling (deep-ball WR, TD-dependent RB); accept same-team QB+WR stack costing <= 0.5 projected pts; avoid starting players sharing an NFL team with opponent's starters. No kill/retro (coin flips), log as notes. [Lead note: A2 measured these as <= 0.3pp total and boom-bust as ~noise; see A2.]
- L4 Keep Adams unless a contender pays > +1.1pp now: sim prices him at 0; contenders (Owl Out, Max's, Jazzy) value his wk16-17 return -> best future-for-present chip.

## 4. Assumptions challenged
- "Win-win on projections" as acceptance test: REJECTED (no big trade passes both filters; TR1/TR2 fail casual-manager). Caveat: heuristic filter; no league accept/reject history.
- "QB surplus weak currency": VERIFIED (Stroud free 18.3; names weak: preseason rank Mahomes 76, Kyler 122). Real currency = Tucker, J. Williams, Gordon.
- "Rank moves by average pts/wk": WEAKENED (upside ≈ 2x its average at 2.7%) -> stashes, role bets, injury returns under-ranked.
- "Correlation isn't the problem; paying for it is": WEAKENED for a 30% underdog (small projection cost for variance breaks even or better); real stack correlation plausible, untested here [A2 measured: +0.35 pts/wk max].
- Sim player value (mean Yahoo proj) fine as ROS mean (per P2); 3 verified blind spots: IR returns (Adams +1.1pp unpriced), fresh role changes (Coleman), credits a 2nd DST streaming makes worthless.
- 15% band higher-raw rule: fine for the mean; add ceiling tiebreak (L3).
- DST streaming, K hold, RB-only game script: no pushback.
- Playoff-week schedule: PLAUSIBLE, ~0pp at 2.7%; use only as sales pitch to contenders (LV, CLE, JAX easy wks 16-17; LA, DAL hard).

## 5. Open
P(accept) = guesses -> log every offer + response to build data. Not scanned: 3-for-2+, three-team, Adams-for-contender-starter beyond screen. Not checked: Yahoo veto threshold; one player in two pending offers. St. Brown Q tag (Yahoo 10-31) absent in nflreadr wk8 -> re-check. Achane return date unknown. Volatility persistence untested (L3 rests on assumption).
