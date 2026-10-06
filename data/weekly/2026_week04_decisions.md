# Week 4 Decisions — 2026, JGrahnasaurs (2-1)

**Opponent:** Jason's Jazzy Team (Pete), 1-2-0, 8th.
**Frozen:** 2026-10-02. Lineup locked as logged. Both lineups written at matchup-page projections (`proj_gameday`, src `matchup_2026-10-01`). Opened Tue 2026-09-29, **materially revised Tue 09-29 evening**
after the methodology correction in §00.

**Waiver state, Tue 09-29 evening:**

| claim | status |
|---|---|
| Ravens DEF in / Chiefs DEF out | **LIVE** — kept, see D2 |
| **D. Boston (WR, Cle) in / K. Gainwell (RB, TB) out** | **LIVE** — new, see D9. Gainwell already dropped. |
| ~~Stroud in / Stafford out~~ | **CANCELLED** — see D8 |
| ~~B. Allen in / Etienne out~~ | **CANCELLED** — see D1. Etienne retained. |
| **T. Etienne (RB, NO) -> IR slot** | **DONE** 10-01 — IR, hamstring. See D10. Frees a roster spot, no drop. |
| **J. Bates (K, Det) added** | **DONE** 10-01 — K2, into the slot Etienne's IR move freed. See D11. |

**Prior:** handoff #32 `docs/handoff/ffdraft-handoff-20260929-25-WEEK4-SWAPS.md`.
**Date note:** handoff #32 dated 09-29 as "Mon". 2026-09-29 is a **Tuesday**. Corrected here.

Do not edit above `## Retro`. Retro appended after Monday 2026-10-05.

---

## 00. METHODOLOGY CORRECTION. Read before trusting anything dated earlier.

**`Rankings Actual` in the Yahoo position exports is NOT realised production. It is that week's
projection restated as a rank.**

Measured 09-29 by counting rank-order violations between `Rankings Actual` and `Fantasy Fan Pts`
within each position file:

| pos | n | rank-order violations |
|---|---|---|
| QB | 140 | 2 (1.4%) |
| RB | 264 | **0** |
| WR | 465 | **0** |
| TE | 246 | **0** |
| K | 56 | **0** |
| DEF | 32 | **0** |

**0 violations in 1,203 of 1,243 players.** The two columns are the same information twice. A
player "ranked 8th on the season" is simply a player with a high projection this week.

**What this invalidated.** Three conclusions in this document were built on `Rankings Actual`
presented as independent evidence. All three were wrong, and all three are corrected below
(D1, D6, D8). Any argument of the form "the projection says X *and* the season rank agrees" was
one source counted twice.

**The correct source for realised production is `nflreadr::load_player_stats(2026)` scored through
`score_player_week()`** — the function `CLAUDE.md` records as validated 35/35 against Yahoo box
scores. That is what every number below now uses. 362 players scored, weeks 1-3, under
`config/scoring.json`.

**Standing rule from here: never cite `Rankings Actual` or `Rankings Pre-Season` as evidence of
performance.** They are projection derivatives. Use them only to read Yahoo's *opinion*, never to
check it. Only `score_player_week()` output counts as production.

---

## 0. The frame. Reversed by the correction. We are favourites, not underdogs.

The earlier version of this section had us as ~9.6-point underdogs and built a variance argument on
it. That rested on Yahoo projections. On realised production the matchup inverts.

**Skill slots only (QB/RB/RB/WR/WR/TE/FLEX). K and DST are excluded — `score_player_week()` is
per-player by design and `score_team_week()` does not exist yet.**

| lineup | by Yahoo projection | **by actual ppg, wks 1-3** |
|---|---|---|
| **JGrahnasaurs** (revised, D6 below) | 99.09 | **110.25** |
| Jason's Jazzy Team — best legal | 109.74 | **92.47** |
| Jason's Jazzy Team — **as actually set** | 89.51 | **83.96** |

**The projection had us 10.6 points behind. Production has us 17.8 points ahead of their best
legal lineup.** Same two rosters, opposite verdicts, and one of the two sources has a documented
four-week failure record on exactly this kind of ranking.

**Their lineup error is smaller than it looked.** De'Von Achane, in their starting RB2 slot, is on
IR and will score 0 — but he averaged 7.03 ppg before the injury, so he was never the 17-point hole
the projection-based read implied. Their real cost is the gap to Hubbard (16.20 ppg), about 16
points.

**A second, funnier finding: their "best legal lineup" is worse than the one they set, at QB.**
Projection-optimal starts Drake Maye (18.47 proj) over Jared Goff (18.44). By production Goff is at
**21.86 ppg** and Maye at **9.20**. They started the right quarterback for the wrong reason, and
our "they should fix it" advice would have made them worse there.

**Consequence, and it now points one way.** On the better signal we are favourites by roughly 18.
**Favourites want floor, not ceiling.** The earlier "variance helps us" argument is dead twice over
— first because it was withdrawn as unusable, now because it points the wrong way.

**Held against all of the above: n = 3 games.** `CLAUDE.md` says fit nothing on this and is right.
Production is not being treated as truth — it is being treated as *a second source that disagrees
with the first*, where the first has a recorded failure history and the second is our own validated
scoring function. That is the entire claim.

**Their only early lock: DK Metcalf, Thu 10-01 8:15**, in their starting lineup at WR2 (7.10 ppg).
Every other slot including Achane stays editable until Sunday.

---

## 1. Roster moves.

### D1. **CORRECTED.** Etienne RETAINED. Allen claim cancelled.

**Originally: drop Etienne, claim Braelon Allen. Both withdrawn 09-29 evening.**

The original argument had two legs and §00 removed both.

| | original claim | **actual production, wks 1-3** |
|---|---|---|
| T. Etienne Jr. (RB, NO) | "worth 0.00, rank 734" | **8.47 ppg — our RB3** |
| B. Allen (RB, NYJ) | "12.6 proj carries, rank 223 -> 87" | **5.07 ppg** |
| B. Hall (RB, NYJ) | "losing the job, rank 32 -> 164" | **12.50 ppg** |

