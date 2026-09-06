#' Expected fantasy points from nflreadr::load_ff_opportunity().
#'
#' CLAUDE.md's core modeling principle: "opportunity is sticky year to year,
#' efficiency is mostly noise." ff_opportunity decomposes each play into what a
#' league-average player would have produced given the same opportunity (a
#' target, a carry) versus what actually happened -- ranking on the expected
#' side is strictly better signal than ranking on realized points, which is
#' all `R/30_scoring.R` + `R/75_value.R` do today.
#'
#' This file does NOT re-score anything. `score_player_week()` is already a
#' pure function of (stat line, scoring config); the only new work here is
#' mapping ff_opportunity's `_exp` columns onto the input-column names that
#' function already expects, then reusing it unchanged.

#' Map ff_opportunity's `_exp` stat columns onto score_player_week()'s input
#' names and join to dim_player for player_key -- never by name.
#'
#' Column mapping (ff_opportunity -> score_player_week input):
#'   pass_yards_gained_exp   -> passing_yards
#'   pass_touchdown_exp      -> passing_tds
#'   pass_interception_exp   -> passing_interceptions
#'   pass_two_point_conv_exp -> passing_2pt_conversions
#'   rush_yards_gained_exp   -> rushing_yards
#'   rush_touchdown_exp      -> rushing_tds
#'   rush_first_down_exp     -> rushing_first_downs
#'   rush_two_point_conv_exp -> rushing_2pt_conversions
#'   receptions_exp          -> receptions
#'   rec_yards_gained_exp    -> receiving_yards
#'   rec_touchdown_exp       -> receiving_tds
#'   rec_two_point_conv_exp  -> receiving_2pt_conversions
#'
#' Deliberately NOT mapped: fumbles and kicking. ff_opportunity has no `_exp`
#' fumble column at all (`rec_fumble_lost`/`rush_fumble_lost` are actual-only)
#' -- a fumble isn't an "opportunity" in this model's sense, there's no
#' league-average fumble rate assigned to a play, so score_player_week()'s
#' fumble term is always zero on this table, which is correct, not a gap.
#' Kicking is out of scope entirely: ff_opportunity only models pass/rush/rec
#' plays. The rare K row in the raw data is a trick-play rush/pass attempt,
#' not kicking production (verified live, 2025 wk15), so K is dropped along
#' with defensive/O-line noise (DB/DL/LB/OL/P) the same way
#' `build_fct_player_week()` drops non-skill positions.
#'
#' Also drops postseason weeks. Unlike `load_player_stats()`, ff_opportunity
#' carries no `season_type` column to filter on -- weeks run 1-22 with
#' playoffs unmarked, so the cutoff is the NFL's own 18-week regular season
#' (week <= 18), matching what `season_type == "REG"` means everywhere else
#' in this pipeline.
#'
#' @param ff_opportunity_path Raw parquet from ingest_ff_opportunity().
#' @param dim_player data.table from build_dim_player().
#' @return data.table, one row per (player_key, season, week): player_key,
#'   player_id, full_name, position, season, week, plus the mapped stat
#'   columns above, ready to pass straight to score_player_week(). Rows with
#'   no crosswalk match get `player_key = NA` rather than being dropped or
#'   matched by name (mirrors `build_fct_player_week()`).
build_expected_stat_lines <- function(ff_opportunity_path, dim_player) {
  opp <- as.data.frame(arrow::read_parquet(ff_opportunity_path))
  opp <- opp[!is.na(opp$player_id), ]
  opp <- opp[opp$week <= 18, ]

  skill_positions <- c("QB", "RB", "WR", "TE")
  opp <- opp[opp$position %in% skill_positions, ]

  crosswalk <- dim_player[, c("player_key", "gsis_id")]
  stat_lines <- merge(opp, crosswalk, by.x = "player_id", by.y = "gsis_id", all.x = TRUE, sort = FALSE)

  exp_map <- c(
    pass_yards_gained_exp   = "passing_yards",
    pass_touchdown_exp      = "passing_tds",
    pass_interception_exp   = "passing_interceptions",
    pass_two_point_conv_exp = "passing_2pt_conversions",
    rush_yards_gained_exp   = "rushing_yards",
    rush_touchdown_exp      = "rushing_tds",
    rush_first_down_exp     = "rushing_first_downs",
    rush_two_point_conv_exp = "rushing_2pt_conversions",
    receptions_exp          = "receptions",
    rec_yards_gained_exp    = "receiving_yards",
    rec_touchdown_exp       = "receiving_tds",
    rec_two_point_conv_exp  = "receiving_2pt_conversions"
  )
  for (src in names(exp_map)) {
    stat_lines[[exp_map[[src]]]] <- if (src %in% colnames(stat_lines)) stat_lines[[src]] else NA_real_
  }

  front_cols <- c("player_key", "player_id", "full_name", "position", "season", "week")
  keep_cols <- c(front_cols, unname(exp_map))
  stat_lines[, intersect(keep_cols, colnames(stat_lines))]
}

