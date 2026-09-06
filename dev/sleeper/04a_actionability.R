# Actionability test: does Sleeper-informed reordering change my picks?
# Compares baseline (current ECR) vs. Sleeper-reordered ECR in a 17-round dry run.
# MY_SLOT = 5, TEAMS and ROUNDS from league_config, K defer=16, DST defer=15.

pkgload::load_all(quiet = TRUE)

store <- "_targets"
league_config <- targets::tar_read(league_config, store = store)
draft_board <- as.data.frame(targets::tar_read(draft_board, store = store))
draft_fallback <- as.data.frame(targets::tar_read(draft_fallback, store = store))

MY_SLOT <- 5
TEAMS <- league_config$teams
ROUNDS <- league_config$roster$rounds %||% 17

# Wait for input file with retries
input_path <- "dev/sleeper/cache/pool_sleeper.csv"
pool_sleeper <- NULL
for (attempt in 1:5) {
  if (file.exists(input_path)) {
    pool_sleeper <- read.csv(input_path, stringsAsFactors = FALSE)
    cat("✓ Loaded pool_sleeper.csv\n")
    break
  }
  if (attempt < 5) {
    cat("Waiting for", input_path, "... attempt", attempt, "\n")
    Sys.sleep(3)
  }
}

if (is.null(pool_sleeper)) {
  cat("ERROR: Could not load", input_path, "after retries.\n")
  cat("Expected columns: player_key, player, pos, team, ecr, ecr_source, sleeper_id, search_rank\n")
  quit(status = 1)
}

# Ensure NA handling for search_rank
pool_sleeper$search_rank <- as.numeric(pool_sleeper$search_rank)

# Helper: run full 17-round draft with supplied draft_board/fallback
# Reuses dryrun.R structure exactly
run_draft <- function(board, fallback, scenario_name) {
  scarcity_board <- scarcity_input(board, fallback)

  # Build combined pool with ECR (same as dryrun.R lines 17-19)
  pool <- combined_selectable_pool(board, fallback)
  pool$ecr <- c(board$ecr, fallback$ecr)
  pool$vor <- c(board$vor, rep(NA_real_, nrow(fallback)))

  log_path <- tempfile(fileext = ".jsonl")
  file.create(log_path)
  start_draft(log_path, TEAMS, "JGrahnasaurs", MY_SLOT)

  my_picks <- data.frame()

  cfg <- league_config
  cfg$draft$defer_until_round <- list(K = 16L, DST = 15L)

  for (n in seq_len(TEAMS * ROUNDS)) {
    state <- replay_pick_log(log_path)
    remaining <- remaining_draft_pool(pool, state)
    rnd <- ceiling(n / TEAMS)

    if (slot_on_the_clock(n, TEAMS) == MY_SLOT) {
      report <- scarcity_report(scarcity_board, state, cfg)
      rec <- recommend_picks(report,
                             remaining_draft_pool(board, state),
                             remaining_draft_pool(fallback, state))

      if (nrow(rec) == 0) {
        # No recommendation -> best bench player (VOR-ordered, deferred rows skipped)
        rb <- remaining_draft_pool(board, state)
        rb <- rb[!(rb$pos %in% names(deferred_notes(report))), ]
        rb <- rb[order(rb$vor, decreasing = TRUE), ]
        pick_key <- rb$player_key[1]
        src <- "bench"
      } else {
        # Match recommendation to remaining pool
        hit <- which(remaining$player == rec$Player[1] & remaining$pos == rec$Pos[1] &
                       remaining$team == rec$Team[1])
        if (length(hit) != 1) stop(sprintf("round %d: %s matched %d rows", rnd,
                                           rec$Player[1], length(hit)))
        pick_key <- remaining$player_key[hit]
        src <- "advised"
      }

      row <- remaining[remaining$player_key == pick_key, ]
      my_picks <- rbind(my_picks, data.frame(
        round = rnd, overall = n, player = row$player, pos = row$pos,
        team = row$team, ecr = round(row$ecr), vor = round(row$vor, 1),
        source = src, stringsAsFactors = FALSE
      ))
      team_name <- "JGrahnasaurs"
    } else {
      pick_key <- remaining$player_key[order(remaining$ecr)][1]
      team_name <- paste("Team", slot_on_the_clock(n, TEAMS))
    }

    append_pick_event(log_path, list(type = "pick_made", slot = n,
                                     team = team_name, player_key = pick_key))
  }

  list(picks = my_picks, scenario = scenario_name)
}

