#!/usr/bin/env Rscript
#
# VONA gate: Step 9 part 1, latency measurement.
# Measure simulate_forward() at worst-case horizons (9, 11, 19).
# Bar 3: all cells in horizon x tau grid must run in < 2.0 seconds at n_sims=1000.

pkgload::load_all(quiet = TRUE)

cat("=== VONA Gate — Latency Measurement (Step 9, Part 1) ===\n\n")

# Load real data to build a realistic mid-draft state
store <- "_targets"
league_config <- targets::tar_read(league_config, store = store)
draft_board <- as.data.frame(targets::tar_read(draft_board, store = store))
draft_fallback <- as.data.frame(targets::tar_read(draft_fallback, store = store))

ctx <- sim_context(draft_board, draft_fallback)
TEAMS <- league_config$teams
pool <- ctx$pool

# Build base state from 40-pick log (provides a real draft context)
log_path <- tempfile(fileext = ".jsonl")
file.create(log_path)
start_draft(log_path, TEAMS, "TestTeam", 5)

for (pick_num in 1:40) {
  state <- replay_pick_log(log_path)
  remaining <- remaining_draft_pool(pool, state)
  pick_idx <- order(remaining$xrank)[1]
  pick_key <- remaining$player_key[pick_idx]
  team_slot <- slot_on_the_clock(pick_num, TEAMS)
  append_pick_event(log_path, list(
    type = "pick_made", slot = pick_num,
    team = paste("Team", team_slot), player_key = pick_key
  ))
}

state <- replay_pick_log(log_path)

# Sweep worst-case horizons (9, 11, 19) x taus (0, 3, 6, 12)
cat(sprintf("%-10s %-10s %-15s\n", "horizon", "tau", "elapsed_sec"))
cat(paste(rep("-", 40), collapse = ""), "\n")

horizons <- c(9, 11, 19)
taus <- c(0, 3, 6, 12)

latency_grid <- data.frame(horizon = integer(), tau = integer(), elapsed_sec = numeric(), stringsAsFactors = FALSE)
all_pass <- TRUE

for (h in horizons) {
  for (tau in taus) {
    result <- simulate_forward(ctx, state, horizon = h, tau = tau, n_sims = 1000, seed = 1)
    elapsed <- result$elapsed_sec

    cat(sprintf("%-10d %-10d %15.2f\n", h, tau, elapsed))

    latency_grid <- rbind(latency_grid, data.frame(horizon = h, tau = tau, elapsed_sec = elapsed))

    if (elapsed >= 2.0) {
      all_pass <- FALSE
    }
  }
}

cat("\n")
if (all_pass) {
  max_elapsed <- max(latency_grid$elapsed_sec)
  cat(sprintf("=== LATENCY PASS — max %.2f seconds (all < 2.0) ===\n", max_elapsed))
} else {
  max_elapsed <- max(latency_grid$elapsed_sec)
  cat(sprintf("=== LATENCY FAIL — max %.2f seconds ===\n", max_elapsed))
}
