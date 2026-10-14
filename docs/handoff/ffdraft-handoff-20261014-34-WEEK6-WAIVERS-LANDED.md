# Handoff #41 — Both DEF claims landed. Week 6 lineup set. Two blanks, both due Thu 10-16.

Written 2026-10-14 Wed. Branch `week3-gameday`, HEAD was `9633ad5` at session start.
Prior: `docs/handoff/ffdraft-handoff-20261013-33-WEEK6-SCAFFOLD.md` (#40).
Index: `docs/handoff/README.md`.

**Authority for week 6 is `data/weekly/2026_week06_decisions.md`.** Do not re-derive §W1,
§H1 or §2a — all three were argued, measured and recorded. This doc is the pointer plus
what is still open.

---

## 0. State. Best branch fired. Record 3-2, 5th. Opponent Owl Out Blitz (4-1, 1st).

**BOTH WAIVER CLAIMS LANDED 2026-10-14.** Roster 15, Jaguars gone, zero priority spent
(10 of 10 on a rolling no-FAAB list — already bottom, so a win cost nothing).

```
QB  Stafford LAR 11   Mahomes KC 5
RB  Henry BAL 13      Williams DAL 14    Gordon II MIA 6
WR  Adams LAR 11      Tate TEN 9         Odunze CHI 10    Boston CLE 11
TE  Higbee LAR 11     Hockenson MIN 6  (concussion, Q)
K   Butker KC 5       Bates DET 6
DEF Chiefs KC 10      Browns CLE 9
IR  Etienne NO 8
```

**The `wk7 DEF = 0` hole — the only unfillable slot left all season per #39 §3b — is
CLOSED.** Browns cover wk7 at opponent implied 18.00.

| file | state |
|---|---|
| `data/weekly/2026_week06_decisions.md` | §W1 result + §2 lineup recorded. **2 `____` DEF proj blanks** |
| `data/weekly/2026_week06_myteam.csv` | **WRITTEN.** 16 rows. Starters **100.18 + KC DEF** |
| `data/weekly/2026_week06_opponent.csv` | **WRITTEN 10-13.** 16 rows, starters **107.83** = Yahoo exactly |

---

## 1. !! TWO THINGS DUE THU 2026-10-16 AFTERNOON !!

Both csvs have **`proj_gameday` blank in every row**. That column is the point of the
freeze — it is the projection the decision was actually made against.

1. **Fill `proj_gameday` in both csvs** from the Thursday Yahoo matchup page, and fill
   the **two `____` DEF proj values** in `2026_week06_decisions.md` §2 (Chiefs starting,
   Browns benched). Yahoo had no DEF number for either at claim time.
2. **Verify `M. Evans, WR, SF`** in `_opponent.csv`. Read off the matchup page as San
   Francisco (Mon 8:15 vs Was is SF's game) but **Mike Evans is normally TB**. Either a
   mis-read or an unidentified player.

**A second look Sun 10-18 before 9:30am is free.** The Chiefs' kickoff is Sun 4:25, but
**the binding freeze deadline is the earliest kickoff of any legal replacement** — with
the Jaguars gone there is no 9:30am game, so Sun 1:00pm now binds (Tate, Boston, Odunze).
Confirm this before relying on it.

### 1a. Their 107.83 is a floor, not their number.

Captured 10-13 before they finished setting a lineup. Two slots were obviously open:

- **QB:** Caleb Williams **18.88** and C.J. Stroud **16.80** both benched behind Bryce
  Young **16.76**. ~+2 available.
- **DEF:** Vikings on **bye, 0.00, no backup DEF rostered**. ~+5-8 available.

Realistic final is nearer **115**. Yahoo's "underdog 49%" was computed against an
unfinished lineup — do not read it as the real line.

**Also unknown and not determinable:** `_opponent.csv` has 16 rows = 15 roster + 1 IR,
and the matchup page gives no way to say which bench row is the IR slot. All 7 coded `BN`.

---

## 2. Lineup. Forced except 3-of-4 WRs. The one hold is tested, not assumed.

Byes off: **Bates** (DET K), **Hockenson** (MIN TE), **Gordon II** (MIA RB).

```
QB   Stafford   LAR vs ARI   22.37      BN  Mahomes    18.37
RB   Henry      BAL @ CLE    15.94      BN  Odunze      8.64
RB   J.Williams DAL @ GB     14.59      BN  Browns DEF  ____
WR   Adams      LAR vs ARI   14.22      BN  Hockenson   0.00  concussion
WR   Tate       TEN @ IND     9.87      BN  Gordon II   0.00  bye
TE   Higbee     LAR vs ARI    5.74      BN  Bates       0.00  bye
FLX  Boston     CLE vs BAL    9.04      IR  Etienne     0.00
K    Butker     KC vs LAC     8.41
DEF  Chiefs     KC vs LAC    ____       opp implied 17.00, best in NFL
```

**Odunze over Boston considered and REJECTED at a 4.6% gap.** Every tool favours Odunze —
targets **3/4/6/7/9** monotonic, snaps **85/89/99**, 101 air yards wk5, ATL 8th-softest to
WR, team implied **+7.75**. Rejected because 4.6% is inside the band Monday's 215-pair test
retired (CI excluded accuracy above 55.7%). Start the higher raw Yahoo projection, stop.
**A hold with a recorded test.**

**Game script as description only** (slope lives, tiebreak dead): Henry BAL fav 4.5 ->
**1.036x** -> ~16.5; Williams DAL dog 1.5 -> **0.988x** -> ~14.4. WR and QB get 1.0.

---

## 3. Settled this week. Do not re-open.

### 3a. Hockenson's 3% snap share = **CONCUSSION**, not role loss. #39 §3g CLOSED.

`yahoo_week5_injuries_2026-10-13.csv` -> `T.J. Hockenson, Min, TE, Q, Concussion`. Snaps
were **85/83** before it. **Cannot be IR'd** — Yahoo's IR slot takes `IR` `IR-R` `PUP`
`NFI` `O`, he is `Q`. **HELD**, need-before-candidates: 1 of 2 TEs with Higbee's bye in
**wk11**; MIN bye wk6 so he costs nothing now; **no named add** for the freed spot.
Decision deferred to wk7 as kill condition **H1**.

### 3b. "JAX is 4-1, HOU is 1-4" — raised, and the records point the OTHER way.

HOU scored **31/6/17/30/26 = 22.0 ppg**; they lose close, offense is fine. LAC (KC's
opponent) scored **14/14/16/23/17 = 16.8**. Vegas priced it — that *is* 19.75 vs 17.00.
Layering record on implied total is #33 one-source-twice; both prior refinements failed
(opponent-quality buckets p=0.291, game total p=0.200).

**Sized it.** DST points-allowed tier regressed on opponent implied, 2026 wks 1-5,
**n=158**: slope **-0.372 pts per +1 implied, p < 0.0001**. KC over JAX = **+1.02**; the
bad branch would have cost **-1.21**. **The whole wk6 DEF call was worth ~1 point.** The
real reason to drop JAX was that once KC landed he could never start again (worse wk6,
bye wk7) — a dead roster spot.

### 3c. Asked directly: do any of our features beat Yahoo? **No, and it is measured.**

`dev/weekly/proj_benchmark.R` — Yahoo MAE **4.29** vs our best alternative 6.71. Checked
the whole roster against opponent fantasy-points-allowed; logged divergences, **acted on
zero**, all four are forced starts anyway:

| player | Yahoo | our read |
|---|---|---|
| **Higbee** | **5.74** | ARI **4th-softest to TE**; last 3 games ≈ 16.2/9.2/10.8 half-PPR. **Low by 4-6** |
| J.Williams | 14.59 | **GB 2nd-softest to RB** (26.4 fpa/g), total 52.5 |
| Stafford | 22.37 | LAR implied **32.5, highest in the NFL this week**; 51/55/54 attempts last 3 |
| Henry | 15.94 | CLE **27th of 32** to RBs — hard draw, already priced |

---

## 4. Kill conditions live. Score every one in the retro.

| # | condition | state |
|---|---|---|
| **W3** | Tate < 6 tgt in **two consecutive** wks | **ARMED.** wk5 = 5. **< 6 in wk6 -> Tate is the drop.** Draws IND (15th to WR) on the slate's 3rd-lowest implied total |
| **H1** | Hockenson clears protocol by wk7 | **NEW.** Fail -> TE room is Higbee only -> **wk11 is a real hole**, revisit the drop |
| W1/W2 | which DEF branch fired | **SCORED: both landed.** Score KC's actual vs the rule |
| W2 | Gordon II < 10 opp, two consecutive | **MIA bye — NOT SCORABLE.** A bye is not a miss |
| K | own implied total hold rule | **Bye-forced AGAIN** (Bates DET). **Do not score wk6 as a pass.** First real test wk7 |
| D9 / T2 | — | **MOOT / ENDED.** Sutton dropped; T2 truncated at **1 of 3** |

**DST rule reminder:** validated league-wide, edge is **0.39 sd**, the >3 pt kill bar is
retired. **A bad KC week does not touch the rule.** Wk5 proved it — our Jaguars were the
rule's #2 and returned 2.00 while its #1 returned 15.

---

## 5. Next session, as the user framed it: collect new data, consider FA swaps.

**Order is fixed by `CLAUDE.md` — need before candidates. Do not rank the wire first.**

1. Pull the **week 6 Yahoo exports** into `docs/uploads/week_6_data/`. Reader is
   `dev/weekly/read_yahoo_week.R`. Six position files only (`_qb_` `_rb_` `_wr_` `_te_`
   `_k_` `_def_`) — `gamedaycalls` and `injuries` share the prefix, not the schema.
2. **Depth + bye table from `load_schedules(2026)`**, byes as
   `setdiff(all_weeks, weeks_played)`. Never from Yahoo's `Bye` column.
3. Only then rank the pool, on **opportunity and its week-over-week trend**, barring
   anyone under ~5 opp/g. **Not ppg** — a 280-row FA export has median ppg 1.5-2.3, so
   every body shows a fake VOR.
4. Pick the drop on **snap share and target trend** (`load_snap_counts()`), never ppg.

**Known shape of the wire going in:** Yahoo dumps every unowned player onto waivers after
Sunday and they clear Wednesday. Before the clear, priority gates everything; after it,
first-come and priority is irrelevant. **A Thu/Fri second look is free.** Any availability
filter must treat **`FA` and `W (...)` both as available** — a `^W \(` -only filter
understated the wk4 WR pool by 360.

**Open FA questions already visible:** wk11 TE depth if H1 fails; whether Tate survives
W3; and the Browns need a wk9 replacement (CLE bye 9) — not urgent, but it is the next
DEF hole after wk7.

---

## 6. Open, carried. None of it is week 6's work.

1. **Push.** Still no PR, 27+ ahead of `origin/main`.
2. Etienne IR reactivation — still NO, bye 8, unexamined since #34.
3. Yahoo API application still not submitted (`https://sports.yahoo.com/developer/access/`).
   **Do not re-run the probes**; `CLAUDE.md` has all twelve.

---

## 7. Environment, mostly unchanged from #40 §7

`readr` missing -> `read.csv(..., check.names = FALSE)`. `devtools` missing ->
`source()` the `R/*.R` files. `rtk` strips timestamps from `ls -l`. Yahoo headers carry
invisible private-use-area chars -> `gsub("[\\p{Co}]", "", names(d), perl = TRUE)`; a
bracket lookup returns **NULL rather than erroring**. **`load_team_stats()` does NOT take
`stat_type=`** — found #40. **DEF names flip city -> nickname between vintages inside one
week**, and the projection file emits `New York` twice — **join on the `Team` abbrev**.
`load_config("scoring")`, not `load_scoring_config()`.

**n = 5. Fit nothing.**
