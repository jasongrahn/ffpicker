# Review 001 — Model critique, pre-draft adversarial pass

**Date**: 2026-09-06. **Draft**: Tue 2026-09-08, 6pm ET, ~2 days out.
**Scope**: read-only. Verified against live `_targets` store + source, not docs alone.
**Style**: caveman, per repo rule.

---

## Verdict

Board math (scoring -> VOR -> tiers) is sound and tested. Biggest risk is not a
bug in the code you have -- it's a fix you already found and haven't shipped.
`docs/backlog/001-yahoo-rank-divergence.md` proved real Yahoo opponents (XRank)
change 5 of 17 picks and cost 32.5 starter points versus the ECR-opponent model
every strategy conclusion in this repo is built on. That fix is scoped, gated,
passed -- and still not wired in. Ship it before the "Next actions" list in that
doc, not after. Second: the switch to expected-points-basis ranking (the
project's headline methodology move, CLAUDE.md's core principle made
operational) was never backtested to the same standard the Sleeper evaluation
used. Run today, it's a real but marginal win, position-dependent, not the
"strictly better" claim in the code comment. Third: a 93-row corner case where
two independent approximations stack (placed ECR x consensus-curve VOR) is
real but inert -- it lands entirely in undraftable bench rows and cannot change
a pick. Everything else found is small, already flagged in your own docs, or a
scope gap this project has explicitly and correctly deferred past Sept 8.

---

## Findings, ranked by blast radius on draft night

### 1. Opponent model in every strategy validation is ECR, proven wrong by 32.5 pts, not fixed

**Claim**: `dev/dryrun.R` -- the harness that produced every headline number in
recent handoffs (568.5 starter pts, "17/17 picks", QB-deferral scenario
comparisons) -- still simulates all nine opponents drafting best-available-by-ECR.
`docs/backlog/001-yahoo-rank-divergence.md` already measured, with real Yahoo
XRank data, that this assumption is wrong enough to flip 5 of 17 picks and cost
32.5 starter points. That fix has not been merged into `dev/dryrun.R` or
`_targets.R`.

**Evidence**:
- `dev/dryrun.R:75`: `pick_key <- remaining$player_key[order(remaining$ecr)][1]`
  -- opponents always take lowest ECR remaining.
- `dev/dryrun.R:7-8` comment states the ECR choice explicitly as "closest cheap
  stand-in."
- `dev/yahoo_gate.R` (already written, already run) swaps that key for a real
  Yahoo XRank join and reruns the same 17-pick loop.
- `docs/backlog/001-yahoo-rank-divergence.md`, "RESOLUTION" section: gate
  passed, picks changed 3,4,6,13,14 of 17, starter pts 568.5 -> 536.0 (-32.5).
  Confirmed live: `_targets` `draft_board` carries no `xrank`/`adp` column
  today -- the promotion described in that doc's "Next actions" item 2 has not
  happened.
- Verified live this session: `grep -n xrank _targets.R` and
  `colnames(tar_read(draft_board))` -> no match. `dev/dryrun.R` unchanged from
  the version quoted above.

**Why it's wrong**: real opponents in this specific room are Yahoo drafters who
lean on Yahoo's own default ordering, not FantasyPros ECR. The two diverge hard
in specific, named spots (A.J. Brown, Zay Flowers, Nico Collins, Justin
Jefferson all rank far higher on Yahoo than on this board -- meaning the real
room takes them before this board expects, and any "no rush, can wait" advice
around them is optimistic). Conversely Josh Jacobs, Javonte Williams, Davante
Adams sit far lower on Yahoo than here -- real bets that will actually last.

**Blast radius**: does not corrupt live in-draft recommendations directly (those
run off the actual Pick Log, not a simulated opponent). It corrupts the
*pre-draft confidence* behind every strategic conclusion drawn from a dry run:
defer-round choices, QB-deferral round comparisons, the "568.5 starter points"
figure repeated across handoffs. Concretely, it means the model is optimistic
by ~32 points relative to the real room, and it's already identified which
players are the specific spots where the gap bites (rounds 3/4/6/13/14 in the
one run tested).

**Falsifiable test**: `dev/yahoo_gate.R` already exists and already returns the
answer -- rerun it, it reproduces the same 5/17, -32.5. To confirm the fix
actually lands, wire XRank into `_targets.R::draft_board` (backlog item 2) and
rerun `dev/dryrun.R`'s existing scenarios; if the QB-deferral round comparisons
still favor the same round after the swap, the earlier conclusion survives; if
not, it doesn't.

---

### 2. Expected-points-as-default ranking basis was never backtested to the standard this project set for itself

