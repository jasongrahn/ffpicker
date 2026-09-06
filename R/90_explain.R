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
  ordered <- rank_positions(report)
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

#' Rank a scarcity report's positions: the one draft-order every caller uses.
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
#'
#' This exists as one function because the alternative already failed. When
#' target_position(), scarcity_display() and explain_scarcity() each held their
#' own copy of the sort, fixing two of them left the third ranking by the old
#' rule -- so the app recommended CeeDee Lamb while the sentence around his
#' name explained a tight end shortage (reported 2026-09-06). Three orderings
#' that must agree are three chances to disagree. Callers get this one or none.
#'
#' @param report data.frame from scarcity_report().
#' @return `report`, rows reordered. Rows are not filtered.
rank_positions <- function(report) {
  report[order(report$urgency, -vor_best_or_na(report), report$tier_supply,
               na.last = TRUE), ]
}

#' Rows with a starter slot open that the plan also allows drafting this round.
#'
#' `deferred` started life as an urgency demotion only, which worked exactly as
#' long as some other position still had a slot open. In a 17-round dry run
#' every non-deferred slot was filled by round 8, K and DST became the only
#' rows with still_needed > 0, and the demotion had nothing left to lose to --
#' so the app recommended Jason Myers in round 8 against a defer_until_round of
#' 16 (found 2026-09-06). Deferral has to remove the row from consideration,
#' not merely rank it last.
#'
#' Shared by target_position() and explain_scarcity() for the same reason
#' rank_positions() is shared: two copies of this filter are two chances for
#' the recommended player and the sentence about him to disagree.
#'
#' @param report data.frame from scarcity_report().
#' @return Subset of `report`. Reports predating `deferred` filter on need only.
draftable_now <- function(report) {
  needed <- report[report$still_needed > 0, , drop = FALSE]
  if (is.null(needed$deferred)) return(needed)
  needed[!isTRUE_each(needed$deferred), , drop = FALSE]
}

#' The mirror of draftable_now(): needed, but parked until a later round.
deferred_needs <- function(report) {
  needed <- report[report$still_needed > 0, , drop = FALSE]
  if (is.null(needed$deferred)) return(needed[0, , drop = FALSE])
  needed[isTRUE_each(needed$deferred), , drop = FALSE]
}

#' The position scarcity_report() says to take next, or NA if nothing is needed.
#'
#' @return Single position code, or NA_character_ when no starter slot is open
#'   -- including when the only open slots are ones the plan parks until later.
target_position <- function(report) {
  if (is.null(report) || nrow(report) == 0) return(NA_character_)
  open <- draftable_now(report)
  if (nrow(open) == 0) return(NA_character_)
  rank_positions(open)$pos[1]
}

#' `vor_best` as a plain numeric, tolerating a report that predates the column.
#'
#' Degrading to "no value information, fall through to the next tiebreak" beats
#' erroring. This runs under a 1-minute pick clock, where a blank advice line
#' is recoverable by reading the board and a crashed app is not.
vor_best_or_na <- function(report) {
  if (is.null(report$vor_best)) rep(NA_real_, nrow(report)) else as.numeric(report$vor_best)
}

#' Positions the config says to leave until late, as display notes.
#'
#' @param report data.frame from scarcity_report().
#' @return Named character vector, position -> note ("wait til rd 16"). Empty
#'   when nothing is deferred, or when handed a report that predates the
#'   `deferred` column.
deferred_notes <- function(report) {
  if (is.null(report) || nrow(report) == 0 || is.null(report$deferred)) {
    return(character(0))
  }
  hit <- isTRUE_each(report$deferred)
  if (!any(hit)) return(character(0))
  pos <- report$pos[hit]
  round <- if (is.null(report$defer_until_round)) {
    rep(NA_integer_, length(pos))
  } else {
    as.integer(report$defer_until_round[hit])
  }
  setNames(ifelse(is.na(round), "wait til late", paste0("wait til rd ", round)), pos)
}

#' Vectorised isTRUE(). NA counts as not-true rather than propagating.
isTRUE_each <- function(x) !is.na(x) & x

