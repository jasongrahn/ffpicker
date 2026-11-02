# Acceptance = what a casual manager sees: (1) perceived lineup gain on ppg/recent lens >= 0,
# (2) STATURE: best name we send (Yahoo preseason rank) within 1.25x+5 of best name we ask for,
# (3) voters: pv_give >= 0.9 pv_get. Then rank by our projection gain.
suppressMessages(library(dplyr)); options(width = 250)
SCR <- "docs/review/002-evidence"
Y <- readRDS(file.path(SCR, "p1_veteran/Y.rds")); rk <- setNames(Y$rank_pre, Y$player)
x <- readRDS(file.path(SCR, "p1_veteran/trade_screen.rds")) |>
  mutate(fair = pv_give / pv_get, adams = grepl("Adams", give), d_us_adj = d_us - ifelse(adams, 2.14, 0),
         rp_give = vapply(strsplit(give, " \\+ "), function(p) min(rk[p], na.rm = TRUE), 0),
         rp_get = vapply(strsplit(get, " \\+ "), function(p) min(rk[p], na.rm = TRUE), 0),
         stature_ok = rp_give <= 1.25 * rp_get + 5)
sh <- function(d, n = 12) print(as.data.frame(d |> head(n) |> transmute(team = substr(team, 1, 14), give, get, d_us = round(d_us_adj, 2), them_proj = round(d_them_proj, 2), them_pv = round(d_them_pv, 2), fair = round(fair, 2), rp_give, rp_get)), row.names = FALSE)
acc <- x |> filter(d_them_pv >= 0, fair >= 0.9, stature_ok)
cat(sprintf("all screened %d | d_us>=3: %d | of those projection win-win (current rule): %d | casual-acceptance (pv+stature+fair): %d | both: %d\n",
  nrow(x), sum(x$d_us_adj >= 3), sum(x$d_us_adj >= 3 & x$d_them_proj >= 0), sum(acc$d_us_adj >= 3), sum(acc$d_us_adj >= 3 & acc$d_them_proj >= 0)))
cat("\n== casual-acceptance set, best 3 per partner ==\n")
sh(acc |> group_by(team) |> slice_max(d_us_adj, n = 3, with_ties = FALSE) |> ungroup() |> arrange(desc(d_us_adj)), 27)
cat("\n== TR1 / TR2 sweetener variants (perceived gain for partner) ==\n")
sh(x |> filter(team == "Monday Night Madison", grepl("Kyler Murray", give), get == "Josh Jacobs") |> arrange(desc(d_them_pv)), 8)
sh(x |> filter(grepl("^Max", team), grepl("Patrick Mahomes", give), get == "Luther Burden III + Isaiah Likely") |> arrange(desc(d_them_pv)), 8)
sh(x |> filter(grepl("^Max", team), get %in% c("Isaiah Likely", "Luther Burden III")) |> filter(d_them_pv >= 0) |> arrange(desc(d_us_adj)), 8)
saveRDS(acc, file.path(SCR, "p1_veteran/acc_set.rds"))
