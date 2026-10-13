# Handoff #38 — Week 5 END-OF-WEEK pull + retro. Prep only, no analysis done yet.

Written 2026-10-13 Tue. Branch `week3-gameday`, **6 ahead of its upstream**, 24 ahead
of `origin/main`, HEAD `ed8860e`.

**Next session's job: end-of-week-5 data pull, then the week 5 retro.** User is
downloading fresh Yahoo exports and will upload a **week-ending** dataset to
`docs/uploads/week_5_data/`. Wait for it before scoring anything.

Prior handoff: `docs/handoff/ffdraft-handoff-20261007-30-WEEK5-SET.md` (#37). That doc
is the authority on the week 5 lineup, the game-script slope rebuild, and the two
reversed standing rules. **Do not re-derive any of it.** Index: `docs/handoff/README.md`.

---

## 0. What this session actually did

One thing: **re-pulled `data/raw/`**. It was 26 days stale — last written 2026-09-15
(week 2). Everything since week 2 had been read live inside `dev/weekly/*.R` scripts,
so the parquet cache had silently fallen out of the loop.

Pulled via the existing `R/10_ingest.R` functions, `nflreadr::clear_cache()` first:

| source | rows | through |
|---|---|---|
| player_stats | 204,385 | 2026 wk5 |
| snap_counts | 6,064 | 2026 wk5 |
| injuries | 1,413 | 2026 wk5 |
| ff_opportunity | 65,164 | 2026 wk5 |
| players | 24,853 | — |
| ff_playerids | 12,526 | — |

Skipped `ingest_ff_rankings()` — draft-only, draft done 09-08. `load_schedules()` and
`load_team_stats()` have **no parquet cache by design** and are pulled live each use;
that matches the snapshot rule in `CLAUDE.md`. `data/raw/` is gitignored
(`.gitignore:19`), so the pull produced **zero tracked diff**.

**That pull is now stale again.** It ran Sun 10-11 with only 1 of 15 week 5 games final.
Monday's BUF @ LA has since played. **Re-run it first thing.**

```
Rscript /private/tmp/claude-501/-Users-jasongrahn-R-projects-ffootballer/\
91bf1923-ab86-46e7-82c7-2b0cf195adfa/scratchpad/pull.R
```

Scratchpad is session-scoped and may be gone. The script is ~15 lines: source
`R/00_config.R` + `R/10_ingest.R`, `clear_cache()`, call the six `ingest_*()`
functions, report rows and max week per file. Trivial to rewrite.

---

## 1. Week 5 partial scoreboard, as of Sun 10-11 pre-13:00. Superseded by the real pull.

Us **13.20** (Javonte Williams, DAL) vs Max's TD Bombers **14.64** (Dak Prescott, DAL).
Only TB 24 @ DAL 16 was final. Javonte came in at 13.20 vs **15.07 projected, −1.87**.
Jake Ferguson scored 3.40 — he was #37 §1's waiver drop, so that is not ours.

**The 14.64 may be a bench score.** Max's TD Bombers roster both Prescott and Jalen
Hurts; Hurts played PHI @ JAX at 09:30. Starters were not determinable. Discard this
table once the week-ending export lands — it exists only to record what was known.

---

## 2. TWO GAPS IN THE WEEKLY LOOP. Both bite the retro directly.

### 2a. No week 5 lineup CSVs were ever written.

`data/weekly/` has `2026_week05_decisions.md` but **no `2026_week05_myteam.csv` and no
`2026_week05_opponent.csv`.** Weeks 3 and 4 have both. Loop step 2 was skipped.

- **Our side is recoverable** — #37 §0 has the nine starters with freeze-time
  projections and the bench. Transcribe it to match the week 4 file's schema.
- **Opponent side is not recoverable from the repo.** Needs the week-ending Yahoo
  matchup export the user is uploading.

Consequence: `regret = best legal lineup − started` cannot be computed, and the four-week
series in `data/weekly/README.md` (wk1 19.76, wk2 2.50, …) breaks without it.

Schema warning carried from #37 §same: `2026_week04_opponent.csv` originally shipped a
**stray empty 11th column** that pushed `actual` into field 12 and returned NA for every
opponent. It was fixed. Do not reintroduce it — check the column count on write.

### 2b. `rosterchanges_league_team` is NOT a roster snapshot. Confirmed this session.

Used `yahoo_week5_rosterchanges_league_team_2026-10-07.csv` to reconstruct both rosters.
Its `Roster Status` column does carry fantasy team names, and the counts look right
(15 ours / 16 theirs). **It still disagreed with #37 §0 on 3 of 15 slots:** listed
Ferguson (dropped 10-07), Butker, and **Ravens DEF**; omitted **Hockenson, Higbee, and
the Jaguars**. Yet Tate and Gordon II — both 10-07 waiver adds — were present. So it is
mid-transaction and internally inconsistent, not merely stale.

This is the `CLAUDE.md` "`rosterchanges_*.csv` is not trustworthy" rule collecting a
second debt, on a different file than the IR one. **Rosters come from the position
exports (`_qb_`, `_rb_`, `_wr_`, `_te_`, `_k_`, `_def_`) via
`dev/weekly/read_yahoo_week.R`, not from any `rosterchanges_*` file.**

Worth adding to `CLAUDE.md` once confirmed against the week-ending export.

---

## 3. Already-uploaded files the user may not have mentioned

`git status` shows **14 untracked `*_2026-10-11.csv` files** already sitting in
`docs/uploads/week_5_data/` — a full Sunday export set (def, k, qb, rb, te, wr, wrt,
gamedaycalls, injuries, 4x rosterchanges). The directory now holds **three** dated
vintages: 10-06, 10-07, 10-11, and the incoming week-ending set makes four.

**Say which vintage you read, every time.** The week 5 decision doc names
`*_2026-10-06.csv` as its source of record; the retro should name the week-ending one.
Mixing vintages inside one table is how the #37 §6 DEF-format trap happened.

---

## 4. Traps that apply to the retro specifically

All already in `CLAUDE.md` — listed here because the retro walks straight into them.

1. **Yahoo weekly position exports carry projections, not actuals.** Decimal TD counts
   are the tell. Actuals come from `load_player_stats(2026)` scored through
   `score_player_week()` with `load_config("scoring")`. The config loader is
   `load_config("scoring")` — there is no `load_scoring_config()`; I guessed that name
   this session and it errored.
2. **DEF never joins on name.** Join on the `Team` abbreviation and `stopifnot()` the
   map. "New York" cannot distinguish NYG from NYJ. Pattern in
   `dev/weekly/roster_vs_wire.R`.
3. **DST is not in `score_player_week()`.** Per-player only, by design. Derive DST from
   `load_team_stats(2026, summary_level="week")` + the `config/scoring.json` tiers, as
   `dev/weekly/dst_test.R` does. Worth ~14% of a weekly total — do not let it read as 0.
4. **Invisible private-use-area chars in Yahoo headers.** `"Fantasy Fan Pts"` is really
   `"Fantasy Fan Pts"` with a sort-arrow glyph, so a bracket lookup returns **NULL
   rather than erroring**. Handled in `read_yahoo_week.R`; do not simplify it out.
5. **Do not score "do the multipliers work" in the retro.** #37 §4 / `CLAUDE.md`: the
   backtest is inconclusive by construction at n=4 weeks and always will be. Signal:noise
   ~1:10, needs ~1,000 player-weeks. See memory `single-seed-bars-underpowered`.

---

## 5. Retro shape, per the loop in `CLAUDE.md`

Append to `## Retro` in `data/weekly/2026_week05_decisions.md`. **Never edit above that
line.** Then:

1. Score **each pre-registered kill condition** y/n. The ledger is §6b of that doc, and
   §204-220 lists the carried conditions — the Bengals >21.0 streamoff, D9 Boston<Sutton,
   and the DST rule whose **>3pt kill bar #37 §4a retired**. A retired bar still gets
   recorded as retired, not silently dropped.
2. **Separate "decision wrong" from "outcome bad."** Week 1 proved they differ.
3. Compute regret, append to `data/weekly/README.md`. Needs §2a fixed first.
4. Check the three §2 decision reversals from #37 landed as intended: Tate started over
   Gordon II (the spread tiebreak's first live use), Boston at FLEX, Sutton benched.
   **This is the first real outcome on the reversed rule** — log it, and resist reading
   one week as evidence either way.

**n = 5. Fit nothing.**

---

## 6. Open, carried forward from #37 §7. None of it is this week's work.

1. **Push.** 6 commits ahead of upstream on `week3-gameday`, no PR.
2. **wk13 zero DEF** — flagged since #34, still unlogged. #37 §1 says the Bengals claim
   failed, so the wk13 fix it was meant to buy did not land.
3. **wk11 loses four at once**: Stafford, Adams, Boston, Higbee. TE covered (Hockenson),
   QB covered (Mahomes), **WR1 and WR2 are not.** Solve before wk9.
4. **wk10 loses Odunze + Sutton.** Sutton droppable → may self-solve.
5. **Etienne IR reactivation** — still NO, bye 8, unexamined since #34.

Also standing: Yahoo API access application **still not submitted**
(`https://sports.yahoo.com/developer/access/`). Manual paste remains the path.
Do not re-run the probes; `CLAUDE.md` has all twelve.

---

## 7. Suggested skills

- **`/caveman`** — repo rule, docs are written in it. This handoff is. The retro append
  and any `CLAUDE.md` edit should be too.
- **`/handoff`** — at the end of the retro session, to write the numbered successor
  (**#39**, file prefix `-32-`) into `docs/handoff/`. The skill writes to temp by
  default; **move it into `docs/handoff/` and add a README row** — that is a repo rule
  the skill does not know. Note the file prefix and the README index number differ by
  seven (this doc is file `-31-`, README row 38).
- **`/revise-claude-md`** (`claude-md-management:revise-claude-md`) — §2b's
  `rosterchanges_league_team` finding is a new silent trap and belongs in the conventions
  list once the week-ending export confirms it.
- **Skip `/diagnose`, `/tdd`, `/code-review`.** This is an analysis session on frozen
  data, not a code change. If a `dev/weekly/*.R` harness does get written, it is
  throwaway and gets referenced from the decision doc, not tested.

**Do not spawn subagents.** `CLAUDE.md` and the session rules both say so, and the
`verify` agent has nothing to verify here.

---

## 8. Two things that cost time this session, so you can skip them

- `readr` **is not installed** in this renv. Use `read.csv(..., check.names = FALSE)`.
  `devtools` is also missing and `load_all()` fails — `source()` the `R/*.R` files you
  need. Known, in `CLAUDE.md`.
- `rtk` (the bash hook) **strips timestamps from `ls -l`.** Use
  `stat -f "%Sm %N" -t "%Y-%m-%d %H:%M"` to check file staleness.
