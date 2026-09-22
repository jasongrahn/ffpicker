test_that("a Monday starter's deadline is set by his Sunday replacement", {
  # The 2026 week 2 Adams case, in miniature. His own kickoff is Monday
  # 20:15, but the only WR who could replace him plays Sunday 13:00.
  # Reporting the Monday time is the bug this function exists to prevent.
  d <- build_slot_deadlines(fake_roster(), fake_schedule(), fake_league(), 2)
  mon <- d[d$player == "Monday WR", ]

  expect_equal(format(mon$own_kickoff, "%Y-%m-%d %H:%M"), "2026-09-21 20:15")
  expect_equal(format(mon$all_options_until, "%Y-%m-%d %H:%M"), "2026-09-20 13:00")
  expect_equal(mon$binding, "replacement")
  expect_lt(mon$all_options_until, mon$own_kickoff)
})

test_that("a slot with no eligible bench player is forced", {
  d <- build_slot_deadlines(fake_roster(), fake_schedule(), fake_league(), 2)
  te <- d[d$player == "Only TE", ]

  expect_equal(te$n_replacements, 0L)
  expect_equal(te$all_options_until, te$own_kickoff)
  expect_match(te$binding, "no bench option")
})

test_that("last_change_at can outlive all_options_until", {
  # Week 3: the bench WR plays Monday, the starter Sunday night. The full
  # option set dies at the Sunday early game, but *a* change stays legal
  # until the starter himself kicks off. Two different questions.
  r <- fake_roster()
  r$slot[r$player == "Sunday WR"] <- "BN"; r$started[r$player == "Sunday WR"] <- FALSE
  d <- build_slot_deadlines(r, fake_schedule(), fake_league(), 3)
  mon <- d[d$player == "Monday WR", ]

  expect_gt(mon$last_change_at, mon$all_options_until)
})

test_that("week filter survives a data.table schedule", {
  # load_schedules() returns a data.table, whose `[` evaluates i inside the
  # table's frame -- `schedule$week == wk` silently became `week == week`
  # and returned every game of the season. Guard the regression.
  skip_if_not_installed("data.table")
  dt <- data.table::as.data.table(fake_schedule())
  ko <- team_kickoffs(dt, 2)

  expect_equal(nrow(ko), 8L)          # 4 week-2 games x 2 teams
  expect_false("PHI" %in% ko$team[ko$kickoff > as.POSIXct("2026-09-22")])
})

test_that("slot eligibility comes from config and accepts DEF or DST", {
  elig <- slot_eligibility(list(roster = list(
    starters = list(QB = 1L, FLEX = 1L, DST = 1L),
    flex_eligible = list(FLEX = list("RB", "WR", "TE"))
  )))

  expect_equal(elig$FLEX, c("RB", "WR", "TE"))
  expect_setequal(elig$DEF, c("DST", "DEF"))   # Yahoo exports say DEF
})
