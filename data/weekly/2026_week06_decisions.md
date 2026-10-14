# Week 6 Decisions — 2026, JGrahnasaurs (3-2, 5th)

Opened 2026-10-13 Tue. Opponent: **Owl Out Blitz — Nicole, 4-1-0, 1st in league**.
Scaffold written pre-waiver. **Freeze window: after the Wed 10-14 waiver run, before
Sun 10-18 9:30am** — no rostered player is in the Thursday game once Sutton is dropped,
so the binding deadline is the Jaguars' London kickoff (`min(kickoff of legal
replacements)`, per `CLAUDE.md`), not Sunday 1:00pm.
Nothing below the `## Retro` line is edited after freeze.

Source of record: `docs/uploads/week_5_data/*_2026-10-13.csv` (Yahoo), plus
`load_player_stats(2026)` / `load_schedules(2026)` re-pulled 10-13.
Prior: handoff #39 `docs/handoff/ffdraft-handoff-20261013-32-WEEK5-RETRO-DONE.md`.

---

## 0. Headline. Lineup is forced. The week's work was the wire.

9 starters, and only **one** slot had a real choice: 3 of 4 WRs. RB (2 bodies), TE (1),
K (1), DEF (1) were all forced by byes. Byes off: **Bates** (DET K), **Hockenson**
(MIN TE), **Gordon II** (MIA RB).

Per `CLAUDE.md` — lineup layer is at its ceiling (4-wk deviation regret 0.80, 99% of
regret is projection error). Effort went to the two streaming slots instead.

---

## 1. Roster moves.

### M0. Dropped **Courtland Sutton** outright, 10-13, no claim attached.

Pre-registered in handoff #39 §3e. Snap share and target trend, never ppg:

```
Odunze 85 / 89 / 99   targets 6/7/9  rising    -> KEEP
Sutton 87 / 73 / 81   opps    7/6/3  falling   -> DROP
Boston 89 / 95 / 91   Tate 88 / 84 / 76   Adams 83 / 95 / 73
```

**Recorded tension, not resolved silently:** this truncates method test T2 (Raymond
outscores Sutton wks 5-7 → the new drop rule is wrong) at **1 of 3**. T2 was the only
out-of-sample test of a rule that changed *because of* a measurement. Ending it
inconclusively is a real cost, taken deliberately to free a roster spot before the
Oct 14 waiver run.

Depth check after the drop — **no new hole.** WR room is Adams / Tate / Odunze / Boston.
Wk11 (Adams LAR and Boston CLE both on bye) leaves 2 WRs for WR1/WR2, and FLEX fills
from 3 healthy RBs. #39 §3b's "wk11 fillable with zero slack" still holds.

### W1. Claim **KC DEF**, no drop. W2. Claim **CLE DEF**, drop **Jaguars**.

**RESULT 2026-10-14: BOTH LANDED.** Roster 15, Jaguars gone. KC starts wk6, CLE held
for wk7. The best branch of the four fired, and it cost zero waiver priority.

Both processed **Wed 2026-10-14**. Priority **10 of 10** — a rolling list with no FAAB, and
a successful claim sends you to the bottom. We are already there, so **claims are
priority-free this week.** That is why two were submitted instead of one.

Ranked on **opponent implied total alone** (`total/2 - spread/2`), the league-wide
validated rule (n=128, r = -0.275, p = 0.0017, +1.92 pts/wk edge). Re-pulled 10-13 from
`load_schedules(2026)` — a line is a snapshot, not a fact.

```
wk6 opp implied, available   wk7 opp implied, available
KC   17.00  <- best in NFL   NYJ  17.00
NE   18.00                   CLE  18.00
BAL  18.50                   TEN  19.50
IND  18.75                   JAX  BYE  <- the hole
JAX  19.75  <- held
```

**No single available DEF is good in both weeks.** Best two-week average is KC at 20.25,
which is just KC being excellent in wk6 (17.00) and mediocre in wk7 (SEA, 23.50). So the
plan is two defenses, not one: KC for wk6, CLE for wk7.

Owned and therefore unavailable: SEA, PIT, DEN, HOU, LAR, MIN, CIN, CHI, NYG, PHI.

**Branches, pre-registered before the run:**

| outcome | lineup consequence |
|---|---|
| **both land — THIS IS WHAT FIRED, 10-14** | KC starts wk6 (17.00), CLE starts wk7 (18.00). Both weeks solved. Roster 15. **Jaguars gone** |
| KC only | keep JAX, start KC wk6, re-claim a wk7 DEF Wed 10-21 |
| CLE only | JAX gone, start CLE wk6 at 23.00 vs JAX's 19.75. **Costs ~1-2 pts.** Accepted |
| neither | start JAX wk6 (19.75, rank 8 of 28), re-claim for wk7 |