**Claim**: `compute_vor()` defaults to `basis = "expected"` (`R/75_value.R:139`),
meaning the entire draft board -- 512 of 732 rows have `has_expected_data ==
TRUE` -- is ranked on `nflreadr::load_ff_opportunity()`'s `_exp` columns instead
of realized production. The roxygen at `R/40_opportunity.R:8` asserts
"ranking on the expected side is strictly better signal than ranking on
realized points." That claim was never run through a held-out backtest. When
one is run with data already in the repo, the actual result is a small,
position-dependent edge, not a decisive one -- yet this basis was adopted as
the silent default for the single most consequential number in the app.

**Evidence**: ad hoc backtest run this session against the live `_targets`
store, holding out 2025 the way a real draft-night decision would (rank on
2024 data, score against the season that actually happened):

| Basis (2024 -> 2025 PPG, Spearman) | n | rho |
|---|---|---|
| Actual points -> actual 2025 PPG | 283 (matched) | 0.803 |
| Expected points -> actual 2025 PPG | 283 (matched) | **0.816** |

Per position (n in parens):
| Pos | actual rho | expected rho |
|---|---|---|
| QB (31) | 0.322 | **0.395** |
| RB (64) | **0.756** | 0.748 |
| WR (117) | 0.729 | 0.735 |
| TE (71) | 0.713 | 0.716 |

**Why it matters even though the sign is right**: the edge is real at QB
(+0.07) and a rounding error everywhere else (+/-0.01). This is not the
Achane/Jefferson-sized effect the roxygen's illustrative examples imply for
individual players -- it is a population-level improvement so small that most
of it could be sampling noise on a single held-out year (n=283, one season
pair, `games >= 6` threshold in both years, which drops injury-limited
breakout/bust seasons -- exactly the cases the principle is supposed to help
with, so this test likely understates both bases equally). Compare the rigor
applied to Sleeper (handoff #16): four pre-registered pass/fail bars,
independence and actionability both tested, verdict REJECT recorded and
closed. The expected-basis default got none of that. It may well be the right
call -- QB's result supports it -- but "strictly better" in the code comment is
not a claim this backtest, or any backtest in the repo, currently supports.

**Blast radius**: this basis choice affects the *entire* ranked board (512/732
rows), not a narrow band like Sleeper's tail. But the measured effect size at
the position level is small enough that it is unlikely to reorder the top of
any position's board (where actual and expected performance both track real
elite volume) -- the theoretical case for concern is the *middle* of a
position's ranking, where a TD-touchdown-lucky/unlucky player could swap order.
Not measured this session; scoped as a remediation item below.

**Falsifiable test**: for the actual live 2026 board, diff player order between
`basis = "expected"` and `basis = "actual"` and count how many of the top ~170
(the actual draftable pool) change position by more than one tier. A high
number would mean the untested assumption is doing real, not cosmetic, work.

---

### 3. Compounding approximation on 93 board rows (placed-ECR x consensus-VOR-curve) -- real, but currently inert

**Claim**: 93 of 732 board rows carry `ecr_source == "position"` (their ECR is,
by this repo's own documentation, "an ordering key, not an expert rank" --
`R/60_draft_pool.R:84`) **and** `value_source == "consensus"` (their VOR comes
from `add_consensus_rows()`'s isotonic ECR->VOR curve, `R/77_consensus.R`,
which is fit on and calibrated for *real* expert-consensus ECR). Feeding a
synthetic ordering key into a curve built to interpret a different kind of
number is a second, uncontrolled approximation stacked on the first.

**Evidence**: verified live against `_targets`:
```
value_source x ecr_source:
            overall position
  consensus      89       93
  projected     389      161
```
All 93 land at `vor` between -32.7 and -293.8, tiers 7-29 (the deep bench/
waiver end of every position). Many share *identical* VOR values within a
position (e.g. eleven WRs all tie at exactly -124.77701) -- a visible symptom
of `monotone_map()`'s `rule = 2` endpoint-clamping: past the fitted range,
every input maps to the same output, so distinct players become
indistinguishable by design once they're this far past FantasyPros' cutoff.

**Why it's wrong in principle, not just cosmetic**: the isotonic curve's
x-axis is supposed to mean "how many real analysts rank this player where."
For these 93 rows it means "how far down our own artificial spacing rule put
him," a number invented in `position_slice_rows()` from a linear rank-density
slope, not from any analyst's opinion. Running one approximation through
another compounds error without a way to audit how much.

**Blast radius, measured**: only 2 of the 93 fall within the top 170 overall-VOR
rank that a 10-team/17-round draft actually reaches -- both kickers (Cade York,
Tanner Brown), both already excluded from real consideration by
`defer_until_round: {K: 16}` regardless of raw VOR. **Zero of the 93 can
currently change a pick.** This is a real methodological gap, not a live risk.
Record it so nobody is surprised if it becomes one (e.g. if `max_at_position`
or roster construction changes push deeper bench rounds into play, or if a
future session extends the position-slice mechanism to reach further down).

