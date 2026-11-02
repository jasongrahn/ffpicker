# Handoff #50 — Wk8 LOST (87.50 v ~113-133). Tue 11-3: wk8 retro -> wk9 pull -> TR1 + TR2 re-run -> send. Thu: freeze wk9.

Written 2026-11-02 Mon morning, before MNF (CHI @ SEA). Branch `week3-gameday`, pushed through
`2f1b2a8`. **All work since #47 uncommitted.** Prior: #49 — its §2 recipe + §3 gotchas still
hold; its state + order superseded here. **#51 = next conversation (meta-analysis). It does NOT
replace this Tuesday list.** If #51 ran first, read its output (`docs/review/002-*`) before
step 4 — it may change TR1/TR2.

---

## 0. READ FIRST.

- Wk8 authority: `data/weekly/2026_week08_decisions.md` — §3 trades, §5 tests, `## Retro` M1 + R1.
- Named-trade recipe, Tate-out bound, `fut()` drops CUR: #49 §2. Silent bugs: #49 §3
  (`read_yahoo_week()` keeps OLDEST pull; sim base blind to fresh injury). Don't re-derive.
- Wk8 numbers below = nflreadr calc (`dev/weekly/wk8_sunday.R`), not Yahoo. **Yahoo matchup page
  = authority for the retro.**

## 1. State.

| item | state |
|---|---|
| record | **4-4** after wk8 L (Yahoo to confirm). Wk9 v Steel City |
| wk8 us | **87.50** v proj 103.78. J. Williams 6.20 (24 car 56 yd, 0 TD; -10.50), Tucker 0.00 (1 tgt, 54% snaps; -8.73), Gordon -4.60. Up: Commanders DEF 13, Hockenson 13.80, Kyler 20.90 |
| wk8 Michelle | ~113 (Love at QB) to ~133 (Burrow) under 10-29 guess lineup, + SEA DEF (MNF). Burrow 42.48 (462 yd, 5 TD, 3 INT; +20.59), Fannin 18.40 (+10.22) |
| QB call | Kyler 20.90 v Stafford 9.28 -> user's call **+11.62 realized** (expected -0.20). 15% band -> no retro score; outcome only |
| bench | Mahomes 25.44, Strange 6.50, Chiefs DEF 0, Odunze MNF |
| P(top 4) | 10-28 conditional on wk8 L = **2.7%**. Re-run Tue with all 5 results |
| TR1 Kyler + Hockenson -> Jacobs (Madison) | GO (T1 passed, R1) |
| TR2 Mahomes + Tate -> Burden + Likely (Max's) | not sent. Tate-out bound mandatory (log M1) |
| Tucker (LV WR) | T5 wk 1 of 3: 1 tgt, 54% snaps (wk7 82%). Kill = < 5 tgt/g or < 60% snaps over wks 8-10. Cause unknown -> Wed injury report |
| nflreadr | re-pulled 11-02 08:29, 13 of 14 wk8 games. Re-pull Tue (MNF) |

## 2. Tue 11-3, in order. ~2 h agent, ~45 min user (pulls run unattended).

1. **User:** Yahoo wk8 actuals (`mode:'actual', week:8`) + wk9 projections (`week_9_data/` must
   exist) + Matchups screenshot, all 5 wk8 finals. Collector runs from claude.ai, not here.
2. `pull_nflreadr.R` -> wk8 scores into `2026_league_schedule.csv` -> `schedule_check.R` ->
   `ceiling_vs_margin.R` (gate n 30) -> `predictions.R score` (expect 3.18 of 5 favourites).
3. **Wk8 retro** below R1 in the log: result + margin, T2 (Burden wk8 share — never holds TR2
   alone), T4 (n 5 of 30, no call), T5 note, regret. Decision wrong v outcome bad, per item.
4. `playoff_odds.R`, `trade_finder.R` (CUR auto = 9) -> named TR1 + TR2 re-run, #49 §2. GO =
   win-win in wins, incl. Tate-out bound.
5. **GO -> user proposes TR1 + TR2 same day.** Max's must accept by ~Thu 11-5 for wk9. Log send
   dates below `## Retro`.

Same day if time: T3 DST desk test (~30 min) -> wk9 DST method. Etienne (NO RB, IR) back from bye
-> activation needs a drop. Both trades land -> Stafford only QB, LA bye wk11 -> FA QB. FA move
after the export -> `TXN` row in `league_sim.R`.

**Thu 11-5, before TNF: freeze wk9.** `freeze_lineups.R`: `WK <- 9L`, `YDIR`, slot list; then
`predictions.R freeze`. Two wk9 pulls in one folder -> `read_yahoo_week()` reads the older (#49 §3.1).

## 3. New since #49.

- Wk8 played: L, §1. Kyler logged as user's call over rule (log M1).
- Scratch -> `dev/weekly/`, all wk8-hardcoded: `wk8_sunday.R` (mid-week scorer: Yahoo rosters +
  `attach_nfl_ids()` + `score_player_week()`; DST approximated from `team_stats` + config PA tiers,
  **unvalidated v Yahoo**), `wk8_qb_dvp.R` (DvP beyond Yahoo, n 112), `wk8_min_record.R`.

## 4. Uncommitted. Commit only when user asks. PR owed (`gh`).

#49 §6 list + handoffs #50, #51 + `dev/weekly/wk8_{sunday,qb_dvp,min_record}.R` +
`docs/uploads/week_8_data/*_2026-10-31.csv`.

## 5. Suggested skills.

| skill | when |
|---|---|
| `caveman` | retro + log text (repo rule) |
| `handoff` | end of session -> #52 here + index row |
