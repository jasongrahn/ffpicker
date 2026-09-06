real_rankings_path <- file.path("..", "..", "data", "raw", "ff_rankings.parquet")

test_that("build_dst_pool filters to redraft-overall DST rows only", {
  tmp <- tempfile(fileext = ".parquet")
  fixture <- data.frame(
    page_type = c("redraft-overall", "redraft-overall", "dynasty", "redraft-overall"),
    pos       = c("DST", "QB", "DST", "DST"),
    player    = c("Test Defense", "Test QB", "Other Defense", "Jaguars"),
    team      = c("SF", "SF", "KC", "JAC"),
    id        = c(1, 2, 3, 4),
    ecr       = c(100, 5, 50, 150),
    bye       = c(9, 9, 10, 7)
  )
  arrow::write_parquet(fixture, tmp)

  pool <- build_dst_pool(tmp)

  # row 2 (QB) fails pos == "DST"; row 3 (KC) fails page_type == "redraft-overall"
  expect_equal(nrow(pool), 2)
  expect_true(all(pool$pos == "DST"))
  expect_setequal(pool$team, c("SF", "JAX"))  # JAC normalized to JAX, see below
})

test_that("team abbreviations are normalized to nflreadr's canonical set (the one deliberate name-adjacent join in this codebase, per CLAUDE.md)", {
  pool <- build_dst_pool(real_rankings_path)

  # Verified live 2026-09-06: FantasyPros' redraft-overall DST rows use "JAC"
  # and "LAR", nflreadr's canonical team_abbr_mapping targets are "JAX" and
  # "LA". Every other one of the 32 abbreviations already agrees.
  expect_false("JAC" %in% pool$team)
  expect_true("JAX" %in% pool$team)
  expect_false("LAR" %in% pool$team)
  expect_true("LA" %in% pool$team)

  # every normalized team abbreviation must be a real nflreadr team code
  canonical_teams <- sort(setdiff(unique(nflreadr::team_abbr_mapping), c("AFC", "NFC", "NFL")))
  expect_true(all(pool$team %in% canonical_teams))
})

test_that("build_dst_pool produces exactly the 32 real NFL team defenses", {
  pool <- build_dst_pool(real_rankings_path)

  expect_equal(nrow(pool), 32)
  expect_equal(length(unique(pool$team)), 32)
})

test_that("every DST gets a unique, non-missing synthetic player_key", {
  pool <- build_dst_pool(real_rankings_path)

  expect_false(anyNA(pool$player_key))
  expect_equal(length(unique(pool$player_key)), nrow(pool))
})

test_that("synthetic player_key is always negative -- disjoint by sign, not by magnitude", {
  # build_dim_player() (R/20_stage.R) assigns player_key <- seq_len(nrow(dim)),
  # i.e. every real player_key is a positive integer starting at 1, forever --
  # no matter how large the crosswalk grows. Any negative integer is therefore
  # provably disjoint from every real player_key without needing to track the
  # real table's current max value. This is the single correctness property
  # this file exists to guarantee.
  pool <- build_dst_pool(real_rankings_path)

  expect_true(all(pool$player_key < 0))
  expect_true(all(pool$player_key == as.integer(pool$player_key)))
})

test_that("the synthetic key is keyed off team abbreviation, not row order -- stable across re-ingests", {
  fixture <- data.frame(
    page_type = "redraft-overall",
    pos = "DST",
    player = c("Team A", "Team B"),
    team = c("SF", "KC"),
    id = c(1, 2),
    ecr = c(10, 20),
    bye = c(9, 10)
  )

  tmp1 <- tempfile(fileext = ".parquet")
  arrow::write_parquet(fixture, tmp1)
  pool1 <- build_dst_pool(tmp1)

  tmp2 <- tempfile(fileext = ".parquet")
  arrow::write_parquet(fixture[c(2, 1), ], tmp2)  # rows reversed
  pool2 <- build_dst_pool(tmp2)

  expect_equal(
    pool1$player_key[pool1$team == "SF"],
    pool2$player_key[pool2$team == "SF"]
  )
  expect_equal(
    pool1$player_key[pool1$team == "KC"],
    pool2$player_key[pool2$team == "KC"]
  )
})

test_that("no synthetic DST player_key collides with any real dim_player player_key", {
  dim_player <- build_dim_player(
    file.path("..", "..", "data", "raw", "ff_playerids.parquet"),
    file.path("..", "..", "data", "raw", "players.parquet")
  )
  pool <- build_dst_pool(real_rankings_path)

  # the disjointness proof rests on this sign invariant holding on both sides
  expect_true(all(dim_player$player_key > 0))
  expect_true(all(pool$player_key < 0))
  expect_equal(length(intersect(pool$player_key, dim_player$player_key)), 0)
})

test_that("build_dst_pool's output shape matches build_fallback_board's, so the two can be rbind()ed into one selectable pool", {
  pool <- build_dst_pool(real_rankings_path)

  expected_cols <- c(
    "player_key", "player", "pos", "team", "ecr", "bye",
    "ppg_current", "games_current", "availability_rate",
    "has_current_data", "projected_points"
  )
  expect_equal(colnames(pool), expected_cols)

  # DSTs never carry per-player game logs in this cheap pre-draft version, so
  # they must present as fallback-board rows (has_current_data == FALSE),
  # never as VOR-ranked rows.
  expect_true(all(!pool$has_current_data))
  expect_true(all(is.na(pool$projected_points)))
})

test_that("required columns are never missing", {
  pool <- build_dst_pool(real_rankings_path)

  expect_false(anyNA(pool$player))
  expect_false(anyNA(pool$pos))
  expect_true(all(pool$pos == "DST"))
  expect_false(anyNA(pool$team))
  expect_false(anyNA(pool$ecr))
  expect_true(all(pool$ecr > 0))
})
