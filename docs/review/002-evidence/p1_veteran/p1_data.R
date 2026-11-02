# P1 shared data: player table = 10-31 Yahoo exports + sim base + nflreadr usage/points 2026.
# Source from repo root AFTER sim_helpers.R (needs P, R, teams, ME).
suppressMessages({library(dplyr); library(tidyr)})
pkgload::load_all(".", quiet = TRUE)
fs <- sprintf("docs/uploads/week_8_data/yahoo_week8_%s_2026-10-31.csv", c("qb","rb","wr","te","k","def"))
Y <- bind_rows(lapply(fs, read_yahoo_position)) |> distinct(player, yteam, .keep_all = TRUE) |>
  mutate(key = ifelse(pos == "DEF", paste0("DEF:", yteam), yahoo_id))
Y <- Y |> left_join(P |> select(key, base), by = "key") |> mutate(base = coalesce(base, 0))
Y <- attach_nfl_ids(Y |> filter(pos != "DEF")) |> bind_rows(Y |> filter(pos == "DEF"))
nf <- readRDS("data/nflreadr/pull_2026.rds")
ps <- nf$player_stats |> filter(season_type == "REG")
ps$fpts <- score_player_week(ps, load_config("scoring"))
# team targets/carries per week for shares
tt <- ps |> group_by(team, week) |> summarise(team_tgt = sum(targets, na.rm = TRUE), team_car = sum(carries, na.rm = TRUE), .groups = "drop")
ps <- ps |> left_join(tt, by = c("team", "week")) |>
  mutate(tshare = targets / pmax(team_tgt, 1), cshare = carries / pmax(team_car, 1),
         opp = targets + carries)
# snaps: pfr id -> gsis via ids
ids <- nf$ids
sn <- nf$snaps |> filter(game_type == "REG") |> left_join(ids |> select(pfr_id, gsis_id) |> filter(!is.na(pfr_id)) |> distinct(pfr_id, .keep_all = TRUE),
                                                   by = c("pfr_player_id" = "pfr_id")) |>
  select(gsis_id, week, team_snap = team, offense_pct)
U <- ps |> select(gsis_id = player_id, week, team, fpts, targets, carries, tshare, cshare, opp, receptions) |>
  full_join(sn, by = c("gsis_id", "week")) |> mutate(team = coalesce(team, team_snap)) |> select(-team_snap)
last_wk <- max(ps$week)
# per-player summary
S <- U |> filter(!is.na(gsis_id)) |> group_by(gsis_id) |> arrange(week) |>
  summarise(gp = sum(!is.na(fpts)), ppg = mean(fpts, na.rm = TRUE),
            ppg_l3 = mean(tail(fpts[!is.na(fpts)], 3)),
            tot = sum(fpts, na.rm = TRUE),
            snap_l3 = mean(tail(offense_pct[!is.na(offense_pct)], 3)),
            snap_prev = { s <- offense_pct[!is.na(offense_pct)]; if (length(s) > 3) mean(head(s, length(s) - 3)) else NA_real_ },
            tsh_l3 = mean(tail(tshare[!is.na(tshare)], 3)), opp_l3 = mean(tail(opp[!is.na(opp)], 3)),
            opp_all = mean(opp, na.rm = TRUE),
            wks = paste(week[!is.na(fpts)], collapse = ","), .groups = "drop") |>
  mutate(across(where(is.numeric), ~ ifelse(is.nan(.x), NA, .x)))
Y <- Y |> left_join(S, by = "gsis_id")
