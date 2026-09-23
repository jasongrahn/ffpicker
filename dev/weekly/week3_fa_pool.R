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

# ---- AVAILABILITY ------------------------------------------------------------
# Ownership comes from the Yahoo players manifest, NOT a separate FA export.
# `roster_status` holds the owning team name, or "FA". All 10 teams appear.
#
# Two limits inherited from how the manifest is built:
#   * QB/RB/WR/TE only -- it comes from the position pages, so there is no K
#     or DST ownership. Teams show 11-13 of 15 players; the gap is K + DST.
#   * It is a point-in-time snapshot. Waivers move it. Check the file date
#     against the week being planned before trusting it.
source("dev/weekly/read_yahoo_week.R")

YAHOO_DIR <- Sys.getenv("FF_YAHOO_DIR", "docs/uploads/week_3_data")

if (!dir.exists(YAHOO_DIR)) {
  cat("\n=== no Yahoo export dir at", YAHOO_DIR, "-- pool written, availability skipped\n")
} else {
  yh <- attach_nfl_ids(read_yahoo_week(YAHOO_DIR))

  cat(sprintf("\n=== ownership from %s (%s), %d rows\n", YAHOO_DIR,
              format(max(file.mtime(list.files(YAHOO_DIR, full.names = TRUE))), "%Y-%m-%d"),
              nrow(yh)))
  print(sort(table(yh$owner), decreasing = TRUE))
  cat("\njoin method:\n"); print(table(yh$method, useNA = "ifany"))

  # Every unresolved row should be a team DEF, which has no player id at all.
  # Anything else unresolved is a real failure and must not pass quietly.
  unresolved <- yh[is.na(yh$gsis_id) & !is.na(yh$proj) & yh$proj >= 5, ]
  bad <- unresolved[unresolved$pos != "DEF", ]
  if (nrow(bad)) {
    warning(nrow(bad), " non-DEF player(s) with proj >= 5 failed to resolve to a gsis_id.")
    cat("\n!!! UNRESOLVED NON-DEF PLAYERS -- check by hand\n")
    print(as.data.frame(bad[order(-bad$proj), c("player", "pos", "yteam", "owner", "proj")]),
          row.names = FALSE)
  } else {
    cat(sprintf("\nresolved: every non-DEF player with proj >= 5 (%d) has a gsis_id\n",
                sum(!is.na(yh$proj) & yh$proj >= 5 & yh$pos != "DEF")))
  }

  # gsis_id join -- surrogate key, no names involved on this side.
  fa <- yh[yh$owner == "FA" & yh$pos %in% c("QB", "RB", "WR", "TE") & !is.na(yh$gsis_id), ]
  avail <- inner_join(
    fa[, c("gsis_id", "player", "pos", "yteam", "proj", "pct_ros", "injury", "game")],
    pool, by = "gsis_id", suffix = c("", ".nfl"))

  cat(sprintf("\n=== FA (QB/RB/WR/TE, id-resolved) %d -> joined to pool %d (%.1f%%)\n",
              nrow(fa), nrow(avail), 100 * nrow(avail) / nrow(fa)))
  cat("    (misses are players with no week 1-2 stat line -- no opportunity to buy)\n")

  cat("\n=== TOP 20 FREE AGENTS BY OPPORTUNITY/GAME\n")
  avail |> arrange(desc(opp_pg)) |> head(20) |>
    transmute(player, pos, tm = yteam, opp_pg = round(opp_pg, 1),
              snap = round(snap_pct, 2), fp_pg = round(fp_pg, 1),
              trend = opp_trend, w3proj = proj, rost = pct_ros, profile) |>
    as.data.frame() |> print(row.names = FALSE)

  cat("\n=== FA BUY list: top-quintile opportunity, results lagging\n")
  b <- avail |> filter(profile == "BUY  volume, results lagging") |> arrange(desc(opp_pg))
  if (nrow(b)) {
    b |> head(10) |>
      transmute(player, pos, tm = yteam, opp_pg = round(opp_pg, 1),
                snap = round(snap_pct, 2), fp_pg = round(fp_pg, 1),
                eff_rel = round(eff_rel, 2), w3proj = proj, rost = pct_ros) |>
      as.data.frame() |> print(row.names = FALSE)
  } else cat("  none\n")

  write.csv(avail, "data/weekly/2026_week03_free_agents.csv", row.names = FALSE)
  write.csv(yh[yh$owner != "FA", c("player", "pos", "yteam", "owner", "proj", "gsis_id")],
            "data/weekly/2026_week03_rosters.csv", row.names = FALSE)
  cat("\n-> data/weekly/2026_week03_free_agents.csv\n")
  cat("-> data/weekly/2026_week03_rosters.csv  (all 10 opponent rosters)\n")
}
