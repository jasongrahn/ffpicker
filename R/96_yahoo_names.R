#' Align our player names to Yahoo's spelling, from a pasted draft-room list.
#'
#' The rankings CSV Yahoo imports matches on name and nothing else
#' (R/95_export.R), so every name we spell differently is a player silently
#' missing from the uploaded ranking. Yahoo's spellings cannot be derived --
#' they are inconsistent even within Yahoo (it writes "Travis Etienne Jr." but
#' "Patrick Mahomes", "Michael Penix Jr." but "Brian Robinson") -- so they have
#' to come from Yahoo. `docs/yahoo-player-names.txt` is that: a paste of the
#' draft room's own player list.
#'
#' This is name matching, which CLAUDE.md forbids for joins. Same reasoning as
#' the export itself: nothing downstream consumes the result, an unmatched name
#' just keeps our spelling, and the guard below refuses any key that is
#' ambiguous on either side rather than guessing between two players.
#'
#' Matching runs on a normalised key -- lowercased, punctuation dropped,
#' trailing generational suffix removed -- plus position. That is what lets
#' "Patrick Mahomes II" find Yahoo's "Patrick Mahomes" without also letting it
#' find some other Mahomes. Team is deliberately NOT part of the key: our
#' abbreviations and Yahoo's disagree in dialect (we carry both JAC and JAX for
#' Jacksonville, and LA and LAR for the Rams; Yahoo writes Jax and LAR), so
#' including it would break matches rather than sharpen them.
#'
#' @param path Pasted Yahoo player list.
#' @return data.frame: name, pos, team, xrank, adp. `adp` is NA for players
#'   Yahoo shows a rank but no average draft position for.
parse_yahoo_names <- function(path) {
  lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
  lines <- trimws(lines)
  lines <- lines[nzchar(lines)]

  # The paste is a fixed four-line block per player: name, name again (the
  # list renders it twice), "POS<dot>Team<dot>Bye N", then "XRank #N" with an
  # optional "<dot>ADP x.y". Anything else means the paste is malformed and
  # must fail loudly -- a silently mis-parsed block would put one player's name
  # on another player's row.
  if (length(lines) %% 4 != 0) {
    stop("parse_yahoo_names: expected a multiple of 4 lines, got ", length(lines))
  }
  i <- seq(1, length(lines), by = 4)
  meta <- lines[i + 2]
  rank <- lines[i + 3]
  if (!all(grepl("Bye", meta)) || !all(grepl("XRank", rank))) {
    stop("parse_yahoo_names: block structure not recognised at line(s) ",
         paste(head(i[!grepl("Bye", meta) | !grepl("XRank", rank)], 5), collapse = ", "))
  }

  parts <- strsplit(meta, "·", fixed = TRUE)
  data.frame(
    name = lines[i],
    pos = vapply(parts, `[`, character(1), 1),
    team = vapply(parts, `[`, character(1), 2),
    xrank = as.integer(sub(".*XRank #([0-9]+).*", "\\1", rank)),
    adp = suppressWarnings(as.numeric(sub(".*ADP ([0-9.]+).*", "\\1", rank))),
    stringsAsFactors = FALSE
  )
}

#' Normalised match key: what two spellings of the same player share.
#'
#' Defenses are the one shape that needs its own rule. We name a unit by city
#' and nickname ("Los Angeles Rams"); Yahoo names it by nickname alone
#' ("Rams"). The last word is the nickname on both sides for all 32 teams, so
#' that is the key -- without this every defense in the file misses.
#'
#' @param name Character vector of player names.
#' @param pos Character vector of positions, our codes or Yahoo's.
#' @return Character vector of keys.
normalize_player_name <- function(name, pos) {
  key <- tolower(trimws(name))
  defense <- pos %in% c("DST", "DEF")
  key[defense] <- sub(".*\\s", "", key[defense])

  key[!defense] <- gsub("[^a-z0-9 ]", "", key[!defense])
  key[!defense] <- sub("\\s+(jr|sr|ii|iii|iv|v)$", "", key[!defense])
  gsub("\\s+", " ", trimws(key))
}

#' Yahoo's name for a team defense: the nickname alone.
#'
#' Applied to all 32 rather than only the ones the paste happens to cover.
#' Every defense in `docs/yahoo-player-names.txt` follows this form without
#' exception -- 25 of 32 teams, no counterexample -- and all 32 NFL nicknames
#' are distinct words, so shortening the other 7 cannot collide. The 7 the
#' paste misses (Titans, Commanders, Raiders, Panthers, Cardinals, Jets,
#' Dolphins) would otherwise be uploaded as "Tennessee Titans" and silently
#' fail to match.
#'
#' @param name Character vector of defense names, e.g. "Los Angeles Rams".
#' @return Nickname only, e.g. "Rams". Input case preserved.
yahoo_defense_name <- function(name) sub(".*\\s", "", trimws(name))

#' Rewrite names to Yahoo's spelling wherever a confident match exists.
#'
#' @param df data.frame with `name` and `position` columns (Yahoo position
#'   codes, i.e. post-`yahoo_position()`).
#' @param yahoo data.frame from parse_yahoo_names().
#' @return `df` with `name` rewritten where matched, plus a logical
#'   `yahoo_matched` column so the caller can report the misses.
align_yahoo_names <- function(df, yahoo) {
  ours <- paste(normalize_player_name(df$name, df$position), df$position)
  theirs <- paste(normalize_player_name(yahoo$name, yahoo$pos), yahoo$pos)

  # A key appearing twice on either side cannot identify a player, so it is
  # refused rather than resolved by whichever row happened to come first.
  # Isaiah Williams (two receivers, same name) is the live case.
  ambiguous <- ours %in% ours[duplicated(ours)] | ours %in% theirs[duplicated(theirs)]

  hit <- match(ours, theirs)
  usable <- !is.na(hit) & !ambiguous

  df$yahoo_matched <- usable
  df$name[usable] <- yahoo$name[hit[usable]]
  df
}
