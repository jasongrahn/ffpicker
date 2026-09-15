# ffdraft — Handoff #13: names settled, 473/510 Yahoo-confirmed, import cause still open

**Repo**: `https://github.com/jasongrahn/ffpicker`
**Local**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: 2026-09-06
**Draft**: Tuesday, Sept 8, 2026, 6:00pm ET — **~2 days out**
**Prior**: `docs/handoff/ffdraft-handoff-20260906-5.md` (#12)
**Git**: `main`, clean. 424 tests pass (was 408).

---

## Read first — #12's lead hypothesis is dead

#12 said 292 imported / 218 failed, cause unsettled, two hypotheses. Both now
falsified. Neither by upload — by arithmetic on data already in hand.

**Hypothesis 1, "team column is validated": dead.** Of the 292 rows that
imported, **1 had a blank team** and **11 carried a team Yahoo disagrees with**
(`JAC`/`JAX`, `LA`/`LAR`, blank/`MIA`). All landed. Team is optional as
documented. Do not run #12's blank-team re-export — it settles nothing.

**Hypothesis "our name was wrong": dead.** User supplied `docs/{qb,rb,wr,te}.csv`
— Yahoo position-page exports, `Player,Position,Team`, covering the deep players
the 300-row draft-room paste stops short of. Wired in. Yahoo-confirmed names went
**292 → 473 of 510**.

**Exactly one name was actually wrong**: `Lew Nichols III` → `Lew Nichols`.
The other 181 newly-confirmed players were already spelled Yahoo's way —
`Troy Franklin`, `Kareem Hunt`, `Darius Slayton`, `Zach Ertz`, `Titans`. Every
one of them failed to import. **Spelling was never the cause.**

So `data/yahoo_rankings.csv` changed by one line. Re-uploading it as-is will
import ~292 again. That is expected, not a regression.

### What is left

Something about the *file or the pool*, not the names. Untested candidates:

1. Yahoo's importer only reorders players already in its own ~300-row pre-draft
   ranking list; a player outside it has no row to reorder.
2. A row-count or rank-range cap in the importer.

**The probe settles it: `data/yahoo_import_probe.csv`** (new, 25 rows). 5
controls that imported last time, then 20 that failed but whose spelling is now
confirmed from Yahoo's own export. Read the result:

| Import reports | Means |
|---|---|
| ~25 matched | The players are fine. The 510-row file is the problem — size or rank range. |
| ~5 matched | Those players are genuinely outside Yahoo's importable pool. 473 is the ceiling; stop here. |
| 0 matched | Upload itself failed. Re-check the format. |

One upload, ~2 min. Do this before anything else.

---

## What shipped

### 1. `parse_yahoo_csv()` + `load_yahoo_names()` — `R/96_yahoo_names.R`

Second parser for Yahoo's other export shape. Dispatch on extension: `.csv` is
a position page, anything else is a draft-room paste. Same five columns out, so
the two rbind. `xrank`/`adp` are NA for CSV rows — those pages carry no rank,
and a fabricated one is worse than a missing one.

Multi-eligible players (`"RB, TE"`) expand to one row per position. Our pool
assigns exactly one position and we cannot know which, so both keys must exist.
Rows differ in `pos`, so this creates no ambiguous key.

**Deduplication added, and it was load-bearing.** Sources overlap by design —
a WR page re-lists receivers the overall paste already covered. Without dedupe
every overlapping player becomes a repeated key, and `align_yahoo_names()`
refuses repeated keys, so appending sources would have *un-matched* players who
work today. Dedupe key is exact name/pos/team, **not** the normalised key:
collapsing on the normalised key would merge the two real Isaiah Williamses and
defeat the ambiguity guard.

### 2. `YAHOO_NAME_SOURCES` — `R/95_export.R`

The five sources stated once. Adding the next position page is a one-line
change. Missing files are skipped, not fatal — these are manual exports that
will go stale, and a missing one must degrade to our spellings.

### 3. Export re-run

`data/yahoo_rankings.csv`, 510 rows, 473 Yahoo-confirmed. One row changed.

---

## Known gaps

**37 rows still unconfirmed**: 7 DEF, 7 K, 22 WR, 1 RB.

- The 7 DEF (Titans, Commanders, Raiders, Panthers, Cardinals, Jets, Dolphins)
  are handled by rule in `yahoo_defense_name()` and are almost certainly correct
  — every one of the 25 defenses the paste does cover follows the nickname
  convention without exception.
- The 7 K have no source. Too few and too deep to be worth a page.
- The 22 WR / 1 RB (Odell Beckham Jr., Jalen Reagor, Jacob Cowing, both Isaiah
  Williamses…) sit past rank 313. `wr.csv` was not exhaustive either.

Not worth chasing until the probe says whether names matter at all.

### Carried forward from #12, untouched

- **`renv::snapshot()`** — 6 Shiny packages installed and used but not in the
  lockfile. 2 min. Warning prints on every `Rscript` call until run.
- **Union position slices into `draft_pool`** — 281 players sit in
  `redraft-{qb,rb,…}` but not `redraft-overall`. ~20 min.
- **Rounds 8–14 name no player** — dry run took three QBs in a league that
  starts one. Roster-shape-aware recommendation fix, ~45–60 min. This is the
  biggest remaining *draft-quality* item.
- **Yahoo ADP unconsumed** — `parse_yahoo_names()` returns `xrank`/`adp` for the
  300 paste players. CLAUDE.md calls Yahoo ADP the one unfilled blind spot in
  the Phase 6 opponent model. Nothing reads it yet.

---

## Do next

1. **Upload `data/yahoo_import_probe.csv`.** Read the count against the table
   above. ~2 min. Settles whether any further name work has value.
2. **`renv::snapshot()`.** 2 min.
3. **Roster-shape-aware recommendations.** ~45–60 min. Highest draft-night value
   of anything open.

---

## Draft-night facts

- Draft room opens **30 min before** 6:00pm ET Tuesday. Team names and draft
  order visible there — `my_slot` in `league.json` stays null until then.
- 1-minute pick clock. `data/yahoo_rankings.csv` printed is the offline backup
  for the night the app will not start.
- Relaunch the app with `dev/relaunch.sh`.
