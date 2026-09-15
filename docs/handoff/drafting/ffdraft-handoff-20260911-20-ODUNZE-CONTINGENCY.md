# ffdraft Handoff #27: roster complete. One live decision, Sunday morning.

**Local**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: 2026-09-11 (Fri)
**Prior**: `docs/handoff/ffdraft-handoff-20260911-19-WEEK1-ROSTER.md` (#26). Read it for
draft/engine state. This doc only records what changed since.
**Git**: branch `week1-roster-handoff`, clean at `6e2a158`. **Zero code this session.**

---

## 1. DO THIS — Sunday 2026-09-13, before 13:00 ET

**Check Bears WR Rome Odunze injury status.**

- Status as of Fri: **Questionable**. Game kicks **Sun 13:00 ET**.
- **If ruled OUT -> start Courtland Sutton (WR, DEN) in his place.**
- Why legal: Sutton plays **DEN @ KC, Mon 20:15 ET** — after Odunze's kickoff. Swap
  stays open all Sunday morning. No earlier deadline.
- Cost if wrong: Odunze proj 9.40 vs Sutton 9.00. **0.4 pts.** Start Sutton on any
  real doubt; downside tiny, zero from an inactive Odunze is total.
- Wan'Dale Robinson also Q. Not rostered as a swap — ignore.

Nothing else is live. Every other slot has locked or has no alternate.

---

## 2. What closed since #26

**Kicker gap: DONE.** Waiver claim processed. **Chase McLaughlin (K, TB)** is on roster
and slotted at K. Josh Jacobs dropped. #26 §1 fully resolved — do not re-open.

Roster = 15: RB 6, WR 4, QB 2, TE 1, K 1, DST 1.

Week 1 starters, all slots filled:

| slot | player | proj |
|---|---|---|
| QB | Stafford | 17.81 |
| RB | J. Williams | 14.04 |
| RB | Henry | 14.09 |
| WR | Adams | 10.55 |
| WR | **Odunze (Q)** | 9.40 |
| TE | Ferguson | 7.47 |
| FLEX | Etienne | 12.84 |
| K | **McLaughlin** | ~9 |
| DEF | NE | 5.43 |

**~100 pts**, up from 91.6 with K empty.

Locks already passed: NE DEF (Wed 9/9), Stafford + Adams (Thu 9/10). Last lock is
Mon 9/14 20:15 (Mahomes / Sutton games).

**Lineup otherwise settled — #26 §2 checked every swap, all worth <1 pt. Do not
re-litigate.**

---

## 3. Still open, unchanged from #26 §4

- **`CLAUDE.md` stale in two places.** `## Current status` says "Nothing built yet.
  Next action is Phase 0" — false. League facts block says **17 rounds**; real is
  **15**. Fix both before picker work starts.
- **Next project: in-season weekly start/sit picker.** Scoped in
  `docs/handoff/ffdraft-handoff-20260907-14-INJURY-SIGNAL-START-HERE.md` (#21).
  First step: re-check what `nflreadr` gives **weekly** — existing data constraints
  were written for draft time.
- Dead, do not revive: VONA as selector, `p_available`/`survival_display()`,
  status-column wiring, Yahoo/ESPN/Sleeper API re-investigation.

---

## 4. Suggested skills

- **`caveman`** — repo doc rule, any doc a later session writes
- **`to-prd`** — scope the weekly picker before any code
- **`claude-md-management:revise-claude-md`** — fix the two stale blocks in §3
- **`handoff`** / **`session-close`** — close the next one
