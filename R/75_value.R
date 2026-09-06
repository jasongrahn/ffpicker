#' Estimate each draft-pool player's value from real historical performance,
#' not ECR "buzz" -- ECR/ADP is used only to define the 2026 draftable
#' universe (in build_draft_pool()), never to rank players.
#'
#' value = points-per-game in the most recent season, projected to a full
#' season, discounted by a multi-year availability rate. This rewards
#' per-game production while penalizing a real injury history -- a player who
#' was excellent for 8 games and hurt for 9 should not simply outrank a
#' healthy compiler because a raw season total already got "spent" evenly by
#' a coincidence of health.
#'
#' Players with no games in `current_season` (rookies, missed the entire
#' season) get `projected_points = NA` and `has_current_data = FALSE` rather
#' than a silently guessed value -- full projection modeling (draft capital as
#' the rookie prior) is Phase 4, not this.
#'
#' @param fct_player_week_scored data.table from add_fantasy_points().
#' @param draft_pool data.table from build_draft_pool().
#' @param current_season Season to base points-per-game on.
#' @param availability_seasons Seasons spanned by the availability-rate lookback.
#' @return `draft_pool` with added columns: ppg_current, availability_rate,
#'   projected_points, has_current_data.
build_player_value <- function(fct_player_week_scored, draft_pool,
                                current_season = 2025,
                                availability_seasons = 2023:2025) {
  fpws <- fct_player_week_scored[fct_player_week_scored$season_type == "REG", ]

  # aggregate() errors on a zero-row input rather than returning an empty
  # result, which happens for real when no draft-pool player has any games in
  # `current_season` yet (e.g. testing against a season that hasn't started).
  empty_stats <- function(cols) setNames(data.frame(matrix(nrow = 0, ncol = length(cols))), cols)

  cur <- fpws[fpws$season == current_season, ]
  if (nrow(cur) == 0) {
    cur_stats <- empty_stats(c("player_key", "games_current", "ppg_current"))
  } else {
    cur_points <- aggregate(fantasy_points ~ player_key, data = cur, FUN = sum)
    cur_games <- aggregate(fantasy_points ~ player_key, data = cur, FUN = length)
    names(cur_games)[2] <- "games_current"
    cur_stats <- merge(cur_points, cur_games, by = "player_key")
    cur_stats$ppg_current <- cur_stats$fantasy_points / cur_stats$games_current
    cur_stats$fantasy_points <- NULL
  }

  avail <- fpws[fpws$season %in% availability_seasons, ]
  if (nrow(avail) == 0) {
    avail_stats <- empty_stats(c("player_key", "availability_rate"))
  } else {
    games_played <- aggregate(week ~ player_key, data = avail, FUN = length)
    names(games_played)[2] <- "games_played_window"
    active_seasons <- aggregate(season ~ player_key, data = avail, FUN = function(s) length(unique(s)))
    names(active_seasons)[2] <- "active_seasons_window"
    avail_stats <- merge(games_played, active_seasons, by = "player_key")
    # denominator uses the player's own active tenure within the window (17
    # games per active season), not a fixed 3-season span, so a player who
    # entered the league in the middle of the window isn't penalized for games
    # that happened before he existed in the NFL.
    avail_stats$availability_rate <- avail_stats$games_played_window / (avail_stats$active_seasons_window * 17)
  }

  value <- merge(draft_pool, cur_stats[, c("player_key", "ppg_current", "games_current")],
                 by = "player_key", all.x = TRUE)
  value <- merge(value, avail_stats[, c("player_key", "availability_rate")],
                 by = "player_key", all.x = TRUE)

  value$has_current_data <- !is.na(value$ppg_current)
  availability <- ifelse(is.na(value$availability_rate), 1, value$availability_rate)
  value$projected_points <- ifelse(value$has_current_data, value$ppg_current * 17 * availability, NA)

  value
}

