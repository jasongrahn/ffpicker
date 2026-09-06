#' Plain-English rationale. Per CLAUDE.md: user has casual football knowledge,
#' so position codes and bare numbers carry no meaning under a 1-minute pick
#' clock. Explanation is product feature, not decoration.

#' Full position names. "WR" means nothing to casual drafter mid-clock.
POSITION_NAMES <- c(
  QB = "quarterback", RB = "running back", WR = "wide receiver",
  TE = "tight end", K = "kicker", DST = "defense"
)

#' Spell out position code. Unknown codes pass through unchanged rather than
#' erroring -- a board with surprise position should degrade, not crash draft night.
position_name <- function(pos) {
  out <- POSITION_NAMES[pos]
  ifelse(is.na(out), pos, out)
}

#' "1 tight end" / "3 tight ends". Tier sizes of exactly 1 are the common case
#' at the top of the board, so this is not a rare path.
count_of <- function(n, noun) paste0(n, " ", noun, if (n == 1) "" else "s")

#' Urgency codes from scarcity_report(), in words. The integers exist to sort by;
#' they are not something to show a drafter mid-clock.
URGENCY_LABELS <- c(
  "1" = "TAKE NOW", "2" = "Can wait", "3" = "Not needed", "4" = "Not needed",
  "5" = "Wait til late"
)

#' Rewrite scarcity_report() for display: full position names, worded urgency,
#' sorted most-urgent first. Column names are the ones a reader can act on.
#'
#' @param report data.frame from scarcity_report().
#' @return data.frame with columns Position, Need, `Left at this level`,
#'   `Picks to your turn`, Status. Zero-row input returns a zero-row frame of
#'   the same shape so renderTable() has something to draw.
scarcity_display <- function(report) {
  if (is.null(report) || nrow(report) == 0) report <- report[0, , drop = FALSE]
  ordered <- report[order(report$urgency, -vor_best_or_na(report),
                          report$tier_supply, na.last = TRUE), ]
  out <- data.frame(
    Position = position_name(ordered$pos),
    Need = as.integer(ordered$still_needed),
    `Left at this level` = as.integer(ordered$tier_supply),
    `Picks to your turn` = as.integer(ordered$picks_until_turn),
    Status = unname(ifelse(is.na(ordered$urgency), "—",
                           URGENCY_LABELS[as.character(ordered$urgency)])),
    check.names = FALSE, stringsAsFactors = FALSE
  )
  rownames(out) <- NULL
  out
}

#' The position scarcity_report() says to take next, or NA if nothing is needed.
#'
#' Most urgent first, then most value at stake, then thinnest live tier.
#'
#' `vor_best` sits ahead of `tier_supply` deliberately. Scarcity on its own
#' cannot rank positions: assign_tiers() works within a position, so at pick 1
#' every position's tier 1 holds exactly one player and urgency + tier_supply
#' tie across RB/WR/TE/K. The sort then fell through to `positions`' own
#' alphabetical order and answered "kicker" first overall -- correct by the
#' letter of the old rule, useless in a draft (reported 2026-09-06). Between
#' two equally urgent positions the one to take is the one where passing costs
#' more points, and VOR is the only cross-position-comparable number available.
#' Thinnest tier stays as the last tiebreak, where it still means something.
#' @return Single position code, or NA_character_ when no starter slot is open.
target_position <- function(report) {
  if (is.null(report) || nrow(report) == 0) return(NA_character_)
  needed <- report[report$still_needed > 0, ]
  if (nrow(needed) == 0) return(NA_character_)
  needed <- needed[order(needed$urgency, -vor_best_or_na(needed),
                         needed$tier_supply, na.last = TRUE), ]
  needed$pos[1]
}

#' `vor_best` as a plain numeric, tolerating a report that predates the column.
#'
#' Degrading to "no value information, fall through to the next tiebreak" beats
#' erroring. This runs under a 1-minute pick clock, where a blank advice line
#' is recoverable by reading the board and a crashed app is not.
vor_best_or_na <- function(report) {
  if (is.null(report$vor_best)) rep(NA_real_, nrow(report)) else as.numeric(report$vor_best)
}

