# Named singles + packages, both worlds, 10 seeds x N 20000, CRN. Partner paper + ppg-world deltas per trade.
source("docs/review/002-evidence/a3_trades/common.R")
pv <- readRDS(file.path(A3, "perceived.rds")); pv$pval <- ifelse(pv$g > 0, 0.5 * pv$ppg + 0.5 * pv$last3, 0)
OWL <- "Owl Out Blitz"; SK <- "Sunday Kevin"
T <- list(TR1 = list(MAD, c("Kyler Murray", "T.J. Hockenson"), "Josh Jacobs"),
  TR2 = list(MAX, c("Patrick Mahomes", "Carnell Tate"), c("Luther Burden III", "Isaiah Likely")),
  D1 = list(DAVE, "T.J. Hockenson", "Jalen Coker"),
  D2 = list(DAVE, c("Patrick Mahomes", "T.J. Hockenson"), c("Jalen Coker", "Josh Downs")),
  X1 = list(MAX, c("Patrick Mahomes", "Tre Tucker", "Brenton Strange"), c("Luther Burden III", "Tucker Kraft")),
  X2 = list(MAX, c("Patrick Mahomes", "Tre Tucker", "Brenton Strange"), c("Luther Burden III", "Isaiah Likely")),
  X3 = list(MAX, c("Kyler Murray", "Tre Tucker", "Brenton Strange"), c("Luther Burden III", "Tucker Kraft")),
  O1 = list(OWL, c("Matthew Stafford", "Tre Tucker", "Brenton Strange"), c("Matthew Golden", "George Kittle")))
P <- list(TR1 = "TR1", TR2 = "TR2", D1 = "D1", D2 = "D2", X1 = "X1", X2 = "X2", O1 = "O1",
  `TR1+TR2` = c("TR1", "TR2"), `TR1+X1` = c("TR1", "X1"), `D1+X1` = c("D1", "X1"), `D2+X3` = c("D2", "X3"), `D1+X1+O1x` = c("D1", "X1"),
  `D1+X2` = c("D1", "X2"), `D1+O1` = c("D1", "O1"), `TR1+X1+O1?` = c("TR1", "X1"))
P[["TR1+X1+O1?"]] <- NULL; P[["D1+X1+O1x"]] <- NULL
mk <- function(Rw, ks) { for (k in ks) { t <- T[[k]]; Rw <- apply_trade(Rw, t[[1]], t[[2]], t[[3]])$R }; Rw }
toppg <- function(Rx) { i <- match(Rx$player, pv$player); Rx$base[!is.na(i)] <- pv$pval[i[!is.na(i)]]; Rx }
out <- list()
for (wn in c("tateOut", "asSim")) {
  Rw <- if (wn == "asSim") R else within(R, base[player == "Carnell Tate"] <- 0); Mb <- M_of(Rw); Rp <- toppg(Rw); Mp <- strength_matrix(Rp)
  Ms <- lapply(P, function(ks) M_of(mk(Rw, ks)))
  res <- mclapply(SEEDS, function(sd) { b <- sim_fast(Mb, seed = sd); lapply(Ms, function(M) { s <- sim_fast(M, seed = sd); list(dp = s$p - b$p, dw = s$w - b$w) }) }, mc.cores = 4)
  for (nm in names(P)) { ks <- P[[nm]]; Rf <- mk(Rw, ks); Rpf <- mk(Rp, ks)
    dp <- sapply(res, function(r) r[[nm]]$dp[ME])
    pt <- paste(sapply(ks, function(k) { tm <- T[[k]][[1]]; sprintf("%s paper %+.2f ppg %+.2f dP %+.1f dW %+.2f", substr(tm, 1, 8),
      fut(Ms[[nm]][tm, ]) - fut(Mb[tm, ]), fut(team_strength(Rpf[Rpf$owner == tm, ])) - fut(Mp[tm, ]),
      100 * mean(sapply(res, function(r) r[[nm]]$dp[tm])), mean(sapply(res, function(r) r[[nm]]$dw[tm]))) }), collapse = " | ")
    out[[length(out) + 1]] <- data.frame(world = wn, pkg = nm, d_us = round(fut(Ms[[nm]][ME, ]) - fut(Mb[ME, ]), 2),
      P_us = round(100 * (mean(sapply(res, function(r) r[[nm]]$dp[ME])) + mean(sapply(SEEDS, function(sd) 0))), 2),
      dP = round(100 * mean(dp), 2), ci = sprintf("[%.2f,%.2f]", 100 * (mean(dp) - 1.96 * sd(dp) / sqrt(10)), 100 * (mean(dp) + 1.96 * sd(dp) / sqrt(10))),
      dW = round(mean(sapply(res, function(r) r[[nm]]$dw[ME])), 3), partners = pt) }
}
o <- do.call(rbind, out); o$P_us <- NULL; options(width = 300); print(o, row.names = FALSE, right = FALSE)
saveRDS(o, file.path(A3, "named.rds"))