**Etienne's 0.00 is one week of injury, not his value.** He out-produces Marks (6.37) and every
back we considered claiming. Dropping a functioning RB3 to clear a spot was correct only under the
belief that he was worthless, and that belief came from a projection for a week he is `O` for.

**The Allen case was the same source twice.** Projected carries and `Rankings Actual` both come
from the Yahoo projection. Against production Allen has been outscored by the man he was supposed
to be replacing, better than 2 to 1. The role change may still be real and coming — Yahoo may know
something the box scores do not yet show — but it was presented here as established and it was not.

**Confirmed separately: the league IR slot does NOT accept an `O` designation.** That answer stands;
it was checked on the roster page, not inferred. Etienne therefore occupies a bench spot, which is
the correct price for an 8.47-ppg back.

**Kill condition (D1):** Etienne misses Weeks 5 and 6 as well. A three-week absence makes the bench
spot too expensive and he becomes droppable on the next roster crunch.



### D2. DEF streamed: Chiefs -> Ravens. Method call, executed.

Rule, unchanged since Week 2: **rank DST by opponent implied total, lowest first**
(`total/2 - spread/2`). DST scoring is dominated by the points-allowed tiers in
`config/scoring.json`.

| DEF | opp | opp implied | tier | Yahoo proj |
|---|---|---|---|---|
| **Ravens** (added) | TEN | **16.00** | 14-20 = 1, upside into 7-13 = 4 | **7.58** |
| Chiefs (dropped) | LV | 21.50 | 21-27 = **0** | 6.45 |

Both signals agree. This was the strongest single result the weekly layer has produced (+9.00 in
Week 3), so it runs again without further argument.

**Concentration, flagged per the standing rule:** Ravens DEF stacks Derrick Henry — both Baltimore,
both against Tennessee, ~25 projected points in one game. Per `CLAUDE.md`, *correlation is not the
thing to avoid, paying for it is*. This concentration **gains** 1.13 projected points over the
alternative rather than costing any, so it is the acceptable kind. Flagged, not avoided.

**Kill condition (D2):** Ravens DEF scores under Chiefs DEF by more than 3.00. Second consecutive
miss on a streaming rule retires the rule (see D3).

---


## 2. Lineup. Nine slots.

| slot | player | pos | NFL | proj | kickoff ET |
|---|---|---|---|---|---|
| QB | P. Mahomes | QB | KC | 19.98 | Sun 4:25 |
| RB | D. Henry | RB | Bal | 17.68 | Sun 1:00 |
| RB | J. Williams | RB | Dal | 12.72 | Sun 1:00 |
| WR | D. Adams | WR | LAR | 11.34 | Sun 1:00 |
| WR | **D. Boston** | WR | Cle | **8.92** | **Thu 8:15** |
| FLEX | **K. Raymond** | WR | Chi | **6.23** | Sun 1:00 |
| TE | J. Ferguson | TE | Dal | 6.94 | Sun 1:00 |
| K | H. Butker | K | KC | 8.60 | Sun 4:25 |
| DEF | **Ravens** | DEF | Bal | 7.58 | Sun 1:00 |
| | | | | **100.02** | |

**Revised 10-01. Sutton -> Boston at WR2, see D6b.** Projections restated from the 10-01 Yahoo
pull, so they differ from the 09-29 figures above by ~0.1 (Mahomes 19.97, Henry 17.60, Adams 11.46).
**Boston plays Thursday 8:15pm**, which makes the WR2 deadline Thu, not Sun — the earliest kickoff
among that slot's legal replacements.

Bench: Stafford 16.74, Sutton 9.15, Odunze 8.16, Robinson 8.01, Marks 7.75, **Bates (K2)**.
**IR: Etienne.** Active roster 15/15, both IR slots now 1 of 2 used.


### D3. K — hold Butker. Method explicitly on probation.

Week 4 own implied total, highest first:

| K | team | own implied | proj | |
|---|---|---|---|---|
| T. Bass | BUF | 27.75 | — | FA |
| E. McPherson | CIN | 27.00 | 8.49 | FA 67% |
| **H. Butker (ours)** | **KC** | **26.00** | **8.60** | ours |
| S. Shrader | IND | 25.50 | 8.93 | FA 17% |

**No swap.** Butker is third by implied total but first among realistic options by projection, and
the two signals **disagree on rank order** — Shrader has the lower implied total and the higher
projection. That disagreement is itself the evidence: the own-implied-total mechanism for kickers
is weak. Week 3 it cost 6.00 (dropped McLaughlin 12.00, started Butker 6.00).

Per the Week 3 retro: **hold the incumbent unless the gap is large.** Gap here is 0.33. Hold.

**Kill condition (D3):** the highest-own-implied-total available kicker outscores Butker by 3+.
Two strikes in two weeks and the kicker half of the streaming rule is **retired**, not revisited.
Pre-registering the retirement now so the retro cannot relitigate it.

### D4. QB — Mahomes. No analysis. Pre-committed.

Gap 19.98 vs Stafford 16.49. Week 3 retro closed this: two wrong calls in three weeks on a ~4-point
projection gap, **-23.52 combined**, wrong in *both* directions. Pick one, leave it, spend the
analysis elsewhere. Mahomes is the higher projection and stays.

**No kill condition.** Deliberate. A kill condition here would reopen exactly the loop that was
closed. If Stafford outscores him, that is noise, not news.

### D5. RB — Henry + J. Williams. Forced by projection.

Henry: BAL favored **11.5** over TEN, own implied 27.50. Per the measured game-script table in
`CLAUDE.md`, an RB on a 10+ point favorite is the **1.134x** bucket, the peak. Highest-projected
player on the roster. Starts.

Williams 12.72 is second-highest RB by 5.14 over Marks. Starts.

**Internal conflict, noted:** Williams (Dal) plays **at Houston**, and Marks (Hou) is the Houston
back. Same game, both ours. Marks is benched, so no live conflict — but it means the two are
substitutes for each other in the worst way, and a Houston blowout either direction moves both.

