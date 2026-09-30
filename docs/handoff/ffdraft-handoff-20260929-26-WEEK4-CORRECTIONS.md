# Handoff #33 — Week 4 corrections. Methodology error found and fixed.

**Tue 2026-09-29 evening.** Branch `week3-gameday`. Week 4 log corrected + committed (`90fd1ad`).
Record 2-1, 3rd. Opponent Jason's Jazzy Team (Pete), 1-2-0, 8th.

---

## 1. THE ERROR. Read this before trusting any Week 4 number dated earlier.

**`Rankings Actual` in Yahoo position exports is NOT realised production. It is that week's
projection restated as a rank.**

Measured by counting rank-order violations vs `Fantasy Fan Pts` per position file:

| pos | n | violations |
|---|---|---|
| QB | 140 | 2 (1.4%) |
| RB | 264 | **0** |
| WR | 465 | **0** |
| TE | 246 | **0** |
| K | 56 | **0** |
| DEF | 32 | **0** |

**0 violations in 1,203 of 1,243 players.** Same information twice.

**Standing rule, now in `2026_week04_decisions.md` §00: never cite `Rankings Actual` or
`Rankings Pre-Season` as evidence of performance.** Read Yahoo's opinion with them. Never check it.
Only `score_player_week()` over `nflreadr::load_player_stats(2026)` counts as production.

**Failure mode: one source counted twice.** Every bad call below had the form "projection says X
*and* the season rank agrees." Watch for it. It reads like corroboration.

---

## 2. What it broke, and the four reversals

Recomputed all 362 scoring players, wks 1-3, `score_player_week()` + `config/scoring.json`.

| decision | was | now | why |
|---|---|---|---|
| **D1** Etienne drop | drop on 0.00 wk4 proj | **RETAINED** | **8.47 ppg — our RB3.** 0.00 is one week of `O`, not his value. |
| **D1** Allen claim | claim, "rank 223 -> 87" | **CANCELLED** | Allen **5.07** ppg. Hall, the man he was "replacing", **12.50**. |
| **D8** Stroud claim | claim, "+3.11 proj *and* rank 8 vs 30" | **CANCELLED** | Stroud **15.05** vs Stafford **18.66**. A 3.61 ppg downgrade. Caught pre-processing. |
| **D6** Sutton start | start, +0.81 proj over Odunze | **BENCHED** | Sutton **4.07** — worst WR on roster. Was our projected WR2. |
| **D9** new | — | **Boston in / Gainwell out** | Boston **12.67** (2nd-best WR by production). Gainwell **2.43**, worst on roster. |

**Also reversed: §0's whole frame.** Skill slots only (K/DST not scorable — `score_team_week()`
still does not exist):

| lineup | by projection | **by actual ppg** |
|---|---|---|
| ours (revised) | 99.09 | **110.25** |
| theirs, best legal | 109.74 | **92.47** |
| theirs, as set | 89.51 | **83.96** |

Projection had us 10.6 down. Production has us **17.8 up**. Favourites want floor, not ceiling —
the earlier "variance helps us" argument is dead twice.

**Funny detail worth keeping.** Their projection-optimal QB is Maye (18.47 proj, **9.20** ppg); they
started Goff (18.44 proj, **21.86** ppg). Right QB, wrong reason, and our "they should fix it"
advice would have made them worse.

**Held: n = 3.** Production is not being treated as truth. It is a **second source that disagrees
with the first**, where the first has a recorded four-week failure history and the second is our own
35/35-validated function. That is the whole claim. Fit nothing.

---

## 3. LIVE TASK — Yahoo says bench Raymond, start Odunze. Run it.

**This is the next thing to do.** Yahoo's lineup assistant is recommending Odunze over Raymond.

Sitting on the table before any analysis:

| WR | **actual ppg wks 1-3** | wk4 proj | Yahoo says |
|---|---|---|---|
| **K. Raymond (Chicago)** | **12.30** | 6.28 | bench |
| R. Odunze (Chicago) | 5.97 | 8.21 | start |

Three things constrain the answer. **Do not skip any of them.**

1. **Yahoo's recommendation is projection-driven** — §1 above says that source is the one with the
   failure record, and here it disagrees with production by 6.33 ppg in the opposite direction.
2. **Raymond starting is PRE-COMMITTED, not a judgment call.** Week 3 log D5 set the trigger at 6+
   targets in Week 3; he got 7. Handoff #32 recorded the trigger firing. **Overriding a fired
   pre-commitment on the discredited source is exactly what the pre-commitment exists to prevent.**
   If it gets overridden, that has to be argued explicitly and logged as a rule change.
