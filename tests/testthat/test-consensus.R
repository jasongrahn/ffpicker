# A deliberately hand-computable curve: five ranked RBs whose VOR falls
# linearly-ish with ECR, all with identical expert spread. isoreg() leaves an
# already-monotone series untouched, so every expectation below is an exact
# number, not a tolerance -- this is the golden test CLAUDE.md's standing rules
# ask for on the ECR -> VOR curve.
ranked_rb <- function() {
  data.frame(
    player_key = 1:5,
    player = paste("Ranked", 1:5),
    pos = "RB",
    team = "XX",
    ecr = 1:5,
    sd = 2,
    has_current_data = TRUE,
    replacement_value = 10,
    vor = c(100, 80, 50, 20, 0),
    stringsAsFactors = FALSE
  )
}

# value_table shape: every ranked column except the two compute_vor() adds.
unranked_rb <- function(ecr, sd, keys = seq_along(ecr) + 100) {
  data.frame(
    player_key = keys,
    player = paste("Rookie", seq_along(ecr)),
    pos = "RB",
    team = "YY",
    ecr = ecr,
    sd = sd,
    has_current_data = FALSE,
    stringsAsFactors = FALSE
  )
}

value_table_for <- function(ranked, unranked) {
  rbind(ranked[, setdiff(names(ranked), c("replacement_value", "vor"))], unranked)
}


# --- monotone_map ----------------------------------------------------------

test_that("monotone_map reproduces an already-monotone decreasing series exactly", {
  expect_equal(monotone_map(1:5, c(100, 80, 50, 20, 0), 1:5), c(100, 80, 50, 20, 0))
})

test_that("monotone_map forces monotonicity on a series that violates it", {
  # y rises at x = 3; the isotonic fit must not let value increase with rank.
  out <- monotone_map(1:4, c(100, 40, 60, 0), 1:4)
  expect_true(all(diff(out) <= 0))
  # The two out-of-order points are pooled to their mean, as isotonic
  # regression does -- not clipped to one or the other.
  expect_equal(out, c(100, 50, 50, 0))
})

test_that("monotone_map interpolates between fitted points", {
  expect_equal(monotone_map(1:5, c(100, 80, 50, 20, 0), 3.5), 35)
})

test_that("monotone_map holds the nearest endpoint outside the fitted range", {
  # rule = 2: a rookie ranked ahead of every projected player at his position
  # gets that player's value, never an extrapolated one above it.
  expect_equal(monotone_map(1:5, c(100, 80, 50, 20, 0), c(0.5, 99)), c(100, 0))
})

test_that("monotone_map tolerates duplicate x values", {
  # approx() cannot interpolate across a repeated abscissa; the duplicates must
  # be collapsed before it sees them.
  expect_silent(out <- monotone_map(c(1, 2, 2, 3), c(100, 60, 40, 0), 2))
  expect_equal(out, 50)
})

test_that("monotone_map degrades rather than erroring on too little data", {
  expect_equal(monotone_map(numeric(0), numeric(0), c(1, 2)), c(NA_real_, NA_real_))
  expect_equal(monotone_map(5, 42, c(1, 900)), c(42, 42))
})

test_that("monotone_map fits increasing when asked, for the ECR -> sd curve", {
  out <- monotone_map(1:4, c(2, 8, 4, 20), 1:4, decreasing = FALSE)
  expect_true(all(diff(out) >= 0))
})


# --- add_consensus_rows ----------------------------------------------------

test_that("a rookie with exactly normal expert spread lands on the curve untouched", {
  ranked <- ranked_rb()
  unranked <- unranked_rb(ecr = 3, sd = 2) # sd == the fitted normal, so no penalty
  out <- add_consensus_rows(ranked, value_table_for(ranked, unranked))

  est <- out[out$value_source == "consensus", ]
  expect_equal(nrow(est), 1)
  expect_equal(est$vor, 50)
})

test_that("expert disagreement is charged in rank space, so more spread is always less value", {
  ranked <- ranked_rb()
  # Same ECR, rising sd. Normal sd at every rank here is 2, so the penalties
  # are 0 / 0.5 / 1 ranks -- effective ranks 3, 3.5, 4 -- read off a curve
  # worth 50 at rank 3 and 20 at rank 4.
  unranked <- unranked_rb(ecr = c(3, 3, 3), sd = c(2, 2.5, 3))
  out <- add_consensus_rows(ranked, value_table_for(ranked, unranked))

  est <- out[out$value_source == "consensus", ]
  expect_equal(est$vor, c(50, 35, 20))
  expect_true(all(diff(est$vor) < 0))
})

