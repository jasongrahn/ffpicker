# Handoff #46 — CLAUDE.md slimmed 648 -> 388, history -> ADRs 0002-0011. Next: week 7 scoring + trade re-run.

Written 2026-10-27 Tue. Branch `week3-gameday`. **All of #45's and this session's work
UNCOMMITTED** (§6). Prior: #45
`docs/handoff/ffdraft-handoff-20261021-38-LEAGUEWIDE-SIM-BUILT-CLAUDEMD-REVIEW-NEXT.md`.
Index: `docs/handoff/README.md`.

---

## 0. READ FIRST. Next session is football again.

- **Week 7 is final** (MNF 10-26). Scoring order: `CLAUDE.md` § Commands, "After MNF".
  `docs/uploads/week_7_data/` holds only the 10-21 pre-kickoff pulls — **no `*_actual_*`
  exports yet**. User supplies them (`yahoo-ff-collector`) + one screenshot: Yahoo ->
  League -> Matchups -> Week 7, all 5 games.
- **Trade re-run was scheduled for today**, Tue 10-27: `data/weekly/2026_week08_trade_ideas.md`
  §5, ~10 min. TR1 + TR2 parked, **NOT SENT**. **Trade deadline unknown — ask the user
  first**; it decides how urgent this is.
- `CLAUDE.md` is new. Read it whole — it replaced 648 lines. Evidence behind any rule:
  `docs/adr/`, index `docs/adr/README.md`.

## 1. What this session did. Pointers only.

| path | what |
|---|---|
| `CLAUDE.md` | **REWRITTEN.** 648 -> 388 lines. Rules + 1-line evidence. New: Commands, in-season Layout, Season objective, League-wide sim, #45 §2a traps, Method |
| `docs/adr/0002`-`0011`, `docs/adr/README.md` | **NEW.** History + closed investigations, one decision per file |
| `PLAN_1.md` | Snake turn section + sweep mode moved in; gap table recomputed for 10 teams (was 12). L104 pointer fixed |
| `docs/handoff/README.md` | #46 row. Rows #43-45 moved back inside the table (were appended below the footer). Filename-convention line corrected |
| auto-memory | **10 of 11 files deleted** — content now in CLAUDE.md or an ADR. Only `token-tooling-audit` (user tooling) left |

## 2. Decisions settled with the user. Do not re-litigate.

1. CLAUDE.md = standing rules + 1-line evidence (key number + path). Tables and narrative ->
   ADRs.
2. History home = `docs/adr/`, one per decision. User chose this over a single
   closed-investigations file.
3. Draft-era -> ADRs 0003-0006 + `PLAN_1.md`, behind one pointer line.
4. No season state in CLAUDE.md. Live state = newest handoff; roster truth = decision log.
5. Project facts live in git (CLAUDE.md or ADR), **never auto-memory**. Now in the CLAUDE.md
   header.
6. **Yahoo API: DENIED — "not enough information". User: go without it, not re-applying.**
   **Drop it from every open-items list**; #38-#45 carried it for weeks.
   `docs/adr/0002-yahoo-api-manual-paste.md`.

## 3. Found during the audit.

- **`pkgload::load_all(".")` works.** Only `devtools` is missing. #45 marked the old
  "`load_all()` fails, `source()` the files" line "verified true" — it checked `devtools`
  alone. A check of one half certified the whole line.
- Dead refs fixed: `PLAN.md` -> `PLAN_1.md`; pre-09-15 handoffs live in
  `docs/handoff/drafting/`.
- **Nothing-lost check** on the rewrite: every code, quoted and decimal token of
  `git show HEAD:CLAUDE.md` searched in new CLAUDE.md + `docs/adr/*.md` + `PLAN_1.md`. 374
  tokens, 15 not carried, all deliberate: dead paths, stale `devtools` workaround, wk1-2
  regret (already in `data/weekly/README.md`), invisible-header example (now described in
  words). It also caught the one real loss — DST evidence -> became ADR 0011. Rerun the
  same check on the next large doc cut; ~20 lines of Python.
- Stale, **not fixed** (out of scope): `PLAN_1.md` config example `"rounds": 17` (real 15);
  `optimal()` multi-position bug in 4 files (named in CLAUDE.md, code untouched);
  `token-tooling-audit` memory's "re-check in a week" dates from 09-10.

## 4. Season state. Authority = decision log, not this doc.

Carried from #45 §4, not re-derived — docs session:
- **3-3 entering wk7.** Wk7 v Monday Night Madison, frozen 105.27 v 100.60, P(win) 0.56.
  **Result unknown to this session.**
- M1: Kyler Murray in 10-21. Drop recorded as **Butker — user never named it; verify on
  the first wk8 export.**
- Trades TR1 (Madison) + TR2 (Max's) parked, NOT SENT. P(top 4) 3.3% -> 8.3% if both land.
- Open: push owed (**37 ahead** of `origin/main`, no PR); Etienne IR reactivation
  unexamined; stream detector blocked.

## 5. Next session, in order.

1. Ask: **trade deadline?**
2. User pulls wk7 actuals + wk8 exports (`yahoo-ff-collector`) + the wk7 Matchups screenshot.
3. Post-MNF chain: `CLAUDE.md` § Commands. Kill conditions: decision log L1 +
   `dev/weekly/score_week07.R`.
4. Trade re-run: trade ideas §5 — each offer still win-win, players healthy, partner still
   owns them.
5. Week 8 decision log + freeze — weekly loop in `CLAUDE.md` § Live state.

## 6. Uncommitted. git status 2026-10-27.

```
 M CLAUDE.md  PLAN_1.md  docs/handoff/README.md                          <- #46
 M data/weekly/2026_week07_decisions.md  dev/weekly/leaguewide_retro.py   <- #45
?? docs/adr/0002 ... 0011, docs/adr/README.md                             <- #46
?? docs/handoff/ffdraft-handoff-20261021-38-*.md (#45), -20261027-39-*.md (#46)
?? data/weekly/{2026_ceilings.rds, 2026_league_schedule.csv, 2026_trade_scan_wk7.rds,
   2026_week07_leaguewide_predictions.csv, 2026_week08_trade_ideas.md}   <- #45
?? dev/weekly/{ceiling_vs_margin, league_sim, playoff_odds, predictions,
   schedule_check, score_week07, trade_finder}.R                          <- #45
```

Commit only when the user asks. `git commit -F <file>` — apostrophes break the heredoc
form. Natural split: #45's sim work, then this docs session.

## 7. Suggested skills

| skill | when |
|---|---|
| **`yahoo-ff-collector`** | First. Wk7 actuals + wk8 exports -> `docs/uploads/week_N_data/` |
| `verify` agent | Only if `R/` or `tests/` change. Command in CLAUDE.md § Commands |
| `caveman` | Repo rule for decision logs, ADRs, handoffs |
| **`handoff`** | End of session. **`docs/handoff/` as #47, not the OS temp dir** |

Do not reach for `claude-md-improver` / `revise-claude-md` this week — CLAUDE.md was just
rebuilt. New fact -> rule + key number into CLAUDE.md, evidence into a new ADR.
