# Handoff #55 — Wk10 Tue done. Two goodwill trade offers out. Cruise control OFF.

Supersedes #54. Authority for wk10 = `data/weekly/2026_week10_decisions.md` (card, trades, log lines at
bottom). Wk9 scored, retro fixed, everything below committed with this doc.

## 1. Mode change

- #54 cruise control **ended**: 5-4, 4th after wk9 W 107.46-84.86 v Steel City. P(top 4) **9.3% mean /
  8.5% latest** > 3% resume bar. User re-engaged, sending trades.
- User rules this session (CLAUDE.md updated): ppg check before ANY trade reaches user; contender
  partner ppg >= 0; **name trades by players, not codes**; one offer per message.

## 2. State, Tue 11-10 night

| item | state |
|---|---|
| roster | Miller dropped, Tate activated (Tate `Q` -> not IR-eligible). 15 active + Adams IR. Brown claim landed (`TXN` row in) |
| offer A, Steel City (2-7, P ~0) | **Brown + Hockenson -> Ja'Marr Chase (CIN WR) + Colston Loveland (CHI TE)**. +9.7 / +9.9pp. SC ppg −10.6 -> fails ADR 0012 on purpose: goodwill ask, user's call. Note sent (honest "not even" pitch) |
| offer B, Michelle (3-6, sim **10.3%**) | **Tre Tucker -> Jahmyr Gibbs (DET RB)** 1-for-1. +22.5 / +18.4pp. Michelle ppg −11.8. Note + Slack sent |
| both | disjoint players -> either lands alone. Both land ≈ +35-40pp (est. from 2-for-2 Gibbs combo +40.1/+36.3) |
| cancelled / declined | J1 (Jazzy) cancelled 11-10. D1 (Dave’s), K2 (Kevin) declined |
| parked | Kevin: Javonte Williams + Tucker -> Olave + Nabers (+4.5/+4.8pp, Kevin ppg +0.46). Shares Tucker w/ Gibbs offer. User: Kevin 4-5 likely holds out |

## 3. Next — on a trade reply (user pastes it)

| reply | do |
|---|---|
| Steel City no / veto | send **Brown + Hockenson -> Garrett Wilson (NYJ WR) + Loveland** (+1.8/+0.3pp, SC ppg +0.47, fair). "Found one that's actually better for you." |
| Michelle no / veto | send **Javonte Williams -> Gibbs** (+13.7/+11.5pp, Michelle ppg −6.3) |
| no reply ~2 days | treat as no. Never nudge (comms advice) |
| counter | price both bases in `lead/wk10_chase.R` / `wk10_gibbs.R` pattern before any yes |
| accepted | trade processes ~2 days later (League Votes). Roster shows in next Yahoo pull; `TXN` = wire moves only. Re-run `playoff_odds.R` |

- Veto risk real: rivals Dave’s 41%, Kevin 36%, Mitchell 20% lose if we jump. Deadline 11-28; get accepted by ~11-26.
- Gibbs offer uses Tucker -> Kevin offer dead if it lands; Kevin would need a rebuild (re-screen `lead/wk10_search.R` shape, ppg >= 0).

## 4. User to-do this week (not confirmed done)

1. Claim **Ravens** DST (v LAC, opp implied 16.5), drop Chiefs. Fallback Texans.
2. Thu before TNF: lineup re-read (card in decisions log). Odunze + Loveland CHI bye wk10.
3. Sun **before 9:30am ET**: Brown (`Q`, NE @ DET) `O` -> Boston. If Chase landed, Chase starts.

## 5. Tue 11-17 after-MNF loop

Exports -> `pull_nflreadr.R` -> wk10 scores into `2026_league_schedule.csv` -> `schedule_check.R` ->
add wk10 to `EX` in `ceiling_vs_margin.R` (late = latest clean wk10 pull, early = `2026-11-10`) ->
`predictions.R score` -> `leaguewide_retro.py 10 <proj> <act>` (now uses lock-time `Roster Status`) ->
odds. Wk11 v Kevin.

## 6. Suggested skills

- `yahoo-ff-collector` — Thu re-read / Tue 11-17 pull.
- `caveman` — any doc edit (repo rule).
- `handoff` — end of session.
