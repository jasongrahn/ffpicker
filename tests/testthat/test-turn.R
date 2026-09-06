test_that("slot_on_the_clock matches the known 12-team snake order from CLAUDE.md", {
  # slot 1: picks 1, 24, 25, 48, 49
  expect_equal(slot_on_the_clock(1, 12), 1)
  expect_equal(slot_on_the_clock(24, 12), 1)
  expect_equal(slot_on_the_clock(25, 12), 1)
  expect_equal(slot_on_the_clock(48, 12), 1)
  expect_equal(slot_on_the_clock(49, 12), 1)

  # slot 2: picks 2, 23, 26, 47, 50
  expect_equal(slot_on_the_clock(2, 12), 2)
  expect_equal(slot_on_the_clock(23, 12), 2)
  expect_equal(slot_on_the_clock(26, 12), 2)

  # slot 6: picks 6, 19, 30, 43, 54
  expect_equal(slot_on_the_clock(6, 12), 6)
  expect_equal(slot_on_the_clock(19, 12), 6)
  expect_equal(slot_on_the_clock(30, 12), 6)

  # slot 12: picks 12, 13, 36, 37, 60
  expect_equal(slot_on_the_clock(12, 12), 12)
  expect_equal(slot_on_the_clock(13, 12), 12)
  expect_equal(slot_on_the_clock(36, 12), 12)
})

test_that("picks_until_turn is 0 when it's already your pick", {
  expect_equal(picks_until_turn(1, my_slot = 1, teams = 12), 0)
  expect_equal(picks_until_turn(25, my_slot = 1, teams = 12), 0)
})

test_that("picks_until_turn matches the gaps in CLAUDE.md's slot table", {
  # slot 1: gaps 23, 1, 23, 1 between 1, 24, 25, 48, 49
  expect_equal(picks_until_turn(2, my_slot = 1, teams = 12), 22)
  expect_equal(picks_until_turn(26, my_slot = 1, teams = 12), 22)

  # slot 2: gaps 21, 3, 21, 3 between 2, 23, 26, 47, 50
  expect_equal(picks_until_turn(3, my_slot = 2, teams = 12), 20)
  expect_equal(picks_until_turn(24, my_slot = 2, teams = 12), 2)
})

test_that("picks_until_turn works for this league's 10-team draft", {
  # round 1 is odd, so slot 7's first pick is pick 7
  expect_equal(picks_until_turn(1, my_slot = 7, teams = 10), 6)
  # round 2 is even: pick = 2*10 - 7 + 1 = 14
  expect_equal(picks_until_turn(8, my_slot = 7, teams = 10), 6)
})

test_that("picks_until_my_turn returns NULL before the draft has a my_slot", {
  state <- list(drafted_players = c(), my_slot = NULL, teams = 10)

  expect_null(picks_until_my_turn(state))
})

test_that("picks_until_my_turn derives the current pick number from drafted_players count", {
  state <- list(drafted_players = c(101, 202, 303), my_slot = 7, teams = 10)

  # 3 picks made, so pick 4 is next; slot 7 is on the clock at pick 7
  expect_equal(picks_until_my_turn(state), 3)
})

test_that("team_for_slot falls back to a placeholder name for an unmapped slot", {
  expect_equal(team_for_slot(list(), 3), "Team 3")
  expect_equal(team_for_slot(list("1" = "JGrahnasaurs"), 3), "Team 3")
})

test_that("team_for_slot returns the mapped name when the slot is known", {
  team_map <- list("1" = "JGrahnasaurs", "3" = "Bob's Squad")

  expect_equal(team_for_slot(team_map, 1), "JGrahnasaurs")
  expect_equal(team_for_slot(team_map, 3), "Bob's Squad")
})

test_that("next_team_name is NULL before the draft has a my_slot (setup not run yet)", {
  state <- list(drafted_players = c(), teams = NULL, team_by_slot = list())

  expect_null(next_team_name(state))
})

test_that("next_team_name resolves the next picker's name via slot_on_the_clock", {
  # 10-team league, no picks yet: pick 1 is slot 1
  state <- list(drafted_players = c(), teams = 10,
                team_by_slot = list("1" = "JGrahnasaurs"))

  expect_equal(next_team_name(state), "JGrahnasaurs")
})

test_that("next_team_name falls back to a placeholder for an opponent slot with no name yet", {
  state <- list(drafted_players = c(), teams = 10, team_by_slot = list())

  expect_equal(next_team_name(state), "Team 1")
})

test_that("next_team_name advances as picks are logged", {
  # 1 pick made -> pick 2 is next -> slot 2 on the clock
  state <- list(drafted_players = c(101), teams = 10, team_by_slot = list())

  expect_equal(next_team_name(state), "Team 2")
})
