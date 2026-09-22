# VOR board for the FLEX slot, replacement = Travis Etienne Jr.
# Opportunity (carries + targets) is the ranking signal, not Week 1 points.
suppressMessages({library(nflreadr); library(dplyr); library(tibble); library(utils)})

SRC <- "docs/uploads/week_2_data"

sched <- load_schedules(2026) |> filter(week == 2)
env <- bind_rows(
  sched |> transmute(team = home_team, opp = away_team, spread = spread_line, total_line),
  sched |> transmute(team = away_team, opp = home_team, spread = -spread_line, total_line)
) |> mutate(implied = total_line/2 + spread/2)

p <- read.csv(file.path(SRC, "week_2_players.csv")) |> as_tibble() |>
  mutate(team = ifelse(nfl_team == "LAR", "LA", toupper(nfl_team))) |>
  left_join(env, by = "team")

OUT_STATUS <- c("IR","IR-R","O","NA","SUSP","PUP","NFI")

flex <- p |>
  filter(pos %in% c("RB","WR","TE"), !(status %in% OUT_STATUS)) |>
  mutate(opp_ct = coalesce(rush_att,0) + coalesce(tgt,0),
         touch_share_pts = fan_pts)

etienne <- flex |> filter(player == "Travis Etienne Jr.")
cat("\n=== REPLACEMENT BASELINE ===\n")
etienne |> select(player, nfl_team, opp_ct, rush_att, tgt, rec, fan_pts, implied, spread) |> print(width=200)

cat("\n=== FREE AGENTS beating Etienne on opportunity (FLEX-eligible) ===\n")
flex |>
  filter(roster_status == "FA" | startsWith(roster_status, "W (")) |>
  filter(opp_ct >= 8) |>
  arrange(desc(opp_ct), desc(implied)) |>
  select(player, pos, nfl_team, roster_status, status, opp_ct, rush_att, tgt,
         rec, fan_pts, pct_rostered, implied, spread) |>
  print(n = 30, width = 250)

cat("\n=== FA with implied >= 24 AND opp_ct >= 6 (best environment) ===\n")
flex |>
  filter(roster_status == "FA" | startsWith(roster_status, "W (")) |>
  filter(implied >= 24, opp_ct >= 6) |>
  arrange(desc(implied)) |>
  select(player, pos, nfl_team, roster_status, opp_ct, tgt, fan_pts,
         pct_rostered, implied, spread) |>
  print(n = 25, width = 250)
