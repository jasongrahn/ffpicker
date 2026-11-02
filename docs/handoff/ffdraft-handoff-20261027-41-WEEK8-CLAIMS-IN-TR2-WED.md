# Handoff #48 — Wk8 claims placed. Next: Wed 10-28 clear -> wk8 pull -> FA fallback -> TR2 re-run.

Written 2026-10-27 Tue night. Branch `week3-gameday`, pushed through `2f1b2a8`. **All work
since #47 uncommitted** (§5). Prior: #47
`docs/handoff/ffdraft-handoff-20261027-40-WEEK7-OVER-SCORE-ALL-TESTS.md` — its job (wk7 retro)
done; its "do next" = history.

---

## 0. READ FIRST.

- **Wk8 authority = `data/weekly/2026_week08_decisions.md`.** Opened 10-27, NOT frozen.
  Claims C1/C2 (why, order, kill), holds, trade timing — all there. Read it; don't re-derive.
- **Wed, in order:** (1) wk8 pull, (2) claim results, (3) FA fallback only if a claim
  failed, (4) TR2 re-run -> verdict -> user sends or holds. **Thu: freeze before 8:15pm ET.**
- Wk7 closed + scored: retro R1-R7 in `data/weekly/2026_week07_decisions.md`. Don't
  re-score. Rules + numbers moved this session live in `CLAUDE.md` (gate n 25, noise
  constants, 15% dead band, opponent-replay trap, trade settings, K retired, DST slope),
  ADR 0008, ADR 0011.

## 1. State.

