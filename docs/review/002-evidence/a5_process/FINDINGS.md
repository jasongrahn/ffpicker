# A5 (process audit) — FINDINGS, 2026-11-02. Saved by lead from the agent's hand-back.

Catalogue: a5_process/catalogue.csv (69 rows x 10 cols). Scripts: wins_accounting.py, effort_by_type.py (+ _detail.tsv), price_process_levers.R, build_catalogue.py. Sim: sim_helpers.R, 5 seeds x N 20000, CRN, base 2.7%; figures = 5-seed mean [min, max].

## 1. Headline
- No loss flippable by a better pre-kickoff lineup call. Hindsight-best lineup still loses wk4, wk6, wk8; wk1 flips only on a QB coin flip Yahoo got wrong. 4-4 ≈ what roster earned (all-play 30-33 = .476 thru wk7).
- Effort inverted: start/sit 18% of log lines, ~4.5 of 26 in-season sessions, worth <= +0.1pp. Trades 2% of lines, 0.6 sessions, worth ~+4pp if they land wk9. TR1/TR2 priced 10-21, unsent 11-02. **Each week of delay ≈ -0.7pp.**
- Fix: trades on a clock; 3-touch weekly loop (Tue 20 min, Thu 5, Sun 5) from one 10-line card; stop coin-flip analysis + long docs.

## 2a. Wins accounting (single ex-ante change that flips each game)
| wk | opp | score | margin | hindsight-best | flips w/ 1 change? | driver |
|---|---|---|---|---|---|---|
| 1 | Dave's | 101.80-118.96 | -17.16 | 121.56 | yes: Mahomes 22.66 for Stafford 5.10 (+17.56); ex ante Yahoo had Stafford +1.67 (9% gap = coin flip) | projection error |
| 2 | SK | 152.58-112.08 | +40.50 | — | — | — |
| 3 | Mitchell | 108.74-96.70 | +12.04 | 133.80 | — | opp -20.24 under proj; won despite 25.06 regret |
| 4 | Jazzy | 93.00-123.98 | -30.98 | 120.10 (loses by 3.88) | no (best Bates 18 for Butker 6, +12) | opp beat frozen replay +25.4; our WR/TE missed |
| 5 | Max's | 107.02-100.44 | +6.58 | 130.32 | — | spread tiebreak cost -2.70; won |
| 6 | Owl Out | 91.68-111.14 | -19.46 | 95.08 (loses by 16.06) | no | our starters missed proj by 17.03; they streamed (+27.24 over proj-following) |
| 7 | Madison | 99.30-70.92 | +28.38 | — | — | opp collapse |
| 8 | Michelle | 87.50 v ~113-133 | <= -25.5 | ~92 + Odunze (MNF) | no (best Mahomes 25.44 for Kyler, +4.54) | Javonte -10, Tucker 0 (Tate O), Burrow +20.6 |
Loss drivers: projection error wk1, wk6, wk8; our decision errors 0 games (costly overrides came in a win + a 31-pt loss: wk5 spread tiebreak -2.70, wk4 D6a Raymond over Odunze v Yahoo -10.80); roster construction wk4, wk6, wk8 (best lineup still loses; weekly points rank 7,1,6,7,7,5,7 = 7th-place roster); data bugs flipped 0 but produced one false lesson (§4). Luck +0.67 W; PA 4th-lowest.

