# 2- and 3-trade packages: different partners, disjoint gives, applied in sequence (real machinery).
# Candidates = shortlist singles from final_<WORLD>_full.rds with d_them >= -1 (paper) + TR1, TR2.
# Our side interacts across trades; each partner sees only its own trade. Pre-rank by d_us (fut),
# simulate top packages 10 seeds x N 20000. Stroud claimed only if we end with no QB.
source("docs/review/002-evidence/a3_trades/common.R")
STROUD <- "C.J. Stroud"; WORLD <- Sys.getenv("WORLD", "tateOut")
Rw <- if (WORLD == "tateOut") within(R, base[player == "Carnell Tate"] <- 0) else R
Mb <- M_of(Rw)
short <- readRDS(file.path(A3, sprintf("final_%s_full.rds", WORLD)))
sp <- function(s) strsplit(s, " \\+ ")[[1]]
stroud_row <- as.data.frame(P[P$player == STROUD, names(R)]); stroud_row$owner <- ME
build <- function(Rx, tm, give, get) {
  x <- apply_trade(Rx, tm, give, get); us <- x$R[x$R$owner == ME, ]
  if (!any(active(us)$pos == "QB")) { a <- settle(rbind(us, stroud_row), c(get, STROUD)); x$R <- rbind(x$R[x$R$owner != ME, ], a$r) }
  x
}
FILT <- Sys.getenv("FILT", "paper")   # paper: partner proj >= -1 | ppg: partner ppg-world >= -1 and proj >= -2
keep <- if (FILT == "ppg") short$ppg_them >= -1 & short$d_them >= -2 else short$d_them >= -1
cand <- short[keep & short$dP > 0, c("team", "give", "get", "d_us", "d_them", "ppg_them", "dP", "dP_them")]
add <- data.frame(team = c(MAD, MAX), give = c("Kyler Murray + T.J. Hockenson", "Patrick Mahomes + Carnell Tate"),
                  get = c("Josh Jacobs", "Luther Burden III + Isaiah Likely"), d_us = NA, d_them = NA, ppg_them = NA, dP = NA, dP_them = NA)
if (FILT == "paper") cand <- rbind(cand, add[!paste(add$team, add$give, add$get) %in% paste(cand$team, cand$give, cand$get), ])
cand <- cand[order(-cand$dP, na.last = FALSE), ]; cand <- head(cand, 30)
cat(WORLD, "package candidates:", nrow(cand), "\n")

seq_apply <- function(ids) { Rx <- Rw
  for (i in ids) { g <- sp(cand$give[i]); if (!all(g %in% Rx$player[Rx$owner == ME])) return(NULL)
    Rx <- build(Rx, cand$team[i], g, sp(cand$get[i]))$R }
  Rx }
ok <- function(ids) length(unique(cand$team[ids])) == length(ids) && !any(duplicated(unlist(lapply(cand$give[ids], sp))))
pairs <- Filter(ok, combn(nrow(cand), 2, simplify = FALSE))
trips <- Filter(ok, combn(min(nrow(cand), 20), 3, simplify = FALSE))
evalp <- function(ids) { Rx <- seq_apply(ids); if (is.null(Rx)) return(NULL)
  list(ids = ids, d_us = fut_df(Rx[Rx$owner == ME, ]) - fut(Mb[ME, ]), Rx = Rx) }
pp <- Filter(Negate(is.null), mclapply(pairs, evalp, mc.cores = 4))
tt <- Filter(Negate(is.null), mclapply(trips, evalp, mc.cores = 4))
cat("pairs", length(pp), "triples", length(tt), "\n")
top <- c(head(pp[order(-sapply(pp, `[[`, "d_us"))], 12), head(tt[order(-sapply(tt, `[[`, "d_us"))], 12))
res <- mclapply(SEEDS, function(sd) { b <- sim_fast(Mb, seed = sd)
  lapply(top, function(z) { s <- sim_fast(M_of(z$Rx), seed = sd); list(dp = s$p - b$p, dw = s$w[ME] - b$w[ME]) }) }, mc.cores = 4)
out <- do.call(rbind, lapply(seq_along(top), function(k) { z <- top[[k]]
  dp <- sapply(res, function(r) r[[k]]$dp[ME])
  data.frame(n = length(z$ids), trades = paste(sprintf("[%s: %s -> %s]", substr(cand$team[z$ids], 1, 10), cand$give[z$ids], cand$get[z$ids]), collapse = " "),
             d_us = round(z$d_us, 2), dP = round(100 * mean(dp), 2), dP_se = round(100 * sd(dp) / sqrt(length(dp)), 2),
             dW = round(mean(sapply(res, function(r) r[[k]]$dw)), 3),
             partners_dP = paste(sprintf("%+.1f", sapply(z$ids, function(i) 100 * mean(sapply(res, function(r) r[[k]]$dp[cand$team[i]])))), collapse = "/"),
             d_them = paste(round(cand$d_them[z$ids], 2), collapse = "/"), ppg_them = paste(round(cand$ppg_them[z$ids], 2), collapse = "/"))
}))
options(width = 400); print(out[order(-out$dP), ], row.names = FALSE, right = FALSE)
saveRDS(list(cand = cand, out = out), file.path(A3, sprintf("packages_%s_%s.rds", WORLD, FILT)))