**Kill condition (D5):** Marks or Gainwell outscores Williams by 5+. Would mean the RB depth chart
is mis-ranked the way the WR one demonstrably is.


### D6. **CORRECTED.** WR / FLEX — Adams, **Robinson**, Raymond. Sutton benched.

**Originally: Adams, Sutton, Raymond. Sutton benched 09-29 evening on the §00 correction.**

The original call started Sutton over Odunze on a 0.81-point projection edge. Production says the
projection has this group close to backwards:

| WR | **actual ppg** | wk4 proj | start? |
|---|---|---|---|
| D. Adams (LA Rams) | **18.93** | 11.34 | **yes** — the only separated player, on both signals |
| **K. Raymond (Chicago)** | **12.30** | 6.28 | **yes** — trigger, and production agrees |
| **W. Robinson (Tennessee)** | **7.63** | 7.98 | **yes** — replaces Sutton |
| R. Odunze (Chicago) | 5.97 | 8.21 | no |
| **C. Sutton (Denver)** | **4.07** | 9.02 | **NO — benched** |

**Sutton was our projected WR2 and is our worst producing receiver by 1.9 ppg.** Starting him was
the single largest error in the original document.

**Raymond starts by pre-commitment and that is still the reason.** D5 of the Week 3 log set the
trigger at 6+ targets in Week 3; he got 7. What changed is the *cost*: originally logged as
"-1.93 projected points, paid knowingly." On production Raymond is our **second-best receiver**
and the trigger was not a cost at all. The rule and the better signal agree. Honour the rule; note
that the arithmetic that made it look expensive came from the discredited source.

**The one genuinely close call: Robinson vs Odunze.** Robinson leads by 1.66 ppg, inside any
reasonable error bar on three games. Against him: **Robinson is the Tennessee receiver in the same
game as our Henry and our Ravens DEF**, so he is directly opposed to two plays we like more than
him. Per `CLAUDE.md`, correlation is not the thing to avoid — paying for it is — and here avoiding
it costs 1.66 ppg of the better signal to buy a hedge on the worse one. **Start Robinson, flag the
overlap.** Reasonable people take Odunze; it is not a mistake, it is a different weighting.

**Kill condition (D6), tightened:** Sutton outscores Robinson **and** Odunze outscores Robinson.
Both must fire. One alone is variance on a 1.66-point gap; both together means the benching logic
is wrong, not merely unlucky.


#### D6a. **AMENDMENT, 09-29 late.** Yahoo says bench Raymond for Odunze. Resolved against Yahoo.

Yahoo's lineup assistant recommends Odunze over Raymond. Per §00 this is the source with the logged
failure record, so it does not get to win on assertion — but Raymond and Odunze are **Chicago
teammates competing for the same targets**, so the 12.30 vs 5.97 ppg gap is not two independent
players and cannot settle it either. Week 2's retro found Odunze's snap share moved 48% -> 84%. If
that role shift continued, the box scores lag reality and Yahoo is reading something true.

**So the test is usage, not points.** Fresh pull, `nflreadr::load_player_stats(2026)` and
`load_snap_counts(2026)`, weeks 1-3, week by week — aggregate ppg cannot see a trend.

| wk | Raymond snap% | **Raymond tgts** | Raymond tgt share | Odunze snap% | **Odunze tgts** | Odunze tgt share |
|---|---|---|---|---|---|---|
| 1 | 0.60 | **9** | 0.346 | 0.48 | 3 | 0.115 |
| 2 | 0.62 | **5** | 0.167 | **0.84** | 4 | 0.133 |
| 3 | 0.75 | **7** | 0.206 | **0.85** | 6 | 0.176 |

**The Week 2 finding is confirmed and it held — and it did not convert.** Odunze really is at
84-85% of snaps. He plays more than Raymond and is targeted less. Targets per snap: Raymond
.200 / .109 / .130, Odunze .083 / .065 / .098 — Raymond leads every week. Odunze is on the field;
Raymond gets the ball.

**Raymond's edge is opportunity, not luck.** 21 targets to 13, leading in *all three weeks*, never
a losing week. **One TD in three games**, so the 12.30 ppg is volume, not touchdown variance. Per
`CLAUDE.md` — opportunity sticky, efficiency noise — that is the side you keep. Hand-computed
half-PPR off this pull reproduces 12.30 and 5.97 exactly, so those figures are sound.

**Three counters, checked, none flips it:**
1. **Raymond's catch rate is 90% (19/21).** That *is* efficiency and it will regress; league-average
   WR is ~65%. Regressed, he still leads on targets, which is the part that sticks.
2. **Odunze owns the air yards** — share .282 / .249 / .416 vs Raymond's .204 / .037 / .278. Odunze
   is the downfield option: higher ceiling, lower floor. §0 has us as **favourites** on production
   (110.25 vs 92.47), and favourites want floor. Argues Raymond a second, independent way.
3. **Raymond is off his Week 1 peak** — target share .346 -> .167 -> .206. Real decline, but flat
   across weeks 2-3 and above Odunze in both.

**Verdict: Raymond starts, as D6 already had it. Yahoo's recommendation is rejected on usage.**

**Kill condition (D6a), two firings required:** Odunze outscores Raymond in Week 4 **and**
out-targets him in Week 4. Points alone do not fire it — one deep TD on a 41%-air-yards-share role
is exactly the variance this decision priced in. Targets are the claim; make targets the test.

**Unrostered finding, logged because it explains both players.** **Luther Burden III (WR, Chicago)**
is the rising target earner in that room — share .192 -> .233 -> **.324**, team-leading **11
targets** in Week 3. He is the threat to Raymond and Odunze alike. **Rostered by Max's TD Bombers**,
so he is a trade target, not a claim — same shape as Breece Hall in §6. Noted as ownership state,
not an action item. Trade angle, if it is ever opened: his target share tripled in three weeks and
Max may still be pricing him on preseason rank.

