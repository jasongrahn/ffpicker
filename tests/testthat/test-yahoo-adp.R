# Yahoo XRank/ADP is an OPPONENT model. These tests pin two things: the join
# reports honestly (it is a name join, so a silent drop is the failure mode
# that matters), and the divergence column stays read-only arithmetic.

test_that("load_yahoo_adp remaps DEF to DST and drops duplicate keys", {
  f <- tempfile(fileext = ".csv")
  write.csv(data.frame(
    Player = c("Ja'Marr Chase", "Patrick Mahomes II", "Baltimore Ravens", "Patrick Mahomes"),
    Position = c("WR", "QB", "DEF", "QB"),
    Team = c("Cin", "KC", "Bal", "KC"),
    `Bye Week` = c(10, 10, 7, 10),
    XRank = c(1, 40, 90, 41),
    ADP = c(1.2, 38.9, NA, 40.0),
    check.names = FALSE
  ), f, row.names = FALSE)

  y <- load_yahoo_adp(f)
  expect_false(any(y$pos == "DEF"))
  expect_true("DST" %in% y$pos)
  # "Patrick Mahomes II" and "Patrick Mahomes" normalise to one key; first wins.
  expect_equal(sum(y$k == "patrick mahomes"), 1L)
  expect_equal(y$xrank[y$k == "patrick mahomes"], 40)
  expect_equal(y$k[y$pos == "DST"], "ravens")
})

test_that("add_yahoo_ranks joins by name+pos and leaves misses NA", {
  yahoo <- data.frame(
    name = c("Ja'Marr Chase", "Bijan Robinson"),
    pos = c("WR", "RB"),
    xrank = c(1, 4), adp = c(1.2, 4.4),
    k = c("jamarr chase", "bijan robinson"),
    stringsAsFactors = FALSE
  )
  board <- data.frame(
    player = c("Ja'Marr Chase", "Bijan Robinson", "Nobody Atall"),
    pos = c("WR", "RB", "TE"),
    ecr = c(1, 2, 300), stringsAsFactors = FALSE
  )
  out <- suppressMessages(add_yahoo_ranks(board, yahoo))
  expect_equal(out$xrank, c(1, 4, NA))
  expect_equal(out$adp, c(1.2, 4.4, NA))
  expect_message(add_yahoo_ranks(board, yahoo), "2/3 rows matched")
})

test_that("yahoo_divergence is xrank minus our own board rank", {
  board <- data.frame(vor = c(100, 90, 80), xrank = c(1, 30, NA))
  expect_equal(yahoo_divergence(board), c(0L, 28L, NA_integer_))
})

test_that("yahoo_gap_display flags only gaps at or beyond the early threshold", {
  out <- yahoo_gap_display(c(NA, -26L, -20L, -19L, 5L))
  expect_equal(out[c(1, 4, 5)], c("", "-19", "5"))
  expect_true(all(grepl("takes him early", out[2:3])))
})
