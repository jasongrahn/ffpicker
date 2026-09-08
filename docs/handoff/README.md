# Handoff docs

Session-to-session continuity. Each one written at the end of a session, read at the
start of the next. Newest last.

Lived in `/tmp` until 2026-09-06 — nine docs, no version control, one macOS purge from
gone. Moved here. **Write new ones here, not `/tmp`.**

Filenames are `ffdraft-handoff-YYYYMMDD[-N].md`, `-N` for the Nth of that day. Date
order is the read order; filename sort is not (`-2` sorts before the unsuffixed file).
Use this index.

| # | File | What it settled |
|---|---|---|
| 1 | `20260829.md` | Phases 0-2 done. Starting Phase 3. |
| 2 | `20260904.md` | Phase 3 done. Decision pending on what came next. |
| 3 | `20260904-2.md` | Real Yahoo league settings applied. Ready for Phase 3.5. |
| 4 | `20260905.md` | Phase 3.5 UI shape resolved via `grill-with-docs`. |
| 5 | `20260905-2.md` | Pick Log + tiering + minimal pick-entry loop, live-verified. |
| 6 | `20260905-3.md` | Rookie fallback section built, live-verified. |
| 7 | `20260905-4.md` | Phase 3.5 hardened. Phase 8 identified as next. |
| 8 | `20260906.md` | Team-assignment gap found and fixed. Phase 3.5 actually done. |
| 9 | `20260906-2.md` | Phase 3.6 run guide built. Expected-points ranking ready to wire. Budget rules. |
| 10 | `20260906-3.md` | Expected-points wired. Three recommendation bugs killed, all found by screenshot. `dev/relaunch.sh`. |
| 11 | `20260906-4.md` | Deferred rows greyed on board. First full 17-round dry run (`dev/dryrun.R`) — found deferral was demotion not exclusion. Rookie sources settled: use FantasyPros `sd`, don't scrape. |
| 12 | `20260906-5.md` | Rookies priced onto Board. Yahoo import CSV built + names aligned — 292/510 imported, cause unsettled. |
| 13 | `20260906-6.md` | Position-page CSVs wired in — 473/510 Yahoo-confirmed. Naming ruled out as the import cause; probe file built to settle it. |
| 14 | `20260906-7.md` | Import thread closed — probe 25/25, full file 508/510. Bench-phase recommendations: rounds 8-14 name a player, 3 QBs -> 2. `renv` snapshotted. |
| 15 | `20260906-8.md` | Position pages unioned into `draft_pool` (478 -> 732). Sleeper API probed: access clean, `search_rank` beats ECR where ECR is censored (-0.354 vs -0.014). Next: plan an *evaluation* of whether Sleeper is a sufficient supplement — verdict, not integration. |
| 16 | `20260906-9.md` | Sleeper evaluated -> **REJECT**. Independent and predictive, but only where `ecr > 290` — past the end of a 10-team 17-round draft. 0 of 17 picks changed. Thread closed. |
| 17 | `20260906-10.md` | Yahoo XRank/ADP acquired, joins 170/170 of draftable range. Gate PASSED: real-Yahoo opponents change 5/17 picks, cost 32.5 starter pts -> `dev/dryrun.R`'s ECR opponent model is wrong and every strategy conclusion is optimistic. Fix scoped, NOT shipped. Adversarial critique in `docs/review/001-model-critique.md`. |
| 18 | `20260906-11.md` | Opponent model SHIPPED — `xrank`/`adp` on `draft_board`, dryrun opponents draft by XRank, `Yahoo gap` column live. New numbers: baseline **536.0**, QB-defer rd7/rd8 both 536.4. But dryrun is **n=1** — deterministic opponents, so no strategy comparison this repo has printed is a measurement. Next: scope for (1) Plackett-Luce Monte Carlo opponents with tau sweep + paired CIs, (2) survival probability -> **VONA**, live under the 1-minute clock. Four pre-registered bars set. |
| 19 | `20260907-12.md` | PRD 001 executed. MC opponent sweep SHIPS (QB-deferral not a lever; starters climb with opponent noise 536 -> 632). VONA pick selector **REJECTED** on bar 2 — arm drafted zero K, zero DST. Next two experiments scoped: A (mandatory-slot fill), B (within-position tiebreak). **tau>0 numbers in its bar table do not reproduce — see #20.** |
| 20 | `20260907-13.md` | Experiment A built + run. A1 PASS, A2 **FAIL** (tau=3), A3 PASS — but 30-seed paired CI says that FAIL was a single-draw artifact (tau=3 mean **+30.1**, CI [+17.6, +43.3], 93% win). Real read: constrained arm wins tau 0/3/6, ties tau 12, loses nowhere. **Lesson: single-seed bars are underpowered — delta sd is 36-43 pts. Pre-register B on 30-seed CIs.** B not started. |
| 21 | `20260907-14-INJURY-SIGNAL-START-HERE.md` | Experiment B run -> **no-op by algebra** (VONA within a fixed position == VOR, 0 picks changed / 124 drafts). VONA as pick selector **closed**, all three framings, merged `a470e71`. `p_available` survives as a display, unwired. Next project = **in-season weekly start/sit picker**, and inside it the **injury-severity signal**: not "detect hidden injury" (loses to free `load_injuries()`) but *quantify the discount on a known one*. Doc carries verified 2024+2025 data availability, the `load_participation()` route trap, the pre-registered gate, and a ~1hr test that can kill the idea cheap. **Plan only next session — do not build.** |
| 22 | `20260908-15-MOCK-DRAFT-ANALYSIS.md` | Draft day. Data refreshed (ECR ceiling = 09-04, upstream is weekly not daily). **Availability signal shipped** — board had none; nflreadr status + same-day Yahoo roster pages caught 13 unavailable in draftable range incl. Jacobs #20, Charbonnet #44, Henderson #50 (Yahoo-only, nflreadr said ACT). `dev/rebuild_yahoo_export.R` rebuilds the upload: drops unavailable, sinks K/DEF to 252+. Import rate 38% -> 85%; **#14's "thread closed, 508/510" does not reproduce** — Troy Franklin still unexplained. Mock #1 analyzed: autodraft follows our list exactly, but QB column is our worst (VOR Spearman +0.45 vs ECR +0.80). Next session receives **mock #2** and answers what mocks teach us. |

| 23 | `20260908-16-DRAFT-DAY-CLOSE.md` | QB fade shipped as one config line (`defer_until_round QB: 7`), zero R code. Slot **10** captured. DEF/K rank-sinking proven a non-lever — Yahoo autodraft fills mandatory slots by round, ignores uploaded rank. Live pick log written during the draft, provenance flagged unresolved. |
| 24 | `20260908-17-SEASON-START.md` | **Current. START HERE.** Official results in, `pick_log.jsonl` rebuilt from them (`422676e`, branch `draft-day-official-results`, PR not opened). **Draft was 15 rounds, not 17** — `rounds: 17` + `defer_until_round K: 16` meant we drafted **no kicker**, only team of 10. Config fixed. QB fade validated: got board's #1 and #4 QB at picks 70/110. Live log was 142/150 correct; our own 15 picks 15/15 — Jacobs at 71 real. **Draft engine done.** Next project = in-season weekly picker, scope from #21. |

## Reading rule

Read the newest first. Go back only when it points you back. Each doc supersedes the
ones before it — an older doc's "do next" list is history, not instruction.

Docs are `/caveman` style per `CLAUDE.md`.
