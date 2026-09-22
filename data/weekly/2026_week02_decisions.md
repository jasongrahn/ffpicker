# Week 2 decision log — written BEFORE kickoff

**Frozen 2026-09-16 (Tue). Week 2 opens Thu 09-17.**
**Do not edit after first kickoff.** Post-game notes go in `## Retro`, appended only.

Point: Week 1 notes were written after the games. Reasoning reconstructed ->
unfalsifiable. This file records the call, the reason, and the **kill condition**
up front, so the retro tests reasoning instead of narrating outcome.

Roster changed this week: **T. Tracy Jr. dropped -> K. Raymond added** (WR Chi,
4% rostered, led Chi in Wk1 targets). 2-day waiver, cleared before lock.

---

## Decisions

### D1. Mahomes (KC) starts, Stafford (LAR) benched

Proj near-tied: **18.50 vs 18.22**. Projection does not decide this.

Tiebreak -> two non-projection reasons:
1. Mahomes has rushing floor (23 rush yds Wk1 vs Stafford -1). Floor, not ceiling.
2. Stafford + Adams both LAR. Starting Stafford = repeat Wk1 double-exposure.
   Adams is the better of the two -> keep Adams, drop Stafford.

Mahomes kicks **Sun 8:20pm**, last non-Monday slot. Decision was free until then.

**Kill condition:** Stafford outscores Mahomes by >4.
**Weaker signal:** Stafford outscores by 0-4 -> noise, projections were tied.

### D2. Sutton (Den) starts over Odunze (Chi) at WR2

Proj favors Sutton narrowly (8.98 vs 8.64). Real reason is snap share.

| | snap % Wk1 | tgt | Wk1 pts |
|---|---|---|---|
| Sutton | **76%** | 5 | 2.10 |
| Odunze | 48% | 3 | 6.20 |

Claim: Sutton's 2.10 was **efficiency** (2 catches / 5 tgt / 11 yds), not role loss.
Efficiency regresses, snap share persists. Repo principle, applied straight.
Denver receiver room thinned by IR -> target concentration up.

**Contrarian.** Sutton started in **18%** of leagues, Odunze **42%**. Crowd is on
the other side. Logged on purpose.

**Kill condition:** Odunze outscores Sutton AND out-snaps him. Both, not either.
Odunze outscoring on fewer snaps = TD variance, does not kill the reasoning.

### D3. Adams (LAR) starts despite 54% snap share

Highest proj on roster at WR (10.02), 97% rostered, but **2nd in LAR snaps behind
Puka Nacua (70%)**. Started on projection + 27.2 implied team total, not on role.

Flagged as the weakest start in the lineup. Ownership is buying reputation.

**Kill condition:** Adams under 8.0 AND snap share still <60%. Two weeks of that
-> he is not a every-week starter, treat as matchup play from Week 4.

### D4. Etienne (NO) held in FLEX. No waiver upgrade taken.

Etienne: **18 opportunities** (9 att + 9 tgt), worst-ish environment (19.5 implied,
+7.5 dog at Bal). Scanned all 221 FAs. Exactly one beat him on opportunity —
Allgeier (RB Ari, 19) — into a **worse** environment (18.5 implied).

Every other candidate was opportunity-down / environment-up:
Black (RB SF) 15 opp / 29.0 implied; Shakir (WR Buf) 6 tgt / 29.5 implied;
Vele (WR NO) 9 tgt but same NO script.

Opportunity is sticky, environment is one week. Held.

**Kill condition:** Etienne under 7.0 AND his opportunity count drops below 12.
Bad score on 18 opportunities = variance, not a bad decision.

### D5. Raymond (Chi) added but BENCHED. Deferred to Sun 11:30am.

Tension, unresolved on purpose:

| evidence | says |
|---|---|
| 9 tgt, 8 rec, 12.40 pts Wk1 | start |
| 60% snaps, out-snapped Odunze (48%) | start |
| **Yahoo proj 3.47** (was 2.91, barely moved) | sit |
| preseason rank 350, 4% rostered, 1% started | sit |

