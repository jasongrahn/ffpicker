# A3 trades -- shared setup. Run from repo root. Sources the team helper (CUR 8, wk8 fixed),
# trade_finder.R machinery lines 18 + 23:40 (CAP, settle, apply_trade, lab) WITHOUT running its scan.
setwd("/Users/jasongrahn/R-projects/ffootballer")
A3 <- "docs/review/002-evidence/a3_trades"
source("docs/review/002-evidence/sim_helpers.R")
eval(local({ L <- readLines("dev/weekly/trade_finder.R"); L <- L[grep("^CAP <- ", L):(grep("^mine <- ", L) - 1)]; parse(text = L[!grepl("^(M0|p0) <- ", L)]) }))   # CAP, settle, apply_trade, lab; range by pattern (lines shift)
suppressMessages(library(parallel))
R <- as.data.frame(R)
MAD <- "Monday Night Madison"; MAX <- "Max’s TD Bombers"; DAVE <- "Dave’s Bone Crushers"
stopifnot(MAX %in% teams, DAVE %in% teams, MAD %in% teams)

# Trade lands wk9 at the earliest -> wk8 column is history-in-progress: keep it at M0 for EVERY team
# (strength_matrix() would otherwise re-price the partner's wk8 game with the post-trade roster).
M_of <- function(Rx, M_base = M0) { M <- strength_matrix(Rx); if (CUR == 8) M[, "8"] <- M_base[, "8"]; M }   # CUR 9+: accepted by Thu -> counts that week, pin nothing

# simulate_cond() with vectorised ranking (identical result; rank(-x, ties 'first') = 1 + #greater
# + #equal-with-lower-index). Same RNG stream -> common random numbers across calls with one seed.
sim_fast <- function(M, tau = 0, n = N, seed = SEED, fixed = WK8_FIXED, sig = SIG) {
  stopifnot(identical(rownames(M), teams))
  set.seed(seed)
  mu <- M + GAPS
  W <- matrix(W0, n, 10, byrow = TRUE); PF <- matrix(PF0, n, 10, byrow = TRUE)
  d <- matrix(rnorm(n * 10, 0, tau), n, 10)
  for (k in seq_along(WEEKS)) {
    Z <- matrix(rnorm(n * 10, 0, 1), n, 10)
    S <- matrix(mu[, k], n, 10, byrow = TRUE) + d + Z * sig
    if (WEEKS[k] == CUR) for (t in names(fixed)) S[, match(t, teams)] <- fixed[[t]]
    PF <- PF + S
    for (j in which(G$week == WEEKS[k])) {
      aw <- S[, G$ia[j]] > S[, G$ib[j]]
      W[, G$ia[j]] <- W[, G$ia[j]] + aw; W[, G$ib[j]] <- W[, G$ib[j]] + !aw
    }
  }
  sc <- W * 1e4 + PF / 1e3
  rk <- matrix(1L, n, 10)
  for (j in 1:10) for (k in 1:10) if (k != j) rk[, j] <- rk[, j] + (sc[, k] > sc[, j] | (sc[, k] == sc[, j] & k < j))
  colnames(rk) <- colnames(W) <- teams
  list(p = colMeans(rk <= 4), w = colMeans(W))
}
SEEDS <- SEED + 0:9

# ---- fast fut() strength for the pre-screen: identical lineup logic to team_strength() wks 9-15 ----
FW <- as.character(9:15)
onm <- function(nflv) sapply(FW, function(w) nflv %in% ON[[w]])
opt1 <- function(pos, v) {   # one week, present players only; = opt_total(pos, v, FILL)
  top <- function(x, n, p) { got <- x[seq_len(min(n, length(x)))]
    if (length(got) < n) got <- c(got, rep(FILL[[p]], n - length(got))); sum(got) }
  s <- function(p) sort(v[pos == p], decreasing = TRUE)
  rb <- s("RB"); wr <- s("WR"); te <- s("TE")
  top(s("QB"), 1, "QB") + top(rb, 2, "RB") + top(wr, 2, "WR") + top(te, 1, "TE") + top(s("K"), 1, "K") +
    top(s("DEF"), 1, "DEF") + top(sort(c(rb[-(1:2)], wr[-(1:2)], te[-1]), decreasing = TRUE), 1, "FLEX")
}
# d: data.frame with pos, base, nfl (active players only)
fut_fast <- function(pos, base, nflv) {
  on <- onm(nflv) & base > 0
  if (!is.matrix(on)) on <- matrix(on, nrow = length(pos))
  mean(vapply(seq_along(FW), function(k) opt1(pos[on[, k]], base[on[, k]]), 0))
}
fut_df <- function(d) { d <- active(d); fut_fast(d$pos, d$base, d$nfl) }

# settle() override: trade_finder.R's version can drop a team's ONLY QB/K/DEF -- FILL then supplies a
# wire body for free without a roster spot (Madison dropped Titans DEF 5.1 -> Browns FILL 6.62 = a
# fake +1.5/wk "gain" in TR1). Sole QB/K/DEF are protected; everything else as in trade_finder.R.
settle <- function(r, keep) {
  dropped <- character(0)
  while (nrow(active(r)) > CAP) {
    a <- active(r); np <- table(a$pos)
    sole <- a$player[a$pos %in% c("QB", "K", "DEF") & np[a$pos] == 1]
    c <- setdiff(a$player, c(keep, sole))
    left <- vapply(c, function(p) fut(team_strength(r[r$player != p, ])), numeric(1))
    d <- c[which.max(left)]; dropped <- c(dropped, d); r <- r[r$player != d, ]
  }
  list(r = r, dropped = dropped)
}
