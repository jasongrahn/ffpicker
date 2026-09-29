# ffdraft Handoff #32: Week 4 SWAPS. Decide roster moves BEFORE starters.

**START HERE -> §1.** Week 3 retro is **closed and filed**. Week 4 is **open, nothing
frozen, no lineup set**. Task order is deliberate: **swaps first, starters second.**
Etienne is OUT, so the roster has a hole; picking starters before filling it wastes work.

**Local**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: Mon 2026-09-29. Week 4 opens **Thu 10-01 20:15**. First Sunday lock **09:30 ET**
(IND @ WAS, international window — earlier than any prior week).
**Prior**: `20260927-24-WEEK3-GAMEDAY.md` (#31)
**Git**: branch `week3-gameday`, **tree dirty, nothing committed this session.**

Record **2-1**, won Week 3 **108.74 - 96.70**.

Do not re-derive the Week 3 retro. It is complete in
`data/weekly/2026_week03_decisions.md` (`## Retro` parts 1 and 2) and
`data/weekly/README.md`. Read it, don't rebuild it.

---

## 1. THE TASK. Four swap decisions, then set starters.

**Roster is 15. One player is worth 0.** Decide these before touching the lineup.

| # | question | urgency |
|---|---|---|
| 1 | **Etienne is `O`, proj 0.00.** Drop, IR, or hold? | **blocking** |
| 2 | **Chiefs DEF -> Ravens DEF?** Method says yes. | high, free |
| 3 | **K: hold Butker?** Method says yes. Week 3 said method may be wrong for K. | medium |
| 4 | **5 WRs, 2 starting slots + FLEX.** Depth chart mis-ranked. Cut one? | medium |

Everything else is a starter decision and belongs in the Week 4 decision log, not here.

---

## 2. Roster as of 2026-09-29. Week 4 Yahoo projections.

Source `docs/uploads/week_4_data/`, read via `dev/weekly/read_yahoo_week.R`.
**These are week-4 projections, not week-3 actuals** — the export never carries actuals.

| pos | player | team | proj | game | note |
|---|---|---|---|---|---|
| QB | P. Mahomes | KC | **20.0** | Sun 16:25 @ LV | |
| QB | M. Stafford | LAR | 16.5 | Sun 13:00 vs PHI | outscored Mahomes wk3 |
| RB | D. Henry | Bal | **17.7** | Sun 13:00 vs TEN | BAL fav **11.5** |
| RB | J. Williams | Dal | 12.7 | Sun 13:00 @ HOU | |
| RB | W. Marks | Hou | 7.58 | Sun 13:00 vs DAL | |
| RB | K. Gainwell | TB | 6.67 | Sun 13:00 vs GB | |
| RB | **T. Etienne Jr.** | NO | **0.00** | Mon 20:15 | **`O` — OUT** |
| WR | D. Adams | LAR | 11.3 | Sun 13:00 vs PHI | |
| WR | C. Sutton | Den | 9.02 | Sun 16:25 vs SF | |
| WR | R. Odunze | Chi | 8.21 | Sun 13:00 vs NYJ | |
| WR | W. Robinson | Ten | 7.98 | Sun 13:00 @ BAL | TEN dog **11.5** |
| WR | K. Raymond | Chi | 6.28 | Sun 13:00 vs NYJ | **trigger fired, starts** |
| TE | J. Ferguson | Dal | 6.93 | Sun 13:00 @ HOU | only TE |
| K | H. Butker | KC | 8.60 | Sun 16:25 @ LV | only K |
| DEF | Chiefs | KC | 6.45 | Sun 16:25 @ LV | |

**Composition: 2 QB / 5 RB (one worth 0) / 5 WR / 1 TE / 1 K / 1 DEF.**
Nine starting slots, six bench. Carrying two QBs and five WRs for **one** QB slot and
**two** WR slots (plus FLEX).

---

## 3. Swap 1 — Etienne. BLOCKING. Decide first.

**T. Etienne Jr. (RB, New Orleans) is `O`** in the week-4 export, **proj 0.00**,
`rank_actual` **734**. New Orleans plays **Mon 20:15 vs Atlanta**.

**Check this against the standing rule before acting:** per `CLAUDE.md`, *a Yahoo injury
`O` is a state, not an event* — diff it against last week's usage before reading it as
news. Week 3 he was `Q` (hamstring), dressed, and played: 57 rush yds, 13 rec yds,
2 receptions, **8.00 pts**. So this is a **change of state from Q-and-playing to O**, not
a stale designation carried forward. Confirm in `yahoo_week4_injuries.csv` and
`yahoo_week4_gamedaycalls.csv`, which agree with each other.

**Do NOT consult `yahoo_week4_rosterchanges_injured_reserve.csv`.** Same file lied in
Week 3 — 15% of one day's rows listed the same player as both On and Off IR, including
healthy starters.

Three options, and the choice depends on a fact not yet established:

| option | cost | requires |
|---|---|---|
| **IR him** | none — IR 2 slots exist and are **empty** | Yahoo must accept `O` for IR eligibility |
| **Drop him** | permanent, and he was a starter two weeks ago | nothing |
| **Hold on bench** | a roster spot, all week, for 0 points | nothing |

**Open question the next session must answer first: does this league's IR slot accept an
`O` designation, or does it require `IR`/`IR-R`?** Yahoo varies by setting. If IR accepts
`O`, **IR is strictly free** — it opens a roster spot at no cost and keeps the player.
Check the Yahoo roster page directly; the exports do not say.

**If IR is unavailable, the recommendation is drop.** Holding a 0.00 on a 15-man roster
while the FLEX slot needs a body is the worst of the three.

---

## 4. Swap 2 — DEF. Chiefs -> Ravens. The method says yes.

**D6's DST half is the strongest result the weekly layer has produced** (+9.00 in Week 3,
see retro part 2). The rule is: **rank by opponent implied total, lowest first.**

