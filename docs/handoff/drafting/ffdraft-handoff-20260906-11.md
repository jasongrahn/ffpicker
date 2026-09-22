# Handoff #18 — opponent model shipped; next is probabilistic survival + VONA

**Date**: 2026-09-06. **Draft**: Tue 2026-09-08 6:00pm ET. **~2 days out.**
**Git**: `cdae24b`. **475 tests passing** (was 464; +11 new).

Next session = **plan** items 1 and 2 below, then implement with Haiku.
User's read: this is the edge, *if* it runs live under a 1-minute clock.

---

## Shipped this session

Handoff #17 section A + C. All of it. Diff in `cdae24b`, not repeated here.

- **A1** — `R/97_yahoo_adp.R` (`load_yahoo_adp()`, `add_yahoo_ranks()`),
  targets `yahoo_adp_file` / `yahoo_adp`. `draft_board` and `draft_fallback`
  now carry `xrank`, `adp`. Name join by necessity, match rate printed every
  build: **299/732 board + 26/32 fallback = 325/764**, and **170/170 of
  top-170-by-ECR**.
- **A2** — `dev/dryrun.R:80` opponents now `order(remaining$xrank)`.
- **A3** — read-only `Yahoo gap` column on Board = `xrank - our_rank`, flagged
  red "takes him early" at `<= -20`. `yahoo_divergence()`,
  `yahoo_gap_display()`. Feeds nothing.
- **C6** — `data/DRAFT_IS_LIVE` touched. `dev/relaunch.sh` refuses wipe,
  verified exit 1.
- **C7** — refresh path verified. `tar_invalidate(ff_rankings_raw)` +
  `tar_make()` = **4.5s**. Data byte-identical -> board untouched.

### New scenario numbers — supersede 568.5 era

| scenario | ECR opponents (old) | XRank opponents (new) |
|---|---|---|
| baseline (K16, DST15) | 568.5 | **536.0** |
| QB deferred to rd 7 | — | **536.4** |
| QB deferred to rd 8 | — | **536.4** |

Baseline reproduces `dev/yahoo_gate.R` exactly. Good.

**But do not quote these as a finding.** See below.

---

## The finding that matters — dryrun is n=1

`536.0` vs `536.4` is **not a measurement**.

Opponents pick `order(remaining$xrank)[1]`. Zero randomness. One deterministic
path -> one realization. Delta of 0.4 across two fixed paths carries no
information. Same defect voided every prior strategy comparison this repo has
printed, 568.5 included.

Real drafters are noisy. Deterministic opponents make survival a step function
— player either gone or not — which understates risk *and* opportunity.

Wrong frame: hypothesis testing. One draft, one decision, no population to
sample. **Right frame: decision theory under uncertainty.**

---

## Scope — item 1: Monte Carlo opponent model

Turn one path into a distribution.

### Noise model

Plackett-Luce. Opponent takes player *i* with probability

```
P(i) ∝ exp(-xrank_i / tau)
```

Equivalently: Gumbel noise on `-xrank/tau`, take argmax. Sample without
replacement. One parameter. `tau = 0` -> today's deterministic behaviour, so
current results stay reachable as a special case.

`xrank` NA (439 of 764 pool rows) -> weight 0 until the listed pool exhausts.
170-pick draft never gets there. Same as today's `order()` NA-last.

### tau is NOT identifiable from our data

Yahoo gives XRank and ADP. Both point estimates. Neither carries
drafter-to-drafter variance. XRank-vs-ADP disagreement is a *proxy for skew*,
not a dispersion estimate — do not fit tau to it and call it calibrated.

Instead **sweep**: `tau in {0, 3, 6, 12}`. Conclusion stable across sweep ->
trust it. Conclusion flips -> it was never real. Standard move for an
unidentified nuisance parameter. Report the sweep, not a chosen tau.

### Comparison method

**Common random numbers.** Same seed set across every scenario. Compare
**paired** differences, never means of independent runs — pairing is where the
variance reduction lives and 0.4-point effects need it.

Report per scenario pair:
- mean delta
- paired bootstrap CI on delta
- `P(scenario A > scenario B)` across sims

CI straddles 0 -> scenarios indistinguishable. Say so. Do not rank them.

### Cost, measured

Full 17-round draft = **~1 sec** (3 scenarios ran in 3.0s, timed this session).
500 sims x 3 scenarios ~= 25 min single-core. Parallel 8 cores ~= 4 min.
Offline job. Not the live path.

### Deliverable

`dev/mc_dryrun.R`. **Leave `dev/dryrun.R` untouched** as the deterministic
reference — it is the thing being generalised, and its output is the tau=0
row.

---

## Scope — item 2: survival probability -> VONA

Falls out of item 1 nearly free, and this is the part that reaches the app.

### The statistic

For candidate X at my pick:

```
VONA(X) = vor(X) - E[ vor of best player at pos(X) available at my next turn ]
```

Take argmax VONA. Not argmax `vor`.

This is what "the room takes him early" means quantitatively. `Yahoo gap`
(A3, shipped) is the eyeball heuristic version of exactly this number —
`-20` threshold picked by hand, not derived.

### Two consumers, one engine

Split them. Different horizons, different budgets.

