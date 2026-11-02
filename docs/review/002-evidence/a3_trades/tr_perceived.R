# TR1/TR2 in the ppg world (base := 0.5 season ppg + 0.5 last-3, same lineup logic) + partner exp-wins delta.
source("docs/review/002-evidence/a3_trades/common.R")
pv <- readRDS(file.path(A3, "perceived.rds")); pv$pval <- ifelse(pv$g > 0, 0.5 * pv$ppg + 0.5 * pv$last3, 0)
Rp <- R; i <- match(Rp$player, pv$player); Rp$base[!is.na(i)] <- pv$pval[i[!is.na(i)]]
Rt <- within(R, base[player == "Carnell Tate"] <- 0)
T <- list(TR1 = list(MAD, c("Kyler Murray", "T.J. Hockenson"), "Josh Jacobs"),
          TR2 = list(MAX, c("Patrick Mahomes", "Carnell Tate"), c("Luther Burden III", "Isaiah Likely")),
          MahLikely = list(MAX, "Patrick Mahomes", "Isaiah Likely"), TateBurden = list(MAX, "Carnell Tate", "Luther Burden III"))
Mp0 <- strength_matrix(Rp)
for (k in names(T)) { t <- T[[k]]; x <- apply_trade(Rp, t[[1]], t[[2]], t[[3]])
  cat(sprintf("%-10s ppg-world: us %+.2f  them %+.2f pts/wk | drops us[%s] them[%s]\n", k,
      fut(team_strength(x$R[x$R$owner == ME, ])) - fut(Mp0[ME, ]), fut(team_strength(x$R[x$R$owner == t[[1]], ])) - fut(Mp0[t[[1]], ]),
      paste(x$drop_us, collapse = ","), paste(x$drop_them, collapse = ","))) }
print(pv[pv$owner %in% c(MAD, MAX) & pv$pos %in% c("QB", "TE", "RB", "WR"), c("player", "owner", "pos", "injury_1031", "g", "ppg", "last3", "pick")], row.names = FALSE)
# partner expected-wins delta (10 seeds), both worlds
for (wn in c("asSim", "tateOut")) { Rw <- if (wn == "asSim") R else Rt; Mb <- M_of(Rw)
  for (k in c("TR1", "TR2", "MahLikely")) { t <- T[[k]]; M <- M_of(apply_trade(Rw, t[[1]], t[[2]], t[[3]])$R)
    r <- mclapply(SEEDS, function(sd) { a <- sim_fast(Mb, seed = sd); b <- sim_fast(M, seed = sd); b$w - a$w }, mc.cores = 4)
    cat(sprintf("%s %-9s partner dW %+.3f\n", wn, k, mean(sapply(r, function(z) z[[t[[1]]]])))) } }
