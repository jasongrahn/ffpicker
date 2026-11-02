# P2 (statistician / model risk) — FINDINGS, 2026-11-02. Saved by lead from the agent's hand-back.

## 1. Headline
- TR1+TR2 = GO under every tested assumption: ΔP(top 4) +1.7 to +5.6pp, never changes sign. Best-supported model: +3.2pp, +0.41 exp wins.
- Our P(top 4) range 1.5-5.8% across assumptions; best-supported ≈ 3.0%. "tau 6 = 4.1%" is not upside: data supporting tau also supports team-specific gaps, which cancel (combined 2.66%).
- Gate slope 1.30 = manager effect (good rosters also beat ceilings), not projection compression. Player added by trade gains ~1:1 (player slope 0.95) -> exchange rate NOT understated.

## 2. Numbers
Baseline reproduced: 2.62% (helper, 1 seed), 2.68% ± 0.08 (5 seeds).

Noise (`s01_noise.R`, n 50 team-wks, wks 3-7): resid mean -4.24 (SE 2.98), sd 21.08 [17.6, 26.3]. Skew -0.08, ex-kurtosis -0.45, Shapiro p 0.46 -> normal, light-tailed if anything. No heteroskedasticity (tercile sd 19.2/25.0/18.5; p 0.92; Levene p 0.87). Team variances equal (Bartlett p 0.22). Our resid sd 7.45 (n 5) CI [4.5, 21.4] = noise; our raw sd 20.8 = league.
Team gaps: TAU2 43.5, REML sd 6.6 [1.7, 26.3], LRT p 0.17; no persistence (wks 3-5 v 6-7 r -0.00, n 10; autocorr 0.01). Our shrunk gap -4.87 v uniform -4.24. Shrunk mode moves RIVALS: Owl Out +4.35, Jazzy +1.76, SK -1.38, Max's -2.28, Michelle -3.21, Dave's -5.54, Mitchell -7.42, Steel City -8.05, Madison -12.57.

Gate slope (`s01`, `s05_checks.R`): 1.30, SE 0.45 [0.38, 2.23]; v 1 p 0.51; boot P(<=1) 0.29. Ex-Madison 0.97 (n 20). Actual~ceiling: all 1.56, within-team 1.08 [0.08, 2.09], between-team 1.93 (n 10), cor(team ceiling, team gap) +0.58 p 0.08. Player-level actual~Yahoo proj slope 0.95 [0.82, 1.09] (n 595, wks 4-8, `s03`). Margin resid sd (slope 1) 28.7 v sim 29.8.

Tau (`s02_tau.R`, patched sim run as-of wks 4-7 via `league_sim_origin.R`): drift (realized ceiling - forecast) sd 6.8 at 1 wk, 7.7-7.9 at 2-4 wks, mean ~0..+0.5. Between-team variance of drift 10.2 (from wk4, p 0.07), 6.3 (wk5, p 0.26), 40.9 (wk6, p 0.03, 2 wks/team). Total forecast error between-team var 54 (wk4, sd 7.3, p 0.26), 139 (wk5, sd 11.8, p 0.09). Every decomposition tau > 0 (sd 2.5-12), none significant at 10 teams. Best-supported: uniform gap -> tau ≈ 7-9; shrunk gaps -> residual per-team tau ≈ 5.6-7.7. Wk4 forecast -> wks 5-7 margins r +0.44 (n 15, CI [-0.09, 0.78]) v same-week ceilings r +0.69.

Base as ROS (`s03_player.R`, as-of wks 5-7, 378 player rows, 148 players; target = mean actual rest-of-window, DNP = 0; id match 81.6%): RMSE base 6.72, latest 6.78, blend 7.07, ppg 7.68, this-wk proj 7.97. Base v latest tie [-2.46, +0.95]; base beats ppg (-13.7 [-19.7, -8.2]) and blend. Calibration slope 0.96; overstates by 1.55/player-wk (missed games), uniform across teams.

