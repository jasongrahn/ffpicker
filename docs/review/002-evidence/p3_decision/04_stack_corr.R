# Q2 practical: how much weekly sd does a same-NFL-team stack add? 2024-25 REG, within-player-season deviations.
suppressMessages(library(dplyr))
x <- arrow::read_parquet("data/raw/player_stats.parquet") |>
  filter(season %in% 2024:2025, season_type == "REG", position %in% c("QB", "RB", "WR", "TE")) |>
  mutate(across(where(is.numeric), ~ coalesce(.x, 0)),
         pts = 0.04 * passing_yards + 4 * passing_tds - passing_interceptions + 0.1 * (rushing_yards + receiving_yards) +
           6 * (rushing_tds + receiving_tds) + 0.5 * receptions - 2 * (rushing_fumbles_lost + receiving_fumbles_lost + sack_fumbles_lost) +
           2 * (passing_2pt_conversions + rushing_2pt_conversions + receiving_2pt_conversions))
sea <- x |> group_by(season, team, player_id, position) |> summarise(att = sum(attempts), tgt = sum(targets), car = sum(carries), .groups = "drop")
top <- function(pos, v, k = 1) sea |> filter(position == pos) |> group_by(season, team) |> arrange(desc(.data[[v]])) |>
  slice(k) |> ungroup() |> select(season, team, player_id)
dv <- x |> group_by(season, player_id) |> filter(n() >= 6) |> mutate(dv = pts - mean(pts)) |> ungroup()
roleweeks <- function(r, cond) dv |> semi_join(r, by = c("season", "team", "player_id")) |> filter({{ cond }}) |> select(season, team, week, dv)
QB <- roleweeks(top("QB", "att"), attempts >= 15)
roles <- list(WR1 = top("WR", "tgt"), WR2 = top("WR", "tgt", 2), TE1 = top("TE", "tgt"), RB1 = top("RB", "car"))
out <- bind_rows(lapply(names(roles), function(nm) {
  B <- roleweeks(roles[[nm]], TRUE); j <- inner_join(QB, B, by = c("season", "team", "week"))
  ct <- cor.test(j$dv.x, j$dv.y)
  data.frame(pair = paste("QB +", nm), n = nrow(j), rho = round(ct$estimate, 3), lo = round(ct$conf.int[1], 3),
             hi = round(ct$conf.int[2], 3), sd_qb = round(sd(j$dv.x), 2), sd_b = round(sd(j$dv.y), 2))
}))
SIG <- 21.08; out$sd_team_after <- round(sqrt(SIG^2 + 2 * out$rho * out$sd_qb * out$sd_b), 2)
out$d_sd <- out$sd_team_after - SIG; out$mean_equiv_pts <- round(out$d_sd * 0.39, 2)   # 0.39 pts mean per +1 sd (02_variance.R)
print(out, row.names = FALSE)
# opposing QBs same game (shootout correlation) -> sharing a game with the opponent's QB
g <- x |> filter(position == "QB", attempts >= 15) |> group_by(season, player_id) |> filter(n() >= 6) |>
  mutate(dv = pts - mean(pts)) |> ungroup() |> select(season, week, team, opponent_team, dv)
gg <- inner_join(g, g, by = c("season", "week", "team" = "opponent_team")) |> filter(team < team.y)
cat(sprintf("opposing QBs same game: rho %.3f, n %d\n", cor(gg$dv.x, gg$dv.y), nrow(gg)))