3. **The Week 3 retro is direct evidence on this exact pair.** Week 3 benched Raymond (**18.00**)
   for Sutton (6.10) — the single largest contributor to Week 3's regret of 25.06. Same
   projection source, same direction of error, one week ago.

**But the honest counter, which needs actually checking:** Raymond and Odunze are **teammates
competing for the same Chicago targets**, so this is not two independent players. Week 2's retro
already found Odunze's role changed (snap share 48% -> 84%) while Raymond's held. If Yahoo's
projection is reflecting a *further* role shift in Week 3-4, that is new information the box scores
lag, and the 12.30 vs 5.97 gap may be describing a Chicago that no longer exists.

**So the analysis to run is a usage diff, not a points comparison:**
- `load_player_stats(2026)` wks 1-3, both players: **targets, target share, snaps, air yards, week
  by week, not aggregated.** Aggregate ppg cannot see a trend.
- Is Raymond's 12.30 front-loaded (wk1-2 heavy, wk3 collapsing) or flat/rising?
- Did Odunze's 84% snap share convert to targets, or is he playing without volume?
- `CLAUDE.md`: **opportunity is sticky, efficiency is noise.** If Raymond's edge is TDs and
  Odunze leads on targets, Yahoo is right and production is measuring luck. If Raymond leads on
  *targets*, Yahoo is wrong.

**Decide on the usage trend. Log it as an amendment to D6 with its own kill condition.** Chicago
plays Sunday, so there is time.

---

## 4. Roster as it actually stands

Waivers **LIVE**: Ravens DEF in / Chiefs DEF out. Boston in / Gainwell out (dropped).
Waivers **CANCELLED**: Stroud, Allen.

Lineup as logged (99.09 proj / 110.25 actual-ppg):
QB Mahomes · RB Henry + J. Williams · WR Adams + **Robinson** · TE Ferguson · FLEX **Raymond**
· K Butker · DEF Ravens.

**Not yet set on Yahoo.** Robinson-for-Sutton still needs doing, and §3 may change the FLEX.

**Flagged conflict:** Robinson is Tennessee, opposed to both our Henry and our Ravens DEF. Priced
at 1.66 ppg, taken knowingly, logged in D6 and §3. Per `CLAUDE.md` correlation is fine; paying for
it is not — and this one gains points on the better signal.

**Ravens DEF KEPT deliberately.** It rests on betting lines, an independent source untouched by
§1, not on Yahoo ranks. Opp implied 16.00 vs Chiefs 21.50.

**Breece Hall: do not pursue.** Rostered by "Maybe Mitchell" — a trade, not a waiver. RB is our
strongest position; he would be bench RB3. His own Yahoo projection (7.36 vs Allen's 10.28) hints
at a job loss anyway.

---

## 5. Queued, in order

1. **§3 Raymond/Odunze usage diff**, then set the Week 4 lineup on Yahoo.
2. **Week 5 waivers: drop Butker, claim Jake Bates (Det).** Butker byes with KC. Bates 29.00 own
   implied total, 55% rostered, free. Only CAR and KC bye wk5, so Ravens DEF unaffected.
3. **Week 13: pre-committed TE claim** to cover Ferguson's wk14 bye. Panel consensus was stream,
   do not carry. Week 10 WR bye is **now solved** by Boston — Adams + Boston are exactly 2 WRs.
4. **§7 open design task: two-week-ahead bye report.** Measured constraint that shapes it:
   `load_schedules(2026)` publishes lines **exactly one week ahead** (wks 4-5 at 100%, wks 6-15 at
   0%), so K/DST bye planning is structurally capped at one week. Nobody can get ahead there on
   matchup merit. QB/RB/WR/TE plan arbitrarily far. **Design not settled. Do not build until it is.**
5. Branch `week3-gameday` unpushed, no PR. `week3-picks` 4 ahead of `main`.

---

## 6. Bye horizon, recomputed for the current roster

| wk | out | read |
|---|---|---|
| 5 | Mahomes, **Butker** | **K hole.** Bates claim, §5.2. Stafford covers QB free. |
| 8 | Etienne, Marks | 2 of 4 RBs. Henry + J. Williams still start. |
| 9 | Robinson | fine |
| 10 | Sutton, Odunze, Raymond | **solved by Boston.** Adams + Boston = exactly 2 WRs. |
| 11 | Stafford, Adams, Boston | Mahomes back. WR thin but legal. |
| 13 | Henry, **Ravens** | DST streams anyway. RB thin. |
| 14 | J. Williams, **Ferguson** | **TE hole.** §5.3. Playoff-adjacent, wk15 is the last regular week. |
