# Q7: sensitivity of OUR P(top 4) and of the TR1+TR2 delta to each noise/strength assumption. CRN, 5 seeds.
SC <- "docs/review/002-evidence"
OUT <- file.path(SC, "p2_stats")
source(file.path(SC, "sim_helpers.R"))
Lm <- readRDS(file.path(OUT, "mats_mean.rds")); Ll <- readRDS(file.path(OUT, "mats_latest.rds"))
me <- match(ME, teams)
# flexible sim: identical draws to simulate_cond() at defaults (checked below)
sim_flex <- function(M, n = N, seed = SEED, gaps = GAPS, tau = 0, sig = SIG, sig_team = NULL, df = Inf, beta = 1,
                     wk_sd = 0, add_us = 0, fixed = WK8_FIXED) {
  stopifnot(identical(rownames(M), teams))
  set.seed(seed)
  Mb <- M; for (k in seq_len(ncol(M))) Mb[, k] <- mean(M[, k]) + beta * (M[, k] - mean(M[, k]))
  Mb[ME, -1] <- Mb[ME, -1] + add_us
  mu <- Mb + gaps[teams]
  tau_t <- if (length(tau) == 1) rep(tau, 10) else tau[teams]
  sd_t <- if (is.null(sig_team)) rep(sqrt(sig^2 - wk_sd^2), 10) else sig_team[teams]
  W <- matrix(W0, n, 10, byrow = TRUE); PF <- matrix(PF0, n, 10, byrow = TRUE)
  d <- if (all(tau_t == 0)) matrix(0, n, 10) else sweep(matrix(rnorm(n * 10, 0, 1), n, 10), 2, tau_t, `*`)   # rnorm(sd=0) draws nothing
  for (k in seq_along(WEEKS)) {
    Z <- if (is.finite(df)) matrix(rt(n * 10, df) * sqrt((df - 2) / df), n, 10) else matrix(rnorm(n * 10, 0, 1), n, 10)
    S <- matrix(mu[, k], n, 10, byrow = TRUE) + d + sweep(Z, 2, sd_t, `*`)
    if (wk_sd > 0) S <- S + rnorm(n, 0, wk_sd)
    if (WEEKS[k] == CUR) for (t in names(fixed)) S[, match(t, teams)] <- fixed[[t]]
    PF <- PF + S
    for (j in which(G$week == WEEKS[k])) {
      aw <- S[, G$ia[j]] > S[, G$ib[j]]
      W[, G$ia[j]] <- W[, G$ia[j]] + aw; W[, G$ib[j]] <- W[, G$ib[j]] + !aw
    }
  }
  rk <- t(apply(W * 1e4 + PF / 1e3, 1, function(x) rank(-x, ties.method = "first")))
  c(p = mean(rk[, me] <= 4), w = mean(W[, me]))
}
chk <- c(sim_flex(Lm$M0), pt4(simulate_cond(Lm$M0)))
cat("check sim_flex == simulate_cond:", chk, "\n"); stopifnot(abs(chk[1] - chk[3]) < 1e-12)
# shrunk gaps + posterior var of each team's gap
tgx <- tg |> dplyr::mutate(B = TAU2 / (TAU2 + se2), shrunk = GAP + B * (g - GAP), pv = TAU2 * se2 / (TAU2 + se2))
GS <- setNames(tgx$shrunk, tgx$team); PV <- setNames(tgx$pv, tgx$team)
cat(sprintf("our gap: uniform %.2f | raw %.2f | shrunk %.2f (posterior sd %.2f)\n", GAP, tgx$g[tgx$team == ME], GS[ME], sqrt(PV[ME])))
SEEDS <- SEED + 0:4
run <- function(lab, M0x = Lm$M0, M12x = Lm$M12, ...) {
  r <- sapply(SEEDS, function(s) { a <- sim_flex(M0x, seed = s, ...); b <- sim_flex(M12x, seed = s, ...)
    c5 <- { Mx <- M0x; Mx[ME, -1] <- Mx[ME, -1] + 5; sim_flex(Mx, seed = s, ...) }
    c(p0 = a[["p"]], w0 = a[["w"]], dTR = b[["p"]] - a[["p"]], dW = b[["w"]] - a[["w"]], d5 = c5[["p"]] - a[["p"]]) })
  m <- rowMeans(r); se <- apply(r, 1, sd) / sqrt(ncol(r))
  data.frame(scenario = lab, p_top4 = round(100 * m["p0"], 2), se = round(100 * se["p0"], 2), exp_w = round(m["w0"], 2),
             dP_TR12 = round(100 * m["dTR"], 2), se_TR = round(100 * se["dTR"], 2), dW_TR12 = round(m["dW"], 2), dP_plus5 = round(100 * m["d5"], 2))
}
sig_h <- sqrt(SIG^2 + 45)    # + within-team drift variance at 2-4 wk horizon (s02_tau.out: 39-50)
tau_data <- sqrt(TAU2 + 25)  # gap persistence + persistent drift (s02: 6-41)
res <- rbind(
  run("baseline (tau 0, SIG 21.1, uniform gap)"),
  run("SIG 17.6 (95% CI low)", sig = 17.6), run("SIG 26.3 (95% CI high)", sig = 26.3),
  run(sprintf("SIG %.1f horizon (+drift var 45)", sig_h), sig = sig_h),
  run("tau 3", tau = 3), run("tau 6", tau = 6), run(sprintf("tau %.1f (TAU2+drift)", tau_data), tau = tau_data), run("tau 12", tau = 12),
  run("GAP shrunk", gaps = GS),
  run("GAP shrunk + tau_t = post sd", gaps = GS, tau = sqrt(PV)),
  run("GAP shrunk + tau_t = sqrt(post var + 25)", gaps = GS, tau = sqrt(PV + 25)),
  run("beta 0.8 (projection diffs overstated)", beta = 0.8), run("beta 1.3 (gate slope)", beta = 1.3), run("beta 1.56 (pf~ceiling slope)", beta = 1.56),
  run("week common shock sd 5.3 (total SIG fixed)", wk_sd = 5.3),
  run("t5 tails, same sd", df = 5),
  run("our sd 15 (others 21.1)", sig_team = setNames(ifelse(teams == ME, 15, SIG), teams)),
  run("our sd 27 (others 21.1)", sig_team = setNames(ifelse(teams == ME, 27, SIG), teams)),
  run("BASE latest", M0x = Ll$M0, M12x = Ll$M12),
  run("us +2/wk (streaming drift, frozen-roster bias)", add_us = 2),
  run("us -2/wk", add_us = -2),
  run("COMBO data-supported: shrunk gap + tau_t sqrt(pv+25) + SIG horizon", gaps = GS, tau = sqrt(PV + 25), sig = sig_h),
  run("COMBO + BASE latest", M0x = Ll$M0, M12x = Ll$M12, gaps = GS, tau = sqrt(PV + 25), sig = sig_h)
)
res$dP_vs_base <- round(res$p_top4 - res$p_top4[1], 2)
print(res[, c("scenario", "p_top4", "se", "dP_vs_base", "exp_w", "dP_TR12", "se_TR", "dW_TR12", "dP_plus5")], row.names = FALSE)
saveRDS(res, file.path(OUT, "sens.rds"))
cat("\nshrunk gaps:\n"); print(round(sort(GS, decreasing = TRUE), 2))