#' Score the mapped expected stat lines under the league's scoring config.
#'
#' Thin wrapper, not a second scoring engine: calls the exact same
#' `score_player_week()` used for actual points in `R/30_scoring.R`, on the
#' expected stat line instead of the realized one.
#'
#' @param expected_stat_lines data.table from build_expected_stat_lines().
#' @param scoring Parsed scoring config (list), e.g. `load_config("scoring")`.
#' @return `expected_stat_lines` with one added column, `fantasy_points_exp`.
add_expected_fantasy_points <- function(expected_stat_lines, scoring) {
  expected_stat_lines$fantasy_points_exp <- score_player_week(expected_stat_lines, scoring)
  expected_stat_lines
}

#' Per-player season aggregates of expected vs. actual fantasy points.
#'
#' This is the ranking signal CLAUDE.md's core principle argues for: expected
#' points (opportunity) are sticky year to year, actual points are noisier
#' because touchdown/efficiency luck washes in and out week to week.
#' `points_diff` follows ff_opportunity's own sign convention (actual minus
#' expected, verified live against `total_fantasy_points_diff`): a large
#' positive diff means a player outscored the opportunity he was given --
#' a touchdown-regression risk -- and a large negative diff means the volume
#' is there but the score hasn't caught up (a buy-low signal).
#'
#' @param expected_stat_lines_scored data.table from add_expected_fantasy_points().
#' @param fct_player_week_scored data.table from add_fantasy_points() (actual
#'   points), with a `season_type` column -- only "REG" rows count, matching
#'   the regular-season-only filter already used in `build_player_value()`.
#' @param season Season to aggregate.
#' @return data.table, one row per player_key: points_exp, games_exp,
#'   points_actual, points_diff. A player present on only one side gets 0,
#'   not NA, on the missing side.
build_player_opportunity_value <- function(expected_stat_lines_scored, fct_player_week_scored, season) {
  exp_season <- expected_stat_lines_scored[expected_stat_lines_scored$season == season, ]
  actual_season <- fct_player_week_scored[fct_player_week_scored$season == season &
                                             fct_player_week_scored$season_type == "REG", ]

  # aggregate() errors on a zero-row input rather than returning an empty
  # result -- same guard as build_player_value() in R/75_value.R, needed for
  # real when a season has no rows yet on one side (e.g. before kickoff).
  empty <- function(cols) setNames(data.frame(matrix(nrow = 0, ncol = length(cols))), cols)

  if (nrow(exp_season) == 0) {
    exp_agg <- empty(c("player_key", "points_exp", "games_exp"))
  } else {
    pts <- aggregate(fantasy_points_exp ~ player_key, data = exp_season, FUN = sum)
    names(pts)[2] <- "points_exp"
    games <- aggregate(fantasy_points_exp ~ player_key, data = exp_season, FUN = length)
    names(games)[2] <- "games_exp"
    exp_agg <- merge(pts, games, by = "player_key")
  }

  if (nrow(actual_season) == 0) {
    actual_agg <- empty(c("player_key", "points_actual"))
  } else {
    actual_agg <- aggregate(fantasy_points ~ player_key, data = actual_season, FUN = sum)
    names(actual_agg)[2] <- "points_actual"
  }

  result <- merge(exp_agg, actual_agg, by = "player_key", all = TRUE)
  result$points_exp <- ifelse(is.na(result$points_exp), 0, result$points_exp)
  result$points_actual <- ifelse(is.na(result$points_actual), 0, result$points_actual)
  result$games_exp <- ifelse(is.na(result$games_exp), 0, result$games_exp)
  result$points_diff <- result$points_actual - result$points_exp
  result
}
