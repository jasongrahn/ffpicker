# Handoff #43 — Week 6 retro done + corrected. Week 7 lineup optimal, Bates claim in. Wed FA check pending.

Written 2026-10-20 Tue afternoon. Branch `week3-gameday`, HEAD `fda9d0b`.
Prior: `docs/handoff/ffdraft-handoff-20261014-35-WEEK6-FROZEN-TESTS-ARMED.md` (#42).
Index: `docs/handoff/README.md`.

**Authority for week 6 is `data/weekly/2026_week06_decisions.md` §R1-R10.** Read §R8-R9
first — they correct §R1 and §R6 of the same doc. Do not re-derive.

---

## 0. State. **3-3, 6th.** Week 7 in flight vs Monday Night Madison (1-5, 10th).

Two commits:

| commit | what |
|---|---|
| `0b98351` | Week 6 retro, league-wide harness, actuals backfilled |
| `fda9d0b` | **Correction.** Final 111.14, they DID stream. R6 wrong, R3 over-read |

Week 6: **L 91.68 - 111.14.** Regret **3.40**, lowest in the league.

---

## 1. !! ONE OPEN ACTION. Wed 2026-10-21 morning: confirm Bates cleared. !!

**Claim submitted Tue 10-20 for Jake Bates (K, Det).** Waiver priority was **10 of 10**,
so the claim cost nothing — last is last.

Why Bates: DET vs GB, **own implied total 28.25, highest in the league wk7** (total 53.5).
Butker is KC @ SEA at 20.00, 13th. K rule ranks on own implied total, highest first.

**Do NOT auto-start him.** `CLAUDE.md`: the Yahoo projection beats our models for
one-week start/sit. Butker's wk7 proj is **7.49**. Pull Bates' wk7 Yahoo proj and start
the higher. The *add* was free; the *start* is a separate decision.

Roster was 14 of 15 active (Adams moved to IR), so the add fills the open spot and costs
no drop. **After it lands the roster is full again** — any further add needs a drop.

Second free look at the wire is Wed after the clear. Spends nothing.

---

## 2. Week 7 lineup is projection-optimal at **104.36**. Verified every slot. Do not touch.

```
QB   Stafford     LAR @ LV  Sun 4:25   19.13     BN  Mahomes   16.49
RB   Henry        BAL v CIN Sun 1:00   17.39     BN  Odunze     8.72  Thu 8:15
RB   J.Williams   DAL @ PHI Mon 8:15   14.90     BN  Higbee     7.55  Sun 4:25
WR   Boston       CLE @ TEN Sun 1:00    9.43     BN  Chiefs     5.62
WR   Tate         TEN v CLE Sun 1:00    9.09     BN  Strange    0.00  JAX bye
TE   Hockenson Q  MIN v IND Sun 1:00    8.22     IR  Adams O / Etienne
FLX  Gordon II    MIA @ NYJ Sun 1:00   11.35
K    Butker       KC  @ SEA Sun 8:20    7.49
DEF  Browns       CLE @ TEN Sun 1:00    7.36     opp implied 18.50, 4th lowest
                            total     104.36     vs their 89.54
```

Checked against every bench alternative. Stafford > Mahomes, Gordon II is the highest
remaining FLEX body, Browns > Chiefs on opponent implied total (18.50 vs 22.50).

### 2a. Deadlines. **Thursday binds, not Sunday.**

**Thu 10-22 8:15pm ET.** Odunze (CHI vs NE) is a legal WR/FLEX replacement, so
`min(kickoff of legal replacements)` puts the **WR slot on Thursday**. Third time this
season the binding deadline is not a starter's own kickoff (wk2 Adams, wk6 Strange).

**Call is HOLD.** Tate 9.09 > Odunze 8.72, a 4% gap.

> **The temptation is live and the answer is no.** CHI own implied **26.75** (3rd in the
> league) vs TEN **18.50** (4th lowest). That argument is the **retired spread
> tiebreak** — died 2026-10-13 on 215 discordant pairs at 48.8%. Inside the band, start
> the higher raw Yahoo projection and stop. **Do not relitigate.**

**Sun 10-25 ~11:30am ET.** Hockenson is `Q`. He plays 1:00, Higbee 4:25 — that ordering
is a **free option**: read the inactive report, still swap Higbee in afterwards. Hold
Hockenson by default (8.22 vs 7.55 is an 8% gap, inside the coin-flip band §R4 measured,
and Yahoo already discounts a `Q`). **If he is on the inactive list, swap before 1:00pm**
— the slot locks at his kickoff whether he plays or not.

**Sun 10-25 ~9:30am ET.** Pull the Yahoo export. See §4.

### 2b. Two facts, no action.

- **Opponent ceiling is ~94.28.** Saquon Barkley (`Q`, 12.67) sits behind Jeremiyah Love
  (`Q`, 7.93) at their RB. **+4.74 if they notice**, and Madison is a heavy churner, so
  assume they do. We are still +10.
- **25% of our points are in TEN-CLE** (Tate 9.09, Boston 9.43, Browns DEF 7.36 = 25.88
  of 104.36), with Tate opposed to the other two. Damps variance rather than adding it,
  and it arrived free — no projected points were paid for it. Fine per the correlation
  rule. Floor and ceiling both compressed.

---

## 3. Week 6 retro. Done, committed, then corrected. Read §R8 before anything else.

### 3a. Conditions. **Both powered tests PASS.**

| # | condition | result | verdict |
|---|---|---|---|
| **A4** | Strange snap% < 60 | **76%** | PASS. Range now 68/83/77/87/81/76 |
| **W3** | Tate < 6 tgt | **7 tgt, 16.00** | PASS. **Tate is NOT the drop.** Test disarmed |
| S1 / S2 / D10 / H1 | — | all right | **deposits**, not verdicts, as pre-registered |

**Carry forward: the Tate drop case is void.** Re-rank any drop from snap share.

### 3b. New harness. `dev/weekly/leaguewide_retro.py <week> <projdate> <actdate>`.

Reconstructs all 10 rosters from `Roster Status` on the six `*_actual_*` exports. Three
outputs the single-roster retro cannot produce. Numbers in `2026_week06_decisions.md`
§R3-R5; do not re-type them here.

Headline: **regret 3.40 (us) to 38.70 across ten rosters running the identical rule.**
A weekly regret number measures the roster's projection error, not the manager.

**But see §R9 — that claim is capped.** The `if-followed` column is a counterfactual.
Owl Out Blitz's said 83.90 / regret 29.64; they actually scored **111.14**, beating it by
**+27.24**. **Do not rank teams by that column.** The harness now prints that warning.

### 3c. Open from R4. Pre-registered, do not act early.

Within-roster RB/WR/TE pairs, higher Yahoo proj vs lower: **67.6%** right above a 15% gap
(n=330), **46.6%** in the 5-15% band (n=58, CI [33.7, 59.4], mean **-1.17 pts**). The dead
band may be wider than 5%.

**Kill condition: pool wks 4-7, revisit at week 8. If the 5-15% band is still under 55%
at n >= 200, the dead band widens from 5% to 15%.** The spread tiebreak needed 215
discordant pairs to die; 58 is not enough. See `single-seed-bars-underpowered`.

Also open: **Yahoo projections ran -1.79 low at all six positions**, n=135, MAE 5.23.
Uniform sign. Re-check at wk7 before calling it anything.

---

## 4. The stream detector. Scoped, partly built, blocked on one data pull.

Motivation: Owl Out Blitz's 111.14 is **unreachable from their Monday roster** (all 1,440
legal lineups enumerated). They added a 16th player and dropped him Sunday night. 18
candidates fit; none identifiable.

