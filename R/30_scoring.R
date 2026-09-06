#' Score a table of player-week stat lines under a league's scoring config.
#'
#' Pure and vectorized: output depends only on (stats, scoring), with no
#' hidden state. This is what lets every historical season be recomputed
#' under the league's exact rules instead of training on generic PPR.
#'
#' DST is intentionally out of scope: Yahoo scores defense/special teams at
#' the team level (points allowed, sacks, turnovers), not from individual
#' player rows, so it needs a separate team-level stat source, not this
#' per-player function.
#'
#' @param stats data.frame with nflverse `load_player_stats()` columns, one
#'   row per player-week. Must include `position`.
#' @param scoring Parsed scoring config (list), e.g. `load_config("scoring")`.
#' @return Numeric vector of fantasy points, one per row of `stats`.
score_player_week <- function(stats, scoring) {
  n0 <- function(x) ifelse(is.na(x), 0, x)
  col <- function(name) if (name %in% colnames(stats)) n0(stats[[name]]) else numeric(nrow(stats))

  pts <- numeric(nrow(stats))

  # passing
  pts <- pts + col("passing_yards") * scoring$passing$yards
  pts <- pts + col("passing_tds") * scoring$passing$td
  pts <- pts + col("passing_interceptions") * scoring$passing$int
  for (bonus in scoring$passing$bonus) {
    stat_col <- col(paste0("passing_", bonus$stat))
    pts <- pts + (stat_col >= bonus$gte) * bonus$points
  }

  # rushing
  pts <- pts + col("rushing_yards") * scoring$rushing$yards
  pts <- pts + col("rushing_tds") * scoring$rushing$td
  if (!is.null(scoring$rushing$first_down)) {
    pts <- pts + col("rushing_first_downs") * scoring$rushing$first_down
  }

  # receiving, with position-specific premium on the reception itself (e.g. TE premium)
  premium_map <- scoring$receiving$position_premium
  premium <- if (length(premium_map) > 0) {
    vals <- setNames(as.numeric(unlist(premium_map)), names(premium_map))
    idx <- match(stats$position, names(vals))
    ifelse(is.na(idx), 0, vals[idx])
  } else {
    numeric(nrow(stats))
  }
  pts <- pts + col("receptions") * (scoring$receiving$reception + premium)
  pts <- pts + col("receiving_yards") * scoring$receiving$yards
  pts <- pts + col("receiving_tds") * scoring$receiving$td

  # misc
  fumbles_lost <- col("sack_fumbles_lost") + col("rushing_fumbles_lost") + col("receiving_fumbles_lost")
  pts <- pts + fumbles_lost * scoring$misc$fumble_lost
  two_point <- col("passing_2pt_conversions") + col("rushing_2pt_conversions") + col("receiving_2pt_conversions")
  pts <- pts + two_point * scoring$misc$two_point

  # kicking: player_stats buckets field goals more finely (10-yard bands)
  # than most scoring configs, so bands are summed up into the config's tiers.
  fg_0_39_made <- col("fg_made_0_19") + col("fg_made_20_29") + col("fg_made_30_39")
  fg_40_49_made <- col("fg_made_40_49")
  fg_50_plus_made <- col("fg_made_50_59") + col("fg_made_60_")
  fg_missed <- col("fg_missed") + col("fg_blocked")

  pts <- pts + fg_0_39_made * scoring$kicking$fg_0_39
  pts <- pts + fg_40_49_made * scoring$kicking$fg_40_49
  pts <- pts + fg_50_plus_made * scoring$kicking$fg_50_plus
  pts <- pts + fg_missed * scoring$kicking$fg_miss
  pts <- pts + col("pat_made") * scoring$kicking$pat_made
  pts <- pts + (col("pat_missed") + col("pat_blocked")) * scoring$kicking$pat_miss

  pts
}

#' Add a `fantasy_points` column to a player-week stat table.
#'
#' @param stats data.frame with nflverse `load_player_stats()` columns.
#' @param scoring Parsed scoring config (list).
#' @return `stats` with one added column, `fantasy_points`.
add_fantasy_points <- function(stats, scoring) {
  stats$fantasy_points <- score_player_week(stats, scoring)
  stats
}
