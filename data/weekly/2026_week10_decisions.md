# Week 10 Decisions — 2026, JGrahnasaurs (5-4, 4th)

Opened **2026-11-10 Tue**. Cruise control (wk9 log §3). Wk9: **W 107.46-84.86** v Steel City.

Source of record: `docs/uploads/week_9_data/*_actual_2026-11-10.csv` + `data/nflreadr/pull_2026.rds`
(pulled 11-10 10:21, MNF in). Wk10 Yahoo pull: pending (user).

## Tue 11-10 data check

| item | read |
|---|---|
| F1 | **A.J. Brown claim LANDED** (Sat 11-7), Kyler dropped -> `TXN` row added (`league_sim.R`) |
| trades | none processed: Hockenson, Tucker, Strange, Odunze still ours -> D1 / K2 / J1 pending or dead |
| roster | **illegal: Tate (IR slot) now `Q`, not `O` -> not IR-eligible -> 16 active for 15** |
| standings | 5-4, 4th. Yahoo PF/PA = ours except wk7 Steel City 84.88 -> 84.78 (stat correction after 10-27 snapshot; `schedule_check` validates v that snapshot -> row left as-is) |

## 1. Moves

| # | move | why |
|---|---|---|
| M4 | **Drop Kendre Miller** (NO RB), **activate Tate** off IR | Miller wk9: 0 snaps, no injury tag. Estime 47%, Kamara 49%. Claim kill (wk9 log: < 8 opp/g or < 40% snaps wks 9-10) fired -> drop by rule. Every other body >= 36% snaps wk9 |

Usage, carries+targets / target share % / snap %, wks 7-9 (`load_player_stats`, `load_snap_counts`):
Miller 13/13/39, -, - | Price -, 14/12/48, 13/14/36 | Henry 19/6/51, 13/8/45, 17/0/50 |
Strange -, 2/12/52, 2/8/79 | Tucker 12/28/82, 1/4/54, 8/25/64. Tate (TEN bye 9) last 7/23/89 wk7.
Brown `O` wk9 (ankle), `Q` now; NE bye 11.

- Price kill watch (wks 9-10 < 8 opp/g or < 40% snaps): wk9 13 opp / 36% snaps -> snap leg under. Wk10 decides.

## Card, Tue 11-10 (`week_10_data/*_2026-11-10.csv`, 0 started games ✓, Miller gone, 15 active + Adams IR)

| item | read |
|---|---|
| odds | P(top 4) **9.3% mean / 8.5% latest** (sim ~2pp low). **> 3% -> stop rule says resume.** Wk10 v Dave’s P(win) 34% (100.0 v 111.9); W -> 19.5%, L -> 4.1%. Underdog all 6 games (27-39%). 9 wins -> 73%, 8 -> 9.5%, 7 -> 0 |
| exchange | +1 pt/wk = +1.0pp; +5 = +5.9pp; +10 = +13.8pp |
| DST | Chiefs @ ATL opp implied 21.0 (9th). **Ravens** v LAC 16.5 (2nd, `W (Nov 11)`), Texans v CLE 17.5 (3rd, W, Yahoo 8.40). Rule: -0.40/implied pt -> Ravens +1.8, Texans +1.4 |
| trades | top both bases: **one QB -> Christian Watson (GB WR) + Tyler Warren (IND TE), Sunday Kevin**: +5.19 / +5.43 pts/wk, **+8.4 / +8.2pp**, drop Price. Kevin paper −1.81 / −1.47. Partner-ppg check (ADR 0012) NOT run. Conflicts w/ pending K2 (Watson). D1 / K2 / J1: 7 days, no reply |
| lineup (Thu re-read) | QB Mahomes 18.86 `Q` (v Stafford 18.06) / RB J. Williams 15.17, Henry 14.82 (Mon) / WR Tate 10.59 `Q`, **Brown 9.23 `Q`, Sun 9:30am ET (NE @ DET)** / TE Strange 8.50 / FLEX Gordon 11.96 / K Bates 8.75 (9:30am) / DEF Chiefs 5.55. Odunze CHI bye |

- Brown + Bates kick 9:30am ET -> Sun 11:45 check too late for Brown. Check Brown status before 9:30am; `O` -> Boston 8.66.

## Trades, Tue 11-10

Replies: **D1 (Dave’s) DECLINED, K2 (Sunday Kevin) DECLINED.** J1 (Jazzy) open, 7 days, no reply.
ADR 0012 log: 0 of 2 answered offers accepted; D1 was partner ppg **+0.37**, K2 −0.37 -> ppg >= −1
bar too loose for contenders -> bar for contenders now **ppg >= 0** (CLAUDE.md).