**Two dead ends, recorded so they are not retried:**

1. `rosterchanges_added_*.csv` is **not** a league transaction log. 1,779 of 2,891 rows
   dated "Apr 6", `Change` is the constant `"Added"`, byte-identical row count across the
   Wed and Mon pulls. Yahoo's player-DB load log. **Fifth untrustworthy member of the
   `rosterchanges_*` family.**
2. **Diffing `Roster Status` Wed -> Mon does not detect streaming.** `FA -> W` fired for
   **1,031 of 1,037** unowned players — it is Yahoo's Sunday-night sweep, not a signal.
   Nearly shipped this as a detector; it carries zero information.

**What does work**, from the same diff:

| transition | n | meaning |
|---|---|---|
| `OWNED -> W` | 7 | dropped in-week, names the dropper |
| `FA -> OWNED` | 6 | added in-week and kept |

That caught Dave's Bone Crushers dropping Bears DEF and adding Ravens DEF — **another
manager running the DST stream, now visible.** Monday Night Madison churned 4-for-4.

**Blocker: an add-and-drop inside one week stays invisible.** Fix is a **third export
pull, Sunday morning pre-kickoff**: `FA` (Wed) -> `OWNED` (Sun) -> `W` (Mon) is
unambiguous and names the owner. That same pull satisfies loop step 2 (freeze both
lineups pre-kickoff), which has now been skipped twice — costing the week-5 opponent
total and the week-6 stream identity.

