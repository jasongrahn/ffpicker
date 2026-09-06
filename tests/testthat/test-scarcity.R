# 10-team league matching config/league.json's real starters, used across
# every test below so still_needed's FLEX-pool math (RB2 + WR2 + TE1 + FLEX1
# = 6 shared slots) is exercised the same way every time.
league <- list(
  teams = 10,
  roster = list(
    starters = list(QB = 1, RB = 2, WR = 2, TE = 1, FLEX = 1, K = 1, DST = 1),
    flex_eligible = list(FLEX = c("RB", "WR", "TE"))
  )
)

test_that("still_needed is the full starter count before any picks are made", {
  board <- data.frame(player_key = 1:2, pos = c("QB", "K"), tier = c(1, 1))
  state <- list(rosters = list(), my_team = "JGrahnasaurs", my_slot = 7, teams = 10,
                drafted_players = c())

  result <- scarcity_report(board, state, league)

  expect_equal(result$still_needed[result$pos == "QB"], 1)
  expect_equal(result$still_needed[result$pos == "K"], 1)
})

test_that("still_needed drops to 0 once a non-flex position's starter slot is filled", {
  board <- data.frame(player_key = 1:2, pos = c("QB", "K"), tier = c(1, 1))
  state <- list(rosters = list("JGrahnasaurs" = c(1)), my_team = "JGrahnasaurs", my_slot = 7,
                teams = 10, drafted_players = c(1))

  result <- scarcity_report(board, state, league)

  expect_equal(result$still_needed[result$pos == "QB"], 0)
  expect_equal(result$still_needed[result$pos == "K"], 1)
})

test_that("still_needed for flex-eligible positions reflects the shared RB/WR/TE/FLEX pool, not a per-position split", {
  board <- data.frame(player_key = 1:5, pos = c("RB", "RB", "WR", "WR", "TE"), tier = 1)
  # dedicated RB(2) and WR(2) slots are full, TE(1) and FLEX(1) are not --
  # total pool is RB2+WR2+TE1+FLEX1=6, 4 drafted so far -> 2 remain, and that
  # 2 applies to RB, WR, *and* TE alike since any of the three could fill it.
  state <- list(rosters = list("JGrahnasaurs" = c(1, 2, 3, 4)), my_team = "JGrahnasaurs",
                my_slot = 7, teams = 10, drafted_players = c(1, 2, 3, 4))

  result <- scarcity_report(board, state, league)

  expect_equal(result$still_needed[result$pos == "RB"], 2)
  expect_equal(result$still_needed[result$pos == "WR"], 2)
  expect_equal(result$still_needed[result$pos == "TE"], 2)
})

test_that("still_needed for flex-eligible positions is 0 once the shared pool is fully filled", {
  board <- data.frame(player_key = 1:6, pos = c("RB", "RB", "WR", "WR", "TE", "RB"), tier = 1)
  state <- list(rosters = list("JGrahnasaurs" = 1:6), my_team = "JGrahnasaurs", my_slot = 7,
                teams = 10, drafted_players = 1:6)

  result <- scarcity_report(board, state, league)

  expect_equal(result$still_needed[result$pos == "RB"], 0)
  expect_equal(result$still_needed[result$pos == "WR"], 0)
  expect_equal(result$still_needed[result$pos == "TE"], 0)
})

test_that("tier_supply counts undrafted players in a position's current best live tier", {
  board <- data.frame(player_key = 1:4, pos = "RB", tier = c(1, 1, 2, 2))
  state <- list(rosters = list(), my_team = "JGrahnasaurs", my_slot = 7, teams = 10,
                drafted_players = c())

  result <- scarcity_report(board, state, league)

  expect_equal(result$tier_supply[result$pos == "RB"], 2)
})

test_that("tier_supply follows the next tier down once the current best tier is fully drafted", {
  board <- data.frame(player_key = 1:4, pos = "RB", tier = c(1, 1, 2, 2))
  state <- list(rosters = list(), my_team = "JGrahnasaurs", my_slot = 7, teams = 10,
                drafted_players = c(1, 2))

  result <- scarcity_report(board, state, league)

  expect_equal(result$tier_supply[result$pos == "RB"], 2)
})

test_that("tier_supply is 0 for a position with no undrafted players left (edge case)", {
  board <- data.frame(player_key = 1:2, pos = "K", tier = c(1, 1))
  state <- list(rosters = list(), my_team = "JGrahnasaurs", my_slot = 7, teams = 10,
                drafted_players = c(1, 2))

  result <- scarcity_report(board, state, league)

  expect_equal(result$tier_supply[result$pos == "K"], 0)
})

test_that("survives is FALSE when tier_supply merely equals picks_until_turn, not just when it's less", {
  board <- data.frame(player_key = 1:3, pos = "WR", tier = c(1, 1, 1))
  state <- list(rosters = list(), my_team = "JGrahnasaurs", my_slot = 7, teams = 10,
                drafted_players = c())
  expect_equal(picks_until_my_turn(state), 6)

  result <- scarcity_report(board, state, league)

  expect_false(result$survives[result$pos == "WR"])
})

