source(file.path("..", "..", "R", "42_deadlines.R"))

# Minimal two-week fixture. Deliberately mirrors the 2026 week 2 shape that
# exposed the bug: a Monday starter whose only replacements play Sunday early.
fake_schedule <- function() {
  data.frame(
    # Week 3 deliberately staggers the two bench WRs (TEN Sun early, CHI Sun
    # night) behind a Monday starter, so the two deadlines separate.
    week      = c(2L, 2L, 2L, 2L, 3L, 3L, 3L, 3L),
    gameday   = c("2026-09-20", "2026-09-20", "2026-09-20", "2026-09-21",
                  "2026-09-27", "2026-09-27", "2026-09-27", "2026-09-28"),
    gametime  = c("13:00", "13:00", "16:25", "20:15",
                  "13:00", "16:25", "20:20", "20:15"),
    home_team = c("CHI", "TEN", "DAL", "LA", "TEN", "DAL", "CHI", "LA"),
    away_team = c("MIN", "PHI", "WAS", "NYG", "PHI", "WAS", "MIN", "NYG"),
    stringsAsFactors = FALSE
  )
}

fake_league <- function() {
  list(roster = list(
    starters = list(WR = 2L, TE = 1L, FLEX = 1L),
    flex_eligible = list(FLEX = list("RB", "WR", "TE"))
  ))
}

fake_roster <- function() {
  data.frame(
    player   = c("Monday WR", "Sunday WR", "Bench WR", "Only TE"),
    pos      = c("WR", "WR", "WR", "TE"),
    nfl_team = c("LA", "TEN", "CHI", "DAL"),
    slot     = c("WR", "WR", "BN", "TE"),
    started  = c(TRUE, TRUE, FALSE, TRUE),
    stringsAsFactors = FALSE
  )
}
