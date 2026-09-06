test_that("a pick_made event puts the player on that team's roster after replay", {
  log_path <- tempfile(fileext = ".jsonl")
  append_pick_event(log_path, list(type = "draft_started", teams = 2))
  append_pick_event(log_path, list(type = "pick_made", slot = 1, team = "JGrahnasaurs", player_key = 101))

  state <- replay_pick_log(log_path)

  expect_true(101 %in% state$rosters[["JGrahnasaurs"]])
})

test_that("picks across multiple teams stay on their own rosters, not mixed together", {
  log_path <- tempfile(fileext = ".jsonl")
  append_pick_event(log_path, list(type = "draft_started", teams = 2))
  append_pick_event(log_path, list(type = "pick_made", slot = 1, team = "JGrahnasaurs", player_key = 101))
  append_pick_event(log_path, list(type = "pick_made", slot = 2, team = "Rival", player_key = 202))

  state <- replay_pick_log(log_path)

  expect_equal(state$rosters[["JGrahnasaurs"]], 101)
  expect_equal(state$rosters[["Rival"]], 202)
})

test_that("pick_corrected undoes the last pick_made without touching earlier picks", {
  log_path <- tempfile(fileext = ".jsonl")
  append_pick_event(log_path, list(type = "draft_started", teams = 2))
  append_pick_event(log_path, list(type = "pick_made", slot = 1, team = "JGrahnasaurs", player_key = 101))
  append_pick_event(log_path, list(type = "pick_made", slot = 2, team = "Rival", player_key = 202))
  append_pick_event(log_path, list(type = "pick_corrected", slot = 2))

  state <- replay_pick_log(log_path)

  expect_null(state$rosters[["Rival"]])
  expect_equal(state$rosters[["JGrahnasaurs"]], 101)
})

test_that("drafted_players excludes an undone pick, so it goes back into the available pool", {
  log_path <- tempfile(fileext = ".jsonl")
  append_pick_event(log_path, list(type = "draft_started", teams = 2))
  append_pick_event(log_path, list(type = "pick_made", slot = 1, team = "JGrahnasaurs", player_key = 101))
  append_pick_event(log_path, list(type = "pick_made", slot = 2, team = "Rival", player_key = 202))
  append_pick_event(log_path, list(type = "pick_corrected", slot = 2))

  state <- replay_pick_log(log_path)

  expect_equal(state$drafted_players, 101)
})

test_that("replay_pick_log exposes last_pick_slot as the slot of the most recent live pick", {
  log_path <- tempfile(fileext = ".jsonl")
  append_pick_event(log_path, list(type = "draft_started", teams = 2))
  append_pick_event(log_path, list(type = "pick_made", slot = 1, team = "JGrahnasaurs", player_key = 101))
  append_pick_event(log_path, list(type = "pick_made", slot = 2, team = "Rival", player_key = 202))

  state <- replay_pick_log(log_path)

  expect_equal(state$last_pick_slot, 2)
})

test_that("replay_pick_log's last_pick_slot is NULL when no picks have been made yet", {
  log_path <- tempfile(fileext = ".jsonl")
  append_pick_event(log_path, list(type = "draft_started", teams = 2))

  state <- replay_pick_log(log_path)

  expect_null(state$last_pick_slot)
})

test_that("replay_pick_log's last_pick_slot falls back to the prior live pick once the latest is undone", {
  log_path <- tempfile(fileext = ".jsonl")
  append_pick_event(log_path, list(type = "draft_started", teams = 2))
  append_pick_event(log_path, list(type = "pick_made", slot = 1, team = "JGrahnasaurs", player_key = 101))
  append_pick_event(log_path, list(type = "pick_made", slot = 2, team = "Rival", player_key = 202))
  append_pick_event(log_path, list(type = "pick_corrected", slot = 2))

  state <- replay_pick_log(log_path)

  expect_equal(state$last_pick_slot, 1)
})

test_that("replay_pick_log's last_pick_slot is NULL once every pick has been undone", {
  log_path <- tempfile(fileext = ".jsonl")
  append_pick_event(log_path, list(type = "draft_started", teams = 2))
  append_pick_event(log_path, list(type = "pick_made", slot = 1, team = "JGrahnasaurs", player_key = 101))
  append_pick_event(log_path, list(type = "pick_corrected", slot = 1))

  state <- replay_pick_log(log_path)

  expect_null(state$last_pick_slot)
})

test_that("replay_pick_log seeds team_by_slot with your own team name at your own slot", {
  log_path <- tempfile(fileext = ".jsonl")
  start_draft(log_path, teams = 10, my_team = "JGrahnasaurs", my_slot = 7)

  state <- replay_pick_log(log_path)

  expect_equal(state$team_by_slot[["7"]], "JGrahnasaurs")
})

test_that("replay_pick_log records an opponent's team name at their draft slot from a pick_made event", {
  log_path <- tempfile(fileext = ".jsonl")
  start_draft(log_path, teams = 10, my_team = "JGrahnasaurs", my_slot = 7)
  # pick 1 (overall) is slot 1's turn in round 1 (odd round: s = pos)
  append_pick_event(log_path, list(type = "pick_made", slot = 1, team = "Bob's Squad", player_key = 101))

  state <- replay_pick_log(log_path)

  expect_equal(state$team_by_slot[["1"]], "Bob's Squad")
})

