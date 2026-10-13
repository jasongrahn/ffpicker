# Handoff #39 — Week 5 retro DONE. Spread tiebreak killed. Next job: week 6, and wk7 has zero DEF.

Written 2026-10-13 Tue. Branch `week3-gameday`, HEAD was `c37aa58` at session start.
Prior: `docs/handoff/ffdraft-handoff-20261013-31-WEEK5-RETRO-PREP.md` (#38) — prep only,
now spent. Index: `docs/handoff/README.md`.

**Week 5 retro is complete and committed to files. Do not redo it.** Authority is
`data/weekly/2026_week05_decisions.md` §R0-R7. This doc is the pointer plus week 6 prep.

---

## 0. What shipped. Read the files, not a summary of them.

| path | what |
|---|---|
| `data/weekly/2026_week05_decisions.md` | `# RETRO` block at **end of file**, §R0-R7. Nothing above `## Retro` touched |
| `data/weekly/2026_week05_myteam.csv` | **new.** 16 rows, 11 fields, column count verified |
| `data/weekly/2026_week05_opponent.csv` | **new.** 15 rows, `slot = UNK` — see §2 |
| `data/weekly/README.md` | wk5 Cases row + Week 5 notes |
| `CLAUDE.md:355` | spread tiebreak **RETIRED**; 3 new convention bullets |
| `dev/weekly/spread_tiebreak_leaguewide.R` | **new.** The test that killed it. Rerunnable, verified clean |

**Result: W, barely. Record 3-2.** Us **107.02**, regret **23.30**, split **12% ours /
88% projection**. Cumulative deviation regret **3.50 over 5 wks (0.70/wk)**, up from 0.80
over 4 — the entire rise is one deviation (Boston over Gordon II, **-2.70**).

Uncommitted. All six paths above are `M` or `??`. **Commit before touching week 6.**

---

## 1. THE RESULT THAT MATTERS: spread tiebreak dead, killed properly.

`CLAUDE.md:355` rewritten. **Inside a ~5% gap nothing arbitrates — start the higher raw
Yahoo projection and stop.** Not the spread. Not usage either.

Method, because it is the reusable part: the old evidence was **5** reordered pairs on our
roster. Rebuilt **all 10 rosters** from the `Roster Status` column of the week-4/5 position
***actual*** exports (191 rostered RB/WR/TE player-weeks), paired every within-5%
RB/WR/TE combination, scored raw vs spread-adjusted ordering against actuals. **Only
discordant pairs carry information** — pairs where the rule changes the pick.

| scope | pairs within 5% | discordant | spread right | 95% CI | p |
|---|---|---|---|---|---|
| 10 rosters, wks 4-5 | 75 | 17 (22.7%) | 6 (35.3%) | [0.142, 0.617] | 0.33 |
| pool-wide | 1,497 | 240 (16.0%) | 114 (47.5%) | [0.410, 0.540] | 0.48 |
| pool-wide, excl. actual == 0 | — | **215** | **105 (48.8%)** | **[0.420, 0.557]** | 0.79 |

**-0.488 pts/decision**, CI [-1.77, +0.80]. No favouredness bucket beats chance. CI
**excludes accuracy above 55.7%**.

**The double-count theory died in the other direction.** Pearson(favouredness, Yahoo proj
/ own season ppg) at **n = 190** (was 39) -> **r = -0.036, p = 0.62**. #37's **+0.129 at
n=39 was noise**. So Yahoo really does not price the spread *and* adding it still loses.
**#37's premise was right and its conclusion was still wrong** — orthogonal information is
not automatically usable information. New failure mode; worth remembering as its own thing.

Cause is arithmetic: 0.00799 x 7 = **5.6%, ~0.6 pts**, against ~8-9 pts of variance
between two actuals inside a 5% band. **A 0.6-pt edge cannot arbitrate a 9-pt coin flip
at the pair level**, however real in the mean.

**The slope SURVIVES** (RB +0.00799/pt, p = 0.0109, n = 779). Use it to describe an RB's
expected week; never to pick between two players. Why it does not transfer: the slope was
measured on points **relative to own season average**, and season ppg is our *worst*
non-trivial baseline (MAE 7.32 vs Yahoo 4.29). **A multiplier calibrated against a weak
baseline does not transfer onto a strong one.**

**NOT a kill of the slope:** the RB coef in the n=190 check came back -0.0060 at p = 0.48.
**Noise, not a sign flip.** §7's condition still stands — `mult_measure.R` on 2026
relative-to-own-average data, season end.

Third rule reversal in two weeks, and **the first retired by a powered test rather than by
reasoning.** The pattern across all three: a rule adopted on a correct-sounding argument,
then killed when someone finally counted. Count first.

---

## 2. Opponent total is PERMANENTLY unrecoverable. Structural, learn from it.

**Yahoo's export has no started/bench flag.** Nothing in the data says who was started.
Best possible is a bound: 84 legal lineups after dropping D. Smith (10-11 proj 0.00, ruled
out) and Walker (KC bye); **47 of 84 lose to 107.02**. Closest plausible loss **105.74**
(Prescott, Taylor+Harvey, Washington+Burden, Likely TE, Deebo FLEX, Fairbairn, Steelers).
Their **projection-optimal** lineup scores only **95.64** — it benches Likely's 26.90.

`2026_week05_opponent.csv` ships `slot = UNK` for all 15. **Do not back-fill by guess.**
`data/weekly/README.md` carries `opp` as a range for wk5.

**Therefore loop step 2 — freeze BOTH lineups pre-kickoff — is load-bearing, not
bookkeeping.** Skipping it in week 5 cost that number forever. Do not skip it in week 6.

Also: week-5 `Roster Status` is **post-week** ownership, so a late add/drop can mis-assign
a fringe row. Noted in the retro.

---

## 3. WEEK 6 PREP. Byes derived from `load_schedules(2026)`, not from Yahoo's `Bye` column.

Per `CLAUDE.md`, byes = `setdiff(all_weeks, weeks_played)`. **Need before candidates** —
depth table first, wire second.

### 3a. Roster, 15 + Etienne on IR

```
DEF Jaguars JAX  bye 7        K  Butker KC bye 5    Bates DET bye 6
QB  Mahomes KC   bye 5        QB Stafford LA bye 11
RB  Gordon II MIA bye 6       RB Henry BAL bye 13   Williams DAL bye 14
TE  Hockenson MIN bye 6       TE Higbee LA  bye 11
WR  Tate TEN bye 9   Sutton DEN 10   Odunze CHI 10   Adams LA 11   Boston CLE 11
IR  Etienne NO bye 8
```

### 3b. Bodies per slot, wks 6-17 (IR excluded). Need QB1 RB2 WR2 TE1 FLEX1 K1 DEF1.

```
     w6 w7 w8 w9 w10 w11 w12 w13 w14 w15 w16 w17
QB    2  2  2  2   2   1   2   2   2   2   2   2
RB    2  3  3  3   3   3   3   2   2   3   3   3
WR    5  5  5  4   3   3   5   5   5   5   5   5
TE    1  2  2  2   2   1   2   2   2   2   2   2
K     1  2  2  2   2   2   2   2   2   2   2   2
DEF   1  0  1  1   1   1   1   1   1   1   1   1
```

**Exactly one unfillable slot in the rest of the season: `wk7 DEF = 0`.**

### 3c. Two corrections to #37 and #38's open lists. Both were right when written.

1. **"wk13 zero DEF" is GONE and replaced by wk7.** That worry assumed the Ravens
   (bye 13). The Bengals claim failed; we hold the **Jaguars, bye 7**. **The DEF hole is
   now week 7, one week out, not week 13.**
2. **"wk11 WR1 and WR2 are not covered" is FALSE now.** Wk11 leaves Tate / Sutton /
   Odunze — **exactly 3 WRs for WR1/WR2/FLEX**, and Mahomes covers QB, Hockenson covers
   TE. Wk11 is **fillable with zero slack**, not a hole. Same for wk10 (3 WRs).

### 3d. Week 6: every slot fillable, zero slack at RB / TE / K / DEF.

Off: **Bates** (DET), **Hockenson** (MIN), **Gordon II** (MIA).

Forced lineup: QB Stafford | RB **Henry + Williams** (only 2) | WR 2 of 5 | TE **Higbee**
(only 1) | FLEX from WR | K **Butker** (only 1) | DEF **Jaguars** (only 1). **Any injury
to Henry, Williams, Higbee or Butker forces a claim.** #37's "week 6 fully pre-covered"
holds — Butker held for exactly this.

### 3e. The week-6 claim should buy a DEF that covers wk7, not a WR.

Lines were live for both weeks at session end. **Re-pull — a line is a snapshot, not a
fact.** Rank on **opponent implied total alone** (rule validated, `CLAUDE.md`).

```
wk6 DEF, lowest opp implied : KC 17.00 | NE 18.00 | BAL 18.50 | IND 18.75 | SEA/PIT 19.00
                              ... JAX 19.75 = rank 8 of 28
wk7 DEF, lowest opp implied : NYJ 17.00 | HOU 17.25 | CLE 18.00 | MIN 19.00 | TEN 19.50
wk7 K,  highest own implied : LA 27.5 | DET 27.5 | SF 27.0 | BAL 27.0
```

One DEF roster spot, so a wk6 claim means a drop. **Ideal is one claim covering wk6 and
wk7** — check which top-ranked wk7 defense is also strong in wk6 against re-pulled lines.
Holding the Jaguars through wk6 at rank 8 is defensible; **going into wk7 with them is
not, their bye is wk7.**

**The drop, per §4's pre-registration: Sutton or Odunze, whichever has the lower snap
share.** Snap % wks 3-5:

```
Odunze 85 / 89 / 99   (targets 6/7/9, rising)      -> KEEP
Sutton 87 / 73 / 81   (opportunities 7/6/3, falling) -> DROP
Boston 89 / 95 / 91   Tate 88 / 84 / 76   Adams 83 / 95 / 73
```

**-> Sutton is the drop.** Snap share and target trend, never ppg (`CLAUDE.md`).

**Tension to record, not resolve silently: dropping Sutton truncates method test T2**
(Raymond outscores Sutton wks 5-7 -> the new drop rule is wrong) at **1 of 3**. T2 is the
only test where a rule changed *because* of a measurement and is now out-of-sample, so it
matters more than the others. Dropping him ends it inconclusively. Decide deliberately and
write the choice down either way.

### 3f. Live kill conditions going into week 6

| # | condition | state |
|---|---|---|
| W3 | Tate < 6 tgt in **two consecutive** wks | **ARMED.** wk5 = 5. **< 6 in wk6 -> Tate is the drop** |
| W2 | Gordon II < 10 opp in two consecutive wks | **MIA bye wk6 — cannot be scored.** Do not count a bye as a miss |
| D9 | Boston < Sutton, wks 4-8 | 3 of 5, no strike. Moot if Sutton dropped |
| T2 | Raymond > Sutton wks 5-7 | 1 of 3. See §3e |
| K | own implied total hold rule | **wk6 bye-forced AGAIN (Bates DET).** Still untestable. **First real test wk7** — do not score wk6 as a pass |

### 3g. UNEXPLAINED, check before week 7: Hockenson's snap share collapsed to 3%.

Snap % wks 3-5: **85 / 83 / 3**. One opportunity. **No injury row in
`load_injuries(2026)` for week 5.** Not explained by the data we have. He is on bye in
wk6, so it costs nothing this week. **Check the wk6 `injuries` and `gamedaycalls` exports.**
If the role is gone, the TE room is **Higbee only**, and **wk11 (Higbee bye) becomes a real
hole** — which §3c just cleared on the assumption Hockenson is fine.

Also from the retro: his claim was **shaky and flagged as such** (§4 pre-registered "only
if he clears 8 opportunities again"; he got 1), while the decision to *start* him over
Higbee was **correct** on the projection (7.18 vs 4.70). Do not collapse those verdicts.

### 3h. Not derivable from the repo. Ask the user.

- **Week 6 opponent.** Unknown. Needed for the h2h section of the decision log.
- Whether the wk6 claim was already submitted. **Ask, do not assume** — #36 made this
  mistake.

---

## 4. Standing rules confirmed this week. Do not re-litigate.

- **DST streaming HELD league-wide in wk5**: n=30, opp implied vs DST pts **r = -0.334,
  p = 0.071**, Spearman -0.346 — same sign and size as the 4-wk validation (-0.275).
  8 lowest opp-implied averaged **9.00** vs league mean 6.47, **+2.53 edge**. Our Jaguars
  were the rule's **#2** and returned **2.00**; the rule's #1 (HOU) returned 15.
  **Decision right, outcome bad — the 0.39-sd edge behaving exactly as predicted. Do not
  touch the rule after a bad week.**
- **Lineup layer at its ceiling.** 88% of wk5 regret was projection error. Spend the week
  on the wire and the two streaming slots.
- **Three new silent traps now in `CLAUDE.md`:** (a) no `rosterchanges_*` file is a roster
  snapshot — but the `*_actual_*` position exports carry owners in `Roster Status`, which
  is how all ten rosters got rebuilt; (b) **DEF naming flips city -> nickname between
  vintages inside one week** (`Jacksonville|Jax|6.90` -> `Jaguars|Jax|2.00`), and the
  projection file emits `New York` **twice** (NYJ and NYG) so the name is not unique even
  within one file — join on `Team` abbrev, `stopifnot()` the map; (c) no started/bench flag.

---

## 5. Open, carried. None of it is week 6's work.

1. **Push.** Still no PR. 24+ ahead of `origin/main`, plus this session's six uncommitted
   paths.
2. **Etienne IR reactivation** — still NO, bye 8, unexamined since #34.
3. Yahoo API access application **still not submitted**
   (`https://sports.yahoo.com/developer/access/`). Manual paste remains the path.
   **Do not re-run the probes**; `CLAUDE.md` has all twelve.

---

## 6. Environment, unchanged from #38 §8

- **`readr` not installed.** `read.csv(..., check.names = FALSE)`.
- **`devtools` missing**, `load_all()` fails. `source()` the `R/*.R` files you need.
- **`rtk` strips timestamps from `ls -l`.** Use `stat -f "%Sm %N" -t "%Y-%m-%d %H:%M"`.
- Yahoo headers carry **invisible private-use-area characters** — a bracket lookup on
  `"Fantasy Fan Pts"` returns **NULL rather than erroring**. Strip with
  `gsub("[\\p{Co}]", "", names(d), perl = TRUE)`.
- `load_config("scoring")`. There is no `load_scoring_config()`.

---

## 7. Suggested skills

- **`/caveman`** — repo rule. This doc is. The wk6 decision log and any `CLAUDE.md` edit
  should be.
- **`/handoff`** — end of the week-6 session, as **#40, file prefix `-33-`**. Skill writes
  to temp by default; **move it into `docs/handoff/` and add a README row** — repo rule the
  skill does not know. **File prefix and README row number differ by seven** (this doc is
  `-32-`, README row 39).
- **Skip `/diagnose`, `/tdd`, `/code-review`.** Week 6 is analysis on live data. A
  `dev/weekly/*.R` harness written for it is throwaway and gets referenced from the
  decision doc, not tested.
- **Do not spawn subagents.** `CLAUDE.md` and the session rules both say so.

**n = 5. Fit nothing.**
