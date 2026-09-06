#' Ingest nflverse sources to raw parquet.
#'
#' Each function pulls one nflreadr source and writes it to data/raw/ verbatim
#' (no joins, no renaming) so raw is a faithful cache of the upstream API.
#' Downstream stage code is what applies structure.

#' @param seasons Integer vector of NFL seasons to pull.
#' @param raw_dir Output directory for raw parquet.
#' @return Path to the written parquet file.
ingest_player_stats <- function(seasons = 2015:nflreadr::most_recent_season(),
                                 raw_dir = "data/raw") {
  dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)
  path <- file.path(raw_dir, "player_stats.parquet")
  stats <- nflreadr::load_player_stats(seasons = seasons)
  arrow::write_parquet(stats, path)
  path
}

#' @param raw_dir Output directory for raw parquet.
#' @return Path to the written parquet file.
ingest_ff_playerids <- function(raw_dir = "data/raw") {
  dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)
  path <- file.path(raw_dir, "ff_playerids.parquet")
  ids <- nflreadr::load_ff_playerids()
  arrow::write_parquet(ids, path)
  path
}

#' @param raw_dir Output directory for raw parquet.
#' @return Path to the written parquet file.
ingest_players <- function(raw_dir = "data/raw") {
  dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)
  path <- file.path(raw_dir, "players.parquet")
  players <- nflreadr::load_players()
  arrow::write_parquet(players, path)
  path
}

#' Draft-day ECR/ADP rankings. Refreshes daily -- re-run close to draft day.
#' Written unfiltered (all page_types: redraft, dynasty, best-ball, IDP, etc);
#' filtering to the standard redraft slice happens in the stage layer.
#'
#' @param raw_dir Output directory for raw parquet.
#' @return Path to the written parquet file.
ingest_ff_rankings <- function(raw_dir = "data/raw") {
  dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)
  path <- file.path(raw_dir, "ff_rankings.parquet")
  rankings <- nflreadr::load_ff_rankings(type = "draft")
  arrow::write_parquet(rankings, path)
  path
}
