suppressMessages({library(dplyr)})
p <- readRDS("data/nflreadr/pull_2026.rds"); s <- p$schedules
g <- bind_rows(s |> transmute(week, team = home_team, opp = away_team, pf = home_score, pa = away_score, spread = spread_line, total = total_line, home = TRUE),
               s |> transmute(week, team = away_team, opp = home_team, pf = away_score, pa = home_score, spread = -spread_line, total = total_line, home = FALSE)) |>
  mutate(imp = total/2 + spread/2)   # spread_line > 0 = home favoured; flipped for away rows -> own-team favouredness
cat("== MIN + LA 2026 results ==\n")
print(as.data.frame(g |> filter(team %in% c("MIN","LA"), !is.na(pf)) |> arrange(team, week) |>
  transmute(team, week, opp, res = ifelse(pf > pa, "W", "L"), pf, pa, imp)), row.names = FALSE)
lg <- g |> filter(!is.na(pf)) |> group_by(team) |> summarise(gp = n(), w = sum(pf > pa), ppg = mean(pf), pa_g = mean(pa)) |>
  mutate(ppg_rank = rank(-ppg, ties.method = "min"), pa_rank = rank(pa_g, ties.method = "min"))
print(as.data.frame(lg |> filter(team %in% c("MIN","LA","DET","LAC"))), row.names = FALSE)
cat("\n== wk8 lines (current pull): own implied total ==\n")
print(as.data.frame(g |> filter(week == 8, team %in% c("MIN","DET","LA","LAC")) |> select(team, opp, home, spread, total, imp)), row.names = FALSE)
