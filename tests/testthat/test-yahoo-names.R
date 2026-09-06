# --- parsing ---------------------------------------------------------------

test_that("a well-formed paste yields one row per player with rank and adp", {
  path <- write_yahoo_file(c(
    yahoo_block("Ja'Marr Chase", "WR", "Cin", 10, 1, "1.3"),
    yahoo_block("Tyler Loop", "K", "Bal", 7, 202)
  ))
  out <- parse_yahoo_names(path)

  expect_equal(nrow(out), 2)
  expect_equal(out$name, c("Ja'Marr Chase", "Tyler Loop"))
  expect_equal(out$pos, c("WR", "K"))
  expect_equal(out$team, c("Cin", "Bal"))
  expect_equal(out$xrank, c(1L, 202L))
  expect_equal(out$adp, c(1.3, NA_real_))
})

test_that("blank lines between blocks do not shift the parse", {
  path <- write_yahoo_file(c(
    yahoo_block("Bijan Robinson", "RB", "Atl", 5, 1, "1.5"), "", "  ",
    yahoo_block("Texans", "DEF", "Hou", 6, 140)
  ))
  expect_equal(parse_yahoo_names(path)$name, c("Bijan Robinson", "Texans"))
})

test_that("a truncated paste fails loudly instead of parsing off by one", {
  # A half-copied last block would otherwise put one player's name on another
  # player's position and rank -- silently wrong is the one outcome to avoid.
  path <- write_yahoo_file(c(yahoo_block("Bijan Robinson", "RB", "Atl", 5, 1), "QB·KC"))
  expect_error(parse_yahoo_names(path), "multiple of 4")
})

test_that("a block that is not the expected shape fails loudly", {
  path <- write_yahoo_file(rep("Bijan Robinson", 4))
  expect_error(parse_yahoo_names(path), "not recognised")
})


test_that("a re-pasted player is deduplicated", {
  # The deep players arrive as further pastes taken one position at a time, and
  # those overlap the overall list. A repeat left in place would read as an
  # ambiguous key and un-match a player who matches today.
  path <- write_yahoo_file(rep(yahoo_block("Bijan Robinson", "RB", "Atl", 5, 1, "1.5"), 2))
  expect_equal(nrow(parse_yahoo_names(path)), 1)
})

test_that("two players sharing a normalised key both survive deduplication", {
  # Deduplication must not defeat the ambiguity guard: collapsing the two
  # Isaiah Williamses would make an undecidable name look decidable.
  path <- write_yahoo_file(c(
    yahoo_block("Isaiah Williams", "WR", "Det", 5, 300),
    yahoo_block("Isaiah Williams", "WR", "NYJ", 9, 400)
  ))
  expect_equal(nrow(parse_yahoo_names(path)), 2)
})


# --- parsing the position-page CSV -----------------------------------------

write_yahoo_csv <- function(lines, file = tempfile(fileext = ".csv")) {
  writeLines(c("Player,Position,Team", lines), file)
  file
}

test_that("a position-page CSV parses to the same columns as a paste", {
  out <- parse_yahoo_csv(write_yahoo_csv(c("Troy Franklin,WR,Den", "Kareem Hunt,RB,KC")))
  expect_equal(names(out), c("name", "pos", "team", "xrank", "adp"))
  expect_equal(out$name, c("Troy Franklin", "Kareem Hunt"))
  expect_equal(out$pos, c("WR", "RB"))
  expect_equal(out$team, c("Den", "KC"))
  # Yahoo does not put a rank on these pages. NA, not a fabricated number.
  expect_true(all(is.na(out$xrank)), all(is.na(out$adp)))
})

test_that("a multi-eligible player becomes one row per position", {
  # Our pool assigns exactly one position, and we cannot know which one it
  # chose, so both spellings of the key must exist to be matchable.
  out <- parse_yahoo_csv(write_yahoo_csv('Riley Nowakowski,"RB, TE",Pit'))
  expect_equal(out$pos, c("RB", "TE"))
  expect_equal(out$name, rep("Riley Nowakowski", 2))
})