Called it for Yahoo. 3.47 vs 8.98 is a **5.5 pt gap**; 9-vs-5 targets buys maybe
2-3 pts *if the role is fully real*, and n=1 cannot establish that. No Chi receiver
was hurt Wk1 -> the 9 targets were not an injury artifact, which is why he is
rostered at all.

**Trigger, pre-committed:** 6+ targets again in Week 2 -> Raymond starts Week 3.
**Kill condition:** Raymond outscores Sutton AND Adams. Beating one = variance.

#### D5 addendum — 2025 history pulled 2026-09-16, BEFORE kickoff

Call unchanged. **Stated reasoning was half wrong.** Correct it, do not re-tell it.

Raymond 2021-2025 (DET), `load_player_stats` + `load_snap_counts`:

| season | tgt | tgt/g | snap % |
|---|---|---|---|
| 2021 | 71 | 4.4 | 72% |
| 2022 | 64 | 3.8 | 50% |
| 2023 | 44 | 2.6 | 30% |
| 2024 | 25 | 1.9 | 28% |
| 2025 | 30 | **2.0** | **37%** |

**8+ target games: 2 of 78 career (2.6%). Career max 10.** Wk1's 9 sits at the
edge of his lifetime range, not at the start of a new role.

Snap-share argument **withdrawn**. 2025 weekly snap pct:
`.66 .54 .49 .55 .03 .04 .44 .45 .54 .64 .40 .17 .26 .09 .19`
-> Wk1 2025 he played **66%** (more than the 60% this year) for 2 rec / 16 yds.
Snap-eater who does not draw targets. Returner + route-filler, not a read.

