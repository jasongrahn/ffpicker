# Final ranked lists from final_<WORLD>.rds; flags: O/IR tags on incoming, name-heavy asks (partner gives a
# round 1-3 pick and gets no round 1-5 pick back), dedupe same (team, get) keeping best dP.
A3 <- "docs/review/002-evidence/a3_trades"
W <- Sys.getenv("WORLD", "tateOut"); f <- readRDS(file.path(A3, sprintf("final_%s.rds", W))); s <- f$short
pv <- readRDS(file.path(A3, "perceived.rds")); sp <- function(x) strsplit(x, " \\+ ")[[1]]
tagf <- function(x) { p <- sp(x); t <- pv$injury_1031[match(p, pv$player)]; paste(ifelse(!is.na(t) & t != "", paste0(sub("^(\\S)\\S* ", "\\1. ", p), " ", t), ""), collapse = " ") }
pk <- function(x) min(pv$pick[match(sp(x), pv$player)], na.rm = TRUE)
s$tags_in <- trimws(vapply(s$get, tagf, "")); s$best_pick_get <- suppressWarnings(vapply(s$get, pk, 0)); s$best_pick_give <- suppressWarnings(vapply(s$give, pk, 0))
s$name_heavy <- s$best_pick_get <= 30 & s$best_pick_give > 50
s <- s[order(-s$dP), ]; s <- s[!duplicated(paste(s$team, s$get)), ]
cols <- c("team", "shape", "give", "get", "drop_us", "d_us", "d_them", "ppg_them", "dP", "dW", "dP_them", "P_them0", "tags_in", "name_heavy", "fa_gain", "fa_who")
fm <- function(d) { d$team <- substr(d$team, 1, 12); d$dP <- round(100 * d$dP, 2); d$dP_them <- round(100 * d$dP_them, 1); d$P_them0 <- round(100 * d$P_them0, 1)
  for (c in c("d_us", "d_them", "ppg_them", "dW", "fa_gain")) d[[c]] <- round(as.numeric(d[[c]]), 2); d[, cols] }
options(width = 320)
cat(W, "baseline P", round(100 * f$P_us0, 2), "| unique (team,get) rows", nrow(s), "\n")
cat("\n== A. win-win on paper (d_them >= 0), top 10 by our dP ==\n"); print(fm(head(s[s$d_them >= 0, ], 10)), row.names = FALSE, right = FALSE)
cat("\n== B. they lose a little on paper (-2 <= d_them < 0), top 5 ==\n"); print(fm(head(s[s$d_them < 0 & s$d_them >= -2, ], 5)), row.names = FALSE, right = FALSE)
cat("\n== C. fair on BOTH surfaces (d_them >= -1 & ppg_them >= -1), not name-heavy, top 10 ==\n"); print(fm(head(s[s$d_them >= -1 & s$ppg_them >= -1 & !s$name_heavy, ], 10)), row.names = FALSE, right = FALSE)
cat("\n== D. ppg-fair but paper-lopsided (d_them < -2 & ppg_them >= 0): 'fleece' tier, top 6 ==\n"); print(fm(head(s[s$d_them < -2 & s$ppg_them >= 0, ], 6)), row.names = FALSE, right = FALSE)
