#' Append one event to the Pick Log.
#'
#' The log is an append-only .jsonl file (see docs/adr/0001-event-sourced-pick-log.md):
#' never mutated in place, so a crash mid-write can lose at most this one event.
append_pick_event <- function(log_path, event) {
  cat(jsonlite::toJSON(event, auto_unbox = TRUE), "\n", file = log_path, append = TRUE, sep = "")
}

#' Derive current draft state by replaying the Pick Log from scratch.
replay_pick_log <- function(log_path) {
  events <- lapply(readLines(log_path), jsonlite::fromJSON, simplifyVector = TRUE)

  my_team <- NULL
  my_slot <- NULL
  teams <- NULL
  # Draft-slot (1..teams, whose turn it is) -> team display name. Seeded with
  # your own name at your own slot; opponent slots get named the first time a
  # pick is logged for them (see slot_on_the_clock() in R/78_turn.R), and
  # re-typing a different name for that slot later renames it (last write
  # wins) -- lazy-created placeholders per PLAN_1.md's Phase 3.5 resolution.
  team_by_slot <- list()
  picks_by_slot <- list()
  for (e in events) {
    if (e$type == "draft_started") {
      teams <- e$teams
      if (!is.null(e$my_team)) my_team <- e$my_team
      if (!is.null(e$my_slot)) my_slot <- e$my_slot
      if (!is.null(my_slot) && !is.null(my_team)) {
        team_by_slot[[as.character(my_slot)]] <- my_team
      }
    } else if (e$type == "pick_made") {
      picks_by_slot[[as.character(e$slot)]] <- e
      if (!is.null(teams)) {
        team_slot <- slot_on_the_clock(e$slot, teams)
        team_by_slot[[as.character(team_slot)]] <- e$team
      }
    } else if (e$type == "pick_corrected") {
      picks_by_slot[[as.character(e$slot)]] <- NULL
    }
  }

  rosters <- list()
  drafted_players <- c()
  for (pick in picks_by_slot) {
    rosters[[pick$team]] <- c(rosters[[pick$team]], pick$player_key)
    drafted_players <- c(drafted_players, pick$player_key)
  }

  # Slot numbers are assigned sequentially as picks are made (see next_slot in
  # inst/app/app.R), so the highest surviving (non-corrected) slot is the most
  # recent live pick -- what the undo button needs to correct. NULL once every
  # pick has been undone or none have been made yet.
  last_pick_slot <- if (length(picks_by_slot) == 0) {
    NULL
  } else {
    max(as.numeric(names(picks_by_slot)))
  }

  list(rosters = rosters, drafted_players = drafted_players,
       my_team = my_team, my_slot = my_slot, teams = teams,
       last_pick_slot = last_pick_slot, team_by_slot = team_by_slot)
}

#' Append the draft_started event that opens a Pick Log session.
#'
#' `my_team`/`my_slot` are captured here (not in `config/league.json`) because
#' the real slot is only revealed at the table on draft night, so it's entered
#' once in the session-start setup screen instead of hand-edited into config.
start_draft <- function(log_path, teams, my_team, my_slot) {
  append_pick_event(log_path, list(
    type = "draft_started", teams = teams, my_team = my_team, my_slot = my_slot
  ))
}

#' Whether the session-start setup screen still needs to run: no log yet, or
#' an existing log whose draft_started event predates my_slot capture.
needs_setup <- function(log_path) {
  if (!file.exists(log_path)) return(TRUE)
  is.null(replay_pick_log(log_path)$my_slot)
}

#' Whether a slot number is a valid draft position for the given team count.
valid_my_slot <- function(my_slot, teams) {
  if (is.null(my_slot) || length(my_slot) != 1 || is.na(my_slot)) return(FALSE)
  my_slot == round(my_slot) && my_slot >= 1 && my_slot <= teams
}

#' Combine the Board and the fallback section into one selectable pool.
#'
#' The Player search box must draw from the full Draft Pool, not just the ranked
#' Board (see PLAN.md Phase 3.5: "Search draws full Draft Pool (including unranked
#' rookies), not just the ranked Board") -- otherwise 2026 rookies with no
#' current-season data yet (has_current_data = FALSE, e.g. Ashton Jeanty, Travis
#' Hunter) are invisible to search and can never be drafted through the app.
#'
#' @param draft_board data.table/data.frame with player_key, player, pos, team
#'   (plus tier/vor, dropped here).
#' @param draft_fallback data.table/data.frame with player_key, player, pos, team
#'   (plus ecr, dropped here).
#' @return A data.frame with just the shared columns needed for a dropdown label:
#'   player_key, player, pos, team.
combined_selectable_pool <- function(draft_board, draft_fallback) {
  shared_cols <- c("player_key", "player", "pos", "team")
  rbind(
    as.data.frame(draft_board)[, shared_cols],
    as.data.frame(draft_fallback)[, shared_cols]
  )
}

#' Filter a draft pool down to players not yet drafted, per current Pick Log state.
#'
#' @param draft_pool data.table from build_draft_pool(), with a player_key column.
#' @param pick_log_state list from replay_pick_log().
#' @return `draft_pool`, restricted to rows whose player_key isn't drafted.
remaining_draft_pool <- function(draft_pool, pick_log_state) {
  draft_pool[!(draft_pool$player_key %in% pick_log_state$drafted_players), ]
}
