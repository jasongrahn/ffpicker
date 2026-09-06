#' Positional-run guide: which position to draft *right now*.
#'
#' The Draft Board ranks players; it does not say *when to switch positions*
#' -- the actual decision made under a 1-minute pick clock (the gap named
#' directly in PLAN_1.md's Phase 3.6: "I wouldn't know where to switch from
#' one position to the next"). This assembles three signals that already
#' exist elsewhere -- tiers, snake-turn gap, roster need -- into one line per
#' position, rather than modeling anything new.
#'
#' The heuristic (see CLAUDE.md's snake-turn structure): count how many
#' players remain in a position's current best ("live") tier, and compare
#' that to how many picks stand between now and the user's next turn. If
#' opponents' picks will exhaust that tier before the user is back on the
#' clock, that position needs to be taken now -- waiting costs a whole tier,
#' not just one player.
#'
#' @param draft_board data.table/data.frame from assign_tiers() (R/75_value.R),
#'   with player_key, pos, tier for every player, drafted or not --
#'   remaining_draft_pool() filters to the undrafted subset internally.
#' @param pick_log_state list from replay_pick_log() (R/76_pick_log.R):
#'   rosters, my_team, my_slot, teams, drafted_players.
#' @param league_config Parsed league config (list), e.g. load_config("league"),
#'   for roster$starters and roster$flex_eligible$FLEX.
#' @return One row per position appearing in `draft_board`, with columns:
#'   pos, still_needed, tier_supply, picks_until_turn, survives, urgency.
#'   `picks_until_turn`/`survives`/`urgency` are NA when `my_slot` hasn't
#'   been captured yet (session setup not run) -- mirroring the NULL
#'   contract of picks_until_my_turn() itself, since there is no turn to
#'   compare against yet. `still_needed`/`tier_supply` don't depend on
#'   my_slot and are always computed.
scarcity_report <- function(draft_board, pick_log_state, league_config) {
  starters <- league_config$roster$starters
  flex_positions <- unlist(league_config$roster$flex_eligible$FLEX)

  remaining <- remaining_draft_pool(draft_board, pick_log_state)
  positions <- sort(unique(draft_board$pos))

  # Map the user's own roster's player_keys to positions via the board, so
  # still_needed reflects starter slots actually filled so far. A roster pick
  # that never appears on this board (an off-board fallback pick, say) can't
  # be classified and is silently dropped from the need count rather than
  # erroring -- a documented v0 limitation, not a crash.
  my_team <- pick_log_state$my_team
  my_roster_keys <- if (is.null(my_team)) NULL else pick_log_state$rosters[[my_team]]
  my_roster_pos <- draft_board$pos[match(my_roster_keys, draft_board$player_key)]
  my_roster_pos <- my_roster_pos[!is.na(my_roster_pos)]

  # Flex-eligible positions (RB/WR/TE) share one pool of slots: their own
  # dedicated starters plus the shared FLEX slot(s), mirroring compute_vor()'s
  # shared replacement level in R/75_value.R. still_needed is set to the
  # *same* remaining-pool count for RB, WR, and TE alike -- not split per
  # position -- because any of the three can fill the open FLEX slot, so
  # drafting any one of them is a legitimate way to close the remaining need.
  # A hard per-position split would understate urgency for whichever position
  # happens to have its own dedicated slots full already but could still plug
  # the FLEX slot.
  flex_dedicated_slots <- sum(vapply(flex_positions, function(p) starters[[p]] %||% 0, numeric(1)))
  flex_slot_count <- starters$FLEX %||% 0
  flex_total_slots <- flex_dedicated_slots + flex_slot_count
  flex_drafted <- sum(my_roster_pos %in% flex_positions)
  flex_need_pool <- max(0, flex_total_slots - flex_drafted)

  picks_until_turn <- picks_until_my_turn(pick_log_state)

  rows <- lapply(positions, function(p) {
    if (p %in% flex_positions) {
      still_needed <- flex_need_pool
    } else {
      drafted <- sum(my_roster_pos == p)
      still_needed <- max(0, (starters[[p]] %||% 0) - drafted)
    }

    # The "current live tier" is the best (lowest-numbered) tier that still
    # has an undrafted player in it -- tier 1 once its players are gone means
    # tier 2 is now what's actually on offer, not that the position is dead.
    live <- remaining[remaining$pos == p, ]
    if (nrow(live) == 0) {
      tier_supply <- 0
    } else {
      live_tier <- min(live$tier)
      tier_supply <- sum(live$tier == live_tier)
    }

    # Strict ">" is deliberate: if tier_supply exactly equals picks_until_turn,
    # opponents could take every single one of them before the user is back on
    # the clock, so the tier does not reliably survive.
    survives <- if (is.null(picks_until_turn)) NA else tier_supply > picks_until_turn

    urgency <- if (is.na(survives)) {
      NA_integer_
    } else if (still_needed > 0 && !survives) {
      1L # needed, and will be gone before your turn -- take it now
    } else if (still_needed > 0 && survives) {
      2L # needed, but can safely wait a turn
    } else if (still_needed == 0 && !survives) {
      3L # not needed for a starter slot, regardless of scarcity
    } else {
      4L # not needed, and in no danger either -- least urgent
    }

    data.frame(
      pos = p,
      still_needed = still_needed,
      tier_supply = tier_supply,
      picks_until_turn = if (is.null(picks_until_turn)) NA_integer_ else picks_until_turn,
      survives = survives,
      urgency = urgency,
      stringsAsFactors = FALSE
    )
  })

  result <- do.call(rbind, rows)
  rownames(result) <- NULL
  result
}
