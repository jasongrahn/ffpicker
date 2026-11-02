# P2 baseline: reproduce helper numbers, dump cl (gap data), M0, GAPS.
SC <- "docs/review/002-evidence"
source(file.path(SC, "sim_helpers.R"))
OUT <- file.path(SC, "p2_stats")
cat("CUR", CUR, "EXDATE", EXDATE, "WEEKS", WEEKS, "\n")
cat(sprintf("SIG %.3f GAP %.3f TAU2 %.2f n %d\n", SIG, GAP, TAU2, nrow(cl)))
print(round(M0, 1))
cat("fut strength:\n"); print(round(sort(apply(M0, 1, fut), decreasing = TRUE), 1))
s0 <- simulate_cond(M0); print(pt4(s0))
s6 <- simulate_cond(M0, tau = 6); print(pt4(s6))
print(round(colMeans(s0$top4), 3))
saveRDS(list(cl = cl, M0 = M0, GAPS = GAPS, tg = tg, W0 = W0, PF0 = PF0, G = G, teams = teams, R = R),
        file.path(OUT, "baseline_objs.rds"))
