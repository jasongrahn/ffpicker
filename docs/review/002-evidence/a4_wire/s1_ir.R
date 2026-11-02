suppressMessages({library(dplyr); pkgload::load_all(".", quiet = TRUE)})
X <- readRDS("data/nflreadr/pull_2026.rds")
who <- c("Travis Etienne", "Davante Adams", "Carnell Tate", "Tre Tucker", "Alvin Kamara", "Kendre Miller", "Kyren Williams", "Blake Corum")
inj <- X$injuries |> filter(grepl(paste(who, collapse="|"), full_name)) |>
  select(full_name, team, week, report_primary_injury, report_status, practice_status) |> arrange(full_name, week)
print(as.data.frame(inj))
cfg <- load_config("scoring")
ps <- X$player_stats |> filter(season_type == "REG")
ps$pts <- score_player_week(ps, cfg)
cat("\nmax wk in player_stats:", max(ps$week), "\n")
st <- ps |> filter(grepl("Etienne|Davante Adams|Tate$|Tre Tucker|Kendre Miller|Alvin Kamara|Kyren Williams|Blake Corum|Puka|Stafford", player_display_name)) |>
  select(player_display_name, team, week, carries, targets, receptions, rushing_yards, receiving_yards, pts) |> arrange(player_display_name, week)
print(as.data.frame(st))
sn <- X$snaps |> filter(grepl("Etienne|Davante Adams|Carnell Tate|Tre Tucker|Kendre Miller|Alvin Kamara|Kyren Williams|Blake Corum", player)) |>
  select(player, team, week, offense_pct) |> tidyr::pivot_wider(names_from = week, values_from = offense_pct)
print(as.data.frame(sn))