#' Escape the three characters that would break out of an HTML table cell.
#'
#' mark_deferred() emits raw markup, so its caller has to turn xtable's own
#' escaping off. This puts the escaping back for the parts that are data.
escape_html <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

#' Grey out board rows whose position the league plan says not to draft yet.
#'
#' The Board is a truthful "best available" and must keep showing these
#' players -- filtering them would misstate what is actually on the board, and
#' a hidden player cannot be reconsidered when a plan changes. But leaving them
#' unmarked put kicker Jason Myers at board rank 21 while the run guide beside
#' him read "Wait til late", so the two panes contradicted each other on screen
#' (reported 2026-09-06). Dim and label; never remove.
#'
#' Output cells are raw HTML, so the caller MUST render with
#' `sanitize.text.function = identity`. Every cell is escaped here first.
#'
#' @param display data.frame already formatted for display -- numbers must
#'   arrive pre-rounded, since every column comes back as character.
#' @param pos Character vector of positions, one per row of `display`.
#' @param notes deferred_notes() output.
#' @param note_col Column the "wait til" note is appended to.
#' @return `display` with all-character cells; deferred rows wrapped in a
#'   dimming span. Escaping happens whether or not anything is deferred, so the
#'   caller's sanitize setting is safe on every path.
mark_deferred <- function(display, pos, notes, note_col = "Player") {
  display[] <- lapply(display, function(col) escape_html(as.character(col)))
  hit <- pos %in% names(notes)
  if (length(notes) == 0 || !any(hit)) return(display)
  display[[note_col]][hit] <- paste0(
    display[[note_col]][hit], " — ", notes[pos[hit]]
  )
  for (nm in names(display)) {
    display[[nm]][hit] <- paste0(
      "<span style=\"color: #9aa0a6;\">", display[[nm]][hit], "</span>"
    )
  }
  display
}

#' "defense (round 15) and kicker (round 16)" -- parked positions, soonest first.
#'
#' @param parked deferred_needs() output.
#' @return Single string. Empty input returns "" rather than erroring; a blank
#'   readout mid-draft is recoverable, a crashed app is not.
parked_phrase <- function(parked) {
  if (nrow(parked) == 0) return("")
  round <- if (is.null(parked$defer_until_round)) {
    rep(NA_integer_, nrow(parked))
  } else {
    as.integer(parked$defer_until_round)
  }
  ord <- order(round, na.last = TRUE)
  names_ <- position_name(parked$pos[ord])
  round <- round[ord]
  parts <- ifelse(is.na(round), names_, paste0(names_, " (round ", round, ")"))
  if (length(parts) == 1) return(parts)
  paste0(paste(parts[-length(parts)], collapse = ", "), " and ", parts[length(parts)])
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
    Value = sprintf("+%.0f pts", rb$vor),
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
        Value = sprintf("expert rank %.0f", fb$ecr),
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

  # Every open slot is a position the plan parks until later. Saying "lineup is
  # full" here would be a lie -- kicker and defense are genuinely still empty --
  # so name them and their rounds, and say what to do with the picks between now
  # and then. This is rounds 10-14 of a real draft, not an edge case.
  open <- draftable_now(report)
  if (nrow(open) == 0) {
    return(paste0("Starters set apart from ", parked_phrase(deferred_needs(report)),
                  ". Draft the best bench player you can until then."))
  }

  ranked <- rank_positions(open)

  # Describe the row belonging to the player actually being named, not merely
  # the top-ranked row. These are the same row whenever recommend_picks() and
  # this function were handed the same report -- but when they diverged, the
  # sentence read "Take CeeDee Lamb (WR, DAL) now. Only 1 tight end left at
  # that level", naming a receiver and counting tight ends (reported
  # 2026-09-06). Keying off `picks` makes the name and the noun the same fact,
  # so no future re-ranking can split them again.
  top <- ranked[1, ]
  if (!is.null(picks) && nrow(picks) > 0) {
    matched <- ranked[ranked$pos == picks$Pos[1], ]
    if (nrow(matched) > 0) top <- matched[1, ]
  }
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
