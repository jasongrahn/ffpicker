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

#' Weekly snap counts. In-season only -- these are the participation numbers
#' that turn a stat line into a role, and role is what carries week to week.
#' Joins on `pfr_id`, not gsis_id: this is the one nflverse weekly feed that
#' carries no gsis_id at all.
#'
#' @param seasons Integer vector of NFL seasons to pull.
#' @param raw_dir Output directory for raw parquet.
#' @return Path to the written parquet file.
ingest_snap_counts <- function(seasons = nflreadr::most_recent_season(),
                                raw_dir = "data/raw") {
  dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)
  path <- file.path(raw_dir, "snap_counts.parquet")
  snaps <- nflreadr::load_snap_counts(seasons = seasons)
  arrow::write_parquet(snaps, path)
  path
}

#' Weekly injury reports. `report_status` is the game-status designation
#' (Out / Doubtful / Questionable / NA), which is the field a start/sit
#' decision actually turns on.
#'
#' @param seasons Integer vector of NFL seasons to pull.
#' @param raw_dir Output directory for raw parquet.
#' @return Path to the written parquet file.
ingest_injuries <- function(seasons = nflreadr::most_recent_season(),
                             raw_dir = "data/raw") {
  dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)
  path <- file.path(raw_dir, "injuries.parquet")
  inj <- nflreadr::load_injuries(seasons = seasons)
  arrow::write_parquet(inj, path)
  path
}

#' Weekly expected-vs-actual fantasy points (nflreadr's ffopportunity model).
#' Decomposes production into opportunity (expected) and efficiency (actual
#' minus expected) -- see R/40_opportunity.R for what consumes this and why.
#'
#' @param seasons Integer vector of NFL seasons to pull.
#' @param raw_dir Output directory for raw parquet.
#' @return Path to the written parquet file.
ingest_ff_opportunity <- function(seasons = 2015:nflreadr::most_recent_season(),
                                   raw_dir = "data/raw") {
  dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)
  path <- file.path(raw_dir, "ff_opportunity.parquet")
  opp <- nflreadr::load_ff_opportunity(seasons = seasons, stat_type = "weekly")
  arrow::write_parquet(opp, path)
  path
}
