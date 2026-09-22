#' Lineup decision deadlines.
#'
#' A slot's deadline is NOT the starter's own kickoff. It is bounded by the
#' earliest kickoff among the players who could legally replace him, because
#' a replacement who has already played cannot be moved into the lineup.
#'
#' Measured failure this rule exists to stop, 2026 week 2: Adams (LAR) locked
#' Mon 20:15 and the decision doc recorded that as the deadline. Every WR who
#' could have replaced him -- Odunze, Robinson, Raymond -- kicked off Sun
#' 13:00. The call was really due 31 hours earlier than the doc claimed. It
#' cost nothing that week only because the start was correct anyway.
#'
#' Two deadlines are reported because they answer different questions:
#'
#' * `all_options_until` -- last moment the FULL replacement set is still
#'   reachable. After it, the option set is shrinking. This is the one to put
#'   in a decision doc.
#' * `last_change_at` -- last moment ANY change is still possible. After it,
#'   the slot is frozen regardless of news.
#'
#' Both are capped by the starter's own kickoff: he cannot be removed once he
#' has played.

#' Slot -> eligible positions, derived from league config.
#'
#' Never hardcode this. FLEX eligibility is a league rule and lives in
#' `config/league.json` under `roster.flex_eligible`.
#'
#' @param league Parsed league config (list), e.g. `load_config("league")`.
#' @return Named list, slot name -> character vector of eligible positions.
slot_eligibility <- function(league) {
  starters <- names(league$roster$starters)
  elig <- stats::setNames(as.list(starters), starters)
  for (slot in names(league$roster$flex_eligible)) {
    elig[[slot]] <- unlist(league$roster$flex_eligible[[slot]], use.names = FALSE)
  }
  # Yahoo's exports say DEF where the config says DST. Same slot, two spellings;
  # accept both rather than making every caller remember which is which.
  if (!is.null(elig[["DST"]]) && is.null(elig[["DEF"]])) elig[["DEF"]] <- c("DST", "DEF")
  if (!is.null(elig[["DST"]])) elig[["DST"]] <- c("DST", "DEF")
  elig
}

#' Normalize a roster's team abbreviations onto nflreadr's.
#'
#' Yahoo writes mixed case (`Dal`, `Bal`, `Hou`) and splits the Rams as `LAR`
#' where nflreadr has used `LA` in some seasons. Upper-casing fixes all but
#' the Rams, which is resolved against the teams actually present in the
#' schedule rather than assumed.
#'
#' @param team Character vector of team codes.
#' @param schedule_teams Character vector of team codes seen in the schedule.
#' @return Character vector, normalized.
normalize_team <- function(team, schedule_teams) {
  out <- toupper(team)
  if (!("LAR" %in% schedule_teams) && ("LA" %in% schedule_teams)) {
    out[out == "LAR"] <- "LA"
  } else if (!("LA" %in% schedule_teams) && ("LAR" %in% schedule_teams)) {
    out[out == "LA"] <- "LAR"
  }
  out
}

#' Kickoff time per team for one week.
#'
#' `as.data.frame()` first is load-bearing, not tidying. `load_schedules()`
#' returns a data.table, whose `[` evaluates `i` inside the table's own frame
#' -- so `schedule[schedule$week == wk, ]` resolves `wk` to the table's `week`
#' COLUMN, making the condition `week == week`, all TRUE. It does not error;
#' it silently returns the whole season. Cost an hour on 2026-09-22.
#'
#' @param schedule `nflreadr::load_schedules()` output.
#' @param wk Week number.
#' @return data.frame with `team` and `kickoff` (POSIXct, US/Eastern).
team_kickoffs <- function(schedule, wk) {
  schedule <- as.data.frame(schedule)
  w <- schedule[schedule$week == wk, ]
  stopifnot(nrow(w) > 0L, nrow(w) <= 16L)
  ko <- as.POSIXct(paste(w$gameday, w$gametime), format = "%Y-%m-%d %H:%M",
                   tz = "America/New_York")
  data.frame(
    team    = c(w$home_team, w$away_team),
    kickoff = rep(ko, 2L),
    stringsAsFactors = FALSE
  )
}

#' Compute the real decision deadline for every started slot.
#'
#' @param roster data.frame with `player`, `pos`, `nfl_team`, `slot`, `started`.
#'   `slot` is the lineup slot for starters; bench rows carry `started = FALSE`.
#' @param schedule `nflreadr::load_schedules()` output.
#' @param league Parsed league config (list).
#' @param week Week number.
#' @return data.frame, one row per started slot, ordered by `all_options_until`.
#'   `binding` names what sets the deadline: `"replacement"` when a bench
#'   player's kickoff binds before the starter's own, else `"own kickoff"`.
#'   `n_replacements` of 0 means the slot is already forced.
build_slot_deadlines <- function(roster, schedule, league, week) {
  elig <- slot_eligibility(league)
  ko <- team_kickoffs(schedule, week)
  sched_teams <- unique(ko$team)

  roster$team <- normalize_team(roster$nfl_team, sched_teams)
  missing <- setdiff(roster$team, sched_teams)
  if (length(missing)) {
    warning("No week ", week, " game for: ", paste(missing, collapse = ", "),
            " -- bye, or an unmapped abbreviation. Treated as unavailable.")
  }
  roster$kickoff <- ko$kickoff[match(roster$team, ko$team)]

  starters <- roster[isTRUE_vec(roster$started), , drop = FALSE]
  bench    <- roster[!isTRUE_vec(roster$started), , drop = FALSE]

  rows <- lapply(seq_len(nrow(starters)), function(i) {
    s <- starters[i, ]
    ok <- elig[[s$slot]]
    if (is.null(ok)) {
      warning("Slot '", s$slot, "' is not in league config; skipped. ",
              "Config uses: ", paste(names(elig), collapse = ", "))
      return(NULL)
    }
    # A replacement must be position-eligible AND have a known kickoff.
    cand <- bench[bench$pos %in% ok & !is.na(bench$kickoff), , drop = FALSE]
    own <- s$kickoff

    if (nrow(cand) == 0L) {
      all_until <- own; last_at <- own; binding <- "own kickoff (no bench option)"
    } else {
      all_until <- min(c(own, cand$kickoff))
      last_at   <- min(own, max(cand$kickoff))
      binding   <- if (!is.na(own) && all_until < own) "replacement" else "own kickoff"
    }

    data.frame(
      slot = s$slot, player = s$player, pos = s$pos, team = s$team,
      own_kickoff = own, n_replacements = nrow(cand),
      all_options_until = all_until, last_change_at = last_at,
      binding = binding, stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  out[order(out$all_options_until, out$last_change_at), ]
}

# `started` may arrive as logical or as the string "TRUE" from a CSV read.
isTRUE_vec <- function(x) if (is.logical(x)) !is.na(x) & x else toupper(as.character(x)) == "TRUE"
