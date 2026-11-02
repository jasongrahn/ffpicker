# Handcuffs + fresh wk8 injuries (snap collapse) -> backups worth a Tue claim.
suppressMessages({library(dplyr); library(tidyr)})
OUT <- "docs/review/002-evidence/a4_wire/"
d <- readRDS(paste0(OUT, "wire_table.rds"))
X <- readRDS("data/nflreadr/pull_2026.rds")
ids <- X$ids |> filter(!is.na(gsis_id), !is.na(pfr_id)) |> distinct(pfr_id, .keep_all = TRUE)
sn <- X$snaps |> filter(game_type == "REG", position %in% c("QB", "RB", "WR", "TE")) |> select(player, pfr_player_id, team, week, position, offense_pct)
# fresh collapse: wk8 (or team's last game) snap < 50% of prior-3-game mean, prior mean >= 55%
lastwk <- sn |> group_by(team) |> summarise(lw = max(week), .groups = "drop")
col <- sn |> inner_join(lastwk, by = "team") |> group_by(pfr_player_id, player, team, position) |>
  summarise(last = sum(offense_pct[week == first(lw)]), prior = mean(offense_pct[week < first(lw) & week >= first(lw) - 3]),
            n_prior = sum(week < first(lw) & week >= first(lw) - 3), played_last = any(week == first(lw)), lw = first(lw), .groups = "drop") |>
  filter(n_prior >= 2, prior >= 0.55, last < 0.5 * prior) |> arrange(position, desc(prior))
cat("== starters whose snaps collapsed in team's last game (possible fresh injury) ==\n")
print(as.data.frame(col |> mutate(across(c(last, prior), ~ round(100 * .x)))), row.names = FALSE)
inj8 <- X$injuries |> filter(week == max(week)) |> select(full_name, team, position, report_status, report_primary_injury)
cat("\nnflreadr injuries max week:", max(X$injuries$week), "\n")
# RB depth by team: last 3 team games carries
ps <- X$player_stats |> filter(season_type == "REG", position == "RB")
l3 <- ps |> distinct(team, week) |> group_by(team) |> slice_max(week, n = 3) |> ungroup()
dep <- ps |> inner_join(l3, by = c("team", "week")) |> group_by(team, player_id, player_display_name) |>
  summarise(car3 = sum(carries, na.rm = TRUE) / 3, tgt3 = sum(targets, na.rm = TRUE) / 3, .groups = "drop") |>
  group_by(team) |> arrange(desc(car3 + tgt3), .by_group = TRUE) |> mutate(rb = row_number()) |> filter(rb <= 3) |> ungroup()
own <- d |> filter(pos == "RB") |> select(gsis_id, owner31, injury, avail, base, pct_ros)
dep <- dep |> left_join(own, by = c("player_id" = "gsis_id"))
w <- dep |> mutate(lab = sprintf("%s (%s%s, %.0f+%.0f, b%.1f)", player_display_name, ifelse(coalesce(avail, TRUE), "AVAIL", substr(owner31, 1, 8)),
                                 ifelse(is.na(injury) | injury == "", "", paste0(",", injury)), car3, tgt3, coalesce(base, 0))) |>
  select(team, rb, lab) |> pivot_wider(names_from = rb, values_from = lab, names_prefix = "RB")
cat("\n== RB depth, last 3 team games (car+tgt per game), owner 10-31 ==\n")
print(as.data.frame(w), row.names = FALSE, right = FALSE)
