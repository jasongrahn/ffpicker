#' Build the 2026 draft-relevant player pool from FantasyPros redraft rankings.
#'
#' load_ff_rankings() returns every page_type FantasyPros publishes (best-ball,
#' dynasty, IDP, ...) mixed into one table. "redraft-overall" is the standard
#' season-long slice this league actually drafts under.
#'
#' Crosswalked to dim_player via FantasyPros' own id (dim_player$fantasypros_id,
#' sourced from load_ff_playerids()) -- not yahoo_id, which is NA on this
#' page_type, and never by name.
#'
#' DST is dropped: it's scored at the team level in Yahoo, not from individual
#' player rows, and was never part of dim_player to begin with.
#'
#' `sd`/`best`/`worst`/`rank_delta` ride along beside `ecr`. FantasyPros'
#' ECR is the mean of many analysts' ranks; those four describe the spread
#' around it -- how much the experts disagree about a player. A rookie with
#' no NFL games has no stat line to project from, so that disagreement is
#' the only measure of confidence available for him, and R/77_consensus.R
#' turns it into a value estimate. Carried here rather than re-read from the
#' parquet downstream, so the pool stays the single source of ranking truth.
#'
#' @param ff_rankings_path Raw parquet from ingest_ff_rankings().
#' @param dim_player data.table from build_dim_player().
#' @return data.table, one row per draftable player: player_key, player, pos,
#'   team, ecr, sd, best, worst, rank_delta, bye.
build_draft_pool <- function(ff_rankings_path, dim_player) {
  rankings <- as.data.frame(arrow::read_parquet(ff_rankings_path))
  rankings <- rankings[rankings$page_type == "redraft-overall", ]
  rankings <- rankings[rankings$pos != "DST", ]

  crosswalk <- dim_player[, c("player_key", "fantasypros_id")]
  pool <- merge(rankings, crosswalk, by.x = "id", by.y = "fantasypros_id", all.x = TRUE, sort = FALSE)

  # Unmatched rows here are deep-bench/rookie noise far outside any realistic
  # draft pool (verified: 46 of 525 in a 10-team league, all ranked 200th+),
  # not a crosswalk failure -- dropped rather than carried as NA player_key.
  pool <- pool[!is.na(pool$player_key), ]

  pool[, c("player_key", "player", "pos", "team",
           "ecr", "sd", "best", "worst", "rank_delta", "bye")]
}

#' Validate the draft pool: one row per player, ECR must be present and positive.
#'
#' @param pool data.table from build_draft_pool().
validate_draft_pool <- function(pool) {
  agent <- pointblank::create_agent(pool) |>
    pointblank::col_vals_not_null(pointblank::vars(player_key, pos, ecr)) |>
    pointblank::col_vals_gt(pointblank::vars(ecr), 0) |>
    pointblank::rows_distinct(pointblank::vars(player_key)) |>
    pointblank::interrogate()

  if (!pointblank::all_passed(agent)) {
    stop("draft_pool failed validation:\n", paste(capture.output(print(agent)), collapse = "\n"))
  }
  invisible(pool)
}
