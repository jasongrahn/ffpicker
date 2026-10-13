# Handoff #40 — Week 6 scaffold committed. Waiting on Wed 10-14 waivers. DEF row blank.

Written 2026-10-13 Tue. Branch `week3-gameday`, HEAD `f81c554`.
Prior: `docs/handoff/ffdraft-handoff-20261013-32-WEEK5-RETRO-DONE.md` (#39).
Index: `docs/handoff/README.md`.

**Authority for week 6 is `data/weekly/2026_week06_decisions.md` (229 lines, committed).**
This doc is the pointer plus what is still open. Do not re-derive §W1 or §H1 — both were
argued and recorded.

---

## 0. State. One blank in the whole week.

Record **3-2, 5th**. Opponent **Owl Out Blitz — Nicole, 4-1-0, 1st**.
Yahoo at scaffold time: us **106.78**, them **107.83**, underdog **49%**.

| thing | state |
|---|---|
| `data/weekly/2026_week06_decisions.md` | committed `f81c554`. §2 DEF row = `<PENDING WAIVER>` |
| `_opponent.csv` | **WRITTEN 10-13**, 16 rows, starters sum **107.83** = Yahoo exactly. `proj_gameday` **BLANK** |
| `_myteam.csv` | **NOT WRITTEN.** Blocked on the DEF row |
| waivers | KC + CLE claims in. Process **Wed 2026-10-14** |
| freeze deadline | **Sun 10-18 9:30am**, JAX London kickoff |

### !! REFRESH `_opponent.csv` BY THU 2026-10-16 AFTERNOON !!

`proj_gameday` and `proj_gameday_src` are **blank in all 16 rows**. Fill them from the
Thursday Yahoo matchup page. Two reasons this is not optional:

1. Their lineup is **not final**. Caleb Williams (18.88) and C.J. Stroud (16.80) both sit
   behind Bryce Young (16.76) on their bench — a QB swap gains them ~2 pts, and their
   **DEF slot is dead** (Vikings on bye, 0.00, no backup DEF rostered). Both are likely
   to move. The 107.83 captured here is a **floor-ish snapshot, not their final number**.
2. Week 5's opponent total was lost permanently because this step was skipped. The export
   has **no started/bench flag**, so starters are only recoverable *before* kickoff.

A second look **Sun 10-18 before 9:30am** is free and costs nothing. Take it.

**Two anomalies in the file, verify on refresh:**
- `M. Evans, WR, SF` — read off the screenshot as San Francisco (Mon 8:15 vs Was, which
  is SF's game). Mike Evans is normally **TB**. Either a mis-read or a player this
  session could not identify. **Confirm the name and team.**
- **16 rows = 15 roster + 1 IR.** Which of the 7 bench rows is the IR slot is **not
  determinable** from the matchup page. All 7 are coded `BN`.

---

## 1. Waiver plan. Pre-registered, four branches. Do not re-litigate.

Roster 14 after the Sutton drop. Priority **10 of 10** -> rolling list, no FAAB, a win
sends you to the bottom. Already bottom -> **claims are priority-free this week.** That
is why two went in.

```
claim 1  KC DEF   no drop       wk6 opp implied 17.00  (best in NFL)
claim 2  CLE DEF  drop Jaguars  wk7 opp implied 18.00  (JAX bye is wk7)
```

| branch | consequence |
|---|---|
| both land | KC wk6, CLE wk7. Both weeks solved. Roster 15 |
| KC only | keep JAX, start KC wk6, re-claim wk7 DEF Wed 10-21 |
| CLE only | start CLE wk6 at 23.00 vs JAX 19.75. **~-1.2 pts.** Accepted |
| neither | start JAX (19.75, rank 8 of 28), re-claim for wk7 |

**No available DEF is good in both weeks.** Best two-week average is KC at 20.25, which
is just KC excellent in wk6 and mediocre in wk7 (SEA 23.50). Hence two defenses.

Owned, unavailable: SEA PIT DEN HOU LAR MIN CIN CHI NYG PHI.

### 1a. "JAX is 4-1, HOU is 1-4" — raised, tested, records point the other way.

HOU scored **31/6/17/30/26 = 22.0 ppg**. Lose close games; offense not soft.
LAC (KC's opponent) scored **14/14/16/23/17 = 16.8 ppg**. Vegas priced this — it *is*
19.75 vs 17.00. Layering record on implied total = #33 one-source-twice; both prior
refinement attempts failed (opponent-quality buckets p=0.291, game total p=0.200).

**Size of the whole question, measured 10-13.** DST points-allowed tier regressed on
opponent implied total, 2026 wks 1-5, **n=158**: slope **-0.372 pts per +1 implied,
p < 0.0001**.

```
KC 17.00 vs JAX 19.75   ->  +1.02 pts
CLE 23.00 vs JAX 19.75  ->  -1.21 pts in the bad branch
```

**The wk6 DEF call is worth ~1 point.** Real reason to let JAX go is not the 2.75 of
implied — **if KC lands, JAX can never start again** (worse wk6, bye wk7). Dead roster
spot. KC-only was offered and **declined**; recorded as a preference call, not a measured
one.

---

## 2. Two §3g-class questions CLOSED this session.

### 2a. Hockenson's 3% snap share = **CONCUSSION**. Not role loss.

`docs/uploads/week_5_data/yahoo_week5_injuries_2026-10-13.csv` -> `T.J. Hockenson, Min,
TE, Q, Concussion`. #39 §3g feared a vanished role. It is a head injury. Snaps were
**85/83** before it.

**Cannot be IR'd.** Yahoo's IR slot takes `IR` `IR-R` `PUP` `NFI` `O`. He is `Q` ->
rejected. Second IR spot is free (Travis Etienne holds the other) and unusable for him.

**HELD**, in `CLAUDE.md`'s required order: (1) 1 of 2 TEs, Higbee bye **wk11**, dropping
him makes wk11 TE = 0 — the hole #39 §3c cleared *assuming he is fine*; (2) MIN bye wk6,
costs nothing now; (3) **no named add** for the freed spot. "Get him off the list" is
candidate-first, which is the failure mode the rule exists to stop.

**Decision deferred to wk7.** New kill condition **H1**: clears protocol by wk7 y/n.

### 2b. Our own numbers vs Yahoo — checked across the whole roster, overrode nothing.

Asked directly. Answer is no, and it is measured (`dev/weekly/proj_benchmark.R`, Yahoo MAE
**4.29** vs our best 6.71). Divergences logged for the retro, acted on **zero**:

| player | Yahoo | our read |
|---|---|---|
| **Higbee** | **5.74** | ARI **4th-softest to TE**; last 3 games ≈ 16.2/9.2/10.8 half-PPR. **Low by 4-6** |
| J.Williams | 14.59 | **GB 2nd-softest to RB** (26.4 fpa/g), total 52.5 |
| Stafford | 22.37 | LAR implied **32.5, highest in NFL this week**; 51/55/54 attempts last 3 |
| Henry | 15.94 | CLE **27th of 32** to RBs — hard draw, already priced |

All four are **forced starts**. Lineup had exactly one free choice all week.

---

## 3. Lineup. Forced except 3-of-4 WRs. The one hold is tested.

Byes off: **Bates** (DET K), **Hockenson** (MIN TE), **Gordon II** (MIA RB).
Forced: QB Stafford | RB Henry + Williams | TE Higbee | K Butker | DEF pending.

```
Adams   14.22  START    LAR implied 32.50, ARI 4th-softest to WR
Tate     9.87  START    TEN implied 18.75 (3rd-lowest), IND 15th to WR
Boston   9.04  FLEX     CLE implied 18.50, BAL 11th to WR
Odunze   8.64  BENCH    CHI implied 26.25, ATL 8th to WR
```

**Odunze over Boston considered and REJECTED.** Every tool favours Odunze — targets
**3/4/6/7/9** monotonic, snaps **85/89/99**, 101 air yards wk5, softer D, team implied
**+7.75**. Rejected because the gap is **4.6%**, inside the band Monday's 215-pair test
retired (CI excluded accuracy above 55.7%). Start the higher raw Yahoo projection, stop.
**A hold with a recorded test, not an unconsidered hold.**

**Game script as description only** (slope lives, tiebreak dead):
Henry BAL fav 4.5 -> **1.036x** -> ~16.5. Williams DAL dog 1.5 -> **0.988x** -> ~14.4.
WR and QB get 1.0.

---

## 4. Kill conditions live. Score every one in the retro.

| # | condition | state |
|---|---|---|
| **W3** | Tate < 6 tgt in **two consecutive** wks | **ARMED.** wk5 = 5. **< 6 in wk6 -> Tate is the drop.** Draws IND, 15th to WR, slate's 3rd-lowest implied |
| **H1** | Hockenson clears protocol by wk7 | **NEW.** Fail -> TE room is Higbee only -> wk11 is a real hole, revisit the drop |
| W1/W2 | DEF claims land as planned | **NEW.** Score which §1 branch fired |
| W2 | Gordon II < 10 opp, two consecutive | **MIA bye — NOT SCORABLE.** A bye is not a miss |
| K | own implied total hold rule | **Bye-forced AGAIN** (Bates DET). **Do not score wk6 as a pass.** First real test wk7 |
| D9 / T2 | — | **MOOT / ENDED.** Sutton dropped; T2 truncated at 1 of 3 |

---

## 5. Do next, in order.

1. **Wed 10-14, after waivers:** fill §2's `<PENDING WAIVER>` DEF row, mark which §1
   branch fired.
2. **Same sitting:** write `data/weekly/2026_week06_myteam.csv` (blocked only on the
   DEF row). `_opponent.csv` already exists.
2b. **THU 10-16 AFTERNOON — REFRESH `_opponent.csv`.** Fill `proj_gameday` in all 16
   rows, confirm `M. Evans / SF`, and re-check their QB and DEF slots, which are the two
   most likely to move. See §0.
3. **Before Sun 9:30am:** freeze. Nothing below `## Retro` edited after.
4. **Monday:** append `## Retro`, score all six conditions, compute
   `regret = best legal lineup - started` into `data/weekly/README.md`.

---

## 6. Open, carried. None is week 6's work.

1. **Push.** Still no PR, 25+ ahead of `origin/main`.
2. Etienne IR reactivation — still NO, bye 8, unexamined since #34.
3. Yahoo API application still not submitted (`https://sports.yahoo.com/developer/access/`).
   **Do not re-run the probes.**

---

## 7. Environment, unchanged from #39 §6

`readr` missing -> `read.csv(..., check.names = FALSE)`. `devtools` missing ->
`source()` the `R/*.R` files. `rtk` strips timestamps from `ls -l`. Yahoo headers carry
invisible private-use-area chars -> `gsub("[\\p{Co}]", "", names(d), perl = TRUE)`; a
bracket lookup returns **NULL rather than erroring**. `load_team_stats()` **does not take
`stat_type=`** — new this session. `load_config("scoring")`, not `load_scoring_config()`.

**n = 5. Fit nothing.**
