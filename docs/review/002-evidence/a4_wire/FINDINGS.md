# A4 (wire: waivers, stashes, IR, streaming) — FINDINGS, 2026-11-02. Saved by lead from the agent's hand-back.

Scripts (a4_wire/): a4_common.R, s1_ir.R, s2_need.R, s3_ir_price.R, s4_baserates.R, s5_wire.R, s6_handcuff.R, s7_qb_dst.R, s8_price.R; caches wire_table.rds, implied_wk9_15.rds, dst_plan.rds, baserates_S.rds, M_base.rds. Sim: simulate_cond, wk8 L fixed, 5 seeds x 20000, CRN; paired-delta MC se <= 0.12pp.

## 1. Headline
- No wire move closes the 13-18/wk gap. Biggest: Adams back wk12 +1.9pp (if healthy); DST streaming +1.7pp v holding Chiefs (practised, not credited by sim); wk11 QB -2.2pp if forgotten. Each ≈ one TR-sized move or less.
- Etienne ≈ 0 (+0.00-0.05pp). Leave on IR while Yahoo lists IR; when NO activates him, DROP HIM rather than anyone with value.
- Post TR1+TR2: 14 active -> 1 open spot. 3 dead spots for lottery tickets: 15th spot, DST2 (Commanders, useless wk9), TE2 (Strange). Ticket with >= 10 touches+targets/g ≈ +0.5pp.
- Nothing changes TR1/TR2; they create the open spot + wk11 QB hole, both cheap.

