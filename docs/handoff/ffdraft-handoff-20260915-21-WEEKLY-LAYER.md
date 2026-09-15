# ffdraft Handoff #28: draft phase closed. Weekly layer built. Yahoo API re-opened.

**START HERE -> §3.** Next session is the deep Yahoo API investigation. User lifted
the `CLAUDE.md` "do not re-investigate" line for Yahoo on 2026-09-15. Secrets go in
`.Renviron` (newly gitignored), never in `config/`.

**Local**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: 2026-09-15 (Mon), after Week 1 completed
**Prior**: `docs/handoff/drafting/ffdraft-handoff-20260911-20-ODUNZE-CONTINGENCY.md` (#27)
**Git**: branch `week1-roster-handoff`, commit **`f4c2298`**, tree clean.
Read that commit message first — full rationale lives there, not repeated here.

**Phase boundary**: all 27 pre-draft handoffs moved -> `docs/handoff/drafting/`.
Draft engine done. Everything from here is in-season.

---

## 1. Week 1 result. Lost.

**101.80 vs Bone Crushers 118.96.** Record 0-1. Box score -> `data/weekly/2026_week01_myteam.csv`.

**Optimal lineup = 121.56. Regret = 19.76.** Optimal beats opponent by 2.60.
Two swaps, nothing else:

| swap | gain |
|---|---|
| Mahomes 22.66 over Stafford 5.10 | **+17.56** |
| W. Robinson 6.30 over Adams 4.10 | +2.20 |

Mahomes alone flips result. Swap was legal — Stafford locked Thu 9/10, Mahomes played Mon 9/14.

### Do not read this as "picker would have helped"

Yahoo projected **Stafford 18.06 vs Mahomes 16.39**. #27 §2 priced that swap at 0.35 pts
and was right to. Picker maximizing projected points makes same wrong call. Ex-ante
correct -> ex-post wrong. Variance, not error.

**One learnable signal: same-game correlation.** Stafford + Adams both LAR vs SF.
Rams lost 7-27. Two starting slots -> one game script -> both the bad ones. Required
picker feature. Everything else week 1 indistinguishable from noise.

Metric + notes -> `data/weekly/README.md`. Regret is the bar. Bench rows are the
counterfactual; without them no test case exists.

---

## 2. Built: in-season layer

New targets. Detail in `f4c2298`, code in `R/41_weekly.R`.

| target | what |
|---|---|
| `fct_player_week_current` | 389 skill rows, live season, + snap share + opponent. Snap match **99.2%** |
| `dim_injury_week` | every player on report, played or not. Wk1: 9 Out, 3 Doubtful, 9 Questionable |

**Scoring validated.** 12/12 roster players match Yahoo box score to the penny,
kicker included. `score_player_week()` + `config/scoring.json` confirmed correct
against real half-PPR output. First independent check of scoring since build.

### Two traps, both now documented in code — do not undo

**Trap 1 — injuries must stay out of the fact table.** Fact table derives from
`player_stats` -> player ruled Out records no stat -> no row to join onto. Measured:
left join retained **3 of 21** skill designations. Lost all 9 Out, all 3 Doubtful,
6 of 9 Questionable. Signal picker exists to use = exactly what stats-derived table
cannot hold. Hence separate `dim_injury_week`. Rationale in
`build_dim_injury_week()` roxygen.

**Trap 2 — targets served stale cache silently.** `ingest_*()` evaluate `season`
inside the function -> targets never sees arg change -> cache from 09-06 kept
reporting max season 2025 after Week 1 played. Only `tar_invalidate()` broke it.
Fixed: `cue = tar_cue(mode = "always")` on the five in-season raw pulls.
`ff_rankings_raw` deliberately excluded (preseason `season = "draft"` snapshot).

Steady-state no-change `tar_make()`: **~24-28s, 18 of 26 skipped**. `dim_player` and
`expected_stat_lines` rebuild every run — `ff_playerids_raw`/`ff_opportunity_raw`
parquet not byte-stable. Values hash identical -> cascade stops -> board and fact
tables skip. Accepted cost. Comment in `_targets.R` says do not "optimize" back.

Tests: **533 pass, 0 fail.**

---

## 3. NEXT SESSION = Yahoo API, deep investigation. User decision 2026-09-15.

**User has explicitly re-opened this.** Direction: "we're going to investigate the
yahoo API much deeper this time around. Adding my secrets as necessary."

**This overrides `CLAUDE.md`'s "do not re-investigate" for Yahoo only.** That line was
written 2026-09-06 off a ~10-minute look at the create-app form. It stands as an
accurate record of *that* probe, not as a verdict on the whole API. User wants the
deep version. Do not quote the constraint back at them — it has been consciously lifted.

**Scope of the lift is Yahoo alone.** ESPN, `ffscrapr`, and Sleeper `search_rank`
stay closed — each was closed with numbers, not a glance. Sleeper `trending/add`
remains unprobed and uncovered by those closures.

### What 09-06 actually established, and what it did not

Established: `developer.yahoo.com/apps/create` shows only "OpenID Connect Permissions"
and "TW Auction". No Fantasy Sports checkbox. Docs at `sports.yahoo.com/developer/docs/`
still describe a Read / Read-Write picker that is not on the live form.

**Not established** — the gaps a deeper pass should attack:

1. Whether the Fantasy scope is grantable at the **authorize URL** even when absent
   from the create-app form. Untested. Form UI and OAuth scope registry are not
   necessarily the same system.
2. Whether an OpenID-Connect-only key returns 200, 401, or 403 on
   `fantasysports.yahooapis.com/fantasy/v2/game/nfl`. **Never actually called.**
   09-06 reasoned it could not work; nobody issued the request.
3. Whether a public-league read differs from private. League 1541392 is private.
4. Whether `YFAR` (GitHub, unmaintained) still authenticates — its flow may predate
   the form change and reveal the scope string.

Order matters: (2) is one `httr2` call and settles the most. Do it first.

### Bars

- **Full pass**: authenticated read of league 1541392 rosters -> hand-harvesting dies.
- **Partial**: any authenticated 200 on `/fantasy/v2/`, even public/game-level ->
  worth building against, scope the subset.
- **Fail**: record the exact endpoint, status code, and error body in `CLAUDE.md`,
  dated. Supersede the 09-06 note; do not delete it.

Record **response codes**, not impressions. 09-06's weakness was inference from a UI.

### Secrets handling — do this before the user pastes anything

**`.gitignore` did not cover `.Renviron` until commit on 2026-09-15.** Anything pasted
there earlier would have been committed. Now ignored, along with `.env*`,
`.httr-oauth`, `*-oauth-cache.rds`, `config/secrets*.json`.

Rules:
- Yahoo consumer key + secret -> `.Renviron` as `YAHOO_CLIENT_ID` /
  `YAHOO_CLIENT_SECRET`. Read with `Sys.getenv()`. Never literal in `R/`, never in
  `config/*.json` (that dir is committed).
- `httr2::oauth_client(secret = )` + disk cache outside the repo (`~/.cache/httr2`).
- Never echo a key into console output, a handoff, or a commit message. Redact to
  last 4 chars if it must be referenced.
- If a secret does reach a commit: rotate it at Yahoo first, rewrite history second.
  Rotation is the fix; history rewrite alone is not.

### Terms — unchanged, still binding

Reverse-engineering and scraping stay prohibited. Deeper investigation means
**exercising the documented OAuth surface harder**, not routing around it. If the
API says no, the answer is a manual paste, not a scraper.

### If the gate holds — what replaces hand-harvesting

Ranked. Ask the user; do not assume:

1. **Nothing, for start/sit.** Needs the 15 rostered players + nflreadr. Both in hand,
   scoring validated. Yahoo adds zero to the core loop.
2. **Waiver targets** — "who is unowned in league 1541392". nflreadr cannot know this.
   Genuinely Yahoo-only. One paste/week, shape of `docs/yahoo_fantasy_football_adp.csv`.
3. **Yahoo weekly projections** as the baseline to beat. Measurement, not capability.

User was mid-collection of Yahoo player info for "data arbitrage" when this session
ended. **Ask what they pulled before building an ingest for it.**

---

## 4. Still open, carried from #26/#27

- **`CLAUDE.md` stale in two places.** `## Current status` says "Nothing built yet.
  Next action is Phase 0" — false, and now badly false. League facts block says
  **17 rounds**; real is **15**. Fix both.
- **`docs/backlog/README.md` line 8 is stale.** Says "No Yahoo ranking data exists in
  the repo." Superseded 2026-09-06 — `docs/yahoo_fantasy_football_adp.csv` exists and
  passed its gate. `CLAUDE.md` already records the supersession; backlog does not.
- Dead, do not revive: VONA as selector, status-column wiring, ESPN/Sleeper
  `search_rank`/`ffscrapr` re-investigation. See `CLAUDE.md`.
- Live but unbuilt: `p_available` / `survival_display()` (`R/81_vona.R`) — draft-only,
  **does not transfer to weekly**. No turn order in waivers. Leave it.

---

## 5. Week 2 mechanics

- `tar_make()` now self-refreshes. No `tar_invalidate()` needed.
- After Week 2 plays: add `data/weekly/2026_week02_myteam.csv`, same columns, bench
  actuals included. Update case table in `data/weekly/README.md`.
- Two backtest weeks is not a sample. Do not fit anything to it.

## 6. Suggested skills

- **`caveman`** — repo doc rule, any doc written
- **`claude-md-management:revise-claude-md`** — §4 stale blocks, AND the Yahoo
  constraint block once §3 returns a verdict. That edit is required either way.
- **`diagnose`** — §3 is a falsification exercise; suits it better than `prototype`
- **`to-prd`** — scope the picker before code. Still not done. Still right, but now
  queued behind the Yahoo tangent by user decision.
- **`handoff`** / **`session-close`** — close next one. Note: skill defaults to `/tmp`;
  repo `docs/handoff/README.md` overrides — write here.