Consequence: Yahoo 3.47 is **not stale**. It is a 78-game prior working correctly
against 1 contrary game. Earlier framing ("Yahoo anchored to a preseason depth
chart Wk1 contradicted") was wrong and is retracted here.

Trigger recalibrated **8+ -> 6+**. 8+ asks a 2.6% event twice running; would not
fire even on a genuine role change. 5-7 tgt games = 17/78 (22%) -> two straight
6+ is real signal at a reachable bar.

Retro must score D5 on the **corrected** reasoning. Right call, wrong reason is a
different result than right call, right reason.

### D6. Dal/Was same-game exposure ACCEPTED

J. Williams (RB) + Ferguson (TE), both starting, Sun 4:25pm. Handoff #29 §3 flag.

Accepted, two reasons:
1. Unavoidable. Ferguson is the only TE. RB alternatives cost ~8 proj pts.
2. RB + TE is **not** the Wk1 failure mode. Dal leading -> Williams carries.
   Dal trailing -> Ferguson targets. Partially self-hedging. Unlike WR+WR.

Bal/NO (Henry + Etienne) is **opposite teams** = hedge, not stack. Not a flag.

**Kill condition:** both under 60% of proj. That is one script sinking both ->
the RB/TE hedge argument is wrong and the flag should apply to RB+TE too.

---

## Open at freeze time

1. **Weather.** TB vs Cle shows rain (McLaughlin K, Gainwell). `week2_game_env.R`
   returns all-NA temp/wind — forecast not populated this far out. Re-run Sunday.
2. **Lines move.** `proj` column in the CSV is Tue value. Refresh at lock.
3. Sun 11:30am inactives -> only new information before D5's 1:00pm deadline.
   No new Raymond usage data exists before then. Waiting buys news, not stats.

## Lock order

| lock | players |
|---|---|
| Sun 1:00pm | **Raymond**, Odunze, Robinson, Henry, Etienne, Marks, McLaughlin, Patriots |
| Sun 4:05pm | Sutton |
| Sun 4:25pm | J. Williams, Ferguson |
| Sun 8:20pm | Mahomes |
| Mon 8:15pm | Adams, Stafford |

Adams + Stafford Monday = free options. D1 and D3 stay live all weekend.

---

## Sunday 11:30am check — 2026-09-20, BEFORE 1:00pm lock

Appended, not edited. D1-D6 above untouched. Resolves `## Open at freeze time` item 3.

Sources: `load_injuries(2026)` wk2 (Fri official report), `load_schedules(2026)`,
`load_snap_counts(2026)` wk1, `load_player_stats(2026)` wk1 — pulled 2026-09-20 11:30am.
Plus `docs/uploads/week_2_data/2026-09-20-game-day-calls.txt`, Yahoo, stamped
**Sep 19 8:46pm** — Sat night, *not* the 90-min inactives. User confirmed all 15 active.

**Verdict: no lineup change. All nine starters unchanged.**

| finding | touches | effect |
|---|---|---|
| Olave (WR NO) designation **cleared**, plays | D4 | neutral. Flagged Q on Fri report, resolved Sat |
| Flowers (WR Bal) Doubtful -> **OUT**, hamstring | Henry | **positive**. Bal -8.5, WR1 gone -> run script |
| NO backfield gutted | D4 | **positive**. Hold confirmed |
| Chi: zero WR out | D5 | **null**. Only pre-lock flip path stayed shut |
| Mims (WR Den) **OUT**, foot | D2 | weak positive. 18% snaps wk1, thin confirm |
| Nacua (WR LAR) **Q**, hip, DNP all wk; Whittington **D** | D1, D3 | live to Mon 8:15pm |

### D4 — NO backfield, wk1 actuals

| RB | snaps | snap % | opp | status 09-20 |
|---|---|---|---|---|
| **Etienne** | 53 | 59% | **18** | active |
| K. Miller | 26 | 29% | 9 | "Coach's Decision" — scratch risk |
| Donaldson | 15 | 17% | 4 | active |
| Chandler | — | — | — | IR |
| Estime | — | — | — | IR |

Neal Q (hamstring). Etienne = only healthy back with workload. D4 reasoning intact.

### False lead, killed before acting. Record it.

Yahoo lists **Mixon (RB Hou) OUT**. Read as "Marks promoted to lead back" -> wrong.
`load_player_stats(2026)` wk1: Mixon **0 rows**, did not play wk1 either. Lead back is
**D. Montgomery** — 20 car, 3 tgt, 3 TD, 49% snaps, on no report. Marks 9 car, 51% snaps,
clear #2. Mixon-OUT is **not new information**, it is a standing absence.

Generalizes: a Yahoo `O` is a *state*, not an *event*. Diffing it against wk1 usage is
what separates the two. Without the snap-count check this was a start recommendation.

### Chi opponent note, unused

Min missing QB Murray (concussion) + WR Jennings (O) + RB Mason (IR). Gutted opponent ->
Chi leads -> Chi passes less. Weakly supports benching Odunze **and** Raymond. Directional
only, **not** part of the D5 call, which was made Tue and stands on its own reasoning.

### Weather — open item 1, CLOSED as unanswerable from nflreadr

`load_schedules(2026)` `temp`/`wind` are **NA for all 15 unplayed games**. Field backfills
post-game only. Not a `week2_game_env.R` bug — do not debug it. Market proxy instead:
TB/Cle total **41.5**, second-lowest on slate -> conditions already priced. TB -8.5 with a
low total = win-but-low-scoring = fine K profile. McLaughlin held.

### Still open at 11:30am

**Nacua.** D1 and D3 both hinge on it, Mon 8:15pm, 33h of runway. Nacua out-snapped Adams
70%-54% wk1 and is the whole reason D3 called Adams the weakest start. Nacua out ->
Adams is LAR WR1 in a 47.5-total game, D3 flips weak->strong and D1 gets a live
counterargument. Decide Monday, not now.

---

## Retro

*Append after Monday night. Do not edit above this line.*

Fill: `actual` in `2026_week02_myteam.csv`, then per decision — **kill condition
hit? y/n**. Separate "decision wrong" from "outcome bad". Wk1 proved they differ:
Mahomes-over-Stafford was ex-ante correct at 0.35 pts and ex-post worth 17.56.

Filed 2026-09-22. Actuals from `load_player_stats(2026)` + `score_player_week()`,
**14/14 matched to the Yahoo box score to the penny** (DST from Yahoo, unimplemented in R).

**WON 152.58 - 112.08 vs "Sunday Kevin". Record 1-1. Regret 2.50** (Wk1: 19.76).

| decision | call | kill hit? | verdict |
|---|---|---|---|
| D1 Mahomes > Stafford | 28.98 vs 27.98 | **NO** (needed >4) | **right, right reason** |
| D2 Sutton > Odunze | 4.00 vs 5.80 | **YES** — outscored **and** out-snapped | **WRONG by own bar** |
| D3 Adams starts | **35.50**, 65% snaps | **NO** | **right, reason vindicated** |
| D4 hold Etienne | 6.10, opp **10** | **YES** — both legs | **WRONG by own bar** |
| D5 bench Raymond | 6.50; beat Sutton, not Adams | **NO** | **right** |
| D6 accept Dal/Was | Williams 6.50, Ferguson **18.30** | **NO** | **right, hedge held** |

### Reading, per decision

**D1.** Correct on the stated tiebreak. Mahomes' rushing floor showed (17 rush yds).
Margin 1.00 — noise-sized, and the doc said projections were tied. Right call, thin edge.

**D2 — wrong, and the mechanism is the lesson.** Half the thesis held: Sutton's snap
share *persisted* (76% -> 73%), exactly as argued. What was missed is that **Odunze's
role changed** (48% -> **84%**). "Efficiency regresses, snap share persists" was applied
to the wrong player — it predicts Sutton's *usage*, not that his usage beats a receiver
whose usage nearly doubled. Cost **1.80 pts**. Kill fired. Logged wrong, not softened.

**D3 — vindicated by outcome and by mechanism.** Nacua was `Q` Sunday morning and
**played 0 snaps**. Adams -> 10 tgt / 195 yds / 2 TD. The "weakest start in the lineup"
became the best player on either roster. Note the flag was still *correct ex ante*:
54% snap share behind a healthy Nacua is a real risk; Nacua sitting is what removed it.

**D4 — wrong, clean kill.** Etienne opportunity **18 -> 10**. The hold rested on
"opportunity is sticky"; it was not, one week later. NO won 24-17 and he still got 10
touches. **n=2. Do not fit a correction to this.**

**D5 — right call, and the corrected reasoning is what earned it.** The 09-16 addendum
(78-game prior, 8+ targets in 2.6% of career games) predicted regression toward his
career line. He got **5 targets**, 6.50 pts. The withdrawn snap-share argument would
have had him starting. **Right call, right reason — after the correction.**

**Trigger did NOT fire. 6+ targets required, got 5.** Raymond does **not** auto-start
Week 3. Missing by one is still missing. Do not rationalize it.

**D6 — right, and the hedge worked exactly as argued.** Dallas won 37-20. Williams
cratered (6.50) while Ferguson posted **18.30, 2 rec TD**. The pre-registered claim —
"Dal leading -> Williams carries, Dal trailing -> Ferguson targets, partially
self-hedging" — got the direction of one leg wrong but the **hedge property right**:
one script did not sink both. RB+TE stays unflagged. WR+WR stays flagged.

### Regret 2.50

Best legal **155.08** vs started **152.58**. Entire gap is **Sutton 4.00 where Raymond
6.50 belonged** — i.e. D2 and D5 pointed at the same swap, and D2 is the one that cost.
K and DST were forced (one each), so the unimplemented DST scorer does not affect regret.

### Scorecard: 4 right, 2 wrong, and the two wrong cost 2.50 combined

Both kills that fired were **low-cost**. Both decisions that carried real points (D3
Adams, D6 Ferguson) were right. That is the shape you want; do not read it as a system
working yet. **n=2. Fit nothing.**

### Yahoo moved its projections on inactive news. We cannot.

Adams' Yahoo proj went **9.82 (Tue) -> 12.32 (final)** once Nacua was ruled out;
McLaughlin 7.66 -> 8.58. `proj` in the CSV is left at the **Tuesday** value deliberately —
it is the decision-time record. Noting the gap as a capability we lack, not an error.