test_that("survives is TRUE when tier_supply strictly exceeds picks_until_turn", {
  board <- data.frame(player_key = 1:8, pos = "WR", tier = 1)
  state <- list(rosters = list(), my_team = "JGrahnasaurs", my_slot = 7, teams = 10,
                drafted_players = c())

  result <- scarcity_report(board, state, league)

  expect_true(result$survives[result$pos == "WR"])
})

test_that("a single-player tier survives only if the user is next on the clock (edge case)", {
  board <- data.frame(player_key = 1, pos = "TE", tier = 1)

  state_on_clock <- list(rosters = list(), my_team = "JGrahnasaurs", my_slot = 1, teams = 10,
                          drafted_players = c())
  expect_equal(picks_until_my_turn(state_on_clock), 0)
  result_on_clock <- scarcity_report(board, state_on_clock, league)
  expect_true(result_on_clock$survives[result_on_clock$pos == "TE"])

  state_waiting <- list(rosters = list(), my_team = "JGrahnasaurs", my_slot = 2, teams = 10,
                         drafted_players = c())
  expect_equal(picks_until_my_turn(state_waiting), 1)
  result_waiting <- scarcity_report(board, state_waiting, league)
  expect_false(result_waiting$survives[result_waiting$pos == "TE"])
})

test_that("urgency ranks a still-needed position that will not survive as most urgent", {
  board <- data.frame(player_key = 1:2, pos = "QB", tier = c(1, 1))
  state <- list(rosters = list(), my_team = "JGrahnasaurs", my_slot = 5, teams = 10,
                drafted_players = c())

  result <- scarcity_report(board, state, league)
  row <- result[result$pos == "QB", ]

  expect_true(row$still_needed > 0)
  expect_false(row$survives)
  expect_equal(row$urgency, 1)
})

test_that("urgency ranks a still-needed position that survives below the most urgent tier", {
  board <- data.frame(player_key = 1:10, pos = "QB", tier = 1)
  state <- list(rosters = list(), my_team = "JGrahnasaurs", my_slot = 5, teams = 10,
                drafted_players = c())

  result <- scarcity_report(board, state, league)
  row <- result[result$pos == "QB", ]

  expect_true(row$still_needed > 0)
  expect_true(row$survives)
  expect_equal(row$urgency, 2)
})

test_that("urgency deprioritizes a position that's already fully filled even if it would not survive", {
  board <- data.frame(player_key = 1:3, pos = "QB", tier = c(1, 1, 1))
  state <- list(rosters = list("JGrahnasaurs" = c(1)), my_team = "JGrahnasaurs", my_slot = 5,
                teams = 10, drafted_players = c(1))

  result <- scarcity_report(board, state, league)
  row <- result[result$pos == "QB", ]

  expect_equal(row$still_needed, 0)
  expect_false(row$survives)
  expect_equal(row$urgency, 3)
})

test_that("picks_until_turn/survives/urgency are NA before my_slot is captured (setup not run), but still_needed/tier_supply still compute", {
  board <- data.frame(player_key = 1:3, pos = "RB", tier = c(1, 1, 2))
  state <- list(rosters = list(), my_team = NULL, my_slot = NULL, teams = 10, drafted_players = c())
  expect_null(picks_until_my_turn(state))

  result <- scarcity_report(board, state, league)
  row <- result[result$pos == "RB", ]

  expect_true(is.na(row$picks_until_turn))
  expect_true(is.na(row$survives))
  expect_true(is.na(row$urgency))
  # still_needed still resolves from the full shared FLEX pool (RB2+WR2+TE1+FLEX1=6)
  # even though the board only has RB rows -- the pool size comes from league
  # config, not from what happens to be on this board.
  expect_equal(row$still_needed, 6)
  expect_equal(row$tier_supply, 2)
})

test_that("scarcity_report returns exactly one row per position present in the draft board", {
  board <- data.frame(player_key = 1:4, pos = c("QB", "RB", "WR", "TE"), tier = 1)
  state <- list(rosters = list(), my_team = "JGrahnasaurs", my_slot = 1, teams = 10,
                drafted_players = c())

  result <- scarcity_report(board, state, league)

  expect_setequal(result$pos, c("QB", "RB", "WR", "TE"))
  expect_equal(nrow(result), 4)
})

test_that("a roster pick that isn't on the board is excluded from still_needed rather than erroring", {
  board <- data.frame(player_key = 2, pos = "QB", tier = 1)
  # player_key 999 was drafted but never appeared on this board (e.g. an
  # off-board fallback pick) -- must not crash the lookup.
  state <- list(rosters = list("JGrahnasaurs" = c(999)), my_team = "JGrahnasaurs", my_slot = 7,
                teams = 10, drafted_players = c(999))

  result <- scarcity_report(board, state, league)

  expect_equal(result$still_needed[result$pos == "QB"], 1)
})