test_that("replay_pick_log's team_by_slot renames a slot when a later pick uses a different name", {
  log_path <- tempfile(fileext = ".jsonl")
  start_draft(log_path, teams = 10, my_team = "JGrahnasaurs", my_slot = 7)
  append_pick_event(log_path, list(type = "pick_made", slot = 1, team = "Team 1", player_key = 101))
  # pick 20 (overall) is also slot 1's turn (round 2 is even: s = teams - pos + 1)
  append_pick_event(log_path, list(type = "pick_made", slot = 20, team = "Bob's Squad", player_key = 102))

  state <- replay_pick_log(log_path)

  expect_equal(state$team_by_slot[["1"]], "Bob's Squad")
})

test_that("remaining_draft_pool drops drafted players but keeps an undone pick's player available", {
  log_path <- tempfile(fileext = ".jsonl")
  append_pick_event(log_path, list(type = "draft_started", teams = 2))
  append_pick_event(log_path, list(type = "pick_made", slot = 1, team = "JGrahnasaurs", player_key = 101))
  append_pick_event(log_path, list(type = "pick_made", slot = 2, team = "Rival", player_key = 202))
  append_pick_event(log_path, list(type = "pick_corrected", slot = 2))
  state <- replay_pick_log(log_path)

  pool <- data.frame(player_key = c(101, 202, 303), player = c("A", "B", "C"))

  result <- remaining_draft_pool(pool, state)

  expect_equal(sort(result$player_key), c(202, 303))
})

test_that("start_draft appends a draft_started event that replay_pick_log reads back", {
  log_path <- tempfile(fileext = ".jsonl")
  start_draft(log_path, teams = 10, my_team = "JGrahnasaurs", my_slot = 7)

  state <- replay_pick_log(log_path)

  expect_equal(state$my_team, "JGrahnasaurs")
  expect_equal(state$my_slot, 7)
  expect_equal(state$teams, 10)
})

test_that("replay_pick_log returns a NULL my_slot for a draft_started event that predates setup-screen capture", {
  log_path <- tempfile(fileext = ".jsonl")
  append_pick_event(log_path, list(type = "draft_started", teams = 2))

  state <- replay_pick_log(log_path)

  expect_null(state$my_slot)
  expect_null(state$my_team)
})

test_that("needs_setup is TRUE when no Pick Log file exists yet", {
  log_path <- tempfile(fileext = ".jsonl")

  expect_true(needs_setup(log_path))
})

test_that("needs_setup is FALSE once a draft_started event carries a my_slot", {
  log_path <- tempfile(fileext = ".jsonl")
  start_draft(log_path, teams = 10, my_team = "JGrahnasaurs", my_slot = 3)

  expect_false(needs_setup(log_path))
})

test_that("needs_setup is TRUE for an existing log whose draft_started event predates my_slot capture", {
  log_path <- tempfile(fileext = ".jsonl")
  append_pick_event(log_path, list(type = "draft_started", teams = 2))

  expect_true(needs_setup(log_path))
})

test_that("valid_my_slot accepts a whole number within 1..teams", {
  expect_true(valid_my_slot(1, teams = 10))
  expect_true(valid_my_slot(10, teams = 10))
  expect_true(valid_my_slot(7, teams = 10))
})

test_that("valid_my_slot rejects out-of-range, non-integer, or missing input", {
  expect_false(valid_my_slot(0, teams = 10))
  expect_false(valid_my_slot(11, teams = 10))
  expect_false(valid_my_slot(3.5, teams = 10))
  expect_false(valid_my_slot(NA, teams = 10))
  expect_false(valid_my_slot(NULL, teams = 10))
})

test_that("combined_selectable_pool includes players from both the Board and the fallback section", {
  draft_board <- data.frame(
    player_key = c(1, 2), player = c("Board Guy A", "Board Guy B"),
    pos = c("QB", "RB"), team = c("KC", "SF"),
    tier = c(1, 1), vor = c(10, 9)
  )
  draft_fallback <- data.frame(
    player_key = c(3, 4), player = c("Ashton Jeanty", "Travis Hunter"),
    pos = c("RB", "WR"), team = c("LV", "JAX"),
    ecr = c(50, 55)
  )

  pool <- combined_selectable_pool(draft_board, draft_fallback)

  expect_setequal(pool$player_key, c(1, 2, 3, 4))
  expect_true("Ashton Jeanty" %in% pool$player)
  expect_true("Travis Hunter" %in% pool$player)
})

test_that("combined_selectable_pool keeps only the shared columns needed for a dropdown label", {
  draft_board <- data.frame(
    player_key = 1, player = "Board Guy", pos = "QB", team = "KC",
    tier = 1, vor = 10
  )
  draft_fallback <- data.frame(
    player_key = 2, player = "Rookie Guy", pos = "RB", team = "LV",
    ecr = 50
  )

  pool <- combined_selectable_pool(draft_board, draft_fallback)

  expect_setequal(names(pool), c("player_key", "player", "pos", "team"))
})

test_that("combined_selectable_pool works with remaining_draft_pool to drop players drafted from either table", {
  draft_board <- data.frame(
    player_key = c(1, 2), player = c("Board Guy A", "Board Guy B"),
    pos = c("QB", "RB"), team = c("KC", "SF"),
    tier = c(1, 1), vor = c(10, 9)
  )
  draft_fallback <- data.frame(
    player_key = c(3, 4), player = c("Ashton Jeanty", "Travis Hunter"),
    pos = c("RB", "WR"), team = c("LV", "JAX"),
    ecr = c(50, 55)
  )
  pick_log_state <- list(drafted_players = c(2, 3))

  pool <- remaining_draft_pool(combined_selectable_pool(draft_board, draft_fallback), pick_log_state)

  expect_setequal(pool$player_key, c(1, 4))
})
