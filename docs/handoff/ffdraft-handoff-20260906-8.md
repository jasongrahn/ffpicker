# ffdraft — Handoff #15: draft_pool unioned; Sleeper ranks probed and validated

**Repo**: `https://github.com/jasongrahn/ffpicker`
**Local**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: 2026-09-06
**Draft**: Tuesday, Sept 8, 2026, 6:00pm ET — **~2 days out**
**Prior**: `docs/handoff/ffdraft-handoff-20260906-7.md` (#14)
**Git**: `main`, clean at `5375525`. 464 tests pass (was 443).

---

## Shipped: position pages unioned into `draft_pool`

Commit `5375525`. Code + rationale in `R/60_draft_pool.R` roxygen, tests in
`tests/testthat/test-draft_pool.R`. Not repeated here.

Board **478 -> 732**. Dry run unchanged (568.5 starter pts, 17/17).

One thing worth carrying: translating position rank onto overall ECR scale
was tried and **abandoned**. `redraft-overall` ECR is censored near its
cutoff -> fitted map goes flat exactly where these players live -> dozens
collapse onto one `ecr`, several get `sd` 0. So added players are *placed*,
not translated. Their `ecr` is ordering key, not expert rank. New
`ecr_source` column marks them (`"overall"` / `"position"`).

---

## Sleeper: probed live, terms clean, premise VALIDATED

Docs: `https://docs.sleeper.com/#players` (user-supplied).

### Access — no Yahoo-style gate

Read-only HTTP. **No API token.** Free for non-commercial. Stay under 1000
calls/min. `/v1/players/nfl` is ~14MB, docs say call **once per day at most**.
Supports `?position=QB&active=true` filters. Nothing here conflicts with
CLAUDE.md's Yahoo constraint — that constraint is about Yahoo, not a blanket
rule.

Verified live 2026-09-06:
```
curl -s https://api.sleeper.app/v1/players/nfl   # HTTP 200, 14,651,642 bytes, 0.86s
```
12,226 players. Crosswalk already exists: `dim_player$sleeper_id`, 6188 of
7997 non-NA. **Pool match rate 714/732 (98%)** — 474/478 overall, 240/254
position-added.

### What `search_rank` is — and is not

Not a fantasy rank. It is a **search-autocomplete popularity rank**. Evidence:
ties (`Ja'Marr Chase` = 3 *and* `Josh Allen` = 3), and the 295-300 band mixes
retired players (Jared Cook, Mike Williams, Bennie Fowler, Kadarius Toney).
1949 skill-position players carry a real rank, 738 distinct values, max 2015,
429 ranks reused. Sentinel for "unranked" is `9999999` — filter it.

Despite that, it carries real signal. See below.

### The tiebreaker test — this is the finding that matters

Question: in the region where FantasyPros ECR is censored, is Sleeper signal
or is it also noise? Answer by correlating each against **actual 2025 PPG**
from `fct_player_week_scored`. Spearman:

| Region | n | ECR vs PPG | Sleeper vs PPG |
|---|---|---|---|
| Uncensored (`ecr` <= 290) | 256 | -0.602 | **-0.672** |
| **Censored (`ecr` > 290)** | 149 | **-0.014** | **-0.354** |
| The 254 position-added | 191 | -0.048 | +0.065 |

Read rows 2 and 3 together — they say different things.

**Row 2 is the win.** In the 290-413 band FantasyPros ECR is *statistically
dead* (-0.014, indistinguishable from zero) and Sleeper carries real signal
(-0.354). That band is ~149-185 players who are genuinely draftable — rounds
10-17 territory, exactly where a 17-round draft spends half its picks.

**Row 3 kills the original motivation.** For the 254 players the last session
added, Sleeper does *not* order them by production either (+0.065, wrong
sign). Caveat: their PPG is itself near-noise — deep bench, tiny game samples
— so this is weak evidence, not proof of no value. Either way: **do not sell
this project as "fixes the 281 tail." It does not.** It fixes the *censored
band of the ranked board*, which is a bigger and more valuable target.

Row 1 caveat, do not overclaim: correlating against 2025 *actual* PPG
structurally favours backward-looking measures. ECR is forward-looking for
2026. Row 1 is **not** proof Sleeper beats ECR for drafting. Row 2 survives
that objection because there ECR scores ~zero, not merely lower.

### Bonus endpoint, unprobed

`/v1/players/nfl/trending/add?lookback_hours=24&limit=25` — adds/drops in
last 24h. That is a **market** signal, arguably closer to CLAUDE.md's named
blind spot (Yahoo ADP / what the nine opponents will do) than `search_rank`
is. Requires attribution to Sleeper per docs. Not tested. Flagged, not scoped.

---

## Next session: plan an EVALUATION of Sleeper, then delegate to haiku agents

**Goal is a verdict, not an integration.** Question on the table: *is Sleeper
data a sufficient supplement to what we already have?* Plan and implementation
both serve that question. Adoption is what happens **if** the evaluation
passes — it is not the premise.

This matters because the probe above already moved once. It started as "fix
the 281 tail," measured out as "does nothing for the tail, beats a dead ECR in
the 290-413 band." It can move again. Do not write a plan that can only
conclude yes.

### What "sufficient supplement" has to mean, concretely

Four criteria. Plan must state a pass/fail bar for each **before** measuring,
or the result is post-hoc.

1. **Coverage** — does it reach players our data misses or mis-ranks?
   *Already measured: 714/732 pool match (98%), 1949 skill players ranked vs
   FantasyPros' censored ~525.* Provisionally passes.
2. **Signal** — does it predict production better than what we hold, and
   where? *Already measured, table above. Passes in the censored band,
   fails on the 281.*
3. **Independence** — is `search_rank` new information, or is it re-deriving
   the same consensus FantasyPros already sold us? **Not measured. Open.**
   A popularity rank downstream of the same expert chatter adds nothing even
   when it correlates. Test: partial correlation of Sleeper with PPG
   controlling for ECR, inside the uncensored band where both are alive.
4. **Actionability** — does any of it change a pick? **Not measured. Open,
   and decisive.** Criteria 1-3 can all pass and the answer still be no.

Criteria 3 and 4 are the session's real work. 1 and 2 are largely done.

### Actionability is the gate that can end the project

Patch `dev/dryrun.R`'s ordering with a Sleeper-informed rank and diff the 17
picks against the current run. If rounds 10-17 name the same players, Sleeper
is a measurement that changes no decision -> **write that verdict and stop.**
~30 min. A clean negative here is a successful session, not a failed one.

Run this early. It is cheap and it can save the other three.

### Shape for haiku delegation

Haiku builds the **evaluation harness**, throwaway-tolerant, not production
targets wired into `_targets.R`. Keep it in `dev/`. Each unit bounded,
verifiable, independent:

1. **Fetch + flatten.** `dev/sleeper_probe.R` — pull `/v1/players/nfl`, cache
   to disk (docs: once/day), flatten `player_id`, `full_name`, `position`,
   `team`, `search_rank`, `active` to a data frame. Acceptance: >11k rows,
   re-run hits cache not network.
2. **Clean.** Drop `9999999` sentinel, inactive, no-team, non-skill positions.
   Acceptance: no sentinel survives, no inactive rows, row count reported.
3. **Crosswalk + join.** To `dim_player$sleeper_id` and `draft_pool`. Emit
   the match-rate table split by `ecr_source`. Acceptance: match rate printed,
   no name-based joins anywhere.
4. **Measurement script.** Criteria 3 and 4 above. Emits the correlation
   table, the partial correlation, and the 17-pick diff. Acceptance: runs
   end to end, prints numbers, asserts nothing.

Unit 4 **reports**; it must not decide. You read its output and write the
verdict.

### Decide these yourself, do not delegate

- The pass/fail bar for each of the four criteria. Set before measuring.
- Any blend rule, **if** the evaluation passes. Haiku implements a model, it
  does not choose one.

### Non-negotiables to state in the plan

- Evaluation code lives in `dev/`. Nothing enters `_targets.R` until the
  verdict is yes. Do not grow `draft_pool` on spec.
- Never join on name. `sleeper_id` only.
- If it passes and gets adopted, thresholds and weights go in `config/`, not
  code. CLAUDE.md rule.
- `/caveman` docs style.
- Do not touch the Yahoo export. Closed in #14, CSV already imported.

### Possible verdicts — all three are acceptable outcomes

- **Adopt.** Passes all four -> write the integration plan.
- **Adopt narrowly.** Passes only in the censored band -> use it only there,
  say so explicitly, leave the rest of the board alone. *Current evidence
  points here.*
- **Reject.** Fails independence or actionability -> record the numbers in a
  handoff so nobody re-investigates. Same closure Yahoo and `ffscrapr` got in
  CLAUDE.md.

## Reproduce the numbers above

Probe artifacts lived in session scratchpad — gone now. Regenerate:

```bash
curl -s https://api.sleeper.app/v1/players/nfl -o sleeper_players.json
```
Then flatten `player_id`, `full_name`, `position`, `team`, `search_rank`,
`active` to CSV, drop `search_rank >= 9999999`, join to
`targets::tar_read(dim_player)` on `sleeper_id`, and correlate against
per-`player_key` mean `fantasy_points` from
`targets::tar_read(fct_player_week_scored)`.

---

## Known gaps

- **Sleeper unbuilt.** Above. Only open item with real upside.
- **`ecr_source == "position"` rows carry an ordering key, not a rank.**
  By design, documented, but nothing in the UI says so.
- **Yahoo ADP unconsumed.** `parse_yahoo_names()` returns `xrank`/`adp` for
  300 paste players. Nothing reads it. Sleeper `trending` may be a better
  fill for the same gap.
- **`max_at_position` values are judgement, not measurement.**
- **DST scoring unconsumed** by `score_player_week()`.

---

## Do next

1. **Write the Sleeper evaluation plan.** Set the four pass/fail bars, then
   the 4-unit haiku harness. Run actionability early — it can end it. ~45 min.
2. Everything else is optional before Tuesday.

`data/yahoo_rankings.csv` printing — **done, user handled it.**

---

## Suggested skills

- **`/prototype`** — right fit. This is a throwaway harness answering a
  yes/no, not a product. Prefer over `/to-prd`; nothing is being specified
  for build yet.
- **`/diagnose`** — if the measurements come back contradictory.
- **`/tdd`** — hand to the haiku agents for units 1-3, which have real
  acceptance tests. **Not** unit 4: a measurement script asserts nothing, and
  TDD on it invites fitting the test to the hoped-for answer.
- **`/caveman`** — repo doc style, required by CLAUDE.md.
- **`verify` agent** — runs suite + targets pipeline, reports pass/fail
  without dumping R console output into context. Use after each haiku unit.
- **`/handoff`** — at session end.
- **`/session-close`** — if wrapping the project rather than continuing.

Skip `/code-review` until all 4 units land; reviewing them piecemeal wastes
the diff.

---

## Draft-night facts (carried from #14, unchanged)

- Draft room opens **30 min before** 6:00pm ET Tuesday. Team names and draft
  order visible there — `my_slot` in `league.json` stays null until then, and
  is entered in the app's setup screen, not the config file.
- 1-minute pick clock.
- Relaunch the app with `dev/relaunch.sh`.
- `data/yahoo_rankings.csv` already imported into Yahoo cleanly.
