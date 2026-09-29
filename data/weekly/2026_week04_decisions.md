# Week 4 Decisions — 2026, JGrahnasaurs (2-1)

**Opponent:** Jason's Jazzy Team (Pete), 1-2-0, 8th.
**Frozen:** NOT YET. Roster moves executed Tue 2026-09-29 (evening). Lineup open.
**Date note:** handoff #32 dated 09-29 as "Mon". 2026-09-29 is a **Tuesday**. Corrected here.
**Projection source:** `docs/uploads/week_4_data/` week-4 Yahoo position exports (projections, not actuals).
**Prior:** handoff #32 `docs/handoff/ffdraft-handoff-20260929-25-WEEK4-SWAPS.md`.

Do not edit above `## Retro`. Retro appended after Monday 10-05.

---

## 0. The frame. Two numbers, and they point opposite ways.

**Observed on the Yahoo matchup page Tue 09-29** (screenshot, pre-waiver). Opponent has **already set
a lineup, and it is not their best legal one.**

| | projected starters |
|---|---|
| **JGrahnasaurs** (after D1/D2 below) | **100.13** |
| Jason's Jazzy Team — **best legal lineup** | **109.74** |
| Jason's Jazzy Team — **lineup as actually set** | **89.51** |

**They are starting De'Von Achane at RB2. Achane is on IR. He projects 0.00.** Benched behind him:
Hubbard 14.53, Flowers 14.28, Maye 18.47, Stevenson 9.95. That is roughly **20 points sitting on
their bench**, and one of the nine slots is a guaranteed zero.

Yahoo's own header reads **92.75 vs 89.51, "Favorite 53%"** — but that is our *pre-move* lineup, still
carrying Etienne 0.00 in the FLEX and Chiefs DEF. It is stale in our favour's direction, not theirs.

**How to plan against this: assume they fix it.** It is Tuesday evening, the first lock is Thursday night, and an
IR player in a starting slot is the most visible possible error. Plan against **109.74**, which makes
us **~9.6 point underdogs**. Treat the 89.51 as upside, not as the baseline.

**Consequence for the calls below, stated carefully because it cuts both ways:** against their best
lineup we are the dog and variance helps us; against their set lineup we are a 10-point favourite and
variance *hurts* us. **So variance is not a usable tiebreaker this week.** Anywhere below where a
"we need the right tail" argument could have been reached for, it is withdrawn. Every call stands on
projection and pre-commitment alone.

**Prediction logged for the retro:** predicted their QB as Maye 18.47; they started **Goff 18.44**.
Wrong player, 0.03 points apart. Records that the QB slot on their roster is a coin flip, not that
the prediction method failed.

**Their only early lock: DK Metcalf, Thu 10-01 8:15.** He is in their starting lineup at WR2 (8.73).
Once he plays they cannot move him, but every other slot including Achane stays editable until Sunday.

---

## 1. Roster moves. BOTH EXECUTED Tue 09-29. Not decisions any more, record only.

### D1. Etienne dropped. Braelon Allen claimed.

**T. Etienne Jr. (RB, New Orleans)** was `O`, proj **0.00**, `rank_actual` 734. IR checked on the
Yahoo roster page directly — **this league's IR does not accept an `O` designation**, so the free
option did not exist. Answers handoff #32 §3's open question: **no**. Record it, do not re-check.

Diffed against usage first per `CLAUDE.md` (`O` state, not event): Week 3 he was `Q`, dressed,
played, 57 rush + 13 rec + 2 rec, scored 8.00. So the `O` **is** new information, not a stale tag.
Drop justified on that, not on the tag alone.

Claim: **Braelon Allen (RB, NY Jets)**, proj **10.28**, **21% rostered**, waiver clears Wed 09-30,
plays Sun 1:00 @ Chi.

Reason he is not a projection artifact — the Jets backfield changed hands and the league has not
repriced it:

| | proj carries | proj pts | rank preseason -> actual | % ros |
|---|---|---|---|---|
| **B. Allen** | **12.6** | **10.28** | 223 -> **87** | **21%** |
| B. Hall | 7.2 | 7.36 | 32 -> **164** | 99% |

