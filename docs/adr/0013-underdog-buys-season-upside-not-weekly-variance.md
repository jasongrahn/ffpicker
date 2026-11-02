# Underdog: buy season-level upside at equal value; weekly variance is not a lever

2026-11-02, review 002. In-season.

Context. We are the underdog in all 7 remaining games (P(win) .27-.35). For an underdog,
P(win) = Φ(μ/σ) rises with σ, and P(top 4) is convex in strength (+1 pt/wk -> +0.47pp, +10 ->
+9.9pp). Handoff #51 seed 2 asked whether variance beats points; `CLAUDE.md` said "a stack
that costs projected points to buy shared upside loses" with no underdog lens.

Decided:

- **Weekly variance: no rule.** +1 pt of OUR weekly sd ≈ **+0.38 pts/wk** of mean (|μ| 16 at
  σ_m 29.8; only 0.71 of our sd passes to margin; analytic 0.379, sim 0.38-0.40). Every weekly
  move we can make is tiny:

  | move | ΔP(top 4) | ≈ pts/wk |
  |---|---|---|
  | QB-WR1 stack (r +0.36..+0.38, adds +0.86 sd) | <= +0.16pp | +0.34 |
  | DST facing the opponent's QB (r −0.36) | +0.12..+0.17pp | +0.2 |
  | theoretical max, QB+WR+TE same team every week | +0.28..+0.41pp | +0.4..+0.5 |

  In-band (5-15%) the higher projection still earns +0.88 pts/pair (ADR 0008) > what a stack
  buys -> **never pay > ~0.3 projected pts for a weekly stack.** At a near-exact tie the stack
  is fine; never spend time on it.
- **Season-level upside: prefer it at equal sim value** — waivers and trades only. A persistent,
  mean-preserving spread raises P(top 4) because we need 5-2: 25% x +8/wk (EV +2) = +1.62pp v
  sure +2 = +1.06pp (1.5x); 50/50 {0, +10} ≈ a sure +6.1 (P3). Upside shapes: IR returner,
  RB one injury from a lead role, rookie with rising **volume** (>= 10 touches+targets/g ->
  15.6% hit; rising snaps alone 4.1%; A4 base rates 2021-25).
- Only in **free** spots: the stash premium (~1.25x) never justifies giving up projected points.

**Considered and rejected**:
- Variance tiebreak inside the 15% band (proposed by two panelists): costs +0.88/pair realized,
  buys <= 0.35.
- Picking "boom-bust" players: weekly sd at equal mean is not a stable trait (odd v even weeks
  r +0.007, n 303; 2024 -> 2025 r +0.21; ~80% of observed spread = sampling noise; A2 `t2b`).
- Avoiding NFL-team overlap with the opponent's starters: −0.04..−0.12pp total; 5-10 min/wk.
- Fat-tail noise: data say normal (skew −0.08, Shapiro p 0.46); empirical noise moves P 0.01pp.

Evidence: `docs/review/002-evidence/a2_variance/` (`t1_sim_sigma.R`, `t2a_corr.R` 2024-25
correlations, cluster bootstrap; `t2b_sd_stability.R`; `t4_levers.R`), `p3_decision/02_variance.R`,
`04_stack_corr.R`, `a4_wire/s4_baserates.R`.

Revisit: P(top 4) >= 25%, or favoured in >= 4 remaining games -> rerun `t4_levers.R`; the curve
may flip and floor beats upside.
