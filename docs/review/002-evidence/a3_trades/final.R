# Shortlist from search_screen.rds -> full machinery (apply_trade + M_of) -> sim 10 seeds x N 20000.
# Adds: partner dP(top 4) (arming cost), perceived Delta (ppg world: base := 0.5 season ppg + 0.5 last-3
# ppg, same lineup logic), open-spot FA value for consolidation trades. Then 2-/3-trade packages.
source("docs/review/002-evidence/a3_trades/common.R")
STROUD <- "C.J. Stroud"
scr <- readRDS(file.path(A3, "search_screen.rds")); pv <- readRDS(file.path(A3, "perceived.rds"))
WORLD <- Sys.getenv("WORLD", "tateOut")
Rw <- if (WORLD == "tateOut") within(R, base[player == "Carnell Tate"] <- 0) else R
Mb <- M_of(Rw)

# ---- ppg world (what managers see) ----
pv$pval <- ifelse(pv$g > 0, 0.5 * pv$ppg + 0.5 * pv$last3, 0)
Rp <- Rw; i <- match(Rp$player, pv$player); Rp$base[!is.na(i)] <- pv$pval[i[!is.na(i)]]
stroud_row <- as.data.frame(P[P$player == STROUD, names(R)]); stroud_row$owner <- ME

build <- function(Rx, tm, give, get) {   # real machinery; no QB left -> claim Stroud (takes a roster spot)
  x <- apply_trade(Rx, tm, give, get); us <- x$R[x$R$owner == ME, ]
  if (!any(active(us)$pos == "QB")) {
    sr <- stroud_row; if (identical(Rx, Rp)) sr$base <- pv$pval[pv$player == STROUD]
    a <- settle(rbind(us, sr), c(get, STROUD)); x$R <- rbind(x$R[x$R$owner != ME, ], a$r); x$drop_us <- c(x$drop_us, a$dropped)
  }
  x
}
fa_pool <- as.data.frame(AVAIL |> filter(pos %in% c("QB", "RB", "WR", "TE")) |> group_by(pos) |> slice_max(base, n = 5) |> ungroup())
open_spot <- function(Rx) {   # best FA add if our active roster < CAP (consolidation)
  us <- Rx[Rx$owner == ME, ]; if (nrow(active(us)) >= CAP) return(c(gain = 0, who = NA))
  b <- fut_df(us); g <- vapply(seq_len(nrow(fa_pool)), function(k) fut_df(rbind(us, transform(fa_pool[k, names(us)], owner = ME))) - b, 0)
  c(gain = max(g), who = fa_pool$player[which.max(g)])
}

# ---- shortlist per partner (dedupe by get set) ----
tag <- function(d, k) { d$kind <- rep(k, nrow(d)); d }
x <- scr[scr$world == WORLD, ]
pick <- function(df, k) { if (!nrow(df)) return(df); df <- df[order(-df$d_us), ]; df <- df[!duplicated(paste(df$team, df$get)), ]
  do.call(rbind, lapply(split(df, df$team), function(z) head(z, k))) }
ww <- pick(x[x$d_us > 0 & x$d_them >= 0, ], 6); ww <- tag(ww, "win-win")
sw <- pick(x[x$d_us > 0 & x$d_them < 0 & x$d_them >= -2, ], 3); sw <- tag(sw, "they lose <=2")
# also: best per partner by d_us + d_them (most 'balanced' big trades)
bal <- x[x$d_us > 1.5 & x$d_them > -2, ]; bal <- bal[order(-(bal$d_us + bal$d_them)), ]; bal <- bal[!duplicated(paste(bal$team, bal$get)), ]
bal <- do.call(rbind, lapply(split(bal, bal$team), function(z) head(z, 2))); bal <- tag(bal, "balanced")
pf <- pick(x[x$d_us > 1 & x$ppg_them >= 0, ], 4); pf <- tag(pf, "ppg-fair")          # perceived-fair on what managers see
pf2 <- pick(x[x$d_us > 1 & x$ppg_them >= 0 & x$d_them >= -1, ], 3); pf2 <- tag(pf2, "ppg-fair+paper")
short <- rbind(ww, sw, bal, pf, pf2); short <- short[!duplicated(paste(short$team, short$give, short$get)), ]
cat(WORLD, ": shortlist", nrow(short), "trades\n")