## 2. Numbers
Baselines (s2_need.R): TR world (TR1+TR2, Tate base 0) 6.39%, 6.55 W. NOW (no trades, Tate base 0) 2.17%, 5.98 W. (Brief's 2.6% = 1 seed, Tate at base.)
Need: NOW never short (3 QB/3 RB/4 WR/2 TE/1 K/2 DST; flex pool >= 7). TR world 1 QB/4 RB/4 WR/2 TE/1 K/2 DST = 14 active; only hole QB wk11 (LA bye). Wk10 (CHI bye): Odunze + Burden out -> WRs Boston + Tucker, flex RB4 (thin, legal). Wks 11/13/14 covered. TE2 + DST2 zero sim value (JAX/NYG/KC/WAS byes past). Tucker 7.8 < wire best WR Sutton 8.2 -> sim's cheapest drop.

IR (s1_ir.R, s3_ir_price.R; per-week override via patched team_strength2):
| player | status | value on return | ΔP(top 4) |
|---|---|---|---|
| Etienne (NO RB) | Yahoo IR hamstring (gamedaycalls 10-30). Hurt wk3; 4-game min served wks 4-7; NO bye wk8 -> eligible wk9; no sign NO is activating | NO committee: Kendre Miller 13 car/g, Kamara 5 car + 4 tgt/g (both FA). Base 8.5 (pre-injury Yahoo 9.70) = our RB5 | TR +0.00 (8.5), +0.05 (9.7). NOW +0.11, needs a drop |
| Adams (LA WR) | IR hamstring; last game wk6 -> out wks 7-10 -> LA bye 11 -> earliest wk12 | base 12.6 (mean 6 pre-IR Yahoo proj) = our WR1 | TR +1.92 (wk12), +1.41 (wk13), +0.36 if rusty (10 pts). NOW +1.20 |
Adams wk12 = +1.87 pts/wk avg wks 9-15, +0.17 W. Activation: TR world needs a spot only if 15th held; drop DST2/TE2/missed ticket. NOW: both activations force a drop (sim pick: Tucker).

DST (s7_qb_dst.R, ADR 0011). Wk9 real lines; wks 10-15 market rating fit on wks 1-9 implied (R² 0.83, resid sd 1.66; fit wks 1-6 -> test 7-9 r 0.83, MAE 1.53, n 86):
| wk | pick (10-31 status) | opp (implied) | best DST we hold |
|---|---|---|---|
| 9 | Chiefs (ours) | NYJ 18.5 (rank 3) | Commanders v LA 26.5 (rank 23) |
| 10 | Colts (FA) | MIA 18.2 | Chiefs 20.8 |
| 11 | Bills (FA) | MIA 17.2 | Chiefs 19.4 |
| 12 | Jets (FA) | MIA 19.3 | Commanders 24.1 |
| 13 | Commanders (ours) | TEN 19.7 | — |
| 14 | Lions (FA) | TEN 18.5 | Commanders 23.4 |
| 15 | Packers (W until 11-4) or Colts (FA) | MIA 17.0 / TEN 19.3 | Chiefs 21.4 |
Pattern: whoever plays MIA, TEN, NYJ. All FA -> first-come after Wed clear -> one DST slot enough. Streaming v holding Chiefs = +1.67 pts/wk -> +1.73pp TR / +0.69pp NOW, +0.15 W (sim's flat DST base can't see it).

QB (s7_qb_dst.R, owners 10-31; own implied wk11): Stroud (HOU) FA base 18.3, v IND (24.5); Brissett (ARI) 17.5, @KC (19.4); Rodgers (PIT) 16.5 (18.6); D. Jones (IND) 15.6; Herbert (LAC) 15.3 (23.6). Stafford implied 25.0-28.6 beats Stroud every other week -> no platoon value outside wk11. 1 QB safe (injury backup costs ~0.4-2.4/wk). Priced (s8_price.R): weak wk11 stream (15.5) v Stroud -0.39pp; EMPTY wk11 QB -2.16pp, -0.18 W (sim assumes fill at 18.28).

Lottery-ticket base rates (s4_baserates.R; 2021-25 REG; RB/WR/TE < 8 ppg wks 1-8; decision after wk8; hit = >= 3 games and >= 12 ppg wks 10-15; Wilson CI):
| signal (last 3 games) | n | hit | 95% CI | top-24 |
|---|---|---|---|---|
| all low producers | 1807 | 1.5% | 1.0-2.2 | 3.4% |
| touches+targets >= 5/g | 239 | 7.1% | 4.5-11.1 | 14.6% |
| touches+targets >= 10/g | 32 | 15.6% | 6.9-31.8 | 25% |
| snaps +15pp (wks 6-8 v 3-5) | 218 | 4.1% | 2.2-7.7 | 8.7% |
| ... and >= 50% snaps | 109 | 5.5% | 2.5-11.5 | 12.8% |
| backup RB, starter healthy at wk8 | 100 | 7.0% | 3.4-13.7 | 13% |
| ... starter misses >= 3 games (19% of time) | 19 | 21% | 8.5-43 | 26% |
| backup RB already > 10 touches/g | 9 | 44% | — | 56% |
| rookie WR, tgt/g up >= 2 | 21 | 4.8% | 0.8-22.7 | 4.8% |
2024-25 alone: >= 5/g 7.4% (n 94); rookie WR rising 0/11. Hits average 13.5-15 ppg. Ticket hits from wk11 (TR world): WR 14 ppg +4.00pp; RB 15 ppg +3.33pp (only displaces Jacobs); WR 12 ppg +2.18pp. EV: RB >= 10/g 0.156 x 3.3 ≈ +0.5pp; WR >= 5/g 0.07 x 4.0 ≈ +0.28pp. Convexity: +2 -> +1.51pp, +4 -> +3.12pp, +8 -> +7.50pp (6.0 if linear) ≈ 1.25x premium -> only in FREE spots, never at cost of projected points.

## 3. Levers (TR world unless noted)
1. Adams return: +1.87/wk = +1.92pp, +0.17 W if back wk12 at 12.6 (+1.41pp wk13); P(wk12) unknown -> ~+1.2-1.4pp expected. Cost 0 now (IR slot); on return drop DST2/TE2/missed ticket. Kill: not activated before wk13 kickoff, OR < 60% snaps in either of first 2 games back -> cut for a ticket.
2. Stream DST on opp implied total, one slot: +1.67/wk, +1.73pp, +0.15 W v holding Chiefs. Hold Chiefs wk9, DROP Commanders Tue (frees spot), follow table; re-rank on real lines each Tue. ~5 min/wk. Kill: ADR 0011 season-end test; no weekly kill.
3. Wk11 QB (TR world only): avoids -2.16pp. Claim Stroud in Tue 11-17 waiver run, or first-come Thu 11-19; or hold him in 15th spot earlier if no ticket deserves it. Don't give up a player for him before wk10. Kill: his Yahoo proj -> 0 before wk11 -> Brissett.
4. Lottery tickets in dead spots (15th until wk11 QB claim; DST2 once Commanders go; TE2 Strange): ~+0.5pp per RB ticket >= 10 touches/g; +0.2-0.3pp per WR ticket; 2-3 tickets ≈ +0.8-1.5pp, ~+0.1 W. Cost: claims (stack several; priority near bottom) + ~10 min/wk. Kill per ticket: < 8 touches+targets/g or < 40% snaps in the 2 games after add -> swap out.
5. Etienne: keep on IR (free); drop when forced. Exception: NO names him lead back AND spot free AND no ticket clears >= 10 touches/g. No kill (not a bet).

## 4. Current wire (owners 10-31; rerun wire_scan.R on wk9 export Tue)
RB tickets (all FA): Jonah Coleman (DEN, rookie, bye 10; snaps 40 -> 49 -> 66%; Dobbins 21-23%, RJ Harvey out knee; wire's top base 8.2). Mike Washington Jr. (LV, rookie, bye 13; 60% snaps wk8, 13 car/g last 3; out-snapped Jeanty 40% — cause unknown, check Tue injuries). Kenny Gainwell (TB, bye 10, Q hip; behind Bucky Irving (SK's) but 14 car/g, 50% snaps). Rico Dowdle (PIT, bye 9; behind Jaylen Warren (Dave's); 10 car + 3 tgt/g). Tyler Allgeier (ARI, bye 14; lead back 12 car + 3 tgt while rookie Jeremiyah Love hurt; Love back 19% wk8 -> role at risk). Kaelon Black (SF, rookie, bye 8; behind McCaffrey (30, Q, Jazzy's); 47% snaps wk7).
WR tickets: Makai Lemon (PHI, rookie, bye 10; snaps 64 -> 94%, 7.7 tgt/g; DeVonta Smith out hamstring -> partly injury-driven). KC Concepcion Jr. (CLE, rookie, bye 11; 81% snaps, 6.7 tgt/g). Also 6-7 tgt/g: Keenan Allen (IND), Wan'Dale Robinson (TEN), Ryan Flournoy (DAL; Pickens Q, Turpin out).
Handcuffs to OUR RBs weak, not worth a spot (Justice Hill 2 car + 5 tgt; Tyler Goodson 6 + 2; Lloyd owned by Steel City).
Wk8 snap collapses (possible fresh injuries; backups claimed Tue): TE Jake Ferguson (DAL) 5% -> Spann-Ford 88%; Hunter Henry (NE) 13% -> Raridon 92%; WR A.J. Brown (NE); Egbuka (TB, foot, out).
IR-slot stash only if Etienne leaves IR: Croskey-Merritt (WAS RB 8.9), Jadarian Price (SEA, IR w/ return designation, 8.8), Hurts (PHI QB 16.9). Low value.

