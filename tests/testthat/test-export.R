mk_cfg <- function(defer = list(K = 16, DST = 15), teams = 10) {
  list(teams = teams, draft = list(defer_until_round = defer))
}

# Four undeferred players and one kicker whose VOR would otherwise put him
# second overall -- the exact shape the export exists to correct.
mk_board <- function() {
  data.frame(
    player = c("Top RB", "Rich Kicker", "Mid WR", "Low TE"),
    pos = c("RB", "K", "WR", "TE"),
    team = c("ATL", "SEA", "DAL", "ARI"),
    ecr = c(4, 200, 20, 60),
    vor = c(140, 120, 80, 10),
    stringsAsFactors = FALSE
  )
}

mk_fb <- function() {
  data.frame(
    player = c("Bears D", "Jets D"),
    pos = "DST",
    team = c("CHI", "NYJ"),
    ecr = c(150, 160),
    stringsAsFactors = FALSE
  )
}


# --- ordering --------------------------------------------------------------

test_that("undeferred players are ranked by value, best first", {
  out <- yahoo_ranking_order(mk_board(), mk_fb(), mk_cfg())
  undeferred <- out[!out$pos %in% c("K", "DST"), ]
  expect_equal(undeferred$player, c("Top RB", "Mid WR", "Low TE"))
  expect_equal(undeferred$rank, 1:3)
})

test_that("a deferred position is ranked at the pick its round begins at, not by its VOR", {
  # Rich Kicker outranks everyone but Top RB on value. Round 16 of a 10-team
  # draft starts at pick 151, so that is where he belongs -- uploading him at
  # rank 2 would hand the draft room the mistake defer_until_round prevents.
  # With only six players nothing fills the gap out to pick 151, so he simply
  # lands last -- behind the defenses, whose round comes first.
  out <- yahoo_ranking_order(mk_board(), mk_fb(), mk_cfg())
  expect_equal(out$rank[out$player == "Rich Kicker"], 6)
  expect_gt(which(out$player == "Rich Kicker"), which(out$player == "Low TE"))
})

test_that("deferred blocks keep their rounds' relative order", {
  # DST is deferred to 15 and K to 16, so every defense precedes every kicker
  # regardless of the fact that the kicker carries a VOR and they do not.
  out <- yahoo_ranking_order(mk_board(), mk_fb(), mk_cfg())
  expect_lt(max(which(out$pos == "DST")), which(out$pos == "K"))
})

test_that("players within a deferred position stay in their own order", {
  out <- yahoo_ranking_order(mk_board(), mk_fb(), mk_cfg())
  expect_equal(out$player[out$pos == "DST"], c("Bears D", "Jets D"))
})

test_that("an undeferred player outranks a deferred one they tie with", {
  # The deferred round is the earliest you would take one, not a promise to.
  board <- mk_board()
  board <- rbind(board, data.frame(player = paste("Filler", 1:200), pos = "WR",
                                   team = "XX", ecr = 300, vor = -1:-200,
                                   stringsAsFactors = FALSE))
  out <- yahoo_ranking_order(board, mk_fb(), mk_cfg())
  # Rank 151 is contested: it is the kicker's target and also a filler's
  # natural place. The filler takes it.
  expect_equal(out$pos[out$rank == 151], "WR")
})

test_that("ranks are contiguous from 1 with no player lost or duplicated", {
  out <- yahoo_ranking_order(mk_board(), mk_fb(), mk_cfg())
  expect_equal(out$rank, seq_len(nrow(out)))
  expect_equal(nrow(out), nrow(mk_board()) + nrow(mk_fb()))
  expect_equal(sum(duplicated(out$player)), 0)
})

test_that("a config deferring nothing gives a pure value ordering", {
  out <- yahoo_ranking_order(mk_board(), mk_fb(), mk_cfg(defer = list()))
  expect_equal(out$player[1:2], c("Top RB", "Rich Kicker"))
})


# --- file shape ------------------------------------------------------------

test_that("the written file matches the columns Yahoo's import documents", {
  path <- file.path(tempdir(), "rk.csv")
  export_yahoo_rankings(mk_board(), mk_fb(), mk_cfg(), path)

  back <- utils::read.csv(path, stringsAsFactors = FALSE)
  expect_equal(names(back), c("rank", "name", "team", "position"))
  expect_equal(back$rank, seq_len(nrow(back)))
  expect_equal(back$name[1], "Top RB")
})

test_that("DST is written as Yahoo's DEF, every other position unchanged", {
  expect_equal(yahoo_position(c("RB", "DST", "K")), c("RB", "DEF", "K"))
})

test_that("a free agent gets a blank team rather than our FA marker", {
  board <- mk_board()
  board$team[1] <- "FA"
  path <- file.path(tempdir(), "rk_fa.csv")
  export_yahoo_rankings(board, mk_fb(), mk_cfg(), path)

  back <- utils::read.csv(path, stringsAsFactors = FALSE, colClasses = "character")
  expect_equal(back$team[back$name == "Top RB"], "")
})

test_that("an apostrophe survives the unquoted format Yahoo's own template uses", {
  board <- mk_board()
  board$player[1] <- "Ja'Marr Chase"
  path <- file.path(tempdir(), "rk_apos.csv")
  export_yahoo_rankings(board, mk_fb(), mk_cfg(), path)

  expect_true(any(grepl("Ja'Marr Chase", readLines(path), fixed = TRUE)))
  expect_equal(utils::read.csv(path, stringsAsFactors = FALSE)$name[1], "Ja'Marr Chase")
})

test_that("a comma in a name fails loudly instead of shifting every later column", {
  board <- mk_board()
  board$player[1] <- "Griffin, Jr."
  expect_error(
    export_yahoo_rankings(board, mk_fb(), mk_cfg(), file.path(tempdir(), "rk_bad.csv")),
    "comma or quote"
  )
})
