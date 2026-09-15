# ffdraft Handoff #26: kicker gap closed via waiver. Week 1 lineup set. No code written.

**Local**: `/Users/jasongrahn/R-projects/ffootballer`
**Date**: session ran **2026-09-08 night**; doc filed 2026-09-11. Filename carries the
file date so index order stays read order — the football facts below are as of 09-08.
**Prior (football)**: `docs/handoff/ffdraft-handoff-20260908-17-SEASON-START.md` (#24).
#25 (`20260910-18`) is a tooling side-track, unrelated.
**Git**: on `main` at `93c0bda` (PR #2 merged). Local branch `draft-day-official-results`
deleted. **Working tree clean. Zero commits this session — no code, no config changed.**

This was a roster-operations session, not a build session. Read #24 for engine state.

---

## 1. Kicker gap: closed, pending

#24 §2 Defect 1 — drafted zero kickers, `defer_until_round K: 16` in a 15-round draft.
Config already fixed in `422676e`. Roster consequence fixed tonight, in Yahoo, by hand.

**Waiver claim placed: ADD Chase McLaughlin (K, TB) / DROP Josh Jacobs (RB, GB).**

- League waiver time = **2 days**. Claim processes **~Fri 2026-09-11, early AM ET**.
- McLaughlin's Week 1 game: **TB @ CIN, Sun 2026-09-13 13:00 ET**. Clears in time.
- Every undrafted player was waiver-locked post-draft. No instant-add path existed.
  Not a mistake, not avoidable.
- Waiver priority likely #1 — Yahoo seeds inverse draft order, we drafted slot 10.
  Unverified, and 9 of 10 teams already rostered a K, so competition unlikely.
- Jacobs was status `CEL`, projected 0.00. Dropping him costs nothing.

### Why McLaughlin, from `tar_read(draft_board)`

All 5 of our board's top-5 K were drafted. Best remaining, by VOR:

| K | Team | 2025 PPG | G | Bye | VOR |
|---|---|---|---|---|---|
| **Chase McLaughlin** | TB | 9.18 | 17 | 10 | **15.4** |
| Jake Bates | DET | 8.94 | 17 | 6 | 11.4 |
| Chris Boswell | PIT | 8.88 | 17 | 9 | 10.4 |

Nine K drafted: Myers, Fairbairn, Aubrey, Dicker, Little, Loop, Mevis, Reichard, Pineiro.

---

## 2. Week 1 lineup: set, verified, leave it

Set via Yahoo **Start Active Players**. Starters project **91.6** with K empty.

QB Stafford 17.81 / RB J.Williams 14.04 / RB Henry 14.09 / WR Adams 10.55 /
WR Odunze 9.40 / TE Ferguson 7.47 / FLEX Etienne 12.84 / K empty 0.00 / DEF NE 5.43

Checked every available swap. **All worth <1 pt.** Do not re-litigate:
- Stafford (17.81) over Mahomes (17.46) — 0.35 pts, and our board had Stafford QB1
  by VOR (44.95) vs Mahomes #4 (40.6). Consistent. Confirms #24 §4.
- Odunze (9.40) over Sutton (9.00) — 0.4 pts.
- Etienne (12.84) over Gainwell (8.69) at FLEX — clear.

### Contingency, the only live one

**Odunze is Questionable, Sun 13:00.** If ruled out -> start **Courtland Sutton**
(DEN @ KC, **Mon 20:15**). Sutton's game is after Odunze's, so the swap stays legal
Sunday morning. Wan'Dale Robinson also Q.

---

## 3. Timeline for whoever picks this up

| when | what |
|---|---|
| Wed 9/9 20:20 ET | Patriots DEF locks. No alternate DST rostered — no decision. |
| Thu 9/10 20:35 ET | Stafford + Davante Adams lock (both LAR vs SF). |
| **Fri 9/11 AM** | **Confirm claim processed. Slot McLaughlin into K.** |
| Sun 9/13 pre-13:00 | Check Odunze status. Swap Sutton if out. |
| Mon 9/14 20:15 | Mahomes / Sutton games. Last slot to lock. |

Roster after claim clears: RB 6, WR 4, QB 2, TE 1, K 1, DST 1 = 15.

---

## 4. Still open from #24, untouched tonight

- **#24 §7 — `CLAUDE.md` is stale in two places.** `## Current status` still says
  "Nothing built yet. Next action is Phase 0." League facts block still says
  **17 rounds**; real answer is **15** (9 starters + 6 bench; 2 IR not drafted).
  **Fix both before starting the picker.** Nothing this session changed that.
- **#24 §6 — next project is the in-season weekly start/sit picker.** Scoped in
  `docs/handoff/ffdraft-handoff-20260907-14-INJURY-SIGNAL-START-HERE.md` (#21).
  First decision: re-check what `nflreadr` gives **weekly**; `CLAUDE.md`'s data
  constraints were all written against draft-time needs.
- Dead, do not revive: VONA as selector, `p_available`/`survival_display()`,
  status-column wiring, Yahoo/ESPN/Sleeper API re-investigation. See #24 §6.

## 5. Session notes

- `nflreadr::load_schedules(2026)` **works** and returned the real Week 1 slate
  (Wed 9/9 NE@SEA opener, Thu 9/10 SF@LAR, Sun 9/13 main slate, Mon 9/14 DEN@KC).
  Useful for the picker; first verified in-season data route.
- `tar_read(draft_board)` columns are `player, pos, team, ...` — **`pos`, not
  `position`**. Costs a failed call every time.
- Stray `k.csv` was written to repo root by a scratch script and removed. Tree clean.

---

## Suggested skills

- **`caveman`** — repo doc rule, any doc a later session writes
- **`to-prd`** — scope the weekly picker before any code
- **`handoff`** / **`session-close`** — close the next one
