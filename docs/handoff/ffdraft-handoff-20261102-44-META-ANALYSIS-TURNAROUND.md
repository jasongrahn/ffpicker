# Handoff #51 — Next session: free-rein meta-analysis. Goal: turn the season around (4-4, P(top 4) ~3%).

Written 2026-11-02 Mon. User: next conversation gives the agent "free reign on a meta analysis of
everything we've done in order to turn our season around." -> scope + method = agent's call.
Tue 11-3 ops = #50 `ffdraft-handoff-20261102-43-WEEK8-LOST-TUE-OPS.md` — **NOT superseded.**

---

## 0. READ FIRST.

- **Mandate:** audit everything, draft -> wk8: what worked, what cost wins, what to stop. Output =
  ranked levers for wks 9-15, each priced in **wins / P(top 4)**, with evidence + kill condition.
- **Clock beats analysis.** Tue 11-3: waivers + wk9 pull + TR1/TR2 send (#50 §2). Thu 11-5: wk9
  freeze before TNF; Max's must accept TR2 by then for wk9. Trade deadline 11-28, accept by ~11-26.
  Session on/after Tue with #50 undone -> ask user which first. A finding that changes TR1/TR2 ->
  surface before the send.
- Rules = `CLAUDE.md`: manual Yahoo pulls only (collector runs from claude.ai), no scraping,
  commit only when asked, caveman docs, explain football, pre-register kills, price in wins. User
  reads in ADHD shape: next action first, <= 5 items.

## 1. Where we stand.

- **4-4** (wk8 L pending Yahoo, #50 §1). All 10 teams' scores: `data/weekly/2026_league_schedule.csv`.
  Left: wk9 Steel City, 10 Dave's, 11 Sunday Kevin, 12 Mitchell, 13 Jazzy, 14 Max's, 15 Owl Out.
  Top 4 of 10 -> playoffs wks 16-17; tiebreak PF.
- P(top 4): 3.3% (10-21) -> 5.1% (10-28) -> **~2.7% after wk8 L** (10-28 conditional; re-run).
  Underdog in every remaining game, 27-35% (10-28). #45: roster 9th of 10, ~9 wins needed.
- Exchange rate 10-28: +1 pt/wk ≈ +0.8pp P(top 4), +0.08 wins. Best known moves: TR1 + TR2 ->
  11.0% together (10-28).
- **Scale check:** 27-35% at margin sd 29.8 = typical deficit ~11-18 pts/wk. No single move closes
  that -> stack moves and/or change the shape of the bet.

## 2. Evidence map. Read, don't re-derive.

| what | where |
|---|---|
| standing rules + key numbers | `CLAUDE.md` |
| decisions + evidence | `docs/adr/0002`-`0011`, index `docs/adr/README.md` |
| weekly decisions, kills, retros | `data/weekly/2026_week02`-`08_decisions.md` (no wk1 log) |
| regret per week | `data/weekly/README.md` |
| sim, odds, trades | `dev/weekly/league_sim.R` <- `playoff_odds.R`, `trade_finder.R`, `predictions.R` |
| gate + noise constants | `dev/weekly/ceiling_vs_margin.R` |
| every harness | `dev/weekly/` — each ADR names its own |
| session history | `docs/handoff/README.md` (51 rows) |
| draft era | `PLAN_1.md`, ADRs 0003-0006, `docs/review/001-model-critique.md`, `docs/prd/001-*`, `docs/backlog/001-*` |
| raw data | `docs/uploads/week_N_data/` (all 10 rosters, proj + `_actual_`), `data/nflreadr/pull_2026.rds` |

## 3. Settled — reopen only with new evidence.

Lineup layer at ceiling (wks 1-4: 0.80 choice regret v 73.62 projection error, ADR 0010). 15% band
-> higher raw proj. Yahoo proj = best one-week estimate (MAE 4.29). DST on opp implied (+1.92/wk).
K: hold (null, n 214). Spread tiebreak retired. Game script = RB slope only. Gate passed (r +0.54,
n 25).

## 4. Seed hypotheses. Not a mandate — rank, test, or drop.

1. **Luck or roster?** All-play record wks 1-8 v 4-4; PA rank; per loss: our proj miss v their
   spike v roster gap. Leads in regret table: wk1 hindsight-optimal 121.56 > opp 118.96. Wk4 opp
   98.58 there v 123.98 in schedule -> reconcile (likely a frozen-lineup replay, not their score).
2. **Underdog variance.** Dog every week -> P(win) = Φ(μ/σ) rises with σ. dP/dσ ÷ dP/dμ = |μ|/σ
   ≈ 14/30 -> +1 pt of margin sd ≈ +0.47 projected pts. `CLAUDE.md` "a stack that costs projected
   points to buy shared upside loses" has no underdog lens. Size it in the sim: QB + own WR/TE
   stacks, boom-bust bodies, not sharing NFL teams with opponent's starters. Wk8 had Kyler +
   Hockenson (both MIN).
3. **Bigger trades.** TR1 + TR2 = +5.9pp. Untried: 2-for-1 consolidation, sequencing, every
   non-contender (arming them costs nothing). QB = weak currency (wire has 16+ pt QBs) -> test:
   trade every QB, stream QB off the wire.
4. **Waivers as a weekly lever.** Rolling list, no FAAB, priority cheap -> stack claims. Upside
   stashes, handcuffs, bye holes wks 9-15 (need-before-candidates order, `CLAUDE.md`).
5. **Process audit.** Effort v wins: lineup coin flips (wk8 QB argued 3x for 0.20 expected), K,
   spread -> v roster quality. Which tests changed a decision, which were overhead. Retire / add.

Also: calibration — wk8 model P(win) 0.322 v Yahoo-implied ~0.43; T4 (wk8 log §5) +
`predictions.R score` history. Too pessimistic -> odds + exchange rate shift. Known gaps: #49 §3
(`read_yahoo_week()` oldest-pull bug, sim base blind to fresh injury); DST not in
`score_player_week()` (approx in `dev/weekly/wk8_sunday.R`, unvalidated).

## 5. Deliverable, suggested.

- `docs/review/002-season-meta-analysis.md` (caveman): <= 5 levers ranked by ΔP(top 4), each with
  evidence, cost, pre-registered kill; stop-doing list; wks 9-15 plan. Rule changes -> ADR +
  `CLAUDE.md`.
- To the user: ADHD shape — first line = the one move to make now.

## 6. Suggested skills.

| skill | when |
|---|---|
| `grill-with-docs` | stress-test each lever against ADRs + `CLAUDE.md`; update docs inline |
| `caveman` | review doc, ADRs (repo rule) |
| `dataviz` | any chart (P(top 4) paths, win prob v variance) |
| `handoff` | end of session -> #52 + index row |
