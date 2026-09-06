# ffdraft — Build Plan

Local fantasy football draft engine in R. Objective function is **P(championship)**,
not projected points. Read `CLAUDE.md` first for league facts and constraints.

---

## Timeline

**Draft is Tuesday, Sept 8, 2026, 6:00pm ET** — the night before the 2026 NFL season
opens (Wednesday, Sept 9).

Phases 0-3.5 are the draft-usable path and require nothing from the organizer beyond
league settings. Phases 4+ are the interesting part and do not have to ship before Week 1.

---

## Phase 0 — Verification and scaffold (0.5 day)

**Verify before building.** Every data claim below is from documentation and unconfirmed
against a live R session:

- Does `load_ff_rankings(type = "draft")` return 2026 ADP right now? What columns?
- Does `load_player_stats()` have 2026 preseason rows, or does it start at Week 1?
- Does `load_ff_playerids()` join cleanly to `load_players()` on `gsis_id`?
- Are `load_ff_opportunity()` model versions current for 2026?
- Does `load_depth_charts()` reflect post-preseason roster cuts?

Then: `renv` init, DESCRIPTION, `config/` + JSON Schemas, DuckDB, `targets` stub.

**Config validation harness.** Build and test the `jsonvalidate` check against
`config/schema/*.schema.json` before any model code depends on config. Confirm it fails
loudly on a bad `league.json` (missing keys, wrong types, `teams`/`my_slot` null is valid,
everything else is not). This is the "validate config early" rule from `CLAUDE.md` made
concrete — it must exist as a runnable check, not just a stated principle.

## Phase 1 — Data spine (1-2 days)

Ingest to parquet, build the ID crosswalk, `dim_player` with a surrogate key,
`fct_player_week` back to ~2015. `pointblank` validation on every table.

The crosswalk is the hardest plumbing in the project. `gsis_id` != `sleeper_id` !=
`espn_id` != `fantasypros_id`, names collide, rookies appear in one source before another.

### Sources (all free, CC-BY, no keys)

| Function | Content |
|---|---|
| `load_player_stats()` | Weekly box scores, 1999+ |
| `load_pbp()` | Play-by-play, ~370 cols/play |
| `load_snap_counts()`, `load_depth_charts()` | Usage and role |
| `load_nextgen_stats()`, `load_pfr_advstats()`, `load_ftn_charting()` | Separation, air yards, routes |
| `load_injuries()`, `load_rosters()`, `load_schedules()` | Availability, byes |
| `load_ff_rankings(type="draft")` | FantasyPros ECR + ADP, weekly refresh |
| `load_ff_playerids()` | Cross-platform ID crosswalk |
| `load_ff_opportunity()` | Pre-computed expected fantasy points |

## Phase 2 — Scoring engine (0.5 day)

Pure vectorized function: stat line x scoring config -> points. Golden-tested against
known box scores.

The payoff is bigger than convenience: this lets you recompute **every historical season
under your exact league rules**, so training data matches the objective. Most public
tools train on generic PPR and hand you numbers subtly wrong for your league.

## Phase 3 — Draft board v0 (1 day)

ECR + ADP + your scoring -> VOR board with dynamic replacement level. **This is the
minimum draft-usable artifact** and already beats most of a company league.

## Phase 3.5 — Draft-day kit (1 day)

Because live Yahoo sync may never exist and the pick clock is short:

- Tiered cheat sheet, PDF-exportable, sorted by VOR under actual scoring
- Minimal local app that records each pick **as (team, player)**, not just "gone" — every
  pick assigns to a draft slot, not just off the board, so opponent rosters build live
- One-line plain-English note per player (the user is reading unfamiliar names on a clock)

Scannability beats precision here.

**Why (team, player) and not just (player):** Phase 6's opponent model (L8) needs each
rival's current roster to compute positional need in real time (softmax over ADP weighted
by need). If picks are only marked "unavailable," that model has no live input and degrades
to pure ADP — losing the edge that comes from knowing a company league drafter chasing a
positional run. This makes per-team pick capture a Phase 3.5 requirement, not a Phase 6
nice-to-have, even though the opponent model itself doesn't ship until later.

**Resolved via `grill-with-docs`, 2026-09-05** (see `CONTEXT.md` for Pick / Pick Log /
Draft Pool / Draft Board definitions, `docs/adr/0001-event-sourced-pick-log.md` for the
storage-format rationale):

