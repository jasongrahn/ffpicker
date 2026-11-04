# Wk9 WR scan (2026-11-04 Wed): wk9_search.R restricted. Get side holds >= 1 WR (WR = -9.3/wk v league median,
# biggest slot gap). Partners = no pending offer (Dave D1, Kevin K2, Jazzy J1 out). Give side excludes
# pending-offer players (Hockenson, Tucker, Strange, Odunze), Kyler (Brown claim drop, clears 11-7), Tate (O).
# Roster = 11-04 export + F2 (Price for Washington Jr.).
# Expanded trade search: shapes 1-1, 2-1, 1-2, 2-2, 3-2 (give-get) x all 9 partners, any of our
# QB/RB/WR/TE. Fast pre-screen of fut pts/wk (wks 9-15) both sides, identical lineup logic to
# team_strength(); settle() replicated (drop = min-cost body, incoming protected). Two worlds:
# asSim (Tate healthy wks 10-15) and tateOut (Tate base 0). Output: screen table -> search_screen.rds.
source("docs/review/002-evidence/a3_trades/common.R")
STROUD <- "C.J. Stroud"
PENDING_GIVE <- c("T.J. Hockenson", "Tre Tucker", "Brenton Strange", "Rome Odunze", "Kyler Murray", "Carnell Tate", "Davante Adams")
FW <- as.character(CUR + 1:(15 - CUR))   # wk9 run: trades land wk10 -> wks 10-15 = fut()
NK <- length(FW)

FQ <- FILL[["QB"]]; FR <- FILL[["RB"]]; FWR <- FILL[["WR"]]; FT <- FILL[["TE"]]; FK <- FILL[["K"]]; FD <- FILL[["DEF"]]; FF <- FILL[["FLEX"]]
opt1f <- function(pos, v) {
  o <- order(-v); pos <- pos[o]; v <- v[o]
  q <- v[pos == "QB"]; r <- v[pos == "RB"]; w <- v[pos == "WR"]; t <- v[pos == "TE"]; k <- v[pos == "K"]; d <- v[pos == "DEF"]
  nr <- length(r); nw <- length(w); nt <- length(t)
  fl <- c(if (nr > 2) r[3], if (nw > 2) w[3], if (nt > 1) t[2])
  (if (length(q)) q[1] else FQ) + (if (nr > 0) r[1] else FR) + (if (nr > 1) r[2] else FR) +
    (if (nw > 0) w[1] else FWR) + (if (nw > 1) w[2] else FWR) + (if (nt > 0) t[1] else FT) +
    (if (length(k)) k[1] else FK) + (if (length(d)) d[1] else FD) + (if (length(fl)) max(fl) else FF)
}

screen_world <- function(Rw, world) {
  A <- active(Rw); A <- rbind(A, transform(as.data.frame(P[P$player == STROUD, names(A)]), owner = "FA"))
  A <- A[!duplicated(A$player), ]
  ONM <- onm(A$nfl) & A$base > 0
  futi <- function(idx) { s <- 0; for (k in 1:NK) { m <- ONM[idx, k]; s <- s + opt1f(A$pos[idx][m], A$base[idx][m]) }; s / NK }
  pv <- readRDS(file.path(A3, "perceived.rds")); j <- match(A$player, pv$player)
  PV <- ifelse(is.na(j), A$base, ifelse(pv$g[j] > 0, 0.5 * pv$ppg[j] + 0.5 * pv$last3[j], 0))   # K/DEF keep base
  ONP <- onm(A$nfl) & PV > 0
  futp <- function(idx) { s <- 0; for (k in 1:NK) { m <- ONP[idx, k]; s <- s + opt1f(A$pos[idx][m], PV[idx][m]) }; s / NK }
  # settle: drop the body whose loss costs least (ties -> first in row order, as settle()), incoming protected
  settlei <- function(idx, keep) {
    dropped <- character(0)
    while (length(idx) > CAP) {
      np <- table(A$pos[idx]); sole <- idx[A$pos[idx] %in% c("QB", "K", "DEF") & np[A$pos[idx]] == 1]
      cand <- idx[!A$player[idx] %in% keep & !idx %in% sole]
      left <- vapply(cand, function(p) futi(setdiff(idx, p)), 0)
      d <- cand[which.max(left)]; dropped <- c(dropped, A$player[d]); idx <- setdiff(idx, d)
    }
    list(idx = idx, dropped = dropped)
  }
  me <- which(A$owner == ME); b_us <- futi(me); bp_us <- futp(me)
  stopifnot(abs(b_us - fut(M_of(Rw)[ME, ])) < 1e-9)
  gv <- me[A$pos[me] %in% c("QB", "RB", "WR", "TE") & !A$player[me] %in% PENDING_GIVE]
  st <- which(A$player == STROUD)
  gsets <- list(`1` = as.list(gv), `2` = combn(gv, 2, simplify = FALSE), `3` = combn(gv, 3, simplify = FALSE))
  out <- mclapply(setdiff(teams, c(ME, DAVE, "Sunday Kevin", "Jason's Jazzy Team")), function(tm) {
    th <- which(A$owner == tm); b_th <- futi(th); bp_th <- futp(th)
    gt <- th[A$pos[th] %in% c("QB", "RB", "WR", "TE") & A$base[th] > 0]
    qsets <- list(`1` = as.list(gt), `2` = combn(gt, 2, simplify = FALSE))
    shapes <- list(c(1, 1), c(2, 1), c(1, 2), c(2, 2), c(3, 2))
    rows <- list()
    for (sh in shapes) for (g in gsets[[as.character(sh[1])]]) for (q in qsets[[as.character(sh[2])]]) { if (!any(A$pos[q] == "WR")) next
      us <- c(setdiff(me, g), q); noqb <- !any(A$pos[us] == "QB")
      if (noqb) us <- c(us, st)                           # no QB left -> claim Stroud (FA 18.3), takes a spot
      su <- settlei(us, A$player[c(q, if (noqb) st)])
      tt <- settlei(c(setdiff(th, q), g), A$player[g])
      rows[[length(rows) + 1]] <- data.frame(world = world, team = tm, shape = paste0(sh[1], "-", sh[2]),
        give = paste(A$player[g], collapse = " + "), get = paste(A$player[q], collapse = " + "),
        n_us = length(su$idx), noQB = noqb,
        drop_us = paste(su$dropped, collapse = ","), drop_them = paste(tt$dropped, collapse = ","),
        d_us = futi(su$idx) - b_us, d_them = futi(tt$idx) - b_th,
        ppg_us = futp(su$idx) - bp_us, ppg_them = futp(tt$idx) - bp_th)   # same drops as base world
    }
    do.call(rbind, rows)
  }, mc.cores = 4)
  do.call(rbind, out)
}
t0 <- Sys.time()
W_as <- R; W_to <- within(R, base[player == "Carnell Tate"] <- 0)
scr <- screen_world(W_to, "tateOut")
cat(nrow(scr), "trades screened in", round(as.numeric(difftime(Sys.time(), t0, units = "secs"))), "s\n")
saveRDS(scr, sprintf("data/weekly/2026_week09_wr_screen_%s.rds", BASE))