Sensitivity (`s04_sens.R`, CRN, 5 seeds x 20k, MC SE <= 0.09pp): P(top 4) / ΔP TR1+TR2 / ΔP +5 pts/wk:
- baseline (tau 0, SIG 21.1, uniform gap): 2.68 / +3.66 / +3.24
- tau 12 / 8.3 / 6 / 3: 8.86 / 5.81 / 4.34 / 3.07; ΔP TR +5.6/+5.0/+4.6/+4.0
- SIG 26.3 / 17.6: 4.88 / 1.38; TR +4.5 / +2.9
- slope 0.8 / 1.3 / 1.56 (rejected): 4.76 / 1.00 / 0.39; TR +4.3/+2.6/+1.7
- our sd 27 / 15: 3.93 / 1.66
- shrunk gaps alone 1.54 (TR +2.3); shrunk + per-team tau 2.66 (TR +3.1)
- us +2 / -2 pts/wk: 3.74 / 1.92 (TR +4.7 / +2.8)
- BASE=latest 3.52; SIG 22.1 (longer-horizon) 3.10; t5 tails 1.84; common week shock sd 5.3 -> 2.37
- **combined data-supported (shrunk + per-team tau + SIG 22.1): 3.00 / +3.21 / +2.84**; + BASE=latest 3.84 / +3.45
Ranked: tau (cancelled by gap treatment) > SIG CI (-1.3/+2.2pp) > gap mode (-1.1) > frozen-roster credit (+1.1) > BASE (+0.8) > tails, week shock (< 1 each). No assumption flips TR1/TR2; size ±40%.

## 3. Levers
- L1 Send TR1 + TR2: strength 98.5 -> 104.3 (+5.8/wk); +3.2pp (combined) to +3.7pp (baseline); +0.41-0.47 wins. TR1 alone +1.6pp, TR2 alone +1.2pp (1 seed, `s04a_mats.R`). Cost: QB depth, Stafford bye wk11 -> stream QB (sim assumes fill). Kill (window from landing wk10): Jacobs < 50% snaps 2 straight games wks 10-12, or Burden < 15% tgt share 2 straight -> slot back to wire/trade scan. Never on points.
- L2 Keep streaming; sim does not credit it, understates us ~1pp: our realized ceiling beat frozen-roster forecast 4 straight weeks at 1-wk horizon (+5.4, +4.0, +2.0, +3.6; mean +3.8 [1.5, 6.0], league max). League differences not significant (p 0.22); pooled shrink -> ~+1.5. +2/wk = +1.06pp, +0.17 wins. Cost: one claim/wk. Kill: stop crediting if our 1-wk drift <= 0 two straight weeks from wk10.
- L3 NOT a lever: buying variance with projected points. sd 21 -> 27 = +1.25pp, but 1 pt sd ≈ 0.5 pt mean at our deficit. Dead-band swap to the lower projection costs 0.88/pair (ADR 0008) -> needs >= 1.8 pts extra team sd per swap; rarely available. Take variance only when free.

## 4. Assumptions challenged
- iid normal noise sd 21.1: VERIFIED (shape, homoskedastic, equal team variances, no autocorr; margin 28.7 ≈ 29.8). Caveat: weeks 2-7 ahead should use sqrt(SIG^2 + 45) ≈ 22.1 (+0.4pp) — forecast drift not in SIG.
- Uniform gap -4.24: PLAUSIBLE-UNTESTED either way (TAU2 p 0.17, no persistence v between-team slope 1.93, cor +0.58). Shrunk lifts rivals (Owl Out, Jazzy), costs us 1.1pp.
- tau = 0: WEAKENED. Data tau ≈ 6-9; must pair with gap treatment: uniform + tau 8.3 -> 5.8%; shrunk + residual tau -> 2.7%; + longer-horizon SIG -> 3.0%.
- Base as ROS: VERIFIED (beats ppg, blend; ties latest; slope 0.96; uniform +1.55 bias).
- Points add 1:1: VERIFIED for trades (player slope 0.95, within-team 1.08). 1.3x multiplier REJECTED.
- Gate licence: PLAUSIBLE — same-week ceiling -> margin; multi-week weaker (r +0.44, CI crosses 0).
- ADR 0008 forking: low risk (ex-wk6 53.5% [47.2, 59.7], n 256 -> rule fires anyway; cuts from S1/S2 classes; decision impact 0).
- Other post-hoc thresholds untested (role rule, gate window, variant). Gate p 0.005 survives x3 Bonferroni.
- Frozen rosters: WEAKENED for us (L2).
- Helper MC pairing: tau 0 v tau 6 not paired — `rnorm(sd = 0)` consumes no draws -> stream shifts. Use >= 5 seeds (done).

## 5. Open
Intra-matchup correlation from shared NFL games not modelled (aggregate margin check only). 7-wk persistent drift extrapolated (max 4-wk horizon, 10 teams). L2 drift not decomposed (DST v claims v byes). ADR 0008 not refit as continuous curve. IR returns not in sim. Re-run `s04_sens.R` after Tue's wk8 entry (gate n 30; SIG/GAP/TAU2 move).
Scripts: `p2_stats/s00_baseline.R`, `s01_noise.R`, `s02_origin_run.R` + `league_sim_origin.R`, `s02_tau.R`, `s03_player.R`, `s04a_mats.R`, `s04_sens.R`, `s05_checks.R`, each with `.out`.
