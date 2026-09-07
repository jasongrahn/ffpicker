source(file.path("..", "..", "R", "78_turn.R"))
source(file.path("..", "..", "R", "76_pick_log.R"))
source(file.path("..", "..", "R", "80_opponent_sim.R"))
source(file.path("..", "..", "R", "81_vona.R"))

test_that("simulate_forward() horizon=0 all survive", {
  ctx <- fixture_ctx()
  league_cfg <- fixture_league()

  # Create a mock state with no picks yet
  log_path <- tempfile(fileext = ".jsonl")
  file.create(log_path)
  start_draft(log_path, league_cfg$teams, "TestTeam", 2)
  state <- replay_pick_log(log_path)

  result <- simulate_forward(ctx, state, horizon = 0, tau = 0, n_sims = 10, seed = 1)

  # All should survive
  expect_true(all(result$p_available$p_available == 1))

  # pos_best should match current max vor per position
  remaining <- remaining_draft_pool(ctx$pool, state)
  for (pos in c("QB", "RB", "WR", "TE", "K", "DST")) {
    remaining_pos <- remaining[remaining$pos == pos, ]
    if (nrow(remaining_pos) > 0) {
      current_max <- max(remaining_pos$vor, na.rm = TRUE)
      pos_best_row <- result$pos_best[result$pos_best$pos == pos, ]
      expect_equal(pos_best_row$mean_best_vor, current_max)
    }
  }
})

test_that("simulate_forward() tau=0 is deterministic", {
  ctx <- fixture_ctx()
  league_cfg <- fixture_league()

  log_path <- tempfile(fileext = ".jsonl")
  file.create(log_path)
  start_draft(log_path, league_cfg$teams, "TestTeam", 2)
  state <- replay_pick_log(log_path)

  # Run 5 times, should all be identical
  results <- list()
  for (i in 1:5) {
    results[[i]] <- simulate_forward(ctx, state, horizon = 3, tau = 0, n_sims = 5, seed = 42)
  }

  for (i in 2:5) {
    expect_identical(results[[i]]$p_available, results[[1]]$p_available)
  }
})

test_that("simulate_forward() survival count matches horizon", {
  ctx <- fixture_ctx()
  league_cfg <- fixture_league()

  log_path <- tempfile(fileext = ".jsonl")
  file.create(log_path)
  start_draft(log_path, league_cfg$teams, "TestTeam", 2)
  state <- replay_pick_log(log_path)

  result <- simulate_forward(ctx, state, horizon = 5, tau = 3, n_sims = 100, seed = 42)

  # Sum of deaths should equal horizon per replicate
  deaths <- sum(1 - result$p_available$p_available)
  expect_true(abs(deaths - 5) < 0.1)  # Allow small float tolerance
})

test_that("simulate_forward() monotone in tau for top player", {
  ctx <- fixture_ctx()
  league_cfg <- fixture_league()

  log_path <- tempfile(fileext = ".jsonl")
  file.create(log_path)
  start_draft(log_path, league_cfg$teams, "TestTeam", 2)
  state <- replay_pick_log(log_path)

  remaining <- remaining_draft_pool(ctx$pool, state)
  top_by_xrank <- remaining[order(remaining$xrank, na.last = TRUE), ][1, ]

  results <- list()
  taus <- c(0, 3, 6, 12)
  for (i in seq_along(taus)) {
    tau <- taus[i]
    results[[i]] <- simulate_forward(ctx, state, horizon = 5, tau = tau, n_sims = 50, seed = 42)
  }

  p_values <- sapply(results, function(result) {
    row <- result$p_available[result$p_available$player_key == top_by_xrank$player_key, ]
    if (nrow(row) > 0) row$p_available else NA
  })

  # Should be non-decreasing as tau increases
  expect_true(p_values[1] <= p_values[2])
  expect_true(p_values[2] <= p_values[3])
  expect_true(p_values[3] <= p_values[4])
})

test_that("simulate_forward() seed reproducibility", {
  ctx <- fixture_ctx()
  league_cfg <- fixture_league()

  log_path <- tempfile(fileext = ".jsonl")
  file.create(log_path)
  start_draft(log_path, league_cfg$teams, "TestTeam", 2)
  state <- replay_pick_log(log_path)

  result1 <- simulate_forward(ctx, state, horizon = 3, tau = 6, n_sims = 20, seed = 99)
  result2 <- simulate_forward(ctx, state, horizon = 3, tau = 6, n_sims = 20, seed = 99)

  expect_identical(result1$p_available, result2$p_available)
  expect_identical(result1$pos_best, result2$pos_best)
})

test_that("vona() hand-computed values", {
  # Hand-built board and pos_best
  board <- data.frame(
    pos = c("QB", "RB", "WR", "TE", "K"),
    vor = c(40, 50, 45, 35, 25),
    stringsAsFactors = FALSE
  )
  pos_best <- data.frame(
    pos = c("QB", "RB", "WR", "TE", "K", "DST"),
    mean_best_vor = c(35, 40, 30, 20, 10, 5),
    sd_best_vor = c(2, 3, 2.5, 1.5, 1, 0.5),
    stringsAsFactors = FALSE
  )

  result <- vona(board, pos_best)

  # VONA = vor - mean_best_vor next turn
  # QB: 40 - 35 = 5
  # RB: 50 - 40 = 10
  # WR: 45 - 30 = 15
  # TE: 35 - 20 = 15
  # K: 25 - 10 = 15
  expect_equal(result, c(5, 10, 15, 15, 15))
})

test_that("vona() missing position returns NA", {
  board <- data.frame(
    pos = c("QB", "RB", "DST"),
    vor = c(40, 50, 15),
    stringsAsFactors = FALSE
  )
  pos_best <- data.frame(
    pos = c("QB", "RB"),
    mean_best_vor = c(35, 40),
    sd_best_vor = c(2, 3),
    stringsAsFactors = FALSE
  )

  result <- vona(board, pos_best)

  # DST is missing from pos_best
  expect_equal(result[1], 5)
  expect_equal(result[2], 10)
  expect_true(is.na(result[3]))
})

test_that("survival_display() formats correctly", {
  result <- survival_display(c(NA, 0.9, 0.1, 0.25, 0.2))

  expect_equal(result[1], "")
  expect_equal(result[2], "90%")
  expect_equal(result[3], '<span style="color: #d32f2f; font-weight: bold;">10% ⚠</span>')
  expect_equal(result[4], "25%")
  expect_match(result[5], "#d32f2f")  # Low survival gets red (hex color)
})

test_that("vona_display() formats correctly", {
  result <- vona_display(c(NA, 12.4, -5.2, 0))

  expect_equal(result[1], "")
  expect_equal(result[2], "+12.4")
  expect_equal(result[3], "-5.2")
  expect_equal(result[4], "+0.0")
})