# Baseline: no reordering
cat("=== BASELINE (current ECR) ===\n")
baseline <- run_draft(draft_board, draft_fallback, "baseline")

# Sleeper reordering: permute ecr within TAIL + non-NA search_rank by search_rank
cat("\n=== APPLYING SLEEPER REORDERING ===\n")

# Define TAIL
sleeper_tail <- pool_sleeper$ecr_source == "overall" & pool_sleeper$ecr > 290 & !is.na(pool_sleeper$search_rank)

if (sum(sleeper_tail) > 0) {
  # Collect ecr values that belong to TAIL + non-NA search_rank
  tail_rows_idx <- which(sleeper_tail)
  tail_ecr_slots <- sort(pool_sleeper$ecr[tail_rows_idx])

  # Sort TAIL rows by search_rank ascending
  tail_by_search_rank <- pool_sleeper[tail_rows_idx, ]
  tail_by_search_rank <- tail_by_search_rank[order(tail_by_search_rank$search_rank), ]

  # New mapping: lowest search_rank gets lowest ecr slot, etc.
  tail_new_ecr <- setNames(tail_ecr_slots, tail_by_search_rank$player_key)

  # Create modified board/fallback
  board_reordered <- draft_board
  fallback_reordered <- draft_fallback

  # Update board
  board_match <- match(names(tail_new_ecr), board_reordered$player_key)
  board_match_valid <- board_match[!is.na(board_match)]
  board_reordered$ecr[board_match_valid] <- tail_new_ecr[!is.na(board_match)]

  # Update fallback
  fb_match <- match(names(tail_new_ecr), fallback_reordered$player_key)
  fb_match_valid <- fb_match[!is.na(fb_match)]
  fallback_reordered$ecr[fb_match_valid] <- tail_new_ecr[!is.na(fb_match)]

  cat("Reordered", sum(sleeper_tail), "TAIL rows by search_rank\n")

  sleeper_result <- run_draft(board_reordered, fallback_reordered, "sleeper_reordered")
} else {
  cat("No TAIL rows with non-NA search_rank found; skipping reordering\n")
  sleeper_result <- baseline
}

# Compare
cat("\n=== PICK COMPARISON ===\n")

bl_picks <- baseline$picks[, c("round", "player", "pos", "team", "ecr")]
sl_picks <- sleeper_result$picks[, c("round", "player", "pos", "team", "ecr")]

cat("\nBASELINE PICKS:\n")
print(bl_picks, row.names = FALSE)

cat("\nSLEEPER REORDERED PICKS:\n")
print(sl_picks, row.names = FALSE)

# Count differences
diffs <- bl_picks$player != sl_picks$player
n_diffs <- sum(diffs)
n_diffs_late <- sum(diffs & bl_picks$round >= 10)

cat("\n=== SUMMARY ===\n")
cat("Rounds where picked player differs:", n_diffs, "\n")
cat("Differences in rounds 10-17:", n_diffs_late, "\n")

# Starter value
starter_value <- function(picks, league_config) {
  starters_config <- league_config$roster$starters
  flex_pos <- unlist(league_config$roster$flex_eligible$FLEX)
  picks_sorted <- picks[order(picks$vor, decreasing = TRUE, na.last = TRUE), ]
  used <- rep(FALSE, nrow(picks_sorted))
  chosen <- integer(0)
  unfilled <- character(0)
  total <- 0

  for (pos_name in c("QB", "RB", "WR", "TE", "K", "DST")) {
    pos_need <- starters_config[[pos_name]] %||% 0
    pos_picks <- which(picks_sorted$pos == pos_name & !used)
    taken <- min(pos_need, length(pos_picks))
    if (taken > 0) {
      chosen <- c(chosen, pos_picks[1:taken])
      used[chosen] <- TRUE
      total <- total + sum(picks_sorted$vor[pos_picks[1:taken]], na.rm = TRUE)
    }
    unfilled_here <- max(0, pos_need - taken)
    if (unfilled_here > 0) unfilled <- c(unfilled, paste0(pos_name, "x", unfilled_here))
  }

  list(total = total, lineup = picks_sorted[chosen, ], unfilled = unfilled)
}

sv_baseline <- starter_value(baseline$picks, league_config)
sv_sleeper <- starter_value(sleeper_result$picks, league_config)

cat("\nStarter Extra pts total (baseline):", round(sv_baseline$total, 1), "\n")
cat("Starter Extra pts total (sleeper):", round(sv_sleeper$total, 1), "\n")
cat("Difference:", round(sv_sleeper$total - sv_baseline$total, 1), "\n")