Week 4 opponent-implied, computed from `load_schedules(2026)` as `total/2 - spread/2`:

| DEF | opp | spread | total | **opp implied** | Yahoo proj | rostered |
|---|---|---|---|---|---|---|
| **Ravens** | TEN | -11.5 | 43.5 | **16.00** | **7.58** | FA, 61% |
| Packers | TB | -3.5 | 39.5 | 18.00 | 7.32 | FA, 32% |
| Bears | NYJ | -3.5 | 42.5 | 19.50 | 7.12 | FA, 10% |
| **Chiefs (ours)** | LV | -4.5 | 47.5 | **21.50** | 6.45 | ours |

**Vikings are the method's actual top pick** (opp implied **14.00** vs MIA) — check
whether they are a free agent; they did not surface in the FA scan, so assume rostered
until confirmed.

**Ravens vs Chiefs: opponent implied 16.00 vs 21.50, and Yahoo agrees (+1.13 proj).**
Both signals point the same way. 21.50 sits in the 21-27 tier = **0 points**; 16.00 sits
in 14-20 = 1 with real upside into the 7-13 tier at 4.

**Unflagged consequence, and it matters: a Ravens DEF stacks with Derrick Henry.** Both
are Baltimore, both against Tennessee. That is a genuine single-game concentration —
Henry 17.7 + Ravens ~7.6 = **~25 points in one game**. Week 3's §1 concentration note
applies. It is probably the acceptable kind: per that note, *correlation is not the thing
to avoid, paying for it is*, and this concentration **gains** projected points rather
than costing them. **But the conflict below is real:**

**W. Robinson (WR, Tennessee) is on the other side of that same game**, an 11.5-point
underdog. Starting the Ravens DEF and Robinson simultaneously is betting against yourself.
Note it, don't let it decide the swap — decide the swap on the DEF merits and let the
starter decision handle Robinson.

---

## 5. Swap 3 — K. Hold Butker. But the method is under review.