**Falsifiable test**: run `dev/dryrun.R`'s 17-round loop and check whether any
`ecr_source == "position" & value_source == "consensus"` player_key ever
appears in `my_picks` or any opponent's roster. Already effectively answered by
the rank-170 cutoff above (no), but the dry run is the more literal proof if
challenged.

---

### 4. Raw board sort is uncorrected for the K/DST VOR artifact outside the app's defer masking

**Claim**: this is the fact CLAUDE.md already states (Jason Myers at #21
overall, vor 61.4) -- included here only to record exactly *where* the masking
lives and does not live, since that boundary is what would let it bite.

**Evidence, verified live**:
- `_targets::draft_board` sorted by `vor` descending puts 9 kickers in the top
  70 (`table(top70$pos)` -> `K=9`). Jason Myers: `ppg_current=11.88`,
  `games_current=17`, `projected_points=202`, `vor=61.375`.
- Masking is real but lives in exactly two places: `inst/app/app.R:243`
  (`available[order(-available$vor, ...)]`, then `mark_deferred()` greys the
  row -- does not remove it, per `R/90_explain.R:219-222` comment) and
  `R/95_export.R`'s `yahoo_ranking_order()` (repositions deferred players to
  their round's first pick, doesn't drop them either). `dev/dryrun.R`'s
  fallback-pick path (`rb <- rb[!(rb$pos %in% names(deferred_notes(report))),]`)
  correctly excludes deferred positions.
- Root cause, confirmed: kicker scoring genuinely has this much year-to-year
  spread in real games (top kicker 202 pts / 17 games vs. replacement-rank
  (11th) kicker ~140), and `ff_opportunity` has no kicker `_exp` columns at
  all (`R/40_opportunity.R:40`), so K is the one position permanently stuck on
  the actual-points basis this repo otherwise argues is noisier. VOR has no
  concept of "when in the draft this position's replacement level actually
  starts eroding" -- it treats round-1 and round-16 replacement identically,
  which is why the defer config exists as a patch rather than the model
  accounting for it directly.

**Blast radius**: none currently -- both consumers that put a number in front of
a human (app, PDF export) apply the mask. Risk is entirely in future code that
reads `vor` directly without going through `mark_deferred()`/`defer_until_round`
-- e.g. any new summary statistic, or a careless `head(draft_board[order(-vor),
], N)` in a new feature, would silently reintroduce this. Config-driven, so a
league-settings change that empties `defer_until_round` would also
reintroduce it live.

**Falsifiable test**: grep any new code path against `order(-vor)` or
`order(vor, decreasing = TRUE)` and confirm it also consults
`league_config$draft$defer_until_round` or consumes `draft_board` only through
`scarcity_report()`/`mark_deferred()`.

---

### 5. Availability model gives rookies a free pass on injury risk

**Claim**: `build_player_value()` (`R/75_value.R:81`) sets
`availability <- ifelse(is.na(value$availability_rate), 1, ...)` -- any player
with no 2023-2025 games (i.e., every rookie) is assumed to play a full,
uninjured 17-game season. `projected_points = ppg * 17 * availability` then
inherits that assumption with no discount.

