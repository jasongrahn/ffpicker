# Handoff #42 — Week 6 frozen at 108.71. Two moves made. Six conditions armed, only two have power.

Written 2026-10-14 Wed evening. Branch `week3-gameday`, HEAD `c5da258`.
Prior: `docs/handoff/ffdraft-handoff-20261014-34-WEEK6-WAIVERS-LANDED.md` (#41).
Index: `docs/handoff/README.md`.

**Authority for week 6 is `data/weekly/2026_week06_decisions.md` §6.** It supersedes §2
and corrects §5. Do not re-derive any of it. This doc is the pointer plus what is open.

---

## 0. State. 3-2, 5th. Week 6 frozen. Roster 15, zero open spots.

Two commits this session:

| commit | what |
|---|---|
| `66394cc` | #41 §1 items closed, bye weeks corrected, wk6 exports added |
| `c5da258` | **FINAL.** D10 drop Bates, A4 add Strange, S1+S2 lineup, §5 corrections |

**Us 108.71 vs Owl Out Blitz 108.65 — but theirs is unfinished. See §2.**

Lineup, both csvs, and all reasoning: `data/weekly/2026_week06_decisions.md` §6d.
Do not re-type the lineup from this doc; read it there.

---

## 1. !! FREEZE DEADLINE MOVED. Sun 2026-10-18 **9:30am ET**, not 1:00pm. !!

**Strange plays JAX vs HOU at Sun 9:30am.** He is a legal replacement at TE and FLEX, so
`min(kickoff of legal replacements)` binds those slots 3.5h earlier than the rest.

Second time this season the binding deadline was not a player's own kickoff (wk2 Adams
was the first). #41 §1 and the log's own §5f both say 1:00pm — **both are superseded by
§6e.**

A Thu/Fri look is still free and spends nothing.

---

## 2. Opponent is NOT finished. Their 108.65 is a floor. Expect ~116-119.

`(Empty)` bench slot on the matchup page -> they dropped Stroud and have not refilled.

| | now | available |
|---|---|---|
| **DEF** | Vikings **0.00**, MIN bye | **+5 to +8** — the empty spot makes it streamable |
| **QB** | Bryce Young 16.68 | Caleb Williams **19.09** (`Q`) -> **+2.41** |

**Yahoo's "51% favorite" is computed against an unfinished lineup. Do not quote 49% as
the real line.** We have no counter-lever — both our DEFs are rostered and Chiefs is the
correct start (opp implied 17.00 vs Browns 18.00).

**This corrects #41 §1a's "+5-8 available" reasoning *and* this session's own §5e, which
claimed they were full at 15.** §5e read a Wednesday position export as a live roster.
That is the `rosterchanges_*` trap in `CLAUDE.md` reappearing in a file not on its list:
**an export is a snapshot, a roster is not.**

---

## 3. Tests armed. Only A4 and W3 can resolve this week. Say so in the retro.

Full table with states: `data/weekly/2026_week06_decisions.md` §6f.

### 3a. Real one-week power. These two are the week's actual learning.

- **A4 — Strange snap% < 60.** Written on *snaps, not points*, deliberately. His range is
  68/83/77/87/81 — tight, because snap share is near-deterministic given a role. A sub-60
  falsifies the role read. Points could not do this at n=1.
- **W3 — Tate < 6 targets.** **Terminal observation of a pre-registered 2-week test**
  (wk5 = 5). Second strike -> Tate is the drop. Matters now: roster is full, so the next
  add finally has a cost.

### 3b. Underpowered BY CONSTRUCTION. Logged as deposits, not results.

**S1** (Strange vs Higbee), **S2** (Tate vs Odunze), and the weekly `regret` number are
the same arithmetic. S2's edge is **1.23 pts**; variance between two actuals inside a
narrow band is **8-9 pts**. That is the ratio that killed the spread tiebreak, which
needed **215 discordant pairs** to resolve.

**-> If Odunze outscores Tate, that is NOT evidence S2 was wrong.** Pre-registered here
so the retro cannot relitigate it after seeing the outcome. See
`single-seed-bars-underpowered`.

### 3c. Explicitly NOT under test. Do not score these on week 6.

| | why |
|---|---|
| DST rule | Validated league-wide n=128, edge **0.39 sd**, >3pt kill bar retired. KC's score says nothing about the rule |
| K rule | **Bye-forced a 2nd straight week** (Bates dropped, Butker the only K). **Wk6 is not a pass.** First real test wk7 |
| Yahoo proj supremacy | Settled at n=221, MAE 4.29 vs our 6.71. Not weekly |