**Challenged and re-tested before the run: "JAX is 4-1, HOU is 1-4 — are we sure?"**
The records point the *opposite* way from the instinct. HOU is 1-4 but has scored
**31 / 6 / 17 / 30 / 26 = 22.0 ppg**; they lose close games, their offense is not soft.
LAC, KC's opponent, has scored **14 / 14 / 16 / 23 / 17 = 16.8 ppg**. Vegas has priced
exactly this — it is what 19.75 vs 17.00 *means*. Layering team record on top of the
implied total is #33's "one source counted twice," and the two refinements already tested
on top of implied total (opponent quality buckets p = 0.291, game total p = 0.200) both
failed.

**Size of the whole question, measured 10-13.** DST points-allowed tier regressed on
opponent implied total, 2026 wks 1-5, n = 158: slope **-0.372 pts per +1 implied**,
p < 0.0001.

```
KC  17.00 vs JAX 19.75  ->  +1.02 pts for KC
CLE 23.00 vs JAX 19.75  ->  -1.21 pts in the KC-fails-CLE-lands branch
```

**So the wk6 DEF decision is worth ~1 point.** The real reason to let JAX go is not the
2.75 of implied total — it is that **if KC lands, JAX can never start again**: worse in
wk6, bye in wk7. He would occupy a roster spot for zero possible starts.

KC-only (keep JAX as insurance, claim a wk7 DEF on 10-21) was offered and **declined**.
The downside branch costs ~1.2 pts and requires KC to fail *and* CLE to land; waiting
risks all three good wk7 defenses (NYJ 17.00, CLE 18.00, TEN 19.50) being taken. Close
enough to be a preference call, not a measured one. Recorded as such.

JAX was **not** dropped manually ahead of the run — a double failure would have left
zero defenses on Sunday.

**Kill condition (DEF, standing):** none this week. The DST rule is validated league-wide
and the >3 pt kill bar is retired for it. **A bad week does not touch the rule** — the
edge is 0.39 sd and will look wrong often. Wk5 proved it: our Jaguars were the rule's #2
and returned 2.00 while the rule's #1 returned 15. Decision right, outcome bad.

### H1. HELD **T.J. Hockenson** despite the concussion. <!-- CONFIRM BEFORE FREEZE -->

Wk5 snap share **85 / 83 / 3** is now explained: `yahoo_week5_injuries_2026-10-13.csv`
lists him `Q, Concussion`. **A head injury, not a lost role.** This closes handoff #39
§3g, which flagged the collapse as unexplained and feared role loss.

**Cannot be IR'd.** Yahoo's IR slot takes `IR`, `IR-R`, `PUP`, `NFI`, or `O`. He is `Q`,
which is rejected. The second IR spot is free (Travis Etienne holds the other) and is not
usable for him. So the only options are hold or drop.

**Held.** Reasoning, in `CLAUDE.md`'s required order — need before candidates:
1. He is **1 of 2 TEs**. Higbee's bye is **wk11**. Dropping him makes wk11 TE = 0, the
   exact hole #39 §3c cleared *on the assumption Hockenson is fine*.
2. MIN is on bye in wk6, so holding him costs **zero** this week.
3. There is **no named add** the freed spot would buy. "Get him off the list" is a
   candidate-first argument, which is the failure mode the rule exists to stop.

**Decision point deferred to wk7**, when concussion-protocol status is actually known.

---

## 2. Lineup. Started vs benched.

```
QB   Stafford   LAR vs ARI   22.37
RB   Henry      BAL @ CLE    15.94
RB   J.Williams DAL @ GB     14.59
WR   Adams      LAR vs ARI   14.22
WR   Tate       TEN @ IND     9.87
TE   Higbee     LAR vs ARI    5.74
FLX  Boston     CLE vs BAL    9.04
K    Butker     KC vs LAC     8.41
DEF  KC         KC vs LAC     7.75   <!-- filled 10-14 from position pages -->
                 total       107.93  (100.18 + KC DEF 7.75)

BN   CLE DEF    CLE vs BAL    5.91   held for wk7 (opp implied 18.00)
BN   Mahomes    KC vs LAC    18.37
BN   Odunze     CHI @ ATL     8.64
BN   Hockenson  MIN  BYE      0.00   concussion, Q
BN   Gordon II  MIA  BYE      0.00
BN   Bates      DET  BYE      0.00
IR   Etienne    NO           hamstring
```

Opponent (Owl Out Blitz) captured in `2026_week06_opponent.csv` on **10-13**, 16 rows,
starters summing **107.83 — matches Yahoo's matchup page exactly**.

**NOT FINAL. Refresh `proj_gameday` by Thu 10-16 afternoon.** Their lineup has two obvious
open slots: **Caleb Williams (18.88) and C.J. Stroud (16.80) are both benched behind
Bryce Young (16.76)**, and their **DEF slot is dead** — Vikings on bye, 0.00, no backup
DEF rostered. Expect them to gain ~2 at QB and ~5-8 at DEF. **107.83 is a snapshot, not
their final number.**

