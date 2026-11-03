# Handoff #50 — Tue 11-3 RUN SHEET. Wk8 L -> 4-4. Pull -> score wk8 -> re-price X1/D1/O3 -> send by 9pm. Thu: freeze wk9.

**User first, Tue afternoon:** Yahoo pulls + Matchups screenshot (§2A), then paste into Claude Code:
`Read docs/handoff/ffdraft-handoff-20261102-43-WEEK8-LOST-TUE-OPS.md and run Tuesday ops. Wk8 finals attached.`

Written 2026-11-02 Mon AM; **rewritten Mon PM after review 002** -> folds in #52 §2. **This doc =
Tuesday authority**; #52 = meta-analysis summary. Old text: git `b93e6a4`. Branch `week3-gameday`
at `8f136c3`, pushed; this rewrite + index rows 50/52 uncommitted.

---

## 0. READ FIRST.

- `docs/review/002-season-meta-analysis.md` §3 (trade set), §2a (DST, tickets). ADR 0012 = trade
  GO rule. ADR 0013 = underdog: season-level upside yes, weekly variance no.
- Wk8 log `data/weekly/2026_week08_decisions.md`: §3 trades, §5 tests, `## Retro` M1 + R1.
- `CLAUDE.md` weekly loop slimmed 11-02 — **user has not reviewed it** -> mention once.
- Numbers here = prior claims. Every number on the card comes from a script run Tue.

## 1. State, Mon 11-02 PM.

| item | state |
|---|---|
| record | 4-4 after wk8 L 87.50 (nflreadr calc; Yahoo final = authority). Wk9 v **Steel City** |
| P(top 4) | ~3% (2.84% w/ provisional wk8; 2.17% Tate-out bound). Rerun Tue |
| trades | **X1 + D1 + O3** (§3). TR1/TR2 retired (review §3) |
| roster flags | Tate (TEN WR) `O` shoulder, TEN bye wk9 -> earliest wk10. IR: Etienne (~0), Adams (~wk12). Commanders = DEF2, dead spot |
| Tucker (LV WR) T5 | wk 1 of 3: 1 tgt, 54% snaps. Kill < 5 tgt/g or < 60% snaps wks 8-10. X1 ships him |
| nflreadr | pulled 11-02 08:29, no MNF -> re-pull Tue |

## 2. Tue 11-3. User ~45 min, agent ~1.5-2 h. Pulls by ~3pm -> card by ~5pm -> sent by 9pm.

**A. User, afternoon.**
1. claude.ai collector: wk8 actuals (`mode:'actual', week:8`) -> `docs/uploads/week_8_data/`.
2. claude.ai collector: wk9 projections -> `docs/uploads/week_9_data/` (new folder).
3. Yahoo Matchups screenshot, all 5 wk8 finals (10 scores). Paste the trigger line above.

**B. Agent, data, ~45 min. Order matters (§4.1).**
1. Check: `week_9_data` = one pull, 6 position files, every Game cell unstarted;
   `*_actual_2026-11-03.csv` in `week_8_data`. Missing -> stop, ask user.
2. `Rscript dev/weekly/pull_nflreadr.R` (adds MNF CHI @ SEA).
3. 10 wk8 rows into `data/weekly/2026_league_schedule.csv` from the screenshot ->
   `Rscript dev/weekly/schedule_check.R`.
4. `dev/weekly/ceiling_vs_margin.R`: add the wk8 `EX` entry after `7` (move the closing paren),
   run. Gate n 25 -> 30; noise constants move every sim number.
   ```r
   `8` = c(sprintf("%s/week_8_data/yahoo_week8_%%s_2026-10-31.csv", U), sprintf("%s/week_8_data/yahoo_week8_%%s_2026-10-28.csv", U)))
   ```
5. `Rscript dev/weekly/predictions.R score` (expect 3.18 of 5 favourites). Skip
   `leaguewide_retro.py` — no decision rides on it.

**C. Agent, decisions, ~45 min.**
1. `Rscript dev/weekly/playoff_odds.R` -> P(top 4), wk9 P(win) v Steel City, exchange rate.
2. Trades. `docs/review/002-evidence/a3_trades/perceived.R` line 13:
   `week_8_data/yahoo_week8_%s_2026-10-31` -> `week_9_data/yahoo_week9_%s_<DATE>`. Then:
   ```bash
   Rscript docs/review/002-evidence/a3_trades/perceived.R
   Rscript docs/review/002-evidence/lead/offer_set.R | tee data/weekly/2026_week09_offer_set_mean.out
   BASE=latest Rscript docs/review/002-evidence/lead/offer_set.R | tee data/weekly/2026_week09_offer_set_latest.out
   ```
   GO per offer: §3.
3. `TMPL=docs/uploads/week_9_data/yahoo_week9_%s_<DATE>.csv WEEK=9 Rscript dev/weekly/wire_scan.R`
   -> DST by opp implied total (ADR 0011; 11-02 lines: hold Chiefs v NYJ 18.5, Commanders v LA
   26.5) + RB tickets >= 10 touches+tgt/g.
