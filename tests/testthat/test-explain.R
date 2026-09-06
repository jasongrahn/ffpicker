source(test_path("helper-pick_log.R"))
source(test_path("../../R/79_scarcity.R"))
source(test_path("../../R/90_explain.R"))

# Minimal scarcity_report()-shaped frame; these functions only read its columns.
mk_report <- function(...) {
  base <- data.frame(
    pos = c("QB", "RB", "WR", "TE"),
    still_needed = c(1, 2, 2, 1),
    tier_supply = c(8, 3, 9, 4),
    picks_until_turn = 11L,
    survives = c(TRUE, FALSE, TRUE, FALSE),
    vor_best = c(40, 120, 100, 90),
    deferred = FALSE,
    urgency = c(2L, 1L, 2L, 1L),
    stringsAsFactors = FALSE
  )
  mods <- list(...)
  for (nm in names(mods)) base[[nm]] <- mods[[nm]]
  base
}

test_that("position_name() spells out codes and passes unknowns through", {
  expect_equal(unname(position_name(c("RB", "DST"))), c("running back", "defense"))
  expect_equal(unname(position_name("ZZ")), "ZZ")
})

test_that("explain_scarcity() names the position that won't survive the turn", {
  msg <- explain_scarcity(mk_report())
  # RB and TE both urgency 1; RB has more value at stake so it wins the tiebreak.
  expect_match(msg, "Take a running back now")
  expect_match(msg, "Only 3 running backs left")
  expect_match(msg, "11 picks")
})

test_that("explain_scarcity() says no rush when the live tier survives", {
  msg <- explain_scarcity(mk_report(urgency = c(2L, 2L, 2L, 2L),
                                    survives = rep(TRUE, 4)))
  expect_match(msg, "^No rush")
  expect_match(msg, "best player available")
})

test_that("explain_scarcity() singularises a one-pick gap", {
  msg <- explain_scarcity(mk_report(picks_until_turn = 1L))
  expect_match(msg, "1 pick until")
  expect_false(grepl("1 picks", msg))
})

test_that("explain_scarcity() handles being on the clock", {
  msg <- explain_scarcity(mk_report(picks_until_turn = 0L))
  expect_match(msg, "on the clock")
})

test_that("explain_scarcity() degrades when my_slot isn't captured yet", {
  # picks_until_my_turn() returns NULL pre-setup, so the whole column is NA.
  msg <- explain_scarcity(mk_report(picks_until_turn = NA_integer_,
                                    survives = NA, urgency = NA_integer_))
  expect_match(msg, "Still need")
  expect_match(msg, "running back")
  expect_match(msg, "draft slot")
})

test_that("explain_scarcity() reports a full starting lineup", {
  msg <- explain_scarcity(mk_report(still_needed = c(0, 0, 0, 0)))
  expect_match(msg, "Starting lineup is full")
})

test_that("explain_scarcity() never returns empty on an empty report", {
  expect_equal(explain_scarcity(mk_report()[0, ]), "No board data yet.")
  expect_equal(explain_scarcity(NULL), "No board data yet.")
})

test_that("scarcity_display() sorts most-urgent-first with readable columns", {
  out <- scarcity_display(mk_report())
  expect_equal(names(out),
               c("Position", "Need", "Left at this level",
                 "Picks to your turn", "Status"))
  # urgency 1 rows first, more value at stake ahead of less within the same urgency.
  expect_equal(out$Position[1:2], c("running back", "tight end"))
  expect_equal(out$Status[1:2], c("TAKE NOW", "TAKE NOW"))
  expect_equal(out$Status[3], "Can wait")
})

test_that("scarcity_display() renders NA urgency as a dash, not NA", {
  out <- scarcity_display(mk_report(urgency = NA_integer_,
                                    picks_until_turn = NA_integer_))
  expect_true(all(out$Status == "—"))
})

test_that("scarcity_input() keeps fallback players behind every ranked player", {
  board <- data.frame(player_key = 1:3, player = c("a", "b", "c"),
                      pos = c("RB", "RB", "WR"), team = "X", tier = c(1L, 2L, 1L),
                      vor = c(100, 50, 80), stringsAsFactors = FALSE)
  fallback <- data.frame(player_key = 4:5, player = c("rook", "def"),
                         pos = c("RB", "DST"), team = "Y", ecr = c(20, 99),
                         stringsAsFactors = FALSE)
  out <- scarcity_input(board, fallback)
  expect_equal(nrow(out), 5)
  expect_equal(out$tier[out$player_key %in% 4:5], c(3L, 3L))
  # Fallback players carry no VOR, so they must not look like replacement-level
  # (0) players to the value tiebreak -- they are unmeasured, not measured-bad.
  expect_true(all(is.na(out$vor[out$player_key %in% 4:5])))
  # DST exists only in the fallback; without this it can never be counted as need.
  expect_true("DST" %in% out$pos)
})