sp <- function(s) strsplit(s, " \\+ ")[[1]]
short$x <- lapply(seq_len(nrow(short)), function(i) build(Rw, short$team[i], sp(short$give[i]), sp(short$get[i])))
short$M <- lapply(short$x, function(z) M_of(z$R))
short$d_us_chk <- vapply(short$M, function(M) fut(M[ME, ]) - fut(Mb[ME, ]), 0)
short$d_them_chk <- mapply(function(M, tm) fut(M[tm, ]) - fut(Mb[tm, ]), short$M, short$team)
stopifnot(all(abs(short$d_us_chk - short$d_us) < 1e-6 | short$noQB), all(abs(short$d_them_chk - short$d_them) < 1e-6))
op <- lapply(short$x, function(z) open_spot(z$R)); short$fa_gain <- as.numeric(sapply(op, `[`, "gain")); short$fa_who <- sapply(op, `[`, "who")
# perceived (ppg world)
Mp0 <- strength_matrix(Rp)
pp <- lapply(seq_len(nrow(short)), function(i) { z <- build(Rp, short$team[i], sp(short$give[i]), sp(short$get[i]))
  c(us = fut(team_strength(z$R[z$R$owner == ME, ])) - fut(Mp0[ME, ]), them = fut(team_strength(z$R[z$R$owner == short$team[i], ])) - fut(Mp0[short$team[i], ])) })
short$ppg_us <- sapply(pp, `[`, "us"); short$ppg_them <- sapply(pp, `[`, "them")

res <- mclapply(SEEDS, function(sd) { b <- sim_fast(Mb, seed = sd)
  lapply(short$M, function(M) { s <- sim_fast(M, seed = sd); list(dp = s$p - b$p, dw = s$w[ME] - b$w[ME], pb = b$p) }) }, mc.cores = 4)
short$dP <- sapply(seq_len(nrow(short)), function(i) mean(sapply(res, function(r) r[[i]]$dp[ME])))
short$dP_se <- sapply(seq_len(nrow(short)), function(i) sd(sapply(res, function(r) r[[i]]$dp[ME])) / sqrt(length(res)))
short$dW <- sapply(seq_len(nrow(short)), function(i) mean(sapply(res, function(r) r[[i]]$dw)))
short$dP_them <- sapply(seq_len(nrow(short)), function(i) mean(sapply(res, function(r) r[[i]]$dp[short$team[i]])))
short$P_them0 <- sapply(seq_len(nrow(short)), function(i) mean(sapply(res, function(r) r[[i]]$pb[short$team[i]])))
P_us0 <- mean(sapply(res, function(r) r[[1]]$pb[ME]))
cat(sprintf("%s baseline P(top4) us %.2f%%\n", WORLD, 100 * P_us0))
saveRDS(list(short = short[, setdiff(names(short), c("x", "M"))], P_us0 = P_us0, world = WORLD), file.path(A3, sprintf("final_%s.rds", WORLD)))
saveRDS(short, file.path(A3, sprintf("final_%s_full.rds", WORLD)))

fmt <- function(d) transform(d[, c("kind", "team", "shape", "give", "get", "drop_us", "drop_them", "d_us", "d_them", "ppg_us", "ppg_them", "fa_gain", "fa_who", "dP", "dP_se", "dW", "dP_them", "P_them0")],
  team = substr(team, 1, 14), d_us = round(d_us, 2), d_them = round(d_them, 2), ppg_us = round(ppg_us, 2), ppg_them = round(ppg_them, 2),
  fa_gain = round(fa_gain, 2), dP = round(100 * dP, 2), dP_se = round(100 * dP_se, 2), dW = round(dW, 3), dP_them = round(100 * dP_them, 1), P_them0 = round(100 * P_them0, 1))
options(width = 300)
cat("\n== TOP 10 win-win (d_them >= 0) by our dP ==\n"); a <- short[short$d_them >= 0, ]; print(fmt(head(a[order(-a$dP), ], 10)), row.names = FALSE, right = FALSE)
cat("\n== TOP 5 they-lose (-2 <= d_them < 0) ==\n"); a <- short[short$d_them < 0, ]; print(fmt(head(a[order(-a$dP), ], 5)), row.names = FALSE, right = FALSE)
cat("\n== TOP 10 perceived-fair (ppg_them >= 0) by our dP ==\n"); a <- short[short$ppg_them >= 0, ]; print(fmt(head(a[order(-a$dP), ], 10)), row.names = FALSE, right = FALSE)
cat("\n== ALL shortlist by dP ==\n"); print(fmt(short[order(-short$dP), ]), row.names = FALSE, right = FALSE)