- **Card row above (Kevin QB -> Watson + Warren) WITHDRAWN**: Kevin ppg **−2.95** -> fails. Was
  `trade_finder.R` output surfaced before the ppg check.
- Screen: `lead/wk10_search.R`, 236,028 trades x 2 bases, perceived.R -> wks 1-9. Pass ADR 0012
  both bases: 7,746; partner ppg >= 0: 4,985. Priced: `lead/wk10_menu.R` -> `2026_week10_offer_menu_{mean,latest}.out`.

| # | partner (P(top 4)) | we give | we get | dP mean / latest | partner ppg / paper | verdict |
|---|---|---|---|---|---|---|
| **KN** | Sunday Kevin (36-41%) | Javonte Williams + Tre Tucker | Chris Olave (NO WR) + Malik Nabers (NYG WR) | **+4.54 / +4.77** | **+0.46** / −1.00, −0.79 | **GO**. Kevin dP +0.1 / +0.6 |
| MH | Maybe Mitchell (20-22%) | Jadarian Price + T.J. Hockenson | Breece Hall (NYJ RB) + Sam LaPorta (DET TE) | +3.14 / +2.79 | +0.23 / −1.54, −1.66 | weak pitch: Mitchell's need = WR, gets RB + TE2 |
| J1 | Jazzy (87-91%) | Rome Odunze | Rhamondre Stevenson (NE RB, `D`) + DK Metcalf (PIT WR) | +2.10 / +0.95 | 0.00 / −0.55, −0.19 | still positive; leave open or cancel = user |
| DH | Dave’s (35-41%) | T.J. Hockenson | Brock Purdy + Tetairoa McMillan | +7.49 / +10.66 | +0.29 / −0.87, −1.22 | NO: D1 (same shape, less asked) declined |
| DV | Dave’s | Rome Odunze + Brent. Strange | Brock Purdy + Tetairoa McMillan | +7.30 / +9.31 | −0.68 | NO: contender ppg < 0 |
| KQ | Sunday Kevin | Mahomes | Watson + Warren | +8.27 / +6.46 | **−2.95** | NO |

- KN logic: Kevin WR4 deep (Watson 16.5, St. Brown 14.8, Nabers 13.8, Olave 12.8 view; 2 WR + FLEX)
  -> one sits weekly. RB3 = Dobbins 5.3 -> FLEX takes WR3. Williams 16.2 view in FLEX > Nabers 13.8.
- Set (`lead/wk10_set.R`): KN+MH +7.97 / +8.09; KN+MH+J1 +9.40 / +7.22; every subset > 0 both bases.
- Usage wks 6-9 (carries+tgt / tgt share % / snap %): Nabers 15/35/86, 9/33/73, -, 8/30/79; Olave
  7/23/58, 10/26/77, -, 12/38/85; Hall wk9 only 19/13/43 (back from injury, 4 g); LaPorta 6/20/93, 5/20/90.
- **Bottom 3 scan** (user: "good players ... not fully utilized"). Michelle / Steel City / Madison targets
  (Chase, Gibbs, Love, Nix, Loveland, Godwin, Egbuka, Barkley, Fannin, Rice, K. Williams, G. Wilson):
  Chase, Gibbs, Barkley, Tuten, Collins -> **no fair trade** (cheapest = partner ppg −10..−23). Love,
  Nix = QBs behind starters -> no use to us (QB surplus). Best fair: **S1** Steel City, A.J. Brown +
  Hockenson -> Garrett Wilson (NYJ WR, `Q`, 23% share, 88% snaps) + Colston Loveland (CHI TE, 26%
  share, 88% snaps): +1.77 / +0.33pp alone, ppg +0.47, Steel City P(top 4) ~0 -> free to arm.
  KN+S1 **+6.56 / +5.71** v KN +4.54 / +4.77 (`lead/wk10_low.R`, `2026_week10_low_set_{mean,latest}.out`).
  S2 (Hockenson -> Godwin + Loveland) +0.51 / +0.65 -> skip.
- Kills, wks 11-13 (window after send): KN Nabers or Olave share < 15% avg 3 g; S1 G. Wilson or
  Loveland share < 15% avg 3 g; MH Hall < 10
  carries+tgt/g or LaPorta snaps < 60%; J1 Stevenson < 10 carries+tgt/g or Metcalf share < 15%.
