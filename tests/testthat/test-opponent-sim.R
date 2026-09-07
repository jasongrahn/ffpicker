test_that("sim_noise() generates Gumbel(0,1) matrix with correct dimensions", {
  noise <- sim_noise(5, 4, 42)
  expect_equal(dim(noise), c(5, 4))
  expect_true(is.numeric(noise))
})

test_that("sim_noise() is deterministic with same seed", {
  noise1 <- sim_noise(5, 4, 7)
  noise2 <- sim_noise(5, 4, 7)
  expect_identical(noise1, noise2)
})

test_that("sim_noise() differs with different seed", {
  noise1 <- sim_noise(5, 4, 7)
  noise2 <- sim_noise(5, 4, 8)
  expect_false(identical(noise1, noise2))
})

test_that("draw_opponent_pick() tau=0 returns argmin(xrank)", {
  xrank <- c(5, 2, 8, 1, 9)
  idx <- draw_opponent_pick(xrank, tau = 0)
  expect_equal(idx, 4)  # 1 is the minimum, at index 4
})

test_that("draw_opponent_pick() tau=0 puts NA last", {
  xrank <- c(5, NA, 2, 8, 1)
  idx <- draw_opponent_pick(xrank, tau = 0)
  expect_equal(idx, 5)  # 1 is the minimum, at index 5
})

test_that("draw_opponent_pick() tau > 0 uses noise", {
  xrank <- c(5, 2, 8, 1, 9)
  noise <- c(0.5, 0.5, 0.5, 0.5, 10)  # Last one gets boosted by noise
  idx <- draw_opponent_pick(xrank, tau = 3, noise = noise)
  # score = -xrank/tau + noise
  # scores: -5/3 + 0.5 = -1.167, -2/3 + 0.5 = -0.167, -8/3 + 0.5 = -2.167, -1/3 + 0.5 = 0.167, -9/3 + 10 = 7
  # max is index 5
  expect_equal(idx, 5)
})

test_that("draw_opponent_pick() all NA with tau>0 returns first index", {
  xrank <- c(NA_real_, NA_real_, NA_real_)
  noise <- c(0.1, 0.2, 0.3)
  idx <- draw_opponent_pick(xrank, tau = 3, noise = noise)
  expect_identical(idx, 1L)
})

test_that("draw_opponent_pick() all NA with tau=0 returns first index", {
  xrank <- c(NA_real_, NA_real_, NA_real_)
  idx <- draw_opponent_pick(xrank, tau = 0)
  expect_identical(idx, 1L)
})

test_that("draw_opponent_pick() listed player beats any unlisted despite noise", {
  xrank <- c(NA, 500, NA)
  noise <- c(99, 0, 99)
  idx <- draw_opponent_pick(xrank, tau = 3, noise = noise)
  # score = -xrank/tau + noise, or -Inf for NA xrank
  # NA: -Inf (at indices 1, 3)
  # listed: -500/3 + 0 = -166.67 (at index 2)
  # max is index 2 (listed player)
  expect_identical(idx, 2L)
})

test_that("starter_value() fills lineup greedily by VOR", {
  picks <- data.frame(
    pos = c("QB", "RB", "WR", "TE", "RB", "WR"),
    vor = c(40, 50, 45, 35, 30, 25),
    stringsAsFactors = FALSE
  )
  league_cfg <- list(
    roster = list(
      starters = list(QB = 1, RB = 1, WR = 1, TE = 1, FLEX = 1),
      flex_eligible = list(FLEX = c("RB", "WR", "TE"))
    )
  )
  result <- starter_value(picks, league_cfg)
  # Lineup should be (sorted by vor desc): QB(40), RB(50), WR(45), TE(35), RB(30) = 5 starters filling 5 slots
  # Total: 40 + 50 + 45 + 35 + 30 = 200
  expect_equal(result$total, 200)
  expect_equal(nrow(result$lineup), 5)
  expect_equal(result$unfilled, character(0))
})

test_that("paired_bootstrap_ci() constant delta", {
  delta <- rep(2, 100)
  ci <- paired_bootstrap_ci(delta, n_boot = 100, conf = 0.95)
  expect_equal(ci$mean, 2)
  expect_equal(ci$lo, 2)
  expect_equal(ci$hi, 2)
  expect_equal(ci$p_a_gt_b, 1)
})

test_that("paired_bootstrap_ci() normal delta contains 0", {
  set.seed(123)
  delta <- rnorm(2000)
  ci <- paired_bootstrap_ci(delta, n_boot = 1000, conf = 0.95)
  expect_true(ci$lo < 0 && ci$hi > 0)
  expect_true(ci$p_a_gt_b > 0.4 && ci$p_a_gt_b < 0.6)
})

test_that("tau = 0 reproduces deterministic draft", {
  ctx <- fixture_ctx()
  league_cfg <- fixture_league()
  got <- simulate_draft(ctx, league_cfg, my_slot = 2, defer = list(), tau = 0)
  expected <- readRDS(test_path("fixtures", "dryrun_tau0_fixture.rds"))
  expect_equal(got$picks, expected)
})

test_that("tau = 0 is noise-invariant", {
  ctx <- fixture_ctx()
  league_cfg <- fixture_league()
  noise_matrix <- sim_noise(nrow(ctx$pool), league_cfg$teams * league_cfg$roster$rounds, 1)

  got1 <- simulate_draft(ctx, league_cfg, my_slot = 2, defer = list(), tau = 0, noise = noise_matrix)
  got2 <- simulate_draft(ctx, league_cfg, my_slot = 2, defer = list(), tau = 0, noise = NULL)

  expect_equal(got1$picks, got2$picks)
})