- Builds as pane 1 (Board) of the eventual `inst/app/` Phase 7 app, not a disposable
  separate tool. No Recommendation or Learn pane yet — those need L8/L3, which don't exist.
- Pick entry: click a row on the Board (opens a team picker), **or** a search box as a
  fallback for off-board/hard-to-find names. Search draws from the full Draft Pool
  (including unranked rookies), not just the ranked Board.
- Opponent team names are lazy-created (renamed from a placeholder on each team's first
  pick) — real names aren't known until Yahoo's draft-order reveal Tuesday. Your own team
  name ("JGrahnasaurs") and `my_slot` are entered once at session start instead, since
  both are already known.
- `my_slot` entry also drives an always-visible "picks until your turn" readout, computed
  from the snake-turn formula already in `CLAUDE.md`.
- Every pick is a `.jsonl`-appended event (`pick_made` / `pick_corrected` / `draft_started`)
  — an append-only log, never a mutated row, so a crash loses at most one in-flight write
  and a mis-entry never destroys history. One undo control, **last pick only**.
- The Board fully recomputes (VOR + tiers) on every logged pick — staleness under a
  1-minute clock is worse than a full recompute of ~500 rows.
- Tiers are gap-based (a `diff()`-and-threshold cut in sorted VOR), not fixed-size —
  fixed-size cuts can split a genuinely tight cluster or hide a real cliff.
- Players with an ECR but no current-season production (`has_current_data = FALSE`,
  mostly 2026 rookies — see `R/75_value.R`) are **not** omitted: they show in a separate,
  un-tiered, ECR-sorted fallback section below the VOR Board, since "no VOR" is not the
  same as "no data."
- Plain-English notes are templated from existing fields (position, team, availability
  signal) for Phase 3.5 — hand-written blurbs across the full pool isn't feasible in the
  time remaining.
- The PDF export is a static, pre-draft snapshot of the frozen Board (generated once
  before Sept 8) — a break-glass backup that doesn't depend on the live app still running,
  not a live/on-demand export.

## Phase 3.75 — Model methodology research (not urgent, precedes Phase 4)

Before committing to L3's hierarchical Bayesian approach, survey what methodologies other
fantasy projection systems actually use and why, and compare against opportunity-vs-efficiency
framing already assumed in `CLAUDE.md`. Two opinion pieces to start from (not benchmarked,
treat as leads not conclusions):
- fantasyfootballanalytics.net/which-projections-are-most-accurate
- datafield.dev/blog/fantasy-football-data-science.html

Deliverable: a short comparison of 2-3 candidate approaches (e.g. hierarchical Bayesian,
gradient-boosted trees on usage features, simple regression-to-ADP blends) with a
recommendation on which to build first, and whether weekly start/sit (Phase 8) can reuse
the same model or needs a lighter one. Does not block the draft-usable path (Phases 0-3.5).

## Phase 4 — Projections (3-5 days)
## Phase 5 — Correlation + season simulation (3-4 days)
## Phase 6 — Draft policy (4-7 days)
## Phase 7 — Shiny live-draft app (3-5 days)
## Phase 3.6 — Draft-night positional-run guide (1 day, build before Sept 8)

**Surfaced during Phase 8 scoping, 2026-09-06.** The Board tells you who's best; it does
not tell you *when to switch positions*. The user named this directly: "I wouldn't know
where to switch from one position to the next." That's the one unmet draft-night need, and
it outranks Phase 8 on both deadline (Sept 8 vs Sept 13) and permanence (draft mistakes
are forever; a bad lineup costs 1 game of 15).

Not Phase 6. No opponent model, no MCTS, no VONA. The heuristic is scarcity against the
snake gap: **for each position, count players remaining in the current live tier; compare
to `picks_until_my_turn()`; the position that runs out before your next turn is the one to
take now.** At slot 5 of 10 the gaps alternate 11 / 9, so a position with 3 usable players
left is gone and one with 12 will survive.

All inputs already exist — this is assembly, not modeling:
- `assign_tiers()` (`R/75_value.R`) — talent cliffs
- `picks_until_my_turn()` (`R/78_turn.R`) — snake gap from Pick Log state
- `remaining_draft_pool()` (`R/76_pick_log.R`) — who's left
- `replay_pick_log()$rosters` + `league.json` starters — what you still need

Output is one line per position: need, tier supply remaining, survives-your-turn yes/no.

## Phase 8 — In-season: waivers, start/sit, trades (post-season-start)

