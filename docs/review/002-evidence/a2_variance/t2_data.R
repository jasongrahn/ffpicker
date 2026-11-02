# Task 2 data: 2024-25 REG player-week half-PPR (score_player_week + config), DST team-week pts, roles.
# Run from repo root. Output: a2_variance/pw_2425.rds
A2 <- "docs/review/002-evidence/a2_variance"
suppressMessages({pkgload::load_all(".", quiet = TRUE); library(dplyr)})
sc_cfg <- load_config("scoring")
ps <- arrow::read_parquet("data/raw/player_stats.parquet") |>
  filter(season %in% 2024:2025, season_type == "REG", position %in% c("QB", "RB", "WR", "TE", "K"))
ps$pts <- score_player_week(ps, sc_cfg)
# check vs nflverse: ours = (std + ppr)/2 + INT (nflverse std uses -2/INT, we use -1); K not in nflverse fp
chk <- ps |> filter(position != "K") |> mutate(ref = (fantasy_points + fantasy_points_ppr) / 2 + passing_interceptions,
  d = pts - ref)
cat(sprintf("score check non-K n %d: |d|<0.01 %.2f%%, mean |d| %.4f, max |d| %.2f\n", nrow(chk),
  100 * mean(abs(chk$d) < 0.01, na.rm = TRUE), mean(abs(chk$d), na.rm = TRUE), max(abs(chk$d), na.rm = TRUE)))
print(chk |> filter(abs(d) >= 0.01) |> count(note = ifelse(special_teams_tds > 0, "st_td", "other")))
x <- readRDS(file.path(A2, "nfl_2425.rds"))
sch <- x$sc |> filter(game_type == "REG")
long <- bind_rows(
  sch |> transmute(season, week, game_id, team = home_team, opp = away_team, pa = away_score,
                   opp_implied = total_line / 2 - spread_line / 2),
  sch |> transmute(season, week, game_id, team = away_team, opp = home_team, pa = home_score,
                   opp_implied = total_line / 2 + spread_line / 2))
tier <- function(pa) { tb <- sc_cfg$dst$points_allowed; out <- rep(NA_real_, length(pa))
  for (i in rev(seq_along(tb))) out[pa <= tb[[i]]$max] <- tb[[i]]$points; out }
dst <- x$ts |> filter(season_type == "REG") |>
  transmute(season, week, team, sacks = def_sacks, ints = def_interceptions, fr = fumble_recovery_opp,
            saf = def_safeties, blk = def_punt_blocks + def_pat_blocks + def_fg_blocks,
            rtd = def_tds + special_teams_tds) |>
  mutate(across(sacks:rtd, ~ coalesce(.x, 0))) |>
  inner_join(long, by = c("season", "week", "team")) |>
  mutate(pts = sacks * sc_cfg$dst$sack + ints * sc_cfg$dst$interception + fr * sc_cfg$dst$fumble_recovery +
           saf * sc_cfg$dst$safety + blk * sc_cfg$dst$block_kick + rtd * sc_cfg$dst$touchdown + tier(pa))
cat(sprintf("DST team-weeks %d mean %.2f sd %.2f\n", nrow(dst), mean(dst$pts), sd(dst$pts)))
# roles per team-season (team = the team he played for that week)
us <- ps |> group_by(season, team, player_id, position) |>
  summarise(name = first(player_display_name), g = n(), tgt = sum(targets, na.rm = TRUE),
            car = sum(carries, na.rm = TRUE), att = sum(attempts, na.rm = TRUE),
            katt = sum(coalesce(fg_att, 0) + coalesce(pat_att, 0)), ppg = mean(pts), .groups = "drop")
role <- bind_rows(
  us |> filter(position == "QB") |> group_by(season, team) |> slice_max(att, n = 1, with_ties = FALSE) |> mutate(role = "QB1"),
  us |> filter(position == "WR") |> group_by(season, team) |> slice_max(tgt, n = 2, with_ties = FALSE) |>
    mutate(role = c("WR1", "WR2")[row_number()]),
  us |> filter(position == "TE") |> group_by(season, team) |> slice_max(tgt, n = 1, with_ties = FALSE) |> mutate(role = "TE1"),
  us |> filter(position == "RB") |> group_by(season, team) |> slice_max(car + tgt, n = 1, with_ties = FALSE) |> mutate(role = "RB1"),
  us |> filter(position == "K") |> group_by(season, team) |> slice_max(katt, n = 1, with_ties = FALSE) |> mutate(role = "K1")) |>
  ungroup()
pw <- ps |> select(season, week, game_id, team, opponent_team, player_id, position, name = player_display_name,
                   pts, attempts, targets, carries, receptions, tds = NULL) |>
  inner_join(role |> select(season, team, player_id, role, g, ppg), by = c("season", "team", "player_id"))
saveRDS(list(pw = pw, dst = dst, ps = ps |> select(season, week, game_id, team, opponent_team, player_id, position,
  name = player_display_name, pts, attempts, targets, carries, receptions, passing_tds, rushing_tds, receiving_tds)),
  file.path(A2, "pw_2425.rds"))
print(role |> count(role))
