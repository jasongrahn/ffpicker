# p3_decision shared code. Source AFTER sim_helpers.R, from repo root.
# sim2() = simulate_cond() with the SAME main rnorm stream (CRN vs the helper) plus:
#   - playoffs wks 16-17 (1v4, 2v3 -> final) when Mpo (10 x 2 strength, wks 16-17) given
#   - sd_us: our weekly sd (others stay SIG)
#   - add_us: n x length(WEEKS) matrix added to OUR weekly score (gambles), any stream
#   - tau_us: persistent N(0, tau_us) offset on OUR strength only (separate stream, seed_x)
# Extra randomness is drawn from separate seeds BEFORE set.seed(seed) -> regular-season
# draws identical to simulate_cond() for the same seed.
SCR <- "docs/review/002-evidence"
OUT <- file.path(SCR, "p3_decision")
eval(local({ L <- readLines("dev/weekly/trade_finder.R"); L <- L[grep("^CAP <- ", L):(grep("^mine <- ", L) - 1)]; parse(text = L[!grepl("^(M0|p0) <- ", L)]) }))   # CAP, settle, apply_trade, lab; range by pattern (lines shift)   # CAP, settle, apply_trade, lab
MEi <- match(ME, teams)

po_strength <- function(Rx) {           # wks 16-17 projection-optimal strength, no byes
  old <- WEEKS; WEEKS <<- 16:17; on.exit(WEEKS <<- old)
  strength_matrix(Rx)
}

sim2 <- function(M, Mpo = NULL, tau = 0, n = N, seed = SEED, fixed = WK8_FIXED, sd_us = SIG,
                 add_us = NULL, tau_us = 0, seed_x = seed + 7777L) {
  stopifnot(identical(rownames(M), teams), is.null(Mpo) || identical(rownames(Mpo), teams))
  off_us <- if (tau_us > 0) { set.seed(seed_x); rnorm(n, 0, tau_us) } else 0
  set.seed(seed)
  mu <- M + GAPS
  sd_t <- rep(SIG, 10); sd_t[MEi] <- sd_us
  W <- matrix(W0, n, 10, byrow = TRUE); PF <- matrix(PF0, n, 10, byrow = TRUE)
  d <- matrix(rnorm(n * 10, 0, tau), n, 10)
  d[, MEi] <- d[, MEi] + off_us
  win <- matrix(NA, n, nrow(G))
  for (k in seq_along(WEEKS)) {
    Z <- matrix(rnorm(n * 10, 0, 1), n, 10)
    S <- matrix(mu[, k], n, 10, byrow = TRUE) + d + sweep(Z, 2, sd_t, `*`)
    if (!is.null(add_us)) S[, MEi] <- S[, MEi] + add_us[, k]
    if (WEEKS[k] == CUR) for (t in names(fixed)) S[, match(t, teams)] <- fixed[[t]]
    PF <- PF + S
    for (j in which(G$week == WEEKS[k])) {
      aw <- S[, G$ia[j]] > S[, G$ib[j]]; win[, j] <- aw
      W[, G$ia[j]] <- W[, G$ia[j]] + aw; W[, G$ib[j]] <- W[, G$ib[j]] + !aw
    }
  }
  rk <- t(apply(W * 1e4 + PF / 1e3, 1, function(x) rank(-x, ties.method = "first")))
  colnames(rk) <- colnames(W) <- teams
  out <- list(top4 = rk <= 4, W = W, win = win, rank = rk)
  if (!is.null(Mpo)) {
    mup <- Mpo + GAPS
    S16 <- matrix(mup[, 1], n, 10, byrow = TRUE) + d + sweep(matrix(rnorm(n * 10), n, 10), 2, sd_t, `*`)
    S17 <- matrix(mup[, 2], n, 10, byrow = TRUE) + d + sweep(matrix(rnorm(n * 10), n, 10), 2, sd_t, `*`)
    ord <- t(apply(rk, 1, order))[, 1:4]                    # team index at seed 1..4
    i <- seq_len(n)
    wA <- ifelse(S16[cbind(i, ord[, 1])] > S16[cbind(i, ord[, 4])], ord[, 1], ord[, 4])
    wB <- ifelse(S16[cbind(i, ord[, 2])] > S16[cbind(i, ord[, 3])], ord[, 2], ord[, 3])
    ch <- ifelse(S17[cbind(i, wA)] > S17[cbind(i, wB)], wA, wB)
    out$champ <- ch; out$final <- cbind(wA, wB); out$seed_us <- rk[, MEi]
  }
  out
}
P4 <- function(s) mean(s$top4[, MEi])
PC <- function(s) mean(s$champ == MEi)
EW <- function(s) mean(s$W[, MEi])
SEEDS <- SEED + 0:4
# multi-seed delta: f(seed) returns a named numeric vector; summarise mean + sd over seeds
ms <- function(f, seeds = SEEDS) {
  x <- do.call(rbind, lapply(seeds, f))
  data.frame(stat = colnames(x), mean = colMeans(x), sd_seed = apply(x, 2, sd),
             se = apply(x, 2, sd) / sqrt(nrow(x)), row.names = NULL)
}
addw <- function(M, x, wk = WEEKS[-1], who = ME) { M[who, as.character(wk)] <- M[who, as.character(wk)] + x; M }
tradeM <- function(Rx, trades) {        # trades: list of list(team, give, get); wk8 column kept (played)
  dr <- character(0)
  for (t in trades) { x <- apply_trade(Rx, t$team, t$give, t$get); Rx <- x$R; dr <- c(dr, x$drop_us, x$drop_them) }
  M <- strength_matrix(Rx); M[, "8"] <- M0[, "8"]
  list(R = Rx, M = M, Mpo = po_strength(Rx), dropped = dr)
}
TR1 <- list(team = "Monday Night Madison", give = c("Kyler Murray", "T.J. Hockenson"), get = "Josh Jacobs")
TR2 <- list(team = "Max’s TD Bombers", give = c("Patrick Mahomes", "Carnell Tate"),
            get = c("Luther Burden III", "Isaiah Likely"))
