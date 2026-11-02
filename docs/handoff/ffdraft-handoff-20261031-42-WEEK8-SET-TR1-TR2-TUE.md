# Handoff #49 — Wk8 set: Kyler QB, Tucker for Tate (O). Next: Tue 11-3 -> wk8 retro + wk9 pull -> TR1 + TR2 re-run -> send.

Written 2026-10-31 Sat. Branch `week3-gameday`, pushed through `2f1b2a8`. **All work since #47
uncommitted** (§6). Prior: #48 `docs/handoff/ffdraft-handoff-20261027-41-WEEK8-CLAIMS-IN-TR2-WED.md`
— its Wed/Thu list = history. **TR2 was NOT sent Wed** -> deferred to Tue with TR1.

---

## 0. READ FIRST.

- **Wk8 authority = `data/weekly/2026_week08_decisions.md`.** §1 claims (both won 10-28), §3
  trades, §4 lineup, §5 tests T1-T5 (T2 amended 10-30), `## Retro` M1 (Tate O -> Tucker; QB Kyler
  over rule) + R1 (T1 scored). Don't re-derive.
- Trade mechanics: `data/weekly/2026_week08_trade_ideas.md`. **Its §6 kill window "wks 8-10" is
  superseded** -> wk8 log §5 T2 amendment = wks 9-11.
- **Collector runs from the claude.ai "football" Project UI, not Claude Code.**
  `claude/yahoo_ff_collector.js` is not on local disk. User runs it; ask first anyway.
- Max's QBs = **Dak + Geno Smith** (#48 said Dak only — misread). Mahomes' pull for them is lower.

## 1. State.

