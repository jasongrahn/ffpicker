# A1 Q4 sim: our P(top 4) conditional on all 10 provisional wk8 scores (q4_wk8_prov.R),
# + robustness (noise on the 9 non-us scores, K draws, same seed = CRN), + SK/Max's flip scenario.
# Run from repo root. GAPMODE env honoured (set before sourcing the helper): uniform (default) | shrunk.
setwd("/Users/jasongrahn/R-projects/ffootballer")
META <- "docs/review/002-evidence"
OUT <- file.path(META, "a1_luck")
source(file.path(META, "sim_helpers.R"))
cat(sprintf("GAPMODE %s | CUR %d | N %d | SEED %d | GAP %.2f SIG %.2f TAU2 %.1f\n", GAPMODE, CUR, N, SEED, GAP, SIG, TAU2))
cat("GAPS:\n"); print(round(GAPS, 2))
pv <- read.csv(file.path(OUT, "q4_wk8_prov_scores.csv"), encoding = "UTF-8", stringsAsFactors = FALSE)
F10 <- setNames(pv$score, pv$team)[teams]; stopifnot(!anyNA(F10), identical(names(F10), teams))
F10_love <- F10; F10_love[MICH] <- 119.16                                   # Michelle with Love at QB
t0 <- Sys.time()
b_helper <- pt4(simulate_cond(M0))                                           # helper default: us + Michelle fixed
cat(sprintf("one call %.1fs\n", as.numeric(Sys.time() - t0, units = "secs")))
s10 <- simulate_cond(M0, fixed = F10)
b10 <- pt4(s10); b10l <- pt4(simulate_cond(M0, fixed = F10_love))
cat(sprintf("\nhelper default (us 87.50 + MICH 120 fixed, 4 games simulated): P(top4) %.4f  expW %.3f\n", b_helper[1], b_helper[2]))
cat(sprintf("all 10 fixed (provisional):                              P(top4) %.4f  expW %.3f\n", b10[1], b10[2]))
cat(sprintf("all 10 fixed, Michelle w/ Love 119.16:                   P(top4) %.4f  expW %.3f\n", b10l[1], b10l[2]))
# MC error, one seed
cat(sprintf("MC se (binomial, one seed): %.4f\n", sqrt(b10[1] * (1 - b10[1]) / N)))
# Seeds check: 5 seeds
ss <- sapply(1:5, function(k) pt4(simulate_cond(M0, fixed = F10, seed = SEED + k))[1])
cat(sprintf("5 extra seeds: %s  mean %.4f\n", paste(round(ss, 4), collapse = " "), mean(ss)))

# Standings after wk8 (provisional)
W8 <- W0; PF8 <- PF0
for (j in which(G$week == 8)) { a <- G$a[j]; b <- G$b[j]; if (F10[a] > F10[b]) W8[a] <- W8[a] + 1 else W8[b] <- W8[b] + 1 }
PF8 <- PF8 + F10
cat("\nprovisional standings after wk8:\n"); print(data.frame(W = W8, L = 8 - W8, PF = round(PF8, 2))[order(-W8, -PF8), ])

# P(top 4 | final wins), from the all-10-fixed sim
cat("\nP(top4 | our final wins), all-10-fixed:\n")
fw <- s10$W[, ME]; print(round(tapply(s10$top4[, ME], fw, mean), 3)); print(round(table(fw) / N, 3))
# per-game leverage, remaining
lev <- sapply(which(G$week > 8 & (G$a == ME | G$b == ME)), function(j) {
  w <- if (G$a[j] == ME) s10$win[, j] else !s10$win[, j]
  c(week = G$week[j], p_win = mean(w), p4_W = mean(s10$top4[w, ME]), p4_L = mean(s10$top4[!w, ME])) })
cat("\nremaining games (all-10-fixed):\n"); print(round(t(lev), 3))

# Robustness: K draws of noise on the 9 non-us scores, same seed (CRN for wks 9-15)
rob <- function(sd, K = 40, n = N) {
  set.seed(777)
  E <- matrix(rnorm(K * 10, 0, sd), K, 10, dimnames = list(NULL, teams)); E[, ME] <- 0
  t(sapply(seq_len(K), function(k) {
    fx <- F10 + E[k, ]
    flips <- sum(sapply(which(G$week == 8), function(j) (fx[G$a[j]] > fx[G$b[j]]) != (F10[G$a[j]] > F10[G$b[j]])))
    c(pt4(simulate_cond(M0, fixed = fx, n = n)), flips = flips) }))
}
for (sd in c(8, 13.1)) {
  R1 <- rob(sd)
  cat(sprintf("\nrobustness sd %.1f, K 40: P(top4) mean %.4f  sd %.4f  range [%.4f, %.4f]; expW mean %.3f; game flips/draw mean %.2f\n",
              sd, mean(R1[, 1]), sd(R1[, 1]), min(R1[, 1]), max(R1[, 1]), mean(R1[, 2]), mean(R1[, 3])))
}
# Scenario: Max's beat Sunday Kevin (SK's Thu lineup never fixed: replay median 77.68 -> Max's 90.47 wins)
F_sk <- F10; F_sk["Sunday Kevin"] <- 77.68
cat(sprintf("\nscenario SK unfixed (77.68, loses to Max's): P(top4) %.4f expW %.3f\n", pt4(simulate_cond(M0, fixed = F_sk))[1], pt4(simulate_cond(M0, fixed = F_sk))[2]))
# Scenario: Jazzy beat Mitchell (Mitchell's Thu set median 104.22 < Jazzy 109.36)
F_jm <- F10; F_jm["Maybe Mitchell"] <- 104.22
cat(sprintf("scenario Jazzy beats Mitchell (104.22):  P(top4) %.4f\n", pt4(simulate_cond(M0, fixed = F_jm))[1]))
F_both <- F_sk; F_both["Maybe Mitchell"] <- 104.22
cat(sprintf("both flips:                               P(top4) %.4f\n", pt4(simulate_cond(M0, fixed = F_both))[1]))
# Exchange rate on the all-10-fixed baseline
ex <- do.call(rbind, lapply(c(1, 3, 5, 10, 15), function(v) { Mx <- M0; Mx[ME, -1] <- Mx[ME, -1] + v
  a <- pt4(simulate_cond(Mx, fixed = F10)); data.frame(pts_wk = v, p_top4 = a[1], dP = a[1] - b10[1], dW = a[2] - b10[2]) }))
cat("\nexchange rate, all-10-fixed baseline:\n"); print(round(ex, 4), row.names = FALSE)
saveRDS(list(b_helper = b_helper, b10 = b10, F10 = F10, ex = ex), file.path(OUT, sprintf("q4_sim_%s.rds", GAPMODE)))
