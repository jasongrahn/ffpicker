source(file.path("..", "..", "R", "60_draft_pool.R"))
source(file.path("..", "..", "R", "75_value.R"))
source(file.path("..", "..", "R", "76_pick_log.R"))
source(file.path("..", "..", "R", "78_turn.R"))
source(file.path("..", "..", "R", "79_scarcity.R"))
source(file.path("..", "..", "R", "80_opponent_sim.R"))
source(file.path("..", "..", "R", "90_explain.R"))
source(file.path("..", "..", "R", "97_yahoo_adp.R"))

#' Build fixture context from committed fixture files.
#'
#' Reads mc_pool.csv and mc_league.json from fixtures directory,
#' loads all necessary functions, builds sim_context().
#'
#' @return list from sim_context(): pool, scarcity_board, board, fallback.
fixture_ctx <- function() {
  # Load config functions
  source(file.path("..", "..", "R", "00_config.R"))

  # Read fixture pool
  pool_path <- test_path("fixtures", "mc_pool.csv")
  fixture_pool <- read.csv(pool_path, stringsAsFactors = FALSE)

  # Separate into board (has tier) and fallback (no tier)
  fixture_board <- fixture_pool[!is.na(fixture_pool$tier), ]
  fixture_fallback <- fixture_pool[is.na(fixture_pool$tier), ]

  # Fallback should not have tier or vor columns
  fixture_fallback <- fixture_fallback[, !(names(fixture_fallback) %in% c("tier", "vor"))]

  # Read fixture league
  league_path <- test_path("fixtures", "mc_league.json")
  fixture_league <- jsonlite::read_json(league_path)

  # Build sim_context
  ctx <- sim_context(fixture_board, fixture_fallback)
  ctx
}

#' Load fixture league config.
#'
#' @return list from jsonlite::read_json() of mc_league.json.
fixture_league <- function() {
  league_path <- test_path("fixtures", "mc_league.json")
  jsonlite::read_json(league_path)
}