Allen would be RB3 by projection ahead of Marks 7.58 and Gainwell 6.67. **Not** started Week 4 —
claim is for depth and for Weeks 5+.

**Kill condition (D1):** Allen under 8 carries in Week 4 **and** Hall over 12. That reads as Yahoo's
projection being ahead of the actual coaching decision, and the claim was wrong.

**Note:** Hall is on the Week 3 opponent's roster (Maybe Mitchell), not this week's. No head-to-head
effect.

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

### D6. WR / FLEX — Adams, Sutton, Raymond. **Raymond is not a judgment call.**

**Raymond starts by pre-commitment.** D5 of the Week 3 log set the trigger at **6+ targets in
Week 3 -> starts Week 4**. He got **7** (6 catches, 90 yards, 1 TD, 18.00 points). Trigger fired.
Not optional. Honouring a rule's hit after the Week 3 log paid 11.90 for honouring its miss.

**State the cost honestly:** Raymond projects **6.28**, lowest of the five receivers. Starting him
over Odunze costs **-1.93 projected points**. That is the price of the rule, paid knowingly. Per §0 the
underdog/variance argument is **withdrawn** — it is not available as a tiebreaker when the same week
has us as a 10-point favourite under the opponent's actual lineup. The cost is paid for one reason
only: the pre-commitment. No supporting argument is offered or needed.

Remaining two receiver-eligible slots:

| WR | wk1 tgt | wk2 | wk3 | wk4 proj | % ros | |
|---|---|---|---|---|---|---|
| **D. Adams** | 6 | 10 | 13 | **11.34** | 98% | **starts** — only separated player |
| **C. Sutton** | 5 | 4 | 7 | **9.02** | 79% | **starts** |
| R. Odunze | 3 | 4 | 6 | 8.21 | 92% | bench |
| W. Robinson | — | — | — | 7.98 | 47% | bench |

Sutton over Odunze on two grounds: higher projection, and Odunze is Chicago **like Raymond**, so
starting both doubles one game with a forced starter already in it.

**Robinson benched resolves the D2 conflict for free.** He is the Tennessee receiver on the other
side of Henry + Ravens DEF. Starting him would have been betting against our own two best plays.
He is off the projection board anyway, so no price was paid to avoid it.

**Kill condition (D6):** any two of {Odunze, Robinson} outscore any two of {Adams, Sutton, Raymond}.
Same bar as Week 3's D5 — beating one starter is variance, beating two as a pair is a ranking failure.
This is now the **fourth straight week** this pool is inside its own error bar. If the kill fires
again, Yahoo projections stop being the WR ranking input and the retro must name a replacement.

### D7. Forced slots. No decision exists.

Ferguson (TE), Butker (K), Ravens (DEF) — one rostered player each. Recorded for completeness.

---

## 3. Head-to-head overlap. Observed lineup, Tue 09-29.

Logged per the standing rule. **Their lineup as actually set** — the hypothetical best-lineup version
is in §0 and is what we plan against.

| game | ours | theirs (as set) | read |
|---|---|---|---|
| **DEN @ SF** | Sutton 9.02 | **McCaffrey 17.44**, **Broncos DEF 5.17** | **Their roster fights itself, and it is live.** Broncos DEF scoring means Denver stopping San Francisco means less McCaffrey. Their best player and their DEF are on opposite sides of one game. Our exposure (Sutton) is on the side that hurts both. **This is the only genuinely leveraged position either way.** |
| **BAL vs TEN** | Henry 17.68, **Ravens DEF 7.58** | **nothing — Flowers 14.28 is benched** | As set, our two biggest correlated plays are unopposed. **This is the slot most likely to change**: if they fix the lineup, Flowers starts and the game becomes aligned-not-opposed (he is a Raven; a Baltimore blowout feeds all three). Re-check Sunday morning. |
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
- Anything about Odunze in isolation (D6's bar is on pairs, not individuals).
- Anything about Allen's Week 4 score (claimed for depth, not started).
- Whether the DST rule works. It is 1-for-1. Week 4 makes n=2. Not validated either way.

---

## Retro

*Append after Monday 2026-10-05. Do not edit above this line.*
