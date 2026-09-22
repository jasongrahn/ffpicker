# ffdraft Handoff #30: Week 2 results. Retro owed. One template bug found.

**START HERE -> §2.** Week 2 done. Task is the retro, and it is mostly *transcription* —
numbers below are already computed and verified. Yahoo API still parked, §7 is a stub.

**Local**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: 2026-09-22 (Tue). Week 3 opens Thu 09-24.
**Prior**: `20260916-22-WEEK2-PICKS.md` (#29)
**Git**: branch `week1-roster-handoff`, head **`e150de6`**. **Tree dirty — see §6.**

**Week 2 WON, 152.58 - 112.08 vs "Sunday Kevin". Record 1-1, 4th of 10.**

---

## 1. Week 2 actuals. Verified, not estimated.

Pulled `load_player_stats(2026)` wk2 (1107 rows), scored with `score_player_week()`
+ `load_config("scoring")`. Not Yahoo-transcribed. K included; **DST excluded — still
unimplemented** (`R/30_scoring.R` roxygen says so on purpose).

### Starters

| slot | player | proj | actual | d |
|---|---|---|---|---|
| WR | **D. Adams** (LAR) | 9.82 | **35.50** | **+25.68** |
| K | C. McLaughlin (TB) | 7.66 | **16.00** | +8.34 |
| QB | P. Mahomes (KC) | 18.47 | 28.98 | +10.51 |
| TE | J. Ferguson (Dal) | 7.70 | 18.30 | +10.60 |
| RB | D. Henry (Bal) | 15.99 | 16.20 | +0.21 |
| RB | J. Williams (Dal) | 15.25 | 6.50 | -8.75 |
| FLEX | T. Etienne (NO) | 10.01 | 6.10 | -3.91 |
| WR | C. Sutton (Den) | 9.36 | 4.00 | -5.36 |
| DEF | Patriots | 6.84 | **21.00** | +14.16 |

**TOTAL 152.58** vs 104.79 final proj. **+47.8.**

Adams: 10 tgt, 8 rec, **195 yds, 2 TD**. McLaughlin: 4 FG incl **59-yarder**, in the
"rain game" that got called fine on market proxy. Patriots: 1 TD, 4 sack, 1-6 allowed.

### Bench

| player | proj | actual |
|---|---|---|
| M. Stafford | 18.10 | **27.98** |
| K. Raymond | 3.47 | 6.50 |
| W. Marks | 7.44 | 6.00 |
| R. Odunze | 8.64 | 5.80 |
| K. Gainwell | 8.01 | 3.00 |
| W. Robinson | 6.96 | 1.40 |

### Regret = **2.50**

Best legal **155.08** vs started **152.58**. Entire gap = Sutton 4.00 where Raymond 6.50
belonged. Wk1 regret was 19.76. **Down ~8x.**

Optimal lineup was: Mahomes / Henry + J.Williams / Adams + **Raymond** / Ferguson /
Etienne FLEX / McLaughlin / Patriots. K and DST were forced (one each), so regret is
unaffected by the DST gap. Mahomes-over-Stafford was **correct** — 28.98 vs 27.98.

### Scoring validated 26/26 across two weeks

Every one of the 14 rostered players matched the Yahoo box score **to the penny**,
starters and bench. Wk1 was 12/12; this is 14/14 more, and it now covers a **2-point
conversion** (Etienne) and a **4-FG kicker line incl. a 59-yarder** (McLaughlin).

`score_player_week()` is trustworthy. **Stop re-validating it. DST is the only gap** —
worth **21.00** this week, **14% of the winning total**. Promote it out of §7.

### Yahoo revised Adams UP on the Nacua news. We did not.

Frozen Tue proj **9.82**; Yahoo's final was **12.32** (+2.50) once Nacua was ruled out.
McLaughlin likewise 7.66 -> 8.58. **`proj` in the CSV stays the Tue value on purpose** —
it is the decision-time record, and overwriting it destroys what D1-D6 were judged on.
Worth knowing that Yahoo's projections *do* move on inactive news within the day; ours
have no mechanism to.

---

## 2. THE TASK. Retro. Kill conditions already evaluated.

Fill `## Retro` in `data/weekly/2026_week02_decisions.md`. Table is stubbed there.
**Do not re-derive — copy this.** Every condition scored against pre-registered text.

| # | call | kill condition | hit? | verdict |
|---|---|---|---|---|
| D1 | Mahomes > Stafford | Stafford by >4 | **NO** (+1.00 Mahomes) | **right, right reason** |
| D2 | Sutton > Odunze | Odunze outscores **AND** out-snaps | **YES** | **wrong, by own bar** |
| D3 | Adams starts | <8.0 **AND** snaps <60% | **NO** (35.50, 65%) | **right, reason vindicated** |
| D4 | hold Etienne | <7.0 **AND** opp <12 | **YES** (6.10, opp **10**) | **wrong, by own bar** |
| D5 | bench Raymond | beats Sutton **AND** Adams | **NO** (beat Sutton only) | **right** |
| D6 | accept Dal/Was | **both** under 60% proj | **NO** | **right, hedge held** |

### D2 — kill fired, and the mechanism matters

| | snap % wk1 | snap % wk2 | wk2 pts |
|---|---|---|---|
| Sutton | 76% | **73%** | 4.00 |
| Odunze | 48% | **84%** | 5.80 |

Half the thesis held: Sutton's snap share *did* persist (76 -> 73). Thesis missed that
**Odunze's role changed** (48 -> 84). Cost only **1.80 pts**, but the bar fired, so log it
as wrong. That is what pre-registration is for. Do not soften it.

### D4 — kill fired clean

Etienne opportunity **18 -> 10**. Both legs hit. Thesis was "opportunity is sticky";
it was not, one week later. **n=2. Do not fit a correction.** Record and move on.

### D3 — the one to keep

Nacua (LAR WR1) was `Q` Sun morning, **played 0 snaps** (`load_player_stats` wk2:
0 rows). Adams -> 10 tgt / 195 yds / 2 TD. The Sunday read — "Nacua out -> Adams is
WR1, D3 flips weak to strong" — is confirmed by outcome **and** by mechanism.

### D5 — trigger did NOT fire. Honor it.

Pre-committed: **6+ targets -> Raymond starts Week 3.** He got **5**. Missed by one.
Raymond does **not** auto-start. The 09-16 addendum (78-game prior, 2.6% of games at 8+
targets) predicted exactly this. **Do not rationalize the near-miss into a start.**

---

## 3. The "24% underdog" was an artifact. Read this before trusting a live win prob.

**WON 152.58 - 112.08.** Kevin's final was **112.08** against a 108.89 proj — he scored
roughly to projection. We beat ours by **+47.8**.

Sun 11:30am state: Kevin live proj **127.07**, us **101.15**, Yahoo **76/24 favorite** to
Kevin. That 127.07 was **never a forecast**. It was 51.10 already banked Thursday
(A. St. Brown 30.70 on a 14.98 proj; J. Cook 20.40 on 16.71) plus 75.97 still projected.
Yahoo carries overperformance forward as if it were expectation.

Correct read at the time, and it held: on *remaining* players we projected **+25.18**
over him. His two Thursday overperformers were **done scoring**; ours had not played.

**Generalizes.** A Yahoo live win probability mid-week is not a forecast of the rest of
the matchup — it is banked points plus a stale projection, and it is most misleading
exactly when the opponent's early players spiked. Compute **remaining-vs-remaining**
instead. One subtraction. It inverted the conclusion here.

---

## 4. Template bug. Fix before Week 3. Highest-value item here.

`## Lock order` in the decisions file lists a player's **own** kickoff. That is not the
deadline. **The deadline is the earliest kickoff among that player's legal replacements.**

Week 2 case: doc said "Adams + Stafford Monday = free options. D1 and D3 stay live all
weekend." **True for D1, false for D3.** Adams locked Mon 8:15pm, but every WR who could
replace him (Odunze / Robinson / Raymond) kicked **Sun 1:00pm**. D3 was really decided at
**Sun 1:00pm**, ~31h earlier than the doc claimed.

Cost nothing this week — Adams was the right start and went 35.50. Next time it will.

**Fix**: Week 3 decision doc gets a `decide_by` column = `min(kickoff of legal
replacements)`, not the starter's own kickoff. Trivially derivable from
`load_schedules()` + roster positions. Worth ~20 min of code in `dev/weekly/`.

---

## 5. Two data traps, both cost time this session

1. **`Kenny Gainwell`, not `Kenneth`.** `load_player_stats()` uses `Kenny`; our CSV says
   `Kenneth`. Silent `NA` on a `right_join`, not an error. Generalizes to the whole
   weekly layer — **CLAUDE.md already bans name-joins**; this is that rule collecting.
   Roster CSV has no id column. Adding `gsis_id` would kill the class.
2. **A Yahoo `O` is a state, not an event.** Yahoo listed Mixon (RB Hou) OUT Sunday;
   read as "Marks promoted to lead back" -> **wrong**. Mixon did not play wk1 either;
   lead back is D. Montgomery, healthy, unlisted. Diffing the designation against wk1
   usage is what separates standing absence from news. Full writeup already in
   `2026_week02_decisions.md` `## Sunday 11:30am check`. **Would have been a bad start
   recommendation without the snap-count check.**

Also closed there: `load_schedules()` `temp`/`wind` are **NA for all unplayed games**,
backfill post-game only. **Not a `dev/weekly/week2_game_env.R` bug. Do not debug it.**

---

## 6. Git. Dirty tree, nothing committed this session.

```
M  data/weekly/README.md
M  data/weekly/2026_week02_decisions.md   <- Sunday check appended
?? data/weekly/2026_week02_myteam.csv     <- actual column STILL EMPTY
?? dev/weekly/
?? docs/uploads/week_2_data/
```

**`actual` column in `2026_week02_myteam.csv` is unfilled.** §1 has every number.
`proj` column is also still Tuesday-frozen; live values in §1 differ (Stafford 18.22 ->
18.10 etc). Fill both, then commit the week as one unit.

Nothing pushed. Branch `week1-roster-handoff` is 5+ commits ahead, no PR.

---

## 7. Carried, still unfixed

- **`CLAUDE.md` stale, 2 places. Open since #24, now 4 handoffs old.** `## Current
  status` says "Nothing built yet, next action Phase 0" — badly false, draft engine
  shipped and two weeks are played. League block says 17 rounds; real is **15**.
  **5 min job. Do it this session.**
- `docs/backlog/README.md:8` — "No Yahoo ranking data exists in the repo." Superseded
  2026-09-06.
- **Yahoo API: parked, no change.** Applied 2026-09-16, human review, no SLA.
  Weekly 5-second check: `source("dev/yahoo/auth_probe.R"); yahoo_open_consent("fspt-r")`
  -> `invalid_scope` = still pending. **Do not re-probe beyond that one line.**
- `renv` **out of sync** — `devtools` not installed, `devtools::load_all()` fails.
  Worked around by `source()`-ing `R/00_config.R` + `R/30_scoring.R` directly. Run
  `renv::status()`.
- **DST unscored in R.** `score_player_week()` is per-player by design. Every weekly
  total is therefore `+ DST` short. Config has the tiers (`config/scoring.json`); the
  team-level stat source does not exist yet.
- Dead, do not revive: VONA as selector, ESPN / `ffscrapr` / Sleeper `search_rank`.
- `to-prd` on the weekly picker — queued since #21, **still not done**.

---

## 8. Suggested skills

- **`caveman`** — repo doc rule, any doc written
- **`claude-md-management:revise-claude-md`** — §7 first bullet, the 4-handoff-old stale
  block. Cheapest real win available.
- **`to-prd`** — scope the weekly picker. Queued 4 sessions. Week 3 is not urgent until
  Thu 09-24, so there is room now.
- **`handoff`** / **`session-close`** — write **here**, not `/tmp`
  (`docs/handoff/README.md` overrides the skill default)

---

## 9. Read order for a cold start

1. This doc, §2.
2. `data/weekly/2026_week02_decisions.md` — D1-D6 + the appended Sunday check.
3. `data/weekly/README.md` — regret metric, Wk1 case.
4. `CLAUDE.md` — league facts, scoring, football primer. **User knows football casually.
   Name team and role when naming a player.**

Do not read `docs/handoff/drafting/`. Draft phase closed.
