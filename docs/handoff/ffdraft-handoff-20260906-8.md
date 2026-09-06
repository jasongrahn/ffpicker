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

## Next session: write the plan, then delegate to haiku agents

Deliverable of next session is **a plan document**, not the implementation.
Implementation gets handed to haiku agents afterward.

### Scope the plan around this, not the tail

Target = replace `ecr`-derived ordering in the censored band with a blended
rank. Not = rescue the 281.

### Gate the plan on one measurement first

Before any ingest target is written, settle: **does blending Sleeper into the
censored band change who the app actually recommends?** Re-run `dev/dryrun.R`
with a patched ordering and diff the 17 picks. If rounds 10-17 name the same
players, the whole project is a no-op and should be dropped. ~30 min. This is
Gate 0 of the plan and it can fail the project.

### Shape for haiku delegation

Haiku agents need bounded, verifiable, independent units. Suggested split —
each one gets its own acceptance test, none needs the others' context:

1. **Ingest target.** `ingest_sleeper_players()` in `R/10_ingest.R` style,
   writes parquet to `data/raw/`, `format = "file"` target in `_targets.R`.
   Cache-respecting — docs say once/day. Acceptance: parquet exists, >11k
   rows, `search_rank` present.
2. **Stage target.** Filter to active skill positions, drop `9999999`
   sentinel, drop retired/no-team, produce `sleeper_rank` keyed on
   `sleeper_id`. Acceptance: no sentinel values survive, no inactive rows.
3. **Crosswalk + blend.** Join to `dim_player$sleeper_id`, blend into
   `draft_pool`. Acceptance: match rate >= 95% of pool, blended order is
   monotone where `ecr` is uncensored.
4. **Tests + validation.** `pointblank` on the new targets, `testthat` file
   matching repo convention.

Blend rule is the one real judgement call — **decide it yourself in the plan,
do not delegate it.** Haiku agents implement, they do not choose the model.

### Non-negotiables to state in the plan

- Config-driven. Any blend weight / censor threshold goes in `config/`, not
  code. CLAUDE.md rule.
- Never join on name. `sleeper_id` only.
- `/caveman` docs style.
- Do not touch the Yahoo export. That thread is closed (#14) and the CSV is
  already imported into Yahoo.

---

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

1. **Write the Sleeper plan.** Gate 0 measurement first, then the 4-unit
   haiku split. ~45 min.
2. Everything else is optional before Tuesday.

`data/yahoo_rankings.csv` printing — **done, user handled it.**

---

## Suggested skills

- **`/prototype`** or **`/to-prd`** — for writing the plan doc itself.
  `/prototype` if Gate 0 is the priority (measure, then decide);
  `/to-prd` if the decision is already made and it needs specifying.
- **`/tdd`** — hand to the haiku agents. Each of the 4 units has a stated
  acceptance test; TDD is the natural fit and keeps haiku bounded.
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
