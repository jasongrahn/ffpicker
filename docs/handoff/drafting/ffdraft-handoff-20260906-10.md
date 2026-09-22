# Handoff #17 — Yahoo XRank acquired, opponent model proven wrong, model critique done

**Date**: 2026-09-06. **Draft**: Tue 2026-09-08, 6:00pm ET. **~2 days out.**
**Git**: `b1fba12` + this doc. 464 tests passing as of last run.

---

## What this session settled

Three things. One is urgent.

### 1. Yahoo XRank/ADP acquired. Gate passed. (URGENT — unshipped)

User harvested `docs/yahoo_fantasy_football_adp.csv` (Gemini-cleaned).
332 rows. `Player,Position,Team,Bye Week,XRank,ADP`. XRank all 332, ADP 227.
Defenses coded `DEF` -> remap `DST`. Team abbrevs differ (`Det`, `Jax`) -> join
name+pos, not team.

Join: `normalize_player_name()`. No `yahoo_id` — 100% NA in `redraft-overall`
slice. **325/764 pool rows overall, but 170/170 of top-170-by-ECR** = full
coverage of everything a 10x17 league can draft. Opposite of Sleeper's failure.

**Reframe that unlocked it: the data is an OPPONENT model, not a board reorder.**
Do not blend XRank into `vor`. Our board is our opinion and stands. Yahoo tells
us what the other nine will do -> changes who survives to our pick.

**Gate** (`dev/yahoo_gate.R`, opponents ECR -> XRank, our board untouched):

| metric | result |
|---|---|
| picks changed | **5 / 17** (pre-registered bar >= 3) -> **PASS** |
| starter Extra pts | **568.5 -> 536.0**, delta **-32.5** |
| rounds changed | 3, 4, 6, 13, 14 |

R3 Henry -> Adams. R4 Adams -> Etienne. R6 Odunze -> Sutton.
R13 Franklin -> Meyers. R14 Allen -> Franklin.

**The -32.5 outweighs the gate.** `dev/dryrun.R:75` opponents take
`order(remaining$ecr)[1]`. Real Yahoo drafters do not. ECR opponents leave value
on the board the real room takes -> **every strategy conclusion this repo has
drawn is optimistic by roughly that margin**, including the QB-deferral scenario
comparisons and the 568.5 headline.

Top-70 board vs Yahoo XRank: Spearman **0.709**.
- Yahoo higher than us (room takes him early — do NOT plan on him): A.J. Brown
  (ours 49 / Yahoo 23), Zay Flowers (56/32), Nico Collins (43/18), Justin
  Jefferson (38/13), Tetairoa McMillan (52/37).
- We higher than Yahoo (our real bets, he lasts): Josh Jacobs (20/126), Javonte
  Williams (6/29), Davante Adams (9/55). Plus whole kicker block = VOR artifact,
  not opinion.

### 2. Name-join rule relaxed