#' Compute Value Over Replacement for each player in a valued draft pool.
#'
#' Replacement level is dynamic, driven entirely by league_config (teams,
#' roster starters, flex eligibility) -- never hardcoded.
#'
#' Flex-eligible positions (RB/WR/TE by default) share one combined
#' replacement level: their starter slots plus the shared FLEX slots are
#' pooled and ranked together, since a real snake draft treats a shallow WR3
#' and a shallow RB3 as roughly interchangeable once FLEX is in play. This is
#' a deliberate v0 approximation (a true assignment-problem solver is L6, out
#' of scope here) -- positions with no flex competition (QB, K) get their own
#' dedicated replacement level.
#'
#' @param value_table data.table from build_player_value().
#' @param league_config Parsed league config (list), e.g. load_config("league").
#' @return `value_table`, restricted to rows with current-season data, with
#'   added columns: replacement_value, vor.
compute_vor <- function(value_table, league_config) {
  teams <- league_config$teams
  starters <- league_config$roster$starters
  flex_positions <- unlist(league_config$roster$flex_eligible$FLEX)

  vt <- value_table[value_table$has_current_data, ]
  all_positions <- unique(vt$pos)
  non_flex_positions <- setdiff(all_positions, flex_positions)

  replacement_value <- setNames(numeric(0), character(0))

  for (p in non_flex_positions) {
    n_starters <- starters[[p]]
    if (is.null(n_starters)) n_starters <- 0
    replacement_rank <- teams * n_starters
    ranked <- sort(vt$projected_points[vt$pos == p], decreasing = TRUE)
    replacement_value[p] <- if (replacement_rank < length(ranked)) {
      ranked[replacement_rank + 1]
    } else {
      min(ranked, na.rm = TRUE)
    }
  }

  if (length(flex_positions) > 0 && any(vt$pos %in% flex_positions)) {
    flex_starter_slots <- sum(vapply(flex_positions, function(p) starters[[p]] %||% 0, numeric(1)))
    flex_slots_total <- teams * (flex_starter_slots + (starters$FLEX %||% 0))
    flex_ranked <- sort(vt$projected_points[vt$pos %in% flex_positions], decreasing = TRUE)
    flex_replacement <- if (flex_slots_total < length(flex_ranked)) {
      flex_ranked[flex_slots_total + 1]
    } else {
      min(flex_ranked, na.rm = TRUE)
    }
    for (p in flex_positions) replacement_value[p] <- flex_replacement
  }

  vt$replacement_value <- replacement_value[vt$pos]
  vt$vor <- vt$projected_points - vt$replacement_value
  vt
}

#' Assign gap-based tiers within each position, from a VOR table.
#'
#' A new tier starts where the drop to the next-ranked player exceeds
#' `gap_multiplier` times that position's own VOR standard deviation, rather
#' than at a fixed rank or fixed VOR gap -- a flat cut can split a genuinely
#' tight cluster or hide a real cliff, and RB/WR/QB/K all sit on different VOR
#' scales so one absolute number can't work across positions.
#'
#' @param vor_table data.table from compute_vor().
#' @param gap_multiplier Number of within-position VOR standard deviations a
#'   drop must exceed to start a new tier.
#' @return `vor_table`, ordered by pos then descending vor, with an added
#'   integer `tier` column (1 = best tier), restarting at 1 for each position.
assign_tiers <- function(vor_table, gap_multiplier = 1) {
  result <- do.call(rbind, lapply(split(vor_table, vor_table$pos), function(vt) {
    vt <- vt[order(vt$vor, decreasing = TRUE), ]
    gaps <- -diff(vt$vor)
    threshold <- gap_multiplier * sd(vt$vor)
    vt$tier <- cumsum(c(1, gaps > threshold))
    vt
  }))
  rownames(result) <- NULL
  result
}

#' Build the un-tiered, ECR-sorted fallback section for Draft Pool players
#' with no current-season data (mostly rookies) -- see build_player_value().
#' These have an ECR but no VOR, so they're excluded from compute_vor()
#' entirely; this surfaces them separately rather than dropping them.
#'
#' @param value_table data.table from build_player_value().
#' @return `value_table`, restricted to has_current_data == FALSE rows,
#'   ordered by ascending ecr.
build_fallback_board <- function(value_table) {
  fb <- value_table[!value_table$has_current_data, ]
  fb[order(fb$ecr), ]
}

#' Validate the VOR table: every row must have a finite VOR, and player_key
#' must be unique -- a bad replacement-level lookup should never reach the
#' draft board silently.
#'
#' @param vor_table data.table from compute_vor().
validate_vor_table <- function(vor_table) {
  agent <- pointblank::create_agent(vor_table) |>
    pointblank::col_vals_not_null(pointblank::vars(vor, replacement_value)) |>
    pointblank::rows_distinct(pointblank::vars(player_key)) |>
    pointblank::interrogate()

  if (!pointblank::all_passed(agent)) {
    stop("vor_table failed validation:\n", paste(capture.output(print(agent)), collapse = "\n"))
  }
  invisible(vor_table)
}
