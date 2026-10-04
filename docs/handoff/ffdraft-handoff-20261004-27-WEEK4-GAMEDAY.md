# Handoff #34 — Week 4 gameday. Log frozen. Next session re-pulls data.

Date: 2026-10-04 **Sunday**. Branch `week3-gameday`, clean, **unpushed**.
Head `3a6d279`.

Prior: #33 `ffdraft-handoff-20260929-26-WEEK4-CORRECTIONS.md`. Still the
methodology authority (§00 `Rankings Actual` finding). Not superseded on that point.

---

## 1. State. Week 4 is frozen. Do not edit above `## Retro`.

`data/weekly/2026_week04_decisions.md` -> **`Frozen: 2026-10-02`**.

Lineup locked as logged. Four decisions landed after #33, all committed:

- **D6a** Raymond held over Odunze. Resolved on **usage**, not points — teammates
  compete for same targets -> ppg cannot settle it. Odunze snaps 48% -> 84-85%,
  held, **did not convert to targets**.
- **D6b** Sutton -> **Boston** at WR2. Supersedes D6's Robinson choice; Boston's
  claim had landed since D6 was written.
- **D10** Etienne -> **IR slot**. League's 2 IR slots **do not count against 15**
  -> freed a roster spot with **no drop**. This is the move that unblocked D11.
- **D11** **Bates** (K, Det) added K2 into the freed slot.

Both lineups rewritten at matchup-page projections, `proj_gameday`, src
`matchup_2026-10-01`. Starters reconcile to Yahoo **exactly**: ours **99.68**,
theirs **90.39**.

**`2026_week04_myteam.csv` had lagged the log** — still listed Stroud, B. Allen,
Gainwell after D8/D1/D9 reversed all three, and Sutton as a starter after D6b
benched him. Rebuilt. This is the CLAUDE.md convention collecting its debt; rule
already written, no new rule needed.

New **§3a** in the log: production read + bench check + pre-registered kill
condition. Numbers live there. Do not restate them, read them.

---

## 2. Gameday check. Run 11:09 Sun 2026-10-04. No change made.

Re-pull **DONE**: `clear_cache()` + `load_schedules(2026)` + `load_injuries(2026)`.

**Frozen is not locked.** This doc first claimed the slate had locked the roster.
Wrong, and caught by the user. Only **Boston (Cle, Thu 8:15)** was locked. **Check
the clock before asserting a lock.**

Deadline per slot is `min(kickoff of legal replacements)` — not the starter's own
kickoff. That rule moved the **QB** call up 3h25m:

| by | slot | starter (kick) | alternative (kick) | call |
|---|---|---|---|---|
| **1:00pm** | QB | Mahomes (4:25) | **Stafford (1:00)** | hold, 22.86 vs 18.66 ppg |
| **1:00pm** | FLEX | **Raymond (1:00)** | Sutton (4:25) | hold, 12.30 vs 4.07 ppg |
| **1:00pm** | RB2 | **Javonte (1:00)** | Marks (1:00) | hold, 15.17 vs 6.37 ppg |
| **4:25pm** | K | Butker (4:25) | Bates (8:20) | **held. see below** |
| locked | WR2 | Boston | — | played Thu |

**Injury reports are filed now.** **138 of 318** wk4 rows carry a `report_status`,
vs **2 of 257** on 09-30. **Nobody on the roster is O or Q.** Only Mahomes and
Adams appear at all, both Full Participation, no designation. The 09-30 silence was
an unfiled report, exactly as D10 recorded — not health, and now not silence either.

**K was the only live call.** Lines moved after the freeze:

| K | own implied | kick |
|---|---|---|
| **Bates** (Det vs Car) | **27.5** | 8:20pm |
| Butker (KC @ LV) | 26.0 | 4:25pm |

