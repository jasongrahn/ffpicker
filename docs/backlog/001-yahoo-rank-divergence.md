# Backlog 001 — Yahoo rank divergence flag

**Status**: BLOCKED. Prerequisite data does not exist.
**Value window**: whole 2026 season. Waivers and trades have the same "what does the
room think" problem the draft does.

---

## Correction first — read this before anything else

This doc was first written 2026-09-06 with a measured comparison of our board against
`data/yahoo_rankings.csv`, reporting Spearman 0.812 and a list of "disagreements."

**That comparison was invalid.** `data/yahoo_rankings.csv` is **our own board exported**
by `export_yahoo_rankings()` (`R/95_export.R:68`, commit `dc2c9c8` "Export the Board as
a Yahoo import-rankings CSV"). It is our rankings formatted *for upload into* Yahoo's
custom-rankings feature. It is not rankings *from* Yahoo. The filename reads both ways.

Comparing our board to that file compares our board to itself. Measured after the
correction: Spearman(our VOR rank, that file's rank) = **0.9859** over 482 players,
**0.9976** excluding K/DST. The residual is K/DST placement and export ordering rules,
not opinion. The earlier "0.812 vs ECR" number was our VOR ordering differing from our
own ECR ordering — an internal fact about our model, nothing to do with Yahoo.

## The idea is still sound. The data is missing.

League drafts on Yahoo. Nine opponents see **Yahoo's** default ordering. Our board is
our own VOR ranking. Where the two disagree, opponent behaviour is predictable:

- Yahoo lower than us -> room undervalues -> he lasts -> we can wait.
- Yahoo higher than us -> room takes him early -> our board says "wait" and we miss.

Still the most direct answer to the blind spot CLAUDE.md names: *what will the nine
opponents actually do*.

## What we actually hold — nothing usable

Audited 2026-09-06:

- `data/yahoo_rankings.csv` — **ours, exported.** Cols `rank, name, team, position`.
  No Yahoo opinion in it.
- `data/yahoo_import_probe.csv` — import diagnostics. Not rankings.
- `docs/qb.csv`, `rb.csv`, `te.csv`, `wr.csv` — Yahoo position-page exports, but shape
  was `Player,Position,Team` **only**. No XRank, no ADP. Used for name alignment, which
  is all they ever supplied. Deleted in `e634f12`; recoverable from git if wanted.
- `parse_yahoo_names()` (`R/96_yahoo_names.R:62`) parses `XRank #N` / `ADP N.N` out of a
  *pasted* page format. **No file in this repo's history ever carried those strings.**
  The parser works; it has never been fed real rank data. Handoff #15's "Yahoo ADP
  unconsumed, `parse_yahoo_names()` returns xrank/adp for ~300 paste players" overstates
  what is on hand — the fields come back NA.
- `dim_player$yahoo_id` — **100% NA** in `ff_rankings`' `redraft-overall` slice, per
  CLAUDE.md. So even given Yahoo ranks by name, the clean join key is absent.

## Prerequisite before any of this is buildable

Obtain a real Yahoo ordering. The only known path is manual: the user opens Yahoo's
draft rankings / player list and pastes it in a shape that carries `XRank` or `ADP`.
The parser at `R/96_yahoo_names.R:62` is already written for exactly that paste format,
so acquisition is the whole cost. **Do not** attempt the Yahoo API — closed, see
CLAUDE.md.

Also needed regardless: fix stale `team = "FA"` rows (Ertz, Hunt, Ekeler all show FA in
our data), and resolve how to join without `yahoo_id`.

## Gate before building — apply the Sleeper standard

Handoff #16 established a signal can be real, independent AND predictive and still
change **zero** picks. Same gate applies, and cannot even be run until data exists.

**PASS bar** (set now, before measuring, per the #16 discipline): a Yahoo-informed
reorder must change **>= 3 of 17 picks** in the `dev/dryrun.R` diff. Below that ->
read-only board column at most, never a scoring input. Zero -> close it the way Sleeper
closed in #16.

## Lesson worth keeping

Two files named for Yahoo in `data/`, neither containing Yahoo's opinion. The check that
would have caught it in one step: correlate the candidate signal against our own board
*first*. A near-1.0 correlation with your own output means you are holding a mirror.
