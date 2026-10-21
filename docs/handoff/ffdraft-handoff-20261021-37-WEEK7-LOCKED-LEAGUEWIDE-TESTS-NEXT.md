# Handoff #44 — Week 7 LOCKED and unattended. Next session: build season-improvement tests across ALL TEN rosters.

Written 2026-10-21 Wed. Branch `week3-gameday`.
Prior: `docs/handoff/ffdraft-handoff-20261020-36-WEEK7-BATES-CLAIM-IN.md` (#43).
Index: `docs/handoff/README.md`.

**Authority for week 7 is `data/weekly/2026_week07_decisions.md`.** It is complete,
frozen, and carries every kill condition. Do not re-derive the lineup.

---

## 0. READ THIS FIRST. Week 7 needs nothing. The next session is a different job.

**User is on a road trip until the week is over.** Week 7 is frozen early and in full by
design. **No mid-week agent action is expected or wanted.**

Two consequences:

1. **The Sunday pre-kickoff export pull will NOT happen.** Third week running. The stream
   detector stays blocked and the opponent's *started* lineup is unrecoverable for wk7.
   Known cost, accepted deliberately. Do not treat it as an error to fix.
2. **The T1 free option will go unexercised.** Hockenson is `Q` with a **concussion**; if
   he is inactive Sunday the swap to Higbee will not be made. Pre-registered in the
   decision log as **"option forfeited by absence," not a wrong call.** Score it that way.

---

## 1. The next session's brief, in the user's own framing.

> "look across ALL teams to figure out what our season-improvement tests will be ...
> develop those tests against ALL teams, not just my own — what are WE doing, what are
> THEY doing ... We don't need to dominate, we just need to win each remaining matchup,
> even by 1 point."

**User will run this on the highest model available on their subscription.** Treat it as
the session with the most headroom all season. Scope it accordingly.

### 1a. Three things that brief changes about method.

**(1) The unit of success is the MATCHUP, not the point total.** Every measurement in the
repo to date scores points or MAE. The objective is `P(our score > their score)` summed
over weeks 8-17. A roster move that adds 4 points to a week we win by 20 is worth
**zero**. One that adds 2 points to a week we lose by 1 is worth the season. **Any test
built next session must be scored in wins, or in margin where margin is near zero — not
in points.** This is a genuinely new frame for this repo and the most important line here.

**(2) The population is 10 rosters, not 1.** `dev/weekly/leaguewide_retro.py` and
`dev/weekly/spread_tiebreak_leaguewide.R` already prove the pattern: our own roster gives
n≈15/week and nothing is ever powered; ten rosters give n≈150 and the spread tiebreak
died on exactly that. **Default to league-wide for every new test.** See
`single-seed-bars-underpowered`.

**(3) Opponent modelling is now in scope, and it was not before.** Everything in-season
so far has been "pick our best lineup." Winning by 1 means knowing **who we play, what
their ceiling is, and where their roster is thin.** That is a real build, not a tweak.

### 1b. The seed finding. We are 7th of 10 on roster, 1st of 10 on decisions.

Week-7 projection-optimal ceiling, all ten rosters (`dev/weekly/league_ceiling.R`,
rerunnable, `YDIR` env var sets the export dir):

| # | team | optimal | | # | team | optimal |
|---|---|---|---|---|---|---|
| 1 | Owl Out Blitz | 122.66 | | 6 | Dave's Bone Crushers | 105.94 |
| 2 | Maybe Mitchell | 116.20 | | **7** | **JGrahnasaurs** | **105.27** |
| 3 | Locked In Michelle | 115.62 | | 8 | Steel City | 103.70 |
| 4 | Max's TD Bombers | 112.05 | | 9 | Monday Night Madison | 100.60 |
| 5 | Jason's Jazzy Team | 105.99 | | 10 | Sunday Kevin | 96.43 |

Against: our week-6 regret was **3.40, lowest in the league** (league range to 38.70), and
our 4-week deviation regret is **0.80 total — 0.20/wk**.

**Read: we play a below-median roster nearly perfectly.** That is `CLAUDE.md`'s "lineup
layer is at its ceiling" seen from the other side. It is also one week of projections, so
it is a **flag, not a finding** — the first job next session is to make it a finding or
kill it across weeks 4-7.

### 1c. Candidate tests. Ranked. All league-wide, all scored in wins or margin.

Do not treat this list as the plan — the user asked to *develop* the tests. This is the
starting shortlist, strongest first.

1. **Roster-ceiling-vs-record.** Does projection-optimal ceiling predict who wins?
   Compute all ten ceilings for weeks 4-7 (the weeks with `*_actual_*` exports), regress
   actual margin on ceiling difference. If ceiling difference predicts margin, roster
   quality is the lever and the season plan is trade/wire aggression. If it does not,
   stop working the roster. **This is the gate on everything else below.**
2. **Remaining-schedule win probability.** We need the weeks 8-17 matchup grid (see §2
   data gap). For each remaining opponent, ceiling distribution vs ours → `P(win)`.
   Ranks the weeks where one roster move flips a loss. **Directly serves "win by 1."**
3. **Who is actually good at streaming, and at what.** The `OWNED -> W` / `FA -> OWNED`
   transition diff already works (#43 §4) and caught Dave's Bone Crushers running the DST
   stream. Extend league-wide across weeks: which managers stream, at which slots, and
   does it show up in their margins. We have **15 moves to the league's next-highest 10**
   and are 6th in points for — so our churn is *not* obviously paying, n=6.
4. **Positional leak, league-wide.** Our pooled leak is WR 46.90, QB 23.52, K 12.00,
   DEF 0.00, TE 0.00 — but `CLAUDE.md` is explicit that this measures the *projection*,
   not us. Across ten rosters the same decomposition separates "nobody can project WRs"
   from "our WRs specifically are bad." **Only the second is actionable.**
5. **§R4 dead-band widening.** Already pre-registered and due: pool wks 4-7 pairs,
   **revisit at week 8**. If the 5-15% band is still under 55% at n >= 200, the dead band
   widens from 5% to 15%. This one is a commitment, not a candidate — honour it.

### 1d. Four traps this brief walks straight into.

- **`if-followed` counterfactual columns are NOT team rankings.** #43 §R9: Owl Out Blitz's
  `if-followed` said 83.90, they scored **111.14, +27.24**. `leaguewide_retro.py` prints a
  warning. A league-wide session will be tempted to rank on it. **Do not.**
- **Streaming is invisible in arrears by construction.** An export dated after kickoff
  cannot show add-and-drop inside one week. Same defect class as the missing
  started/bench flag. Any league-wide churn measure is a **lower bound.**
- **n = 7 weeks. Fit nothing.** Ten rosters multiplies *cross-section*, not weeks. A
  league-wide n=150 player-weeks is still 4-7 weeks of correlated time. Tests, not models.
- **`rosterchanges_*` is six-for-six untrustworthy** (IR, league_team, added, and the
  `FA -> W` Sunday sweep that fired 1,031 of 1,037). **Rosters come from the six position
  exports** via `Roster Status`. Nothing else.

---

## 2. Data gap the next session must close FIRST.

**We do not have the weeks 8-17 matchup schedule.** None of the 14 week-7 export files
carries it — they are player tables, not league structure. Test #2 above is blocked
without it.

**Ask the user for the Yahoo schedule page** (who JGrahnasaurs plays each week 8-17), or
the standings page which usually carries it. One paste, unblocks the whole
remaining-schedule analysis. **Do this at the top of the session, not after building.**

Also still missing and still worth having: Yahoo's own ADP/ownership as an opponent
behaviour signal — `yahoo_id`, `player_owned_yahoo` are 100% NA in `ff_rankings`. Known
standing blind spot, not newly discovered.

---

## 3. What week 7 actually decided. Summary only — detail is in the decision log.

**Lineup 105.27 vs Monday Night Madison 100.60. +4.67.** Projection-optimal, every slot
checked against every bench alternative.

Three corrections to #43, all from the fresh data pull, none from reasoning:

| #43 said | truth |
|---|---|
| Butker at K, 104.36 | **Bates landed, 8.61 > Butker 7.49.** 105.27 |
| Hockenson `Q`, 8.22 vs 7.55 (8%) | **`Q` = CONCUSSION.** 8.09 vs Higbee 7.88, **2.7%** |
| opponent ~89.54 | **100.60.** They have Barkley. We are +4.67, not +10 |

Decisions: **K1** Bates (rule and projection concordant → **does not test the K rule**,
carry that test to the first discordant week). **T1** Hockenson on *slot ordering* not
belief — he plays 1:00, Higbee 4:25, so starting Hockenson keeps the swap. **W1** hold
Tate over Odunze. **D1** Browns DEF, opp implied 18.00. **M0** no roster move.

### 3a. Two standing claims CORRECTED. Both are in `CLAUDE.md` or #43 and both are wrong.

1. **"TE 1-deep all season, zero in wk14" is STALE.** True at week 4. We are now
   **3-deep** (Hockenson, Higbee, Strange) and **every week 7-17 is fillable** — TE never
   drops below 2. Week 11 is the season's tightest week (QB 1, DEF 1, 7 flex bodies for 6
   slots) and is still legal. **Keep Chiefs DEF — it is the week-11 DEF.**
2. **Strange is not dead weight.** He reads 0.00 this week only because **JAX is on bye
   in week 7**. His target trend is **7.7 over the last 3 — the best TE trend on the
   board, ours or the wire's** (5.5 tgt/g, snaps 68/83/77/87/81/76). He returns in week 8
   as arguably our TE1 on usage. Best available FA TE is Mayer (LV, 6.7 l3) and he is not
   better than any of our three. **No TE add was warranted; the user's instinct that the
   concussion needed covering was right, and it was already covered.**

### 3b. Standing finding, carried.

**Butker is our only genuinely droppable body.** Both kickers have their byes behind them
(KC 5, DET 6), so with Bates rostered Butker at 7.49 is pure redundancy. That is the
roster spot. It was deliberately **not** spent on a TE we do not need — spend it against
test #1's verdict, not on the next player who looks good. **Need before candidates.**

---

## 4. New and changed files.

| path | what |
|---|---|
| `data/weekly/2026_week07_decisions.md` | **NEW.** Frozen, kill conditions pre-registered |
| `data/weekly/2026_week07_myteam.csv` | **NEW.** Freeze-time projections, slots, started flag |
| `data/weekly/2026_week07_opponent.csv` | **NEW.** Their projection-optimal, not their started |
| `dev/weekly/pull_nflreadr.R` | **NEW.** Clears cache, pulls 2026, writes `data/nflreadr/pull_2026.rds` |
| `dev/weekly/league_ceiling.R` | **NEW.** All-ten projection-optimal ceilings. `YDIR` env var |
| `dev/weekly/roster_need.R` | **NEW.** Counts + byes from source + per-week fillability grid |
| `dev/weekly/rank_fa_te.R` | **NEW.** FA pool ranked on target trend, not ppg |
| `dev/weekly/freeze_lineups.R` | **NEW.** Writes both frozen CSVs |
| `.gitignore` | `data/nflreadr/` — the pull is a reproducible cache, 960K xz |

All four new harnesses verified rerunnable from the repo root.

---

## 5. Environment. Deltas from #43 §8 only.

- **nflreadr re-pulled 2026-10-21 07:57**, cache cleared. player_stats / snaps /
  team_stats weeks **1-6**; injuries weeks **1-7**. R 4.5.2, nflreadr 1.5.1.
- **`load_injuries()` week 7 is CHI/NE only** (23 rows, the Thursday game) and
  `report_status` is entirely NA — practice reports for Sunday games had not filed
  Wednesday morning. **Do not read an empty wk7 injury filter as "nobody is hurt."**
- **`load_injuries()` has ZERO rows for Hockenson all season**, while the Yahoo injuries
  export has him `Q / Concussion`. **The two sources disagree and Yahoo is right here.**
  New gotcha, not previously recorded.
- **Player-name traps in the 2026 pool**, all cost a failed grep this session:
  `Denzel Boston` (not Tre), `Carnell Tate` (not Golden — and `Tate Ratledge` is a DET
  OL who matches `Tate`), `Ollie Gordon II` (snaps table says `Ollie Gordon`, stats table
  says `Ollie Gordon II` — **the same player spelled two ways in one package**).
- `load_player_stats()` team column is **`team`**, not `recent_team`.
- `load_depth_charts(2026)` returns **677,875 rows with no `week` column** and inflates
  the saved pull to 12M. Dropped from `pull_nflreadr.R`'s bundle; load on demand.
- Byes recomputed from source: KC 5 · MIA 6 · MIN 6 · JAX 7 · NO 8 · TEN 9 · CHI 10 ·
  LA 11 · CLE 11 · BAL 13 · DAL 14.
- `git commit -F <file>` still required; apostrophes break the heredoc form.

**n = 7. Fit nothing.**

---

## 6. Open, carried. Unchanged and still not week 7's work.

1. **Push. Still no PR, 33+ ahead of `origin/main`.** Oldest carried item.
2. Etienne IR reactivation — still NO, unexamined since #34.
3. Yahoo API application still not submitted
   (`https://sports.yahoo.com/developer/access/`). **Do not re-run the probes.**
4. Pierce (PHI RB) unowned-and-watched. Rejected again — RB is our deepest room.
5. Stream detector blocked on the Sunday pre-kickoff pull. Will not clear this week.

---

## 7. Suggested skills

| skill | when |
|---|---|
| **`caveman`** | Repo rule — all docs this style. Applied here |
| **`grill-me`** | **Recommended for the next session.** The brief is "develop the tests," and the trap is building a test that scores points instead of wins. Getting grilled on the test design before writing a harness is the right order |
| **`handoff`** | End of next session. **Write to `docs/handoff/`, NOT the OS temp dir** |

**Do not reach for `tdd`, `improve-codebase-architecture`, or `to-issues`.** In-season
work is a decision log, not a build. The draft engine is done.
