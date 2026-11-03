# Week 8 Decisions — 2026, JGrahnasaurs (4-3, 5th)

Opened **2026-10-27 Tue**. **Frozen 2026-10-29 Thu 18:59 ET**, before 8:15pm kickoff
(CAR @ GB). None of ours play Thursday -> lineup slots bind Sun 1:00pm at the earliest.

Opponent: **Locked In Michelle (2-5, 8th)** — PF 796.04 (4th in league), PA 828.56 (most).
Unlucky, not weak. Yahoo matchup page 10-27: us 103.57 vs them 110.09, us 44%.

Source of record: `docs/uploads/week_7_data/*_actual_2026-10-27.csv` (owners after MNF,
before Wed clear) + `data/nflreadr/pull_2026.rds` (pulled 2026-10-27 13:12).
Scans: scratchpad `wk8_wire.R`, `wk8_dst.R`, `wk8_k.R`; `dev/weekly/k_test.R`.

Nothing below `## Retro` edited after freeze.

---

## 1. Claims. Placed 10-27 by user, clear Wed 10-28. Order C1 > C2.

| # | add | drop | rule |
|---|---|---|---|
| C1 | **Tre Tucker** (LV WR, bye 13) | Tyler Higbee (LAR TE, TE3) | wire rank: last-3 opportunity |
| C2 | **Commanders DEF** (v PHI) | Browns DEF | ADR 0011: opp implied total |

**C1. Need = depth, not a hole.** 6 healthy RB/WR for 5 RB/WR/FLEX slots. Byes ahead, one
body each: wk9 Tate, wk10 Odunze, wk11 Boston, wk13 Henry, wk14 Williams -> FLEX falls to
a TE each of those weeks. 3 TEs for 1 TE slot -> Higbee dead: 4.3 opp/g last 3, trend -2.0.
Tucker: targets wks 5-7 **5, 7, 12**, snaps 75/70/82%, 8.7 opp/g last 3 (trend +2.9) vs
our WRs 6.0-6.7. Also backfills Tate if TR2 goes. Fallback if C1 fails: Makai Lemon (PHI
WR, rookie, snaps 64 -> 91%) first-come after the clear.
- **Kill (role, wks 8-10): Tucker < 5 targets/g or < 60% snaps -> role read wrong.**

**C2.** Opp implied wk8: PHI 18.0 (Commanders) vs DEN 20.0 (Chiefs) vs PIT 21.5 (Browns).
-0.40 DST pts per implied pt -> **+0.8** over Chiefs. Claim fails -> start Chiefs.
- No single-week kill (ADR 0011). Dropping Browns empties the DEF slot -> refill at freeze.

C1 above C2: multi-week depth > one-week +0.8. A won claim drops us to the bottom of the list.

**Outcome 10-28** (wk8 export `yahoo_week8_*_2026-10-28.csv`, pulled after the clear): **both
won.** Tucker + Commanders ours; Higbee, Browns -> `W (Oct 31)`. No FA fallback (Lemon still
FA). DEF: Commanders (v PHI, Sun 8:20pm, Yahoo 7.05) > Chiefs (@ DEN, 5.86) -> rule and
projection agree.

## 2. Holds.

- **K: Bates, no claim.** Cam Little (JAX, own implied 27.0 vs DET 24.75) asked about. K
  rule tested today, null: n 214, r +0.02, p 0.75 (`k_test.R`, ADR 0011). Rule retired.
- **RB: no add.** Ours 17.7-23.0 opp/g. Wire tops = fill-ins: Pierce (PHI, `Q`, Barkley
  out), K. Miller (NO, bye 8, Etienne out).

## 3. Trades. Deadline 11-28; accept by ~11-26 (2-day league-vote review).

