# Q2: risk posture. Sure gain vs gambles; weekly sd; persistent own-strength uncertainty. 10 seeds, CRN.
SCR <- "docs/review/002-evidence"
source(file.path(SCR, "sim_helpers.R")); source(file.path(SCR, "p3_decision/sim2.R"))
Mpo0 <- readRDS(file.path(OUT, "01_objective.rds"))$Mpo0
S10 <- SEED + 0:9
K <- length(WEEKS); fw <- WEEKS > CUR
coin <- function(sd, lo, hi, n = N) {            # per-week independent coin on OUR score, own stream
  set.seed(sd + 999L); x <- matrix(ifelse(runif(n * K) < .5, lo, hi), n, K); x[, !fw] <- 0; x }
r <- ms(seeds = S10, function(sd) {
  b <- sim2(M0, Mpo0, seed = sd); p <- P4(b); pc <- PC(b); w <- EW(b)
  f <- function(x) c(P4(x) - p, PC(x) - pc, EW(x) - w)
  sure5 <- f(sim2(addw(M0, 5), Mpo0 + c(0, 5)[1 + (rownames(Mpo0) == ME)], seed = sd))
  p0  <- c(0, 0, 0); p10 <- f(sim2(addw(M0, 10), Mpo0 + c(0, 10)[1 + (rownames(Mpo0) == ME)], seed = sd))
  pm4 <- f(sim2(addw(M0, -4), Mpo0 + c(0, -4)[1 + (rownames(Mpo0) == ME)], seed = sd))
  sure3 <- f(sim2(addw(M0, 3), Mpo0 + c(0, 3)[1 + (rownames(Mpo0) == ME)], seed = sd))
  wk <- f(sim2(addw(M0, 0), Mpo0, seed = sd, add_us = coin(sd, 0, 10)))     # weekly 0/+10, regular wks only
  sdv <- sapply(c(23, 25, 27, 30), function(v) P4(sim2(M0, seed = sd, sd_us = v)) - p)
  tv  <- sapply(c(3, 6, 10), function(v) P4(sim2(M0, seed = sd, tau_us = v)) - p)
  tv6 <- { b6 <- P4(sim2(M0, tau = 6, seed = sd)); sapply(c(3, 6, 10), function(v) P4(sim2(M0, tau = 6, seed = sd, tau_us = v)) - b6) }
  c(base_p4 = p, base_pc = pc,
    sure5_dP4 = sure5[1], sure5_dPC = sure5[2], sure5_dW = sure5[3],
    gam0_10_dP4 = (p0[1] + p10[1]) / 2, gam0_10_dPC = (p0[2] + p10[2]) / 2, gam0_10_dW = (p0[3] + p10[3]) / 2,
    sure3_dP4 = sure3[1], gamm4_10_dP4 = (pm4[1] + p10[1]) / 2, gamm4_10_dPC = (pm4[2] + p10[2]) / 2,
    wkcoin_dP4 = wk[1], wkcoin_dW = wk[3],
    setNames(sdv, paste0("sd", c(23, 25, 27, 30), "_dP4")),
    setNames(tv, paste0("tauus", c(3, 6, 10), "_dP4")),
    setNames(tv6, paste0("tau6_tauus", c(3, 6, 10), "_dP4")))
})
print(r, digits = 3)
# mean-equivalent of the sd effects: fine exchange curve, seed 1..10 mean
xs <- c(0.25, 0.5, 1, 1.5, 2, 3, 4)
ex <- sapply(xs, function(v) mean(sapply(S10, function(sd) P4(sim2(addw(M0, v), seed = sd)) - P4(sim2(M0, seed = sd)))))
cat("\nexchange curve (10 seeds):\n"); print(round(data.frame(pts = xs, dP4 = ex), 4))
mq <- function(dp) approx(c(0, ex), c(0, xs), xout = dp)$y
m <- setNames(r$mean, r$stat)
cat("\nmean-equivalent (pts/wk) of a weekly-sd increase on our team score:\n")
for (v in c(23, 25, 27, 30)) cat(sprintf("  sd 21.1 -> %d: dP4 %+.4f = %.2f pts/wk of mean  (%.3f pts per +1 sd)\n",
  v, m[paste0("sd", v, "_dP4")], mq(m[paste0("sd", v, "_dP4")]), mq(m[paste0("sd", v, "_dP4")]) / (v - SIG)))
cat(sprintf("certainty equivalent of persistent 50/50 {0,+10}: %.2f pts/wk (mean 5)\n",
  approx(c(0, ex, m["sure5_dP4"]), c(0, xs, 5), xout = m["gam0_10_dP4"])$y))
saveRDS(list(r = r, ex = ex, xs = xs), file.path(OUT, "02_variance.rds"))