#### D6b. **AMENDMENT, 10-01.** Sutton -> Boston at WR2. D6's choice of Robinson superseded.

D6 picked Adams + Robinson because **Boston's claim was still pending** when it was written. The
claim landed, so the comparison had to be re-run with him in it. Yahoo's lineup also still held the
**pre-correction** D6 (Sutton starting, Robinson benched) — the §00 fix had never been applied on the
site, so the live lineup was wrong against our own log independently of this decision.

| WR | **ppg** | snap% by wk | tgt share by wk | last wk tgts |
|---|---|---|---|---|
| D. Adams | 18.93 | .54 / .65 / .83 | .222 / .333 / .265 | 13 |
| **D. Boston** | **12.67** | **.92 / .93 / .89** | .182 / .233 / .133 | 4 |
| K. Raymond | 12.30 | .60 / .62 / .75 | .346 / .167 / .206 | 7 |
| W. Robinson | 7.63 | .82 / **.53 / .63** | .214 / **.059** / .314 | 11 |
| C. Sutton | 4.07 | .76 / .73 / .87 | .185 / .138 / .226 | 7 |

**Boston plays 90% of Cleveland's snaps every week** — the most stable opportunity signal in the
group, and the one the repo principle says sticks. Sutton is also full-time and has converted it to
4.07 ppg with **zero TDs**; he is the clearest downgrade on the roster.

**Boston over Robinson, revising D6:** Robinson's snap share is 53-63% in two of three weeks, and his
11-target Week 3 sits next to a **one-target Week 2**. Part-time role that spiked once, against an
every-down role.

**Honest counter, recorded:** Boston's targets fell to 4 in Week 3 and two TDs in three games carry
the 12.67. At **2.53 fp per opportunity** he is over-efficient and will regress. The case rests on
the snaps, not the points. Robinson is the higher-variance alternative and taking him is defensible.

**Side effect:** benching Robinson (Ten) removes the self-opposition D6 flagged — we no longer own a
Tennessee receiver against our own Henry and Ravens DEF in the same game.

**Kill condition (D6b), two firings:** Boston finishes Week 4 below **both** Sutton and Robinson.
One alone is variance on a 3-receiver spread this tight; both together means the snap-share read is
wrong, not merely unlucky.

### D8. **CANCELLED.** Stroud claim withdrawn. Stafford retained.

**Originally: claim C.J. Stroud (QB, Houston), drop M. Stafford (QB, LA Rams). Cancelled 09-29
evening before processing.**

The original case was "Stroud outprojects Stafford by 3.11 **and** outranks him 8 to 30 on the
season," with an explicit note that the rank was "realised production rather than projection, so it
does not lean on the weak signal." **Per §00 that note was false.** Rank 8 and projection 19.60 are
the same number in two costumes. The case was one source asserted twice.

| | **actual ppg wks 1-3** | wk4 proj |
|---|---|---|
| **M. Stafford (ours, retained)** | **18.66** | 16.49 |
| C.J. Stroud (not claimed) | **15.05** | 19.60 |

**The swap was a 3.61 ppg downgrade.** Caught only because the claim had not yet processed.

**No QB action is needed at all.** Mahomes byes Week 5, Stafford byes Week 11. They do not collide,
so the Week 5 cover this move was meant to buy already exists for free.

**Noted, not acted on:** Kirk Cousins (QB, Las Vegas) has produced **19.75 ppg** and is free at 14%
rostered — ahead of Stafford by 1.09. Too small a gap to spend a claim on a player who starts once
all season.



### D9. **NEW.** D. Boston claimed, K. Gainwell dropped. Executed 09-29 evening.

**Denzel Boston (WR, Cleveland)** claimed; **Kenny Gainwell (RB, Tampa Bay)** dropped outright.

| | actual ppg wks 1-3 | wk4 proj | bye | % ros |
|---|---|---|---|---|
| **D. Boston (WR, Cle)** | **12.67** (3g) | 8.87 | 11 | 76% |
| K. Gainwell (RB, TB) — dropped | **2.43** (3g) | 6.67 | 10 | — |

Gainwell was the worst producer on the roster by a factor of two and byed in Week 10 alongside
three of our five receivers. Boston would slot in immediately as our **second-best receiver by
production**, behind only Adams.

**This is the first move in this document made on production rather than projection**, and it is
the largest single upgrade the roster had available.

**Side effect, and it closes a hole flagged in §6:** Boston's bye is Week 11, so he plays in Week 10.
The Week 10 three-receiver bye is now covered by Adams + Boston with no FLEX contortion required.

**Not started Week 4 unless the waiver clears before Thu 8:15.** Cleveland plays Thursday. If the
claim processes after kickoff he is locked at 0 and the D6 lineup stands as written.

**Kill condition (D9):** Boston finishes Weeks 4-8 below Sutton over the same span. Five-week bar,
matching D8's reasoning — this was a rest-of-season call on a three-game sample and a one-week
result cannot settle it.


### D10. **NEW.** Etienne -> IR slot. Executed 10-01. No drop required.

**Travis Etienne Jr. (RB, NO) is on IR with a hamstring.** Moved to an IR slot rather than dropped.

Three sources, and the one CLAUDE.md says to distrust failed exactly as documented:

| source | says | trust |
|---|---|---|
| `yahoo_week4_injuries_2026-10-01.csv` | `IR, Hamstring`, new note `Y` | yes |
| `yahoo_week4_gamedaycalls_2026-10-01.csv` | `IR, Hamstring`, **Oct 1 2:51 AM** | yes |
| `rosterchanges_injured_reserve_2026-10-01.csv` | **"Off IR" (Sep 30) AND "On IR" (Sep 23)** | **no — self-contradicting, as the standing rule predicts** |
| `nflreadr::load_injuries(2026)` wk4 | silent | **not evidence** — see below |

**nflreadr's Week 4 report is not filed yet and must not be read as a clean bill of health.** 257
rows, **2 with a `report_status`**, and **zero rows for New Orleans**. An absent row means an absent
report. Checked on 09-30 when Yahoo showed only `O` and the temptation was to read nflreadr's silence
as disagreement.