- **TR1 (Kyler + Hockenson -> Jacobs, Madison): DEFERRED to Tue 11-3, after MNF.** Jacobs
  plays Thu 10-29 8:15pm; 2-day review -> sent Wed clears Fri at the earliest -> **zero
  wk8 value**. Sending now only costs Hockenson's Sunday (our TE1). Wk9 GB @ NE Sun 4:25pm ->
  sent Tue 11-3, accepted by Thu -> clears in time. First useful week = wk9 either way.
  Score: cleared before wk9 kickoff y/n. Jacobs hurt / Madison refuses in the gap = outcome,
  not decision.
- **TR2 (Mahomes + Tate -> Burden + Likely, Max's): send Wed 10-28 if re-run still
  win-win.** Max's **dropped Hurts** (`W (Oct 28)`) -> Dak is their only QB -> need is live
  now, gone if they grab a wire QB. Wk8 cost ~0: Tate out (TEN @ CIN Sun 1pm), Burden plays
  CHI @ SEA Mon 8:15pm, Likely NYG bye.
- Pre-registered kills unchanged: `2026_week08_trade_ideas.md` §6.
- **TR2 re-run 10-28** (wk8 export; `trade_finder.R` + scratchpad `wk8_tr2.R` on its own
  helpers): us **+2.67 pts/wk**, Max's **+0.30** -> still win-win. P(top 4) **5.1% -> 7.1%**
  (+2.0pp), +0.19 wins. Max's P(top 4) 84.2% -> 84.3% -> arms a contender ~0. Burden, Likely:
  no tag, still Max's (Likely NYG bye wk8). **Max's QBs = Dak + Geno Smith** — Geno FA 10-21,
  Max's by the 10-27 export -> "Dak is their only QB" above = misread. Mahomes worth +0.36/wk
  to them -> pitch weaker; sim already prices it. Variants, one seed: Boston for Tate +2.3pp
  (inside noise, ADR 0006 -> keep Tate); Odunze for Tate +2.9pp but them -0.27 (fails
  win-win). **Verdict: GO.** User proposes in Yahoo; sent date -> next line.
- Baseline 10-28: P(top 4) 5.1% (tau 6: 7.6%), exp wins 6.40, wk8 P(win) 32% (sim 100.3 v
  114.0). Exchange rate +1 pt/wk wks 9-15 = +0.8pp, +0.08 wins.
- **Partner check 10-28** (user: "offer to someone doing worse than us?"). Same seed, scratchpad
  `wk8_tr1.R`: **TR1 alone +3.11 pts/wk, P 5.1% -> 8.1%** (+0.28 wins) > TR2 alone (+2.0pp).
  **TR1 + TR2: +5.85, P 11.0%, +0.49 wins.** Scan's best 2-trade combo (Dave's + Max's) +6.2pp
  -> same, inside noise. Arming cost tracks P(top 4), not standings: Max's 84% + Madison 0% +
  Steel City 1% ~free; Dave's 51% / Mitchell 18% / Michelle 14% all > our 5% = the race for
  4th. Steel City: no win-win; best "they lose" costs Henry. -> plan unchanged: TR2 now, TR1
  Tue 11-3.
- **FA swap instead? No.** `trade_finder.R` FREE moves: 0 rows (no FA base >= 9).
  `wire_scan.R` wk8: best FA WR K. Allen (IND) 7.7 opp/g last 3, Concepcion (CLE) 7.3, Lemon
  7.0 vs Odunze 6.0 -> none starts over Tate/Boston/Tucker. RB best Pierce 16 (`Q`, Yahoo 4.74)
  vs ours 17.7-23.0. TE Okonkwo 6.5 vs Strange 7.5. Hockenson last-3 3.0 = concussion artifact
  (wk5 3% snaps, wk6 bye, wk7 76%, 5 tgt) -> not a drop; TR1 chip.
- **TR2 split 10-28** (scratchpad `wk8_tr2_split.R`, additive): Mahomes -> Likely us +1.86 /
  them +0.04; Tate -> Burden us +0.81 / them +0.30 (Max's wk10 fit: Burden + D. Smith both bye
  10, Tate bye 9). Usage disagrees on the Tate half: Tate tgt share 28% avg wks 3-7, snaps
  74-89% vs Burden 21%, 39-77%. Follow projection (ADR 0009); Burden = weak link, kill §6
  watches it (17% last 3, 13% wk7). Likely snaps 66-91% (86% wk7) -> far from 60% bar.
  Priced in: wk14 = Dak bye = Max's v us -> Mahomes starts against us (+2.5 v Geno).
- **TR2 NOT sent** (user 10-29: missed 10-28). **Deferred -> Tue 11-3 with TR1**, both re-run
  on wk9 export first. User: let wk8 "shake out who doesn't need their key players". Wait cost
  ~0: wk8 value ~0 (above). **Wk9 = TR2's biggest week** (TEN bye -> Tate out; Likely NYG @ PHI
  Sun 11-8 1pm, Burden v TB Sun 8:20pm) -> **Max's must accept by ~Thu 11-5** (2-day vote).
  Wait buys: Burden wk8 target share = 1st point on §6 kill before committing; wk8 results
  re-sort P(top 4) -> arming-cost map.

