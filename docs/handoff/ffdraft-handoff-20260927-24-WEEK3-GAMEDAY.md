# ffdraft Handoff #31: Week 3 GAME DAY. One live decision. Do not re-plan the week.

**START HERE -> §1.** Week 3 is **frozen and committed**. Lineup is set, two waiver moves
are executed, every decision is logged with a pre-registered kill condition. The task is
a 5-minute status check, not analysis.

**Local**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: Sun 2026-09-27. **First lock 13:00 ET.**
**Prior**: `20260922-23-WEEK2-RESULTS.md` (#30)
**Git**: branch `week3-picks`, head **`1ff011c`**, tree clean. **Not pushed, no PR.**

Record **1-1**, 4th of 10. Week 3 vs **Maybe Mitchell (2-0, 2nd)**.
Projected **103.99 – 116.94**, Yahoo has us **38% underdog**.

**Do not re-litigate the lineup.** All 16 legal bench swaps were tested; every one loses
points. Reasoning is in `data/weekly/2026_week03_decisions.md`, D1-D7. That file is
frozen above `## Retro` — append only.

---

## 1. THE TASK. Etienne, ~14:55 ET.

**T. Etienne Jr. (RB, New Orleans) is `Q` with a hamstring.** He is our FLEX, projected
**9.68**. NO hosts LV, **Sun 16:25**.

Inactives publish ~90 min before kickoff = **~14:55 ET**.

| if | then |
|---|---|
| Etienne **OUT** | start **R. Odunze** (WR, Chicago) in FLEX |
| Etienne **active** | leave it — `Q` players who dress usually play a normal workload |

**Why this is the whole job:** leaving an inactive player in a slot is the single largest
avoidable loss available this week. Nothing else on the roster is close.

**Why there is time:** Odunze and Raymond play **Mon 20:15**, so they stay swappable until
Etienne kicks off at 16:25. **We get to know before we must decide.** This is the
replacement-deadline rule from `R/42_deadlines.R` paying off for the first time in
real time — Week 2 got it wrong for Adams by 31 hours.

Confirmed `Q` in **both** `yahoo_week3_injuries.csv` and `yahoo_week3_gamedaycalls.csv`
as of 09-23. **Re-check today** — user is reloading these files.

### Everything else is already locked or forced

8 of 9 slots want a decision by **13:00**. Mahomes, Butker and Chiefs all kick at 13:00;
K, DEF and TE have **no bench option at all** (one rostered player each). The only slot
with a live choice after 13:00 is FLEX, and that is Etienne.

Full deadline table -> `2026_week03_decisions.md` §0. Regenerate after any roster move:
```r
source("R/00_config.R"); source("R/42_deadlines.R")
build_slot_deadlines(read.csv("data/weekly/2026_week03_myteam.csv"),
                     nflreadr::load_schedules(2026), load_config("league"), 3)
```

---

## 2. Reloading the injury files. Read this before parsing.

User is dropping fresh exports into `docs/uploads/week_3_data/`. Reader is
`dev/weekly/read_yahoo_week.R`.

```r
source("dev/weekly/read_yahoo_week.R")
z <- attach_nfl_ids(read_yahoo_week("docs/uploads/week_3_data"))
z[z$owner == "JGrahnasaurs", c("player","pos","proj","injury","game")]
```

**Three traps, all silent, all already handled in the reader — do not "simplify" them out:**

1. **Invisible characters in headers.** `"Fantasy Fan Pts"` is really
   `"Fantasy Fan Pts"` — codepoint 57346, a sort-arrow glyph from Yahoo's icon
   font. `d[["Fantasy Fan Pts"]]` returns **NULL, not an error**, so the column reads as
   missing while printing identically to a present one. `ascii_only()` strips it.
2. **`read_yahoo_week()` whitelists the six position files.** A glob over
   `yahoo_week*_*.csv` also swallows `gamedaycalls` and `injuries`, which share the
   prefix but not the schema, and fails as a confusing tibble-recycling error. Already
   fixed once (`b312a3e`); do not regress it.
3. **The stat columns are PROJECTIONS, not actuals.** Decimal TD counts are the tell.

**DO NOT TRUST `yahoo_week3_rosterchanges_injured_reserve.csv`.** 15% of its Sep 23 rows
list the same player as **both** "On" and "Off" IR — including **Mahomes, Adams, Olave,
Kamara**, all demonstrably healthy. Taken at face value it says our starting QB is on
injured reserve. **Use `injuries` + `gamedaycalls`**, which agree with each other and
with `nflreadr::load_injuries()`.

Also: the Yahoo injuries export is **skill-positions only**. For defensive players (e.g.
checking whether the Chiefs DEF is healthy) use `nflreadr::load_injuries(2026)`.

---

## 3. Roster, post-moves. Both waiver claims executed 09-23.

| slot | player | team | proj | kickoff |
|---|---|---|---|---|
| QB | P. Mahomes | KC | 20.90 | Sun 13:00 |
| RB | D. Henry | Bal | 16.99 | Sun 16:25 |
| RB | J. Williams | Dal | 13.32 | Sun 16:25 |
| WR | D. Adams | LAR | 9.89 | Sun 20:20 |
| WR | C. Sutton | Den | 8.81 | Sun 20:20 |
| TE | J. Ferguson | Dal | 7.57 | Sun 16:25 |
| **FLEX** | **T. Etienne Jr.** `Q` | NO | 9.68 | **Sun 16:25** |
| K | **H. Butker** | KC | 9.06 | Sun 13:00 |
| DEF | **Chiefs** | KC | 7.77 | Sun 13:00 |

Bench: Stafford 16.65, Odunze 7.69, Robinson 7.28, Marks 7.16, Gainwell 6.74, Raymond 4.94.
**Dropped:** Patriots DEF, C. McLaughlin (K).

Files: `data/weekly/2026_week03_myteam.csv`, `2026_week03_opponent.csv`. Both sum to
Yahoo's totals to the penny.

---

## 4. What this week is testing. Do not disturb it.

Full version -> `2026_week03_decisions.md` §3. Ranked:

1. **Does streaming K/DST on implied totals work?** D6. Chiefs over Patriots
   (opponent-implied **17.5 vs 24.2**, straddles a scoring tier) and Butker over
   McLaughlin (own-implied **29.0 vs 20.5**). Kill bar is deliberately loose, **>3 pts**,
   because the *method* is on trial, not the players. It repeats for 13 more weeks on two
   otherwise-dead slots — **this is the week's real experiment.**
2. **Does the game-script effect hold out of sample?** Measured on 2024-25, points
   relative to each player's own season average: **RB on a 3-7 pt favorite 1.078x**
   (peak bucket), **RB on a 3-7 pt dog 0.945x**, **WR flat 0.94-1.06 across every
   bucket**, **QB favored 10+ 1.120x**. Live tests: Henry (fav 3.5 AND the slate's
   highest total, 52.5), Mahomes (fav 11.5), Sutton (dog — should NOT matter).
   **Record actual / own-season-average, not raw points.**
3. **Single-game concentration** — §1 kill condition.
4. **Was the `Q` contingency executed?** Process, not outcome. That is §1 of this doc.
5. **Was benching Odunze right twice?** D2 fired against us in Week 2 and he is benched
   again.

**n=3. Fit nothing.**

---

## 5. Head-to-head shape, for the retro

8 of 9 starters sit in 3 games; the opponent has players in 2 of them.

| game | mine | theirs |
|---|---|---|
| BAL @ DAL | Henry + Williams + Ferguson **37.88** | **L. Jackson 22.89** |
| KC @ MIA | Mahomes + Butker + Chiefs **37.73** | — |
| LA @ DEN | Adams + Sutton **18.70** | Rams DEF 5.77 |

Two unplanned hedges: **Henry and their Lamar Jackson are teammates**, so a Baltimore
blowout moves ~38 of ours and ~23 of theirs in partly offsetting directions. And
**Sutton is directly opposed to their Rams DEF** — Denver passing well *is* the Rams
defense failing.

**KC @ MIA is the unhedged bet.** 37.73 of ours, none of theirs.

**Margin variance is therefore lower than either roster's standalone variance implies.
A close final score is NOT evidence the projections were sharp.**

---

## 6. After the games — Monday or later, NOT today

1. Fill `actual` in `2026_week03_myteam.csv` **and** `2026_week03_opponent.csv`.
   Score with `score_player_week()`; it is validated **26/26** across weeks 1-2.
   **DST must be read off Yahoo** — still unimplemented in R, and it now sits on a slot
   we actively manage.
2. Fill the `## Retro` table in `2026_week03_decisions.md`. **Append only.** Separate
   "decision wrong" from "outcome bad".
3. `regret = best legal lineup - started`; add a row to `data/weekly/README.md`
   `## Cases so far`. Week 1 regret 19.76, Week 2 **2.50**.
4. First week the opponent's lineup was logged pre-kickoff -> **projection error is
   measurable on both sides** against the same Yahoo model. Two weeks of our own error
   cannot separate "Yahoo is biased" from "we got unlucky".

---

## 7. Carried

- **Branch `week3-picks` is 4 commits ahead of `main`, not pushed, no PR.** Push when
  convenient; nothing blocks on it.
- **`renv` out of sync** — `devtools` not installed, `devtools::load_all()` FAILS.
  Workaround in use: `source()` the `R/*.R` files directly. Run `renv::status()`.
- **DST unscored in R.** `score_player_week()` is per-player by design. Worth **21.00 in
  Week 2, 14% of the winning total.** Needs a team-level source that does not exist yet.
- **`load_ff_playerids()` `yahoo_id` collapses by draft class**: 2022 85.6%, 2023 75.4%,
  2024 32.3%, **2025 0.3%, 2026 0%**. `attach_nfl_ids()` already falls back to name and
  records which key was used in `method`. Do not "fix" it to id-only — that silently
  drops every rookie.
- **Yahoo API still parked.** Applied 09-16, no SLA. Weekly 5-second check:
  `source("dev/yahoo/auth_probe.R"); yahoo_open_consent("fspt-r")` -> `invalid_scope`
  means still pending. Do not re-probe beyond that one line.
- `to-prd` on the weekly picker — queued since #21, still not done.
- Stale branches `token-tooling-audit`, `vona-experiments-closed` — merge status unknown.

---

## 8. Suggested skills

- **`caveman`** — repo doc rule, any doc written
- **`handoff`** / **`session-close`** — write to `docs/handoff/`, **not `/tmp`**
  (`docs/handoff/README.md` overrides the skill default)
- **`to-prd`** — the weekly picker, if Sunday finishes early. Do NOT let it block §1.
- **`claude-md-management:revise-claude-md`** — only if new *durable* patterns emerge.
  CLAUDE.md was refreshed 09-22 and again 09-23; it is current.

---

## 9. Read order

1. This doc, §1. That is the task.
2. `data/weekly/2026_week03_decisions.md` — §0 deadlines, D1-D7, §3 what we are learning.
3. `CLAUDE.md` — league facts, scoring, football primer, the Yahoo-export gotchas.
   **Assume the user knows football casually. Name team and role when naming a player.**

Do not read `docs/handoff/drafting/`. Draft phase closed.
