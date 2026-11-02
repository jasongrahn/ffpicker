# A2 (underdog variance) — FINDINGS, 2026-11-02. Saved by lead from the agent's hand-back.

Scripts (a2_variance/, each saves .rds): t1_sim_sigma.R, t2_data.R, t2a_corr.R, t2b_sd_stability.R, t2c_shape.R, t3_roster.R, t4_levers.R. Helper baseline (wk8 L fixed), CRN, 10 seeds x N 20000 unless stated; seed-paired SEs.

## 1. Headline
- Weekly variance (stacks, boom-bust picks, NFL-team overlap with opponent) real but tiny: every available option <= +0.3pp P(top 4), most ~0.1pp. No weekly rule; 15% band unchanged.
- Season-level variance IS a lever while underdog: P(top 4) convex -> 25% chance of +8/wk ≈ 1.5x a sure +2 (same EV). In waivers/trades at similar value, buy upside, not floor.
- TR1/TR2 unchanged: send.

## 2. Numbers
t1 (only our weekly sd raised; others SIG 21.08):
| our sd | dP pp (se) | dW | pts/wk equiv (dP / dW) |
|---|---|---|---|
| +1 | +0.19 (0.013) | +0.031 | 0.40 / 0.38 |
| +2 | +0.41 (0.019) | +0.061 | 0.82 / 0.74 |
| +4 | +0.81 (0.032) | +0.117 | 1.56 / 1.42 |
| +6 | +1.25 (0.034) | +0.172 | 2.30 / 2.07 |
Exchange same runs: +1 pt/wk -> +0.49pp, +0.082 W (base 2.64%). Per-game P(W) sd+0 -> +6: wk9 .323->.345, wk10 .279->.305, wk11 .291->.316, wk12 .354->.373, wk13 .265->.292, wk14 .271->.298, wk15 .292->.317 (~+0.004/game per +1 sd).
#51 check: formula right; real |μ| wks 9-15 = 16.0 (not 14), σ_m 29.81 -> +1 margin sd = 0.54 pts; we control only our sd, pass-through 21.08/29.81 = 0.71 -> **+1 our sd ≈ +0.38 pts/wk** (analytic 0.379; sim 0.38-0.40).

t2a correlations 2024-25 REG (half-PPR via score_player_week, matches nflverse 99.73% of 11,901 non-K rows; misses = return TDs; DST from team stats + tiers; starter-calibre, player-season demeaned; cluster bootstrap B 2000):
QB1-WR1 +0.36 [.27,.43] n 672; QB1-WR2 +0.46 [.39,.52] n 400; QB1-TE1 +0.28 [.19,.36] n 575; QB1-RB1 +0.02; WR1-WR2 +0.01; RB1-own DST +0.07; QB1-own DST -0.12 [-.19,-.05]; K-own QB1 +0.03; QB1 v opp QB1 +0.25 [.16,.33]; QB1 v opp WR1 +0.16; DST v opp QB1 -0.36 [-.41,-.30] n 756.
Within-player weekly sd: QB 7.4, RB1 7.6, WR1 7.2, WR2 6.7, TE1 5.7, K 4.6, DST 5.3. QB-WR stack adds ≈ 38 variance -> team sd 21.08 -> 21.96 (+0.9) ≈ 0.35 pts/wk. Max stack (QB+WR+TE same team) +60 var ≈ +1.4 sd.

t2b boom-bust stability (log-sd residual at equal mean): odd v even weeks r +0.007 [-0.11, 0.12] n 303; 2024 -> 2025 r +0.21 [0.02, 0.39] n 102 (QB +0.47 n 20, TE +0.36, RB +0.19, WR +0.08). True spread ~9% (1 SD); ~80% of observed spread = sampling noise. TD share predicts next-season volatility r +0.28 but within ~9%. Best case ≈ 0.16 pts/wk; realistic ≈ 0.03. -> "pick the boom-bust guy" NOT a lever.

t2c shape: sim noise skew -0.08, ex-kurt -0.34, Shapiro p 0.46; team scores (n 70) skew +0.27, ex-kurt -0.11; margin tail P(>16) 0.299 emp v 0.296 normal. P(top 4): normal 2.68%, empirical quantiles 2.67%, smoothed bootstrap 2.70%, t5 stress (unsupported) 1.93%. +2 sd worth 0.41-0.46pp under all supported models -> normal noise fine.

t3 our roster: only possible stack = Stafford (LA QB) + Davante Adams (LA WR, IR, earliest wk12). Kyler + Hockenson (MIN) never live (Kyler not projected starter). Odunze + Burden (both CHI WR) post-TR2: WR-WR r +0.01 -> no variance. Jacobs (GB), Likely (NYG): no QB pair. Nobody in league stacks (within-lineup stack variance -4.8..+5.6; ours +0.3) -> SIG = "unstacked". Overlap with opponents slightly against us: worst wk15 v Owl Out (Puka Nacua = Stafford's top WR, r +0.39; post-TR2 Caleb Williams = Burden's QB) -> margin var -73 (sd 29.8 -> 28.6). Wk13 Stafford v our Chiefs DST (r -0.36) = self-hedge; DST streamed anyway. Net priced: current -0.04pp (se 0.010); post TR1+TR2 -0.12pp (se 0.012). Trades themselves +3.6pp (2.64% -> 6.28%).