- **11-10 user: one offer at a time, Steel City first, 2-for-2 Chase.** Brown + Hockenson -> Ja'Marr Chase (CIN WR)
  + Loveland: **+9.71 / +9.87pp** both bases. Steel City ppg **−10.56** (Yahoo Evaluate Trade: them −57.48, us +52.81)
  -> fails ADR 0012; user sends as goodwill ask (SC 2-7, P ~0). Loveland CHI bye wk10 -> Strange starts TE, no hole.
  Veto risk: League Votes, rivals Dave’s / Kevin / Mitchell. Fallback if no: Brown + Hockenson -> G. Wilson + Loveland
  (ppg +0.47). Then Kevin (Javonte Williams + Tucker -> Olave + Nabers). Kill wks 11-13: Chase or Loveland share < 15% avg 3 g.
  Pricing: `lead/wk10_chase.R` -> `2026_week10_chase_{mean,latest}.out` (5 seeds).
- **11-10 Chase offer SENT** (Brown + Hockenson -> Chase + Loveland, goodwill note). **J1 CANCELLED.**
- Michelle Gibbs scan (user: "basically out", goodwill ask). Sim: Michelle P(top 4) **10.3%** v ours 9.4% (3-6 but PF 4th)
  -> not out by the numbers. Gibbs (DET RB, no bye left), both bases, dP us / Michelle ppg:
  Odunze + Tucker -> Gibbs + Jordan Mason **+22.7 / +18.4pp**, ppg −10.6 (ask); Tucker -> Gibbs +22.5 / +18.4, −11.8;
  JW + Tucker -> Gibbs + Mason **+13.7 / +11.5pp**, ppg −5.4 (fallback); JW -> Gibbs +13.7 / +11.5, −6.3.
  With Chase deal: ask +40.1 / +36.3pp, fallback +29.6 / +27.5. Kevin offer parked (user: Kevin 4-5 holds out; shares
  Tucker / JW with these). Veto risk compounds: 2 lopsided deals -> Dave’s 41%, Kevin 36%, Mitchell 20% pay for it.
  Pricing: `lead/wk10_gibbs.R` -> `2026_week10_gibbs_{mean,latest}.out`.
- Mason = throw-in, worth ~0 to us (Tucker -> Gibbs = Odunze + Tucker -> Gibbs + Mason, both bases) -> **ask = Tucker for
  Gibbs 1-for-1** (+22.5 / +18.4pp, keep Odunze). Fallback = JW for Gibbs 1-for-1 (+13.7 / +11.5pp).
- **11-10 Gibbs offer SENT** to Michelle: Tucker -> Gibbs 1-for-1, goodwill note. Open now: Chase (Steel City), Gibbs (Michelle). Kevin parked.
- **11-11 Wed**: Ravens claimed, Chiefs dropped (user). `TXN` row once a pull confirms. Chase + Gibbs offers: no reply, day 1.
- **11-12 Thu: Michelle DECLINED Tucker -> Gibbs.** Next (`lead/wk10_mich2.R` -> `2026_week10_mich2_{mean,latest}.out`):
  JW -> Gibbs +13.66 / +11.52pp, Michelle ppg −6.28 (planned fallback); fair alt JW + Odunze -> Kyren Williams (LA RB, bye 11)
  + Rashee Rice (KC WR) +3.34 / +2.72pp, ppg **+0.17**, paper −3.97 (her Yahoo screen red). Chase offer: no reply, day 2.
- **11-12: Michelle does not want to trade, at all** -> no more Michelle offers. JW + Tucker free again.

## Deferred -> wk11 Tue 11-17 (user 11-12: "for after this week ends")

- **Kevin offer, NOT sent:** Javonte Williams + Tre Tucker -> Chris Olave (NO WR) + Malik Nabers (NYG WR). 11-10 price:
  **+4.54 / +4.77pp**, Kevin ppg **+0.46**, Kevin dP +0.1, paper −1.00 / −0.79. Before sending: re-price both bases on the
  wk11 pull (`lead/wk10_menu.R` row KN) + re-run ppg check (wk10 actuals move it). **Wk11 opponent = Kevin** -> a trade
  landing before wk11 lock changes that matchup; check our wk11 P(win) with and without. Note:
  "Your WR room is stacked and one of them sits every week. Javonte's been putting up 16 a game and would start in your
  FLEX every week. JW + Tucker for Nabers + Olave?"
- **11-12 wire check** (11-10 pull; waivers cleared 11-11 -> FA first-come): no FA beats a starter outside the 15% band.
  Best: K Eddy Pineiro (SF) 9.43 v Bates 8.75 (K = hold, ADR 0011); TE Gesicki 8.04 < Strange 8.50; WR Flournoy 8.60 <
  Brown 9.23; DEF Texans 8.40 v Ravens 7.67 Yahoo, but opp implied 17.5 v 16.5 -> Ravens by rule. Dave’s 118 (Yahoo,
  user) = Allen 24.3 + Bijan 18.1; not wire-fixable.
