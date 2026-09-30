# Week 4 Decisions — 2026, JGrahnasaurs (2-1)

**Opponent:** Jason's Jazzy Team (Pete), 1-2-0, 8th.
**Frozen:** NOT YET. Lineup open. Opened Tue 2026-09-29, **materially revised Tue 09-29 evening**
after the methodology correction in §00.

**Waiver state, Tue 09-29 evening:**

| claim | status |
|---|---|
| Ravens DEF in / Chiefs DEF out | **LIVE** — kept, see D2 |
| **D. Boston (WR, Cle) in / K. Gainwell (RB, TB) out** | **LIVE** — new, see D9. Gainwell already dropped. |
| ~~Stroud in / Stafford out~~ | **CANCELLED** — see D8 |
| ~~B. Allen in / Etienne out~~ | **CANCELLED** — see D1. Etienne retained. |

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
| WR | C. Sutton | WR | Den | 9.02 | Sun 4:25 |
| FLEX | **K. Raymond** | WR | Chi | **6.28** | Sun 1:00 |
| TE | J. Ferguson | TE | Dal | 6.93 | Sun 1:00 |
| K | H. Butker | K | KC | 8.60 | Sun 4:25 |
| DEF | **Ravens** | DEF | Bal | 7.58 | Sun 1:00 |
| | | | | **100.13** | |

Bench: Stafford 16.49, Odunze 8.21, Robinson 7.98, Marks 7.58, Gainwell 6.67, (Allen 10.28 if claim lands).


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
