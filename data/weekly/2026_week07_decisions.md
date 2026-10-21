# Week 7 Decisions — 2026, JGrahnasaurs (3-3, 6th)

Opened and **frozen 2026-10-21 Wed**. Opponent: **Monday Night Madison (1-5, 10th)**.
Frozen early and in full — user on a road trip through the week, no mid-week agent.
**Binding deadline is Thu 10-22 8:15pm** (Odunze, CHI vs NE — a bench WR is a legal
replacement, so `min(kickoff of legal replacements)` lands Thursday, not Sunday).
Third time this season the binder is not a starter's own kickoff.

Nothing below `## Retro` edited after freeze.

Source of record: `docs/uploads/week_7_data/*_2026-10-21.csv` (Yahoo position exports,
read via `dev/weekly/read_yahoo_week.R`) + `data/nflreadr/pull_2026.rds`
(cache cleared, re-pulled 2026-10-21 07:57, new harness `dev/weekly/pull_nflreadr.R`).
Prior: handoff #43 `docs/handoff/ffdraft-handoff-20261020-36-WEEK7-BATES-CLAIM-IN.md`.

---

## 0. Headline. Lineup is projection-optimal at **105.27** vs their **100.60**. +4.67.

Three corrections to #43 drove the week. All three came from the fresh pull, none from
reasoning.

| #43 said | truth |
|---|---|
| Butker at K, lineup 104.36 | **Bates landed, proj 8.61 > Butker 7.49.** Lineup 105.27 |
| Hockenson `Q`, 8.22 vs Higbee 7.55 (8% gap) | **`Q` = CONCUSSION.** 8.09 vs 7.88, **2.7%** |
| opponent ~89.54, "+4.74 if they notice" Barkley | **They have him. 100.60.** We are +4.67 |

---

## 1. Lineup. Frozen.

```
QB   M. Stafford   LAR @ LV   Sun 4:25   19.16    BN  P. Mahomes  16.49
RB   D. Henry      BAL v CIN  Sun 1:00   17.46    BN  R. Odunze    8.73  Thu 8:15
RB   J. Williams   DAL @ PHI  Mon 8:15   14.99    BN  T. Higbee    7.88  Sun 4:25
WR   D. Boston     CLE @ TEN  Sun 1:00    9.37    BN  H. Butker    7.49
WR   C. Tate       TEN v CLE  Sun 1:00    9.13    BN  Chiefs DEF   5.62
TE   T. Hockenson  MIN v IND  Sun 1:00    8.09    BN  B. Strange   0.00  JAX bye
FLX  O. Gordon II  MIA @ NYJ  Sun 1:00   11.15    IR  D. Adams / T. Etienne Jr.
K    J. Bates      DET v GB   Sun 4:25    8.61
DEF  Browns        CLE @ TEN  Sun 1:00    7.31
                              total     105.27
```

Frozen files: `2026_week07_myteam.csv`, `2026_week07_opponent.csv`.

---

## 2. Decisions, with pre-registered kill conditions.

### K1. Start **Bates** (8.61) over Butker (7.49). 15% gap, above every dead band.

Rule and projection **CONCORDANT**: Bates is DET own implied **28.25 — #1 of 28 teams**;
Butker is KC **20.00, 22nd**. Yahoo agrees.

**This therefore does NOT test the K rule.** #43 §6.2 pre-registered wk7 as "the K rule's
first real test." It is not one — a rule is only tested by a **discordant** pair, where
the rule and the raw projection disagree. Same logic that killed the spread tiebreak on
215 discordant pairs. **Carry the K test forward to the first week the two disagree.**

> **KILL (K1): none scoreable this week.** Log Bates' actual for the ledger, draw no
> verdict on the rule from it.

### T1. Start **Hockenson** (8.09) over Higbee (7.88) — on ORDERING, not belief.

`yahoo_week7_injuries`: `T.J. Hockenson | 31840 | Min | TE | Q | Concussion`.
He has not played a real game since **week 4**: wk5 was **3% snaps / 1 target** (injury
week), MIN bye wk6. `nflreadr::load_injuries()` has **zero rows** for him all season, so
the Yahoo export is the only trace — recorded because it contradicts the nflverse source.

Higbee moved the other way: snaps **20/26/71/65/67/83**, 5.8 tgt/g.