**Week 3 fired the kicker half of D6** — dropped McLaughlin scored **12.00**, Butker
**6.00**, a 6-point loss past the 3-point bar. The retro proposed dropping the
own-implied-total rule for kickers and holding the incumbent unless the gap is large.

Week 4 own-implied, highest first:

| K | team | own implied | proj | rostered |
|---|---|---|---|---|
| S. Shrader | IND | 25.50 | **8.93** | FA, 17% |
| **H. Butker (ours)** | **KC** | **26.00** | **8.60** | ours |
| E. McPherson | CIN | 27.00 | 8.49 | FA, 67% |
| T. Bass | BUF | 27.75 | 8.48 | FA, 25% |

**Butker is already near the top of the method's own ranking** (KC own implied 26.00, 5th
of 32) and no available kicker beats him by a meaningful margin. **Both the method and the
"hold the incumbent" revision agree: hold Butker.** Nothing to decide, which is the
cleanest possible outcome for a slot under review.

**Note for the record:** own-implied-total and Yahoo proj **disagree in rank order** here
(Shrader has the lower implied total but the higher projection). That disagreement is
itself evidence for the Week 3 read that the K mechanism is weak. One more week.

---

## 6. Swap 4 — the WR logjam. The real structural problem.

**Five WRs, two WR slots, one FLEX.** Week 3's finding: two *benched* pass-catchers
(Raymond 18.00, Robinson 15.20) outscored two of three starting receiver-eligible slots.

Target counts are converging, which is the whole problem:

| WR | wk1 | wk2 | wk3 | wk4 proj | % rostered |
|---|---|---|---|---|---|
| D. Adams | 6 | 10 | 13 | **11.3** | 98% |
| C. Sutton | 5 | 4 | 7 | 9.02 | 79% |
| R. Odunze | 3 | 4 | 6 | 8.21 | 92% |
| W. Robinson | — | — | — | 7.98 | **47%** |
| K. Raymond | 9 | 5 | 7 | 6.28 | **11%** |

**Adams is the only separated player.** The other four sit inside 2.74 projected points of
each other, and Yahoo's projections have not successfully ranked them for three straight
weeks. **Raymond is projected last and scored first in Week 3.**

**This is the cut candidate pool if a roster spot is needed** (e.g. to add a DEF while
holding Etienne). **Do not cut on Yahoo projection alone** — that is exactly the ranking
that has been wrong three weeks running. **Raymond's 11% rostered is not evidence he is
bad; it is evidence he is reclaimable if cut and wrong.** Odunze at 92% rostered is the
opposite — cutting him is irreversible in practice.

**No recommendation is made here.** This needs the next session's judgment with the
decision log open, and it interacts with §3: if Etienne goes to IR, no cut is needed at
all.

---

## 7. Already settled. Do not re-litigate.

1. **Raymond starts Week 4.** His D5 trigger — 6+ targets — **fired at 7**. It was
   pre-committed in the Week 3 log and re-committed unchanged. This is a rule, not a
   judgment call. It cost 11.90 to honour the rule's *miss* in Week 3; honour the *hit*.
2. **Stop analysing Mahomes vs Stafford.** Wrong in both directions now — -17.56 Week 1,
   -5.96 Week 3, **23.52 combined**, both times following the projection. Pick one, leave
   it, spend the analysis elsewhere. Week 4 gap is 20.0 vs 16.5.
3. **Henry starts.** BAL favored **11.5** vs TEN with own implied 27.5 — RB favored 10+
   is the 1.134x bucket per `CLAUDE.md`. Highest-projected player on the roster.
4. **Ferguson, Butker, Chiefs/Ravens are forced slots** — one rostered player each at TE,
   K, DEF. No lineup choice exists there regardless of the swap decisions.

---

## 8. Known gaps this session did not close

1. **Week 4 opponent is unknown.** Not in the exports. Read it off Yahoo. Without it
   there is no head-to-head overlap analysis, which Week 3 proved is worth doing —
   and which produced the one **falsified** claim of the week (§1a, below).
