# ffdraft Handoff #29: Week 2 picks. Yahoo API parked, do not work it.

**START HERE -> §2.** Task is one thing: set Week 2 lineup. Silo. Yahoo API thread
closed for this session by user instruction — §5 is a status stub, not a task.

**Local**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: 2026-09-16 (Tue). Week 2 opens **Thu 09-17**.
**Prior**: `ffdraft-handoff-20260915-21-WEEKLY-LAYER.md` (#28)
**Git**: branch `week1-roster-handoff`, head **`cbf2414`**, tree clean. Not pushed.

Record 0-1. Week 1 detail -> `data/weekly/README.md`. Not repeated here.

---

## 1. Clock

Lineup locks per-player at that player's kickoff. **TNF Thu 09-17** is the first
lock. Any TNF starter decided by then, rest by Sun 13:00 ET.

Week 1 lesson, already paid for: Stafford locked Thu, Mahomes played Mon, swap stayed
legal all weekend. **Late-game players are free options.** Do not lock a Thursday
player without checking what the Monday player would cost.

---

## 2. THE TASK

Set Week 2 starters. 9 slots: QB, RB, RB, WR, WR, TE, FLEX, K, DEF.

### Inputs not in repo yet. Get these first.

1. **Week 2 Yahoo projections** for all 15. Hand-entered, same as Week 1.
2. **Week 2 opponent** + their projected total. Unknown at write time.
3. **Injury status** -> `dim_injury_week`, already built, rebuilds on `tar_make()`.

Do not model before inputs exist. Week 1 file is the column contract:
`season,week,player,pos,nfl_team,slot,started,proj,actual`.

### Roster, 15, carried from Week 1

| player | pos | team |
|---|---|---|
| M. Stafford | QB | LAR |
| P. Mahomes | QB | KC |
| J. Williams | RB | Dal |
| D. Henry | RB | Bal |
| T. Etienne Jr. | RB | NO |
| K. Gainwell | RB | TB |
| W. Marks | RB | Hou |
| T. Tracy Jr. | RB | NYG |
| D. Adams | WR | LAR |
| R. Odunze | WR | Chi |
| C. Sutton | WR | Den |
| W. Robinson | WR | Ten |
| J. Ferguson | TE | Dal |
| C. McLaughlin | K | TB |
| Patriots | DEF | NE |

Verify against Yahoo before trusting — waivers may have moved it.

### Bar

`regret = best legal lineup - lineup actually started`. Metric defined in
`data/weekly/README.md`. Log Week 2 there when actuals land, bench rows included.
**Bench actuals are the counterfactual. Without them no test case exists.**

---

## 3. One real feature. Same-game correlation.

Only learnable signal Week 1 produced. Everything else there = variance.

Stafford + Adams both LAR vs SF. Rams lost 7-27. Two slots -> one game script ->
both bad. Not bad luck. Structural.

Week 2 check, cheap, no code required:
- Group starters by game.
- Two-plus non-QB/WR-stack players in one game -> flag it.
- QB + his own WR is *positive* correlation, different thing, do not penalize.

Ship as a surfaced warning first, not a scoring penalty. No data to fit a penalty on.
**n=2 weeks. Fit nothing.**

---

## 4. Tools that exist. Use, do not rebuild.

| thing | where | state |
|---|---|---|
| `fct_player_week_current` | `R/41_weekly.R` | live season, snap share + opponent, 99.2% snap match |
| `dim_injury_week` | `R/41_weekly.R` | every player on report incl. Out. Separate from fact table **on purpose** |
| `score_player_week()` | `R/30_scoring.R` | **validated 12/12 to the penny vs Yahoo box score** |
| `load_schedules(2026)` | nflreadr | verified working in-season (#26) |

`tar_make()` self-refreshes now — `cue = tar_cue(mode = "always")` on the five
in-season raw pulls. No `tar_invalidate()`. ~24-28s steady state.

Trap, documented in code, **do not undo**: injuries stay OUT of the fact table.
Fact table derives from `player_stats` -> player ruled Out records no stat -> no row.
Left join retained 3 of 21 designations. Rationale in `build_dim_injury_week()` roxygen.

Tests: 533 pass, 0 fail.

---

## 5. Yahoo API. Parked. Status only.

**Do not work this. User called the silo.**

Submitted access application **2026-09-16** -> `sports.yahoo.com/developer/access/`.
Human review, no SLA. Nobody public has reported an approval (`yfpy` issue #84, opened
2026-07-22, zero replies).

Full record -> `CLAUDE.md` Yahoo block + `dev/yahoo/ACCESS_APPLICATION.md`.
Harnesses `dev/yahoo/auth_probe.R`, `dev/yahoo/oauth1_probe.py`.

Weekly check, one line, 5 seconds:
```r
source("dev/yahoo/auth_probe.R"); yahoo_open_consent("fspt-r")
```
`error=invalid_scope` -> pending. Consent screen -> approved, then adopt `yfpy`.

Checked 2026-09-16: still `invalid_scope`. Expected, submitted same day.

**Yahoo buys waiver ownership only.** Start/sit needs 15 rostered players + nflreadr.
Both in hand. Nothing here blocks §2.

Secrets: `.Renviron`, gitignored. `Sys.getenv()` only. Never `config/` — that dir ships.

---

## 6. Carried, still unfixed

- **`CLAUDE.md` stale, 2 places.** `## Current status` says "Nothing built yet,
  next action Phase 0" — badly false. League block says 17 rounds; real is **15**.
  Open since #24. 5 min job.
- `docs/backlog/README.md` line 8 stale — "No Yahoo ranking data exists in the repo."
  Superseded 2026-09-06.
- Dead, do not revive: VONA as selector (3 framings, closed), ESPN / `ffscrapr` /
  Sleeper `search_rank`. See `CLAUDE.md`.
- Draft-only, does not transfer: `p_available` / `survival_display()` (`R/81_vona.R`).
  No turn order in waivers. Leave it.
- Undecided, low stakes: R vs Python for picker. R recommended — `targets` DAG already
  there, `yfpy` would be a weekly CSV drop the DAG reads. User said "i dont care."

---

## 7. Suggested skills

- **`caveman`** — repo doc rule, any doc written
- **`to-prd`** — scope the picker before code. Queued since #21, still not done. Do it
  if §2 finishes early; do NOT let it block Week 2 lineup.
- **`claude-md-management:revise-claude-md`** — §6 stale blocks
- **`handoff`** / **`session-close`** — close next session, write **here** not `/tmp`
  (`docs/handoff/README.md` overrides skill default)

---

## 8. Read order for a cold start

1. This doc, §2.
2. `data/weekly/README.md` — metric, Week 1 case, kicker note.
3. `CLAUDE.md` — league facts, scoring, football primer. **Assume user knows football
   casually.** Name team and role when naming a player.
4. Commit `f4c2298` message — weekly layer rationale, not repeated anywhere else.

Do not read the 27 drafting handoffs. Draft phase closed. `docs/handoff/drafting/`.