The 2.7% gap is noise under any dead-band width (§R4 open test has the 5-15% band at
46.6%). So the call is not made on the projections at all — it is made on **slot
ordering**: Hockenson plays **1:00**, Higbee **4:25**. Starting Hockenson *keeps* the
swap; starting Higbee throws it away. Strictly better regardless of which number you
believe. Concussions are also closer to binary (clear or sit) than soft-tissue, so
"active but snap-limited" is the less likely failure mode.

> **KILL (T1): if Hockenson is on the Sunday inactive list and the lineup is not swapped
> to Higbee before 12:55pm ET, the free option was wasted — that is a process failure,
> logged as such, separate from the outcome.** User is travelling; if nobody is at a
> screen, record it as **option forfeited by absence**, not as a wrong call.

### W1. **HOLD Tate** (9.13) over Odunze (8.73). Locks Thu 8:15pm.

User raised two arguments against Tate. Both answered from measured data, neither
accepted.

**(a) "TEN has a horrible record."** True — TEN **1-5, 14.0 ppg, 32nd of 32**; game total
**37.5, lowest on the slate**. But target share is where the player lives:

```
Tate   (TEN)  21/29/26/43/14/32   mean 28%   7.3 tgt/g   snaps 88/75/88/84/76/74
Odunze (CHI)  12/13/18/23/22/12   mean 17%   5.5 tgt/g   snaps 48/84/85/89/99/96
Boston (CLE)  18/23/13/21/22/20   mean 20%   5.7 tgt/g   snaps 92/93/89/95/91/92
```

Tate is TEN's #1. Odunze is CHI's #3 in a crowded room *despite* 96% snaps. 28% of a
27.5-target offence out-targets 17% of a 32.3-target offence by ~1.8/game. **The bad team
shrinks the pie by less than Tate's share exceeds Odunze's.**

Measured directly: **WR game-script slope -0.00129/pt, p = 0.679 — flat**, n = 1,132.
Underdog status does not move WR scoring; trailing teams pass more and it offsets.
"CHI's offence is better" is the **retired spread tiebreak** in costume (CHI own implied
26.75 vs TEN 18.00) — died 2026-10-13, 215 discordant pairs, 48.8%, CI excludes >55.7%.
**Not relitigated.**

**(b) "Boston vs Tate is a hedge."** Correct, and it is an asset this week.
`CLAUDE.md`: correlation is not the thing to avoid — *paying* for it is. We paid nothing:
Tate is the best WR behind Boston, Browns DEF is the rule-correct DEF (opp implied 18.00,
4th lowest). The negative leg is **Tate vs Browns DEF** (the DEF scores when TEN fails),
which **compresses** variance. We are the +4.67 favourite, and favourites want lower
variance. Swapping Tate out costs 0.40 points *and* raises variance. Wrong on both axes.
Boston/Tate are mildly *positively* linked via the 37.5 total, which Yahoo already priced
into both — discounting again is the #33 double-count.

> **KILL (W1a):** Odunze outscores Tate by **> 3.0** this week → the share argument was
> the wrong read for one week; needs 3 such weeks before the method moves (single weeks
> are underpowered, see `single-seed-bars-underpowered`).
> **KILL (W1b), the hedge:** TEN-CLE lands **under 30 total points** AND Tate + Boston +
> Browns DEF combine **under 15.0** against a 25.81 projection → the free-hedge framing
> failed; re-examine holding two WRs plus the DEF in one bottom-of-slate total.

### D1. Start **Browns DEF** (7.31). Opp implied **18.00, 4th lowest of 28**.

Line moved from #43's 18.50; rank unchanged. Chiefs DEF alternative is opp **22.50**.

> **KILL (D1): retired for DST** per `CLAUDE.md` — the rule is validated league-wide
> (r = -0.275, p = 0.0017, n = 128, +1.92 pts/wk) and explains only 7.6% of variance.
> **Do not kill it on a bad week.** Log the actual, no verdict.

### M0. **No roster move. Roster is full and there is no hole.** HOLD, recorded as a result.

User asked whether two IR bodies open a slot for a better TE. Ran need-before-candidates
in order, from source, before looking at any candidate:

**Step 1 — counts.** 15 active (QB2 RB3 WR3 TE3 K2 DEF2) + **2 IR (Adams, Etienne)**.
15 is the cap. **IR slots are separate and do not add active capacity** — both already
filled. Any add costs a drop.

