#' Yahoo's own draft ordering: XRank and ADP, as an OPPONENT model.
#'
#' `docs/yahoo_fantasy_football_adp.csv` is user-harvested from Yahoo's draft
#' room and cleaned outside this repo. It is the only source in the project for
#' what the *other nine managers* will actually do -- every other ranking here
#' is expert opinion, and the gate in `dev/yahoo_gate.R` showed the two differ
#' enough to change 5 of our 17 picks.
#'
#' These columns are deliberately inert. `xrank`/`adp` ride along on the Board
#' for display and for simulating opponents; nothing blends them into `vor`.
#' Our board is our opinion and stands on its own. Yahoo tells us who survives
#' to our pick, not who is good.
#'
#' NAME JOIN, stated at point of use per CLAUDE.md. Yahoo's export carries no
#' `yahoo_id`, and `ff_rankings`' `redraft-overall` slice is 100% NA on
#' `yahoo_id`, so there is no id on either side to join. Name + position is all
#' there is. `add_yahoo_ranks()` reports its match rate on every run.
#'
#' @param path CSV path. Columns Player, Position, Team, Bye Week, XRank, ADP.
#' @return data.frame: name, pos, team, bye, xrank, adp, k (the match key).
#'   Defenses remapped DEF -> DST. Duplicate keys dropped, first wins.
load_yahoo_adp <- function(path = "docs/yahoo_fantasy_football_adp.csv") {
  y <- utils::read.csv(path, stringsAsFactors = FALSE)
  if (ncol(y) != 6) {
    stop("load_yahoo_adp: expected 6 columns, got ", ncol(y), " in ", path)
  }
  names(y) <- c("name", "pos", "team", "bye", "xrank", "adp")
  y <- y[nzchar(trimws(y$name)), , drop = FALSE]
  y$pos[y$pos == "DEF"] <- "DST"
  y$xrank <- suppressWarnings(as.numeric(y$xrank))
  y$adp <- suppressWarnings(as.numeric(y$adp))
  y$k <- normalize_player_name(y$name, y$pos)
  y[!duplicated(y$k), , drop = FALSE]
}

#' Attach `xrank`/`adp` to a board by normalised name + position.
#'
#' @param df Board or fallback table. Needs `player` and `pos`.
#' @param yahoo Output of `load_yahoo_adp()`.
#' @param label Name used in the match-rate message.
#' @return `df` plus numeric `xrank` and `adp`. NA where Yahoo does not list
#'   the player -- overall coverage is deliberately partial (Yahoo publishes
#'   ~330 names; the pool is 764), and the misses are undraftable tail.
add_yahoo_ranks <- function(df, yahoo, label = "board") {
  df <- as.data.frame(df, stringsAsFactors = FALSE)
  k <- normalize_player_name(df$player, df$pos)
  hit <- match(k, yahoo$k)
  df$xrank <- yahoo$xrank[hit]
  df$adp <- yahoo$adp[hit]

  n <- nrow(df)
  matched <- sum(!is.na(df$xrank))
  msg <- sprintf("yahoo name join [%s]: %d/%d rows matched (%.1f%%)",
                 label, matched, n, 100 * matched / max(n, 1))
  if (!is.null(df$ecr)) {
    top <- utils::head(order(df$ecr), 170)
    msg <- sprintf("%s; top-%d-by-ecr: %d/%d",
                   msg, length(top), sum(!is.na(df$xrank[top])), length(top))
  }
  message(msg)
  df
}

#' Divergence between our board order and Yahoo's draft-room order.
#'
#' Read-only. Feeds display and nothing else -- no scoring input consumes it.
#' Our rank is our own board position (Extra pts, descending), so the number
#' answers one question: is the room going to take this man earlier than we
#' would? Negative means Yahoo ranks him higher (earlier). At -20 or beyond the
#' gap is big enough that planning to wait on him is planning to lose him.
#'
#' @param board data.frame with `vor` and `xrank`.
#' @return Integer vector, `xrank - our_rank`. NA where Yahoo does not list him.
yahoo_divergence <- function(board) {
  our_rank <- rank(-board$vor, ties.method = "first", na.last = "keep")
  as.integer(round(board$xrank - our_rank))
}

#' Threshold for "the room takes him early, do not wait."
YAHOO_EARLY_GAP <- -20L

#' Render `yahoo_divergence()` for the Board table.
#'
#' Plain number normally. At `YAHOO_EARLY_GAP` or beyond it carries its own
#' plain-English warning in the cell, because under a 1-minute clock a bare
#' "-26" is a number nobody decodes in time. HTML, so the Board's
#' `sanitize.text.function = identity` renders it.
#'
#' @param gap Integer vector from `yahoo_divergence()`.
#' @return Character vector. Empty string where Yahoo does not list the player.
yahoo_gap_display <- function(gap) {
  out <- ifelse(is.na(gap), "", as.character(gap))
  early <- !is.na(gap) & gap <= YAHOO_EARLY_GAP
  out[early] <- sprintf(
    "<span style='color:#b00020; font-weight:bold;'>%d takes him early</span>",
    gap[early]
  )
  out
}
