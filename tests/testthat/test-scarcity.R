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

test_that("still_needed for flex-eligible positions is dedicated need plus the shared FLEX slot, not a collapsed shared pool", {
  board <- data.frame(player_key = 1:5, pos = c("RB", "RB", "WR", "WR", "TE"), tier = 1)
  # dedicated RB(2) and WR(2) slots are full, TE(1) is not, and the single
  # shared FLEX(1) slot hasn't been used by any surplus RB/WR pick -- so it's
  # still open to whichever of RB/WR/TE gets drafted next.
  state <- list(rosters = list("JGrahnasaurs" = c(1, 2, 3, 4)), my_team = "JGrahnasaurs",
                my_slot = 7, teams = 10, drafted_players = c(1, 2, 3, 4))

  result <- scarcity_report(board, state, league)

  # RB: dedicated 2-2=0, plus open FLEX(1) = 1
  expect_equal(result$still_needed[result$pos == "RB"], 1)
  # WR: dedicated 2-2=0, plus open FLEX(1) = 1
  expect_equal(result$still_needed[result$pos == "WR"], 1)
  # TE: dedicated 1-0=1, plus open FLEX(1) = 2
  expect_equal(result$still_needed[result$pos == "TE"], 2)
})

test_that("still_needed correctly separates dedicated need per position instead of collapsing RB/WR/TE together (regression: reported 2026-09-06)", {
  # 3 RBs drafted: fills both dedicated RB slots plus the single FLEX slot.
  # RB's true remaining need is 0 -- but 0 WR and 0 TE have been drafted, so
  # those positions have real, distinct holes that a shared-pool number
  # would have hidden (the bug: it reported RB/WR/TE all == 3 here).
  board <- data.frame(
    player_key = 1:20, player = paste0("P", 1:20),
    pos = c(rep("RB", 5), rep("WR", 5), rep("TE", 5), rep("QB", 5)),
    tier = rep(1:5, 4), vor = 20:1
  )
  state <- list(rosters = list(Me = c(1L, 2L, 3L)), drafted_players = c(1L, 2L, 3L),
                my_team = "Me", my_slot = 5, teams = 10)

  result <- scarcity_report(board, state, league)

  expect_equal(result$still_needed[result$pos == "RB"], 0)
  expect_equal(result$still_needed[result$pos == "WR"], 2)
  expect_equal(result$still_needed[result$pos == "TE"], 1)
  expect_equal(result$still_needed[result$pos == "QB"], 1)
})

test_that("still_needed's shared FLEX slot is closed once a surplus flex-eligible pick already occupies it", {
  # 3 RBs drafted (2 dedicated + 1 surplus) already occupies the single FLEX
  # slot, so an empty TE's still_needed is its dedicated need only (1), not
  # dedicated-plus-FLEX (2) -- the FLEX slot isn't double-counted as "open"
  # for every flex-eligible position once something has already claimed it.
  board <- data.frame(player_key = 1:8, pos = c(rep("RB", 3), rep("WR", 2), rep("TE", 3)), tier = 1)
  state <- list(rosters = list("JGrahnasaurs" = c(1, 2, 3)), my_team = "JGrahnasaurs",
                my_slot = 7, teams = 10, drafted_players = c(1, 2, 3))

  result <- scarcity_report(board, state, league)

  expect_equal(result$still_needed[result$pos == "RB"], 0)  # 2 dedicated + 1 surplus, no need left
  expect_equal(result$still_needed[result$pos == "WR"], 2)  # dedicated 2-0=2, FLEX already spoken for
  expect_equal(result$still_needed[result$pos == "TE"], 1)  # dedicated 1-0=1, FLEX already spoken for
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
  # still_needed still resolves independent of my_slot: dedicated RB need
  # (2-0=2) plus the open shared FLEX slot (1, untouched by any drafted
  # flex-eligible pick) = 3.
  expect_equal(row$still_needed, 3)
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

# --- Regression: kicker recommended first overall (reported 2026-09-06) ---
# The app told the drafter to take Jason Myers (K, SEA) with the first pick of
# the draft. Three independent causes; these cover the two that live here.

test_that("defer_until_round parks a position at the lowest urgency before its round, even with an open starter slot", {
  board <- data.frame(player_key = 1:2, pos = c("RB", "K"), tier = 1,
                      vor = c(140, 61))
  state <- list(rosters = list(), my_team = "JGrahnasaurs", my_slot = 5, teams = 10,
                drafted_players = c())
  cfg <- league
  cfg$draft <- list(defer_until_round = list(K = 16))

  result <- scarcity_report(board, state, cfg)

  # Round 1 of 17. K's starter slot is genuinely open and its tier will not
  # survive, which is urgency 1 under the old rules -- the deferral is what
  # stops that becoming a first-round kicker.
  expect_equal(result$still_needed[result$pos == "K"], 1)
  expect_true(result$deferred[result$pos == "K"])
  expect_equal(result$urgency[result$pos == "K"], 5L)
  expect_false(result$deferred[result$pos == "RB"])
  expect_equal(result$urgency[result$pos == "RB"], 1L)
})

test_that("defer_until_round stops deferring once the draft reaches that round", {
  board <- data.frame(player_key = 1:2, pos = c("RB", "K"), tier = 1,
                      vor = c(140, 61))
  # 150 picks made in a 10-team league -> pick 151 -> round 16.
  state <- list(rosters = list(), my_team = "JGrahnasaurs", my_slot = 5, teams = 10,
                drafted_players = seq_len(150))
  cfg <- league
  cfg$draft <- list(defer_until_round = list(K = 16))

  result <- scarcity_report(board, state, cfg)

  expect_false(result$deferred[result$pos == "K"])
  expect_true(result$urgency[result$pos == "K"] < 5L)
})

test_that("the report carries the deferral round, so display can name it", {
  board <- data.frame(player_key = 1:2, pos = c("RB", "K"), tier = 1,
                      vor = c(140, 61))
  state <- list(rosters = list(), my_team = "JGrahnasaurs", my_slot = 5, teams = 10,
                drafted_players = c())
  cfg <- league
  cfg$draft <- list(defer_until_round = list(K = 16))

  result <- scarcity_report(board, state, cfg)

  expect_equal(result$defer_until_round[result$pos == "K"], 16L)
  expect_true(is.na(result$defer_until_round[result$pos == "RB"]))
})

test_that("a config with no defer_until_round defers nothing", {
  board <- data.frame(player_key = 1:2, pos = c("RB", "K"), tier = 1,
                      vor = c(140, 61))
  state <- list(rosters = list(), my_team = "JGrahnasaurs", my_slot = 5, teams = 10,
                drafted_players = c())

  result <- scarcity_report(board, state, league)

  expect_true(all(!result$deferred))
})

test_that("vor_best reports the best VOR still available at each position, NA when the position has none", {
  board <- data.frame(player_key = 1:4, pos = c("RB", "RB", "WR", "DST"), tier = 1,
                      vor = c(140, 90, 116, NA_real_))
  state <- list(rosters = list(), my_team = "JGrahnasaurs", my_slot = 5, teams = 10,
                drafted_players = c())

  result <- scarcity_report(board, state, league)

  expect_equal(result$vor_best[result$pos == "RB"], 140)
  expect_equal(result$vor_best[result$pos == "WR"], 116)
  # DST rides in the fallback with no VOR at all; max(na.rm=TRUE) on an
  # all-NA vector would warn and return -Inf, which would sort as the most
  # valuable position of all.
  expect_true(is.na(result$vor_best[result$pos == "DST"]))
})