4. Wk8 retro, below R1 in the wk8 log: one line each — C1 Tucker, C2 Commanders, §2 holds, M1
   Tucker-for-Tate, Kyler (user call, outcome only), TR1/TR2 (retired unsent). T2/T4/T5 = status
   notes, no grades. Decision wrong v outcome bad.
5. New `data/weekly/2026_week09_decisions.md`: card (§5) on top, then one line per
   offer/claim/drop/hold, each with its pre-registered kill. Show the card.

**D. User, by 9pm, ~15 min.**
1. Send GO offers, one per partner, pitch lines from the card.
2. Waiver claims, stacked in scan order (11-02: Jonah Coleman DEN RB > Mike Washington Jr. LV RB
   > Kenny Gainwell TB RB), each dropping Commanders. Clears Wed. Not Achane (ACL, season over).
3. Report what went out -> agent logs it with date.

After send, if time: wk8 row in the `data/weekly/README.md` regret table.

## 3. Trade set (review §3; 11-02 numbers, re-price Tue).

| offer | partner | we give -> we get | ΔP mean / latest | why them | kill, wks 10-12 |
|---|---|---|---|---|---|
| X1 | Max’s TD Bombers | Mahomes + Tre Tucker + Brenton Strange -> Luther Burden III (CHI WR) + Tucker Kraft (GB TE) | +1.74 / +1.29 | WR thin (D. Smith, RJ Harvey `O`); QB cover for Dak's wk14 bye | Burden share < 15% avg 3 g, or Kraft snaps < 60% |
| D1 | Dave’s Bone Crushers | T.J. Hockenson -> Jalen Coker (CAR WR) | +1.75 / +1.72 | TE hole (Andrews 7.4, Pitts 6.8); rival for 4th | Coker share < 15% |
| O3 | Owl Out Blitz (long shot) | Matthew Stafford -> Matthew Golden (GB WR) + George Kittle (SF TE); 1-for-2, drop Odunze | +3.99 / +5.92 | near-lock -> arming costs ~0; sharpest manager | Golden share < 18% or Kittle snaps < 70% |

- **GO = our ΔP > 0 under BOTH bases AND partner ppg >= −1 AND paper >= −2** (ADR 0012).
  Incoming players not `O`/IR; still on the partner's roster (`apply_trade()` stops if not).
- No-GO -> don't send, no same-day improvising. Re-scan that partner Wed.
- One offer per partner, no player in two offers. Pitch in their numbers (season ppg, last 3,
  their hole), never our projections.
- Accept by Thu 11-5 -> counts wk9. Not accepted by Thu -> re-offer with Odunze as sweetener if
  still free. 0 accepted of >= 4 offers by 11-20 -> stop asking. Last send Tue 11-24 AM.
- Stafford + Kyler both gone -> claim a wire QB for LA's wk11 bye. X1 + O3 keeps Kyler -> no hole.

## 4. Gotchas.

1. **Enter wk8 scores before ANY sim.** `league_sim.R` has no guard for an unscored week < CUR:
   wk9 export -> CUR 9 -> wk8 vanishes (W0 from wks 1-7, 14-game season), no error.
2. `perceived.R` + `offer_set.R` overwrite their committed `.rds`; the 11-02 versions stay in git
   `0f22cd0`. The `.out` tees are the wk9 record.
3. `offer_set.R` zeroes Tate (Tate-out world). `league_sim.R` alone prices him healthy from wk10:
   TEN bye wk9 -> base from pre-injury wk7 + wk8 exports.
4. `read_yahoo_week(dir, date)` stops on 2+ pulls -> pass `date` (`week_8_data` holds 10-28 +
   10-31). `_actual_` files sit outside its whitelist.
5. Moves after the Tue export: trade landed -> fresh wk9 pull Thu (`TXN` takes wire add/drop
   only); claim only -> `TXN` row in `league_sim.R`.

## 5. Card, ~10 lines, top of the wk9 log.

Data check | wk8 result, record, rank | P(top 4) + wk9 P(win) | DST | hole + claim | trades GO/NO |
kills armed | lineup (Yahoo projection, Thu lock).

## 6. Thu 11-5 + Sun 11-8.

- **Thu, before 8:15pm ET** (TNF JAX @ BAL: Henry plays): set lineup to the card.
  `freeze_lineups.R`: `WK <- 9L`, `slots_me` = card lineup, `slots_op` = Steel City
  projection-optimal, `mk("Steel City", slots_op)`. Run
  `YDIR=docs/uploads/week_9_data YDATE=<newest clean pull> Rscript dev/weekly/freeze_lineups.R`,
  then `Rscript dev/weekly/predictions.R freeze`.
- **Sun 11:45am ET**: any starter `O`/IR/inactive -> best legal bench body. CIN @ ATL kicks
  9:30am: no player of ours or incoming plays in it -> 11:45 stands.
