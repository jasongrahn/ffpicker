# Handoff #45 — League-wide sim BUILT, P(top 4) 3.3%, trades parked. Next session: evaluate CLAUDE.md.

Written 2026-10-21 Wed. Branch `week3-gameday`. **All of this session's work UNCOMMITTED** (§6).
Prior: #44 `docs/handoff/ffdraft-handoff-20261021-37-WEEK7-LOCKED-LEAGUEWIDE-TESTS-NEXT.md`.
Index: `docs/handoff/README.md`.

---

## 0. READ FIRST. Next session is a docs session, not football.

User, verbatim: *"our next conversation is going to take the lessons we've learned and
evaluate our CLAUDE.md."*

- Inputs = **§2** (lessons, each with evidence) + **§3** (CLAUDE.md audit, line-numbered).
  Numbers live in the files cited. **Do not re-derive the football.**
- Week 7 in flight until MNF 10-26. User travelling. **No week-7 action** unless asked.
  Post-week scoring is already one command each (§5).
- `CLAUDE.md` = **648 lines**. ~45% is draft-era or superseded history. Core question for
  the audit: **standing context vs history that belongs in `docs/`**.

## 1. What this session built. Pointers only.

| path | what |
|---|---|
| `data/weekly/2026_league_schedule.csv` | **NEW.** All 10 schedules wks 1-15, scores wks 1-6. Ten Schedule-tab screenshots + Standings tab |
| `dev/weekly/schedule_check.R` | **NEW.** Mirror check (every matchup on two pages) + reproduces Standings tab to the cent |
| `dev/weekly/ceiling_vs_margin.R` | **NEW.** Gate test. Adds a week automatically once its scores are entered |
| `dev/weekly/league_sim.R` | **NEW.** Shared sim, week-agnostic: CUR = newest clean export; `TXN` = moves after it |
| `dev/weekly/playoff_odds.R` | **NEW.** P(top 4), per-game leverage, exchange rate. Env `BASE`/`GAPMODE` sensitivities |
| `dev/weekly/trade_finder.R` | **NEW.** 15,675 trades vs all 9 rosters, scored in wins, common random numbers |
| `dev/weekly/predictions.R` | **NEW.** `freeze` (refuses after kickoff, refuses overwrite) / `score` |
| `dev/weekly/score_week07.R` | **NEW.** Every wk7 kill condition, one command, `WAITING` per missing input |
| `dev/weekly/leaguewide_retro.py` | **CHANGED.** `--pool` mode for R4. Single-week output byte-identical (diffed) |
| `data/weekly/2026_week07_decisions.md` | **APPENDED** below Retro: M1 (Kyler add, executed + scored in wins), L1 (league-wide pre-registration) |
| `data/weekly/2026_week07_leaguewide_predictions.csv` | **NEW.** Frozen 10-21 10:35 EDT, before Thu kickoff |
| `data/weekly/2026_week08_trade_ideas.md` | **NEW.** Trade plan, **NOT SENT**, re-run checklist §5 |

## 2. Lessons learned. Each one = candidate CLAUDE.md line.

### 2a. Silent traps. Same class as `CLAUDE.md` Conventions traps — none raised an error.

1. **`arrange()` vs `sort()` locale.** dplyr `arrange()` sorts in the C locale, base `sort()`
   in the system one -> "JGrahnasaurs" and "Jason's Jazzy Team" swap -> matrix rows
   mislabeled, no error. Our strength became theirs: P(top 4) read **33%, truth 4.4%**.
   Caught only because adding points to us *lowered* our odds. Fix: align by name,
   `stopifnot(identical(rownames(M), teams))` in `league_sim.R simulate()`.
   Rule candidate: **never align by position across two sorts; align by key.**
2. **Post-kickoff exports leak outcomes.** Sat/Sun pulls list games `Final` or live
   (`Half`, `Q2 0:11`); for those players `Fantasy Fan Pts` = points SCORED. wk3/4/5 Sunday
   pulls: 77/149/138 such players. Fix: clean export = latest pull with every Game cell
   unstarted (`league_sim.R clean_tmpl()`). **Qualifies `CLAUDE.md` trap (c)** "stat
   columns are projections" — true only before kickoff.