**The `O` was real news, not a stale state.** Per the standing rule, diffed against usage before
believing it: Etienne was a **full practice participant with no designation** in Week 3 and took
**15 opportunities, his season high**, carries trending 9 -> 8 -> 13. Healthy and rising, then IR.

**Why IR and not a drop.** League carries **2 IR slots that do not count against the 15**. He is
IR-designated, so the move is free: it opens a roster spot while keeping a back who was producing
8.47 ppg on a growing role. The alternative on the table was dropping Sutton, which is no longer
necessary.

**Kill condition (D10):** Etienne is cleared to play and we fail to restore him to the active roster
within one week of clearance. The risk in this move is forgetting it, not making it.

### D11. **NEW.** J. Bates (K, Det) added as K2, into the slot D10 freed.

First week K and DST could be evaluated against a real pool: the 10-01 upload carries a
**`Roster Status`** column, so availability is known — **46 FA kickers, 20 FA defenses**. The Week 3
free-agent export had **no K or DEF rows at all**, which is why D3 could only say "hold."

Ranked by the standing method — kickers on **own implied total**, DST on **opponent implied total**,
from `load_schedules(2026)`, all 16 Week 4 games priced.

| kicker | wk4 own implied | wk5 own implied |
|---|---|---|
| **J. Bates (Det)** | 27.00 | **29.00 — best in the league** |
| H. Butker (KC) | 26.00 | **BYE** |
| best other FA | Bass (Buf) 27.75 | Drzewiecki / Moody (Bal) 27.75 |

Bates wins the week that matters. **Week 5 is Butker's bye**, and Bates holds the single best kicker
spot on the board that week. §5.2 queued him on reasoning that now checks out against published lines.
Taken on 10-01 rather than next week because the slot existed on 10-01 and he was 55% rostered.

**Butker still starts Week 4.** Bates leads by 1.00 of implied total — inside noise, and far under
D3's deliberately loose >=3 pt bar. Switch in Week 5.

**Ravens held, and they are the best DST on the board**, not merely adequate: opponent implied
**15.50** (line moved toward us from 16.00 on 09-29) against the best available FA at **17.50**
(Packers). Nothing to do.

**Logged for Week 5, do not act yet:** the Ravens degrade hard, opponent implied **15.50 -> 21.75**
(vs Atl), best FA then being the Jets at 18.5. §7's one-week line horizon means that call cannot be
made earlier than Week 5 anyway.

**Kill condition (D11):** in Week 5, Bates scores **more than 3 points below** the FA kicker who held
the highest own implied total that week. Bar matches D3's — the *method* is on trial, not the player.

### D7. Forced slots. No decision exists.

Ferguson (TE), Butker (K), Ravens (DEF) — one rostered player each. Recorded for completeness.

---


## 3. Head-to-head overlap. Observed lineup, Tue 09-29.

Logged per the standing rule. **Their lineup as actually set** — the hypothetical best-lineup version
is in §0 and is what we plan against.

| game | ours | theirs (as set) | read |
|---|---|---|---|
| **DEN @ SF** | *(Sutton 9.02 — now BENCHED, D6)* | **McCaffrey 17.44**, **Broncos DEF 5.17** | **Their roster fights itself, and it is live.** Broncos DEF scoring means Denver stopping San Francisco means less McCaffrey. Their best player and their DEF are on opposite sides of one game. Our exposure there is gone since Sutton was benched, so this leverage is now theirs alone. **This is the only genuinely leveraged position either way.** |
| **BAL vs TEN** | Henry 17.68, **Ravens DEF 7.58**, **Robinson 7.98 (TEN — now STARTING, D6)** | **nothing — Flowers 14.28 is benched** | As set, our two biggest correlated plays are unopposed by *them* — but D6 put our own Robinson on the Tennessee side, so we now oppose ourselves here. Self-inflicted, priced at 1.66 ppg, taken knowingly. **This is the slot most likely to change**: if they fix the lineup, Flowers starts and the game becomes aligned-not-opposed (he is a Raven; a Baltimore blowout feeds all three). Re-check Sunday morning. |
| **DAL @ HOU** | J. Williams 12.72, (Marks 7.58 BN) | Schultz 7.80 **benched** | No live overlap. |
| **CHI vs NYJ** | Raymond 6.28, (Odunze 8.21 BN) | Monangai 8.33 **benched** | No live overlap. Our claimed Allen (NYJ) is on the other side, benched. |

**Structural read: their errors and their strengths are in the same game.** Fixing the lineup costs
them nothing in DEN @ SF — McCaffrey and Broncos DEF are both already in — so the self-conflict there
survives any correction they make. It is the one edge we hold that does not depend on them staying
asleep.

**What depends on them staying asleep:** ~20 points, concentrated in Achane's zeroed RB2 slot and the
Hubbard/Flowers bench. Do not build any decision on it. It is not ours to control and it is the most
correctable error on the page.


### 3a. Production read, added at freeze 2026-10-02.

Projection says this is close. **Production says it is not.** Both computed on the same
roster, skill slots only.

| surface | ours | theirs | margin |
|---|---|---|---|
| Yahoo proj, 9 slots (`proj_gameday`) | 99.68 | 90.39 | +9.29 |
| Yahoo proj, 7 skill slots | 83.50 | 78.17 | +5.33 |
| **Our ppg wks 1-3, 7 skill slots** | **115.29** | **83.96** | **+31.33** |
| same, Achane correctly zeroed | 115.29 | 76.93 | **+38.36** |
| same, vs their best legal lineup | 115.29 | 108.33 | **+6.96** |

Method: `score_player_week()` over `nflreadr::load_player_stats(2026)` wks 1-3, mean per
game. K and DST excluded both sides -> `score_team_week()` does not exist. Not comparable
to Yahoo's number and not meant to be: Yahoo projects one week, this averages three played.

**Finding.** Both sides beat projection on production, ours by **+31.79**, theirs by
**+5.79**. Gap is not roster quality as projected -> it is that our starters have
outperformed their own projections ~5.5x harder than theirs have. Consistent with §00.

