real_rankings_path <- file.path("..", "..", "data", "raw", "ff_rankings.parquet")

# Two positions on both pages, plus rows only a position page carries.
# WR is dense (one position rank costs ~2 overall ranks), TE is thin
# (~4), so the fixture can check that the slope is read per position.
fixture_rankings <- function() {
  overall <- data.frame(
    page_type = "redraft-overall",
    id = c(1, 2, 3, 4, 10, 11, 12, 13, 90),
    player = c("WR A", "WR B", "WR C", "WR D",
               "TE A", "TE B", "TE C", "TE D", "D/ST A"),
    pos = c(rep("WR", 4), rep("TE", 4), "DST"),
    team = "SF",
    ecr = c(2, 22, 42, 62, 10, 50, 90, 130, 200),
    sd = 1, best = 1, worst = 3, rank_delta = NA_real_, bye = 6
  )
  slices <- data.frame(
    page_type = c(rep("redraft-wr", 6), rep("redraft-te", 5), "redraft-dst"),
    id = c(1, 2, 3, 4, 5, 6, 10, 11, 12, 13, 14, 90),
    player = c("WR A", "WR B", "WR C", "WR D", "WR E", "WR F",
               "TE A", "TE B", "TE C", "TE D", "TE E", "D/ST A"),
    pos = c(rep("WR", 6), rep("TE", 5), "DST"),
    team = "SF",
    ecr = c(1, 11, 21, 31, 41, 36, 1, 11, 21, 31, 41, 1),
    sd = 2, rank_delta = NA_real_, bye = 6
  )
  slices$best <- pmax(1, slices$ecr - 3)
  slices$worst <- slices$ecr + 5
  rbind(overall, slices)
}

write_fixture <- function(df) {
  path <- tempfile(fileext = ".parquet")
  arrow::write_parquet(df, path)
  path
}

test_that("position-only players are added and tagged", {
  pool <- build_draft_pool(write_fixture(fixture_rankings()),
                           data.frame(player_key = 1:14, fantasypros_id = c(1:14)))

  expect_setequal(pool$player[pool$ecr_source == "position"],
                  c("WR E", "WR F", "TE E"))
  expect_equal(sum(pool$ecr_source == "overall"), 8)  # DST dropped
  expect_false("DST" %in% pool$pos)
})

test_that("added players sort behind every overall-ranked player", {
  pool <- build_draft_pool(write_fixture(fixture_rankings()),
                           data.frame(player_key = 1:14, fantasypros_id = c(1:14)))

  expect_gt(min(pool$ecr[pool$ecr_source == "position"]),
            max(pool$ecr[pool$ecr_source == "overall"]))
  expect_false(is.unsorted(pool$ecr))
})

test_that("added players keep their position page's ordering", {
  pool <- build_draft_pool(write_fixture(fixture_rankings()),
                           data.frame(player_key = 1:14, fantasypros_id = c(1:14)))
  wr <- pool[pool$ecr_source == "position" & pool$pos == "WR", ]

  # WR F is position rank 36, WR E is 41, so F comes first.
  expect_equal(wr$player[order(wr$ecr)], c("WR F", "WR E"))
  expect_false(anyDuplicated(wr$ecr) > 0)
})

test_that("a thin position is spread wider than a dense one", {
  pool <- build_draft_pool(write_fixture(fixture_rankings()),
                           data.frame(player_key = 1:14, fantasypros_id = c(1:14)))
  added <- pool[pool$ecr_source == "position", ]
  floor_ecr <- max(pool$ecr[pool$ecr_source == "overall"])

  wr_step <- min(added$ecr[added$pos == "WR"]) - floor_ecr
  te_step <- min(added$ecr[added$pos == "TE"]) - floor_ecr
  expect_gt(te_step, wr_step)
})

test_that("sd is converted to overall-rank units, never left at zero", {
  pool <- build_draft_pool(write_fixture(fixture_rankings()),
                           data.frame(player_key = 1:14, fantasypros_id = c(1:14)))
  added <- pool[pool$ecr_source == "position", ]

  expect_true(all(added$sd > 0))
  # WR slope is (62-2)/(31-1) = 2, so a position-scale sd of 2 becomes 4.
  expect_equal(unique(added$sd[added$pos == "WR"]), 4)
  expect_true(all(added$best < added$ecr & added$worst > added$ecr))
})

test_that("position_rank_slope falls back to 1 rather than dividing by zero", {
  expect_equal(position_rank_slope(c(5, 5, 5), c(1, 2, 3)), 1)
  expect_equal(position_rank_slope(numeric(0), numeric(0)), 1)
  expect_equal(position_rank_slope(c(1, NA), c(4, 9)), 1)
  expect_equal(position_rank_slope(c(1, 3), c(2, 8)), 3)
})

test_that("no position-only rows leaves the overall pool untouched", {
  df <- fixture_rankings()
  df <- df[!(df$id %in% c(5, 6, 14)), ]
  pool <- build_draft_pool(write_fixture(df),
                           data.frame(player_key = 1:14, fantasypros_id = c(1:14)))

  expect_true(all(pool$ecr_source == "overall"))
  expect_equal(nrow(pool), 8)
})

test_that("the real rankings file gains its position-only players", {
  skip_if_not(file.exists(real_rankings_path))
  dim_player <- targets::tar_read(dim_player, store = file.path("..", "..", "_targets"))

  pool <- build_draft_pool(real_rankings_path, dim_player)

  expect_gt(sum(pool$ecr_source == "position"), 200)
  expect_true(all(table(pool$player_key) == 1))
  expect_silent(validate_draft_pool(pool))
  expect_gt(min(pool$ecr[pool$ecr_source == "position"]),
            max(pool$ecr[pool$ecr_source == "overall"]))
})