Waivers and trades remain unscoped and are **deliberately deferred** — neither is urgent,
and both want the projection stack. Only the Week 1 lineup slice is specified here.

### Phase 8.1 — Weekly Lineup tab (resolved via `grill-with-docs`, 2026-09-06)

**Problem:** the season opens 1 day after the draft. The full start/sit stack (L2-L6) is
10-16 days of work and does not exist. Week 1 also has zero in-season signal by
construction — no games played — so no Week-1-specific model can beat preseason consensus.
Scope is therefore **a view over data that already exists**, not a new model.

**Resolved decisions:**

- **Ranking basis: positional ECR rank**, with `ppg_current` displayed beside it as a
  sanity check. ECR covers 100% of the roster including rookies (who are `NA` in
  `projected_points`), and it already prices 2026 team/coaching/depth-chart changes that
  2025 production is blind to. The Board's `projected_points` is explicitly *not* reused —
  it's a season-total metric (`ppg × 17 × availability`), and both the ×17 and the
  durability discount are wrong shapes for a single-week decision.
- **Display, never bake in.** Applied three times over: defensive matchup, weekly
  volatility, and expert dispersion are all shown next to the player and never fold into
  the ranking. Rationale: no way to calibrate any of them before Week 1, and false
  precision is worse than a visible number the reader judges. Consistent with `CLAUDE.md`'s
  "regress efficiency aggressively."
- **Not matchup-optimized.** A lineup tool built around Week 1's specific matchups is
  thrown away in Week 2. Every decision here generalizes to any week.
- **Lineup solve is greedy, not LP.** With one ranking and one FLEX, greedy is *provably*
  optimal (fill fixed slots with top-N at position, FLEX takes best remaining RB/WR/TE; the
  exchange argument closes it). ~15 lines of R. **This retires the `highs` LP dependency
  L6 assumes** for the single-week case.
- **Auto-fill all 9 slots, then flag the coin flips** — any slot where the two candidates
  sit within a small ECR gap gets marked "check news," with the defensive matchup and
  volatility shown. Most weeks 7 of 9 slots are obvious and shouldn't consume attention;
  the product value is entirely in the 2 that aren't.
- **Injuries: manual "mark out" toggle first, `load_injuries()` as fast-follow.** 2026
  injury data does not exist yet (verified — errors), so building against an unverifiable
  schema before the deadline violates the Phase 0 rule. When it lands (~Sept 9-11, verify
  Fri Sept 11), the auto-rule is tiered and **only ever auto-removes `Out` and `Doubtful`;
  `Questionable` is flagged, never benched** — ~70-75% of Questionable players play.
  Surface `practice_status` (DNP/Limited/Full) alongside, which resolves most of them.
- **Documented limit:** the definitive inactives list drops 90 minutes before kickoff and
  is not in nflverse at all. The tool gets you to a correct lineup the night before; it
  never replaces the pre-kickoff check. Do not promise otherwise.
- **Per-player lock times, not one deadline.** Week 1 2026 spans six windows across six
  days (Wed 9/9 NE-SEA → Mon 9/14 DEN-KC). Yahoo locks each player at his own kickoff, so
  the tab shows when each player locks. From `load_schedules()` (verified live for 2026).
- **Home: a new tab in `inst/app/app.R`**, not a separate app. The app already loads the
  pool, replays the Pick Log, and reads `league.json`; the roster is
  `replay_pick_log()$rosters[[my_team]]`. Gives the draft app a second life after Sept 8.
  Laptop-only by design — confirmed the user never sets lineups from a phone.
- **Opponent rosters are free** (`replay_pick_log()$rosters` returns all teams). The weekly
  H2H opponent's *identity* is not — that's Yahoo's league schedule, behind the blocked API
  — so it's a once-a-week dropdown.

**Prerequisite (blocks a complete Lineup): DST is not draftable.**
`R/60_draft_pool.R:20` drops `pos != "DST"`, so the app cannot record a DST pick and the
Roster ends the draft 16/17 with an unfillable starter slot. **Chosen fix: build real
team-defense scoring and valuation** (option C, over the cheaper ECR-only patch). Verified
buildable — `nflreadr::load_team_stats()` is in the pinned 1.5.1, grain is team-week with
`opponent_team` and `game_id`, and it carries every input `config/scoring.json`'s `dst`
block needs (`def_sacks`, `def_interceptions`, `def_tds`, `def_safeties`,
`fumble_recovery_opp`, `def_*_blocks`). Points allowed is a self-join on `game_id`.
The one open risk is the **crosswalk**: FantasyPros publishes 32 DST rows but they have no
`dim_player` row and no `fantasypros_id` match, so they need a synthetic `player_key` and a
team-abbreviation map. That is `CLAUDE.md`'s "never join on name" rule's one deliberate,
bounded exception — 32 rows, hand-checkable.

