# Value of VARIANCE for a left-tail team. Two kinds, both mean-preserving:
#  (1) persistent ROS-strength variance for US only (lottery tickets: stash hits, role breakouts) = tau_us
#  (2) week-to-week variance for US only (boom-bust starters, stacks) = sig_us
# CRN: simulate_cond's RNG stream is reused exactly (d drawn as N(0,1) then scaled per team).
SCR <- "docs/review/002-evidence"
suppressMessages(source(file.path(SCR, "sim_helpers.R")))
sim_v <- function(M, tau_vec = setNames(rep(0, 10), teams), sig_vec = setNames(rep(SIG, 10), teams), n = N, seed = SEED, fixed = WK8_FIXED) {
  stopifnot(identical(rownames(M), teams)); set.seed(seed)
  mu <- M + GAPS
  W <- matrix(W0, n, 10, byrow = TRUE); PF <- matrix(PF0, n, 10, byrow = TRUE)
  d <- sweep(matrix(rnorm(n * 10, 0, 1), n, 10), 2, tau_vec[teams], `*`)
  for (k in seq_along(WEEKS)) {
    Z <- matrix(rnorm(n * 10, 0, 1), n, 10)
    S <- matrix(mu[, k], n, 10, byrow = TRUE) + d + sweep(Z, 2, sig_vec[teams], `*`)
    if (WEEKS[k] == CUR) for (t in names(fixed)) S[, match(t, teams)] <- fixed[[t]]
    PF <- PF + S
    for (j in which(G$week == WEEKS[k])) { aw <- S[, G$ia[j]] > S[, G$ib[j]]
      W[, G$ia[j]] <- W[, G$ia[j]] + aw; W[, G$ib[j]] <- W[, G$ib[j]] + !aw }
  }
  rk <- t(apply(W * 1e4 + PF / 1e3, 1, function(x) rank(-x, ties.method = "first"))); colnames(rk) <- teams
  c(p = mean(rk[, ME] <= 4), w = mean(W[, match(ME, teams)]))
}
seeds <- SEED + 0:4
base_p <- sapply(seeds, function(s) sim_v(M0, seed = s))
cat(sprintf("baseline (helper-equivalent) P(top4) mean over %d seeds: %.4f  [per seed: %s]  exp W %.2f\n", length(seeds),
            mean(base_p["p", ]), paste(round(base_p["p", ], 4), collapse = " "), mean(base_p["w", ])))
chk <- pt4(simulate_cond(M0)); cat(sprintf("helper simulate_cond seed SEED: %.4f (must equal seed-1 value above)\n", chk[1]))
row <- function(lbl, f) { v <- sapply(seeds, f); d <- v["p", ] - base_p["p", ]
  cat(sprintf("%-38s P %.4f  dP %+.4f (seed sd %.4f)  dW %+.3f\n", lbl, mean(v["p", ]), mean(d), sd(d), mean(v["w", ] - base_p["w", ]))) }
cat("\n(1) persistent ROS-strength sd for US only, mean-preserving\n")
for (tu in c(3, 6, 9, 12)) row(sprintf("tau_us = %d", tu), function(s) { tv <- setNames(rep(0, 10), teams); tv[ME] <- tu; sim_v(M0, tau_vec = tv, seed = s) })
cat("\n(2) weekly sd for US only (SIG = %.2f), mean-preserving\n")
for (su in c(23, 25, 27, 30)) row(sprintf("sig_us = %d (base %.1f)", su, SIG), function(s) { sv <- setNames(rep(SIG, 10), teams); sv[ME] <- su; sim_v(M0, sig_vec = sv, seed = s) })
cat("\n(3) mean shift for comparison\n")
for (m in c(1, 3, 5)) row(sprintf("+%d pts/wk wks 9-15", m), function(s) { Mx <- M0; Mx[ME, -1] <- Mx[ME, -1] + m; sim_v(Mx, seed = s) })
cat("\n(4) lottery ticket: 25%% chance of +10/wk persistent (stash hits), else -0.5 (cost of slot)  [mean +2.1]\n")
# implemented as a two-point persistent shift: draw independent of everything else via separate RNG
row("ticket 25% x +10, else -0.5", function(s) {
  set.seed(s + 999); hit <- runif(N) < 0.25
  # run two sims with shift and blend by hit flag using same main seed
  Mh <- M0; Mh[ME, -1] <- Mh[ME, -1] + 10; Mm <- M0; Mm[ME, -1] <- Mm[ME, -1] - 0.5
  a <- sim_v(Mh, seed = s); b <- sim_v(Mm, seed = s); c(p = 0.25 * a[["p"]] + 0.75 * b[["p"]], w = 0.25 * a[["w"]] + 0.75 * b[["w"]]) })
row("certain +2.1/wk (same mean)", function(s) { Mx <- M0; Mx[ME, -1] <- Mx[ME, -1] + 2.125; sim_v(Mx, seed = s) })
