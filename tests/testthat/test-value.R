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

test_that("assign_tiers cuts a new tier where a gap is unusual for a step between neighbours", {
  vt <- data.frame(player_key = 1:4, pos = "RB", vor = c(50, 45, 10, 5))
  # gaps are 5, 35, 5 -> sd(gaps) = 17.32; only the 35 gap crosses 1x that
  result <- assign_tiers(vt)
  expect_equal(result$tier, c(1L, 1L, 2L, 2L))
})

test_that("assign_tiers separates a gently-sloping position into several tiers", {
  # Regression guard for the sd(vor) bug: a realistic long tail with a few real
  # cliffs. sd(vor) as the threshold collapsed this kind of shape into 2 tiers.
  vor <- c(100, 60, 58, 56, 54, 30, 29, 28, 27, 26)
  vt <- data.frame(player_key = 1:10, pos = "WR", vor = vor)
  result <- assign_tiers(vt)
  expect_gt(max(result$tier), 2)
  # The two cliffs (100->60 and 54->30) are where the breaks must land.
  expect_equal(result$tier[1:2], c(1L, 2L))
  expect_true(result$tier[6] > result$tier[5])
})

test_that("assign_tiers tiers each position independently", {
  vt <- data.frame(
    player_key = 1:6, pos = c("RB", "RB", "RB", "WR", "WR", "WR"),
    vor = c(50, 45, 10, 50, 45, 10)
  )
  result <- assign_tiers(vt)
  expect_equal(result$tier[result$pos == "RB"], result$tier[result$pos == "WR"])
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

# --- Phase 8.1: expected-points ranking basis (see PLAN_1.md) ---

test_that("build_player_value: player_opportunity = NULL (default) adds no expected-basis columns -- pipeline stays runnable pre-wiring", {
  fpws <- data.frame(
    player_key = c(1, 1), season = c(2025, 2025), week = c(1, 2),
    season_type = "REG", fantasy_points = c(10, 20)
  )
  pool <- data.frame(player_key = 1, player = "Test Player", pos = "RB", team = "XX", ecr = 5, bye = 9)

  result <- build_player_value(fpws, pool, current_season = 2025, availability_seasons = 2023:2025)

  expect_false("ppg_expected" %in% names(result))
  expect_false("projected_points_exp" %in% names(result))
  expect_false("has_expected_data" %in% names(result))
  # old columns present and unchanged
  expect_equal(result$ppg_current, 15)
  expect_true(result$has_current_data)
})

test_that("build_player_value: expected projection uses ppg_expected * 17 * the SAME availability multiplier as the actual projection", {
  fpws <- data.frame(
    player_key = c(1, 1), season = c(2025, 2025), week = c(1, 2),
    season_type = "REG", fantasy_points = c(10, 20)
  )
  pool <- data.frame(player_key = 1, player = "Test Player", pos = "RB", team = "XX", ecr = 5, bye = 9)
  opp <- data.frame(player_key = 1, points_exp = 24, games_exp = 2, points_actual = 30, points_diff = 6)

  result <- build_player_value(fpws, pool,
    current_season = 2025, availability_seasons = 2023:2025,
    player_opportunity = opp
  )

  # current season (2025) falls inside availability_seasons (2023:2025), so
  # availability_rate is a real computed value here, not the NA->1 fallback:
  # games_played_window = 2, active_seasons_window = 1 -> 2/17.
  avail <- 2 / 17
  expect_equal(result$availability_rate, avail)
  expect_equal(result$ppg_expected, 12)
  expect_equal(result$projected_points_exp, 12 * 17 * avail)
  expect_true(result$has_expected_data)
  # old actual-based columns stay untouched, side by side, same multiplier
  expect_equal(result$ppg_current, 15)
  expect_equal(result$projected_points, 15 * 17 * avail)
})

test_that("build_player_value: expected projection falls back to availability = 1 when availability_rate is NA (mirrors actual-side rule exactly)", {
  fpws <- data.frame(
    player_key = c(1, 1), season = c(2025, 2025), week = c(1, 2),
    season_type = "REG", fantasy_points = c(10, 20)
  )
  pool <- data.frame(player_key = 1, player = "Test Player", pos = "RB", team = "XX", ecr = 5, bye = 9)
  opp <- data.frame(player_key = 1, points_exp = 24, games_exp = 2, points_actual = 30, points_diff = 6)

  # availability_seasons has zero overlap with current_season's data -> no
  # avail_stats rows for player 1 -> availability_rate NA -> both bases use 1.
  result <- build_player_value(fpws, pool,
    current_season = 2025, availability_seasons = 2020:2022,
    player_opportunity = opp
  )

  expect_true(is.na(result$availability_rate))
  expect_equal(result$projected_points, 15 * 17 * 1)
  expect_equal(result$projected_points_exp, 12 * 17 * 1)
})

test_that("build_player_value: Board player (has_current_data) absent from player_opportunity gets NA expected fields, not dropped", {
  fpws <- data.frame(
    player_key = c(1, 1), season = c(2025, 2025), week = c(1, 2),
    season_type = "REG", fantasy_points = c(10, 20)
  )
  pool <- data.frame(player_key = 1, player = "Test Player", pos = "RB", team = "XX", ecr = 5, bye = 9)
  opp <- data.frame(player_key = 999, points_exp = 24, games_exp = 2, points_actual = 30, points_diff = 6)

  result <- build_player_value(fpws, pool,
    current_season = 2025, availability_seasons = 2023:2025,
    player_opportunity = opp
  )

  expect_true(result$has_current_data)
  expect_false(result$has_expected_data)
  expect_true(is.na(result$ppg_expected))
  expect_true(is.na(result$projected_points_exp))
})

test_that("compute_vor basis='expected' (default) ranks on projected_points_exp when present", {
  vt <- data.frame(
    player_key = 1:4,
    pos = "QB",
    projected_points = c(20, 15, 10, 5),
    projected_points_exp = c(5, 40, 30, 25),
    has_current_data = TRUE
  )
  result <- compute_vor(vt, synthetic_league)
  # sorted desc by expected: 40,30,25,5 -> replacement_rank 2 -> 3rd ranked = 25
  expect_equal(result$replacement_value, rep(25, 4))
  expect_equal(result$vor, c(5 - 25, 40 - 25, 30 - 25, 25 - 25))
})

test_that("compute_vor basis='actual' ignores projected_points_exp entirely", {
  vt <- data.frame(
    player_key = 1:4,
    pos = "QB",
    projected_points = c(20, 15, 10, 5),
    projected_points_exp = c(5, 40, 30, 25),
    has_current_data = TRUE
  )
  result <- compute_vor(vt, synthetic_league, basis = "actual")
  expect_equal(result$replacement_value, rep(10, 4))
  expect_equal(result$vor, c(10, 5, 0, -5))
})

test_that("compute_vor basis='expected' falls back per-row to actual projection when expected is missing (Board-survival rule)", {
  vt <- data.frame(
    player_key = 1:4,
    pos = "QB",
    projected_points = c(20, 15, 10, 5),
    projected_points_exp = c(NA, 40, 30, NA),
    has_current_data = TRUE
  )
  result <- compute_vor(vt, synthetic_league)
  # effective projection: 20(fallback), 40, 30, 5(fallback) -> sorted desc 40,30,20,5 -> 3rd = 20
  expect_equal(result$replacement_value, rep(20, 4))
  expect_equal(result$vor, c(20 - 20, 40 - 20, 30 - 20, 5 - 20))
})

test_that("compute_vor default basis stays backward-compatible with value tables that have no projected_points_exp column at all", {
  vt <- data.frame(
    player_key = 1:4,
    pos = "QB",
    projected_points = c(20, 15, 10, 5),
    has_current_data = TRUE
  )
  result <- compute_vor(vt, synthetic_league)
  expect_equal(result$replacement_value, rep(10, 4))
  expect_equal(result$vor, c(10, 5, 0, -5))
})