3. **Team names carry mixed apostrophes.** "Dave’s Bone Crushers", "Max’s TD Bombers" =
   U+2019; "Jason's Jazzy Team" = straight. Same in `Roster Status`. Join byte-exact.
4. **Multi-position eligibility exists:** `RB,TE` 4, `WR,RB` 2, `WR,TE` 2 in wk7. Every
   `optimal()` (`league_ceiling.R` and copies) uses `pos %in% p` -> such a player fills no
   slot, silently. None rostered wks 3-7 (checked) -> no past number wrong.
   `league_sim.R` now stops loudly.
5. **Mean-of-non-zero projection misreads backups.** Mariota: one wk4 start, zeros since,
   tagged `D` -> read as a 17.8-pt starter and became the wire's "replacement QB". Fix:
   zero in both of last two applicable exports -> base 0. **No injury-tag exception** —
   an injured backup carries a tag too.
6. **A sim with no future roster moves fakes bye holes.** Max's (Dak only, Hurts IR, DAL bye
   wk14 — the week they play us) scored 0 at QB -> our wk14 P(win) read 46%; with bye-hole
   fill **25%**. Fill EMPTY slots only — fill weak starters too and every FA add scores
   zero by construction.
7. **Base projection cannot see a fresh injury.** McLaurin (W, base 9.85) topped the wire;
   `O`/knee, snaps 75 -> 58 -> 10. **"Snaps before ppg" held again** — third catch.
8. **Actual export: `-` = did not play** -> NA, not 0. Every player (FA included) is in
   the file; a started inactive player scores 0.
9. **Marginal-strength auto-drop sees a 3rd QB as free** -> dropped Mahomes, the trade
   chip, for McLaurin. Drop logic is blind to trade value; protect currency explicitly.
10. **League-wide top-k shortlist = one partner.** Ranking trades by strength gain never
    simulated non-contenders, where arming the partner costs nothing. Shortlist per partner.

### 2b. Measured facts. Same class as `CLAUDE.md`'s measured findings.

1. **Gate PASSED** (`ceiling_vs_margin.R`, wks 3-6, n=20 matchups): ceiling diff -> margin
   **r +0.49, p 0.028**, slope +1.17, resid sd 30.0. Prior-weeks PPG weaker: r +0.36,
   p 0.12. Favourite wins only 10-12/20 — typical gaps 5-10 vs ~30 pts of margin noise.
2. **Noise constants:** per-team weekly sd(actual − ceiling) **22.0**; mean gap **−3.88**;
   team-score sd 26.3. Every sim number rests on these.
3. **Our roster is 9th of 10** for wks 8-15, bye-aware. Ceiling ranks wks 3-6: 7, 10, 9, 6.
   #44's "7th of 10, flag not finding" -> **finding, and worse.**
4. **Lowest regret ≠ outscoring the ceiling.** Our actual-minus-ceiling gap −4.8 ≈ league
   −3.88. Near-zero regret avoids loss; it buys no surplus. Owl Out Blitz +13.8 (SE 5.3).
5. **P(top 4) 3.3%** (5.8% with τ=6). Exp final wins 5.9. **Need 9** (67%); 10 -> 99%;
   8 -> 8%. Pre-fill sensitivity range 3-11%.
6. **Exchange rate:** +1 pt/wk ≈ **+0.09 wins, +0.7pp** P(top 4); +5 -> +0.47; +10 -> +0.96.
7. **Starting QBs are free on this wire** — Brissett (W) 17.1, Rodgers (FA) 16.7, Cousins
   (FA) 16.1. Max partner gain from any of our QBs **+1.2/wk**. QB surplus = weak currency.
8. **Standings tiebreak = PF**, inferred: every W-L tie ordered by PF; head-to-head ruled
   out (DBC beat SK wk4, ranks below).
9. **Schedule:** round robin wks 1-9; wks 10-15 replay wks 1-6, every team. Regular season
   ends wk15; playoffs wks 16-17, top 4.
