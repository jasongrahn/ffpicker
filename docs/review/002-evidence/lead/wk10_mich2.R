# Michelle after Gibbs decline (2026-11-12): JW -> Gibbs fallback v fair JW + Odunze -> Kyren Williams + Rashee Rice.
source("docs/review/002-evidence/a3_trades/common.R")
pv <- readRDS(file.path(A3, "perceived.rds")); pv$pval <- ifelse(pv$g > 0, 0.5 * pv$ppg + 0.5 * pv$last3, 0)
MI <- "Locked In Michelle"; SC <- "Steel City"
T <- list(CH = list(SC, c("A.J. Brown", "T.J. Hockenson"), c("Ja'Marr Chase", "Colston Loveland")),
  GW = list(MI, "Javonte Williams", "Jahmyr Gibbs"),
  KR = list(MI, c("Javonte Williams", "Rome Odunze"), c("Kyren Williams", "Rashee Rice")))
for (p in c("Kyren Williams", "Rashee Rice")) { n <- R$nfl[R$player == p][1]; cat(p, n, "bye:", Filter(function(w) !(n %in% ON[[w]]), as.character(10:15)), "\n") }
Mb <- M_of(R); Rp <- R; i <- match(Rp$player, pv$player); Rp$base[!is.na(i)] <- pv$pval[i[!is.na(i)]]; Mp <- strength_matrix(Rp)
subs <- c(as.list(names(T)[-1]), lapply(names(T)[-1], function(k) c("CH", k)), list("CH"))
mk <- function(ks) { Rx <- R; Rpx <- Rp; for (k in ks) { t <- T[[k]]; Rx <- apply_trade(Rx, t[[1]], t[[2]], t[[3]])$R; Rpx <- apply_trade(Rpx, t[[1]], t[[2]], t[[3]])$R }; list(R = Rx, Rp = Rpx) }
X <- lapply(subs, mk); names(X) <- sapply(subs, paste, collapse = "+")
res <- mclapply(SEED + 0:4, function(sd) { b <- unlist(sim_fast(Mb, seed = sd)$p); sapply(X, function(x) { p <- unlist(sim_fast(M_of(x$R), seed = sd)$p); c(us = p[[ME]] - b[[ME]], mi = p[[MI]] - b[[MI]]) }) }, mc.cores = 4)
A <- Reduce(`+`, res) / 5
options(width = 200)
print(data.frame(subset = names(X), give = sapply(subs, function(ks) paste(unlist(lapply(T[ks], `[[`, 2)), collapse = " + ")),
  us_pts = round(sapply(X, function(x) fut(M_of(x$R)[ME, ]) - fut(Mb[ME, ])), 2), dP_us = round(100 * A["us", ], 2),
  dP_MI = round(100 * A["mi", ], 1),
  MI_ppg = round(sapply(X, function(x) fut(team_strength(x$Rp[x$Rp$owner == MI, ])) - fut(Mp[MI, ])), 2),
  MI_paper = round(sapply(X, function(x) fut(M_of(x$R)[MI, ]) - fut(Mb[MI, ])), 2)), row.names = FALSE)
