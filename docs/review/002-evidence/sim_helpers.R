# Shared helpers, 2026-11-02 season meta-analysis. RUN FROM REPO ROOT:
#   setwd("/Users/jasongrahn/R-projects/ffootballer"); source("<scratch>/meta/sim_helpers.R")
# Loads dev/weekly/league_sim.R (CUR = 8, 10-28 export, wks 8-15) and adds:
#   simulate_cond(): simulate() with week-8 scores we already know FIXED (us 87.50 = L).
#   pt4(): one-line summary for us.  exch(): exchange rate on top of any M.
# simulate_cond() draws the SAME rnorm stream as simulate() -> common random numbers:
# any two calls with the same seed differ only by the move under test.
suppressMessages(source("dev/weekly/league_sim.R"))

MICH <- "Locked In Michelle"
# Wk8: us 87.50 (nflreadr calc, dev/weekly/wk8_sunday.R; Yahoo confirms Tue). Michelle ~113-133
# (Love v Burrow unknown, SEA DEF on MNF) -> 120 = midpoint ESTIMATE, only moves their PF tiebreak.
# Other 4 wk8 games: unknown until Tue -> simulated.
WK8_FIXED <- if (CUR == 8) setNames(c(87.50, 120), c(ME, MICH)) else c()   # CUR 9+: wk8 is in the schedule csv -> fix nothing

simulate_cond <- function(M, tau = 0, n = N, seed = SEED, fixed = WK8_FIXED, sig = SIG, sig_team = NULL) {
  stopifnot(identical(rownames(M), teams))
  set.seed(seed)
  mu <- M + GAPS
  sd_t <- if (is.null(sig_team)) rep(sig, 10) else sig_team[teams]   # per-team weekly sd (variance tests)
  stopifnot(!anyNA(sd_t))   # unnamed sig_team -> NA scores -> P(top 4) silently 1.0 (P4)
  W <- matrix(W0, n, 10, byrow = TRUE); PF <- matrix(PF0, n, 10, byrow = TRUE)
  d <- matrix(rnorm(n * 10, 0, tau), n, 10)
  win <- matrix(NA, n, nrow(G))
  for (k in seq_along(WEEKS)) {
    Z <- matrix(rnorm(n * 10, 0, 1), n, 10)                    # same draws as simulate() when sd = SIG
    S <- matrix(mu[, k], n, 10, byrow = TRUE) + d + sweep(Z, 2, sd_t, `*`)
    if (WEEKS[k] == CUR) for (t in names(fixed)) S[, match(t, teams)] <- fixed[[t]]
    PF <- PF + S
    for (j in which(G$week == WEEKS[k])) {
      aw <- S[, G$ia[j]] > S[, G$ib[j]]; win[, j] <- aw
      W[, G$ia[j]] <- W[, G$ia[j]] + aw; W[, G$ib[j]] <- W[, G$ib[j]] + !aw
    }
  }
  rk <- t(apply(W * 1e4 + PF / 1e3, 1, function(x) rank(-x, ties.method = "first")))
  colnames(rk) <- colnames(W) <- teams
  list(top4 = rk <= 4, W = W, win = win, rank = rk)
}
pt4 <- function(s, who = ME) c(p_top4 = mean(s$top4[, who]), exp_wins = mean(s$W[, who]))
exch <- function(M, x = c(1, 3, 5, 10, 15), tau = 0) {
  b <- pt4(simulate_cond(M, tau = tau))
  do.call(rbind, lapply(x, function(v) { Mx <- M; Mx[ME, -1] <- Mx[ME, -1] + v
    a <- pt4(simulate_cond(Mx, tau = tau)); data.frame(pts_wk = v, p_top4 = a[1], dP = a[1] - b[1], dW = a[2] - b[2]) }))
}
M0 <- strength_matrix(R)
