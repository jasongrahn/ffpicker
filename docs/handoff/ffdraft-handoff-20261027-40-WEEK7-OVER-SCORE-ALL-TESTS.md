# Handoff #47 — Week 7 over. Next: score every pre-registered test — our matchup + all 10 rosters.

Written 2026-10-27 Tue. Branch `week3-gameday`, pushed through `2f1b2a8`; this doc + its
index row uncommitted. Prior: #46
`docs/handoff/ffdraft-handoff-20261027-39-CLAUDEMD-SLIMMED-WEEK7-SCORING-NEXT.md` — docs
session, CLAUDE.md rebuilt. **Rules live in `CLAUDE.md` now; read it, not #46.**

---

## 0. READ FIRST.

- **Next session = week-7 retro, two scopes.** (A) our matchup v Monday Night Madison —
  decision tests. (B) all ten managers — sim + rule tests. Every test pre-registered
  2026-10-21, before Thu kickoff. **Score, do not re-plan.** Authority:
  `data/weekly/2026_week07_decisions.md` §2, §3, Retro M1 + L1.
- Retro text goes **below `## Retro`** in the decision log; never edit above it. Separate
  "decision wrong" from "outcome bad" (CLAUDE.md § Live state).
- (A) is n=1 — log, rarely a verdict. Power lives in (B). Price conclusions in wins
  (CLAUDE.md § Season objective).

## 1. Inputs. Two of four missing.

| input | status | how |
|---|---|---|
| wk7 `*_actual_*` exports | **landed 2026-10-27** — `docs/uploads/week_7_data/*_actual_2026-10-27.csv`, 6 positions + `wrt` | — |
| nflreadr pull | **stale** — `data/nflreadr/pull_2026.rds` is 10-21 07:59, pre-week | `Rscript dev/weekly/pull_nflreadr.R` |
| wk7 scores, all 5 games | **missing** — pf/pa blank on all 10 wk7 rows of `data/weekly/2026_league_schedule.csv` | user screenshot: Yahoo -> League -> Matchups -> Week 7. Enter rows -> `Rscript dev/weekly/schedule_check.R` (mirror check) |
| wk8 exports | missing — only the trade re-run (§4) needs them | `yahoo-ff-collector` |

`schedule_check.R`'s to-the-cent Standings check is a wk1-6 snapshot (`filter(week <= 6)`).
Optional: a fresh Standings screenshot extends it to wk7.

## 2. (A) Our matchup. One command: `Rscript dev/weekly/score_week07.R`.

Prints KILL / pass / WAITING per test. Kill conditions live in the log — not restated here.

| test | log § | input it waits on |
|---|---|---|
| K1 Bates over Butker | §2 | exports. Log only — K rule untested |
| T1 Hockenson over Higbee | §2 | nflreadr snaps. Inactive = option forfeited; pre-registered as not a wrong call |
| W1a / W1b hold Tate over Odunze | §2 | exports (W1a); + nflreadr TEN-CLE final (W1b) |
| D1 Browns DEF | §2 | exports. Log only — DST rule validated, no kill on one week |
| M0 no roster move | §2 | retro y/n on the recorded hold |
| M1a Kyler snap% < 80 | Retro M1 | nflreadr snaps. Window wks 7-11; M1b scored at wk11 |
| RESULT + export-vs-Yahoo match | — | wk7 rows in the schedule CSV |
| REGRET, hindsight − started | — | exports. Append to `data/weekly/README.md` |

Also: **verify the M1 drop = Butker** off the wk7 actual export's `Roster Status`. User never
named the drop (#45 §4).

## 3. (B) All ten managers.

| test | pre-registered | command | verdict rule |
|---|---|---|---|
| **L1a gate, n 20 -> 25** | log Retro L1 | `Rscript dev/weekly/ceiling_vs_margin.R` | KILL if r < 0.20 or slope <= 0 -> trade valuations overstate; re-scan before any offer |
| L1b calibration | log Retro L1 | `Rscript dev/weekly/predictions.R score` | hit rate + Brier vs 0.250. Log only — n 5/wk |
| **R4 pair band, pooled wks 4-7** | log §3.1 | `python3 dev/weekly/leaguewide_retro.py --pool 4:2026-10-01:2026-10-05 5:2026-10-07:2026-10-13 6:2026-10-14:2026-10-20 7:2026-10-21:2026-10-27` | 5-15% band still < 55% at n >= 200 -> dead band widens 5% -> 15% |
| Yahoo projection sign | log §3.2 | `python3 dev/weekly/leaguewide_retro.py 7 2026-10-21 2026-10-27` | wk6 ran -1.79 low at all 6 positions (n 135). Re-check; one more week is not a call |
| regret, all 10 rosters | — | same single-week run | descriptive. Our wk6 regret 3.40 was lowest |

Not testable: log §3.3 stream detector — Sunday pre-kickoff pull missed, third week running.

`ceiling_vs_margin.R` also re-estimates the noise constants (sd 22.0, gap -3.88 at n=20). If
they move, every `league_sim.R` number moves -> rerun `playoff_odds.R` before quoting P(top 4).

## 4. If a verdict changes a standing rule.

- **R4 fires** -> CLAUDE.md § Game script "inside ~5%" becomes 15%. Evidence: append a dated
  section to `docs/adr/0008-spread-tiebreak-retired.md`; keep the 10-13 result as history.
- **L1a fires** -> CLAUDE.md § League-wide sim gate line + re-scan
  `data/weekly/2026_week08_trade_ideas.md`.
- New fact = rule + key number in CLAUDE.md, evidence in an ADR. **Never auto-memory.**

Then, if time: trade re-run, `data/weekly/2026_week08_trade_ideas.md` §5. TR1 + TR2 parked,
NOT SENT. **Trade deadline unknown — ask the user.**

## 5. Season state. Authority = decision log.

- 3-3 entering wk7, 6th. Wk7 frozen 105.27 v 100.60, P(win) 0.56 (L1). **Result not yet in
  any file.**
- P(top 4) 3.3% before wk7 (#45). Rerun after scores enter.
- Open: PR owed (`week3-gameday` ~40 ahead of `origin/main`); Etienne IR reactivation
  unexamined; stream detector blocked. Yahoo API **closed** — ADR 0002, not an open item.

## 6. Suggested skills

| skill | when |
|---|---|
| **`yahoo-ff-collector`** | Only to re-pull wk7 actuals or fetch wk8 exports |
| `caveman` | Retro entries, any CLAUDE.md / ADR change — repo style |
| `verify` agent | Only if `R/` or `tests/` change |
| **`handoff`** | End of session. `docs/handoff/` as #48, never the OS temp dir |
