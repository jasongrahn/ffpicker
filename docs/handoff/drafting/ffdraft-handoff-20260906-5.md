# ffdraft — Handoff #12: rookies priced, Yahoo export built, name alignment half-proven

**Repo**: `https://github.com/jasongrahn/ffpicker`
**Local**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: 2026-09-06
**Draft**: Tuesday, Sept 8, 2026, 6:00pm ET — **~2 days out**
**Prior**: `docs/handoff/ffdraft-handoff-20260906-4.md` (#11)
**Git**: `main` == `9398688`, clean. 408 tests pass.

Written to `docs/handoff/` not `/tmp`, per `docs/handoff/README.md`.

---

## Read first — the one open question

**Yahoo import ran. 292 imported, 218 lines didn't match.**

292 is exactly the number of names we had rewritten/confirmed from
`docs/yahoo-player-names.txt`. Not coincidence. Every row that matched is a row
whose spelling we took from Yahoo; every row that failed is a row we spelled
ourselves.

**That does not yet prove the cause.** The 218 include obviously-real players
spelled the obvious way — `Troy Franklin,DEN,WR`, `Kareem Hunt,,RB`,
`Darius Slayton,NYG,WR`. Yahoo has all three. So "our name is wrong" is not a
sufficient explanation on its own.

Two live hypotheses, untested:

1. **The `team` column is validated, not optional.** Yahoo's docs say optional.
   Note `Kareem Hunt,,RB` has an empty team (our `FA` → blank) and still
   failed. Our codes are uppercase (`DEN`); Yahoo displays `Den`. The 292 that
   worked may have worked because their teams happened to agree.
2. **Yahoo's pool is narrower than we assume** and genuinely lacks ~218 of our
   510 deep names.

**The diagnostic that settles it, in one upload:** re-export with the `team`
column blank for everyone (it is documented optional), upload, compare the
match count. If it jumps, team was the gate. If it stays 292, the names are.
The comparison script was written but not run — session ended first.

Secondary check worth running at the same time: for the 292 that matched, do
our team codes agree with Yahoo's (case-insensitive)? If they agree 292/292
that is strong evidence for hypothesis 1.

---

## Done this session

### 1. Rookies priced onto the Board — `R/77_consensus.R` (new)

89 players had no stat line (2026 rookies) and sat in a separate fallback table
with no Extra pts. Now priced and merged into the Board.

Method: two isotonic fits per position over the players who *do* have
projections. First maps ECR → VOR. Second maps ECR → normal `sd` at that rank
— because `sd` scales hard with ECR (median 5.1 in the top 25, 30.6 past 200),
so raw `sd` is not an uncertainty signal by itself. Only the *excess* over
normal is charged, as a rank penalty: `ecr_adj = ecr + max(0, sd - normal_sd)`.

**Deviated from #11's spec deliberately.** #11 said "shrink toward position
mean in proportion to sd". That breaks: position mean VOR is strongly negative
(RB -55.6, WR -49.8), so shrinking a deep player's negative VOR toward the
anchor *raises* it — uncertainty becomes a promotion. Charging in rank space
can only move a player later, which is the intended direction.

Consensus-priced players are marked `~` before Extra pts on the board and in
recommendations (`consensus_mark()` in `R/90_explain.R`). Legend line added.

`build_fallback_board()` gained `exclude_keys` so Board and fallback stay
disjoint. Second app table is now `h4("Team defenses (no Extra pts)")` — DST is
all that is left in it.

Golden ECR→VOR curve test included, per CLAUDE.md's standing rule.

### 2. Spread columns plumbed through

`sd`, `best`, `worst`, `rank_delta` added to the selected columns in
`R/60_draft_pool.R` and `R/62_dst.R` (both, or the `rbind` breaks). Three
fixtures in `test-dst.R` updated to match.

### 3. Yahoo import-rankings export — `R/95_export.R` (new)

Writes `data/yahoo_rankings.csv`, 510 rows, `rank,name,team,position`,
unquoted (Yahoo's own template carries `Ja'Marr Chase` bare).

**Deferred positions are placed, not dropped.** A raw VOR order puts Jason
Myers 21st overall. A deferred position is instead ranked at the pick its round
begins at — round 16 of a 10-team league starts at pick 151 — and undeferred
players flow around them. `yahoo_ranking_order()` is split out from the writing
so the ordering can be tested without touching disk.

Fails loudly if any field contains a comma or quote, rather than emitting a
file that silently shifts every later column.

### 4. Name alignment — `R/96_yahoo_names.R` (new)

User pasted 300 players from the draft room into
`docs/yahoo-player-names.txt` (4-line blocks: name, name, `POS·Team·Bye N`,
`XRank #N·ADP x.y`). Parser fails loudly on any malformed block.

Corrected 35 of 510 names:
- **All 32 defenses.** Yahoo says `Texans`; we said `Houston Texans`. Applied
  to all 32, not just the 25 the paste covers — same convention, all 32
  nicknames are distinct words, no collision possible.
- **Three suffix cases**: `Patrick Mahomes II` → `Patrick Mahomes`,
  `Oronde Gadsden II` → `Oronde Gadsden`, `Brian Robinson Jr.` →
  `Brian Robinson`.

**Yahoo keeps most suffixes** — `Travis Etienne Jr.`, `Kenneth Walker III`,
`Marvin Harrison Jr.`, `Michael Penix Jr.` all present. So a blanket strip
would be wrong; the rule has to be data-driven.

Match key is normalised name + position. Team deliberately excluded — our
abbreviations and Yahoo's disagree in dialect (we emit both `JAC` and `JAX`;
we emit `LAR` for Rams players but `LA` for the Rams DST; Yahoo writes `Jax`,
`LAR`). A key ambiguous on either side is refused, not guessed
(Isaiah Williams — two real receivers). A player absent from the paste keeps
our spelling.

This matches on name, which CLAUDE.md forbids for joins. Justified in the
roxygen: it is an export, nothing downstream consumes it, and `yahoo_id` is
100% NA in our source so there is no id to send.

---

## Found, not fixed

### Two draftable players missing from the board entirely

- **Ricky Pearsall** — WR, San Francisco. Yahoo ADP 114.9 (~round 12).
- **Jayden Higgins** — WR, Houston. Yahoo ADP 132.9 (~round 14).

Not a naming problem. FantasyPros' `redraft-overall` slice omits both; they
appear only in its dynasty pages. Someone in the league will draft them and
they would never appear on the board.

Scope of the gap: **281 players** sit in `redraft-{qb,rb,wr,te,k,dst}` but not
in `redraft-overall` (QB 57, TE 83, WR 90, RB 41, K 10). Most are deep bench.
Only these two have a real ADP. Fix would be to union the position slices into
`draft_pool` — ~20 min, not started.

### Rounds 8–14 name no player

From the #11 dry run, still open. The simulated drafter took Mahomes R9 + Bo
Nix R10 — three QBs in a league that starts one. Roster-shape-aware
recommendation fix, ~45–60 min.

### `renv::status()` out of sync

6 Shiny-stack packages (httpuv, later, promises, shiny, sourcetools, xtable)
installed and used but not in the lockfile. `renv::snapshot()`, 2 min. Every
`Rscript` call prints the warning until it is run.

### Yahoo ADP is now partly in hand

`docs/yahoo-player-names.txt` carries Yahoo's own XRank and ADP for 227 of the
300 players. CLAUDE.md records Yahoo ADP as *the* unfilled blind spot for the
Phase 6 opponent model. `parse_yahoo_names()` already returns both columns;
nothing consumes them yet.

---

## Do next

1. **Settle the 218 unmatched.** Re-export with `team` blank, upload, compare
   the count. Plus the 292-row team-agreement check. ~10 min including the
   upload. Highest value of anything here — an import that only covers 292 of
   510 leaves the deep rounds unranked in the room.
2. **`renv::snapshot()`.** 2 min.
3. **Union the position slices into `draft_pool`** so Pearsall and Higgins
   exist. ~20 min.
4. **Rounds 8–14 recommendation fix.** ~45–60 min.
5. Phase 8.1 Lineup tab — post-draft, before Sept 13.

Open and explicitly parked by the user: QB deferral (`QB: 7` in
`config/league.json`). Do not raise unless they do.

---

## Draft-night facts

- Draft room opens **30 min before** 6:00pm ET Tuesday. Team names and draft
  order should be visible there — `my_slot` in `league.json` stays null until
  then.
- 1-minute pick clock. `data/yahoo_rankings.csv` printed is the offline backup
  for the night the app will not start.
- Relaunch the app with `dev/relaunch.sh`.