#' Name the specific players to take, not just the position.
#'
#' "Take a running back" is only half an answer under a 1-minute clock -- the
#' whole point is not having to cross-reference the position against the Board
#' by eye. This picks the undrafted players at the target position, best first.
#'
#' Ranked players (the Board, which carries VOR) come first and are ordered by
#' VOR. Unranked ones (rookies, DSTs -- no VOR at all) are appended in ECR
#' order, and only surface when the position has no ranked players left, or
#' too few to fill `n`. DST is the case that matters: it lives entirely in the
#' fallback, so without this half the recommendation would come back empty.
#'
#' @param report data.frame from scarcity_report().
#' @param remaining_board undrafted rows of the Board: player, pos, team, tier, vor.
#' @param remaining_fallback undrafted fallback rows: player, pos, team, ecr.
#' @param n How many to name.
#' @return data.frame with Player, Pos, Team, Tier, Value -- zero rows when no
#'   starter slot is open or the position is exhausted.
recommend_picks <- function(report, remaining_board, remaining_fallback, n = 3) {
  empty <- data.frame(Player = character(0), Pos = character(0), Team = character(0),
                      Tier = integer(0), Value = character(0), stringsAsFactors = FALSE)
  pos <- target_position(report)
  if (is.na(pos)) return(empty)

  rb <- as.data.frame(remaining_board)
  rb <- rb[rb$pos == pos, , drop = FALSE]
  rb <- rb[order(rb$vor, decreasing = TRUE), , drop = FALSE]
  ranked <- if (nrow(rb) == 0) empty else data.frame(
    Player = rb$player, Pos = rb$pos, Team = rb$team,
    Tier = as.integer(rb$tier),
    Value = sprintf("%.0f VOR", rb$vor),
    stringsAsFactors = FALSE
  )

  out <- head(ranked, n)
  if (nrow(out) < n) {
    fb <- as.data.frame(remaining_fallback)
    fb <- fb[fb$pos == pos, , drop = FALSE]
    fb <- fb[order(fb$ecr), , drop = FALSE]
    if (nrow(fb) > 0) {
      unranked <- data.frame(
        Player = fb$player, Pos = fb$pos, Team = fb$team,
        Tier = NA_integer_,
        Value = sprintf("ECR %.0f", fb$ecr),
        stringsAsFactors = FALSE
      )
      out <- rbind(out, head(unranked, n - nrow(out)))
    }
  }
  rownames(out) <- NULL
  out
}

#' Turn scarcity_report() into one sentence naming what to draft next.
#'
#' Picks most urgent position -> explains supply vs turn gap in words. Ties
#' broken by thinnest tier_supply, since scarcer position is the one that
#' disappears first.
#'
#' @param report data.frame from scarcity_report().
#' @param picks Optional recommend_picks() output. When supplied, the sentence
#'   names the actual player instead of only his position -- per CLAUDE.md, a
#'   name alone carries no meaning here, so it always ships with team and
#'   position attached.
#' @return Single character string. Never NA, never zero-length -- app renders
#'   this directly and blank readout mid-draft is worse than a hedge.
explain_scarcity <- function(report, picks = NULL) {
  # "Bijan Robinson (RB, ATL)" -- never a bare surname.
  who <- if (!is.null(picks) && nrow(picks) > 0) {
    paste0(picks$Player[1], " (", picks$Pos[1], ", ", picks$Team[1], ")")
  } else {
    NULL
  }
  named <- function(fallback_phrase) if (is.null(who)) fallback_phrase else who

  if (is.null(report) || nrow(report) == 0) {
    return("No board data yet.")
  }
  # my_slot not captured (setup not run) -> turn-dependent columns are NA.
  # Report need without pretending to know the gap.
  if (all(is.na(report$picks_until_turn))) {
    needed <- report[report$still_needed > 0, ]
    if (nrow(needed) == 0) return("Starting lineup is full. Draft best available.")
    return(paste0("Still need: ",
                  paste(position_name(needed$pos), collapse = ", "),
                  ". Enter your draft slot for run warnings."))
  }

  needed <- report[report$still_needed > 0, ]
  if (nrow(needed) == 0) {
    return("Starting lineup is full. Draft best available for the bench.")
  }

  ranked <- needed[order(needed$urgency, needed$tier_supply), ]
  top <- ranked[1, ]
  gap <- top$picks_until_turn
  pos <- position_name(top$pos)

  if (gap == 0) {
    return(paste0("You're on the clock. Take ", named(paste("a", pos)),
                  " -- thinnest position you still need, ",
                  top$tier_supply, " left at that level."))
  }

  # survives == FALSE -> tier empties before next turn -> take it now.
  if (!isTRUE(top$survives)) {
    return(paste0("Take ", named(paste("a", pos)), " now. Only ",
                  count_of(top$tier_supply, pos), " left at that level and ",
                  count_of(gap, "pick"),
                  " until your turn -- likely gone."))
  }

  paste0("No rush -- ", count_of(top$tier_supply, pos), " left at that level and ",
         count_of(gap, "pick"), " until your turn. ",
         if (is.null(who)) "Take the best player available."
         else paste0("Best available there is ", who, "."))
}