**+6.96 vs their best legal lineup is the number that matters.** It is the floor, and it
does not depend on them leaving Achane (IR, 0.00) in at RB2 or Flowers (14.30) on the bench.

**Bench check, run at freeze.** Yahoo has our FLEX inverted. Projection prefers Sutton over
Raymond by 2.66; production has Raymond at **3x** Sutton. Hold confirmed, not changed.

| player | proj wk4 | ppg wks 1-3 |
|---|---|---|
| Raymond (FLEX, start) | 6.49 | **12.30** |
| Sutton (BN) | 9.15 | **4.07** |
| Odunze (BN) | 8.03 | 5.97 |
| Robinson (BN) | 7.85 | 7.63 |
| Marks (BN) | 7.78 | 6.37 |
| Mahomes (QB, start) | 19.96 | 22.86 |
| Stafford (BN) | 16.78 | 18.66 |

Confirms **D6a** (Raymond over Odunze on usage -> also right on output) and **D6b**
(Sutton out -> margin wider than when logged). Mahomes over Stafford is the narrowest hold
on the roster at 4.20 ppg.

**Kill condition (3a).** If over wks 4-6 the ppg-based margin calls the winner no better
than the Yahoo projection does, stop computing it and use Yahoo. Scored in the wk6 retro.

**n = 3. Fit nothing.** This is a read, not a model.

**Name trap.** Our `J. Williams` is **Javonte** Williams (Dal, RB). Theirs is **Jameson**
Williams (Det, WR). Both start. Do not collapse them in the retro.


## 4. Deadlines. Earlier than the lock table says.

Per `CLAUDE.md`: the real deadline for a slot is `min(kickoff of that player's legal replacements)`,
not the player's own kickoff.

- **Every decision on this page is due Sun 10-04, 1:00 pm ET.** Mahomes, Sutton, Butker play 4:25,
  but their replacements (Stafford, the three benched WRs, any FA kicker) all play 1:00 or earlier.
  There is no 4:25 grace period on any slot.
- **No Thursday exposure.** Nobody of ours plays Thu 10-01 20:15. Their Metcalf does.
- **First Sunday lock is 09:30 ET** (IND @ WAS, international window). We have nobody in it. No effect
  this week — but it is 3.5h earlier than any prior week, so do not carry a 1:00 pm habit into Week 5
  without re-checking.
- **Waiver:** Allen clears **Wed 09-30**. If the claim fails, the roster sits at 14 and nothing in
  §2 changes.

---


## 5. Explicitly NOT being learned this week

