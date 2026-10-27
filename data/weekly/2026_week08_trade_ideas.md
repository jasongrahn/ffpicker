# Week 8 trade ideas — 2026, JGrahnasaurs. Written 2026-10-21 Wed. **NOT SENT.**

Revisit after week 7 closes (MNF 10-26). Source: `dev/weekly/trade_finder.R` on the week-7
export (10-21) + M1 (Kyler in, Butker out). 15,675 trades scanned, every shape built on our
QB surplus, vs all nine rosters. Scan saved: `data/weekly/2026_trade_scan_wk7.rds`.
**Numbers below go stale in a week. Re-run (§5) before sending anything.**

---

## 0. Why trade at all. From `dev/weekly/playoff_odds.R`.

- 3-3, 6th. Roster projects **9th of 10** for wks 8-15. Ceiling ranks wks 3-6: 7, 10, 9, 6.
- **P(top 4) 3.3%** (5.8% with strength uncertainty). Expected final wins **5.9**.
- Need **9 wins = 6-3 the rest of the way** -> 67% in. 10 -> 99%. 8 -> 8%.
- Gate PASSED (`ceiling_vs_margin.R`, n=20): ceiling diff -> margin r +0.49, p 0.03, slope ~1.
  Roster strength is the lever. Lineup layer already at ceiling (`CLAUDE.md`).
- Exchange rate: **+1 pt/wk ~ +0.09 wins, +0.7pp** P(top 4). +5 -> +0.47 wins, +4.1pp.
  +10 -> +0.96 wins, +11pp.

## 1. The finding that shapes every offer. Our QBs are weak currency.

Starting QBs sit on the wire: **Brissett** (ARI, waivers) 17.1, **Rodgers** (PIT, FA) 16.7,
**Cousins** (LV, FA) 16.1. Any team gets a starter free -> max partner gain from any of our
QBs **+1.2 pts/wk** (Madison <- Stafford). **Mahomes' NAME is the currency, not his points.**

Kyler (MIN, no bye left, base 18.5) ~ Stafford (19.2, bye 11) ~ Mahomes (18.4). Any two are
tradeable; one QB covers every week, Stafford's wk11 bye aside.

## 2. Send order. **Tue 10-27, after week 7 ends.** Not before.

Both primary offers carry wk7 starters (Tate, Hockenson) -> frozen lineup breaks. Madison is
the wk7 opponent -> a trade arms them for Sunday. **Check first: trade deadline** (Yahoo ->
League -> Settings). Not in `config/league.json`.

### TR1. To Monday Night Madison: **Kyler Murray + T.J. Hockenson -> Josh Jacobs** (GB RB, 11.4)
- Us **+2.2 pts/wk, +2.1pp P(top 4), +0.32 wins.** Them +0.0 on paper.
- Madison 1-5, out of the race (P ~0) -> arming them costs us nothing. 12 moves, active.
- Hockenson `Q` concussion -> they may wait for protocol.
- Alt: Mahomes + Hockenson -> **Jeremiyah Love** (ARI RB, rookie, `Q`): +2.1, +1.9pp.

### TR2. To Max's TD Bombers: **Mahomes + Carnell Tate -> Luther Burden III** (CHI WR, 10.5) **+ Isaiah Likely** (NYG TE, 9.7)
- Us **+2.9 pts/wk, +2.3pp, +0.30 wins.** Them +0.1 on paper, their P(top 4) -0.2pp.
- Their QBs: Dak only, Hurts on IR -> Mahomes is real insurance. 5 moves.
- Alt: Stafford + Tate -> Burden + **Tucker Kraft** (GB TE): +2.5, +1.9pp.

**TR1 + TR2: +5.0 pts/wk, P(top 4) 3.3% -> 8.3%, +0.61 wins.** Leaves Stafford as only QB ->
stream a FA QB for his wk11 bye (Rodgers/Brissett class). Sim already assumes that fill.

### TR3 (alternative to TR2). To Sunday Kevin: **Stafford + Ollie Gordon II -> Malik Nabers** (NYG WR, 11.5) **+ Travis Kelce** (KC TE, 9.3)
- Us +3.1 pts/wk, +2.4pp, +0.33 wins. Them +0.1 on paper — **but their P(top 4) +6.7pp.** 3rd
  place. Arms a direct rival more than it helps us.
- 1 move all season -> may never answer.
- TR3 + TR1: +5.35 pts/wk, +5.6pp, +0.67 wins. Best pair on paper, worst on acceptance.

## 3. Long shots. Partner LOSES on paper. Only if they overrate Mahomes' name. Free to ask.

| to | give | get | us pts/wk | us ΔP | them pts/wk |
|---|---|---|---|---|---|
| Owl Out Blitz | Mahomes + Strange | **Matthew Golden** (GB WR) + **George Kittle** (SF TE) | +6.1 | +6.6pp | -2.0 |
| Owl Out Blitz | Mahomes | **Jaylen Waddle** (DEN WR) + Kittle | +5.0 | +4.6pp | -1.0 |
| Jason's Jazzy | Mahomes + Hockenson | **Zay Flowers** (BAL WR) | +4.7 | +4.5pp | -1.8 |
| Max's | Mahomes | **DeVonta Smith** (PHI WR) + Kraft | +4.6 | +4.4pp | -1.9 |
| Sunday Kevin | Mahomes | Nabers + **Tyler Warren** (IND TE, `Q`) | +4.4 | +4.3pp | -1.1 |

Owl Out = sharpest manager (5-1, beats own ceiling +13.8/wk, streams). Expect no.

## 4. Ruled out.

- **Dropping Stafford.** No FA beats a starter: best Sutton (DEN WR) 8.2, Pierce (PHI RB) 8.1,
  H. Henry (NE TE) 7.5. A dropped Stafford is a free QB for a rival. Trade him or keep him.
- **McLaurin** (WAS WR, waivers). Topped the wire on base 9.85 — `O`/knee, snaps 75 -> 58 -> 10.
  Odunze 96-99% snaps last 3. Usage kills it (`CLAUDE.md`: snaps before ppg).

## 5. Re-run before sending. Tue 10-27, ~10 min.

1. Pull week-8 exports -> `docs/uploads/week_8_data/` (`yahoo-ff-collector`).
2. `Rscript dev/weekly/pull_nflreadr.R`.
3. Enter wk7 scores in `data/weekly/2026_league_schedule.csv` (Yahoo -> League -> Matchups ->
   Week 7: one screenshot, all 5 games) -> `Rscript dev/weekly/schedule_check.R`.
4. `Rscript dev/weekly/ceiling_vs_margin.R` -> L1a gate check, n = 25.
5. `Rscript dev/weekly/trade_finder.R` — `league_sim.R` picks up the week-8 export by itself.
   Confirm each offer still win-win, players healthy, partner still owns them.

## 6. Pre-registered kill conditions, if executed. Role, not points — n is tiny.

- **TR1:** Jacobs snap share **< 50%** in any of wks 8-10 -> role read wrong.
- **TR2:** Burden target share **< 15%** over wks 8-10, or Likely snaps **< 60%** -> wrong.
- **TR3:** Nabers target share **< 20%** over wks 8-10 -> wrong.
- Points verdict needs ~10 weeks (per-player-week sd ~8 vs a +3 edge). **Do not grade a trade
  on wks 8-9 points.** Score it in wins: rerun `playoff_odds.R` with vs without.

Model limits: base = mean of Yahoo weekly projections (no ROS projections exist); no IR
returns (Adams earliest wk12); no future moves beyond bye-hole fill; n = 6 scored weeks.
**Tests, not models.**
