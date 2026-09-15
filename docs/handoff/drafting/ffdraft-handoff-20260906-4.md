# ffdraft — Handoff #11: deferral bug killed by first full dry run; rookie source settled

**Repo**: `https://github.com/jasongrahn/ffpicker`
**Local**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: 2026-09-06
**Draft**: Tuesday, Sept 8, 2026, 6:00pm ET — **~2 days out**
**Prior**: `docs/handoff/ffdraft-handoff-20260906-3.md` (#10)
**Git**: clean, `main` == `fca4f6e`. All session work committed + pushed by user.

Written to `docs/handoff/` not `/tmp`, per `docs/handoff/README.md`. Skill said
`/tmp`; repo rule wins — nine docs already lost to a macOS purge once.

---

## Read first

Handoff #10's "do next" items 2 and 3 are **done**. Item 4 (shrinkage) decided.
Item 5 (Phase 8.1 Lineup tab) still post-draft, untouched.

Screenshot again beat tests. Tests green while deferral was broken.

---

## Done session — see `fca4f6e` for the diff

### 1. Deferred positions marked on Best available

Board rows for deferred positions render greyed with "— wait til rd 16" after
name. Not filtered — board stays truthful best-available. Same on rookie table
(all DST lives there). Legend line added.

Mechanism: `mark_deferred()` + `deferred_notes()` in `R/90_explain.R`,
`defer_until_round` column added to `scarcity_report()` so display never
re-reads `league.json`. Cells emit raw HTML, so both `renderTable()` calls now
pass `sanitize.text.function = identity` — `escape_html()` puts escaping back,
and runs on every path, deferred or not. `align=` set explicitly because
all-character columns lose xtable's numeric right-align.

**User verified in browser.** Myers / Fairbairn / Aubrey greyed, still at ranks
21/27/28.

### 2. First full 17-round dry run — `dev/dryrun.R`

Never run end to end before. New harness, parameterised on
`draft.defer_until_round`, drives the *same* functions the app calls
(`scarcity_report`, `recommend_picks`, `explain_scarcity`, real pick log).
Opponents draft best-available by ECR.

Result: **17/17, DST rd 15, K rd 16, every starter slot filled.**

Run it: `Rscript dev/dryrun.R`

### 3. Bug it found: deferral was demotion only, not exclusion

`deferred` set `urgency = 5L`. Worked only while some other position had an
open slot. By **round 8** every non-deferred starter slot was full → K and DST
the only rows with `still_needed > 0` → demotion had nothing to lose to →
**app recommended Jason Myers in round 8** against `defer_until_round` 16.

Same shape as #10's three bugs: rule correct by its letter, useless in a draft.

Fix: `draftable_now()` in `R/90_explain.R`, shared by `target_position()` and
`explain_scarcity()` — one filter, not two copies, same discipline as
`rank_positions()`. Plus `deferred_needs()` + `parked_phrase()` for the new
rounds-8-to-14 sentence:

> Starters set apart from defense (round 15) and kicker (round 16). Draft the
> best bench player you can until then.

Previously that path said "Starting lineup is full", which was a lie — K and
DST genuinely empty.

Tests 306 → 323, green.

---

## Decisions made

### Kicker VOR shrinkage — **ship as-is**

Deferral removes K from recommendations, greying removes it from the board.
Real shrinkage is model work, not a draft-night patch. Matches #10's lean.

### QB deferral — **open, user's call, one-line config**

Dry run compared baseline / `QB: 7` / `QB: 8`. **All three produce the
identical starting lineup, 568.5 starter Extra pts.** Only pick order moves
(Stafford R5 → R7 → R8; same four players every time).

Ties because opponents draft by ECR and Stafford's ECR is 106 — nobody reaches.
Sim cannot price a real opponent reaching for a QB.

QB supply genuinely deep, not an artifact: Mahomes still there pick 85, Bo Nix
pick 96.

Recommended `QB: 7` on structural grounds (spend early picks where supply
depletes, late pick where it doesn't) while stating plainly it is a judgment
call on top of a tie, not a measured gain. **Not applied.** Add to
`config/league.json` `draft.defer_until_round` if wanted.

**Correction carried forward**: #10-era claim that QB deferral fixes the round-5
Stafford overdraft is wrong. It delays the pick, it does not fix the valuation.
Our board ranks Stafford 29, consensus 106. Valuation fix is post-draft.

---

## Rookie ranking sources — evaluated, settled, do not re-investigate

User asked about five external rookie-ranking sites (nflfantasyedge, fftoday,
draftsharks, fantasyteamadvice, draftedge).

**Verdict: do not scrape any.** Four of five are *dynasty* rookie rankings —
answer "best career", wrong question for a one-season redraft. Draftsharks
1-year-projection sort is the right question and agrees with what we already
hold. Plus: HTML scraping on five commercial sites, ToS exposure, brittle,
none use our scoring.

**What we already have, unused** — `data/raw/ff_rankings.parquet` carries **28
FantasyPros slices**, incl. `dynasty-rk` (125 rookies). `build_draft_pool()`
reads only `redraft-overall` and drops `sd` / `best` / `worst` / `rank_delta`.

Those columns answer the question directly:

| Player | Redraft ECR | sd | best | worst |
|---|---|---|---|---|
| Derrick Henry (established) | 37.6 | 6.99 | 20 | 50 |
| Breece Hall (established) | 39.5 | 4.84 | 30 | 53 |
| **Jeremiyah Love (rookie)** | **40.1** | **7.87** | **23** | **65** |
| Emeka Egbuka (established) | 40.7 | 8.30 | 14 | 68 |

Love's spread no wider than the established players beside him. In
`dynasty-rk` he is **#1 with sd 0.00** — unanimous. Contrast Travis Hunter:
ECR 197, sd 38.5, best 128, worst 347 — correctly buried.

Only **4 no-data players inside top-100 ECR** (Love 40, Price 67, Tate 68,
Brooks 89), 10 inside top-150. Realistically only Love changes a pick.

---

## Do next, in order

1. **Carry `sd` / `best` / `worst` / `rank_delta` through `build_draft_pool()`**
   (~15 min). `R/60_draft_pool.R`. Additive. Already on #10's cheap list.
2. **Rookies onto the board** (~45-60 min). Per-position monotone ECR →
   Extra-pts curve fit on the 389 ranked players, applied to the 89 no-data
   players, **each shrunk toward its position mean in proportion to `sd`**.
   Love (sd 7.9) barely shrinks; Hunter (sd 38.5) collapses to replacement.
   Mark such rows as estimated-from-consensus, not projected.
   **User explicitly will not eyeball rookies manually — this is the whole
   reason it matters.**
   Started this session, **no code written**. Clean start.
3. Apply `QB: 7` if user says so. One line, `config/league.json`.
4. **Phase 8.1 Lineup tab** — post-draft, before Sept 13. Spec in `PLAN_1.md`.

Re-run `Rscript dev/dryrun.R` after 1-3. It is the regression test that catches
what unit tests do not.

---

## Known, deliberately not done

- Rounds 10-14 give no named recommendation, only "draft best bench player".
  8 of 17 picks. Fixing properly needs bench value ≠ starter VOR. Not attempted.
- DST scoring in `config/scoring.json` but `score_player_week()` still
  per-player. DST rides fallback, no VOR.
- `docs/adr/0002-ecr-as-weekly-ranking-basis.md` still offered, never written.
- `renv` reports out-of-sync on every `Rscript`. Cosmetic so far. `devtools`
  genuinely absent from library — related, still one look owed.
- Draft slot unknown. `my_slot` nullable until Tuesday. App seeds slot 5 for QA.
- Yahoo API + league-scoped third-party libs settled 2026-09-06. See CLAUDE.md.
  Rookie-ranking *sites* now settled too, above. **Do not re-investigate any.**

---

## Standing rules — held all session, keep them

- Tests: `pkgload::load_all()`, **not** `devtools` (absent from renv library).
- Work inline. Zero subagents unless genuinely parallel.
- **Do not drive the app with `claude-in-chrome`.** User verifies in own
  browser. Ask, then wait for screenshot. Every bug in #10 and the greying
  confirmation this session came that way.
- Restart app with `dev/relaunch.sh --slot 5` — wipes pick log first. Stale log
  silently skews `still_needed` and `picks_until_turn`.
- Docs `/caveman` style per CLAUDE.md.

## Suggested skills

- `/caveman` — any doc written next session.
- `/tdd` — item 2 is a new model layer. Golden-test the ECR→VOR curve.
- `/handoff` — end of next session.
- `/session-close` — if wrapping rather than continuing.

Do **not** reach for `/diagnose` or `/triage` on the deferral bug. Fixed,
covered by tests + `dev/dryrun.R`.

## Budget

Weekly reset **Sep 8 3am ET**, draft **Sep 8 6pm ET** — fresh budget 15 hours
before first pick. Not tight.