## 4. Lineup. Frozen 10-29 18:59 ET. QB re-frozen 19:14 ET (pre-kickoff) -> Kyler.

- `predictions.R freeze` -> `2026_week08_leaguewide_predictions.csv`: us 104.55 v Michelle
  118.29, pred margin -13.74, **P(win) 0.322**. 5 games: favourites right 3.18 if model perfect.
- `freeze_lineups.R` (10-28 position exports) -> `_myteam.csv`, `_opponent.csv`. Opponent total
  = freeze ceiling to the cent; ours 104.46 = ceiling 104.55 minus QB swap (0.09).
- Ours: QB **Kyler** 17.93 / RB J. Williams 16.16, Henry 15.29 / FLEX Gordon 11.43 / WR Tate
  10.21, Boston 9.00 / TE Hockenson 8.95 / K Bates 8.44 / DEF Commanders 7.05. Bench Stafford
  18.02, Mahomes 16.32, Tucker 8.52, Strange 8.44, Odunze 7.75, Chiefs 5.86.
- **QB: Kyler (MIN @ DET Sun 1pm) over Stafford (v LAC Sun 4:05).** Yahoo 10-29 evening (user):
  Kyler 17.93 > Stafford 17.89 -> higher raw = Kyler (rule). 10-28 export had Stafford 18.02 ->
  csv `proj` still shows Stafford higher. 15% band -> no kill, no retro score.
- User argued DET matchup + LA rain. Checked, scratchpad `wk8_qb_dvp.R` (QB-weeks proj >= 12,
  wks 4-7, n 112):
  - Rain moot: SoFi + Ford Field both `dome` (nflreadr).
  - DvP real: DET 26.2 QB pts/g allowed (1st), +8.0 vs QBs-faced own avg (3rd); LAC 15.1
    (26th), -4.1 (28th).
  - Yahoo already prices it: proj vs own mean +0.11 per DvP pt (p < 0.001), +0.09 per implied
    pt (p 0.001).
  - Beyond Yahoo: DvP +0.21/pt, CI [-0.11, +0.53], p 0.20; implied +0.26/pt, p 0.13. Net Kyler
    edge +0.8, CI [-3.4, +5.1] -> coin flip. Untested before this; underpowered, not a null.
  - Against Kyler: LA implied 25.5 v MIN 21.75. Kyler 11.1 ppg (13.8 ex wk1, 5 att), under
    Yahoo proj 2 of 3 wks; Stafford 18.6. Rule bars ppg + usage as tiebreak (ADR 0009).
- Same band: Boston v Tucker, Hockenson v Strange.
- Michelle = proj-optimal guess (no export has a started flag): Burrow, Gibbs, K. Williams,
  Pickens, Rice (`Q`), Fannin, Mason FLEX, Aubrey, Seahawks. Love (GB QB) benched in it; GB
  plays Thu -> they may start him. Their score = Yahoo matchup page, never this replay.

