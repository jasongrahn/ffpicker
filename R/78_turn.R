#' Which draft slot is on the clock for a given overall pick number.
#'
#' Inverts the snake-turn formula in the root CLAUDE.md (pick from round/slot)
#' to go the other direction: round/slot from pick number.
slot_on_the_clock <- function(pick_number, teams) {
  r <- ceiling(pick_number / teams)
  pos <- pick_number - (r - 1) * teams
  if (r %% 2 == 1) pos else teams - pos + 1
}

#' How many picks stand between `current_pick` and `my_slot`'s next turn.
picks_until_turn <- function(current_pick, my_slot, teams) {
  pick_number <- current_pick
  while (slot_on_the_clock(pick_number, teams) != my_slot) {
    pick_number <- pick_number + 1
  }
  pick_number - current_pick
}

#' Picks remaining before your next turn, given current Pick Log state.
#' @return NULL if the draft hasn't captured a my_slot yet (setup not run).
picks_until_my_turn <- function(state) {
  if (is.null(state$my_slot)) return(NULL)
  current_pick <- length(state$drafted_players) + 1
  picks_until_turn(current_pick, state$my_slot, state$teams)
}

#' Display name for a draft slot: its mapped name if known, else a
#' "Team <slot>" placeholder (lazy-created, renamed once you learn who they
#' are -- see PLAN_1.md's Phase 3.5 resolution).
team_for_slot <- function(team_map, slot) {
  name <- team_map[[as.character(slot)]]
  if (is.null(name)) paste0("Team ", slot) else name
}

#' Display name for whoever is on the clock for the *next* pick, so the pick
#' entry form can auto-advance instead of requiring the drafter to retype the
#' correct opponent name from memory every 1-2 minutes for the whole draft.
#' @return NULL if the draft hasn't started yet (no `teams` captured).
next_team_name <- function(state) {
  if (is.null(state$teams)) return(NULL)
  next_pick <- length(state$drafted_players) + 1
  team_slot <- slot_on_the_clock(next_pick, state$teams)
  team_for_slot(state$team_by_slot, team_slot)
}