test_that("a CSV without the expected columns fails loudly", {
  f <- tempfile(fileext = ".csv")
  writeLines(c("name,pos", "Troy Franklin,WR"), f)
  expect_error(parse_yahoo_csv(f), "expected columns")
})


# --- combining the sources -------------------------------------------------

test_that("both shapes load together and overlaps collapse", {
  paste_path <- write_yahoo_file(yahoo_block("Troy Franklin", "WR", "Den", 12, 59))
  csv_path <- write_yahoo_csv(c("Troy Franklin,WR,Den", "Kareem Hunt,RB,KC"))
  out <- load_yahoo_names(c(paste_path, csv_path))

  expect_equal(nrow(out), 2)
  expect_setequal(out$name, c("Troy Franklin", "Kareem Hunt"))
})

test_that("sources that do not exist are skipped, not fatal", {
  csv_path <- write_yahoo_csv("Kareem Hunt,RB,KC")
  out <- load_yahoo_names(c(file.path(tempdir(), "gone.txt"), csv_path))
  expect_equal(out$name, "Kareem Hunt")
  expect_null(load_yahoo_names(file.path(tempdir(), "gone.txt")))
})


# --- normalising -----------------------------------------------------------

test_that("a generational suffix does not change the key", {
  expect_equal(
    normalize_player_name(c("Patrick Mahomes II", "Brian Robinson Jr.",
                            "Kenneth Walker III", "Kyle Pitts Sr."), "QB"),
    c("patrick mahomes", "brian robinson", "kenneth walker", "kyle pitts")
  )
})

test_that("punctuation and case do not change the key", {
  expect_equal(normalize_player_name("Ja'Marr Chase", "WR"),
               normalize_player_name("JAMARR CHASE", "WR"))
  expect_equal(normalize_player_name("Amon-Ra St. Brown", "WR"), "amonra st brown")
})

test_that("a defense keys on its nickname, which is all Yahoo gives us", {
  expect_equal(normalize_player_name("Houston Texans", "DST"), "texans")
  expect_equal(normalize_player_name("Texans", "DEF"), "texans")
  expect_equal(normalize_player_name("San Francisco 49ers", "DST"), "49ers")
})

test_that("a player named for a suffix-looking word keeps it", {
  # "Vance" ends in no suffix token; the rule must anchor on whole words only.
  expect_equal(normalize_player_name("Ray Davis", "RB"), "ray davis")
  expect_equal(normalize_player_name("Roman Wilson", "WR"), "roman wilson")
})


# --- aligning --------------------------------------------------------------

mk_ours <- function(name, position) {
  data.frame(name = name, position = position, stringsAsFactors = FALSE)
}

test_that("a suffix we carry and Yahoo drops is rewritten to Yahoo's spelling", {
  out <- align_yahoo_names(mk_ours("Patrick Mahomes II", "QB"), mk_yahoo())
  expect_equal(out$name, "Patrick Mahomes")
  expect_true(out$yahoo_matched)
})

test_that("a suffix both sides carry is left alone", {
  out <- align_yahoo_names(mk_ours("Travis Etienne Jr.", "RB"), mk_yahoo())
  expect_equal(out$name, "Travis Etienne Jr.")
  expect_true(out$yahoo_matched)
})

test_that("a defense is rewritten from city-and-nickname to nickname", {
  out <- align_yahoo_names(mk_ours("Houston Texans", "DEF"), mk_yahoo())
  expect_equal(out$name, "Texans")
})

test_that("a name Yahoo lists twice is refused rather than guessed at", {
  # Two real receivers share the name. Picking either at random would put one
  # player's rank on the other, so neither is touched.
  out <- align_yahoo_names(mk_ours("Isaiah Williams", "WR"), mk_yahoo())
  expect_equal(out$name, "Isaiah Williams")
  expect_false(out$yahoo_matched)
})