- Anything about Mahomes vs Stafford (D4 — deliberately unmeasured).
- Anything about Odunze in isolation (D6's bar requires two firings, not one).
- Anything about Boston's or Etienne's single Week 4 score (D9 and D1 are five-week and
  three-week bars respectively).
- Whether the DST rule works. It is 1-for-1. Week 4 makes n=2. Not validated either way.
- **Whether production beats projection.** n=3. §00 establishes that the two disagree and that one
  of them is our own validated function. It does not establish that three games predict anything.


## 6. Bye horizon. Opened Tue 09-29, not yet a process.

Roster byes after the three pending claims land. **Week 4 is the last week with no bye exposure.**

| wk | out | who | slot actually at risk |
|---|---|---|---|
| **5** | 2 | QB Mahomes, **K Butker** | **K** — Stroud covers QB. One kicker on roster, zero that week. |
| 8 | 2 | QB Stroud, RB Marks | none — Mahomes covers QB, RB is 4 deep |
| 9 | 1 | WR Robinson | none — he is already benched |
| **10** | 4 | RB Gainwell, **WR Sutton, WR Odunze, WR Raymond** | **WR** — 3 of 5 receivers gone at once. Leaves Adams + Robinson for two WR slots, FLEX must go to an RB. |
| 11 | 1 | WR Adams | thin, not broken |
| 13 | 3 | RB Henry, RB Allen, DEF Ravens | RB — loses the best back and the new claim together |
| **14** | 2 | RB Williams, **TE Ferguson** | **TE** — only rostered TE. Week 14 is a seeding week (regular season runs 1-15). |

**Three real holes: K in 5, WR in 10, TE in 14.** Everything else is covered by existing depth.

**Week 5 K answer already computed** from `load_schedules(2026)` week-5 lines (published, checked
09-29). Own implied total, highest first, free agents only:

| K | team | wk5 own implied | opp | % ros |
|---|---|---|---|---|
| **J. Bates** | Det | **29.00** | @ARI (total 52.5) | **55%** |
| E. McPherson | Cin | 27.50 | vs MIA | 67% |
| T. Bass | Buf | 25.00 | vs LA | 25% |

Only **Carolina and Kansas City** bye in Week 5, so the Ravens DEF claim is unaffected.

**Recommended Week 5 move: drop Butker, claim Bates.** A bye is a *forced* swap, so D3's
"hold the incumbent" rule does not apply — that rule governs optional weekly swaps. Bates at 55%
rostered means roughly half the league can see the same bye coming; this is decided on the Week 5
waiver run, not later.

**This section is a one-off, produced by hand. Making it a repeatable two-week-ahead process is
the open task — see the Week 4 to-do below.**

---

## 7. Open task: bye monitoring, two weeks ahead

Stated as a priority Tue 09-29. **Not yet designed. Decide before Week 5 freezes.**

Requirement: each week, know which slots go uncovered in week `W+2`, and see the candidate pool
for those slots early enough to claim ahead of the other nine managers. Two weeks is the stated
horizon; Bates at 55% rostered is the worked example of why one week is too late.

**Constraint found 09-29, and it splits the design in two. Measured, not assumed:**

| week | games | with lines |
|---|---|---|
| 4 | 16 | **16 (100%)** |
| 5 | 15 | **15 (100%)** |
| **6** | 14 | **0** |
| 7-15 | — | **0** |

**`load_schedules(2026)` publishes `spread_line` / `total_line` exactly one week ahead.** During
Week 4, Week 5 is the furthest week with any lines at all. So:

- **K and DST cannot be planned two weeks out.** Implied total *is* the entire streaming method,
  and the input does not exist until the week before. **Their horizon is capped at one week.**
  The Week 5 Bates call in §6 was possible only because Week 5 is exactly one week out — that is
  the ceiling, not headroom.
- **QB / RB / WR / TE can be planned as far ahead as wanted**, because they are ranked on
  `rank_actual` (realised production) and projection, neither of which needs a future line.
- **The bye calendar itself is known for the whole season** from the exports' `Bye` column.

**Consequence for the stated goal of "getting in front of other managers":** at K and DST you
structurally *cannot* get ahead on matchup merit — nobody can, the information does not exist.
The only early edge there is claiming on **bye-avoidance** alone, which is a weaker reason and
should be priced as such. The two-week edge is real at WR/RB/TE, which is where Week 10's
three-receiver hole lives anyway.

**Second constraint, unmeasured:** free-agent status comes from the weekly Yahoo export's
`Roster Status`, so a two-week-ahead candidate list uses *today's* availability as a proxy for
availability in two weeks. That is not a flaw — it is the point, since the move is to claim while
the player is still free — but it means the list decays and must be re-cut each week, never cached.

Design not settled. Do not build until it is.

---


## Retro

*Append after Monday 2026-10-05. Do not edit above this line.*

---

### GD1. Gameday script read. 2026-10-04 11:40 ET. **No lineup change.**

Read, not decision. Logged below `## Retro` line because it is post-freeze. Scored
apart from D1-D11. Lineup as frozen stands — no slot moved.

**Sign error found and fixed.** `load_schedules()` `spread_line` is **positive =
HOME favoured**. Earlier verbal reads this session inverted it for CHI and DEN.
Corrected: **Chi favoured 3.5** (own implied 23.50), **Den 3-pt dog @ SF** (22.75).
Validated against handoff #34 numbers before use — BAL own 27.0 / opp 15.5, DET own
27.5. Both reproduce exactly.

Consequence: Sutton's only remaining edge over Raymond was implied total. Gone.
Raymond's team is the favourite. **D6/D6a/D6b hold strengthens, no amendment needed.**

Multipliers from `CLAUDE.md` game-script table. RB/WR/QB only — TE/K/DST unmeasured.

| slot | player | game | fav by | own imp | mult | ppg | adj |
|---|---|---|---|---|---|---|---|
| RB1 | **Henry** | BAL vs TEN | **+11.5** | **27.0** | **1.134** | 24.13 | **27.36** |
| QB | Mahomes | KC @ LV | +4.5 | 26.0 | 1.028 | 22.86 | 23.50 |
| WR1 | Adams | LA @ PHI | +3.5 | 23.0 | 1.000 | 18.93 | 18.93 |
| RB2 | J. Williams | DAL @ HOU | **-3.0** | 22.75 | **0.945** | 15.17 | **14.34** |
| FLEX | Raymond | CHI vs NYJ | +3.5 | 23.5 | 1.000 | 12.30 | 12.30 |
| WR2 | Boston | *played Thu* | -2.5 | 18.0 | — | — | **10.90 actual** |
| TE | Ferguson | DAL @ HOU | -3.0 | 22.75 | n/a | 9.23 | 9.23 |
| K | Butker | KC @ LV | +4.5 | 26.0 | — | — | — |
| DEF | Ravens | BAL vs TEN | +11.5 | **opp 15.5** | — | — | — |

**116.56 script-adjusted. Skill slots only, 7 of 9** — `score_team_week()` does not
exist. Not comparable to a Yahoo total. Say so every time.

**Four reads.**

1. **One blowout on slate: BAL -11.5. We hold both profitable sides.** Henry at RB
   fav 10+ -> 1.134x, and measured table says **no blowout tax** (RB fav 13+ = 1.311).
   Ravens DST opponent implied **15.50, lowest on the board** — DST dominated by
   points allowed -> correct start. Positively correlated, both ours, **arrived free
   while gaining points** -> permitted concentration, not paid-for. Benched Robinson
   is the TEN side (own implied 15.50, worst we roster) — starting him would have
   fought our own DST.
2. **Javonte is the only starter in a negative RB bucket.** Dal 3-pt dog -> 0.945x.
   Bench Marks is Hou, 3-pt favourite -> 1.078x. 14% multiplier swing toward Marks.
   Adjusted **14.34 vs 6.87. Hold by 7.47.** Script moves the gap, does not close it.
   Total 48.5 is highest of our 1:00 games -> helps both backs (47+ -> 1.061).
3. **Nothing to defend.** No starter a dog by more than 3. Only double-digit dog we
   roster is Robinson, already benched. No defensive adjustment exists.
4. **QB script is a dead heat.** Mahomes +4.5 and Stafford +3.5 both land 1.028. Hold
   rests entirely on production, 22.86 vs 18.66. **Hold by 4.32 adjusted.**

**K unchanged.** Bates own implied **27.50** (Det @ Car, total 51.5, highest on board)
vs Butker **26.00**. 1.5 total ~ 0.3-0.5 fp, **under the >3pt kill bar**. Hold Butker.
Wk5 switch stands, reason is implied total not form.

**Kill condition (GD1), two firings required:** Henry finishes **below his own 24.13
ppg** AND Javonte finishes **above his own 15.17 ppg**. Both must fire — that is the
multipliers wrong-signed, not noise. One alone is a single player-week at n=3 and
settles nothing. **Score at the wk6 retro, not Monday.** Same bar as §3a.

---

## Retro — Week 4. Appended 2026-10-05. Nothing above this edited.

**L. 93.00 - 98.58, margin -5.58. Record 2-2.** All nine slots, Yahoo finals.
`score_player_week()` reproduced **22/22** skill scores both rosters exactly —
validation now 57/57 wks 1-4. DST still hand-read from Yahoo.

Opponent caveat: their logged RB2 **Achane scored 0.00** (IR, since waived). They
added **Kamara** (NO, MNF) post-freeze. If Kamara took the slot their total rises and
the loss widens. **Loss is determinate either way.** Matchup page would settle it.

| | started | best legal | regret |
|---|---|---|---|
| **ours** | **93.00** | **120.10** | **27.10** |
| theirs | 98.58 | 141.86 | 57.28 |

**Worst regret of four weeks** (wk1 19.76, wk2 2.50, wk3 25.06, **wk4 27.10**).
**Best legal lineup beats them by 21.52.** Winnable game, lost on three swaps:

| swap | gain |
|---|---|
| **Bates 18.00 over Butker 6.00** | **+12.00** |
| Robinson 9.50 over Raymond 1.60 | +7.90 |
| Odunze 12.40 over Adams 5.20 | +7.20 |

Both pass-catcher swaps were **on our own bench and flagged pre-kickoff**. Not variance.

### Kill conditions scored

| id | bar | result |
|---|---|---|
| **D6a** | Odunze > Raymond on **pts AND tgts** | **FIRED. KILLED.** 12.40/1.60, **7 tgt / 2 tgt** |
| D6 | Sutton > Robinson **and** Odunze > Robinson | **not fired.** Sutton 0.90 < 9.50, one leg |
| D6b | Boston below **both** Sutton, Robinson | **not fired.** 10.90 beat both |
| D2 | Ravens under Chiefs by >3 | **not fired.** Ravens 6.00, Chiefs 4.00. **DST half works 2nd wk running** |
| D5 | Marks beats Javonte by 5+ | **not fired.** 8.20 vs 28.80 |
| D9 | Boston < Sutton wks 4-8 | wk1 of 5. 10.90 vs 0.90, on track |
| **D3** | highest-own-implied **available** K beats Butker by 3+ | **see below. literal NO, intent YES** |
| GD1 | Henry < 24.13 **and** Javonte > 15.17 | **FIRED.** 14.90 / 28.80. Caveat below |
| D1, D10, D11 | — | MNF pending / wk5 |

### D6a. Clean kill. Chicago target room reorganised.

Bar was deliberately **targets, not points**. Both legs fired. Log's own honest counter
was correct: *"the 12.30 vs 5.97 gap may be describing a Chicago that no longer exists."*
It was. **Luther Burden III took 6 targets** — the exact player flagged at D6a line 311.
Third Chicago QB in four weeks (Bagent, 34 att). Raymond's 12.30 ppg rested on a target
share that is gone. **Raymond out of FLEX from wk5. Not revisitable.**

### D3. The bar measured the wrong thing. Method NOT retired.

**Literal reading: does not fire.** D3's "highest-own-implied available" was **Bass (BUF
27.75, FA)**. Bass **8.00** vs Butker **6.00** = **+2.00, under the 3 bar.** So the
pre-registered retirement of the kicker rule is **not triggered.** Say that plainly
before anything else, because it is the reading that does *not* flatter us to skip.

