# FFPICKER — INJURY SIGNAL EXPERIMENT — START HERE

**Handoff #21.** Written 2026-09-07. Next session = **plan this experiment**
(user throwing Opus max at planning). Do NOT build in the planning session.

Repo `/Users/jasongrahn/R-projects/ffootballer`. GitHub `jasongrahn/ffpicker`.
Standing context = `CLAUDE.md`. Read it first. Read `dev/README.md` second.

---

## State

- Branch `vona-experiments-closed`, commit `a470e71`, pushed. **User merged.**
  Local `main` may lag — `git checkout main && git pull` before anything.
- Working tree clean at handoff time.
- Draft **Tue 2026-09-08 6:00pm ET**. Week 1 games **Wed 2026-09-09**.
- Week 1 lineup = top-ranked player per position off existing board. **No code.**
- Build window for picker: **Wed 2026-09-09 -> ~Sat 2026-09-12.** ~3.5 days.

## Closed. Do not reopen.

- **VONA as pick selector.** Three framings, all dead. Verdicts + evidence in
  `CLAUDE.md` VONA block, `dev/README.md`, `dev/PREREG_B.md`. Experiment B was
  no-op **by algebra** — no seed count changes it.
- Yahoo API, ffscrapr, Sleeper `search_rank`. All in `CLAUDE.md`.

## Alive but unwired

`simulate_forward()`'s `p_available` — per-player survival prob to next turn.
Never failed a bar; never was a selector. Display, not mechanic.
`survival_display()` + `VONA_LOW_SURVIVAL` in `R/81_vona.R` already format it.
Draft-only. Does not transfer in-season.

---

## The experiment

### Hypothesis — reframed, use this version

Original idea: "detect players hiding injury via faster-than-expected decline."

**That version loses.** NFL mandates weekly injury disclosure. Teams fined for
underreport. `load_injuries()` gives `practice_status` (DNP/Limited/Full) and
`report_status` (Out/Doubtful/Questionable) free. Detector must beat *reading the
report*, which costs zero.

**Sharp version:** report says **that** he hurt. Never says **how much it cost**.
"Questionable, ankle" identical string whether normal route tree or 15% fewer
snaps. Quantify the **severity discount on a known injury**. Undisclosed decline
= rarer secondary case, not primary target.

### Watch sticky series, not fantasy points

`CLAUDE.md` core principle already says it: opportunity sticky, efficiency noise.
PPG is TD-variance dominated -> healthy WR posts 4 pts twice on pure noise.

Ranked by signal quality:
1. **`offense_pct`** — snap share. `load_snap_counts()`. Cleanest, cheapest.
2. **Route participation proxy** — see data note below. Derived, approximate.
3. **Target share / carry share / RZ touches** — from `load_pbp()`.
4. **Efficiency** (YPC, YPRR) — noisiest. Regress hard. Use last.

Injury shows in snap share weeks before it shows in lineup decision.

---

## Data — VERIFIED live 2026-09-07, nflreadr 1.5.1. Do not re-verify.

| fn | 2024 | 2025 | note |
|---|---|---|---|
| `load_snap_counts()` | 26,615 rows | 26,612 rows | key `pfr_player_id` |
| `load_injuries()` | 6,215 rows | 6,068 rows | key `gsis_id` |
| `load_participation()` | 45,919 rows | 45,184 rows | **play-level**, not player-level |

`load_snap_counts()` cols: `game_id, pfr_game_id, season, game_type, week,
player, pfr_player_id, position, team, opponent, offense_snaps, offense_pct,
defense_snaps, defense_pct, st_snaps, st_pct`

`load_injuries()` cols: `season, game_type, team, week, gsis_id, position,
full_name, first_name, last_name, report_primary_injury,
report_secondary_injury, report_status, practice_primary_injury,
practice_secondary_injury, practice_status, date_modified`

### Trap in `load_participation()`