## 5. Tests. Pre-registered 10-29 19:45 ET, before kickoff.

T1-T3 change a decision. T4-T5 sharpen the map only. Score each y/n in `## Retro`.

- **T1 Jacobs role -> TR1 go/no-go.** GB v CAR tonight 8:15pm. Jacobs 2026 = 1 game (wk7: 52%
  snaps, 11 car, 7 tgt; missed wks 1-6) -> already near the 50% kill line. **Snaps >= 50% -> TR1
  stays GO** (re-run Tue). **< 50% -> hold TR1, re-scan Madison** (10-21 alt: Mahomes +
  Hockenson -> Jeremiyah Love). Score Fri/Sat (`pull_nflreadr.R`).
- **T2 Burden role -> TR2 go/no-go.** CHI @ SEA Mon. Tgt share wks 1-7 19/23/32/19/15/24/13%,
  snaps 39-77%. **Wk8 >= 15% -> TR2 GO. < 15% = 2nd straight wk under §6 line -> hold Tate ->
  Burden half, re-scan Max's without Burden.** Score Tue 11-3.
  - **Amended 10-30 Fri, before CHI @ SEA.** Calibration `dev/weekly/target_dip_test.R`, 2024-25
    REG, all WRs (5,292 WR-games, pfr -> gsis 99.7%). WRs at 18-26% season share: 2 straight
    games < 15% (n 41, 24 players) -> next-3 share 16.0% [13.7, 18.1], P(< 15%) 44% [27, 63];
    no dip (n 338) 23.3%, 12%. Forecast weights (n 1,009): season-to-date 0.66, last game 0.21,
    game before 0.14. Burden (wks 1-6 22.3%, wk7 13.3%) by wk8 share: 13% -> wks 9-11 18.4%,
    P(< 15%) 26%; 5% -> 16.7%, 37%; 0% -> 15.7%, 45%. Never > 50%.
  - **New T2 rule: wk8 share alone never holds TR2.** Send Tue if re-run still win-win in wins,
    Burden not hurt, still Max's.
  - **§6 kill window wks 8-10 -> wks 9-11.** Wk8 lands before the send; wk8 10% alone -> P(kill)
    49%. With wk8 15% the new kill still fires ~24% by chance -> a fired kill alone != decision
    wrong.
- **T3 DST: Yahoo DST proj v opp-implied rule.** Desk test, 32 DSTs, clean exports wks 4-7 +
  `_def_actual_`. ADR 0011 tested rule v random only. **Yahoo beats rule by >= 0.5 pts/wk,
  paired CI excl 0 -> pick DST on Yahoo proj wks 9-15. Else keep rule.** Wk8 no call: both pick
  Commanders. By Tue 11-3, ~30 min.
- **T4 Ceiling model v Yahoo set-lineup proj.** `2026_week08_yahoo_matchups.csv` (user
  screenshot ~19:40 ET). Same 5 favourites. Gap Yahoo - ceiling: SK -23.6, Michelle -8.2,
  Mitchell -6.7, Max's -4.2, rest within ±1.1 (proj drift since 10-28). Score margin abs error,
  both, after MNF. **No call before n >= 30 games** (Thu screenshot each wk). Yahoo wins -> sim
  uses set-lineup proj for current wk + per-team gap. Us: model P(win) 0.322, Yahoo-implied
  ~0.43 (sd 21.1 x sqrt 2).
- **T5 Tucker role** = C1 kill (§1): < 5 tgt/g or < 60% snaps over wks 8-10. Feeds bye depth
  (wk9 Tate, wk10 Odunze). Score wk10.
- Auto after MNF: gate `ceiling_vs_margin.R` n 25 -> 30; `predictions.R score` (expect 3.18 of
  5 favourites right).