**Partly answered already, from the standings page:** we have **15 moves, league's
next-highest is 10** (Madison), then 8 (Owl Out Blitz). **Nobody out-churns us.** And we
are 6th of 10 in points for (654.82). So the activity is not obviously paying. Flag, not
a finding — n=6 and some moves were forced bye patches.

---

## 5. Corrections to #42 that are now load-bearing.

| #42 said | truth |
|---|---|
| "they never filled the empty slot" (and R6 built a lesson on it) | **False. They streamed.** §R8 |
| W3 would fire -> Tate is the drop | **W3 passed.** Drop case void |
| wk7 freeze deadline | **Thu 8:15pm**, not Sunday — Odunze, not a starter |
| waiver priority 9 of 10 | **10 of 10.** The wk6 DEF claims dropped us to last |

**Generalised rule, candidate for `CLAUDE.md` on recurrence:** a Yahoo export dated after
kickoff cannot show a player added and dropped inside the same week. **Streaming is
invisible in arrears by construction.** Same defect class as the missing started/bench
flag, same fix: observe before kickoff. §6c named the trap; R6 then fell into it one
section later in the opposite temporal direction.

---

## 6. Next session, in order.

1. **Wed morning:** confirm the Bates claim landed. Second free wire look, spends nothing.
2. **Wed:** pull Bates' wk7 Yahoo projection, compare to Butker 7.49, set the K.
   **This is the K rule's first real test** — wk6 was bye-forced, #42 §3c pre-registered
   wk7. Write the kill condition *before* Sunday.
3. **Write `data/weekly/2026_week07_decisions.md`.** Loop step 1, not yet started.
   Pre-register: K-rule test, Hockenson `Q`, Odunze hold, Bates add.
4. **Thu 8:15pm:** Odunze locks. Confirm lineup unchanged.
5. **Sun 9:30am:** export pull — **both lineups** and the stream-detector snapshot.
6. **Sun 11:30am:** inactive report, Hockenson.

---

## 7. Open, carried. None of it is week 7's work.

1. **Push. Still no PR, 31+ ahead of `origin/main`.** Oldest carried item, now older.
2. Etienne IR reactivation — still NO, unexamined since #34.
3. Yahoo API application still not submitted
   (`https://sports.yahoo.com/developer/access/`). **Do not re-run the probes.**
4. Pierce (PHI RB) unowned-and-watched — 86% snaps, 11.0 opp/g wks 4-6, still conditional
   on Barkley (`Q`). Rejected again: RB is our deepest room and the spot went to Bates.

---

## 8. Environment. Deltas from #42 §8 only.

- **Byes recomputed from `load_schedules(2026)`**, all rostered teams: LA 11, KC 5, BAL 13,
  DAL 14, MIA 6, TEN 9, CLE 11, CHI 10, MIN 6, JAX 7, NO 8. **Week 11 still the only
  zero-slack week** (LA + CLE) — 9 legal bodies for 9 slots. **Chiefs DEF is the wk11
  DEF; do not drop it.**
- **The six `*_actual_*` position exports reconstruct all ten rosters cleanly** via
  `Roster Status`. This is now the sanctioned path, not `rosterchanges_league_team`.
- DEF export still has **no `Player ID`** — key on `Team`.
- Header PUA strip is required on **every** export, not just week 3 format.
- `git commit -F <file>` still required; apostrophes break the heredoc form.

**n = 7. Fit nothing.**

---

## 9. Suggested skills

| skill | when |
|---|---|
| **`caveman`** | Repo rule — all docs this style. Applied here |
| **`handoff`** | End of next session. **Write to `docs/handoff/`, NOT the OS temp dir** — the skill defaults to temp; nine docs lived in `/tmp` until a macOS purge nearly lost them |
| `diagnose` | Only if a harness breaks. The weekly loop is not a debugging task |

**Do not reach for `tdd`, `improve-codebase-architecture`, or `to-issues`.** In-season
work is a decision log, not a build. The draft engine is done.