Play-level, one row per play. Cols include `offense_players` (semicolon-joined
gsis ids), `n_offense`, `route`, `was_pressure`, `time_to_throw`, `ngs_air_yards`.

`route` = route type on the play, **not per-player routes run**. Per-player route
participation requires unnesting `offense_players` and counting pass plays where
player on field. That is a **proxy**, not true routes run. Label it as proxy
wherever it surfaces. Snap share stays the clean signal.

### Join keys — repo rule, never name-join

Snaps carry `pfr_player_id`. Injuries carry `gsis_id`. Participation carries
gsis ids inside `offense_players`. Crosswalk via `load_ff_playerids()` ->
`dim_player` surrogate key, same as rest of repo. `CLAUDE.md` "Conventions".

---

## Known problems. Price these in the plan, before any bar.

1. **Power.** 1 obs/week, ~14 games. Detecting slope change in 3-4 points against
   real week-to-week variance. Same trap as `dev/bars_a.R`. Need effect size +
   power calc **before** setting bar, else confident answer from noise.
2. **Cost asymmetry.** Benching RB1 on false positive >> starting him hurt.
   Need **high precision, not high recall**. 10-team league, 6-deep bench, the
   alternative player is usually bad.
3. **Baseline is free.** `report_status` alone is the thing to beat. Any gate
   that does not compare against it is not a gate.
4. **Decision relevance.** Output must change a start/sit call. "Player declining"
   with no swap candidate is not a decision.

---

## Gate — pre-register before running anything

Backtest **2024 AND 2025** completed seasons. User explicit on both.

Label = player later ruled Out / hit IR / reported injury materialized.

> **Bar:** detector precision at fixed recall must beat `report_status` alone by
> a stated margin. If reading the report does as well, model does not ship.

Mutation-test it: feed healthy-player series, must not fire. Gate that cannot
fail is not gate.

### Cheapest first test — ~1 hour, do this before building anything

Pull 2024 `offense_pct` series for ~20 players who landed on IR. Ask: does snap
share **bend before** `report_status` changes?

No bend -> whole idea dies cheap, build picker without it. That is a good
outcome. Report it either way.

---

## Discipline carried from Experiments A and B. Non-negotiable.

Encoded in `dev/README.md` "House rules". Short form:

1. Pre-register bars **AND the read** before running. Threshold with no stated
   interpretation invites tuning after the fact.
2. **Mutation-test any gate before trusting a PASS.** Caught real problems in A
   and B. #19 shipped circular golden that this would have caught.
3. Where stochastic: >= 30 seeds, common random numbers, paired bootstrap CI.
   `paired_bootstrap_ci()` in `R/80_opponent_sim.R`.
4. **Report the failure.** A2 FAIL stands as recorded even though 30 seeds
   contradicted it. Bar was underpowered; result still result.
5. Check **whether bar or hypothesis was wrong**, with evidence for which. A =
   bar wrong. B = hypothesis wrong. Different fixes.

---

## Architecture decision to make EARLY

`_targets/` is gitignored. Existing DAG is **preseason-shaped** — runs once,
builds a draft board. Picker is **weekly cadence**, in-season data.

Decide up front: new DAG, or new targets in existing one. Annoying to reverse.
Not a detail to defer.

---

## Also worth fixing

`CLAUDE.md` "Current status" section stale — still says *"Nothing built yet. Next
action is Phase 0."* False. Draft engine ships, opponent model ships, VONA
closed. Update it.

---

## Suggested skills

- **`/to-prd`** — spec the experiment before building. PRD-first caught #19's
  circular gate. **Do this first in the planning session.**
- **`/caveman`** — all docs. Repo rule, `CLAUDE.md`.
- **`/tdd`** — bars as tests, written before detector.
- **`/handoff`** — end of next session.

---

## Do not do

- Do not build in the planning session. User wants Opus max on planning only.
- Do not touch `inst/app/app.R` mechanics without asking.
- Do not re-open VONA.
- Do not skip the 2025 backtest. User explicit: **2024 AND 2025**.
- Do not join players on name.
