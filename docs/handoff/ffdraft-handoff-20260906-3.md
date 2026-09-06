# ffdraft — Handoff #10: expected-points wired; three recommendation bugs killed

**Repo**: `https://github.com/jasongrahn/ffpicker`
**Local**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: 2026-09-06
**Draft**: Tuesday, Sept 8, 2026, 6:00pm ET — **~2 days out**
**Prior**: `docs/handoff/ffdraft-handoff-20260906-2.md` (#9)
**App**: running on 7645, clean log, slot 5.

---

## Read first

Handoffs live in repo now (`docs/handoff/`), not `/tmp`.

Every bug this session came from **user screenshots**, not from tests. Tests
were green through all three. Trust screenshot over any claim here.

Run tests with `pkgload`, not `devtools` — `devtools` not in renv library.
`verify.md` agent doc corrected.

---

## Done session

### 1. Expected-points ranking wired (`1b553ae`)

`_targets.R` passes `player_opportunity` into `build_player_value()`. Board
ranks on expected, not actual. Was the open decision from #9.

Reproduced #9's predicted numbers exactly. Jefferson 101 -> 37.

| Player | Pos | Actual | Expected | Move |
|---|---|---|---|---|
| Mike Evans | WR | 141 | 59 | **+82** |
| Justin Jefferson | WR | 101 | 37 | **+64** |
| George Kittle | TE | 54 | 110 | **-56** |
| Tucker Kraft | TE | 59 | 163 | **-104** |

Two things blocked it beyond the one line:

- `build_dst_pool()` hardcoded pre-expected column shape -> `draft_fallback`
  `rbind()` failed.
- Its shape test asserted a **hardcoded column list**, so it passed green while
  pipeline broke. Rewritten assert `rbind()` itself. **This is the session's
  lesson: assert behaviour, not column names.**

25 of 389 players no expected data — 22 kickers (`ff_opportunity` out of scope
by design) + 3 deep-roster. Fall back per-row to actual, never dropped.

### 2. Kicker recommended first overall (`f728183`) — three independent bugs

User screenshot: app said take Jason Myers (K, SEA) at pick 1.

- **Board sorted `tier` then VOR.** `assign_tiers()` groups WITHIN position, so
  cross-position tier compare is meaningless. Myers (61 VOR) + five QBs sat
  above McCaffrey (133). Now `-vor` first, tier as tiebreak.
- **`target_position()` tiebreak was effectively alphabetical.** At pick 1 every
  position's tier 1 holds exactly one player -> urgency AND tier_supply tie
  across K/RB/TE/WR -> stable sort fell through to alphabetical -> K wins
  because K < RB. Never reasoned about kickers at all. Added `vor_best` as
  tiebreak ahead of `tier_supply`.
- **Nothing encoded K/DST are late-round.** New `league.json`
  `draft.defer_until_round` = `{"K": 16, "DST": 15}`. New urgency 5,
  "Wait til late". `still_needed` keeps reporting the real open slot.

### 3. Advice line named one position, counted another (`277b465`)

User screenshot: *"Take CeeDee Lamb (WR, DAL) now. Only 1 **tight end** left."*

Structural, not arithmetic. `target_position()`, `scarcity_display()`,
`explain_scarcity()` each held **own copy** of the ordering. Fixed two in
`f728183`, third kept old rule -> recommendation and sentence disagreed.

Now one `rank_positions()`, all three call it. Plus `explain_scarcity()` keys
its clause off the position of the player it names, so name and noun are the
same fact — no future re-ranking can split them.

Swept 11 draft states, pick 1 -> round 17, real data: **0 contradictions**.
Round 16 correctly releases K deferral, recommends Myers.

### 4. `dev/relaunch.sh` (`2a13067`)

Clean-log restart for QA. Stale log skews `still_needed` +
`picks_until_turn` -> the thing under inspection reads plausible but wrong.

```
dev/relaunch.sh --slot 5    # seeded 10-team draft, opens on board
dev/relaunch.sh             # empty log, opens setup form
dev/relaunch.sh --no-wipe   # restart server, keep log
dev/relaunch.sh --force     # wipe even when data/DRAFT_IS_LIVE exists
```

Waits on port before printing URL. Kills by port — plain `pkill -f runApp`
does not work.

**Guard v1 was wrong.** Inferred "real draft" from pick count > 10; blocked a
routine 16-pick QA run immediately. Pick count cannot distinguish long QA from
live draft. Now: `touch data/DRAFT_IS_LIVE` on draft night. Unconditional
archive to `dev/pick_log_archive/` was always the lossless net.

### 5. Jargon -> plain English + expert rank (`277b465`, `b4d9773`)

Per CLAUDE.md: plain English is a product feature. Header you must decode is a
header you ignore under a 1-minute clock.

| Was | Now |
|---|---|
| `vor` | **Extra pts** |
| `68 VOR` | **+68 pts** |
| `ecr` | **Expert rank** |

Legends under both tables. Extra pts legend states it is the one
cross-position-comparable figure; Tier legend states the opposite (within
position only) — treating tier as cross-position is exactly what put a kicker
in the top 4.

**Expert rank added to Best available** (user request). Was the only column the
two tables did NOT share -> rookie table was an island, no way to place a
rookie against the ranked board. Ranks render as integers (`as.integer`, not
`round` — `digits=` would print "68.0").

Legends had been running off the right edge of the page mid-sentence. Explicit
`max-width`, tables in `overflow-x` containers.

---

## Verified this session, do not re-investigate

- **Rookie/fallback draft path works live.** 2 fallback players drafted through
  app (Jeremiyah Love RB ARI, Jadarian Price RB SEA). Previously untested in
  practice.
- **Replacement levels are correct.** K 140.6, QB 298.7, RB/TE/WR pooled 146.6
  (FLEX pooling working). Kicker VOR of 61 is arithmetically right, not a bug.
- **No zero-week padding bug.** Checked Jefferson / Nacua / Bijan weekly lines:
  17 / 16 / 17 real rows, zero blank weeks, `ppg` computed over games actually
  played. Jefferson genuinely averaged 9.4 in this data.
- `ppg_expected` is `NaN` for kickers -> `is.na(NaN)` is TRUE in R ->
  `has_expected_data` FALSE -> actual fallback fires. Correct.

---

## Biggest open risk: our number is backward-looking, ECR is forward-looking

Adding expert rank made this visible and it is **not** a bug — name it before
Tuesday.

"Extra pts" is derived from **2025 production**. "Expert rank" is a **2026
projection**. When they disagree, consensus holds information the model
structurally cannot: offseason moves, depth-chart changes, injuries, rookie
arrivals, holdouts.

Top-40 disagreements, our rank vs consensus rank:

| Player | Pos | Ours | Consensus | Note |
|---|---|---|---|---|
| Jason Myers | K | 21 | 171 | kicker inflation, below |
| Ka'imi Fairbairn | K | 27 | 165 | same |
| Josh Jacobs | RB | 20 | 134 | worth a look |
| Justin Jefferson | WR | 37 | 8 | real 2025 down year in data |
| Puka Nacua | WR | 13 | 3 | |
| CeeDee Lamb | WR | 16 | 7 | |

Deferral hides kickers from *recommendations* but they still sit at ranks
21/27/28/40 of **Best available**, cluttering the board with players you must
not take for 15 more rounds. Board and run guide visibly contradict.

**Why kicker VOR inflates**: replacement kicker scores ~140, best ~202, so 61
"extra points" is true. But it is near-pure efficiency noise — last year's K1
has little chance of repeating, and any round-16 kicker scores ~140-150. Real
fix is per-position shrinkage toward positional mean, weighted by
year-over-year predictability. That is CLAUDE.md's core principle and belongs
in the model layer, not a draft-night patch.

---

## Do next, in order

2. **Mark deferred positions on Best available** (~20 min). Board says take
   Myers, guide says wait til late. Cheapest honest fix: dim or flag rows whose
   position is deferred at the current round — do NOT filter them out, the
   board should stay a truthful "best available". Config already carries
   `defer_until_round`; `scarcity_report()` already returns `deferred`.
3. **Dry-run full 17 rounds** (~30 min). Still never done end to end. Confirm
   roster lands 17/17 with K and DST arriving in rounds 15-16 once deferral
   releases, and that no starter slot ends unfilled.
4. **Decide on kicker/QB shrinkage before Tuesday** (decision, not code).
   Options: (a) ship as-is, deferral is enough; (b) config-driven per-position
   VOR haircut; (c) nothing, trust expert rank column to catch it by eye.
   Recommend **(a) plus (2)** — shrinkage done properly is model work, and
   there are 2 days.
5. **Phase 8.1 Lineup tab** — post-draft, before Sept 13. Spec in `PLAN_1.md`.

## Known, deliberately not done

- `build_draft_pool()` still drops `sd` / `best` / `worst` / `rank_delta` from
  `ff_rankings`. Additive, cheap, recommended.
- `docs/adr/0002-ecr-as-weekly-ranking-basis.md` offered, never written.
- DST scoring recorded in `config/scoring.json` but `score_player_week()` still
  per-player only. DST rides fallback with no VOR.
- Existing docs verbose prose; `/caveman` rule now standing. Retroactive
  rewrite not decided.
- `renv` reports out-of-sync on every `Rscript`. Cosmetic so far,
  uninvestigated. `devtools` genuinely absent from the library — related, worth
  one look.
- Draft slot still unknown. `my_slot` nullable in `league.json` until Tuesday.
  App seeds slot 5 for QA only.
- Yahoo API + third-party libs settled empirically. See CLAUDE.md. **Do not
  re-investigate.**

## Budget

Weekly resets **Sep 8 3am ET**, draft **Sep 8 6pm ET** — fresh budget lands 15
hours before first pick. Not tight.

Standing rules held this session: worked inline, zero subagents, zero
`claude-in-chrome` (user verified in own browser — which is how all three bugs
were found). Keep it.
