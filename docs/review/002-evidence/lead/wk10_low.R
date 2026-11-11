# Wk10 low-partner add-ons (2026-11-10): KN + Steel City TE/WR deals (disjoint gives). Steel City P(top 4) ~0 -> arming costs 0.
# Real offers designate drops; here settle() picks (min-cost body).
source("docs/review/002-evidence/a3_trades/common.R")
SK <- "Sunday Kevin"; JAZ <- "Jason's Jazzy Team"; MIT <- "Maybe Mitchell"
T <- list(KN = list(SK, c("Javonte Williams", "Tre Tucker"), c("Chris Olave", "Malik Nabers")),
          S1 = list("Steel City", c("A.J. Brown", "T.J. Hockenson"), c("Garrett Wilson", "Colston Loveland")),
          S2 = list("Steel City", "T.J. Hockenson", c("Chris Godwin Jr.", "Colston Loveland")))
mk <- function(Rx, ks) { dr <- character(0); for (k in ks) { t <- T[[k]]; a <- apply_trade(Rx, t[[1]], t[[2]], t[[3]]); Rx <- a$R; dr <- c(dr, a$drop_us) }; list(R = Rx, drop = dr) }
subs <- list("KN", "S1", "S2", c("KN", "S1"), c("KN", "S2"))
X <- lapply(subs, function(ks) tryCatch(mk(R, ks), error = function(e) NULL)); names(X) <- sapply(subs, paste, collapse = "+")
stopifnot(!any(sapply(X, is.null)))
Mb <- M_of(R); SEEDS5 <- SEED + 0:4
res <- mclapply(SEEDS5, function(sd) { b <- sim_fast(Mb, seed = sd)$p[[ME]]; sapply(X, function(x) sim_fast(M_of(x$R), seed = sd)$p[[ME]] - b) }, mc.cores = 4)
D <- do.call(cbind, res)
print(data.frame(subset = names(X), our_drops = sapply(X, function(x) paste(x$drop, collapse = ",")),
  us_pts = round(sapply(X, function(x) fut(M_of(x$R)[ME, ]) - fut(Mb[ME, ])), 2),
  dP_pp = round(100 * rowMeans(D), 2), se = round(100 * apply(D, 1, sd) / sqrt(5), 2)), row.names = FALSE)