### 3d. One genuinely new observation, n=1, not a test.

**Does the opponent fill the empty slot with a DEF?** We have never had data on in-season
opponent behaviour — the Yahoo-ADP blind spot was a *draft*-time problem and this is its
in-season analog. Nothing in the repo models what the other nine managers do after wk1.
Record it in §6c as the first datapoint. Do not build on n=1.

---

## 4. Two process failures this session. Both generalise. Higher yield than any S2.

Both are recorded in `data/weekly/2026_week06_decisions.md` §6b and §6c as defects, not
quietly fixed.

1. **§5d ranked the wire and concluded "no add" — never filtered for *plays in week 11*.**
   A ranking with the constraint unapplied is not a ranking. `CLAUDE.md`'s
   need-before-candidates rule says compute depth first; it does not say the *candidate*
   pool inherits the same filter. **It must.**
2. **§5e read an export as a roster** (see §2 above).

Candidate for `CLAUDE.md` if either recurs. Not added yet — one occurrence each.

---

## 5. Corrections to #41 that are now load-bearing.

| #41 said | truth, from `load_schedules(2026)` |
|---|---|
| KC bye 10 | **KC bye 5 — already past.** Butker + Chiefs DEF play every remaining week |
| CLE bye 9 | **CLE bye 11** |
| "Browns need a wk9 replacement" | **False alarm. ZERO DEF holes remain all season** |
| H1 is a drop question | **Downgraded to informational.** Strange now covers wk11 TE |

**Week 11 is the only zero-slack week.** LA bye 11 **and** CLE bye 11 removes Stafford,
Adams, Higbee, Boston, Browns DEF. Legal lineup is 9 bodies for 9 slots. Strange/Higbee
byes are complementary (JAX 7, LA 11), which is why the add cost nothing structurally.
Arithmetic in §5c.

---

## 6. Next session.

1. **Thu/Fri (free):** matchup page — did a DEF appear in their empty slot? Did Caleb
   Williams clear `Q`? Append to §6c. Two glances, no export needed.
2. **Sun before 9:30am:** final check. Deadline is §1, not 1:00pm.
3. **Monday:** retro. Append below `## Retro`, **never edit above it**. Score all six of
   §6f, and **mark A4/W3 as resolved and S1/S2/D10/H1 as deposits** — do not write a
   verdict a sample of 1 cannot support. Fill `actual` in both csvs,
   `regret` -> `data/weekly/README.md` (wk1 19.76, wk2 2.50).
4. Pierce (PHI RB) stays unowned-and-watched: 77% wk5 snaps but **conditional** on
   Barkley (`Q`, hamstring). Rejected for Strange because RB is our deepest room. No spot
   free now — would cost Browns DEF, the next-cheapest drop after Bates.

---

## 7. Open, carried. None of it is week 6's work.

1. **Push. Still no PR, 29+ ahead of `origin/main`.** Oldest carried item.
2. Etienne IR reactivation — still NO, unexamined since #34.
3. Yahoo API application still not submitted
   (`https://sports.yahoo.com/developer/access/`). **Do not re-run the probes**;
   `CLAUDE.md` has all twelve.

---

## 8. Environment. Deltas from #41 §7 only.

- **`load_player_stats()` has no `recent_team`** — the column is `team`. Also no
  `fantasy_points_half_ppr`.
- **`load_schedules(2026)` uses `LA`, not `LAR`.** A `LAR` lookup returns `NA` silently —
  this is the name-join debt again, in the team dimension.
- Week 6 DEF export has **no `Player ID` column** (the other five position files do) and
  its `Roster Status` sits at a different column index. Byes in Yahoo's `Bye` column
  disagreed with `load_schedules()`; **`load_schedules()` won.**
- `git commit -m "$(cat <<'EOF' ...)"` fails in this shell — apostrophes break it. Use
  `git commit -F <file>`.

**n = 6. Fit nothing.**

---

## 9. Suggested skills

| skill | when |
|---|---|
| **`caveman`** | Repo rule — all docs in this style. Already applied here |
| **`handoff`** | End of next session. **Write to `docs/handoff/`, NOT the OS temp dir** — the skill defaults to temp; this repo's index records that nine docs lived in `/tmp` until a macOS purge nearly lost them |
| `diagnose` | Only if a harness breaks. The weekly loop is not a debugging task |

**Do not reach for `tdd`, `improve-codebase-architecture`, or `to-issues`.** In-season
work is a decision log, not a build. The draft engine is done.
