# Week 3 waiver candidate pool.
#
# Builds the evaluation half of a waiver scan from nflreadr alone. The
# availability half -- who is actually a free agent in league #1541392 -- is
# Yahoo-only and must be pasted in; see JOIN, bottom.
#
# Ranks on OPPORTUNITY, not points. Repo principle: opportunity is sticky year
# to year, efficiency is mostly noise. A player who saw 18 touches and scored 4
# is a better add than one who saw 5 and scored 14, and the second is how
# waiver wires get lost.
#
# Writes: data/weekly/2026_week03_candidates.csv
suppressMessages({library(dplyr); library(tidyr)})
options(nflreadr.verbose = FALSE)
source("R/00_config.R"); source("R/30_scoring.R")

SEASON <- 2026
THRU   <- 2      # weeks played
scoring <- load_config("scoring")

stats <- as.data.frame(nflreadr::load_player_stats(SEASON)) |>
  filter(week <= THRU, position %in% c("QB", "RB", "WR", "TE"))
stats$fp <- score_player_week(stats, scoring)

snaps <- as.data.frame(nflreadr::load_snap_counts(SEASON)) |>
  filter(week <= THRU) |>
  select(player, team, week, offense_snaps, offense_pct)

# ---- per-week, then collapse -------------------------------------------------
wk <- stats |>
  transmute(gsis_id = player_id, player = player_display_name, pos = position,
            team, week, fp,
            car = coalesce(carries, 0), tgt = coalesce(targets, 0),
            rec = coalesce(receptions, 0),
            yds = coalesce(rushing_yards, 0) + coalesce(receiving_yards, 0),
            td  = coalesce(rushing_tds, 0) + coalesce(receiving_tds, 0),
            opp = car + tgt)

# team pass/rush volume -> share, the denominators that make opp comparable
team_vol <- wk |> group_by(team, week) |>
  summarise(team_tgt = sum(tgt), team_car = sum(car), .groups = "drop")

wk <- wk |> left_join(team_vol, by = c("team", "week")) |>
  mutate(tgt_share = ifelse(team_tgt > 0, tgt / team_tgt, NA_real_),
         car_share = ifelse(team_car > 0, car / team_car, NA_real_))

# snap share joins on NAME -- load_snap_counts() carries no gsis_id. Allowed
# under the CLAUDE.md rule only because name is all this source gives; match
# rate is reported below and must be watched.
wk <- wk |> left_join(snaps, by = c("player", "team", "week"))
match_rate <- mean(!is.na(wk$offense_pct))

pool <- wk |> group_by(gsis_id, player, pos, team) |>
  summarise(
    g = n(),
    opp_tot = sum(opp), opp_pg = mean(opp),
    tgt_tot = sum(tgt), car_tot = sum(car),
    tgt_share = mean(tgt_share, na.rm = TRUE),
    car_share = mean(car_share, na.rm = TRUE),
    snap_pct  = mean(offense_pct, na.rm = TRUE),
    fp_tot = sum(fp), fp_pg = mean(fp),
    yds = sum(yds), td = sum(td),
    .groups = "drop") |>
  # trend: is the role growing or shrinking? wk2 minus wk1, NA if one game.
  left_join(
    wk |> select(gsis_id, week, opp) |>
      pivot_wider(names_from = week, values_from = opp, names_prefix = "opp_w") |>
      mutate(opp_trend = opp_w2 - opp_w1) |> select(gsis_id, opp_trend),
    by = "gsis_id") |>
  arrange(desc(opp_pg))

# Efficiency flag, POSITION-RELATIVE. A single fp/opp threshold is wrong:
# an RB carry is worth ~0.4 pts in half-PPR and a WR target ~1.2, so a flat
# cut labels every healthy RB "inefficient". First pass did exactly that and
# tagged Kenneth Walker (26.7 fp/g) a buy. Compare each player to the median
# of his own position instead, and score opportunity the same way.
pool <- pool |>
  mutate(fp_per_opp = ifelse(opp_tot > 0, fp_tot / opp_tot, NA_real_)) |>
  group_by(pos) |>
  mutate(
    opp_pctl = ifelse(is.na(opp_pg), NA_real_, percent_rank(opp_pg)),
    eff_rel  = fp_per_opp / stats::median(fp_per_opp[opp_tot >= 5], na.rm = TRUE)
  ) |>
  ungroup() |>
  mutate(profile = case_when(
    is.na(eff_rel)                   ~ "-",
    opp_pctl >= 0.80 & eff_rel < 0.85 ~ "BUY  volume, results lagging",
    opp_pctl >= 0.80                  ~ "hold volume + results",
    opp_pctl <  0.50 & eff_rel > 1.30 ~ "FADE points on no volume",
    TRUE                              ~ "-"))

dir.create("data/weekly", showWarnings = FALSE, recursive = TRUE)
out <- "data/weekly/2026_week03_candidates.csv"
write.csv(pool, out, row.names = FALSE)

cat(sprintf("\n=== pool: %d players thru wk %d | snap-name match %.1f%% -> %s\n",
            nrow(pool), THRU, 100 * match_rate, out))
cat("\n=== top 25 by opportunity/game (NOT filtered to free agents yet)\n")
pool |> filter(g >= 1) |> head(25) |>
  select(player, pos, team, g, opp_pg, tgt_share, car_share, snap_pct,
         fp_pg, opp_trend, profile) |>
  as.data.frame() |> print(digits = 2, row.names = FALSE)

cat("\n=== BUY profile: volume without results (regression in our favor)\n")
pool |> filter(profile == "BUY  volume, results lagging", opp_pg >= 8) |> head(20) |>
  select(player, pos, team, opp_pg, opp_pctl, snap_pct, fp_pg, eff_rel, opp_trend) |>
  as.data.frame() |> print(digits = 2, row.names = FALSE)

# ---- JOIN --------------------------------------------------------------------
# Once the Yahoo free-agent export lands in docs/uploads/week_2_data/:
#   fa <- read.csv("docs/uploads/week_2_data/<file>")
#   fa$key <- normalize_player_name(fa$Player)      # R/96_yahoo_names.R
#   pool$key <- normalize_player_name(pool$player)
#   avail <- semi_join(pool, fa, by = "key")
# Report the match rate at the point of use. Name join is forced here: Yahoo
# exports carry no gsis_id, and yahoo_id is 100% NA in our pool.
