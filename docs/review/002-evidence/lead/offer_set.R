# Lead: price a non-overlapping Tuesday offer set, every subset (any subset may be accepted).
# Tate-out world (pre-registered bound), A3's corrected settle() (sole QB/K/DEF protected).
source("docs/review/002-evidence/a3_trades/common.R")
LEAD <- "docs/review/002-evidence/lead"
pv <- readRDS(file.path(A3, "perceived.rds")); pv$pval <- ifelse(pv$g > 0, 0.5 * pv$ppg + 0.5 * pv$last3, 0)
SK <- "Sunday Kevin"; MICH <- "Locked In Michelle"; OWL <- "Owl Out Blitz"
T <- list(
  X1 = list(MAX, c("Patrick Mahomes", "Tre Tucker", "Brenton Strange"), c("Luther Burden III", "Tucker Kraft")),
  D1 = list(DAVE, "T.J. Hockenson", "Jalen Coker"),
  S1 = list(SK, "Javonte Williams", c("Chris Olave", "Travis Kelce")),
  M1 = list(MICH, "Ollie Gordon II", c("Aaron Jones Sr.", "Cam Skattebo")),
  O3 = list(OWL, "Matthew Stafford", c("Matthew Golden", "George Kittle")))
Rw <- within(R, base[player == "Carnell Tate"] <- 0)
Mb <- M_of(Rw); Rp <- R; i <- match(Rp$player, pv$player); Rp$base[!is.na(i)] <- pv$pval[i[!is.na(i)]]; Mp <- strength_matrix(Rp)
mk <- function(Rx, ks) { dr <- character(0); for (k in ks) { t <- T[[k]]; a <- apply_trade(Rx, t[[1]], t[[2]], t[[3]]); Rx <- a$R; dr <- c(dr, a$drop_us) }; list(R = Rx, drop = dr) }
subs <- unlist(lapply(1:length(T), function(m) combn(names(T), m, simplify = FALSE)), recursive = FALSE)
# A chain fails when an earlier trade's auto-drop (settle) cut a player a later trade gives (BASE=latest,
# 11-03: S1 drops Stafford -> S1+O3). Real offers designate drops -> skip that subset, say so.
Ms <- lapply(subs, function(ks) tryCatch(M_of(mk(Rw, ks)$R), error = function(e) NULL)); names(Ms) <- sapply(subs, paste, collapse = "+")
if (any(bad <- sapply(Ms, is.null))) cat(sprintf("skipped %d subset(s), auto-drop conflict: %s\n", sum(bad), paste(names(Ms)[bad], collapse = " ")))
subs <- subs[!bad]; Ms <- Ms[!bad]
SEEDS5 <- SEED + 0:4
res <- mclapply(SEEDS5, function(sd) { b <- sim_fast(Mb, seed = sd); sapply(Ms, function(M) sim_fast(M, seed = sd)$p[[ME]] - b$p[[ME]]) }, mc.cores = 4)
dP <- rowMeans(do.call(cbind, res)); se <- apply(do.call(cbind, res), 1, sd) / sqrt(length(SEEDS5))
base_p <- mean(sapply(SEEDS5, function(sd) sim_fast(Mb, seed = sd)$p[ME]))
cat(sprintf("Tate-out baseline P(top 4) %.2f%% (5 seeds)\n", 100 * base_p))
single <- do.call(rbind, lapply(names(T), function(k) { t <- T[[k]]; x <- mk(Rw, k); tm <- t[[1]]
  xp <- apply_trade(Rp, tm, t[[2]], t[[3]])$R
  data.frame(offer = k, partner = substr(tm, 1, 14), give = paste(t[[2]], collapse = " + "), get = paste(t[[3]], collapse = " + "),
    our_drop = paste(x$drop, collapse = ","), us_pts = round(fut(Ms[[k]][ME, ]) - fut(Mb[ME, ]), 2),
    them_paper = round(fut(Ms[[k]][tm, ]) - fut(Mb[tm, ]), 2),
    them_ppg = round(fut(team_strength(xp[xp$owner == tm, ])) - fut(Mp[tm, ]), 2),
    dP_pp = round(100 * dP[k], 2), se = round(100 * se[k], 2)) }))
options(width = 250); print(single, row.names = FALSE)
tab <- data.frame(subset = names(Ms), us_pts = round(sapply(Ms, function(M) fut(M[ME, ]) - fut(Mb[ME, ])), 2),
                  dP_pp = round(100 * dP, 2), P_pct = round(100 * (base_p + dP), 2))
tab <- tab[order(-tab$dP_pp), ]; print(head(tab, 32), row.names = FALSE)
# Expected value under illustrative, independent acceptance guesses (NOT data).
pa <- c(X1 = 0.5, D1 = 0.35, S1 = 0.1, M1 = 0.3, O3 = 0.1)
ev <- sum(sapply(seq_along(subs), function(j) { ks <- subs[[j]]; prod(pa[ks]) * prod(1 - pa[setdiff(names(T), ks)]) * dP[j] }))
cat(sprintf("\nEV dP with guesses %s: %+.2fpp (P(none accepted) %.2f)\n", paste(names(pa), pa, collapse = " "), 100 * ev, prod(1 - pa)))
saveRDS(list(single = single, tab = tab, base_p = base_p), file.path(LEAD, "offer_set.rds"))