**Step 2 — byes, from `load_schedules(2026)`** (`setdiff(all_weeks, weeks_played)`):
```
KC 5 · MIA 6 · MIN 6 · JAX 7 · NO 8 · TEN 9 · CHI 10 · LA 11 · CLE 11 · BAL 13 · DAL 14
```
Startable bodies, weeks 7-17 — **every week fillable, TE never short**:
```
week      7  8  9 10 11 12 13 14 15 16 17
TE        2  3  3  3  2  3  3  3  3  3  3
flexpool  8  9  8  8  7  9  8  8  9  9  9
```
Week 11 is the tightest of the season (QB 1, DEF 1, 7 flex bodies for 6 slots) and is
still legal. **Keep Chiefs DEF — it is the week-11 DEF.**

**Correction to `CLAUDE.md` and #43:** the standing line "TE 1-deep all season, zero in
wk14" is **stale**. It was true at week 4. We are **3-deep** and covered through 17.

**Step 3 — only then, the pool.** Ranked available TEs (`FA` *and* `W (...)`, 1,036 rows)
on **targets last 3**, never ppg:

| TE | tgt/g | **last 3** | snaps wk1-6 | wk7 proj |
|---|---|---|---|---|
| **Strange (JAX) — OURS** | 5.5 | **7.7** | 68/83/77/87/81/76 | 0.00 JAX bye |
| Higbee (LAR) — ours | 5.8 | 5.3 | 20/26/71/65/67/83 | 7.88 |
| Hockenson (MIN) — ours | 5.4 | 6.0 | 66/69/85/83/3 | 8.09 |
| Mayer (LV) — best FA | 5.7 | 6.7 | 81/84/87/88/65/79 | 6.09 |
| H. Henry (NE) — FA | 4.0 | 4.7 | 76/91/70/64/64/76 | 7.34 |
| Waller (CAR) — FA | 4.2 | 5.3 | 35/44/51/53/46 | 5.69 |

**Strange has the best TE target trend on the board, ours or the wire's.** He reads 0.00
only because JAX is on bye *this* week — he returns wk8 as arguably our TE1 on usage.
Mayer is the only comparable FA and is not better than any of our three. **No add.**

**Standing finding, not this week's action: Butker is now our only genuinely droppable
body.** Both kickers have their byes behind them (KC 5, DET 6), so with Bates in, Butker
is pure redundancy. That is the roster spot — it was not spent on a TE we do not need.

---

## 3. Open tests carried in, not resolved this week.

1. **§R4 pair band.** Within-roster RB/WR/TE pairs: 67.6% right above a 15% gap (n=330),
   **46.6% in the 5-15% band** (n=58, CI [33.7, 59.4]). Pre-registered: **pool wks 4-7,
   revisit at week 8. If the 5-15% band is still under 55% at n >= 200, the dead band
   widens from 5% to 15%.** Week 7 adds its pairs to the pool; do not score early.
2. **Yahoo projection sign.** Ran **-1.79 low at all six positions**, n=135, MAE 5.23 in
   wk6. Uniform sign. Re-check on wk7 actuals before calling it anything.
3. **Stream detector.** Needs a **Sunday pre-kickoff export pull** to make
   `FA -> OWNED -> W` unambiguous. **Will not happen this week — user travelling.**
   Third consecutive week this pull is missed. Not a failure of the detector; a gap in
   observation.

---

## 4. League-wide seed for the next session. Not a week-7 decision.

Week-7 projection-optimal ceiling, all ten rosters, from the same export:

| # | team | optimal |
|---|---|---|
| 1 | Owl Out Blitz | 122.66 |
| 2 | Maybe Mitchell | 116.20 |
| 3 | Locked In Michelle | 115.62 |
| 4 | Max's TD Bombers | 112.05 |
| 5 | Jason's Jazzy Team | 105.99 |
| 6 | Dave's Bone Crushers | 105.94 |
| **7** | **JGrahnasaurs** | **105.27** |
| 8 | Steel City | 103.70 |
| 9 | Monday Night Madison | 100.60 |
| 10 | Sunday Kevin | 96.43 |

**We are 7th of 10 on roster ceiling while 1st of 10 on regret (3.40).** That is
`CLAUDE.md`'s "lineup layer is at its ceiling" stated from the other side: we play our
roster nearly perfectly and the roster is below median. Leverage is roster quality.

Drawn from one week of projections, so it is a **flag, not a finding**. It is the thing
the next session is for.

---

## Retro

*(append after Monday 2026-10-26. Never edit above this line.)*
