# ffdraft — Handoff #9: Phase 3.6 run guide built; expected-points ranking ready to wire

**Repo**: `https://github.com/jasongrahn/ffpicker` (now a git repo — was not at #8)
**Local**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: 2026-09-06
**Draft**: Tuesday, Sept 8, 2026, 6:00pm ET — **~2 days out**
**Prior**: `/tmp/ffdraft-handoff-20260906.md` (#8), `/tmp/ffdraft-handoff-20260905-4.md` (#7)
**HEAD**: `5a23fb7` — **local only, not pushed**. `ab8b80e` and earlier are on the
remote. Tests **271 / 0 failures** (last run at `ab8b80e`; `5a23fb7` is config only,
no R code touched). Pipeline green.
**Pick Log**: reset to baseline `{"type":"draft_started","teams":10}`. No app on 7645.

---

## Read this first

Docs are written `/caveman` style now — repo rule, recorded in `CLAUDE.md`. This
doc follows it.

User confirmed Chrome extension works again. They live-verified the run guide in
their own browser mid-session and drove two changes from it. Trust their screenshot
over any claim here.

---

## What got built this session

### 1. Phase 8 / 3.6 scoped into `PLAN_1.md` (was a bare header)

Full `grill-with-docs` interview, 8 decisions resolved. Two sections written:

- **Phase 3.6** — draft-night positional-run guide. Higher priority than 8.1
  because the draft precedes Week 1. **This is what got built.**
- **Phase 8.1** — Weekly Lineup tab. Specced, not built. Due before Sept 13.

`CONTEXT.md` gained 5 terms. Key one: "matchup" was overloaded onto two unrelated
things — split into **Defensive Matchup** (the defense your player faces) and
**Weekly Opponent** (the fantasy team you're scored against).

### 2. Run guide — shipped, live-verified by user

Answers "which position now, and *who*" under a 1-minute clock.

- `R/79_scarcity.R` — `scarcity_report()` (built earlier this session) plus new
  `scarcity_input()`. **Why the latter matters**: the Board has no DST rows at all
  (team-level, no `dim_player`) and no rookies. Feeding it straight to the report
  meant a DST or rookie-RB pick was unclassifiable, so `still_needed` kept
  demanding a position you'd already filled. `scarcity_input()` combines Board +
  fallback, parking fallback players one tier past the Board's worst so they never
  dilute a live tier's supply.
- `R/90_explain.R` (new) — plain-English layer. `recommend_picks()` names the top 3
  at the target position (VOR order, topped up from ECR fallback for DST/rookies).
  `explain_scarcity()` writes one sentence: *"Take Trey McBride (TE, ARI) now. Only
  1 tight end left at that level and 3 picks until your turn — likely gone."*
  Position codes always spelled out; a name never ships without pos + team.
- `inst/app/app.R` — advice line above the fold, "Take one of these" panel, run
  guide table. Tier now renders as integer, not `1.00`.

### 3. Tiering bug — found and fixed (this was load-bearing)

`assign_tiers()` thresholded on `gap_multiplier * sd(vor)`. Wrong yardstick:
`sd(vor)` spans elite-to-waiver for the whole position, and a gap between two
*consecutive* players essentially never crosses that. Real 2025 board: **every
position collapsed to 2 tiers, 114 RBs sharing "tier 1."** The run guide was inert.

Now `sd(gaps)` — "is this drop unusual *for a step between neighbours*?" Same
multiplier, same board: **K 9, TE 5, WR 15, QB 17, RB 19 tiers**, with 1-8 players
in the top ones. Single-player top tiers are correct, not a bug: the best back
really is alone above the field.

Two regression tests guard the old shape.

### 4. Earlier this session (already committed, see #8→now)

- `R/62_dst.R` — DST pool. DST was **structurally undraftable**: `build_draft_pool()`
  drops `pos != "DST"`, so the roster would have ended 16/17 with an unfillable
  starter slot. Synthetic keys `-(900000L + team_idx)`, disjoint from real keys by
  sign. Fixed 2 abbreviation mismatches (`JAC`→`JAX`, `LAR`→`LA`).
- `R/40_opportunity.R` — `load_ff_opportunity()` ingested. Expected vs actual points
  for 660 players. This is CLAUDE.md's core principle as data, not assertion.
- FLEX bug in `scarcity_report()` — shared-pool math reported `still_needed = 3` for
  RB/WR/TE alike on a 3RB/0WR/0TE roster, telling you to keep taking RBs while TE
  sat empty. Fixed: dedicated need per position + one shared FLEX slot.
- Yahoo API settled empirically — recorded in `CLAUDE.md` as **do not re-investigate**.
  Third-party libs (ffscrapr, espn-api, ESPN MCP servers) evaluated and rejected:
  all league-scoped.

---

## The one thing not wired: expected-points ranking

A background agent finished `R/75_value.R` changes. **Code is committed and tested
(the agent's 26 assertions are in the 271), but `_targets.R` does not pass the new
argument yet — so the board still ranks on actual points.**

New signatures:
```r
build_player_value(fct_player_week_scored, draft_pool,
                   current_season = 2025, availability_seasons = 2023:2025,
                   player_opportunity = NULL)
compute_vor(value_table, league_config, basis = c("expected", "actual"))
```
`player_opportunity = NULL` → behaves byte-identical to today. That's why the
pipeline still runs.

**To wire it** (one line in `_targets.R`):
```r
tar_target(player_value, build_player_value(fct_player_week_scored, draft_pool,
                                            player_opportunity = player_opportunity)),
```
Then `tar_make()`. `compute_vor()` already defaults to `basis = "expected"`.

Fallback rule: a Board player with no expected data falls back per-row to actual,
never gets dropped. 25 of 389 hit it — 24 are kickers (out of scope for
`ff_opportunity` by design) plus 3 deep-roster players.

**Measured effect** (agent's numbers, real 2025 data, actual vs expected rank):

| Player | Pos | Actual | Expected | Delta |
|---|---|---|---|---|
| Justin Jefferson | WR | 101 | 37 | **+64** |
| CeeDee Lamb | WR | 36 | 16 | +20 |
| Josh Allen | QB | 12 | 30 | −18 |
| Davante Adams | WR | 24 | 9 | +15 |
| Saquon Barkley | RB | 25 | 14 | +11 |
| De'Von Achane | RB | 9 | 17 | −8 |

Jefferson is the "unlucky, buy him" signal; Achane the "lucky, regress him" signal.
Both fire exactly as CLAUDE.md predicts. **This is not cosmetic — decide before the
draft whether you want it.**

Evidence backing expected-over-ECR (the Alex Cates studies the user supplied):
FantasyPros expert consensus lost **−1.7 season wins** vs the manager's own choices;
ESPN's projections won by +0.2. This *overturned* the user's earlier Q2 answer
(positional ECR); they approved the reversal.

---

## Budget + timing (added end of session, read before starting)

Session hit **100% of the 5-hour limit**. Weekly at 49%, **resets Sep 8 at 3am ET**.
Draft is **Sep 8 at 6pm ET** — fresh weekly budget lands 15 hours before first pick.
Not tight. Do not rush Tuesday.

Where last session's tokens went, and the standing rule that follows:

| Source | Share | Rule now |
|---|---|---|
| Subagent-heavy sessions | 87% | Work inline. Spawn only if genuinely parallel. |
| `general-purpose` agent | 19% | Use `scout` / `verify` instead (below). |
| `claude-in-chrome` MCP | 17% | Don't drive the app. **User verifies in own browser.** |
| Context above 150k | 25% | `/clear` between tasks, not `/compact`. |

The 87% was earned honestly — four parallel agents under a deadline, authorized.
It is not a mistake to undo, it is a default to stop repeating.

**Two repo agents exist now** (`.claude/agents/`, committed `5a23fb7`):
- `scout` (haiku) — read-only "where is X", returns `path:line` + excerpt, nothing else
- `verify` (sonnet) — runs tests/pipeline, reports pass/fail + first failing assertion.
  Exists so R console output never lands in main context. Sonnet not haiku on
  purpose: it reports whether tests pass, and a misread result beats no result only
  if it's right. Knows the `renv` warning is cosmetic and won't surface it.

**Plugins trimmed** for this repo only (`.claude/settings.local.json`, gitignored):
`code-modernization`, `frontend-design`, `skill-creator`, `feature-dev` disabled.
Honest accounting: all 14 plugins together were only **~2,753 always-on tokens** —
noise next to 733k cache reads. The win is a shorter agent/skill menu, not a smaller
bill. Don't repeat this trim expecting savings.

`andrej-karpathy-skills` installed this session, user scope. Biases toward
think-before-coding and surgical diffs. It is live; expect it to fire on edits.

## Do next, in order

0. **`git push`** — `5a23fb7` is local only. One command, do it first.
1. **Decide + wire expected-points ranking** (5 min, above). Biggest single lever
   left before Tuesday.
2. **Live-verify the run guide again** after wiring — the tier change and the new
   ranking both move what's on screen. Launch:
   `(nohup Rscript -e 'shiny::runApp("inst/app", port = 7645, launch.browser = FALSE)' > /tmp/ffdraft_app.log 2>&1 & disown)`
   Kill: `lsof -ti :7645 | xargs -r kill -9` (plain `pkill -f runApp` did **not**
   work this session). Reset `data/pick_log.jsonl` after.
3. **Dry-run a full 17-round draft** through the app. Never done since DST became
   draftable — confirm the roster actually ends 17/17.
4. **Phase 8.1 Lineup tab** — post-draft, before Sept 13. Spec is in `PLAN_1.md`.

## Known, deliberately not done

- `build_draft_pool()` still drops `sd` / `best` / `worst` / `rank_delta` from
  `ff_rankings`. Additive, recommended, cheap.
- `docs/adr/0002-ecr-as-weekly-ranking-basis.md` offered, never written.
- Existing docs are verbose prose; the new `/caveman` rule says compressed.
  Retroactive rewrite not decided.
- `renv` reports out-of-sync on every `Rscript`. Cosmetic so far, uninvestigated.
- Commit `e868333`'s message says "Wire ff_opportunity + DST into targets" but a
  `git add -A` swept in the FLEX fix too. Content verified; history not rewritten.
- ~~User asked for a `/karpathy-guidelines` skill mid-session. **It is not installed**~~
  **Resolved 2026-09-06.** Installed as plugin `andrej-karpathy-skills@karpathy-skills`
  from `multica-ai/andrej-karpathy-skills`. User scope, `~/.claude/settings.json` only.
  No project files touched. Reloaded and live.

## Open, unanswered

- Week 1 injuries: 2026 injury data **errors** from `nflreadr` (schedules and depth
  charts are fine). User chose manual marking now, auto-load as fast follow, and
  only ever auto-remove players explicitly listed **Out** — never Questionable.
- Draft slot still unknown. `my_slot` nullable in `league.json` until the order is
  revealed Tuesday.
