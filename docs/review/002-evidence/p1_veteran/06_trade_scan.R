# Perception-arbitrage trade scan. Our side valued on PROJECTION (sim base). Partner acceptance valued on
# what a casual manager sees in Yahoo: pv = 0.5*season ppg + 0.5*last-3 ppg (gp >= 2; else base).
# Gives: any 1-3 of our QB/RB/WR/TE (+ Adams IR, perceived from wk12). Gets: 1-2 of partner RB/WR/TE base >= 8.
# Screen without cap (extra bench bodies don't change a projection-optimal lineup); exact apply_trade + sim on shortlist.
SCR <- "docs/review/002-evidence"
suppressMessages(source(file.path(SCR, "sim_helpers.R")))
Y <- readRDS(file.path(SCR, "p1_veteran/Y.rds"))
options(width = 250)
FW <- WEEKS[-1]                                       # wks 9-15
pv_tab <- Y |> transmute(key, ppg, l3 = ppg_l3, gp)
RR <- R |> left_join(pv_tab, by = "key") |>
  mutate(pv = ifelse(!is.na(gp) & gp >= 2, 0.5 * ppg + 0.5 * l3, base),
         pv = ifelse(pos %in% c("K", "DEF"), base, pv))
# Adams: IR, back wk12 earliest. Projection value for US: pre-injury mean proj 12.6 wks 12-15 (sensitivity only).
ADAMS_PROJ <- mean(c(11.24, 13.13, 13.33))
onw <- lapply(FW, function(w) ON[[as.character(w)]])
strength <- function(d, val, adams_from = 99) {      # mean over wks 9-15, FILL for empty slots
  ok <- is.na(d$injury) | !grepl("IR", d$injury) | (d$player == "Davante Adams")
  d <- d[ok, ]; v <- d[[val]]
  mean(vapply(seq_along(FW), function(k) {
    w <- FW[k]; on <- d$nfl %in% onw[[k]] & v > 0
    if (any(d$player == "Davante Adams")) on[d$player == "Davante Adams"] <- w >= adams_from && "LA" %in% onw[[k]]
    opt_total(d$pos[on], v[on], FILL) }, numeric(1)))
}
RR$pv[RR$player == "Davante Adams"] <- 14.5         # what partners see (season ppg, pre-injury)
RR$base_adams <- RR$base; RR$base_adams[RR$player == "Davante Adams"] <- ADAMS_PROJ
mine <- RR[RR$owner == ME, ]
TRD <- mine$player[mine$pos %in% c("QB", "RB", "WR", "TE") & !(mine$injury %in% "IR") | mine$player == "Davante Adams"]
cat("tradeable:", paste(TRD, collapse = ", "), "\n")
gives <- c(combn(TRD, 1, simplify = FALSE), combn(TRD, 2, simplify = FALSE), combn(TRD, 3, simplify = FALSE))
us0 <- strength(mine, "base"); us0a <- strength(mine, "base_adams", 12)
cat(sprintf("our strength wks 9-15: base %.2f | with Adams back wk12 @ %.1f: %.2f (+%.2f)\n", us0, ADAMS_PROJ, us0a, us0a - us0))
t0 <- Sys.time()
res <- list()
for (tm in setdiff(teams, ME)) {
  th <- RR[RR$owner == tm, ]
  IN <- th$player[th$pos %in% c("RB", "WR", "TE") & th$base >= 8 & !(th$injury %in% c("IR", "O"))]
  gets <- c(as.list(IN), if (length(IN) >= 2) combn(IN, 2, simplify = FALSE))
  th_p0 <- strength(th, "base"); th_v0 <- strength(th, "pv")
  for (g in gives) for (r in gets) {
    if (length(r) > length(g) + 1) next
    usn <- rbind(mine[!mine$player %in% g, ], th[th$player %in% r, ])
    thn <- rbind(th[!th$player %in% r, ], mine[mine$player %in% g, ])
    if (!any(usn$pos == "QB")) next
    res[[length(res) + 1]] <- data.frame(team = tm, give = paste(g, collapse = " + "), get = paste(r, collapse = " + "),
      ng = length(g), nr = length(r),
      d_us = strength(usn, "base") - us0,
      d_them_proj = strength(thn, "base") - th_p0, d_them_pv = strength(thn, "pv") - th_v0,
      pv_give = sum(mine$pv[mine$player %in% g]), pv_get = sum(th$pv[th$player %in% r]),
      base_give = sum(mine$base[mine$player %in% g]), base_get = sum(th$base[th$player %in% r]))
  }
}
res <- do.call(rbind, res)
cat(sprintf("%d trades screened in %.0fs\n", nrow(res), as.numeric(difftime(Sys.time(), t0, units = "secs"))))
saveRDS(res, file.path(SCR, "p1_veteran/trade_screen.rds"))