2. **DST still unscored in R.** `score_player_week()` is per-player by design. Week 3's
   Patriots DEF was hand-computed from `config/scoring.json` tiers (allowed 35 -> -4,
   +1 sack, +2 INT = **-1.00**); the same hand method reproduces the Chiefs' Yahoo 8.00
   exactly. **A `score_team_week()` is now clearly worth building** — DST sits on a slot
   we actively manage and it decided the largest swing of Week 3.
3. **§1a hedge claim falsified, carry the correction.** "Sutton is opposed to their Rams
   DEF" was stated at **team** level while the exposure is at **player** level. Denver won
   30-26 (Rams DEF 3.00, correct direction) and Sutton still scored 6.10. Future
   correlation notes must say which level they mean.
4. **§1 concentration bar was mis-set.** It tested "all three under 60%" when the live risk
   was "all three mildly disappoint." KC block returned 30.94 on 37.73 (82%). Candidate
   revision: fire on **block total under 80% of block projection**. Not adopted.
5. **Game-script out-of-sample is uninterpretable at n=3.** All three week-3 tests came in
   backwards (Henry 0.887x, Mahomes 0.741x, Sutton 1.500x) against a 3-game denominator
   containing a 34.80 outlier. **Revisit at week 8+**, not before.
6. **Branch `week3-gameday` dirty, nothing committed.** Week 3 retro, both CSVs and
   `data/weekly/README.md` are all modified and unstaged. `week3-picks` is still 4 ahead
   of `main`, unpushed, no PR.
7. **`renv` out of sync** — `devtools::load_all()` FAILS. Workaround in use: `source()`
   the `R/*.R` files directly. Run `renv::status()`.
8. **Yahoo API still parked.** Applied 09-16, no SLA. Weekly 5-second check:
   `source("dev/yahoo/auth_probe.R"); yahoo_open_consent("fspt-r")` -> `invalid_scope`
   means still pending. **Do not re-probe beyond that one line.**
9. `to-prd` on the weekly picker — queued since #21, still not done.

---

## 9. Validation status. Stop re-checking these.

- **`score_player_week()` is 35/35 across weeks 1-3.** Week 3 added 9 more exact matches
  against the Yahoo box score. **Do not re-validate.** DST is the only gap.
- **The week-4 export carries week-4 PROJECTIONS, not week-3 actuals.** Decimal TD counts
  are the tell. Week 3 bench actuals had to come from
  `nflreadr::load_player_stats(2026)` + `score_player_week()`. Expect the same every week.
- **`dev/weekly/read_yahoo_week.R` handles three silent traps** — invisible private-use-area
  characters in headers, the six-file position whitelist, projections-not-actuals. It read
  week 4 clean (1195 rows, 15 per team). **Do not simplify those guards out.**

---

## 10. Suggested skills

- **`caveman`** — repo doc rule, any doc written including the Week 4 decision log
- **`handoff`** / **`session-close`** — write to `docs/handoff/`, **not `/tmp`**
  (`docs/handoff/README.md` overrides the skill default)
- **`to-prd`** — a `score_team_week()` for DST is now a real, scoped, justified build
  (see §8.2). Also the weekly picker, queued since #21.
- **`claude-md-management:revise-claude-md`** — only if a durable pattern emerges. Two
  candidates from Week 3: the team-level-vs-player-level correlation distinction (§8.3),
  and "the Yahoo weekly export never contains last week's actuals" (§9).

---

## 11. Read order

1. This doc, §1. That is the task.
2. `data/weekly/2026_week03_decisions.md` `## Retro` parts 1 and 2 — what fired and why.
3. `data/weekly/README.md` `## Cases so far` + Week 3 notes — regret series 19.76 / 2.50 /
   **25.06**.
4. `CLAUDE.md` — league facts, scoring, football primer, Yahoo-export gotchas.
   **Assume the user knows football casually. Name team and role when naming a player.**

Do not read `docs/handoff/drafting/`. Draft phase closed.