Method ranks kickers by own implied total, highest first -> prefers **Bates by 1.5**,
worth **~0.3-0.5 fp**, **under the >3pt kill bar** the streaming test runs on.
**Held Butker.** Week 5 switch stands. Open until 4:25 if revisited — a change after
freeze needs its own dated entry so the retro scores it apart from D1-D11.

Two confirmations from the same pull:

- **Henry is in the best game script available.** BAL favored **11.5** (own implied
  **27.0**). RB favored 10+ -> **1.134x** own average, and our measured table says
  **there is no blowout tax**.
- **Ravens DST opponent implied 15.5**, lowest on the board. DST is dominated by
  points allowed -> correct start. The **21.75** degrade is **wk5**, not today.

---

## 2b. Still to do.

1. **Mon 2026-10-05: append `## Retro`.** Score each kill condition y/n.
   **Separate "decision wrong" from "outcome bad"** — wk1 proved they differ.
   `regret = best legal lineup - started` -> `data/weekly/README.md`.
   Running: wk1 **19.76**, wk2 **2.50**.
2. **Fill the `actual` column** in both wk4 csvs. Schema has it, empty.
3. **Re-pull `load_player_stats(2026)` for actuals.** Week 4 is **incomplete until
   Tuesday** — MNF is Mon 8:15 ATL @ NO. Etienne is IR there, scores 0.
4. **Score §3a's kill condition at the wk6 retro**, not before.

---

## 3. Week 5, queued. Two items, both already measured.

- **Butker -> Bates** at K. Reason is implied total, not form.
- **Ravens DST re-evaluate.** Opponent implied total degrades **15.50 -> 21.75**.
  Jets at 18.5 are the comparison. Logged in D11 as **watch-only** — it was not a
  Week 4 action and must not be retro-fitted into one.

---

## 4. Open, not yet logged. Carry these forward.

| item | week | state |
|---|---|---|
| **Etienne reactivate from IR** | when cleared | D10 kill condition is *forgetting to do it*. Check every week. |
| **TE bye, zero bodies** | 14 | Ferguson is 1-deep all season. Sadiq/Waller were candidates. Roster is **full again** -> now needs a drop. |
| **DEF bye, zero bodies** | 13 | Surfaced, **never logged**. Log it. |
| **K/DST planning horizon** | — | `load_schedules()` publishes lines **exactly 1 week ahead** (wks 4-5 100%, 6-15 0%). Structural cap. Measured in #33. |

---

## 5. Traps that cost time this session. Do not re-pay.

- **`score_team_week()` does not exist.** DST cannot be scored by our code. Every
  production comparison is **skill slots only, 7 of 9**. Say so every time, or the
  number reads as comparable to Yahoo's and is not.
- **`renv` out of sync** -> `devtools::load_all()` fails. `source("R/30_scoring.R")`
  directly. Unfixed.
- **Name trap, both sides of the h2h.** Our `J. Williams` is **Javonte** (Dal, RB).
  Theirs is **Jameson** (Det, WR). Both started wk4. Do not collapse in the retro.
- **Absent nflreadr injury row is not evidence of health.** Only 2 of 257 wk4 rows
  carried a `report_status`; New Orleans had **zero** rows. Report was not filed.
  Recorded in D10.
- **Need before candidates.** CLAUDE.md rule, written after a real miss this
  session. Depth + bye tables on screen *before* the sentence "X is your hole".
- Apostrophes in player names (`Wan'Dale`) break inline `Rscript -e`. Use a
  scratchpad `.R` file.

---

## 6. Suggested skills

- **`/caveman`** — repo doc style. Already applied here. Use for the retro and any
  handoff.
- **`/loop`** — only if monitoring live scores across the Sunday slate. Poll
  interval should match the data, not the clock: box scores settle ~15 min after a
  game ends, so nothing under ~600s is useful.

No skill invocation is required to do §2. It is a data pull and a retro.

---

## 7. Standing

**n = 3. Fit nothing.** Decision logs accumulate honest test cases. They are not a
training set yet. §3a's production read is a **read**, with a kill condition scored
at the wk6 retro — not a model.