## 5. Assumptions challenged
- league_sim.R drops IR -> understates us (Adams ~+1.9pp; Etienne 0). Per-week return override (team_strength2) belongs in sim.
- Flat DST base hides ADR 0011 streaming (~+1.7pp TR).
- Empty-slot fill assumes we make the bye move (wk11 QB 18.28); real risk = forgetting (-2.2pp).
- CLAUDE.md "bar under 5 opp/g" SUPPORTED: < 5 ~1% hit; >= 5 7%; >= 10 16%. Volume beats rising snaps (4%) and rookie rising targets (4.8%; 0/11 2024-25).
- Pure handcuffs weak (7%); value only in starter-hurt branch (21%, happens 19%). Exception: backups already > 10 touches/g (n 9, wide CI).
- "Variance is a feature" (#51 seed 2): true but small at stash level (~1.25x); doesn't justify giving up projected points.

## 6. Open
Wire after Sunday wk8 unseen (10-31 snapshot only). Our waiver priority unknown (likely near bottom after 2 claims 10-28). Etienne activation + Adams wk12 odds unknown (priced assuming return). DST wks 10-15 from rating proxy (MAE 1.5) -> re-rank each Tue. Ticket values = upper bound (hit started from wk11, real wks 10-15 ppg). No roster-% history ("on wire" ≈ < 8 ppg). No injury model -> RB depth insurance unpriced.
