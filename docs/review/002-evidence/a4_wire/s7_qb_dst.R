# QB streaming (wk11, LA bye) + DST plan wks 9-15. Wk9 = real lines; wks 10-15 = market ratings
# fitted on wks 1-9 implied totals (implied ~ off[team] + def[opp] + home), n = 2 x games.
suppressMessages({library(dplyr); library(tidyr)})
OUT <- "docs/review/002-evidence/a4_wire/"
d <- readRDS(paste0(OUT, "wire_table.rds"))
s <- readRDS("data/nflreadr/pull_2026.rds")$schedules |> filter(game_type == "REG")
long <- function(x) bind_rows(x |> transmute(week, tm = home_team, opp = away_team, home = 1, imp = total_line / 2 + spread_line / 2),
                              x |> transmute(week, tm = away_team, opp = home_team, home = 0, imp = total_line / 2 - spread_line / 2))
fit_d <- long(s |> filter(week <= 9, !is.na(spread_line)))
m <- lm(imp ~ tm + opp + home, data = fit_d)
cat(sprintf("rating fit: n %d team-games, R2 %.2f, resid sd %.2f\n", nrow(fit_d), summary(m)$r.squared, sigma(m)))
# out-of-sample check: fit wks 1-6, predict wks 7-9
m6 <- lm(imp ~ tm + opp + home, data = fit_d |> filter(week <= 6)); te <- fit_d |> filter(week >= 7)
cat(sprintf("holdout wks 7-9 (fit 1-6): r %.2f, MAE %.2f, n %d\n", cor(predict(m6, te), te$imp), mean(abs(predict(m6, te) - te$imp)), nrow(te)))
fut <- long(s |> filter(week >= 9) |> mutate(spread_line = coalesce(spread_line, 0), total_line = coalesce(total_line, 0)))
fut$imp_hat <- ifelse(fut$week == 9, fut$imp, predict(m, fut))
saveRDS(fut, paste0(OUT, "implied_wk9_15.rds"))
# ---- QB ----
q <- d |> filter(pos == "QB") |> select(player, nfl, bye, injury, owner31, avail, base, base_raw, p8, pct_ros)
qi <- fut |> select(week, tm, opp, imp_hat) |> mutate(x = sprintf("%s %.1f", opp, imp_hat)) |> select(week, tm, x) |>
  pivot_wider(names_from = week, values_from = x, names_prefix = "w")
qa <- q |> filter(avail, base > 0 | base_raw >= 14) |> left_join(qi, by = c("nfl" = "tm")) |> arrange(desc(base))
cat("\n== AVAILABLE QBs (10-31 owners). base = sim base (0 = not starting in last 2 exports); cells = opp + OWN implied total ==\n")
print(as.data.frame(qa |> transmute(player, nfl, bye, inj = coalesce(injury, ""), own = substr(owner31, 1, 11), base = round(base, 1), braw = round(base_raw, 1), p8, w9, w10, w11, w12, w13, w14, w15)), row.names = FALSE)
st <- fut |> filter(tm == "LA") |> transmute(week, opp, own_imp = round(imp_hat, 1))
cat("\nStafford (LA) own implied by week:\n"); print(as.data.frame(st), row.names = FALSE)
# ---- DST ----
df <- d |> filter(pos == "DEF") |> transmute(dst = player, tm = nfl, owner31, avail)
dp <- fut |> transmute(week, tm, opp, opp_imp = imp_hat - 0) |>
  left_join(fut |> transmute(week, tm2 = tm, opp_imp2 = imp_hat), by = c("week", "opp" = "tm2")) |>
  transmute(week, tm, opp, opp_imp = opp_imp2) |> inner_join(df, by = "tm")
ours <- c("WAS", "KC")
cat("\n== DST by week: top 6 by LOWEST opponent implied (AVAIL or ours), + our two ==\n")
for (w in 9:15) {
  x <- dp |> filter(week == w) |> arrange(opp_imp) |> mutate(rank = row_number())
  best <- x |> filter(avail | tm %in% ours) |> head(6)
  cat(sprintf("\nwk%d (%s):\n", w, ifelse(w == 9, "real lines", "rating proxy")))
  print(as.data.frame(bind_rows(best, x |> filter(tm %in% ours, !tm %in% best$tm)) |>
    transmute(rank, dst, tm, opp, opp_imp = round(opp_imp, 1), status = ifelse(tm %in% ours, "OURS", substr(owner31, 1, 12)))), row.names = FALSE)
}
plan <- dp |> filter(avail | tm %in% ours) |> group_by(week) |> slice_min(opp_imp, n = 1, with_ties = FALSE) |> ungroup() |>
  left_join(dp |> filter(tm %in% ours) |> group_by(week) |> summarise(ours_best = min(opp_imp), .groups = "drop"), by = "week") |>
  left_join(dp |> group_by(week) |> summarise(field_mean = mean(opp_imp), .groups = "drop"), by = "week") |>
  mutate(gain_vs_ours = round(0.40 * (ours_best - opp_imp), 2), gain_vs_avg = round(0.40 * (field_mean - opp_imp), 2))
cat("\n== stream plan: best avail-or-ours DST per week; gain = 0.40 x implied-pt gap ==\n")
print(as.data.frame(plan |> transmute(week, dst, tm, opp, opp_imp = round(opp_imp, 1), status = substr(owner31, 1, 12), ours_best = round(ours_best, 1), gain_vs_ours, gain_vs_avg)), row.names = FALSE)
cat(sprintf("\nmean gain vs holding best of ours wks 9-15: %.2f pts/wk; vs avg DST: %.2f\n", mean(plan$gain_vs_ours), mean(plan$gain_vs_avg)))
saveRDS(plan, paste0(OUT, "dst_plan.rds"))