test_that("a player absent from the paste keeps our spelling and is reported", {
  out <- align_yahoo_names(mk_ours("Nobody Here", "TE"), mk_yahoo())
  expect_equal(out$name, "Nobody Here")
  expect_false(out$yahoo_matched)
})

test_that("the same name at a different position does not match", {
  out <- align_yahoo_names(mk_ours("Patrick Mahomes II", "WR"), mk_yahoo())
  expect_false(out$yahoo_matched)
})

test_that("row order and row count survive alignment", {
  ours <- mk_ours(c("Bijan Robinson", "Nobody Here", "Houston Texans"),
                  c("RB", "TE", "DEF"))
  out <- align_yahoo_names(ours, mk_yahoo())
  expect_equal(nrow(out), 3)
  expect_equal(out$name, c("Bijan Robinson", "Nobody Here", "Texans"))
})


# --- wired into the export -------------------------------------------------

cfg <- list(teams = 10, draft = list(defer_until_round = list(K = 16, DST = 15)))

test_that("the exported file carries Yahoo's spellings when the list is present", {
  board <- data.frame(player = "Patrick Mahomes II", pos = "QB", team = "KC",
                      ecr = 30, vor = 50, stringsAsFactors = FALSE)
  fb <- data.frame(player = "Houston Texans", pos = "DST", team = "HOU",
                   ecr = 150, stringsAsFactors = FALSE)
  names_path <- write_yahoo_file(c(
    yahoo_block("Patrick Mahomes", "QB", "KC", 10, 30),
    yahoo_block("Texans", "DEF", "Hou", 6, 140)
  ))
  path <- file.path(tempdir(), "rk_aligned.csv")
  export_yahoo_rankings(board, fb, cfg, path, yahoo_names_path = names_path)

  back <- utils::read.csv(path, stringsAsFactors = FALSE)
  expect_equal(sort(back$name), c("Patrick Mahomes", "Texans"))
  expect_equal(names(back), c("rank", "name", "team", "position"))
})

test_that("every defense is shortened to its nickname, paste or no paste", {
  # The paste covers 25 of 32. The other 7 follow the same convention and must
  # not be uploaded as "Tennessee Titans", which Yahoo would never match.
  expect_equal(yahoo_defense_name(c("Tennessee Titans", "New York Jets",
                                    "San Francisco 49ers", "Rams")),
               c("Titans", "Jets", "49ers", "Rams"))

  board <- data.frame(player = "Top RB", pos = "RB", team = "ATL",
                      ecr = 1, vor = 90, stringsAsFactors = FALSE)
  fb <- data.frame(player = "Tennessee Titans", pos = "DST", team = "TEN",
                   ecr = 150, stringsAsFactors = FALSE)
  path <- file.path(tempdir(), "rk_def.csv")
  export_yahoo_rankings(board, fb, cfg, path,
                        yahoo_names_path = file.path(tempdir(), "nope.txt"))

  back <- utils::read.csv(path, stringsAsFactors = FALSE)
  expect_equal(back$name[back$position == "DEF"], "Titans")
})

test_that("a missing names list degrades to our own spellings", {
  board <- data.frame(player = "Patrick Mahomes II", pos = "QB", team = "KC",
                      ecr = 30, vor = 50, stringsAsFactors = FALSE)
  fb <- data.frame(player = "Houston Texans", pos = "DST", team = "HOU",
                   ecr = 150, stringsAsFactors = FALSE)
  path <- file.path(tempdir(), "rk_noalign.csv")
  export_yahoo_rankings(board, fb, cfg, path,
                        yahoo_names_path = file.path(tempdir(), "nope.txt"))

  expect_equal(utils::read.csv(path, stringsAsFactors = FALSE)$name[1],
               "Patrick Mahomes II")
})