t4 options (pts-equivalent from sure +2 arm: 0.53pp/pt current, 1.03pp/pt post-TR):
| move | current dP pp | post-TR dP pp | ≈ pts/wk |
|---|---|---|---|
| Start Adams with Stafford wks 12-15 (v equal-proj WR) | +0.09 | +0.16 | 0.15-0.17 |
| DST facing opponent's QB every week | +0.12 | +0.17 | 0.17-0.23 |
| Theoretical max QB+WR+TE stack every week | +0.28 | +0.41 | 0.39-0.53 |
| Persistent spread N(0, 3²) on our strength | +0.26 | +0.44 | — |
| Persistent spread N(0, 6²) | +1.18 | +1.84 | ≈ sure +2 |
| Sure +2 pts/wk | +1.06 | +2.06 | 2 |
| 25% chance of +8/wk (EV +2) | +1.62 | +2.91 | 1.4-1.5x sure |
| 10% chance of +20/wk (EV +2) | +3.21 | +4.48 | 2.2-3.0x sure |
| Sure +4 / 33% of +12 (EV +4) | +2.38 / +4.19 | +4.66 / +7.07 | 1.5-1.8x |
Mean-preserving spread: dW ≈ 0 but P(top 4) up — need 5-2, only upside paths count.

## 3. Levers
- L1 ADOPT (near-zero cost): underdog buys SEASON-level upside, not floor — waivers + trades only. At similar sim value prefer: IR returner (Adams, Etienne), backup RB behind fragile/old starter, rookie with rising snaps, player back from injury. Upside "25% x +8/wk" ≈ +0.6pp (current) / +0.9pp (post-TR) more than equal-EV sure thing. Cost ≈ 0 time (tiebreak inside decisions already made), 1 bench spot; risk = misjudged odds. Sim caveat: trade_finder scores point estimates (tau 0, IR excluded) -> undervalues upside packages; 2.6% = low-side. Kill per stash: within 2 wks after add (window starts week after), role never opens = starter active both weeks AND stash snaps < 20% both weeks -> drop. Kill rule: re-run t4 when P(top 4) >= 25% or favoured in >= 4 remaining games (curve may flip -> floor beats upside).
- L2 REJECT weekly variance: stacks, boom-bust, overlap avoidance, DST v opp QB each <= +0.17pp, <= 0.5 pts/wk even at theoretical max; weekly overlap check ≈ 5-10 min user time for ~0.1pp.
- CLAUDE.md stack rule under underdog lens HOLDS for weekly stacks: +1 our sd ≈ 0.38 pts/wk -> stack worth paying only if it costs < ~0.3 projected pts/wk; in-band projection still earns +0.88/pair (ADR 0008) > ~0.35 a stack buys -> stack wins only at near-exact tie (< ~0.3 pts), worth ~0.1pp.
Proposed CLAUDE.md addendum: "Underdog variance priced 2026-11-02 (A2): +1 our weekly sd ≈ +0.38 pts/wk. QB-WR stack ≈ +0.35, DST v opp QB ≈ +0.2 -> never pay > ~0.3 pts projected. No variance tiebreak in the band. Season-level upside is different: convex odds -> at equal value, underdog takes upside (25% x +8/wk ≈ 1.5x sure +2). Recheck at P(top 4) >= 25%."

## 4. Assumptions challenged
Supported: CLAUDE.md stack rule (even as underdog); 15% band (no tiebreak); normal sim noise (empirical moves P 0.01pp); ADR 0011 (opp-QB DST worth <= ~0.6 implied pts).
Corrected: #51 "+1 margin sd ≈ +0.47 pts" -> 0.38 pts per +1 OUR sd (μ ≈ -16, 0.71 pass-through).
Broken as lever: boom-bust picking (~80% of sd spread = noise; true spread ~9%).
Weakened: point-estimate valuation (tau 0, IR excluded) biased against upside for an underdog. TR1+TR2 unaffected (overlap -0.08pp v +3.6pp).

## 5. Open
No odds for named wire players (A4's job). Correlations position-level 2024-25, not player-specific; DST from team stats, unvalidated v Yahoo. Lineups proj-optimal from 10-28 export. Curve flip point (P at which favourite buys floor) not tested. Repo bug (not fixed): `score_player_week()` ignores `misc$return_td` (32 of 11,901 rows 2024-25). t1 dW SE printed NA (summarise-order bug); dW means + dP SEs valid.
