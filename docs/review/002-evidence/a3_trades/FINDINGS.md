# A3 (trades) — FINDINGS, 2026-11-02. Saved by lead from the agent's hand-back.

Raw outputs (a3_trades/): tr12.out, tr_perceived.out, search.out, final_tateOut.out, lists_tateOut.out, packages_tateOut_{paper,ppg}.out, named.out, partners.out, buylow.out, usage.out. Machinery: common.R (settle() fix), named.R, search.R -> final.R -> lists.R, packages.R, partners.R.

## 1. Headline
- TR2 as built: NO-GO. Fails pre-registered Tate-out bound: Max's -0.52 pts/wk, -1.5pp P(top 4), -0.10 W; on ppg (what managers see) Max's -6.1/wk.
  - Replace with X1: Mahomes (KC QB) + Tre Tucker (LV WR) + Brenton Strange (JAX TE) -> Luther Burden III (CHI WR) + Tucker Kraft (GB TE). Tate out of package. Win-win on projections (Max's +0.25) AND ppg (+0.02). Us +1.76pp (Tate-out) / +1.66pp (as-sim), +0.29 W.
- TR1 no longer win-win: Madison -2.0 pts/wk on projections, -8.3/wk on ppg (Jacobs 18.9 ppg in 2 games). Us +1.44..+1.60pp. Hockenson worth more elsewhere: D1 Hockenson (MIN TE) -> Jalen Coker (CAR WR) from Dave's: +1.79pp, fair on ppg (+0.20). TR1 = cheap ask at best. Prefer D1 or D2 + X1: +3.8..+3.9pp, P 2.1% -> ~5.9%.
- Ceiling: +10..+13/wk only as 3-trade package where each partner loses 1.4-2.0/wk on projections but looks fair on ppg -> +13.5pp, P ~15.6%. Paper-win-win packages top ~+10pp. Expect 1-2 acceptances -> realistic +4..+7pp.

## 2. Numbers
10 seeds x N 20000, CRN, wk8 fixed (simulate_cond logic); sim_fast == simulate_cond (validated tr12.R), SE 0.03-0.08pp; trades land wk9.
BUG FIXED in trade_finder settle(): let Madison drop its only DEF (Titans 5.1) -> sim filled slot from wire free (Browns 6.62) without a roster spot = fake +1.5/wk for partner -> why 10-28 run read TR1 +0.0 for Madison. Sole QB/K/DEF now protected (override in common.R).
Baseline P(top 4): 2.64% as-sim; 2.10% Tate-out (Tate base 0 wks 9-15). ppg-world = lineup strength with player value 0.5 x season ppg + 0.5 x last-3 ppg (nflreadr wks 1-8 via score_player_week; wk8 MNF missing).
| move | us pts/wk | us ΔP Tate-out / as-sim | us ΔW | partner pts/wk | partner ppg-world | partner ΔP (base P) |
|---|---|---|---|---|---|---|
| TR1 Kyler + Hockenson -> Jacobs (GB RB), Madison | +3.26 | +1.44 / +1.60 | +0.27 | -2.02 | -8.26 | 0.0 (0%) |
| TR2 Mahomes + Tate -> Burden + Isaiah Likely (NYG TE), Max's | +3.93 | +1.84 / +1.28 | +0.30 | -0.52 (+0.30 as-sim) | -6.11 | -1.5 (84.5%) |
| TR1 + TR2 | +7.10 | +4.12 / +3.54 | +0.57 | | | |
| X1 Mahomes + Tucker + Strange -> Burden + Kraft, Max's | +3.81 | +1.76 / +1.66 | +0.29 | +0.25 | +0.02 | -0.1 |
| X2 same give -> Burden + Likely | +3.99 | +1.87 / +1.78 | +0.30 | +0.08 | -5.21 | -0.4 |
| D1 Hockenson -> Coker (1-for-1), Dave's | +3.46 | +1.79 / +1.57 | +0.29 | -0.46 | +0.20 | -1.7 (50.9%) |
| D2 Mahomes + Hockenson -> Coker + Josh Downs (IND WR), Dave's | +4.07 | +2.19 / +1.76 | +0.34 | -0.60 | +0.06 | -2.1 |
| O1 Stafford + Tucker + Strange -> Matthew Golden (GB WR, Q) + George Kittle (SF TE), Owl Out | +6.45 | +3.97 / +3.95 | +0.55 | -1.74 | -0.97 | -2.7 (91.5%) |
| TR1 + X1 | +6.93 | +3.92 / +3.76 | +0.55 | | | |
| D1 + X1 | +6.51 | +3.81 / +3.31 | +0.52 | Dave's -0.46, Max's +0.25 | +0.20 / +0.02 | |
| D2 + X3 (Kyler instead of Mahomes) | +6.66 | +3.93 / +3.40 | +0.53 | | | |
| D1 + O1 | +9.06 | +6.89 / +6.57 | +0.79 | | | |
Expanded search: 207,658 trades per world (Tate-out, as-sim), 9 partners, gives any QB/RB/WR/TE, shapes 1-1, 2-1, 1-2, 2-2, 3-2; no-QB results add Stroud explicitly (FA 10-31, first-come); 129 unique shortlisted simulated (10 seeds, Tate-out).
Top win-win on projections (Tate-out): X2 +1.87; X1 +1.77; Hockenson -> DJ Moore (BUF WR, Q) + Downs, Dave's +1.58 (ppg +0.30); Mahomes + Boston + Tucker -> DeVonta Smith (PHI WR, O) + Kraft +1.51; Hockenson -> Purdy + DJ Moore +1.44; J. Williams + Tucker + Hockenson -> London + Coker +1.44 (asks a round 1-3 pick); Stafford -> Waddle (Q) + Evans (Q), Owl Out +1.40; Hockenson -> DJ Moore + McConkey +1.34; Henry -> Olave + Nabers, SK +1.27 (ppg -6.6); Stafford + Henry -> CeeDee Lamb + Kittle, Owl Out +1.26.
Partner loses <= 2 on projections: O1 +3.97; Stafford -> Evans + Brock Bowers, Owl Out +3.76 (name-heavy); Stafford -> Waddle + Bowers +3.76; Mahomes -> Nabers + Tyler Warren, SK +3.40 (ppg -6.8); Gordon + Strange -> Tetairoa McMillan + DJ Moore, Dave's +3.32 (ppg +0.51).
Packages (packages.R): best with every partner ppg >= -1 and projections >= -2: O1 + Dave's (Hockenson -> McMillan + Downs) + Max's (Kyler + Mahomes + Tate -> RJ Harvey (O) + Parker Washington) = +13.08/wk, +13.50pp, +1.15 W (no QB -> Stroud claim). Swap 3rd for Jazzy (Mahomes -> Rhamondre Stevenson + DK Metcalf): +12.17/wk, +13.0pp, keeps Kyler. Each partner -1.4..-2.0 projections, -1.7..-6.6pp. Best with every partner >= -1 on projections: TR1 + SK (Mahomes -> Nabers + Kelce) + Dave's (Gordon + Strange -> McMillan + Downs) = +11.05/wk, +10.22pp, +1.01 W (SK -6.1 ppg). +10-15/wk only with 3 trades; best single ~+6.5 (O1); best fair-on-both single ~+4.

## 3. Levers
| lever | Δ/wk | ΔP (Tate-out) | ΔW | cost / risk | kill (wks 10-12, after landing) |
|---|---|---|---|---|---|
| X1 to Max's, Tue | +3.8 | +1.76 | +0.29 | sells Tucker high (12.5 perceived v 7.8 base; wk8 4% tgt share, 54% snaps); 3-for-2 opens spot -> Etienne activatable w/o drop | Burden tgt share < 15% wks 9-11 (fires 26-45% by chance; never on wk8 alone) or Kraft snaps < 60% |
| D1 (or D2) to Dave's, Tue | +3.5 / +4.1 | +1.79 / +2.19 | +0.29 / +0.34 | Dave's (50.9%) = rival for 4th, loses 1.7-2.1pp (helps us); TE need real (Andrews 7.4, Pitts 6.8) | Coker tgt share < 15% wks 10-12 (21.6% season; 14%, 14% wks 7-8, near line) or snaps < 60% |
| TR1 as ask only | +3.3 | +1.44 | +0.27 | uses Hockenson (conflicts D1); bad on ppg | Jacobs snaps < 50% wks 9-11 |
| O1 to Owl Out (long shot) | +6.5 | +3.97 | +0.55 | sharpest manager, 91.5%, loses 1.7/wk; Golden Q | Golden tgt share < 18% (27% season) or Kittle snaps < 70% |
Timing: accept by Thu 11-5 to count wk9 (2-day vote); each later week drops 1/7 of value; past 11-28 = dead.

## 4. Partner context (partners.R; P(top 4) 10 seeds; adds = churn across 13 snapshots)
| team | W-L thru wk7 | P(top 4) | fill weeks | QB room | injury tags | adds |
|---|---|---|---|---|---|---|
| Owl Out | 6-1 | 91.5 | 13 | Young 18.0, C. Williams 18.4 | Charbonnet, Waddle, Evans Q | 8 |
| Max's | 5-2 | 84.4 | – | Dak 19.7 (bye 14), Geno 15.4 | DeVonta Smith O, RJ Harvey O | 6 |
| Jazzy | 5-2 | 72.8 | 10 | Maye, Goff | McCaffrey, Kincaid Q | 4 |
| Sunday Kevin | 4-3 | 60.7 | 10 | Lawrence, Cousins | Watson Q, 2 IR | 4 |
| Dave's | 4-3 | 50.9 | 11, 13 | Allen 23.9, Purdy | DJ Moore Q | 5 |
| Mitchell | 3-4 | 18.4 | 11 | Lamar Q, Penix | Hall Q, B. Robinson O | 9 |
| Michelle | 2-5 (+wk8 W) | 17.9 | 11, 14 | Burrow, Love | Pickens, Skattebo Q | 4 |
| Steel City (wk9 opp) | 1-6 | 1.0 | 11 | Daniels, Nix | Loveland Q | 7 |
| Madison | 1-6 | 0.0 | 9, 13 | Shough, Darnold | A.J. Brown Q, Egbuka O | 10 |
Most likely yes: Max's (thin WR, Smith + Harvey O; X1 fair both surfaces; arming -0.1pp); Dave's (TE hole; D1 fair on ppg). Madison active but sees TR1 -8/wk. SK, Jazzy, Michelle barely move. Owl Out sharp. `rosterchanges_added_*` = Yahoo NFL player-database log (no league activity) -> used snapshot churn.
Buy-low (base >> perceived ppg): A.J. Brown 12.1 v 4.9, Bijan Robinson 19.8 v 13.6, Chase Brown 14.9 v 9.4, Nico Collins 14.8 v 9.6, Jeremiyah Love 10.8 v 5.7. Sell-high (ours): Tucker +4.7, Gordon +2.6, Hockenson +1.1. Don't sell: Henry (perceived 12.0 v base 16.1, last-3 7.6), Kyler (15.2 v 18.3).

## 5. Assumptions challenged
- BROKEN: "TR1 win-win (+0.0 Madison)" = settle() fill artifact + Jacobs' rising base; truth -2.0.
- Sharpened: QBs weak currency -> each of our 3 QBs ≈ 0 at the margin to us too (Stroud FA 18.3 first-come); a QB thrown in costs nothing. Caveat: sim fill hands every team Stroud at once -> claimed explicitly in no-QB packages.
- New: "win-win on projections" overstates acceptance (TR1 -8, TR2 -6 on ppg). ppg misses names/draft capital; "fleece" tier (e.g., Gordon + Tucker -> Bijan + London, +18.5pp, Dave's -11.2) = unrealistic, veto-bait, flagged out.
- Tate-out bound hurts partner side only; TR2 improves for us under it (+1.84 v +1.28).
- Supported: convexity (D1 + O1 = +6.9pp > 1.8 + 4.0).

## 6. Open
Expanded shortlist simulated Tate-out world only (named trades both). Acceptance + vetoes = proxies; draft capital crude flag. No IR returns (Adams wk12; Etienne). No Stroud-claim competition. No partner counter-moves. Wk8 other games, MNF stats (Burden T2 share), wk9 export pending Tue -> re-run named.R with CUR_WEEK=9 before sending.
