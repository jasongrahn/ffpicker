# ffdraft — Handoff #16: Sleeper evaluated. Verdict NO. Thread closed.

**Repo**: `https://github.com/jasongrahn/ffpicker`
**Local**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: 2026-09-06
**Draft**: Tuesday, Sept 8, 2026, 6:00pm ET — **~2 days out**
**Prior**: `docs/handoff/ffdraft-handoff-20260906-8.md` (#15)
**Git**: `main`, clean. 464 tests pass. Nothing entered `_targets.R`.

---

## Verdict: REJECT Sleeper. Do not re-investigate.

Evaluated per #15's four criteria. Bars set **before** measuring, written to
`dev/sleeper/PLAN.md` first, not moved after.

| Criterion | Bar | Measured | |
|---|---|---|---|
| C1 Coverage | >=90% pool, >=100 tail | 84.8% (621/732), 160 tail | **FAIL** |
| C2 Signal | tail \|rho\| >=0.25, >=2x ECR | -0.314 vs ECR -0.104 (3.0x) | PASS |
| C3 Independence | partial \|rho\| >=0.15; tail rho(rank,ecr) <0.85 | -0.416; 0.166 | PASS |
| C4 Actionability | >=3 of 17 picks change | **0 of 17. 0.0 starter pts.** | **FAIL** |

Rule was: any FAIL -> NO. C4 fails decisively. Verdict NO.

## Why it fails — structural, not marginal

**My 17 picks bottom out at `ecr` 219.** Sleeper's entire measured edge lives in
`ecr > 290`. 10 teams x 17 rounds = 170 players leave the board. That band is never
reached. Reordering all 160 matched tail players by `search_rank` changed **zero**
picks and zero starter points.

**#15's premise was wrong.** It called the 290-413 band "rounds 10-17 territory."
At 10 teams rounds 10-17 are picks 91-170 -> `ecr` ~90-220. The band is past the
end of the draft, not in its late rounds. Signal there is real and useless.

## What was NOT wrong — record this, it was the open question

`search_rank` is **not** re-derived FantasyPros consensus. C3 passed clean:
- HEAD (`ecr<=290`): rho(search_rank, ecr) = **0.938** -> redundant with ECR here.
- TAIL (`ecr>290`): rho(search_rank, ecr) = **0.166** -> genuinely independent.
- Partial rho(search_rank, ppg | ecr) in HEAD = **-0.416**, n=247.

So it carries independent, predictive information. Independence was the suspected
killer. It was not. Actionability was.

## Full correlation table (2025 PPG, Spearman)

| Region | n_ecr | ECR vs PPG | n_search | Sleeper vs PPG |
|---|---|---|---|---|
| HEAD (`ecr<=290`) | 250 | -0.689 | 247 | -0.754 |
| TAIL (`ecr>290`, overall) | 139 | -0.104 | 122 | -0.314 |
| `ecr_source == "position"` | 161 | -0.177 | 122 | **+0.092** |

Row 3 confirms #15: Sleeper does nothing for the 254 position-added players, wrong
sign. Row 2 replicates #15's finding at weaker magnitude (ECR -0.104 here, not
-0.014 — ECR is not statistically dead in the band, only weak).

## Coverage detail (C1)

Raw `sleeper_id` match is 98%, as #15 reported. Cleaning drops it to 84.8%:
sentinel `9999999`, `active != TRUE`, and missing team remove 111 matched pool
players. `/v1/players/nfl` -> 12,226 rows -> 804 after cleaning.
By source: overall 93.1% (445/478), position-added 69.3% (176/254).
No DST rows exist in `draft_pool`, so DST does not explain the gap.

**Bar self-critique:** C1 was badly drawn — measuring coverage across the whole
pool counts the HEAD, where ECR is already good and Sleeper coverage is irrelevant.
Recorded as written rather than redrawn post-hoc. Moot anyway; C4 decides.

## Reproduce

`dev/sleeper/` — throwaway harness, four scripts, run in order from repo root.
`01_fetch.R` caches to `dev/sleeper/cache/` and will not re-hit the network within
24h (Sleeper docs: one call/day max). `04a_actionability.R` is the one that matters.

## Access facts (unchanged from #15, kept so nobody re-probes)

Read-only HTTP, no token, free non-commercial, <1000 calls/min. Terms clean.
Nothing about Sleeper conflicts with CLAUDE.md's Yahoo constraint. Access was never
the problem. Usefulness was.

## What this does NOT close

`/v1/players/nfl/trending/add` — 24h adds/drops. Still unprobed. Different signal
(market movement, not search popularity) aimed at a different gap (what the nine
opponents will do). This verdict is about `search_rank` only. Not a
recommendation to probe it 2 days before the draft.

## Known gaps (carried forward from #15)

- **Yahoo ADP unconsumed.** `parse_yahoo_names()` returns `xrank`/`adp`. Nothing reads it.
- **`ecr_source == "position"` rows carry an ordering key, not a rank.** Nothing in UI says so.
- **`max_at_position` values are judgement, not measurement.**
- **DST scoring unconsumed** in `score_player_week()`.

## Do next

Nothing required. Sleeper was the last open item with real upside and it closed
negative. Everything else is optional before Tuesday.