Two anomalies to verify on refresh: `M. Evans, WR, SF` (Mike Evans is normally TB; read
off the matchup page, Mon 8:15 vs Was is SF's game), and **16 rows = 15 roster + 1 IR**
with no way to tell which bench row is the IR slot — all 7 coded `BN`.
Yahoo had us **106.78 vs 107.83, underdog 49%**.

### 2a. The only live choice: 3 WRs from 4. Started Adams / Tate / Boston.

```
Adams   14.22   LAR implied 32.50 (highest on the slate), ARI 4th-softest to WR
Tate     9.87   TEN implied 18.75 (3rd-lowest), IND 15th to WR
Boston   9.04   CLE implied 18.50, BAL 11th to WR
Odunze   8.64   CHI implied 26.25, ATL 8th to WR
```

**Odunze over Boston was considered and rejected.** Everything in our toolkit favours
Odunze: targets **3/4/6/7/9** monotonic, snaps **85/89/99**, 101 air yards in wk5, softer
matchup, and a team implied total **7.75 points higher**.

Rejected because the gap is **4.6%** — inside the band where Monday's 215-pair test found
nothing arbitrates, not the spread and not usage. CI excluded accuracy above 55.7%.
`CLAUDE.md`: inside ~5%, start the higher raw Yahoo projection and stop. We did.

**This is a HOLD with a recorded test, not an unconsidered hold.**

### 2b. Our own numbers vs Yahoo's. Checked, overrode nothing.

Yahoo MAE 4.29 beats every alternative we have (`dev/weekly/proj_benchmark.R`). Divergences
logged for the retro only:

| player | Yahoo | our read | acted? |
|---|---|---|---|
| Higbee | **5.74** | ARI 4th-softest to TE; his last 3 games ≈ 16.2 / 9.2 / 10.8 half-PPR. Looks low by 4-6 | No — only TE, forced |
| J.Williams | 14.59 | **GB 2nd-softest to RB** (26.4 fpa/g), game total 52.5 | No — only 2 RBs, forced |
| Stafford | 22.37 | LAR implied **32.5, highest in NFL this week**; 51/55/54 attempts last 3 | No — Mahomes lower |
| Henry | 15.94 | CLE **27th of 32** to RBs — a hard draw Yahoo already priced | No |

**Game script as description only** (slope survives, tiebreak retired). RB multiplier
`1 + 0.00799 * favouredness`; WR and QB get 1.0:
- Henry, BAL favored 4.5 → **1.036x** → ~16.5
- Williams, DAL dog 1.5 → **0.988x** → ~14.4

---

## 3. Kill conditions live this week. Score every one in the retro.

| # | condition | state going in |
|---|---|---|
| **W3** | Tate < 6 targets in **two consecutive** weeks | **ARMED.** wk5 = 5. **< 6 in wk6 → Tate is the next drop.** He draws IND (15th to WR) on the slate's 3rd-lowest implied total |
| **W2** | Gordon II < 10 opportunities in two consecutive weeks | **MIA bye — NOT SCORABLE.** Do not count a bye as a miss |
| **D9** | Boston < Sutton, wks 4-8 | **MOOT.** Sutton dropped |
| **T2** | Raymond > Sutton, wks 5-7 | **ENDED at 1 of 3, inconclusive.** See §M0 |
| **K** | own implied total hold rule | **Bye-forced AGAIN** (Bates DET). Butker is the only K. **Do not score wk6 as a pass.** First real test is wk7 |
| **H1** | Hockenson clears protocol by wk7 | New. Fails → TE room is Higbee only → wk11 becomes a real hole, revisit the drop |
| **W1/W2** | DEF claims land as planned | New. Score which branch of §W1's table actually fired |

---

## 4. Open questions carried into the retro

1. Did KC and/or CLE land? Which §W1 branch fired, and what did the DEF actually score?
2. Tate's target count — W3 strike or reset?
3. Higbee's actual vs Yahoo's 5.74. If the gap is real and repeats, it is a **wire/role**
   signal, not a start/sit one (he is forced either way).
4. Hockenson concussion status in the wk6 `injuries` / `gamedaycalls` exports.
5. `regret = best legal lineup - started`, appended to `data/weekly/README.md`.

## 5. Wed 10-14 refresh. Both #41 §1 items closed. Two bye-week facts in #41 are WRONG.

Source: `docs/uploads/week_6_data/yahoo_week6_*_2026-10-14.csv` (position pages, **not**
matchup page -> ~0.02-1.0 lower than the 10-13 matchup capture; see `CLAUDE.md`).

### 5a. Closed.
- **DEF proj filled**: KC **7.75**, CLE **5.91**. Starter total **107.93**.
- **`proj_gameday` filled in both csvs**, 32/32 rows matched, `proj_gameday_src =
  position_pages_2026-10-14`. Sun 10-18 refresh may overwrite.
- **M. Evans WR SF VERIFIED REAL.** `Mike Evans,27535,SF,WR` in the wk6 WR export, owned
  by Owl Out Blitz. Not a mis-read. He is on SF in 2026.

### 5b. #41's bye weeks are wrong. Derived from `load_schedules(2026)`.

| team | #41 said | actual |
|---|---|---|
| **KC** | 10 | **5 — already past.** Butker + Chiefs DEF play every remaining week |
| **CLE** | 9 | **11** |
| LA (=LAR) | 11 | 11 ok |

-> **"The Browns need a wk9 replacement" is a false alarm. There are ZERO DEF holes left
all season.** KC DEF bye already passed and covers CLE's wk11.

### 5c. Week 11 is the pinch week, and it is exactly covered. H1 resolved by arithmetic.

LA bye 11 **and** CLE bye 11 -> out: Stafford, Adams, Higbee, Browns DEF, **Boston**.
Legal wk11 lineup is forced, **9 bodies for 9 slots, zero bench**:
QB Mahomes / RB Henry, J.Williams / WR Tate, Odunze / TE **Hockenson** / FLX Gordon II /
K Butker / DEF Chiefs.

**-> HOLD HOCKENSON regardless of how H1 scores.** With Higbee on bye in 11 he is the
only legal TE. Dropping him makes wk11 unfillable. H1 stops being a drop question.

### 5d. Wire: waivers already cleared. No swap justified.

RB FA 217 / W 0, WR FA 409 / W 2, TE FA 221 / W 0 -> **first-come, priority irrelevant.**

Need-before-candidates, in order: depth table (5c) shows **no hole**; every one of our 9
skill players clears the 5 opp/g bar and 7 of 9 trend **up** (wks 4-5 vs 1-3):

| ours | opp/g last2 | trend | | best available | opp/g | trend |
|---|---|---|---|---|---|---|
| Henry RB | 25.5 | +1.8 | | Dameon Pierce RB PHI | 16.0 | **1 game only** |
| J.Williams RB | 19.5 | +1.2 | | Keaton Mitchell RB LAC | 13.0 | +6 |
| Gordon II RB | 14.5 | +3.0 | | Woody Marks RB HOU | 13.0 | +3 |
| Tate WR | 8.5 | +1.8 | | Roschon Johnson RB CHI | 8.5 | +8.5 |
| Odunze WR | 8.0 | +3.7 | | Brenton Strange TE JAX | 8.0 | +4.7 |
| Adams WR | 8.0 | **-1.7** | | | | |
| Boston WR | 7.0 | +2.0 | | | | |
| Hockenson TE | 7.0 | +2.7 | | | | |
| Higbee TE | 6.0 | -0.5 | | | | |

**No add.** Pierce's 16 is one week post-signing, not a trend. Adams is our only negative
trend and still our WR1 by projection (13.33).

**The free drop, when we want a body, is `J. Bates` (K, DET).** Butker's bye (KC 5) is
past, so a second kicker is now a **dead roster spot** — the same argument that dropped
the Jaguars in §W1. Do not drop a TE, and keep both DEFs (streaming is the validated
+1.92/wk lever; a 2nd K is the same lever on far weaker evidence).

### 5e. Opponent re-read. They DROPPED Stroud. Realistic final ~112.8, not #41's 115.

15 rostered, no IR row now. `C.J. Stroud` shows `W (Oct 16)` -> they cut him.

- QB: **Caleb Williams 18.87 (Q)** vs Bryce Young 16.72. ~+2.2 if Williams is cleared.
- **DEF: Vikings 0.00, MIN on bye, no 2nd DEF, and the roster is FULL at 15.** They must
  **drop someone** to stream a DEF. #41's "+5-8 available" assumed a free spot. There
  isn't one. If they stand pat, DEF = 0.00.
- Their optimal: 18.87 + 13.31 + 10.02 + 19.04 + 15.80 + 14.43 + 13.21 (Evans FLEX) +
  8.14 + 0.00 = **112.82**. With Young instead: 110.67.

**Us 107.93 vs ~112.8 = -4.9.** Underdog, inside one WR game. Watch two things only:
whether Caleb Williams clears Q, and whether a DEF appears on their roster.

### 5f. Freeze deadline CONFIRMED Sun 10-18 1:00pm ET.

Earliest kickoff among legal replacements for any slot. No rostered player of ours has a
9:30am or Thursday game (Jaguars gone). A Thu/Fri second look is free and spends nothing.

---

## Retro

<!-- Nothing above this line is edited after freeze. Append only, after Monday night. -->