**Why it's wrong**: rookie missed-game rates are not league-average, let alone
100%. This isn't a subtle omission -- CLAUDE.md's own "Known risks" section
already names it ("Rookies have no NFL usage data... model is least confident
exactly where hype is loudest"), and the roxygen at `R/75_value.R:15` says
full projection modeling (draft capital as rookie prior) is explicitly
"Phase 4, not this." Recording here only to make the mechanism explicit: it
isn't merely "unmodeled," it's modeled as the single most favorable possible
assumption (zero injury risk), which inflates every rookie's `projected_points`
and, for the 89 consensus-estimated rookies specifically, feeds an inflated
number into the same isotonic curve discussed in Finding 3.

**Blast radius**: touches real, potentially-drafted players (unlike Finding 3)
-- any rookie with real current-season data eventually gets this treatment too
for the availability component even after his rookie season, until 3 years of
history accumulate. Likely small in practice (rookies are a minority of
drafted rounds 1-8 where this would most matter), but unmeasured. Already
correctly scoped as out of v0 by the project itself -- listed here so
remediation prioritization has the mechanism in one place, not to relitigate
the phase boundary.

**Falsifiable test**: compute league-wide rookie games-missed rate from
historical rookie seasons (`fct_player_week_scored` filtered to
first-observed-season players) and compare to 1.0; the gap times `ppg * 17`
is the size of the current overstatement per rookie.

---

## Do-not-investigate list

Carried forward from CLAUDE.md and handoffs #15/#16/backlog 001. Re-opening
any of these wastes a session this close to Tuesday.

- **Yahoo API access.** Gated, verified empirically 2026-09-06. No live sync,
  ever, as a dependency.
- **Sleeper `search_rank`.** Evaluated, rejected on actionability (0/17 picks
  changed). Independence and signal both held up; actionability didn't. Do
  not re-run the same test hoping for a different answer.
- **Sleeper `trending/add`.** Explicitly *not* covered by the rejection above
  (different signal, different gap) but also explicitly flagged as "not a
  recommendation to probe 2 days before the draft." Leave it.
- **`ffscrapr` / Python `espn-api` / ESPN MCP servers.** League-scoped, no
  cross-league ADP/rankings exposed. Confirmed dead end for the Yahoo-ADP gap.
- **`data/yahoo_rankings.csv` as a source of Yahoo's opinion.** It is our own
  export, Spearman 0.9976 against our own board (a mirror). This was
  corrected once already in backlog 001; don't let it drift back into use as
  ground truth.
- **Position-page rank-to-overall-rank translation via curve fitting.** Tried,
  abandoned (`R/60_draft_pool.R:67-74`) -- the overall page's censoring near
  its cutoff makes the fit flat exactly where it would matter. "Placed, not
  translated" is the settled design.

---

## Remediation backlog

Each scoped for one session. Acceptance criteria are checkable without
re-deriving the finding above.

**R1. Wire Yahoo XRank into the opponent model, not just the gate script.**
Promote the join in `dev/yahoo_gate.R` into `R/` + `_targets.R` so `xrank`/
`adp` are real `draft_board` columns (backlog 001's own "Next actions" item 2).
Then make `dev/dryrun.R`'s opponents draft by `xrank` (falling back to `ecr`
for the ~440 unmatched rows, as the gate script already does), not `ecr`.
**Accept when**: `dev/dryrun.R`'s existing three scenarios (baseline, QB
deferred rd 7, QB deferred rd 8) all rerun against XRank opponents and the
summary table is regenerated; note in a handoff whether the round
recommendation changes.

**R2. Backtest the expected-vs-actual basis choice properly, not ad hoc.**
This session's quick check (Finding 2) used one season pair, a `games >= 6`
floor in both years, and no per-basis handling of players who existed in only
one year. Build a real version: multiple season pairs (2021->2022 through
2024->2025), report per position, and decide a pass bar *before* looking (mirror
the Sleeper C1-C4 discipline). If the edge stays this small, consider whether
`basis = "expected"` should remain the silent default or become a config flag
the user can compare against `basis = "actual"` on demand.
**Accept when**: a written verdict exists with pre-stated bars, the same
rigor Sleeper got, filed as a handoff or backlog doc.

**R3. Add a compounding-approximation guard rail.**
`add_consensus_rows()` should either exclude `ecr_source == "position"` rows
from the curve fit input (`ref`) and from candidacy (since neither the x-axis
meaning nor the calibration is valid for them), or tag the resulting VOR with
a second marker (e.g. `value_source = "consensus_synthetic"`) so it's visibly
distinguishable from `"consensus"` estimates built on real ECR. Given Finding
3's measured blast radius (0 of 170 draftable), this is about correctness and
auditability, not urgency -- fine to do after Sept 8.
**Accept when**: the 93-row overlap in the `value_source x ecr_source` table
either goes to 0 (excluded) or gets a distinct label surfaced in the app.

**R4. Rookie availability discount.**
Replace the `availability = 1` default for no-history players with a
population rookie-availability rate computed from historical data already in
the repo (see Finding 5's falsifiable test). Small model, no new data source.
**Accept when**: `build_player_value()` takes a `rookie_availability_rate`
parameter (config-driven per CLAUDE.md's rule), defaulting to the measured
historical rate instead of 1, and `projected_points` for a sample rookie
changes measurably in a test.

**R5. Grep guard for raw-VOR sorts bypassing the defer mask.**
Add a lint/test that fails if any file under `R/` or `inst/` sorts
`draft_board` by `vor` without also referencing `defer_until_round` or routing
through `scarcity_report()`. Cheap insurance against Finding 4 resurfacing
silently in new code.
**Accept when**: the test exists and passes today, and would fail if
`inst/app/app.R:243`'s sort were copy-pasted into a new file without the
`mark_deferred()` call that follows it.

---

## What this review did not have time to do

Full audit of `R/76_pick_log.R` (event-sourcing correctness under
crash/replay), `R/96_yahoo_names.R` (name-matching edge cases beyond the two
already-documented collisions), and the test suite's actual coverage map (13
test files, one per major R module, ~464 `test_that()` calls per handoff #14 --
not independently re-verified line by line here). Nothing in the time spent
suggested these are live risks; flagging only so a future reviewer doesn't
assume this pass covered them.