| item | state |
|---|---|
| record | 4-3, 5th. Wk8 v Locked In Michelle (2-5) in play |
| wk8 lineup | **Kyler** QB / J. Williams, Henry RB / Gordon FLEX / Boston, **Tucker** WR / Hockenson TE / Bates K / Commanders DEF |
| wk8 odds | model P(win) 0.322 (frozen 10-29); Yahoo-implied ~0.43. Proj gap ~-14 unchanged 10-31 |
| Tate (TEN WR) | `O` shoulder, DNP, no timeline (Yahoo 10-30 8:06pm). TEN bye wk9 -> earliest wk10 |
| P(top 4) | **5.1%**, exp wins 6.40 (10-28). Wk8 W -> 10.3%, L -> 2.7% |
| exchange rate | +1 pt/wk ≈ +0.8pp P(top 4), +0.08 wins (10-28) |
| TR1 Kyler + Hockenson -> Jacobs (Madison) | **GO** — T1 passed (Jacobs 71% snaps). 5.1 -> 8.1% |
| TR2 Mahomes + Tate -> Burden + Likely (Max's) | **NOT SENT.** +2.67/wk us, +0.30 them; 5.1 -> 7.1%. Both: 11.0% |
| trade deadline | 11-28; accept by ~11-26. **Wk9 = TR2's biggest week** -> Max's must accept by ~Thu 11-5 |

## 2. Tue 11-3, in order. ~2 h.

1. User pulls **wk8 actuals** (`mode:'actual', week:8`) + **wk9 projections** -> `week_8_data/`,
   `week_9_data/` (folder must exist).
2. `pull_nflreadr.R` -> Matchups screenshot -> wk8 scores into `2026_league_schedule.csv` ->
   `schedule_check.R` -> `ceiling_vs_margin.R` (gate n 25 -> 30) -> `predictions.R score`
   (expect 3.18 of 5 favourites).
3. Wk8 retro below R1 in the log: result, T2 (Burden wk8 share **never holds TR2 alone**), T4 (n 5
   of 30, no call), regret. Kyler's 0.20 = choice regret (ADR 0010).
4. `playoff_odds.R`, `trade_finder.R` (CUR auto = 9), then named TR1 + TR2 re-run (recipe below).
   **Tate sensitivity is pre-registered** (log M1): TR2 GO needs win-win in wins with Tate at 0
   too. Fails -> re-scan Max's with Tate out of the package.
5. Both GO -> user proposes both in Yahoo same day; log send dates below `## Retro`.

Also Tue: T3 DST desk test (~30 min, not started) -> decides wk9 DST method. Etienne (NO RB, IR):
Saints back from bye — activation needs a drop. TR1 + TR2 both land -> Stafford only QB, LA bye
wk11 -> FA QB for wk11. FA move after the export -> `TXN` row in `league_sim.R`.

Named-trade recipe (scratchpad scripts died with the session):
```r
eval(parse(text = readLines("dev/weekly/trade_finder.R")[1:40]))   # sim, settle, apply_trade
MAX <- "Max’s TD Bombers"                                             # U+2019, byte-exact
x <- apply_trade(R, MAX, c("Patrick Mahomes", "Carnell Tate"), c("Luther Burden III", "Isaiah Likely"))
s <- simulate(strength_matrix(x$R)); colMeans(s$top4)[ME] - p0[ME]   # dP(top 4) us
fut(team_strength(x$R[x$R$owner == MAX, ])) - fut(M0[MAX, ])           # acceptance proxy
```
- `fut()` drops week CUR -> acceptance proxy = wks 10-15 only. `simulate()` P(top 4) includes wk9
  on post-trade rosters = the lands-before-wk9 case.
- Tate-out bound: `R$base[R$player == "Carnell Tate"] <- 0` before `apply_trade` = out wks 10-15.
  Wk10-only needs a per-week tweak: `team_strength()` uses one `base` for every non-CUR week.

**Thu 11-5: freeze wk9 before TNF.** `freeze_lineups.R`: set `WK`, `YDIR`, slot list. See §3.1.

## 3. Gotchas, new since #48.

1. **`read_yahoo_week()` silently keeps the OLDEST pull when a folder holds 2+ pulls.** Verified
   10-31 on `week_8_data` (10-28 + 10-31): Tate 10.21, no `O` = 10-28 rows, plus 5 stragglers from
   10-31. `distinct(player, yteam)` keeps first; files sort by date ascending. Callers:
   `freeze_lineups.R`, `league_ceiling.R`, `roster_need.R`, `rank_fa_te.R`, `week3_fa_pool.R`.
   `league_sim.R` safe (`clean_tmpl()` reads by date). **Two wk9 pulls -> Thursday freeze reads
   Tuesday's projections.** Fix offered (newest date, or stop on > 1 date), not done. Workaround:
   `read_yahoo_position()` per dated file.
2. Sat 10-31 pull: TNF rows read `Final` but `Fantasy Fan Pts` = projection (Jacobs 14.98 v
   scored 20.20; decimal stat cols). CLAUDE.md trap (c) "Final -> points scored" not universal.
3. `read_yahoo_week()` skips `_actual_` files -> read those with `read_yahoo_position()`.
4. `league_sim.R` base is blind to a fresh injury on a rostered player (`O` filter = wire fill
   only). TEN bye wk9 -> Tate's last two applicable exports both pre-injury -> priced healthy.
5. `trade_finder.R` display: `record = sprintf("%d-%d", W0[tm], 6 - W0[tm])` should be
   `(CUR - 1) - W0[tm]`. Display only. Offered, not done.

## 4. Done this session (since #48).

- Wk8 frozen 10-29 18:59 ET (`predictions.R freeze`); QB re-frozen 19:14 -> Kyler. Yahoo set-lineup
  proj for all 10 teams -> `2026_week08_yahoo_matchups.csv` (T4).
- Tests T1-T5 pre-registered (log §5). T1 scored early (R1).
- T2 calibration: new `dev/weekly/target_dip_test.R` (9 s, 2024-25 WRs). CLAUDE.md +2 Roster
  rules: target-share dip = weak evidence; a kill window starts after the decision.
- `dev/weekly/freeze_lineups.R` week-parameterized (`WK`, `YDIR`, `src`, `stopifnot` on slot keys).
- 10-31: nflreadr re-pulled 11:37 (gitignored). User's Yahoo pull `*_2026-10-31.csv` landed.
  Tate -> Tucker swap; QB rule said Stafford +0.20, user kept Kyler (MIN 6-0 = defense, 24th in
  scoring; matchup already in Yahoo; beyond-Yahoo +0.5, CI ±4.4 — coin flip). All in log M1.

## 5. Tests.

T1 scored GO. T2 + T4 Tue. T3 Tue, ~30 min. T5 wk10 (Tucker < 5 tgt/g or < 60% snaps wks 8-10).
Auto after MNF: gate n 30, `predictions.R score`. Optional each wk: Sun ~12:30pm ET Matchups
screenshot -> T4 sees set lineups.

## 6. Uncommitted. Commit only when user asks. PR owed — `gh` (GitHub MCP auth header fails).

- Modified: `CLAUDE.md`, `data/weekly/{2026_league_schedule.csv, 2026_week07_decisions.md,
  README.md}`, `dev/weekly/{ceiling_vs_margin,freeze_lineups,schedule_check}.R`, ADRs 0008 + 0011,
  `docs/handoff/README.md`.
- New: `data/weekly/2026_week08_{decisions.md, leaguewide_predictions.csv, myteam.csv,
  opponent.csv, yahoo_matchups.csv}`, `data/weekly/2026_trade_scan_wk8.rds`,
  `dev/weekly/{k_test,target_dip_test,wire_scan}.R`, handoffs #47-#49, wk7 + wk8 exports.

## 7. Open, not Tuesday.

- Lineup recovery: unique-subset-sum match to Yahoo finals for all 10 teams. Offered.
- Trade ideas §6 text -> wks 9-11 (log is authoritative meanwhile).
- Adams (LAR WR, IR): earliest wk12.

## 8. Suggested skills.

| skill | when |
|---|---|
| `caveman` | any log / ADR / handoff text (repo rule) |
| `anthropic-skills:yahoo-ff-collector` | reference only — user runs the pull from claude.ai |
| `handoff` | end of session -> #50 here + index row (not `/tmp`) |