**Additive data change (no ranking impact):** widen `build_draft_pool()`'s select to carry
`sd`, `best`, `worst`, `rank_delta` from `ff_rankings`. `sd` is expert *disagreement*,
which covers rookies where weekly-points volatility is `NA`; `rank_delta` flags players
news is currently happening to.

### Deferred out of Phase 8.1

- **Variance-aware start/sit.** In H2H you maximize P(win), not expected points: favorites
  should minimize variance, underdogs maximize it. Correct, and it is `CLAUDE.md`'s
  P(championship) objective at weekly scale. Needs point projections for both teams to
  establish favorite/underdog — that's Phase 4-5. Week 1 ships only the volatility
  *column*; the policy that consumes it comes later.
- **Yahoo sync — permanently dead.** See `CLAUDE.md`: the Fantasy Sports OAuth scope no
  longer exists in the app-creation form (verified 2026-09-06). Manual entry stays primary.
  Consequence to carry forward: the pipeline has **zero Yahoo-specific signal** — no Yahoo
  ADP, no ownership (`yahoo_id`, `player_owned_yahoo`, `player_owned_espn` are 100% NA in
  `redraft-overall`). Opponents draft off Yahoo's default list; we cannot model that. This
  is the main known gap in Phase 6's opponent model.
- Waivers, trades.

---

## Architecture

```
ffdraft/
├── DESCRIPTION, renv.lock, _targets.R
├── config/                    # the JSON-editable surface
│   ├── league.json  scoring.json  model.json  strategies.json
│   └── schema/*.schema.json
├── R/
│   ├── 00_config.R            # load + jsonvalidate
│   ├── 10_ingest.R            # nflverse -> parquet
│   ├── 20_stage.R             # crosswalk, dim_player, fct_player_week
│   ├── 30_scoring.R           # config -> points (pure, vectorized)
│   ├── 40_features.R          # usage decomposition
│   ├── 50_project.R           # hierarchical projection model
│   ├── 55_availability.R      # injury hazard model
│   ├── 60_correlate.R         # joint weekly distribution
│   ├── 70_simulate.R          # season Monte Carlo
│   ├── 75_value.R             # VOR, wins added
│   ├── 80_adp_survival.R      # P(available at pick k)
│   ├── 85_policy.R            # VONA / MCTS
│   └── 90_explain.R           # natural-language rationale
├── inst/app/                  # Shiny
├── data/{raw,stage,mart}/ + ff.duckdb
└── tests/testthat/
```

**Optional fork:** staging/marts could be `dbt-duckdb` SQL models, giving `dbt test` and
docs for free. Lean R-only for v1, but write transforms in a style that ports cleanly.

---

## Config spine

Real values for this league (pulled from Yahoo 2026-09-04, see `CLAUDE.md`):

```jsonc
// config/scoring.json
{
  "passing":   { "yards": 0.04, "td": 4, "int": -1 },
  "rushing":   { "yards": 0.1, "td": 6 },
  "receiving": { "reception": 0.5, "yards": 0.1, "td": 6,
                 "position_premium": { "TE": 0.0 } },
  "misc":      { "fumble_lost": -2, "two_point": 2,
                 "return_td": 6, "offensive_fumble_return_td": 6 },
  "kicking":   { "fg_0_39": 3, "fg_40_49": 4, "fg_50_plus": 5, "fg_miss": 0,
                 "pat_made": 1, "pat_miss": 0 },
  "dst":       { "...": "team-level, not yet consumed by score_player_week()" }
}
```

```jsonc
// config/league.json — my_slot nullable, filled by sweep mode once draft order is set
{
  "platform": "yahoo",
  "teams": 10,
  "draft": { "type": "snake", "my_slot": null, "rounds": 17 },
  "roster": {
    "starters": { "QB": 1, "RB": 2, "WR": 2, "TE": 1, "FLEX": 1, "K": 1, "DST": 1 },
    "flex_eligible": { "FLEX": ["RB", "WR", "TE"] },
    "bench": 6,
    "ir": 2
  },
  "season": { "regular_weeks": [1, 15], "playoff_weeks": [16, 17], "playoff_teams": 4 }
}
```

