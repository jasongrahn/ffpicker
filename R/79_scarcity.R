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
#' Build the position-complete board that scarcity_report() needs.
#'
#' The Board alone is not position-complete: it has no DST rows at all (team-level,
#' no dim_player row -- see _targets.R) and no rookies (has_current_data = FALSE).
#' Feeding it to scarcity_report() directly means drafting a rookie RB1 or a DST
#' leaves those picks unclassifiable, so `still_needed` keeps demanding a position
#' you already filled. Combining fixes the need count.
#'
#' Fallback players get a tier one past the Board's worst. They are genuinely
#' unranked by VOR, so they must not dilute a live tier's `tier_supply`; parking
#' them behind every ranked player means they only become the live tier once the
#' ranked ones at that position are actually gone -- which is exactly true.
#'
#' @param draft_board from assign_tiers(); needs player_key, player, pos, team, tier.
#' @param draft_fallback from build_fallback_board() + dst_pool; no tier column.
#' @return data.frame with the five shared columns, fallback rows tier-padded.
scarcity_input <- function(draft_board, draft_fallback) {
  cols <- c("player_key", "player", "pos", "team", "tier", "vor")
  board <- as.data.frame(draft_board)[, cols]
  fb <- as.data.frame(draft_fallback)[, setdiff(cols, c("tier", "vor"))]
  fb$tier <- max(board$tier, na.rm = TRUE) + 1L
  # Fallback players have no VOR by definition (that is what puts them in the
  # fallback). NA, not 0: 0 would read as "replacement level", which is a
  # measurement, and these are unmeasured.
  fb$vor <- NA_real_
  rbind(board, fb)
}

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
  drafted_count <- function(p) sum(my_roster_pos == p)

  # RB2/WR2/TE1 are NOT interchangeable with each other -- only the single
  # shared FLEX slot is open to all three. An earlier version of this
  # function collapsed dedicated + FLEX into one shared-pool number
  # (`flex_total_slots - flex_drafted`, applied identically to RB/WR/TE);
  # that hid which specific position was actually empty. E.g. 3 drafted RBs
  # fill both RB starter slots plus FLEX, leaving RB's true need at 0 -- but
  # the shared-pool number reported RB/WR/TE all == 3, telling the drafter
  # to keep taking RBs while WR and TE sat empty (bug reported 2026-09-06).
  #
  # Correct model: dedicated need per position is independent; the shared
  # FLEX slot is "open" only if drafted flex-eligible picks haven't already
  # exceeded their combined dedicated slots (that excess -- "flex surplus"
  # -- is exactly who is eligible to occupy FLEX). Whatever FLEX need
  # remains is then added to *each* flex-eligible position's own dedicated
  # need, since any of the three can legitimately close it.
  dedicated_need <- setNames(
    vapply(positions, function(p) max(0, (starters[[p]] %||% 0) - drafted_count(p)), numeric(1)),
    positions
  )
  flex_surplus <- sum(vapply(flex_positions, function(p) {
    max(0, drafted_count(p) - (starters[[p]] %||% 0))
  }, numeric(1)))
  flex_slot_count <- starters$FLEX %||% 0
  flex_need <- max(0, flex_slot_count - flex_surplus)

  picks_until_turn <- picks_until_my_turn(pick_log_state)

  # Which round the draft is in right now, for defer_until_round below. Uses
  # overall picks made, so it is correct regardless of whose slot is on the
  # clock and works before my_slot is known.
  teams <- pick_log_state$teams %||% league_config$teams
  current_round <- if (is.null(teams) || is.na(teams) || teams < 1) {
    NA_integer_
  } else {
    as.integer(ceiling((length(pick_log_state$drafted_players) + 1) / teams))
  }
  defer_until <- league_config$draft$defer_until_round %||% list()

  rows <- lapply(positions, function(p) {
    still_needed <- if (p %in% flex_positions) {
      dedicated_need[[p]] + flex_need
    } else {
      dedicated_need[[p]]
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

    # Best VOR still on the board at this position -- how much value is
    # actually at stake. Scarcity alone cannot rank positions: at pick 1 every
    # position's tier 1 holds exactly one player, so urgency and tier_supply
    # tie across RB/WR/TE/K and the sort fell through to alphabetical order,
    # which recommended a kicker first overall (reported 2026-09-06).
    vor_best <- if (nrow(live) == 0 || all(is.na(live$vor))) {
      NA_real_
    } else {
      max(live$vor, na.rm = TRUE)
    }

    # Positions the league config says to leave until late. A kicker's VOR
    # spread is real (61 points here) but it is pure efficiency noise -- and
    # ff_opportunity carries no kicker data, so K is the one position still
    # ranked on last season's ACTUAL points, which barely predict next
    # season's. Deferring is cheaper than modelling that.
    deferred <- !is.null(defer_until[[p]]) && !is.na(current_round) &&
      current_round < defer_until[[p]]

    urgency <- if (is.na(survives)) {
      NA_integer_
    } else if (deferred) {
      5L # needed eventually, but deliberately parked until its round
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
      vor_best = vor_best,
      deferred = deferred,
      # First round this position is allowed. Carried on the report so display
      # code can label a dimmed board row ("wait til rd 16") without re-reading
      # league.json and growing a second copy of the rule.
      defer_until_round = if (is.null(defer_until[[p]])) {
        NA_integer_
      } else {
        as.integer(defer_until[[p]])
      },
      urgency = urgency,
      stringsAsFactors = FALSE
    )
  })

  result <- do.call(rbind, rows)
  rownames(result) <- NULL
  result
}
