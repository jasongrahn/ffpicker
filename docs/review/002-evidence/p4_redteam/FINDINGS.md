# P4 (red team) — FINDINGS, 2026-11-02. Saved by lead from the agent's hand-back.

Scripts (p4_redteam/): p4_engine.R, 00_baseline.R, 01-03, 05-10 (04_wk8_actuals.R superseded by A1).

## 1. Headline
- No bug changes the sign of our ΔP for TR1, TR2, X1, D1: all positive in every world, all 5 seeds.
- A3's settle() bug CONFIRMED; no bias on our side today; affects partner number (acceptance proxy) only.
- TR2 fails partner half of win-win under pre-registered Tate-out bound (Tate 0 wk10): Max's -0.55pp, -0.05 W, negative on all 10 seeds -> per wk8 log M1, re-scan Max's with Tate out of package.
- Biggest sim bias = IR-blindness, hits only us: Adams never returns -> understates our P(top 4) ~1.1pp.
- Latent: under LC_ALL=C, Dave's + Max's silently drop out of the sim.

## 2. Our ΔP per trade (settle patched, wk8 leak fixed, 5 seeds CRN; pp [min, max]; 10_signs.R)
| world | TR1 | TR2 | X1 | D1 |
|---|---|---|---|---|
| W1: 10-31 rosters | +1.60 [1.46, 1.71] | +1.28 [1.19, 1.35] | +1.66 [1.52, 1.73] | +1.59 [1.52, 1.66] |
| W4: W1 + injured out wks 9-10 + IR returns | +1.81 | +1.86 | +1.93 | +1.94 |
| W5: injured out wks 9-15 + IR | +1.94 | +2.86 | +2.58 | +2.22 |
| partner pts/wk W1 -> W4 | Madison -2.02 -> -2.02 | Max's +0.30 -> -0.44 | Max's +0.25 -> -0.13 | Dave's -0.46 -> -0.46 |
ΔW us +0.19..+0.31 all cells. W4: four trades within ~0.15pp (MC noise).
TR2 partner (10 seeds, 08_max_seeds.R): Tate healthy Max's ΔP +0.14pp, ΔW -0.009 (win-win on P only); Tate 0 wk10 -0.55pp [-0.64, -0.47], ΔW -0.047 (fails); Tate out wks 10-15 -1.38pp. Our side improves as Tate's injury priced: +1.24 -> +1.33 -> +1.78pp.
X1 also marginal for Max's: +0.25 -> -0.13 once D. Smith + Harvey (both O) zeroed (Burden then starts for them wks 9-10).
TR1, D1 = "partner loses" in every world. Madison 0% -> arming free, but refusal/veto risk.

## 3. Items
- Helper simulate_cond: CLEARED (fixed = c() reproduces simulate() exactly; named sig_team any order OK; wk8 fixed scores land on us v Michelle). FOOTGUN verified: unnamed sig_team -> NA scores -> our P(top 4) silently 1.0; panel scripts (a1 q5b, a2 t1, p2 s04) all pass named vectors -> unaffected. Fix: stopifnot(!anyNA(sd_t)).
- settle() sole-slot: CONFIRMED. Dropping only DEF/K costs <= 0 for 5 teams (FILL hands wire best free): Madison Titans -1.29/wk, Dave's Ravens -0.56, Mitchell Rams -0.24, Owl Out K Loop -0.22, Jazzy Broncos -0.10. Patched: Madison drops Darnold; TR1 partner -2.02 (= A3). Our side not biased today (our cheapest drops = Mahomes, Tucker, Hockenson, Commanders at 0.00/wk, ahead of sole K Bates +0.14). Latent once those are traded -> protect sole slots both sides.
- 1 Roster truth: CLEARED. 10-28 -> 10-31 only Madison changed (Titans off, Jaguars DEF on, Doubs to IR): Madison +1.19/wk, our P +0.04pp. Sun/Mon moves invisible till Tue.
- 2 IR: VERIFIED bias v us only. Adams base 12.6, back wk12 assumed -> +2.16/wk avg wks 9-15, ΔP +1.14pp [1.05, 1.24], ΔW +0.18. Etienne RB4 +0.05/wk. Rivals' IR (Pittman SK 7.0, Doubs Madison 8.5, Brooks SK) bench-only, no change. With Adams back, TR1/TR2 ΔP each +0.3-0.4pp.
- 3 Injured not on IR: VERIFIED, immaterial to us. 9 players carry full base (O: Tate, D. Smith, Harvey, Egbuka, B. Robinson, Monangai; Q no game 2+ wks: Breece Hall, Montgomery, Evans). Zero wks 9-10: Mitchell -0.86/wk, us -0.24, Max's -0.08, our P -0.07pp. Zero wks 9-15: Mitchell -2.58, us -1.26, our P -0.30pp. Mitchell = most overrated rival.
- 4 FILL: minor bug, immaterial. No team QB-short wks 9-15. Fill pts/wk: Michelle 3.2, Dave's 2.1, Madison 2.1, others <= 1.2, us 0. FILL ignores fill player's own bye (Coleman/Sutton DEN bye 10; Henry NE + Browns CLE bye 11) -> <= 0.2/wk, <= 0.01pp. If inactive managers never stream (SK, Jazzy): SK -1.2/wk, Jazzy -0.9, our P +0.11pp.
- 5 base edge cases: CLEARED (no rostered non-IR player zeroed by live rule; no NFL team changes wks 4-8 — NFL trade deadline this week, recheck Tue). Thin bases: Jacobs 12.9 on 2 projections (= all of TR1's value); Mason 10.7 on 1; Charbonnet 8.6 on 1; A.J. Brown 12.1 on 2. Tate: TEN bye wk9 -> Tue run reads pre-injury wk7-8 -> healthy from wk10 (bound pre-registered).
- 6 opt_total / multi-position / DEF keys: CLEARED (greedy = brute force, max diff 2.8e-14; no rostered multi-pos; DEF keys stable, "New York" split NYJ/NYG).
- 7 Tiebreak W*1e4 + PF/1e3: CLEARED (= sort by W then PF, n 2000, PF 1000-1994). PF decides our 4th-place fate in 8.6% of sims.
- 8 Locale: VERIFIED latent. LC_ALL=C -> R keeps 8 owners (U+2019 teams lose rosters), G 3 games/wk; our P reads 14.6% v 2.6%; Max's, Dave's 0%; no error. All runs so far en_US.UTF-8. Guard: stopifnot(setequal(unique(R$owner), teams), nrow(G) == 5 * length(WEEKS)).
- 9 Wk8 leak: VERIFIED, immaterial (TR1 1.63 v 1.64pp); fut() excludes wk8.

## 4. Levers
- L1 Model Adams' return + plan his spot: +2.16/wk, +1.14pp, +0.18 W. Cost one drop wk12 (0-cost body exists). Kill: not practicing by LA wk11 bye, or < 60% snaps first game back -> value 0.
- L2 Guards for Tue CUR=9 run (~10 min): locale/owner/game-count stopifnot; sole QB/K/DEF protection in settle() both sides; NA check on sig_team.
- L3 Never call TR2 (or X1) win-win without the Tate/Smith-out partner check.

## 5. Assumptions challenged
"No IR returns modelled" not neutral (costs us ~1.1pp; rivals' IR = bench). "Every player available every week" overrates Mitchell (irrelevant to us). FILL realism immaterial now. Helper sound. Sim output locale-dependent, fails silently.

## 6. Open
Adams timeline (no source); Etienne health; Sun/Mon wk8 moves (Tue pull); wk8 actuals (A1); Jacobs thin base (Tue export adds wk9).
