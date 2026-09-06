# Synthetic fixture, not the real config — the real league scoring changes
# (e.g. dropping the 300-yard bonus) shouldn't break these golden tests, and
# this fixture exercises paths (bonus, first_down) the real config no longer
# uses but score_player_week() must still support for other leagues.
scoring <- list(
  passing = list(yards = 0.04, td = 4, int = -2,
                 bonus = list(list(stat = "yards", gte = 300, points = 3))),
  rushing = list(yards = 0.1, td = 6, first_down = 0.5),
  receiving = list(reception = 0.5, yards = 0.1, td = 6,
                    position_premium = list(TE = 0.0)),
  misc = list(fumble_lost = -2, two_point = 2),
  kicking = list(fg_0_39 = 3, fg_40_49 = 4, fg_50_plus = 5, fg_miss = 0,
                 pat_made = 1, pat_miss = 0)
)

test_that("passing: yards, TDs, INTs, and the 300-yard bonus", {
  row <- data.frame(
    position = "QB",
    passing_yards = 320, passing_tds = 3, passing_interceptions = 1
  )
  # 320*0.04 + 3*4 + 1*(-2) + 3 (>=300yd bonus) = 12.8 + 12 - 2 + 3
  expect_equal(score_player_week(row, scoring), 25.8)
})

test_that("passing: no bonus below the yardage threshold", {
  row <- data.frame(position = "QB", passing_yards = 299, passing_tds = 0, passing_interceptions = 0)
  expect_equal(score_player_week(row, scoring), 299 * 0.04)
})

test_that("rushing: yards, TDs, first downs, and a lost fumble", {
  row <- data.frame(
    position = "RB",
    rushing_yards = 100, rushing_tds = 1, rushing_first_downs = 5, rushing_fumbles_lost = 1
  )
  # 100*0.1 + 1*6 + 5*0.5 + 1*(-2) = 10 + 6 + 2.5 - 2
  expect_equal(score_player_week(row, scoring), 16.5)
})

test_that("receiving: WR gets no position premium", {
  row <- data.frame(position = "WR", receptions = 8, receiving_yards = 90, receiving_tds = 1)
  # 8*0.5 + 90*0.1 + 1*6 = 4 + 9 + 6
  expect_equal(score_player_week(row, scoring), 19)
})

test_that("receiving: TE position premium is applied (currently 0.0, but the path must fire)", {
  row <- data.frame(position = "TE", receptions = 5, receiving_yards = 50, receiving_tds = 0)
  # 5*(0.5 + 0.0) + 50*0.1 = 2.5 + 5
  expect_equal(score_player_week(row, scoring), 7.5)
})

test_that("misc: two-point conversions score regardless of how they were scored", {
  row <- data.frame(position = "RB", rushing_2pt_conversions = 1)
  expect_equal(score_player_week(row, scoring), 2)
})

test_that("kicking: field goal tiers, a miss, and PATs", {
  row <- data.frame(
    position = "K",
    fg_made_20_29 = 1, fg_made_40_49 = 1, fg_made_50_59 = 1,
    fg_missed = 1, pat_made = 3, pat_missed = 1
  )
  # fg_0_39: 1*3, fg_40_49: 1*4, fg_50_plus: 1*5, fg_miss: 1*0, pat_made: 3*1, pat_miss: 1*0
  expect_equal(score_player_week(row, scoring), 3 + 4 + 5 + 0 + 3 + 0)
})

test_that("a fully empty stat line scores zero", {
  row <- data.frame(position = "RB")
  expect_equal(score_player_week(row, scoring), 0)
})

test_that("is vectorized across multiple rows in one call", {
  rows <- data.frame(
    position = c("QB", "RB"),
    passing_yards = c(320, 0), passing_tds = c(3, 0), passing_interceptions = c(1, 0),
    rushing_yards = c(0, 100), rushing_tds = c(0, 1)
  )
  result <- score_player_week(rows, scoring)
  expect_equal(result, c(25.8, 10 + 6))
})
