# Reader for Yahoo's per-position CSV exports (week 3 format onward).
#
# Week 3 changed shape from week 2's .txt pastes: real CSVs, one per position,
# and critically they carry a `Player ID` column -- Yahoo's own player id. That
# kills the name join. `load_ff_playerids()` publishes `yahoo_id`, so the two
# sides meet on a surrogate key instead of "Kenny" vs "Kenneth".
#
# THREE TRAPS, all silent. Do not simplify this reader without re-reading them.
#
# 1. Headers carry INVISIBLE private-use-area characters. "Fantasy Fan Pts" is
#    really "Fantasy Fan Pts" -- codepoint 57346, a sort-arrow glyph from
#    Yahoo's icon font. `d[["Fantasy Fan Pts"]]` returns NULL, not an error, so
#    a column reads as missing while printing identically to a present one.
#    Strip non-ASCII from names before anything else.
# 2. Numeric columns use "-" for absent and "%" suffixes for rates.
#    as.numeric() on those gives NA with a warning, so clean before coercing.
# 3. The stat columns are PROJECTIONS for the upcoming week, not actuals.
#    Mahomes reads 258 pass yds / 2.0 TD, not his 382 and 327 from weeks 1-2.
#    Decimal TD counts are the tell. Never join these onto a results table.
suppressMessages({library(dplyr)})

#' Strip invisible and non-ASCII characters from a character vector.
#' @param x character vector
#' @return `x` with codepoints > 127 removed and whitespace squeezed
ascii_only <- function(x) {
  x <- vapply(x, function(s) {
    cp <- utf8ToInt(s)
    intToUtf8(cp[cp <= 127])
  }, character(1), USE.NAMES = FALSE)
  trimws(gsub("\\s+", " ", x))
}

#' Coerce a Yahoo numeric column: "-" is absent, "%" is a rate.
#' @param x character vector
#' @return numeric
yahoo_num <- function(x) {
  if (is.numeric(x)) return(x)
  x <- trimws(as.character(x))
  x[x %in% c("-", "", "--", "N/A")] <- NA_character_
  suppressWarnings(as.numeric(sub("%$", "", x)))
}

#' Read one Yahoo position export.
#'
#' @param path Path to a `yahoo_weekN_<pos>.csv`.
#' @return tibble with normalized names, `yahoo_id`, and numeric stat columns.
read_yahoo_position <- function(path) {
  d <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  names(d) <- ascii_only(names(d))

  # `Player ID` is absent from the DEF export -- Yahoo has no player id for a
  # team defense. Those join by team nickname downstream, not by id.
  d$yahoo_id <- if ("Player ID" %in% names(d)) as.character(d[["Player ID"]]) else NA_character_

  out <- tibble::tibble(
    player      = d[["Player"]],
    yahoo_id    = d$yahoo_id,
    yteam       = d[["Team"]],
    pos         = d[["Positions"]],
    injury      = if ("Injury" %in% names(d)) d[["Injury"]] else NA_character_,
    game        = d[["Game"]],
    owner       = d[["Roster Status"]],
    proj        = yahoo_num(d[["Fantasy Fan Pts"]]),
    rank_pre    = yahoo_num(d[["Rankings Pre-Season"]]),
    rank_actual = yahoo_num(d[["Rankings Actual"]]),
    pct_ros     = yahoo_num(d[["Trends % Ros"]]),
    src         = basename(path)
  )
  stopifnot(!all(is.na(out$proj)))   # catches trap 1 regressing
  out
}

#' Read every position export for a week and stack them.
#'
#' @param dir Directory holding `yahoo_week*_*.csv`.
#' @return tibble, one row per player (deduped; `wrt` is a superset of wr/te).
read_yahoo_week <- function(dir) {
  files <- list.files(dir, pattern = "^yahoo_week\\d+_.*\\.csv$", full.names = TRUE)
  # `wrt` is Yahoo's combined flex page and duplicates wr + te. Drop it: the
  # per-position files carry the same rows with cleaner position labels.
  files <- files[!grepl("_wrt\\.csv$", files)]
  stopifnot(length(files) > 0)

  bind_rows(lapply(files, read_yahoo_position)) |>
    distinct(player, yteam, .keep_all = TRUE)
}

#' Attach nflverse ids to a Yahoo table: id first, name only as fallback.
#'
#' `yahoo_id` is the right key and is used wherever it resolves. It does NOT
#' resolve for recent players: `load_ff_playerids()` coverage collapses by
#' draft class -- 2022 85.6%, 2023 75.4%, 2024 32.3%, 2025 **0.3%**, 2026 0%.
#' The crosswalk is community-maintained and simply has not backfilled
#' `yahoo_id` for anyone drafted since 2024. Those players ARE present with a
#' `gsis_id`; only the Yahoo id is missing, so an id-only join silently loses
#' every rookie -- Jeanty, Ward, McMillan, Hampton, Henderson among them.
#'
#' So: join on id, then fall back to normalized name for the remainder. The
#' fallback is the CLAUDE.md-sanctioned case -- name is all that is left once
#' the id is absent -- and `method` records which key each row used so the
#' name-joined subset stays auditable.
#'
#' @param yh tibble from `read_yahoo_week()`.
#' @return `yh` plus `gsis_id`, `nfl_name`, and `method` ("yahoo_id"/"name"/NA).
attach_nfl_ids <- function(yh) {
  ids <- as.data.frame(nflreadr::load_ff_playerids())
  ids$yahoo_id <- as.character(ids$yahoo_id)

  by_id <- ids[!is.na(ids$yahoo_id), c("yahoo_id", "gsis_id", "name")]
  names(by_id) <- c("yahoo_id", "gsis_id_i", "nfl_name_i")

  # merge_name is the crosswalk's own normalized form (lowercase, suffixes and
  # punctuation stripped) -- reuse it rather than inventing a second scheme.
  by_nm <- ids[!is.na(ids$merge_name), c("merge_name", "gsis_id", "name")]
  by_nm <- by_nm[!duplicated(by_nm$merge_name), ]   # collisions -> drop, not guess
  names(by_nm) <- c("merge_name", "gsis_id_n", "nfl_name_n")

  yh$merge_name <- nflreadr::clean_player_names(yh$player, lowercase = TRUE)

  out <- yh |>
    left_join(by_id, by = "yahoo_id") |>
    left_join(by_nm, by = "merge_name") |>
    mutate(
      method   = case_when(!is.na(gsis_id_i) ~ "yahoo_id",
                           !is.na(gsis_id_n) ~ "name",
                           TRUE              ~ NA_character_),
      gsis_id  = coalesce(gsis_id_i, gsis_id_n),
      nfl_name = coalesce(nfl_name_i, nfl_name_n)
    ) |>
    select(-gsis_id_i, -gsis_id_n, -nfl_name_i, -nfl_name_n)

  out
}
