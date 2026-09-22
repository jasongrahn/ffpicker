# Week 2 game environment: Vegas-implied team totals for the roster.
# spread_line in nflreadr is the HOME team's spread (positive = home favored).
# implied team total = total_line/2 + team_spread/2
suppressMessages({library(nflreadr); library(dplyr); library(tidyr)})

sched <- load_schedules(2026) |>
  filter(week == 2) |>
  select(game_id, gameday, weekday, gametime, away_team, home_team,
         spread_line, total_line, away_moneyline, home_moneyline, roof, temp, wind)

# long: one row per team per game
env <- bind_rows(
  sched |> transmute(team = home_team, opp = away_team, site = "home",
                     spread = spread_line, total_line, gameday, gametime,
                     moneyline = home_moneyline, roof, temp, wind),
  sched |> transmute(team = away_team, opp = home_team, site = "away",
                     spread = -spread_line, total_line, gameday, gametime,
                     moneyline = away_moneyline, roof, temp, wind)
) |>
  mutate(implied_total = total_line / 2 + spread / 2,
         opp_implied   = total_line / 2 - spread / 2,
         favored       = spread > 0)

# Yahoo abbreviations -> nflreadr
yh <- c(LAR="LA", KC="KC", Dal="DAL", Bal="BAL", NO="NO", TB="TB", Hou="HOU",
        NYG="NYG", Chi="CHI", Den="DEN", Ten="TEN", NE="NE")
if (!all(yh %in% env$team)) yh["LAR"] <- "LAR"   # nflreadr flips LA/LAR by year

roster <- tibble::tribble(
  ~player,              ~pos,  ~yteam, ~proj,  ~slot,
  "Matthew Stafford",   "QB",  "LAR",  18.22,  "QB",
  "Patrick Mahomes",    "QB",  "KC",   18.53,  "BN",
  "Javonte Williams",   "RB",  "Dal",  15.75,  "RB",
  "Derrick Henry",      "RB",  "Bal",  15.52,  "RB",
  "Travis Etienne Jr.", "RB",  "NO",    9.41,  "FLEX",
  "Kenny Gainwell",     "RB",  "TB",    8.01,  "BN",
  "Woody Marks",        "RB",  "Hou",   7.43,  "BN",
  "Tyrone Tracy Jr.",   "RB",  "NYG",   1.81,  "BN",
  "Davante Adams",      "WR",  "LAR",  10.02,  "WR",
  "Rome Odunze",        "WR",  "Chi",   8.64,  "WR",
  "Courtland Sutton",   "WR",  "Den",   8.98,  "BN",
  "Wan'Dale Robinson",  "WR",  "Ten",   6.96,  "BN",
  "Jake Ferguson",      "TE",  "Dal",   8.11,  "TE",
  "Chase McLaughlin",   "K",   "TB",    7.69,  "K",
  "Patriots",           "DEF", "NE",    6.86,  "DEF"
) |> mutate(team = unname(yh[yteam]))

out <- roster |>
  left_join(env, by = "team") |>
  arrange(desc(implied_total)) |>
  mutate(line = sprintf("%+.1f", spread))

cat("\n=== Week 2 game environment, by implied team total ===\n")
out |>
  select(slot, player, pos, yteam, opp, site, line, total_line,
         implied_total, opp_implied, proj) |>
  print(n = 20, width = 200)

cat("\n=== All 16 games, by total ===\n")
sched |>
  mutate(fav = ifelse(spread_line > 0, home_team, away_team),
         by  = abs(spread_line)) |>
  arrange(desc(total_line)) |>
  select(away_team, home_team, fav, by, total_line, gameday) |>
  print(n = 16)