- Not testing, settled: lineup calls (15% band, layer at ceiling), K streaming (null, n 214),
  spread tiebreak (48.8%), multipliers (~1,000 player-wks needed), DvP beyond Yahoo (n 112, p
  0.20; accumulates, no call unless CI clears 0).

---

## Retro

*(append after Monday 2026-11-02. Never edit above this line.)*

---

### M1. Post-freeze, 2026-10-31 Sat. **Tate OUT (shoulder) -> Tucker starts WR.** Status: **DONE** — user swapped in Yahoo.

- Tate (TEN WR): nflreadr wk8 report (re-pulled 10-31 11:37) = `Out`, shoulder, DNP final
  practice. No wk7 tag, wk7 89% snaps -> new injury. TEN bye wk9 -> earliest return wk10.
- WR slot -> only bench WRs legal: Tucker 8.52 v Odunze 7.75 (10-28 export). Inside 15% band ->
  higher raw = Tucker. No kill, no retro score. Re-check on user's 10-31 Yahoo pull.
- Tucker: LV @ NYJ Sun 1pm (NYJ -1.5, total 45.5). Wk7 82% snaps, 12 tgt (28% share).
- Binder Sun 1pm (Tucker kickoff; Odunze plays Mon).
- `_myteam.csv` + frozen predictions NOT rewritten (pre-registered; this row beats the csv).
- **TR2 exposure (§3): Tate = half of what we send Max's.** `league_sim.R` base cannot see a
  fresh injury: TEN bye wk9 -> his last two applicable exports = wk7 + wk8 10-28, both
  pre-injury -> Tue re-run prices him healthy from wk10. Pre-registered 10-31: **Tue re-run adds
  Tate base 0 wk10 (wks 10-15 if IR). TR2 GO needs win-win in wins under it too. Fails -> re-scan
  Max's with Tate out of the package.**
- **Re-check, user's 10-31 Yahoo pull** (`*_2026-10-31.csv`, 14 files, rows match 10-28 within
  1%; read by date — `read_yahoo_week()` would mix both pulls): WR Boston 9.20, **Tucker 8.73**,
  Odunze 7.73, Tate `O` 0.00 -> **Tucker confirmed**. Yahoo: Tate O shoulder, updated 10-30
  8:06pm, no timeline. Burden + Likely clean, still Max's. Jacobs still Madison's. Every other
  slot still top proj.
- **QB flipped on position page: Stafford 17.94 > Kyler 17.74** (+0.20, 1.1%). Thu matchup page
  had Kyler 17.93 > 17.89. Rule = higher raw on matchup page -> user checks it; Stafford higher
  there -> swap before Sun 1pm (Kyler kickoff binds QB slot). Worth ~0.2 pts, ~+0.25pp P(win).
  Status: **KYLER — user's call 10-31, over rule (Stafford +0.20 on matchup page).** Inside 15%
  band -> no kill, no retro score. The 0.20 = choice regret in decomposition (ADR 0010), not
  projection error.
  - User 10-31: Stafford higher on matchup page too; argues Kyler (DET most QB pts allowed, LAC
    stingy, MIN 6-0). Checked, `dev/weekly/wk8_min_record.R` + `wk8_qb_dvp.R` re-run on 10-31 pull:
  - MIN 6-0 via defense: 12.3 pts allowed/g (1st), 20.8 scored/g (24th); wins 9-3, 15-10, 16-10.
    Vegas has the record -> MIN +3 dog in DET, implied 21.75 v LA 26.00 (LA -6.5 v LAC, 0-6).
  - Matchup already in Yahoo: Kyler 17.74 v own 11.1 ppg (14.6 last 3, best 18.3); Stafford
    17.94 v 18.6 (20.9 last 3).
  - Beyond Yahoo (QB-wks proj >= 12, wks 4-7, n 112): Kyler +0.73, CI [-3.65, +5.11] -> net of
    0.20 gap ~+0.5. Coin flip. Rule -> Stafford; either pick < 0.5 pts expected. No kill, no
    retro score.