Yahoo now supports per-position per-stat values, separate kickoff/punt return scoring,
and 60+ yard FG tiers. The schema must be permissive enough to absorb whatever the
commissioner picked. Do not assume defaults.

---

## Model stack

**L1 Scoring.** Pure, vectorized, golden-tested.

**L2 Usage decomposition.** Split points into opportunity x efficiency. Team level: plays
per game, pass rate over expected, pace, implied team total. Player level: snap share,
route participation, target share, air yards share (WOPR), carry share, red zone and
goal-line share. Efficiency modeled separately and regressed hard.

**L3 Projection.** Hierarchical Bayesian with partial pooling by position and team
offense (`brms`/`cmdstanr`, or `glmmTMB` for speed). Position-specific age curves. Draft
capital as the rookie prior, since draft round predicts opportunity better than any
college stat. Output is a **posterior predictive distribution of weekly points**. Blend
with FantasyPros ECR at a config-set weight for a sane floor.

**L4 Availability.** Survival model for games missed by position, age, injury history.
Multiplies into weekly draws.

**L5 Correlation.** Weekly outcomes are not independent. QB and his top WR correlate
positively (stacking), RB and WR on the same team slightly negatively (target
competition), both sides of a shootout rise together. Factor structure: game environment
-> team -> player idiosyncratic. Or a Gaussian copula on historical residuals. This is
what separates a simulator from a spreadsheet.

**L6 Season simulation.** Draw correlated weekly scores, solve optimal starting lineup
each week (assignment problem, non-trivial with FLEX; `highs` LP or greedy-plus-swap),
play the schedule, aggregate to **P(playoffs) and P(championship)**.

*Performance:* the expensive step is drawing correlated scores, not evaluating rosters.
Pre-draw one `[players x weeks x sims]` array and reuse it, turning evaluation into array
indexing. 300 players x 14 weeks x 10k sims x 8 bytes is ~340 MB, fine on 48 GB.

**L7 Value.** VOR with dynamically computed replacement level (expected best player on
waivers given league size x roster depth). **Wins Added** as the headline metric: delta
P(title) from substituting a player for replacement level. `ffsimulator::ff_wins_added()`
is a useful reference implementation.

Note that 10-team vs 12-team materially changes this. Smaller leagues raise replacement
level, compress the value spread, and make waiting on scarce positions cheaper.

**L8 Draft policy.** The hard part. Snake drafts are sequential decisions with adversaries.

- *Availability:* fit a distribution over draft slot per player from ADP and its
  dispersion, giving P(player i survives to pick k).
- *Opponent model:* softmax over ADP rank weighted by current positional need, temperature
  calibrated against historical drafts. A company league is unusually predictable here,
  since casual drafters hew close to Yahoo's default rankings. That makes availability
  curves tight and the edge from knowing who survives the turn unusually large.
- *VONA:* marginal cost of passing on a player now versus the best expected alternative
  at your next pick. This is the metric that wins snake drafts.
- *Full policy:* MCTS over the draft tree. At each of your picks, roll out N complete
  drafts under the opponent model, evaluate resulting rosters through L6, choose the
  action maximizing E[P(title)]. Target sub-10-second response for live use.

Keep this behind a generic `recommend_pick()` interface so an auction engine could slot
in later without a rewrite.

*Research feature:* encode named strategies (Zero-RB, Hero-RB, Robust-RB, late-round QB)
as comparable policies and let the simulator determine which the specific league config
rewards. Nobody agrees on the answer, and this can actually settle it for this league.

---

## Application

Shiny + `bslib`, three panes:

1. **Board** — `reactable`, live-filterable: rank, VONA, wins added, ADP delta,
   availability at next pick, positional scarcity heatmap
2. **Recommendation** — top 3 with MCTS rationale and the delta to title odds
3. **Learn** — plain-English player profile: role, team situation, usage trend, why the
   model likes or dislikes him, the risk

Manual entry is the primary input path. API sync, if it ever exists, is additive.

---

## Known risks

- Rookies have no NFL usage data, so draft capital and depth chart carry the entire prior.
  The model is least confident exactly where the hype is loudest.
- ADP shifts daily in late August. Cache with timestamps, re-pull the morning of the draft.
- K and DST are near-unpredictable. Give them flat priors, not a modeling budget.
- nflverse schemas drift mid-season. `pointblank` catches it; nothing else will.
- Yahoo API access may never arrive. Nothing should depend on it.