| item | state |
|---|---|
| record | 4-3, 5th (PF 754.12 = 7th). Wk7 W 99.30-70.92 |
| wk8 opp | Locked In Michelle, 2-5. Yahoo 10-27: 103.57 v 110.09, us 44% |
| C1 Tre Tucker (LV WR) / drop Higbee | placed by user 10-27, clears Wed 10-28 |
| C2 Commanders DEF / drop Browns | placed, ranked below C1, clears Wed |
| K | hold Bates. Cam Little asked, not claimed — K rule tested null, retired |
| TR1 Kyler + Hockenson -> Jacobs (Madison) | **deferred to Tue 11-3**, after MNF |
| TR2 Mahomes + Tate -> Burden + Likely (Max's) | **send Wed 10-28 if re-run holds** |
| trade deadline | 11-28; accept by ~11-26 (2-day league-vote review) |
| P(top 4) | 3.3% (10-21), stale. Blocked until wk8 export (`league_sim.R` guard) |

## 2. Wed 10-28. ~40 min.

1. **Ask user before** `yahoo-ff-collector` — drives their Chrome. Pull after the clear
   processes, before Thu 8:15pm ET -> clean export (every Game cell unstarted). Lands in
   `docs/uploads/week_8_data/`.
2. **Claim results:** owners of Tucker, Higbee, Commanders, Browns in the new export.
   Append a dated outcome line to wk8 log §1 (log not frozen yet — allowed).
3. **FA fallback.** After the clear = first-come, priority irrelevant.
   - C1 lost -> `TMPL=docs/uploads/week_8_data/yahoo_week8_%s_2026-10-28.csv WEEK=8 Rscript
     dev/weekly/wire_scan.R`. 10-27 fallback = Makai Lemon (PHI WR, rookie, snaps 64 ->
     91%). Same drop (Higbee).
   - C2 lost -> start Chiefs. Jaguars only +0.2 over Chiefs -> no claim.
   - Both won -> **DEF slot empty** (Browns was the starter). User slots Commanders.
4. `Rscript dev/weekly/playoff_odds.R` (CUR auto = newest clean export = 8) -> P(top 4),
   exchange rate. Then `Rscript dev/weekly/trade_finder.R`.
5. **TR2 go/no-go** per `data/weekly/2026_week08_trade_ideas.md` §5: still win-win both
   sides; Burden + Likely still Max's + healthy; **Max's QB room** — dropped Hurts (IR,
   `W (Oct 28)`), Dak only on 10-27 -> if they claimed a wire QB at the clear, Mahomes' pull
   drops. Price in wins. Go -> user proposes in Yahoo; log the date in wk8 log §3. Kills:
   trade ideas §6.

## 3. Thu 10-29, before 8:15pm ET. ~30 min.

- **`dev/weekly/freeze_lineups.R` is wk7-hardcoded** (slot list, `src`, output filenames)
  -> edit for wk8 first, `YDIR=docs/uploads/week_8_data`. Writes `_myteam.csv`,
  `_opponent.csv`.
- `Rscript dev/weekly/predictions.R freeze` — refuses after first kickoff (CAR @ GB Thu).
- Lineup = Yahoo projection (ADR 0009). QB Stafford 17.96 v Kyler 17.93 (10-27) = inside
  15% band -> higher raw at freeze, no kill. User leans Kyler; 0.03 pts.
- None of ours play Thu -> slots bind Sun 1pm. Predictions still freeze Thu.

## 4. New this session — gotchas.

- **`dev/weekly/wire_scan.R`** (new): RB/WR/TE on opportunity + DEF on opp implied; env
  `TMPL`, `WEEK`. NA keys must not join — draft let NA `gsis_id` match NA rows -> 58k rows,
  no error. Fixed with `na_matches = "never"` + row-count `stopifnot`. Predecessor
  `roster_vs_wire.R` = wk5-hardcoded.
- **`dev/weekly/k_test.R`** (new): K rule null, n 214 (ADR 0011). Don't re-raise K streaming.
- `league_sim.R` refuses once CUR is scored: "week 7 already scored -- pull the week 8
  export before simulating". #47 said only the trade re-run needed wk8 exports — wrong,
  P(top 4) does too.
- Higbee + Browns, once dropped, sit on waivers 2 days -> not re-addable instantly.

## 5. Uncommitted. Commit only when user asks.

- Modified: `CLAUDE.md`, `data/weekly/2026_league_schedule.csv`,
  `data/weekly/2026_week07_decisions.md`, `data/weekly/README.md`,
  `dev/weekly/ceiling_vs_margin.R`, `dev/weekly/schedule_check.R`,
  `docs/adr/0008-spread-tiebreak-retired.md`,
  `docs/adr/0011-stream-dst-on-opponent-implied-total.md`, `docs/handoff/README.md`.
- New: `data/weekly/2026_week08_decisions.md`, `dev/weekly/k_test.R`,
  `dev/weekly/wire_scan.R`, handoffs #47 + #48, wk7 exports
  `docs/uploads/week_7_data/*_2026-10-27.csv`.

## 6. Open, not tomorrow.

- TR1: re-run + send Tue 11-3 (timing case in wk8 log §3).
- Lineup recovery: unique-subset-sum match to Yahoo finals (wk7 Madison: 1 of 520) for all
  10 teams -> real lineups -> may unblock the stream detector (wk7 log R7). Offered, not
  taken.
- Yahoo DST projection vs opp-implied rule — never compared (ADR 0011 tested vs random
  only). 10-27: Yahoo Browns 6.23 > Chiefs 5.90, rule the reverse. ~20 min on wks 3-7.
  Offered, not run.
- PR owed: `week3-gameday` ~40 commits ahead of `origin/main`. GitHub MCP failed to
  connect (auth header) -> use `gh`.
- Etienne (NO RB, IR): Saints bye wk8 -> look wk9. Adams (LAR WR, IR): earliest wk12.

## 7. Suggested skills.

| skill | when |
|---|---|
| `anthropic-skills:yahoo-ff-collector` | wk8 pull, Wed. Ask first — drives the user's Chrome |
| `caveman` | any doc / log / ADR text (repo rule) |
| `handoff` | end of session -> #49 in `docs/handoff/` + index row (README: here, not `/tmp`) |
