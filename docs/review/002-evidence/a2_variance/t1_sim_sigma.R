# Task 1: our weekly sd -> P(top 4), exp wins, per-game P(win). Points-equivalent via mean shifts.
# Run from repo root. CRN: same seed for every arm; >= 10 seeds -> paired deltas + seed sd.
SCR <- "docs/review/002-evidence"
suppressMessages(source(file.path(SCR, "sim_helpers.R")))
t0 <- Sys.time()
cat(sprintf("SIG %.3f  GAP %.3f  CUR %d  N %d\n", SIG, GAP, CUR, N))
SEEDS <- SEED + 0:9
DS <- c(0, 1, 2, 4, 6)          # +sd on our team only
MU <- c(0.25, 0.5, 1, 2, 3)     # +pts/wk on our team only (wks 9-15), for the exchange rate
mine <- which(G$a == ME | G$b == ME)
gw <- G$week[mine]
pwin <- function(s) { x <- s$win[, mine, drop = FALSE]; flip <- G$b[mine] == ME; x[, flip] <- !x[, flip]; colMeans(x) }
res <- list()
for (sd_ in SEEDS) {
  for (d in DS) {
    sg <- setNames(rep(SIG, 10), teams); sg[ME] <- SIG + d
    s <- simulate_cond(M0, seed = sd_, sig_team = sg)
    res[[length(res) + 1]] <- data.frame(seed = sd_, arm = sprintf("sd+%g", d), dsd = d, dmu = 0,
      p_top4 = mean(s$top4[, ME]), ew = mean(s$W[, ME]), t(pwin(s)))
  }
  for (m in MU) {
    Mx <- M0; Mx[ME, -1] <- Mx[ME, -1] + m
    s <- simulate_cond(Mx, seed = sd_)
    res[[length(res) + 1]] <- data.frame(seed = sd_, arm = sprintf("mu+%g", m), dsd = 0, dmu = m,
      p_top4 = mean(s$top4[, ME]), ew = mean(s$W[, ME]), t(pwin(s)))
  }
}
r <- do.call(rbind, res)
names(r)[-(1:6)] <- paste0("wk", gw)
saveRDS(r, file.path(SCR, "a2_variance", "t1_sim_sigma.rds"))
b <- r[r$arm == "sd+0", ]
r$dP <- r$p_top4 - b$p_top4[match(r$seed, b$seed)]
r$dW <- r$ew - b$ew[match(r$seed, b$seed)]
agg <- r |> group_by(arm, dsd, dmu) |> summarise(p_top4 = mean(p_top4), dP_pp = 100 * mean(dP),
  dP_se = 100 * sd(dP) / sqrt(n()), dW = mean(dW), dW_se = sd(dW) / sqrt(n()), .groups = "drop") |>
  arrange(dmu, dsd)
print(as.data.frame(agg), digits = 4)
# per-game P(win) vs our sd
pg <- r |> filter(dmu == 0) |> group_by(dsd) |> summarise(across(starts_with("wk"), mean), .groups = "drop")
cat("\nPer-game P(win) (mean over seeds), by +sd on our team:\n"); print(as.data.frame(pg), digits = 3)
# points-equivalent: linear interp of dP (and dW) on the mu arms
mua <- agg |> filter(dsd == 0) |> select(dmu, dP_pp, dW)
pe <- function(y, col) approx(c(0, mua[[col]]), c(0, mua$dmu), xout = y, rule = 2)$y
sda <- agg |> filter(dmu == 0, dsd > 0)
sda$pts_eq_P <- pe(sda$dP_pp, "dP_pp"); sda$pts_eq_W <- pe(sda$dW, "dW")
cat("\nPoints-equivalent of +sd (pts/wk wks 9-15 giving same dP / same dW):\n")
print(as.data.frame(sda[, c("dsd", "dP_pp", "dP_se", "dW", "pts_eq_P", "pts_eq_W")]), digits = 3)
# analytic per game: mu margin from M0, sigma_m = sqrt(sig_us^2 + SIG^2)
mm <- sapply(mine, function(j) { a <- G$a[j]; b2 <- G$b[j]; k <- as.character(G$week[j])
  if (a == ME) M0[a, k] - M0[b2, k] else M0[b2, k] - M0[a, k] })
names(mm) <- paste0("wk", gw)
fut_ <- gw > CUR
cat("\nAnalytic per-game (future weeks): margin mu, P(win) normal:\n")
sm <- sqrt(2) * SIG
an <- data.frame(week = gw, mu = round(mm, 2), p_norm = round(pnorm(mm / sm), 3),
  ratio_mu_over_sigm = round(abs(mm) / sm, 3), pts_per_team_sd = round(abs(mm) / sm * SIG / sm, 3))
print(an[fut_, ], row.names = FALSE)
cat(sprintf("mean |mu| fut %.2f; sigma_m %.2f; mean ratio %.3f; pts per +1 our-sd %.3f\n",
  mean(abs(mm[fut_])), sm, mean(abs(mm[fut_])) / sm, mean(abs(mm[fut_])) / sm * SIG / sm))
for (d in DS[-1]) { s2 <- sqrt((SIG + d)^2 + SIG^2)
  cat(sprintf("  sd+%g: sigma_m %.2f (+%.2f) analytic mean dP(win)/game %+.4f; mu-equiv %.3f pts\n", d, s2, s2 - sm,
    mean(pnorm(mm[fut_] / s2) - pnorm(mm[fut_] / sm)),
    mean(mm[fut_] * s2 / sm - mm[fut_]) ))   # mu shift giving same z: mu' = mu*sm/s2 ... equiv
}
cat("elapsed", format(Sys.time() - t0), "\n")