10. **Adams IR (hamstring) after wk6** -> earliest return wk12 (4-game minimum, LA bye wk11).

### 2c. Method lessons.

1. **Score in wins.** P(top 4) + leverage + exchange rate exist; any move prices in wins.
   M1 Kyler: ΔP ≈ 0.000 alone — value only as trade enabler.
2. **Common random numbers** for every delta. Without them, +1 pt/wk drowned in MC noise.
3. **Monotonicity checks catch silent bugs** — "more points cannot lower odds" caught 2a.1.
4. **Validate transcription by redundancy** — mirror + Standings reproduction: one misread
   digit fails loudly.
5. **Pre-registration is now enforced by code**: freeze refuses after kickoff and refuses
   overwrite; scorers print `WAITING`, never a silent pass.
6. **Refactors verified by output diff** — playoff odds and retro single-week byte-identical.

## 3. CLAUDE.md audit seed. Line numbers as of 2026-10-21, 648 lines.

| lines | section | verdict | why |
|---|---|---|---|
| 11-28 | Who you're working with | keep | still true |
| 29-58 | League facts | **correct** | L51-56 "Unknown: draft slot only" + sweep-mode implication: drafted 09-08, slot 10. Add tiebreak PF (inferred), schedule structure, waiver = rolling no-FAAB (memory `waiver-system`) |
| 59-257 | Hard constraints | **compress ~200 -> ~25** | Yahoo API: three superseded generations (09-06, 09-15, 09-16) -> keep status + form URL + "do not re-run probes", move probe table to `docs/`. Third-party libs, Sleeper, XRank, VONA = draft-era, closed -> move. L192 "17-round" stale (15). Keep "VONA/XRank do not transfer mid-season" |
| 258-275 | Football primer | **correct** | L263 "regular season 1-14, playoffs 15-17" contradicts League facts (1-15, 16-17) |
| 276-283 | core modeling principle | keep | foundational |
| 284-402 | Game script | **compress ~120 -> ~15** | tiebreak rule retired 10-13. Keep slope, "nothing arbitrates inside 5%", kill condition; history -> `docs/` |
| 403-428 | Streaming K/DST | keep, **update** | L427 "K side untested" still true. Only 1 K rostered since M1 -> K stream now needs a FA add |
| 429-449 | Snake turn structure | **move** | draft-only; table is "Slot (of 12)" in a 10-team league |
| 450-460 | Stack | keep | L453 renv/devtools note **verified true 2026-10-21** (`requireNamespace("devtools")` FALSE) |
| 461-623 | Conventions | keep most, **add §2a** | **Correct** L515: wk7 projection export names DEF by nickname ("Browns"), not city — vintage-dependent; "join on abbrev" stands. L537 "TE 1-deep all season, zero in wk14" stale (3-deep, #44 §3a) -> reword as dated anecdote |
| 624-648 | Current status | **rewrite** | L626 "record 1-1 through Week 2, Week 3 frozen" -> 3-3, wk7 in flight. L628 "current work = start/sit, `R/41_weekly.R`" -> league-wide sims; lineup layer at ceiling. L639 regret list stops at wk2. L642 "three weeks of data" -> 6-7 |

### 3a. Missing from CLAUDE.md entirely.

- **Season objective = win matchups / P(top 4), not points.** Only in memory
  `win-by-one-not-points` and #44.
- Gate result + noise constants (§2b.1-2) — the measured basis of every sim.
- The sim family and how it chains: `league_sim.R` <- `playoff_odds.R`, `trade_finder.R`,
  `predictions.R`; `ceiling_vs_margin.R` writes the noise input.
- "Roster is the lever, priced by the exchange rate" — counterpart to the existing "lineup
  layer at ceiling".
- QB wire depth -> QB trade value (§2b.7). Traps §2a.1-5, 8.

### 3b. Overlap with auto-memory (`~/.claude/projects/-Users-jasongrahn-R-projects-ffootballer/memory/`).

- `win-by-one-not-points`, `lineup-layer-at-ceiling`, `roster-need-before-candidates`,
  `handoff-is-a-claim-not-a-source`, `waiver-system`: partly duplicated in CLAUDE.md or
  missing from it. **One home per fact.**
- `next-project-weekly-picker`: likely stale (start/sit at ceiling). Check.
- `yahoo-rank-divergence-backlog`: draft-era.

### 3c. Questions to settle with the user BEFORE cutting.

1. CLAUDE.md = standing rules only, or rules + measured findings? Today both -> 648 lines.
2. Where does history live: `docs/adr/`, a `docs/closed_investigations.md`, handoffs only?
3. Archive draft-era sections now that the draft engine is done?
4. Season-state lines (record, current week): CLAUDE.md at all? L626 is **five weeks stale**
   — anything that changes weekly rots there.

Also: `docs/handoff/README.md` had **three** rows marked "Current. START HERE." (#38, #39,
#42). Cleared this session; #45 carries the marker. Same rot pattern as L626.

## 4. Season state. Authority = decision log, not this doc.

- **3-3, 6th.** Wk7 v Monday Night Madison: frozen 105.27 v 100.60, P(win) 0.56 (frozen L1).
- **M1 executed 10-21:** Kyler Murray in. Drop recorded as **Butker per M1 — user never
  named the drop; verify on next export.** QBs: Stafford, Mahomes, Kyler.
- **Trades parked, NOT SENT:** `data/weekly/2026_week08_trade_ideas.md`. TR1 Madison
  (Kyler + Hockenson -> Jacobs) + TR2 Max's (Mahomes + Tate -> Burden III + Likely):
  +5.0 pts/wk, P(top 4) 3.3% -> 8.3%. **Trade deadline unknown — ask user.**
- Carried from #44 §6: push owed (**37 ahead** of `origin/main`, no PR); Etienne IR
  reactivation unexamined; Yahoo API application not submitted; stream detector blocked.

## 5. After MNF. Not the next session's job unless asked.

User supplies: wk7 `*_actual_*` exports (`yahoo-ff-collector`) + one screenshot, Yahoo ->
League -> Matchups -> Week 7. Order: `pull_nflreadr.R` -> enter wk7 scores in the schedule
CSV -> `schedule_check.R` -> `score_week07.R` -> `ceiling_vs_margin.R` (L1a, n=25) ->
`predictions.R score` -> `leaguewide_retro.py --pool …` (R4 verdict) -> week-8 export ->
`trade_finder.R`. Full commands: decision log L1 + trade ideas §5.

## 6. Uncommitted. git status 2026-10-21.

```
 M data/weekly/2026_week07_decisions.md
 M dev/weekly/leaguewide_retro.py
 M docs/handoff/README.md
?? data/weekly/2026_ceilings.rds  2026_league_schedule.csv  2026_trade_scan_wk7.rds
?? data/weekly/2026_week07_leaguewide_predictions.csv  2026_week08_trade_ideas.md
?? dev/weekly/{ceiling_vs_margin,league_sim,playoff_odds,predictions,schedule_check,score_week07,trade_finder}.R
?? docs/handoff/ffdraft-handoff-20261021-38-LEAGUEWIDE-SIM-BUILT-CLAUDEMD-REVIEW-NEXT.md
```

Commit only when the user asks. `git commit -F <file>` — apostrophes break the heredoc form.

## 7. Suggested skills

| skill | when |
|---|---|
| **`claude-md-management:claude-md-improver`** | **First.** Audit CLAUDE.md quality — the 648-line, standing-vs-history question |
| **`grill-me`** or **`grill-with-docs`** | **Before cutting anything.** Settle §3c with the user; deleting a measured finding is hard to reverse |
| **`claude-md-management:revise-claude-md`** | Then fold §2 lessons in |
| **`caveman`** | Repo rule — CLAUDE.md, handoffs, ADRs all this style |
| **`handoff`** | End of session. **Write to `docs/handoff/` as #46, NOT the OS temp dir** |

Do not reach for `tdd`, `improve-codebase-architecture`, or `to-issues` — docs session, no build.
