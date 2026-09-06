#' Build dim_player: one row per real NFL player, keyed by a surrogate key.
#'
#' Crosswalks load_ff_playerids() (cross-platform ids, including yahoo_id) to
#' load_players() (canonical bio/name) on gsis_id. Never joins on name --
#' names collide and roster churn breaks it mid-season.
#'
#' Players without a gsis_id (unsigned prospects, practice-squad-only) are
#' dropped: fct_player_week only ever needs players who have game stats, and
#' game stats are keyed on gsis_id.
#'
#' @param ff_playerids_path Raw parquet from ingest_ff_playerids().
#' @param players_path Raw parquet from ingest_players().
#' @return data.table, one row per gsis_id, with an integer surrogate key `player_key`.
build_dim_player <- function(ff_playerids_path, players_path) {
  # as.data.frame() strips the data.table class tag arrow round-trips from
  # parquet metadata -- otherwise `[.data.table` dispatch (active whenever the
  # data.table package is attached, e.g. via targets) breaks these subsets.
  ids <- as.data.frame(arrow::read_parquet(ff_playerids_path))
  players <- as.data.frame(arrow::read_parquet(players_path))

  ids <- ids[!is.na(ids$gsis_id), ]
  ids <- ids[!duplicated(ids$gsis_id), ]

  # draft_year/draft_round/draft_pick are already present on `ids` (from
  # ff_playerids) -- taken from there, not duplicated from `players`, to avoid
  # a merge-suffix collision.
  bio_cols <- c("gsis_id", "display_name", "position", "birth_date",
                "college_name", "latest_team", "status")
  players_bio <- players[, intersect(bio_cols, colnames(players))]

  dim <- merge(ids, players_bio, by = "gsis_id", all.x = TRUE, sort = FALSE)
  dim <- dim[order(dim$gsis_id), ]
  dim$player_key <- seq_len(nrow(dim))

  keep_cols <- c("player_key", "gsis_id", "display_name", "name", "position.x", "position.y",
                 "team", "yahoo_id", "sleeper_id", "espn_id", "fantasypros_id",
                 "birth_date", "draft_year", "draft_round", "draft_pick", "draft_ovr",
                 "college_name", "latest_team", "status")
  dim <- dim[, intersect(keep_cols, colnames(dim))]

  # position.y (from load_players, canonical) wins over position.x (from ff_playerids)
  if ("position.y" %in% colnames(dim)) {
    dim$position <- ifelse(is.na(dim$position.y), dim$position.x, dim$position.y)
    dim$position.x <- NULL
    dim$position.y <- NULL
  }
  if ("display_name" %in% colnames(dim)) {
    dim$display_name <- ifelse(is.na(dim$display_name), dim$name, dim$display_name)
  } else {
    dim$display_name <- dim$name
  }
  dim$name <- NULL

  dim
}

#' Build fct_player_week: weekly box scores keyed to dim_player's surrogate key.
#'
#' @param player_stats_path Raw parquet from ingest_player_stats().
#' @param dim_player data.table from build_dim_player().
#' @return data.table, one row per (player_key, season, week).
build_fct_player_week <- function(player_stats_path, dim_player) {
  stats <- as.data.frame(arrow::read_parquet(player_stats_path))
  stats <- stats[!is.na(stats$player_id), ]

  # Only QB/RB/WR/TE/K score in this format (CLAUDE.md); player_stats also
  # carries occasional defensive/special-teams lines for O-linemen and long
  # snappers (a fumble recovery, a blocked kick), who were never fantasy-
  # relevant and were never in the ff_playerids crosswalk to begin with.
  # DST is scored at the team level, not from individual player rows, so it
  # isn't part of this fact table.
  skill_positions <- c("QB", "RB", "WR", "TE", "K")
  stats <- stats[stats$position %in% skill_positions, ]

  crosswalk <- dim_player[, c("player_key", "gsis_id")]
  fct <- merge(stats, crosswalk, by.x = "player_id", by.y = "gsis_id", all.x = TRUE, sort = FALSE)

  front_cols <- c("player_key", "player_id", "player_display_name", "position", "team", "season", "week", "season_type")
  other_cols <- setdiff(colnames(fct), front_cols)
  fct[, c(intersect(front_cols, colnames(fct)), other_cols)]
}

#' Validate dim_player: surrogate key and gsis_id must each be unique and non-null.
#'
#' Fails loudly (stop()) on any violation, per the project rule that a bad
#' table should never reach a model fit silently.
#'
#' @param dim data.table from build_dim_player().
validate_dim_player <- function(dim) {
  agent <- pointblank::create_agent(dim) |>
    pointblank::col_vals_not_null(pointblank::vars(gsis_id, player_key)) |>
    pointblank::rows_distinct(pointblank::vars(player_key)) |>
    pointblank::rows_distinct(pointblank::vars(gsis_id)) |>
    pointblank::interrogate()

  if (!pointblank::all_passed(agent)) {
    stop("dim_player failed validation:\n", paste(capture.output(print(agent)), collapse = "\n"))
  }
  invisible(dim)
}

#' Validate fct_player_week: grain must be unique, and crosswalk join loss
#' (player_key NA -> gsis_id present in stats but not in dim_player) must
#' stay under 2%, since a bigger gap signals the crosswalk itself is broken
#' rather than a handful of edge cases (e.g. a player retiring mid-crosswalk-refresh).
#'
#' @param fct data.table from build_fct_player_week().
validate_fct_player_week <- function(fct) {
  agent <- pointblank::create_agent(fct) |>
    pointblank::col_vals_not_null(pointblank::vars(player_id, season, week)) |>
    # grain is checked on player_id (native gsis_id, always non-null here),
    # not player_key: a handful of crosswalk-unmatched rows would otherwise
    # collide on the shared NA key and register as false-positive duplicates.
    pointblank::rows_distinct(pointblank::vars(player_id, season, week, season_type)) |>
    pointblank::interrogate()

  if (!pointblank::all_passed(agent)) {
    stop("fct_player_week failed validation:\n", paste(capture.output(print(agent)), collapse = "\n"))
  }

  unmatched_rate <- mean(is.na(fct$player_key))
  if (unmatched_rate > 0.02) {
    stop(sprintf(
      "fct_player_week: %.1f%% of rows failed to join to dim_player via gsis_id (>2%% threshold). Crosswalk is likely stale.",
      unmatched_rate * 100
    ))
  }

  invisible(fct)
}
