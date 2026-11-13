# Handoff #56 — Thu 11-12. Next session Tue 11-17: wk10 loop, then the Kevin trade.

Supersedes #55. Authority = `data/weekly/2026_week10_decisions.md` (bottom log lines + `## Deferred -> wk11`).
Last commit `c4d73f8` (pushed). **Uncommitted since:** decisions log lines 11-11..11-12, #55 edits,
`lead/wk10_mich2.R` + `2026_week10_mich2_{mean,latest}.out`, this doc. Commit when user asks.

## 1. State, Thu 11-12

| item | state |
|---|---|
| record | 5-4, 4th. P(top 4) 9.3% mean / 8.5% latest (11-10) |
| wk10 v Dave’s | Yahoo (user, Thu) Dave’s 118 -> we trail ~11. Sim Tue: 100.0 v 111.9, P(win) 34%. Wire check: nothing outside 15% band (log) |
| DST | **Ravens claimed, Chiefs dropped** 11-11 (user). Add `TXN` row once a pull confirms: `"2026-11-11", ME, "Ravens", "Chiefs", "2026_week10_decisions.md DST"` (check DEF key format in `league_sim.R` TXN first) |
| Steel City offer | **OPEN, no reply** (sent 11-10): Brown + Hockenson -> Ja'Marr Chase + Colston Loveland. Goodwill ask, SC ppg −10.6. User plan: no reply by ~Sat -> fallback Brown + Hockenson -> Garrett Wilson + Loveland (SC ppg +0.47) |
| Michelle | **Declined Gibbs; does not want to trade at all.** Never offer again |
| Jazzy J1 | cancelled. D1 (Dave’s), K2 (Kevin) declined earlier |
| user to-do | Thu lineup (Mahomes `Q` v Stafford -> higher Yahoo proj); Sun before 9:30am ET Brown `O` -> Boston |

## 2. FOCUS: Kevin trade follow-up, Tue 11-17

User deferred it 11-12 ("for after this week ends"). Offer + 11-10 price + note text: decisions log
`## Deferred -> wk11 Tue 11-17`. Javonte Williams + Tre Tucker -> Chris Olave + Malik Nabers.

Before it reaches the user:
1. Wk10 loop first (§3) -> fresh rosters, wk10 actuals in ppg.
2. Confirm Steel City outcome. If it landed, Brown + Hockenson gone -> settle() drop changes; re-price on new roster.
3. Re-run `perceived.R` with `week <= 10` + wk11 export -> regenerate `perceived.rds`.
4. Re-price both bases (`lead/wk10_menu.R` pattern, KN row). Gain > 0 under BOTH.
5. **Kevin ppg >= 0** (contender bar; he's 4-5, sim 36%). If it flips negative -> rescreen Kevin only (`lead/wk10_search.R`
   shape) for a ppg >= 0 variant; never surface a failing one.
6. **Kevin = wk11 opponent.** Trade accepted before wk11 lock changes that matchup. Report wk11 P(win) with + without.
7. Deliver as player names, one offer, plain English + the note. No codes (CLAUDE.md).

If Kevin fails: other fair offers 11-10 (re-price same way) — Jazzy JW + Price -> Chuba Hubbard + DK Metcalf
(+2.7/+2.4pp, ppg +0.37); Owl Out Tucker -> Zach Charbonnet + Jaylen Waddle (+1.3/+2.0pp, ppg 0.00; Owl 99.6% -> free to arm).
All share JW or Tucker with Kevin -> one at a time. Deadline 11-28; accepted by ~11-26.

## 3. Tue 11-17 after-MNF loop

CLAUDE.md §Commands order. Wk10 specifics: add wk10 to `EX` in `ceiling_vs_margin.R` (late = latest clean wk10
pull, early = `2026-11-10`); `leaguewide_retro.py 10 <proj> <act>`; odds rerun. Wk11 opponent Kevin.

## 4. User style this session

- One trade at a time; player names only; plain-English football.
- Lopsided goodwill asks to eliminated teams = user's call; price + flag veto risk, don't block. Comms note: admit
  lopsided up front, make "no" easy, never "you're out", no nudges, no bribes.

## 5. Suggested skills

- `yahoo-ff-collector` — Tue 11-17 pull.
- `caveman` — doc edits (repo rule).
- `handoff` — end of session.