test_that("scarcity_report() counts a fallback pick against roster need", {
  # A rookie RB drafted from the fallback section is still an RB. Before
  # scarcity_input(), that pick was unclassifiable and RB need stayed at 2.
  board <- data.frame(player_key = 1:6, player = paste0("p", 1:6),
                      pos = c("RB", "RB", "WR", "WR", "TE", "QB"),
                      team = "X", tier = 1L, vor = c(100, 90, 80, 70, 60, 50),
                      stringsAsFactors = FALSE)
  fallback <- data.frame(player_key = 7L, player = "rookie rb", pos = "RB",
                         team = "Y", ecr = 5, stringsAsFactors = FALSE)
  cfg <- list(teams = 10, roster = list(
    starters = list(QB = 1, RB = 2, WR = 2, TE = 1, FLEX = 1, K = 1, DST = 1),
    flex_eligible = list(FLEX = c("RB", "WR", "TE"))
  ))
  state <- list(rosters = list(me = 7L), my_team = "me", my_slot = 1,
                teams = 10, drafted_players = 7L)

  rpt <- scarcity_report(scarcity_input(board, fallback), state, cfg)
  # 1 RB drafted -> dedicated need 1, FLEX still open -> 1 + 1 = 2, not 3.
  expect_equal(rpt$still_needed[rpt$pos == "RB"], 2)
})

mk_board <- function() data.frame(
  player_key = 1:5, player = c("Top RB", "Mid RB", "Low RB", "A WR", "A TE"),
  pos = c("RB", "RB", "RB", "WR", "TE"), team = c("ATL", "DET", "BUF", "SEA", "ARI"),
  tier = c(1L, 2L, 3L, 1L, 1L), vor = c(180, 90, 40, 150, 99),
  stringsAsFactors = FALSE
)
mk_fb <- function() data.frame(
  player_key = 6:8, player = c("Rookie RB", "Bears D", "Jets D"),
  pos = c("RB", "DST", "DST"), team = c("LV", "CHI", "NYJ"), ecr = c(40, 88, 95),
  stringsAsFactors = FALSE
)

test_that("target_position() picks the most urgent needed position", {
  expect_equal(target_position(mk_report()), "RB")
  expect_true(is.na(target_position(mk_report(still_needed = c(0, 0, 0, 0)))))
  expect_true(is.na(target_position(NULL)))
})

test_that("recommend_picks() names ranked players best-VOR-first", {
  out <- recommend_picks(mk_report(), mk_board(), mk_fb())
  expect_equal(out$Player, c("Top RB", "Mid RB", "Low RB"))
  expect_equal(out$Team[1], "ATL")
  expect_equal(out$Value[1], "+180 pts")
})

test_that("recommend_picks() tops up from the fallback when the Board runs short", {
  board <- mk_board()[mk_board()$player == "Top RB", ]
  out <- recommend_picks(mk_report(), board, mk_fb())
  expect_equal(out$Player, c("Top RB", "Rookie RB"))
  expect_true(is.na(out$Tier[2]))
  expect_equal(out$Value[2], "expert rank 40")
})

test_that("recommend_picks() finds DSTs, which exist only in the fallback", {
  rpt <- data.frame(pos = "DST", still_needed = 1, tier_supply = 32,
                    picks_until_turn = 5L, survives = TRUE, urgency = 1L,
                    stringsAsFactors = FALSE)
  out <- recommend_picks(rpt, mk_board(), mk_fb())
  expect_equal(out$Player, c("Bears D", "Jets D"))
})

test_that("recommend_picks() returns no rows when no starter slot is open", {
  out <- recommend_picks(mk_report(still_needed = c(0, 0, 0, 0)), mk_board(), mk_fb())
  expect_equal(nrow(out), 0)
  expect_equal(names(out), c("Player", "Pos", "Team", "Tier", "Value"))
})

test_that("explain_scarcity() names the player, with position and team attached", {
  picks <- recommend_picks(mk_report(), mk_board(), mk_fb())
  msg <- explain_scarcity(mk_report(), picks)
  expect_match(msg, "Take Top RB \\(RB, ATL\\) now", perl = TRUE)
})

test_that("explain_scarcity() falls back to the position when given no picks", {
  expect_match(explain_scarcity(mk_report()), "Take a running back now")
})

# --- Regression: kicker recommended first overall (reported 2026-09-06) ---

test_that("target_position breaks an urgency tie on value at stake, not alphabetically", {
  # The real pick-1 shape: assign_tiers() works within a position, so every
  # position's tier 1 holds exactly one player. urgency and tier_supply tie
  # across K/RB/TE/WR, and the old sort fell through to the report's own
  # alphabetical row order -- answering "kicker" first overall.
  rpt <- data.frame(
    pos = c("K", "RB", "TE", "WR"),
    still_needed = c(1, 3, 2, 3),
    tier_supply = 1,
    picks_until_turn = 4L,
    survives = FALSE,
    vor_best = c(61.4, 142.1, 92.0, 116.6),
    deferred = FALSE,
    urgency = 1L,
    stringsAsFactors = FALSE
  )

  expect_equal(target_position(rpt), "RB")
  # And the displayed guide agrees with the headline, rather than contradicting it.
  expect_equal(scarcity_display(rpt)$Position[1], "running back")
})

