# Synthetic scoring fixture, not the real config -- mirrors config/scoring.json's
# shape (see test-scoring.R for the same convention) but kept minimal since these
# tests only need to prove score_player_week() is being reused, not re-verify its
# own golden tests.
scoring <- list(
  passing = list(yards = 0.04, td = 4, int = -1),
  rushing = list(yards = 0.1, td = 6),
  receiving = list(reception = 0.5, yards = 0.1, td = 6, position_premium = list(TE = 0.0)),
  misc = list(fumble_lost = -2, two_point = 2),
  kicking = list(fg_0_39 = 3, fg_40_49 = 4, fg_50_plus = 5, fg_miss = 0, pat_made = 1, pat_miss = 0)
)

write_opp_parquet <- function(df) {
  path <- tempfile(fileext = ".parquet")
  arrow::write_parquet(df, path)
  path
}

test_that("build_expected_stat_lines maps ff_opportunity's _exp columns onto score_player_week's input names", {
  opp_raw <- data.frame(
    season = c(2025L, 2025L, 2025L),
    week = c(1L, 1L, 1L),
    player_id = c("00-0001", "00-0002", "00-0003"),
    full_name = c("Player One", "Player Two", "Kicker Three"),
    position = c("QB", "RB", "K"),
    pass_yards_gained_exp = c(250, 0, 0),
    pass_touchdown_exp = c(1.8, 0, 0),
    pass_interception_exp = c(0.9, 0, 0),
    rush_yards_gained_exp = c(5, 80, 0),
    rush_touchdown_exp = c(0.1, 0.6, 0),
    receptions_exp = c(0, 3.2, 0),
    rec_yards_gained_exp = c(0, 25, 0),
    rec_touchdown_exp = c(0, 0.2, 0),
    stringsAsFactors = FALSE
  )
  path <- write_opp_parquet(opp_raw)

  # Names deliberately don't match `full_name` above -- proves the join runs
  # on player_id/gsis_id, never on name.
  dim_player <- data.frame(
    player_key = c(1L, 2L, 99L),
    gsis_id = c("00-0001", "00-0002", "00-9999"),
    display_name = c("Totally Different Name A", "Totally Different Name B", "Nobody")
  )

  result <- build_expected_stat_lines(path, dim_player)

  # K is dropped: ff_opportunity has no opportunity model for kicking (a K's
  # only rows are stray trick-play rush/pass attempts, not kicking production).
  expect_equal(nrow(result), 2)
  expect_false("K" %in% result$position)

  qb <- result[result$player_id == "00-0001", ]
  expect_equal(qb$player_key, 1L)
  expect_equal(qb$passing_yards, 250)
  expect_equal(qb$passing_tds, 1.8)
  expect_equal(qb$passing_interceptions, 0.9)

  rb <- result[result$player_id == "00-0002", ]
  expect_equal(rb$player_key, 2L)
  expect_equal(rb$rushing_yards, 80)
  expect_equal(rb$rushing_tds, 0.6)
  expect_equal(rb$receptions, 3.2)
  expect_equal(rb$receiving_yards, 25)
  expect_equal(rb$receiving_tds, 0.2)
})

test_that("build_expected_stat_lines keeps crosswalk-unmatched rows with NA player_key rather than dropping or matching by name", {
  opp_raw <- data.frame(
    season = 2025L, week = 1L, player_id = "00-9999", full_name = "Ghost Player",
    position = "WR", rec_yards_gained_exp = 40, stringsAsFactors = FALSE
  )
  path <- write_opp_parquet(opp_raw)
  dim_player <- data.frame(player_key = 1L, gsis_id = "00-0001", display_name = "Someone Else")

  result <- build_expected_stat_lines(path, dim_player)
  expect_equal(nrow(result), 1)
  expect_true(is.na(result$player_key))
})

test_that("build_expected_stat_lines drops postseason weeks (no season_type column exists in this source, so the cutoff is the NFL's 18-week regular season)", {
  opp_raw <- data.frame(
    season = c(2025L, 2025L),
    week = c(18L, 19L),
    player_id = c("00-0001", "00-0001"),
    full_name = c("Player One", "Player One"),
    position = c("QB", "QB"),
    pass_yards_gained_exp = c(200, 200),
    stringsAsFactors = FALSE
  )
  path <- write_opp_parquet(opp_raw)
  dim_player <- data.frame(player_key = 1L, gsis_id = "00-0001", display_name = "Player One")

  result <- build_expected_stat_lines(path, dim_player)
  expect_equal(nrow(result), 1)
  expect_equal(result$week, 18L)
})

test_that("build_expected_stat_lines never fabricates a fumble column -- ff_opportunity has no expected-fumble concept", {
  opp_raw <- data.frame(
    season = 2025L, week = 1L, player_id = "00-0001", full_name = "Player One",
    position = "RB", rush_yards_gained_exp = 50, stringsAsFactors = FALSE
  )
  path <- write_opp_parquet(opp_raw)
  dim_player <- data.frame(player_key = 1L, gsis_id = "00-0001", display_name = "Player One")

  result <- build_expected_stat_lines(path, dim_player)
  fumble_cols <- c("sack_fumbles_lost", "rushing_fumbles_lost", "receiving_fumbles_lost")
  expect_true(all(!fumble_cols %in% colnames(result)))
})

test_that("add_expected_fantasy_points reuses score_player_week() on the mapped expected stat line", {
  expected_stats <- data.frame(
    player_key = 1L, position = "QB",
    passing_yards = 250, passing_tds = 1.8, passing_interceptions = 0.9
  )
  result <- add_expected_fantasy_points(expected_stats, scoring)
  # 250*0.04 + 1.8*4 + 0.9*(-1) = 10 + 7.2 - 0.9
  expect_equal(result$fantasy_points_exp, 16.3)
})

test_that("build_player_opportunity_value aggregates expected and actual points per player-season, with diff = actual - expected", {
  expected_scored <- data.frame(
    player_key = c(1, 1),
    season = c(2025, 2025),
    week = c(1, 2),
    fantasy_points_exp = c(16.3, 10.0)
  )
  actual_scored <- data.frame(
    player_key = c(1, 1, 1),
    season = c(2025, 2025, 2025),
    week = c(1, 2, 1),
    season_type = c("REG", "REG", "POST"),
    fantasy_points = c(20, 5, 999) # POST week must be excluded
  )

  result <- build_player_opportunity_value(expected_scored, actual_scored, season = 2025)

  expect_equal(result$points_exp[result$player_key == 1], 26.3)
  expect_equal(result$points_actual[result$player_key == 1], 25)
  # diff sign matches ff_opportunity's own convention (actual - expected):
  # negative means the player underperformed the opportunity he was given.
  expect_equal(result$points_diff[result$player_key == 1], 25 - 26.3)
  expect_equal(result$games_exp[result$player_key == 1], 2)
})

test_that("build_player_opportunity_value fills 0, not NA, for a player present on only one side", {
  expected_scored <- data.frame(player_key = 2, season = 2025, week = 1, fantasy_points_exp = 12)
  actual_scored <- data.frame(
    player_key = 3, season = 2025, week = 1, season_type = "REG", fantasy_points = 8
  )

  result <- build_player_opportunity_value(expected_scored, actual_scored, season = 2025)

  exp_only <- result[result$player_key == 2, ]
  expect_equal(exp_only$points_actual, 0)
  expect_equal(exp_only$points_diff, -12)

  actual_only <- result[result$player_key == 3, ]
  expect_equal(actual_only$points_exp, 0)
  expect_equal(actual_only$points_diff, 8)
})