**Intent reading: fires hard.** D3's table was written 09-29. **D11 added Bates 10-01**,
after it. Final lines put **Det own implied 28.50, highest of all 30 teams** -> the
method's true #1 pick was **Bates, on our own bench, 18.00. +12.00 over Butker.**

**Method tested properly instead of on one player.** 30 teams, one kicker each, wk4
finals vs final own implied total:

- **Spearman 0.300, Pearson 0.339.** Positive.
- buckets: `<20` **7.14** | `20-23` **8.78** | `23-26` **11.10** | `26+` 9.75 (n=4)
- method's #1 (Bates) was the week's **#2 kicker overall**. Butker 6.00, under the
  30-team **median 8.00** and mean 9.30.

**-> The streaming method was right. The HOLD BAR is what failed.** D3 and GD1 both
denominate the K bar in **projected points** (gap 0.33, then 0.25). Yahoo kicker
projections cluster inside ~1 point for everyone while **actuals ran 0-19**. A
>3-*projected*-point bar on kickers is **unsatisfiable by construction** -> always says
hold -> the method can never act. Two weeks running it suppressed a correct call
(wk3 McLaughlin +6.00, wk4 Bates +12.00, **18.00 forgone**).

**Change, wk5 on: the K hold bar is denominated in OWN IMPLIED TOTAL, not projection.**
Start the highest-own-implied kicker we hold. Retire the projected-point gap for K only.
Kicker *projections* are not evidence and do not get a vote.

### GD1. Fired, and stated against ourselves.

Multipliers inverted: best-script RB (Henry, fav 11.5, 1.134x) **14.90**, below his 24.13.
Worst-script RB (Javonte, dog 3, 0.945x) **28.80**, our top scorer.

**Do not retire the game-script table.** The bar was pre-registered on **one player-week
per leg**, which this repo already knows is underpowered. One week cannot overturn a
multi-season mean. **Logged as fired, table stands. Re-score wk6 as written.**

Real lesson is the bar, not the table: **GD1 repeated D3's error** — a two-leg bar on
n=1 observations. Future script bars need many player-weeks, not our own two starters.

### Decision wrong vs outcome bad

- **Sutton/Raymond: decision RIGHT, outcome bad.** Raymond 1.60 beat Sutton 0.90. The
  question asked twice on gameday was answered correctly and gained **+0.70**. It was
  also **the wrong FLEX** — Odunze and Robinson both sat. **Sutton was never the
  expensive comparison. D6a was, and we got it wrong.** Answering the question asked
  instead of the question that mattered is the lesson.
- **QB hold RIGHT.** Mahomes 17.00 > Stafford 11.68. First time in 4 wks the QB call
  landed; prior leak was 23.52 over wks 1+3.
- **D5 RB hold RIGHT, big.** Javonte 28.80.
- **Adams 5.20** on 18.93 ppg. Outcome bad, no decision to fix — he was the correct WR1.

### Standing

**n = 4. Fit nothing.** Two bars this week (D3, GD1) failed on *power*, not on direction.
**Stop writing kill conditions on single player-weeks.** That is the transferable finding.