`CLAUDE.md:176` was "Never join players on name." Now **"Prefer not to."**
Allowed when name is genuinely all the source gives (Yahoo's export) — and when
you do it, say so at point of use and report match rate. User's call.

### 3. Adversarial model critique -> `docs/review/001-model-critique.md`

Ran by Fable as a one-pass outside consultant. 357 lines, file:line evidence,
findings ranked by draft-night blast radius, plus do-not-investigate list.
Verdict: board math (scoring -> VOR -> tiers) sound and tested. Biggest risk is
not a bug — it's finding #1 above, found and not shipped.

Its finding #2 is new and real: **expected-points basis never backtested.**
`compute_vor()` defaults `basis = "expected"` (`R/75_value.R:139`), 512/732 rows.
Roxygen at `R/40_opportunity.R:8` claims "strictly better." Fable ran the
held-out test (rank 2024, score 2025 PPG, Spearman):

| Pos (n) | actual rho | expected rho |
|---|---|---|
| QB (31) | 0.322 | **0.395** |
| RB (64) | **0.756** | 0.748 |
| WR (117) | 0.729 | 0.735 |
| TE (71) | 0.713 | 0.716 |
| overall (283) | 0.803 | **0.816** |

Real at QB (+0.07). Rounding error elsewhere (+/-0.01). Direction right,
"strictly better" unsupported. Note asymmetry: Sleeper got four pre-registered
bars and a REJECT; this got adopted as a silent default with none.

Findings 3-5 (93 rows stacking two approximations — only 2 in top 170, both
deferred kickers; K/DST raw-VOR artifact; rookie availability = 1.0) all have
**zero draft-night blast radius**. Post-draft.

---

## Triage — user's decision, recorded

- **#1 = only item with consequence in 48 hours.** Do it.
- **#2 = doc correction + follow-up test, NOT a re-model.** Changing the ranking
  basis two days out would be reckless. But **scope it** — feasible work.
- **#3-5 = document, implement post-draft.**

---

## Do next, in order

### A. Ship the opponent model (before Tuesday)

1. Promote the Yahoo join out of `dev/yahoo_gate.R` into `R/` + `_targets.R` so
   `xrank`/`adp` are columns on `draft_board`.
   **Accept when**: `colnames(tar_read(draft_board))` contains `xrank`, `adp`.
2. Default `dev/dryrun.R` opponents to XRank, not ECR (`dev/dryrun.R:75`).
   **Accept when**: all three deferral scenarios re-scored vs XRank opponents,
   old 568.5-era numbers superseded in this doc's successor.
3. Read-only divergence column in app: `xrank - our_rank`, flag when Yahoo >= 20
   ranks higher -> "room takes him early, do not wait."
   **Accept when**: visible on Board, changes no scoring input.

### B. Correct + scope #2 (before or after A, does not block draft)

4. Fix the roxygen at `R/40_opportunity.R:8` — drop "strictly better," state the
   measured per-position numbers above. **Accept when**: comment matches table.
5. Run Fable's falsifiable test: diff player order between `basis = "expected"`
   and `basis = "actual"` on the live 2026 board, count top-170 rows moving more
   than one tier. **Accept when**: number recorded. High -> untested assumption
   doing real work -> schedule a proper pre-registered evaluation post-draft.

### C. Draft-day readiness (still open)

6. `touch data/DRAFT_IS_LIVE` before Tuesday — protects live pick log from
   `dev/relaunch.sh` wipe.
7. Data refresh Tuesday afternoon: `targets::tar_invalidate(ff_rankings_raw)`
   then `tar_make()`. ~22.5s. Last run returned byte-identical data;
   `scrape_date` = 2026-09-04, nflverse-paced, cannot force fresher.
8. Full rehearsal at real slot once draft order revealed.
   `bash dev/relaunch.sh --slot N`. Port 7645.
9. `my_slot: null` in `config/league.json` needs NO edit — entered at runtime
   (`inst/app/app.R:31`).

### D. Post-draft backlog

10. Findings 3-5 from `docs/review/001-model-critique.md`. Acceptance criteria
    already written there. Do not re-derive.

---

## Do not investigate

Closed, with evidence. Re-opening any of these wastes a session.

- **Yahoo API** — gated, verified empirically 2026-09-06. Fantasy Sports scope
  no longer offered at `developer.yahoo.com/apps/create`.
- **Sleeper `search_rank`** — REJECT, handoff #16. Independent and predictive,
  but only where `ecr > 290`, past end of a 170-player draft. 0/17 picks.
  (`trending/add` is a different endpoint, still unprobed — not covered.)
- **ffscrapr / ESPN / espn-api / fantasy MCP servers** — all league-scoped, none
  expose cross-league ADP.
- **`data/yahoo_rankings.csv`** — our OWN board exported by
  `export_yahoo_rankings()` (`R/95_export.R:68`). Spearman 0.9976 vs our board.
  A mirror. Not Yahoo's opinion. Do not confuse with
  `docs/yahoo_fantasy_football_adp.csv`.
- **Yahoo import thread** — closed #14, 508/510.

## Unexamined

`docs/2026-concensus-ppr-rankings.txt` and
`docs/2026-Consensus-halfppr-rankings.txt` — user-supplied Yahoo analyst
consensus (Rank, Player, AVG, Boone, Smyth, Harmon, Pianowski, Winks, Norris).
Multi-line-per-player format, needs custom parser. **Half-PPR file matches
league scoring.** Not touched this session. Possible per-analyst spread ->
uncertainty signal. Unevaluated, no bars set.

---

## Lesson

A fix that is found, measured, and gate-passed but not merged is worth zero.
Finding #1 of an outside review was our own unshipped work.