| | offline (item 1) | **live (item 2)** |
|---|---|---|
| horizon | all 170 picks | to my next turn only, 9-19 picks |
| when | batch, pre-draft | after every opponent pick |
| budget | minutes | **< 2 sec** |

Live rollout is ~10% the length of a full draft. N=1000 x ~19 picks ~= 19k
draws. Vectorised R should land well inside budget. **Measure it, do not
assume it.**

Core function shape:

```
simulate_forward(pool, state, horizon, tau, n_sims) -> P(available) per player
```

Same rollout yields both survival probs and the positional-best distribution
VONA needs. One pass.

### Real-time is the requirement, not a bonus

User's framing: this is the advantage **if it works under the 1-minute clock**.
A correct VONA that takes 30 seconds is worthless on draft night. Latency is a
first-class acceptance criterion, not polish.

---

## Pre-registered bars — set BEFORE running

Repo culture (Sleeper got four bars and a REJECT; expected-points basis got
none and slipped in as a silent default — do not repeat that).

Item 1 is **measurement infrastructure**, not a hypothesis. No adopt/reject
gate. It ships if it runs.

Item 2 gates:

1. **Pick change**: VONA vs current `recommend_picks()` changes **>= 3 of 17**
   picks. Same bar as the Yahoo gate.
2. **No value loss**: starter Extra pts under VONA >= current, at every tau in
   the sweep. A reordering that costs points is a REJECT regardless of bar 1.
3. **Latency**: live recompute **< 2 sec** at N=1000, measured on the user's
   machine, not estimated.
4. **Read-only until it passes**: VONA displays alongside the current
   recommendation before it replaces it.

Miss bar 1 -> the deterministic model was already good enough, ship nothing.
Miss bar 3 -> offline-only, cut from the app.

---

## Known simplification, deliberately out of scope

Simulated opponents ignore roster need. Real drafters stop taking RBs once
their RB slots fill. Second-order vs the ECR->XRank fix already made. Note it,
do not build it. Positional-need weighting is a post-draft upgrade.

---

## Also touched by this work — do not fix blind

`R/79_scarcity.R:148` — `survives <- tier_supply > picks_until_turn`.
Pure worst-case counting. Assumes every intervening pick could hit that tier,
and knows nothing about Yahoo. Systematically pessimistic. Item 2's survival
probability is its natural replacement (`P(>= 1 of tier survives) > threshold`)
but that changes `urgency`, which drives `explain_scarcity()` and the app's
green advice bar. **Behind bar 4. Not a drive-by edit.**

`recommend_picks()` lives at `R/90_explain.R:289`.

---

## Still open, unchanged

- **B4** — `R/40_opportunity.R:8` roxygen says expected basis "strictly
  better". Unsupported. Real only at QB (+0.07), rounding error elsewhere.
  Table in handoff #17. Doc correction, 10 min.
- **B5** — diff player order `basis = "expected"` vs `"actual"` on live board,
  count top-170 rows moving > 1 tier. One measurement, number recorded.
- **C8** — full rehearsal at real slot once draft order revealed.
  `bash dev/relaunch.sh --slot N --force` (needs `--force` now,
  `DRAFT_IS_LIVE` exists). Port 7645.
- **C9** — `my_slot: null` in `config/league.json` needs no edit. Runtime
  entry, `inst/app/app.R:31`.
- **D10** — findings 3-5, `docs/review/001-model-critique.md`. Post-draft.
  Acceptance criteria already written there.

**Do NOT change the ranking basis before Tuesday.** Standing user decision.

---

## Do not investigate

Carried forward from #17, all closed with evidence.

- **Yahoo API** — gated, verified empirically 2026-09-06.
- **Sleeper `search_rank`** — REJECT, #16. (`trending/add` not covered.)
- **ffscrapr / ESPN / espn-api / fantasy MCP** — league-scoped, no cross-league ADP.
- **`data/yahoo_rankings.csv`** — our OWN board, exported for upload. Mirror,
  Spearman 0.9976. Not Yahoo's opinion. `docs/yahoo_fantasy_football_adp.csv`
  is the real one.
- **Yahoo import thread** — closed #14, 508/510.

## Unexamined

`docs/2026-concensus-ppr-rankings.txt`,
`docs/2026-Consensus-halfppr-rankings.txt`. Yahoo analyst consensus, per-analyst
columns. Half-PPR file matches league scoring. Needs custom parser. Possible
per-analyst spread -> uncertainty signal, which item 2's VONA could consume.
No bars set. Untouched.

---

## Suggested skills

- **`/caveman`** — all docs. Repo rule, `CLAUDE.md`.
- **`/prototype`** or **`/to-prd`** — next session is planning items 1 and 2
  before code. Scope above is the input, not the output.
- **`/tdd`** — implementation phase. Survival probabilities and paired
  bootstrap are exactly the shape that fails silently. `tau = 0` must
  reproduce `dev/dryrun.R` byte-for-byte — that is the golden test, write it
  first.
- **`/handoff`** — end of next session.
- Implementation delegated to **Haiku** per user. Plan must therefore be
  explicit about function signatures, file paths, and the four bars. Haiku
  gets a spec, not a direction.

---

## Lesson

Deterministic simulation reports a number with no error bar and the number gets
quoted. `568.5`, `536.0`, `536.4` all read as findings. All were n=1. The
opponent model got the *ordering* right this session; item 1 is what makes any
comparison built on it mean something.
