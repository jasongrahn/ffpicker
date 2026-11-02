# Price process levers in wins with the shared sim (sim_helpers.R, wk8 L fixed).
# Run from repo root:  Rscript <scratch>/meta/a5_process/price_process_levers.R
# Every delta = same seed (common random numbers); 5 seeds x N 20000 -> mean, min-max.
suppressMessages(source("docs/review/002-evidence/sim_helpers.R"))
SEEDS <- 20261021 + 0:4
wk_col <- function(w) as.character(w)
bump <- function(M, pts, weeks) { M[ME, wk_col(weeks)] <- M[ME, wk_col(weeks)] + pts; M }
delta <- function(Mx, tau = 0) {
  d <- sapply(SEEDS, function(s) {
    b <- pt4(simulate_cond(M0, tau = tau, seed = s)); a <- pt4(simulate_cond(Mx, tau = tau, seed = s))
    c(dP = unname(a[1] - b[1]), dW = unname(a[2] - b[2]), base = unname(b[1])) })
  sprintf("dP %+5.2fpp [%+5.2f,%+5.2f]  dW %+5.3f  (base %.1f%%)", 100 * mean(d["dP", ]),
          100 * min(d["dP", ]), 100 * max(d["dP", ]), mean(d["dW", ]), 100 * mean(d["base", ]))
}
cat("Weeks in M0:", colnames(M0), "\n")
cat("\n== One-week shocks (wk9) — what a single gameday action is worth ==\n")
for (p in c(0.2, 1.92, 8.5, -8.5)) cat(sprintf("%+6.2f pts in wk9 only: %s\n", p, delta(bump(M0, p, 9))))
cat("\n== Season levers, wks 9-15 ==\n")
cat("DST stream edge +1.92/wk:      ", delta(bump(M0, 1.92, 9:15)), "\n")
cat("Lineup coin flips +0.2/wk:     ", delta(bump(M0, 0.2, 9:15)), "\n")
cat("Injury-zero avoided 1 in 3 wks (+8.5/3 = +2.83/wk):", delta(bump(M0, 8.5 / 3, 9:15)), "\n")
cat("\n== Trade delay: +X pts/wk from landing week k to 15 ==\n")
for (X in c(3, 5.85)) for (k in 9:13)
  cat(sprintf("X %4.2f lands wk%-2d: %s\n", X, k, delta(bump(M0, X, k:15))))