- Proj (position page): us 103.98 w/ Stafford (103.78 w/ Kyler) v Michelle proj-optimal 117.90
  -> -13.9 (freeze -13.74) -> P(win) ~0.32, unchanged. Pickens (their DAL WR1) `Q` shoulder.
- Data note: TNF rows in this Sat pull read `Final` but `Fantasy Fan Pts` = still PROJECTION
  (Jacobs 14.98, decimal stat cols; scored 20.20 per nflreadr). CLAUDE.md trap (c) says Final ->
  points scored (wk3-5 Sunday pulls). Not universal -> read the decimals, not the Game cell.

### R1. T1 scored early, 2026-10-31 Sat. **Jacobs 71% snaps -> TR1 stays GO.**

- Jacobs (GB RB), TNF v CAR, GB won 27-19: 49 snaps, **71%** (wk7 52%). 21 car 39 yd, 6 rec on
  6 tgt 13 yd, 2 TD -> 20.2 half-PPR. Lloyd 16%, Strong 13% -> clear lead back.
- Kill line 50% -> not fired. TR1 re-run Tue 11-3 on wk9 export, as planned.
- Big game raises his price to Madison too -> re-run prices it (base = mean non-zero proj).

### R2. Wk8 final, 2026-11-03 Tue. **L 87.50-125.22 -> 4-4, 6th.**

Source: Yahoo Matchups screenshot 11-03 (authority; Yahoo proj at final 103.87 v 113.09) +
`*_actual_2026-11-03.csv` (9 starters sum 87.50 exact) + nflreadr 11-03 (MNF in).

- **Result.** Best legal 103.04 (Mahomes 25.44 QB, Odunze WR, Strange FLEX) -> still L by
  22.18 -> 0 of 5 losses winnable by any lineup. Regret **15.54** = our deviation **−11.62**
  (Kyler call) + projection error **+27.16**.
- **C1 Tucker claim** — decision right (top wire opportunity, rule followed). Outcome bad so
  far: 1 tgt (4%), 54% snaps, 0.00 -> both kill legs under, wk 1 of 3. Score wk10. X1 ships him.
- **C2 Commanders DST** — decision right (PHI opp implied 18.0, lowest). Outcome good: 13.00
  (WAS 27-10) v Chiefs 0.00, Browns 3.00. One week = 0.39 sd -> not evidence either way.
- **§2 holds** — K: Bates 7.00 v Cam Little 6.00, right (K rule null, retired). RB no add: Pierce
  (PHI) 0.00, now IR -> right.
- **M1 Tucker for Tate** — forced (Tate `O`); Tucker 8.73 v Odunze 7.73 inside band -> higher
  raw. Outcome bad: 0.00 v 10.70. Coin flip by rule -> not a wrong decision, no score.
- **Kyler (user call over rule)** — outcome only: Kyler 20.90 v Stafford 9.28, +11.62. Inside the
  15% band -> coin flip; not evidence for DvP or overrides.
- **TR1/TR2** — retired unsent (review 002 §3: partner fails on ppg; TR2 fails Tate-out bound;
  TR1 win-win = `settle()` bug). Right for cause. Outcome note: TR2 sent 10-28 -> Burden 15.10 in
  Tucker's slot -> 102.60, still L. TR1 had zero wk8 value by construction.
- Status, no grades. **T2** Burden wk8 share 26% (line 15%) -> feeds X1. **T4** stopped (review
  §7); wk8 point: margin MAE Yahoo Thu 17.97 v model 18.79, n 5. **T5** = C1 kill above. **T3**
  (Yahoo DST proj v rule) not run -> run only if the two pick different wk9 DSTs. Gate n 30:
  r +0.564, p 0.001; wk8 favourites 5/5 (gate), frozen predictions 4/5 (miss = 50.2% flip).
