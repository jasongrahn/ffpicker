synthetic_league <- list(
  teams = 2,
  roster = list(
    starters = list(QB = 1, RB = 1, WR = 1, TE = 1, K = 1, FLEX = 1),
    flex_eligible = list(FLEX = c("RB", "WR", "TE"))
  )
)

test_that("non-flex position (QB) replacement level is the (teams*starters + 1)th ranked player", {
  vt <- data.frame(
    player_key = 1:4,
    pos = "QB",
    projected_points = c(20, 15, 10, 5),
    has_current_data = TRUE
  )
  result <- compute_vor(vt, synthetic_league)
  # replacement_rank = 2*1 = 2 -> replacement value is the 3rd-ranked QB (10)
  expect_equal(result$replacement_value, rep(10, 4))
  expect_equal(result$vor, c(10, 5, 0, -5))
})

test_that("K replacement level falls back to the worst available when the pool is smaller than starter demand", {
  vt <- data.frame(player_key = 1:2, pos = "K", projected_points = c(8, 3), has_current_data = TRUE)
  result <- compute_vor(vt, synthetic_league)
  # replacement_rank = 2*1 = 2, pool has exactly 2 -> falls back to min(pool) = 3
  expect_equal(result$replacement_value, c(3, 3))
  expect_equal(result$vor, c(5, 0))
})

test_that("flex-eligible positions (RB/WR/TE) share one combined replacement level", {
  vt <- data.frame(
    player_key = 1:9,
    pos = c(rep("RB", 4), rep("WR", 3), rep("TE", 2)),
    projected_points = c(30, 20, 10, 4, 25, 15, 5, 12, 8),
    has_current_data = TRUE
  )
  result <- compute_vor(vt, synthetic_league)
  # flex_starter_slots = 1(RB)+1(WR)+1(TE) = 3; flex_slots_total = 2*(3+1) = 8
  # combined pool sorted desc: 30,25,20,15,12,10,8,5,4 (9 players) -> 9th = 4
  expect_true(all(result$replacement_value == 4))
  expect_equal(result$vor[result$player_key == 1], 30 - 4)  # top RB
  expect_equal(result$vor[result$player_key == 5], 25 - 4)  # top WR
})

test_that("rows without current-season data are excluded from VOR, not silently ranked", {
  vt <- data.frame(
    player_key = 1:3,
    pos = "QB",
    projected_points = c(20, NA, 10),
    has_current_data = c(TRUE, FALSE, TRUE)
  )
  result <- compute_vor(vt, synthetic_league)
  expect_equal(nrow(result), 2)
  expect_false(2 %in% result$player_key)
})

test_that("build_player_value: points-per-game and availability rate are computed correctly", {
  # player 1: 2025, 2 games, 10 + 20 = 30 points -> ppg 15
  # 2023-2025 window: played all 3 seasons, 10 games total out of 3*17=51 possible -> availability 10/51
  fpws <- data.frame(
    player_key = c(1, 1, 1, 1),
    season = c(2023, 2024, 2025, 2025),
    week = c(1, 1, 1, 2),
    season_type = "REG",
    fantasy_points = c(5, 5, 10, 20)
  )
  pool <- data.frame(player_key = 1, player = "Test Player", pos = "RB", team = "XX", ecr = 5, bye = 9)

  result <- build_player_value(fpws, pool, current_season = 2025, availability_seasons = 2023:2025)

  expect_equal(result$ppg_current, 15)
  expect_equal(result$games_current, 2)
  expect_equal(result$availability_rate, 4 / (3 * 17))
  expect_true(result$has_current_data)
})

test_that("build_player_value: a player with no current-season games gets NA projected_points, not zero", {
  fpws <- data.frame(
    player_key = 1, season = 2023, week = 1, season_type = "REG", fantasy_points = 5
  )
  pool <- data.frame(player_key = 1, player = "Rookie", pos = "WR", team = "XX", ecr = 50, bye = 9)

  result <- build_player_value(fpws, pool, current_season = 2025, availability_seasons = 2023:2025)

  expect_false(result$has_current_data)
  expect_true(is.na(result$projected_points))
})

test_that("assign_tiers cuts a new tier only where the VOR gap exceeds the position's spread", {
  vt <- data.frame(player_key = 1:4, pos = "RB", vor = c(50, 45, 10, 5))
  # sd(vor) = 23.27; gaps are 5, 35, 5 -> only the 35 gap crosses 1x sd
  result <- assign_tiers(vt)
  expect_equal(result$tier, c(1, 1, 2, 2))
})

test_that("build_fallback_board returns only no-current-data rows, sorted by ascending ecr", {
  vt <- data.frame(
    player_key = 1:3,
    ecr = c(30, 10, 20),
    has_current_data = c(FALSE, FALSE, TRUE)
  )
  result <- build_fallback_board(vt)
  expect_equal(result$player_key, c(2, 1))
})

test_that("build_fallback_board excludes rows that have current-season data", {
  vt <- data.frame(
    player_key = 1:2,
    ecr = c(5, 10),
    has_current_data = c(TRUE, FALSE)
  )
  result <- build_fallback_board(vt)
  expect_false(1 %in% result$player_key)
  expect_equal(nrow(result), 1)
})
