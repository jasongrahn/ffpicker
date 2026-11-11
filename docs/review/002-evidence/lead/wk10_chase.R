# Steel City Chase variants (2026-11-10): user asks Chase instead of G. Wilson; Loveland CHI bye wk10.
source("docs/review/002-evidence/a3_trades/common.R")
pv <- readRDS(file.path(A3, "perceived.rds")); pv$pval <- ifelse(pv$g > 0, 0.5 * pv$ppg + 0.5 * pv$last3, 0)
SK <- "Sunday Kevin"; SC <- "Steel City"
T <- list(KN = list(SK, c("Javonte Williams", "Tre Tucker"), c("Chris Olave", "Malik Nabers")),
  S1 = list(SC, c("A.J. Brown", "T.J. Hockenson"), c("Garrett Wilson", "Colston Loveland")),
  C1 = list(SC, c("A.J. Brown", "T.J. Hockenson"), c("Ja'Marr Chase", "Colston Loveland")),
  C2 = list(SC, c("A.J. Brown", "T.J. Hockenson"), "Ja'Marr Chase"),
  C3 = list(SC, "A.J. Brown", "Ja'Marr Chase"),
  C4 = list(SC, c("A.J. Brown", "Rome Odunze"), "Ja'Marr Chase"),
  C5 = list(SC, c("A.J. Brown", "Rome Odunze", "T.J. Hockenson"), c("Ja'Marr Chase", "Colston Loveland")))
print(as.data.frame(R[R$owner == SC | R$player %in% unlist(lapply(T, `[[`, 2)), c("player", "owner", "pos", "nfl", "injury", "base")]), row.names = FALSE)
pl <- unique(c(unlist(lapply(T, `[[`, 2)), unlist(lapply(T, `[[`, 3)), "Brenton Strange"))
cat("\nbyes wks 10-15 (no game):\n"); for (p in pl) { n <- R$nfl[R$player == p][1]; cat(sprintf("  %-20s %s %s\n", p, n, paste(Filter(function(w) !(n %in% ON[[w]]), as.character(10:15)), collapse = ","))) }
Mb <- M_of(R); Rp <- R; i <- match(Rp$player, pv$player); Rp$base[!is.na(i)] <- pv$pval[i[!is.na(i)]]; Mp <- strength_matrix(Rp)
subs <- list("S1", "C1", "C2", "C3", "C4", "C5", c("KN", "S1"), c("KN", "C1"), c("KN", "C2"))
mk <- function(Rx, Rpx, ks) { for (k in ks) { t <- T[[k]]; Rx <- apply_trade(Rx, t[[1]], t[[2]], t[[3]])$R; Rpx <- apply_trade(Rpx, t[[1]], t[[2]], t[[3]])$R }; list(R = Rx, Rp = Rpx) }
X <- lapply(subs, function(ks) mk(R, Rp, ks)); names(X) <- sapply(subs, paste, collapse = "+")
SEEDS5 <- SEED + 0:4
res <- mclapply(SEEDS5, function(sd) { b <- sim_fast(Mb, seed = sd)$p[[ME]]; sapply(X, function(x) sim_fast(M_of(x$R), seed = sd)$p[[ME]] - b) }, mc.cores = 4)
D <- do.call(cbind, res)
options(width = 200)
print(data.frame(subset = names(X), us_pts = round(sapply(X, function(x) fut(M_of(x$R)[ME, ]) - fut(Mb[ME, ])), 2),
  dP_pp = round(100 * rowMeans(D), 2), se = round(100 * apply(D, 1, sd) / sqrt(5), 2),
  SC_ppg = round(sapply(X, function(x) fut(team_strength(x$Rp[x$Rp$owner == SC, ])) - fut(Mp[SC, ])), 2),
  SC_paper = round(sapply(X, function(x) fut(M_of(x$R)[SC, ]) - fut(Mb[SC, ])), 2)), row.names = FALSE)
