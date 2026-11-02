suppressMessages(library(dplyr)); options(width = 250)
SCR <- "docs/review/002-evidence"
x <- readRDS(file.path(SCR, "p1_veteran/trade_screen.rds")) |>
  mutate(fair = pv_give / pv_get, adams = grepl("Adams", give),
         d_us_adj = d_us - ifelse(adams, 2.14, 0),            # Adams returning wk12 is worth +2.14/wk to us; sim gives 0
         across(where(is.numeric), ~ round(.x, 2)))
sh <- function(d, n = 12) print(as.data.frame(d |> head(n) |> transmute(team = substr(team, 1, 14), give, get, d_us, d_us_adj, d_them_proj, d_them_pv, pv_give, pv_get, fair)), row.names = FALSE)
cat("== TR1 / TR2 under both lenses ==\n")
sh(x |> filter((team == "Monday Night Madison" & give == "Kyler Murray + T.J. Hockenson" & get == "Josh Jacobs") |
               (grepl("^Max", team) & give == "Patrick Mahomes + Carnell Tate" & get == "Luther Burden III + Isaiah Likely")))
cat("\n== counts: d_us_adj >= 3 ==\n")
print(x |> filter(d_us_adj >= 3) |> summarise(n = n(), proj_winwin = sum(d_them_proj >= 0), perceived_win = sum(d_them_pv >= 0),
   perceived_and_fair = sum(d_them_pv >= 0 & fair >= 0.9), proj_lose_but_perceived_win = sum(d_them_proj < 0 & d_them_pv >= 0 & fair >= 0.9)))
cat("\n== BEST per partner: d_us_adj, partner perceives gain (pv lens), fair to voters (pv_give >= 0.9 pv_get) ==\n")
best <- x |> filter(d_them_pv >= 0, fair >= 0.9) |> group_by(team) |> slice_max(d_us_adj, n = 3, with_ties = FALSE) |> ungroup() |> arrange(desc(d_us_adj))
sh(best, 30)
cat("\n== same, but ALSO win-win on projections (sharp-manager safe) ==\n")
sh(x |> filter(d_them_pv >= 0, fair >= 0.9, d_them_proj >= 0) |> group_by(team) |> slice_max(d_us_adj, n = 2, with_ties = FALSE) |> ungroup() |> arrange(desc(d_us_adj)), 20)
cat("\n== CONSOLIDATION (we give more bodies than we get), perceived-win + fair ==\n")
sh(x |> filter(ng > nr, d_them_pv >= 0, fair >= 0.9) |> arrange(desc(d_us_adj)), 15)
cat("\n== ADAMS (IR, back wk12) as sell-for-now chip; d_us_adj nets his return value ==\n")
sh(x |> filter(adams, d_them_pv >= 0, fair >= 0.9) |> arrange(desc(d_us_adj)), 12)
saveRDS(best, file.path(SCR, "p1_veteran/best_perceived.rds"))
