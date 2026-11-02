# P4 patched strength engine (scratch copy; repo untouched). Source AFTER sim_helpers.R.
# strength2(R, ov, fillmode, nofill_teams): same as strength_matrix() when ov = NULL,
# fillmode = "orig", nofill_teams = NULL (verified byte-identical in 03_verify.R).
#   ov: tibble(player, week, val) -- overrides a player's value in a FUTURE week (IR return, injury zero).
#       IR rows are kept only where ov gives them a value.
#   fillmode: "orig" = FILL constant (league_sim.R); "byeaware" = best AVAIL at pos whose NFL team
#       plays that week; "rank" = byeaware + k-th team short at a pos in a week gets the k-th best body
#       (order = random per week, fixed seed) -> one wire player cannot fill two rosters.
#   nofill_teams: teams that never stream (empty slot stays 0).
SC <- "docs/review/002-evidence"
opt_total2 <- function(pos, v, fillv = NULL) {   # returns total + count of filled slots by pos
  s <- function(p) sort(v[pos == p], decreasing = TRUE)
  need <- c(QB = 0, RB = 0, WR = 0, TE = 0, K = 0, DEF = 0, FLEX = 0)
  top <- function(x, n, p) {
    got <- x[seq_len(min(n, length(x)))]
    k <- n - length(got)
    if (k > 0) { need[[p]] <<- k; if (!is.null(fillv)) got <- c(got, rep(fillv[[p]], k)) }
    sum(got)
  }
  rb <- s("RB"); wr <- s("WR"); te <- s("TE")
  tot <- top(s("QB"), 1, "QB") + top(rb, 2, "RB") + top(wr, 2, "WR") + top(te, 1, "TE") + top(s("K"), 1, "K") +
    top(s("DEF"), 1, "DEF") + top(sort(c(rb[-(1:2)], wr[-(1:2)], te[-1]), decreasing = TRUE), 1, "FLEX")
  list(tot = tot, need = need)
}
POSF <- c("QB", "RB", "WR", "TE", "K", "DEF")
wire_by_week <- function(avail = AVAIL) {   # per week: sorted values of available bodies per pos (playing that week)
  lapply(setNames(WEEKS, WEEKS), function(w) {
    a <- avail[avail$nfl %in% ON[[as.character(w)]], ]
    l <- lapply(setNames(POSF, POSF), function(p) sort(a$base[a$pos == p], decreasing = TRUE))
    l$FLEX <- sort(a$base[a$pos %in% c("RB", "WR", "TE")], decreasing = TRUE); l })
}
WIRE <- wire_by_week()
strength2 <- function(Rx, ov = NULL, fillmode = "orig", nofill_teams = NULL, seed = 1, wire = WIRE, detail = FALSE) {
  M <- matrix(NA_real_, length(teams), length(WEEKS), dimnames = list(teams, WEEKS))
  NEED <- list()
  for (t in teams) {
    d <- Rx[Rx$owner == t, ]
    isir <- !is.na(d$injury) & grepl("IR", d$injury)
    for (k in seq_along(WEEKS)) {
      w <- WEEKS[k]
      if (w == CUR) { M[t, k] <- opt_total(active(d)$pos, active(d)$proj); next }
      v <- ifelse(d$nfl %in% ON[[as.character(w)]] & d$base > 0, d$base, 0)
      keep <- !isir
      if (!is.null(ov)) {
        o <- ov[ov$week == w & ov$player %in% d$player, ]
        if (nrow(o)) { i <- match(o$player, d$player); v[i] <- ifelse(d$nfl[i] %in% ON[[as.character(w)]], o$val, 0); keep[i] <- TRUE }
      }
      on <- keep & v > 0
      r <- opt_total2(d$pos[on], v[on], NULL)
      NEED[[paste(t, w)]] <- r$need
      M[t, k] <- r$tot
    }
  }
  # fills
  FILLED <- matrix(0, length(teams), length(WEEKS), dimnames = list(teams, WEEKS))
  set.seed(seed)
  for (k in seq_along(WEEKS)) {
    w <- WEEKS[k]; if (w == CUR) next
    ord <- if (fillmode == "rank") sample(teams) else teams
    used <- c(QB = 0, RB = 0, WR = 0, TE = 0, K = 0, DEF = 0, FLEX = 0)
    for (t in ord) {
      if (t %in% nofill_teams) next
      nd <- NEED[[paste(t, w)]]
      for (p in names(nd)[nd > 0]) for (j in seq_len(nd[[p]])) {
        val <- switch(fillmode,
          orig = FILL[[p]],
          byeaware = wire[[as.character(w)]][[p]][1],
          rank = { used[[p]] <- used[[p]] + 1
                   # a FLEX body also consumes an RB/WR/TE body: approximate by offsetting FLEX rank by RB+WR+TE fills
                   pool <- wire[[as.character(w)]][[p]]
                   off <- if (p == "FLEX") used[["RB"]] + used[["WR"]] + used[["TE"]] else 0
                   pool[min(used[[p]] + off, length(pool))] })
        FILLED[t, k] <- FILLED[t, k] + val
      }
    }
  }
  M <- M + FILLED
  if (detail) return(list(M = M, FILLED = FILLED, NEED = NEED))
  M
}
# multi-seed P(top 4) for us and deltas vs a base M, common random numbers per seed
SEEDS <- c(20261021, 1, 2, 3, 4)
mp <- function(M, seeds = SEEDS, tau = 0, who = ME) sapply(seeds, function(s) { x <- simulate_cond(M, tau = tau, seed = s); c(p = mean(x$top4[, who]), w = mean(x$W[, who])) })
dmp <- function(M1, M0x, seeds = SEEDS, tau = 0) {
  a <- mp(M1, seeds, tau); b <- mp(M0x, seeds, tau); d <- a - b
  c(p0 = mean(b["p", ]), p1 = mean(a["p", ]), dP = mean(d["p", ]), dP_lo = min(d["p", ]), dP_hi = max(d["p", ]), dW = mean(d["w", ]))
}