## 2b. Effort v value (effort = log-line share + sessions of 26 in-season, #26-#51; hours never logged)
| activity | lines | sessions | changed decisions | realized pts | forward value wks 9-15 | verdict |
|---|---|---|---|---|---|---|
| Start/sit coin flips (< 15% gap) | ~570 (16%) | 4.5 | ~6 overrides | override regret -3.50 over 7 wks; wk8 Kyler +11.62 = user's call | +0.2/wk -> +0.09pp, +0.016 W | STOP |
| Gameday injury/option checks | ~90 (2%) | (incl. above) | 3 (wk3 Q, wk4 IR, wk8 Tate O) | 0 (Tucker scored 0.00) | +0.57pp, +0.11 W per zero avoided | KEEP |
| DST stream | ~200 (6%) | ~1.5 | 6 claims | ≈ +22 over 5 scored wks | +1.92/wk -> +1.02pp [0.91, 1.13], +0.16 W | KEEP |
| K stream | ~135 (4%) | ~0.85 | 4 moves + Bates drop/re-add | ≈ -14 | 0 (null, n 214) | STOP |
| Waiver adds/drops | 510 (14%) | 4.1 | ~10 adds | now most starters; unpriced | wire thin: 0 free upgrades 10-28 | KEEP, lean |
| Trades | 55 (2%) | 0.6 (+0.7 sim build) | 0 sent | 0 | +5.85/wk landing wk9 -> +4.05pp [3.93, 4.25], +0.49 W | START |
| Method tests, powered | ~280 (8%) | ~1.5 | 5 rules settled | indirect | stops bad rules early | KEEP, gated |
| Method tests, underpowered | ~464 (13%) | ~2.25 | 1 (spread tiebreak -> -2.70) | -2.70 | 0 | STOP |
| Opponent / H2H / hedges | 239 (7%) | ~0.5 | 0 | 0 | 0 | STOP |
| Retro + scaffolding + docs | ~800 (22%) + ~4,700 handoff lines | ~7.2 | 0 | 0 | 0 (continuity) | CUT |
| Data infra / corrections | 94 + 2,841 harness lines | 3.5 (1.5 on Yahoo API probes, 0 value) | prevented errors | — | enabling | KEEP, minimal |
>= ~55% of log lines changed no decision. 5 of 26 sessions empty (#38) or superseded within a day (#32, #36, #40, #41).

## 2c. Who caught what
User caught (6): 09-29 "4 RBs, is that MY hole?" (real holes K, TE); 10-04 "frozen is not locked" (QB due 1pm not 4:25); 10-06 Sutton v Raymond drop (ppg ranking -> ADR 0009); 10-07 Gordon v MIA -7 (-> slope rebuild; tiebreak on it cost -2.70, retired); 10-20 wk6 final 111.14 off matchup page; 10-28 "offer to someone doing worse?" (arming-cost lens; TR1 > TR2). Kyler override = coin flip, not a catch. Correctly rejected user ideas: Jets DST, JAX/HOU records, TEN record v Tate, LA rain (dome).
Analysis caught (8): `Rankings Actual` = projection (3 moves reversed before processing: Stroud claim, Etienne drop, Allen claim); wk2 Mixon O = standing absence; wk3 replacement-deadline rule kept Etienne option; wk4 IR slot outside 15 (Etienne stashed, no drop); wk6 Hockenson 3% snaps = concussion; wk6 Strange added at zero priority (+4.70 over Higbee); wk8 Tate O in Sat pull -> Tucker (Tucker then 0); 10-30 target_dip_test stopped a noise kill of TR2. Week-1 kicker: McLaughlin claimed in time, but **Jacobs was dropped for him — now the TR1 target**; root cause = no test of round count v roster size.
Missed by both: wk4 opp 123.98, not 98.58.

## 2d. Failure modes, worst first
1. Plan not executed (biggest cost now): TR2 GO 10-28 not sent; TR1/TR2 parked since 10-21; Ferguson dropped instead of Butker (wk5); no wk5 lineup CSVs; Sunday pre-kickoff pull missed 3 weeks. Delay price: -0.7pp/wk (land wk9 +4.05 -> wk10 +3.31 -> wk11 +2.52 -> wk12 +1.87pp); -0.28pp/wk for a +3/wk trade.
2. Snapshot as truth (12+): Rankings Actual + ppg; opponent replays (wk4 off 25.4, wk7 7.8); Wed/Mon exports as live rosters (wk6 x2); stale handoff claims (#36 ppg, #41 byes, #43 x3, "TE 1-deep", #48 Max's QBs); `read_yahoo_week()` oldest-pull bug STILL UNFIXED — hits Thursday's wk9 freeze.
3. Re-arguing settled coin flips: QB debated 6 of 8 weeks despite wk3 "stop analysing QB"; wk8 argued 3x, 2 new harnesses, for 0.20 pts (+0.003 W).
4. Rules on single observations: Raymond 6-target trigger whipsawed (-11.90 wk3, -10.80 wk4); K rule 4 states in 5 weeks.
5. Rules adopted before a test: spread tiebreak 6 days (-2.70); K streaming 4 weeks (≈ -14) until a 30-min k_test.R closed it.
Kills: ~11 fired, ~7 followed; 3 overridden/rewritten (wk5 Hockenson trigger, wk4 K bar rewritten not retired, wk3 "stop analysing QB" broken wk8).

## 3. Levers
- L1 Trade send clock: send what Tue re-run confirms by Tue 11-3 9:00pm; re-scan non-contenders every Tue; last send Tue 11-24 AM. +5.85/wk landing wk9 -> +4.05pp, +0.49 W; each week late ~-0.7pp / -0.07 W. Cost 10 min/Tue. Kill per trade (role, wks 9-11): Jacobs snaps < 50%; Burden tgt share < 15%; Likely snaps < 60%.
- L2 Sunday 11:45am injury swap: +0.57pp / +0.11 W per zero avoided; ~1 per 4-8 wks -> +0.1-0.2 W. 5 min. Audit: skipped 2 Sundays -> add starter-status check to Thu card.
- L3 Keep DST streaming: +1.02pp, +0.16 W; 5 min/Tue. Kill: season-end dst_test.R CI incl 0; never on a bad week.
- L4 Reallocate time: drop coin-flip lineup work (forgo <= +0.09pp) -> L1 scans. Kill: card's lineup leaves > 5 pts regret over wks 9-11 on > 15%-gap calls -> restore Thu review.

## 4. Assumptions challenged
- ADR 0010 holds, stronger: 0/4 losses flippable ex ante; 3/4 lose even hindsight-best.
- Broken: README wk4 row (98.58) + wk4 retro "winnable, lost on 3 swaps / K hold bar forfeited 18 pts" -> real final 123.98, best 120.10 loses. That false lesson drove the K-bar rewrite. Correct record; K rule retired anyway.
- Weakened: kill condition for every decision — coin flips + single player-weeks produced ~380 retro lines, changed nothing. Keep for adds + trades (role, multi-week, window after decision).
- Weakened: "freeze both lineups pre-kickoff is load-bearing" — analytics only; opponent replays missed real score 3x (wk4, wk6, wk7). Quote Yahoo matchup page.
- "Roster quality is the lever" right but not acted on: after ADR 0010 (10-06), wks 6-8 put 243 log lines into lineups v 55 into trades.

## 5. Stop (<= 5)
1. Start/sit analysis inside 15% gap, QB included. Start highest Yahoo proj; user may override, logged "user call", no harness.
2. K streaming + churn. Hold Bates.
3. Underpowered weekly tests (player-week kills, regret narratives, H2H/hedge maps, game-script descriptions, Yahoo bias check, T4, stream detector).
4. 500-line weekly logs, 190-line handoffs -> 10-line card, one retro line per changed decision, handoff <= 30 lines.
5. Acting on any prior-doc number without a fresh script read that fails loudly.
## 6. Keep (<= 5)
1. DST streaming on opp implied total. 2. Sunday injury swap. 3. League-wide sim pricing in wins. 4. Role-based multi-week kills for adds + trades. 5. <= 30-min league-wide test before adopting any rule (k_test, dst_test, 215-pair test, pair band = best value/hour).
## 7. Start (<= 5)
1. Trade clock (L1). 2. Fix `read_yahoo_week()` oldest-pull bug before Thu 11-5 freeze. 3. Single `weekly_card` command as only weekly agent output. 4. Gate every analysis: "which decision changes if the answer is X?" No answer -> no analysis; 30-min cap. 5. Yahoo matchup-page finals = only source for opponent scores.

## 8. Weekly loop wks 9-15 (user ~30 min/wk, agent ~70 min/wk)
TUESDAY 7:00pm ET (11-3, 11-10, 11-17, 11-24 last trade send, 12-1, 12-8, 12-15):
1. FIRST: run Yahoo collector (this week's proj + last week's actuals) + Matchups screenshot. 10 min.
2. Agent runs weekly_card (<= 60 min) -> 10 lines.
3. User by 9:00pm: do exactly what card says (DST claim, add/drop, send/accept trades). 10 min.
THURSDAY 6:00pm ET (11-5, 11-12, 11-19, 11-26 Thanksgiving, 12-3, 12-10, 12-17):
4. Set lineup to card's lineup. 5 min (agent 10 min refresh).
SUNDAY 11:45am ET (9:15am London week):
5. Any starter tagged O, IR, inactive -> highest-projected legal bench player. Nothing else. 5 min.
Monday: nothing.

## 9. weekly_card = 8 one-line checks, in order
1. data_check -> "OK wk9: newest clean export 11-03, 10x15" or STOP + reason (absorbs oldest-pull bug + snapshot traps).
2. result_line -> "wk8 L 87.50-1xx.xx | override regret 0.20".
3. odds_line -> "4-4 | P(top4) 2.7% | E[W] 6.1 | wk9 P(win) .33 | +1 pt/wk = +0.46pp".
4. dst_line -> "CLAIM X (opp implied 17.5), DROP Y" or "HOLD".
5. hole_line -> "no hole wks 9-15" or "wk11 QB hole: add X, drop Y (snaps 41%)".
6. trade_line -> "TR1 GO: us +x/wk +y pp, them +z; Jacobs 71% snaps" or "NO-GO: <reason>".
7. kills_line -> "fired: none" or "T5 Tucker FIRED (3.0 tgt/g) -> drop candidate".
8. lineup_line -> "LINEUP 104.2: QB Stafford ... | flags: none".
Overhead harnesses (keep for season-end reruns only): mult_backtest.R, spread_tiebreak_leaguewide.R, proj_vs_choice.R, regret_decomp.R, roster_error.R, week2_*/week3_*, roster_vs_wire.R (wk5-hardcoded), score_week07.R, wk8_*.

## 10. Open
Wk8 per-player finals + Odunze (MNF) with Tue pull -> wk8 hindsight-best approximate. Each add's value v its drop unpriced (catalogue coarse). No hours logged (effort = lines + sessions). +5.85/wk = 10-28 pre-Tate-injury estimate; delay curve scales (+3/wk: wk9 +1.68pp, -0.28pp/wk late). Other managers' streaming never measured (needed a Sunday pre-kickoff pull).
