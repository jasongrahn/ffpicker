#' Export the Board as a Yahoo "import rankings" CSV.
#'
#' Yahoo's draft room can be told to order its own best-available list by an
#' uploaded ranking. That is worth more than it sounds: it puts this project's
#' numbers inside the room where the picks actually happen, so a 1-minute clock
#' no longer means reading two screens against each other. The same file
#' printed is the offline backup for the night the app will not start.
#'
#' Format, per the live import tool (2026-09-06): one player per line,
#' `rank,name,team,position`, header row allowed, **name is the match key** and
#' the other columns are optional.
#'
#' ## Matching on name, deliberately
#'
#' CLAUDE.md's rule is never to join players on name, and this does exactly
#' that -- because Yahoo offers no other key. `yahoo_id` is 100% NA in our
#' rankings source (also recorded in CLAUDE.md), so there is no id to send.
#'
#' What makes it acceptable here is that this is an export, not a join. Nothing
#' downstream consumes the result: a name Yahoo fails to match is a player
#' missing from a convenience ordering, not a corrupted row in the pipeline.
#' The blast radius is one wrong line in a list you will read with your own
#' eyes before the draft. Two name pairs collide outright (Antonio Williams,
#' Isaiah Williams -- all four deep-bench); `align_yahoo_names()` refuses those
#' rather than guessing.
#'
#' Where a spelling is known to differ it is corrected before writing, from
#' Yahoo's own draft-room list -- see R/96_yahoo_names.R. That is what makes
#' the 32 team defenses land at all: Yahoo calls them "Texans", we call them
#' "Houston Texans".
#'
#' ## Deferred positions are placed, not dropped
#'
#' A straight VOR ordering puts Jason Myers 21st overall, because a kicker's
#' Extra pts really is that high and is also pure noise (see `scarcity_report()`
#' in R/79_scarcity.R). Uploading that would hand the draft room the exact
#' mistake `defer_until_round` exists to prevent.
#'
#' So a deferred position is ranked at the pick its round begins at -- round 16
#' in a 10-team league starts at pick 151, so the best kicker is ranked 151st,
#' the next 152nd, and so on -- and the undeferred players flow around them.
#' The result is a list whose top is pure value and whose round-15/16 stretch
#' surfaces a defense and a kicker right where the plan wants them.
#'
#' @param draft_board data.frame from the draft_board target: player, pos,
#'   team, ecr, vor.
#' @param draft_fallback data.frame from the draft_fallback target. No vor
#'   column; ordered among itself by ecr.
#' @param league_config Parsed league config, for `teams` and
#'   `draft$defer_until_round`.
#' @param path Where to write. Directory is created if absent.
#' @param yahoo_names_path Pasted Yahoo player list used to correct spellings.
#'   NULL, or a path that does not exist, writes our own spellings unchanged.
#' @return `path`, invisibly. Writes a CSV of every player, rank 1..n.
export_yahoo_rankings <- function(draft_board, draft_fallback, league_config,
                                  path = "data/yahoo_rankings.csv",
                                  yahoo_names_path = "docs/yahoo-player-names.txt") {
  pool <- yahoo_ranking_order(draft_board, draft_fallback, league_config)

  out <- data.frame(
    rank = pool$rank,
    name = pool$player,
    # "FA" is our marker for a player on no roster, not a team Yahoo knows.
    # Blank is the honest value, and the column is optional anyway.
    team = ifelse(pool$team == "FA", "", pool$team),
    position = yahoo_position(pool$pos),
    stringsAsFactors = FALSE
  )

  # Not conditional on the paste: this is Yahoo's naming convention for team
  # defenses, and the whole position misses without it.
  is_def <- out$position == "DEF"
  out$name[is_def] <- yahoo_defense_name(out$name[is_def])

  # Optional by design: the list is a manual paste that will go stale, and a
  # missing one must degrade to our spellings rather than break the export.
  if (!is.null(yahoo_names_path) && file.exists(yahoo_names_path)) {
    out <- align_yahoo_names(out, parse_yahoo_names(yahoo_names_path))
    out$yahoo_matched <- NULL
  }

  # Written unquoted, matching the template Yahoo ships (which carries
  # "Ja'Marr Chase" bare, so its parser handles an apostrophe). That is only
  # safe while no field contains a delimiter or a quote -- no name does today,
  # and if one ever appears this must fail loudly rather than emit a file that
  # silently shifts every column right of it.
  unsafe <- grepl('[",]', unlist(out[, c("name", "team", "position")]))
  if (any(unsafe)) {
    stop("export_yahoo_rankings: field(s) contain a comma or quote, which the ",
         "unquoted CSV format cannot carry: ",
         paste(unique(unlist(out[, c("name", "team", "position")])[unsafe]), collapse = ", "))
  }

  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  utils::write.csv(out, path, row.names = FALSE, quote = FALSE)
  invisible(path)
}

#' Yahoo's position codes. Only DST differs from ours; Yahoo spells a team
#' defense DEF. The column is optional and the match runs on name, so a wrong
#' code here costs nothing -- it is a constant so it stays a one-line fix.
YAHOO_POSITIONS <- c(DST = "DEF")

yahoo_position <- function(pos) {
  mapped <- YAHOO_POSITIONS[pos]
  unname(ifelse(is.na(mapped), pos, mapped))
}

#' Rank the full pool for export: value first, deferred positions placed at the
#' pick their round begins at.
#'
#' Split out from the writing so the ordering -- the only part with judgement
#' in it -- can be tested without touching the filesystem.
#'
#' @inheritParams export_yahoo_rankings
#' @return data.frame of player, pos, team, ecr, vor, rank; one row per player,
#'   ordered by and numbered 1..n.
yahoo_ranking_order <- function(draft_board, draft_fallback, league_config) {
  cols <- c("player", "pos", "team", "ecr")
  board <- as.data.frame(draft_board)[, c(cols, "vor")]
  fb <- as.data.frame(draft_fallback)[, cols]
  # No VOR by definition -- that is what put them in the fallback. NA, not 0:
  # 0 would read as replacement level, which is a measurement.
  fb$vor <- NA_real_
  pool <- rbind(board, fb)

  teams <- league_config$teams
  defer <- league_config$draft$defer_until_round %||% list()
  pool$defer_round <- as.integer(unlist(lapply(pool$pos, function(p) defer[[p]] %||% NA)))

  # Best first: value where we have it, expert rank where we do not, and the
  # unvalued always behind the valued.
  pool <- pool[order(is.na(pool$vor), -pool$vor, pool$ecr), ]
  parked <- !is.na(pool$defer_round)

  # An undeferred player's target rank is just his place in that order. A
  # deferred one's is the first pick of his round, then one per player after.
  target <- numeric(nrow(pool))
  target[!parked] <- seq_len(sum(!parked))
  for (p in unique(pool$pos[parked])) {
    idx <- which(parked & pool$pos == p)
    target[idx] <- (pool$defer_round[idx[1]] - 1) * teams + seq_along(idx)
  }

  # Where a deferred block lands on top of undeferred players, the undeferred
  # go first: the deferred round is the earliest you would take one, not a
  # promise to take one there.
  pool <- pool[order(target, parked), ]
  pool$rank <- seq_len(nrow(pool))
  rownames(pool) <- NULL
  pool
}