test_that("uncertainty never promotes a player, even one whose fitted value is negative", {
  # The failure mode that ruled out shrinking VOR toward an anchor: most of the
  # real board sits below replacement, so shrinking a negative VOR upward would
  # turn expert disagreement into a reward.
  ranked <- ranked_rb()
  ranked$vor <- c(60, 20, -10, -40, -80)
  unranked <- unranked_rb(ecr = c(3, 3), sd = c(2, 6))
  out <- add_consensus_rows(ranked, value_table_for(ranked, unranked))

  est <- out[out$value_source == "consensus", ]
  expect_lt(est$vor[2], est$vor[1])
})

test_that("no consensus row is valued above the best projected player at its position", {
  ranked <- ranked_rb()
  unranked <- unranked_rb(ecr = c(-50, 0.1, 1), sd = 2) # ranked ahead of everyone
  out <- add_consensus_rows(ranked, value_table_for(ranked, unranked))

  est <- out[out$value_source == "consensus", ]
  expect_true(all(est$vor <= max(ranked$vor)))
})

test_that("consensus rows carry the replacement level their curve was fit under", {
  ranked <- ranked_rb()
  unranked <- unranked_rb(ecr = 3, sd = 2)
  out <- add_consensus_rows(ranked, value_table_for(ranked, unranked))

  expect_equal(out$replacement_value[out$value_source == "consensus"], 10)
})

test_that("ranked rows are labelled and left otherwise untouched", {
  ranked <- ranked_rb()
  out <- add_consensus_rows(ranked, value_table_for(ranked, unranked_rb(3, 2)))

  keep <- out[out$value_source == "projected", ]
  expect_equal(nrow(keep), nrow(ranked))
  expect_equal(keep$vor, ranked$vor)
  expect_equal(keep$player_key, ranked$player_key)
})

test_that("a position with no ranked players is left in the fallback, not guessed at", {
  # DST is the standing case: team-level, so it never reaches value_table at
  # all and there is no curve to fit it against.
  ranked <- ranked_rb()
  unranked <- unranked_rb(ecr = 3, sd = 2)
  unranked$pos <- "TE"
  out <- add_consensus_rows(ranked, value_table_for(ranked, unranked))

  expect_equal(nrow(out), nrow(ranked))
  expect_false(any(out$value_source == "consensus"))
})

test_that("a player with no expert spread at all is skipped rather than priced", {
  ranked <- ranked_rb()
  unranked <- unranked_rb(ecr = c(3, 3), sd = c(2, NA))
  out <- add_consensus_rows(ranked, value_table_for(ranked, unranked))

  expect_equal(sum(out$value_source == "consensus"), 1)
})

test_that("add_consensus_rows degrades to a labelled passthrough on a pool with no sd column", {
  ranked <- ranked_rb()
  vt <- value_table_for(ranked, unranked_rb(3, 2))
  vt$sd <- NULL
  out <- add_consensus_rows(ranked, vt)

  expect_equal(nrow(out), nrow(ranked))
  expect_true(all(out$value_source == "projected"))
})


# --- disjointness with the fallback board ----------------------------------

test_that("build_fallback_board subtracts whoever the Board already absorbed", {
  vt <- data.frame(
    player_key = 1:3,
    ecr = c(10, 20, 30),
    has_current_data = c(TRUE, FALSE, FALSE)
  )
  expect_equal(build_fallback_board(vt)$player_key, c(2L, 3L))
  expect_equal(build_fallback_board(vt, exclude_keys = 2L)$player_key, 3L)
  expect_equal(nrow(build_fallback_board(vt, exclude_keys = c(2L, 3L))), 0)
})

test_that("Board and fallback stay disjoint end to end, so no player is selectable twice", {
  ranked <- ranked_rb()
  unranked <- unranked_rb(ecr = c(3, 4), sd = 2)
  vt <- value_table_for(ranked, unranked)

  board <- add_consensus_rows(ranked, vt)
  fallback <- build_fallback_board(vt, exclude_keys = board$player_key)

  expect_equal(nrow(fallback), 0)
  expect_equal(length(intersect(board$player_key, fallback$player_key)), 0)
})