test_that("target_position still falls back to thinnest tier when value at stake ties", {
  rpt <- data.frame(
    pos = c("WR", "RB"), still_needed = 2, tier_supply = c(9, 3),
    picks_until_turn = 4L, survives = FALSE, vor_best = 100, deferred = FALSE,
    urgency = 1L, stringsAsFactors = FALSE
  )
  expect_equal(target_position(rpt), "RB")
})

test_that("target_position tolerates a report with no vor_best column instead of erroring", {
  # Draft night runs on a 1-minute clock: degrading to the old tiebreak is
  # recoverable, a crashed app is not.
  rpt <- data.frame(
    pos = c("WR", "RB"), still_needed = 2, tier_supply = c(9, 3),
    picks_until_turn = 4L, survives = FALSE, urgency = 1L,
    stringsAsFactors = FALSE
  )
  expect_equal(target_position(rpt), "RB")
  expect_silent(scarcity_display(rpt))
})

test_that("a deferred position sorts below every live one and reads as wait-til-late", {
  rpt <- data.frame(
    pos = c("K", "RB"), still_needed = c(1, 3), tier_supply = 1,
    picks_until_turn = 4L, survives = FALSE, vor_best = c(61.4, 142.1),
    deferred = c(TRUE, FALSE), urgency = c(5L, 1L), stringsAsFactors = FALSE
  )

  expect_equal(target_position(rpt), "RB")
  disp <- scarcity_display(rpt)
  expect_equal(disp$Position[nrow(disp)], "kicker")
  expect_equal(disp$Status[disp$Position == "kicker"], "Wait til late")
})

# --- Regression: advice line named a WR while counting TEs (2026-09-06) ---
# Screenshot read: "Take CeeDee Lamb (WR, DAL) now. Only 1 tight end left at
# that level and 8 picks until your turn -- likely gone."

test_that("explain_scarcity() counts the position of the player it names, not a different one", {
  # WR and TE both urgency 1 with tier_supply 1. WR wins on value at stake, so
  # recommend_picks() names a receiver -- and the sentence must say receiver.
  rpt <- data.frame(
    pos = c("QB", "RB", "TE", "WR"),
    still_needed = c(1, 2, 2, 2),
    tier_supply = c(5, 4, 1, 1),
    picks_until_turn = 8L,
    survives = FALSE,
    vor_best = c(45, 66.9, 26.5, 68),
    deferred = FALSE,
    urgency = 1L,
    stringsAsFactors = FALSE
  )
  picks <- data.frame(Player = "CeeDee Lamb", Pos = "WR", Team = "DAL",
                      Tier = 6L, Value = "+68 pts", stringsAsFactors = FALSE)

  msg <- explain_scarcity(rpt, picks)

  expect_match(msg, "CeeDee Lamb \\(WR, DAL\\)", fixed = FALSE)
  expect_match(msg, "1 wide receiver left")
  expect_false(grepl("tight end", msg))
})

test_that("explain_scarcity() describes the named player's position even if it is not the top-ranked one", {
  # Belt and braces: if a caller hands in a `picks` from some other ranking,
  # the sentence still stays internally consistent rather than mixing the two.
  rpt <- data.frame(
    pos = c("RB", "TE"), still_needed = 2, tier_supply = c(4, 1),
    picks_until_turn = 8L, survives = FALSE, vor_best = c(140, 26.5),
    deferred = FALSE, urgency = 1L, stringsAsFactors = FALSE
  )
  picks <- data.frame(Player = "Trey McBride", Pos = "TE", Team = "ARI",
                      Tier = 1L, Value = "+27 pts", stringsAsFactors = FALSE)

  msg <- explain_scarcity(rpt, picks)

  expect_match(msg, "Trey McBride")
  expect_match(msg, "1 tight end left")
  expect_false(grepl("running back", msg))
})

test_that("rank_positions() is the single ordering all three callers share", {
  rpt <- data.frame(
    pos = c("K", "RB", "TE", "WR"), still_needed = c(1, 3, 2, 3),
    tier_supply = 1, picks_until_turn = 4L, survives = FALSE,
    vor_best = c(61.4, 142.1, 92.0, 116.6), deferred = FALSE, urgency = 1L,
    stringsAsFactors = FALSE
  )
  ranked <- rank_positions(rpt)
  expect_equal(ranked$pos, c("RB", "WR", "TE", "K"))
  # All three public callers must agree with it, by construction.
  expect_equal(target_position(rpt), ranked$pos[1])
  expect_equal(scarcity_display(rpt)$Position[1], unname(position_name(ranked$pos[1])))
  expect_match(explain_scarcity(rpt), position_name(ranked$pos[1]))
})
