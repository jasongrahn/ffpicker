#!/usr/bin/env Rscript
#
# Step 11 bars test: Compare recommend vs vona rule across taus.
# Bar 1: >= 3 of 17 picks differ between arms.
# Bar 2: starter_value total vona >= recommend at EVERY tau.

pkgload::load_all(quiet = TRUE)

cat("=== Step 11 — Bars 1 and 2 ===\n\n")

# Load real data
store <- "_targets"
league_config <- targets::tar_read(league_config, store = store)
draft_board <- as.data.frame(targets::tar_read(draft_board, store = store))
draft_fallback <- as.data.frame(targets::tar_read(draft_fallback, store = store))

ctx <- sim_context(draft_board, draft_fallback)
MY_SLOT <- 5
TEAMS <- league_config$teams
ROUNDS <- league_config$roster$rounds %||% 17

# Scenarios
scenarios <- list(
  "baseline (K16, DST15)" = list(K = 16, DST = 15),
  "QB deferred to rd 7"   = list(K = 16, DST = 15, QB = 7),
  "QB deferred to rd 8"   = list(K = 16, DST = 15, QB = 8)
)

# Test each tau with both arms
taus <- c(0, 3, 6, 12)
bar1_pass <- TRUE
bar2_pass <- TRUE

cat(sprintf("%-10s %-15s %-15s %-15s %-15s\n", "tau", "picks_changed", "starters_recommend", "starters_vona", "delta"))
cat(paste(rep("-", 70), collapse = ""), "\n")

for (tau in taus) {
  # Generate one noise matrix for this tau
  noise_matrix <- sim_noise(nrow(ctx$pool), TEAMS * ROUNDS, seed = tau + 1)

  # Run recommend arm
  sim_recommend <- simulate_draft(ctx, league_config, my_slot = MY_SLOT, defer = scenarios[["baseline (K16, DST15)"]],
                                  tau = tau, noise = noise_matrix, my_rule = "recommend")

  # Run vona arm
  sim_vona <- simulate_draft(ctx, league_config, my_slot = MY_SLOT, defer = scenarios[["baseline (K16, DST15)"]],
                            tau = tau, noise = noise_matrix, my_rule = "vona")

  # Bar 1: Count picks that differ
  picks_differ <- sum(sim_recommend$picks$player != sim_vona$picks$player)

  # Bar 2: Compare starter values
  sv_recommend <- starter_value(sim_recommend$picks, league_config)
  sv_vona <- starter_value(sim_vona$picks, league_config)

  delta <- sv_vona$total - sv_recommend$total

  cat(sprintf("%-10d %-15d %-15.1f %-15.1f %-15.1f\n", tau, picks_differ, sv_recommend$total, sv_vona$total, delta))

  if (picks_differ < 3) {
    bar1_pass <- FALSE
  }
  if (sv_vona$total < sv_recommend$total) {
    bar2_pass <- FALSE
  }
}

cat("\n")
if (bar1_pass && bar2_pass) {
  cat("=== BARS PASS ===\n")
} else if (!bar1_pass) {
  cat("=== BAR 1 FAIL — deterministic model good enough, ship nothing ===\n")
} else {
  cat("=== BAR 2 FAIL — reordering costs points, REJECT ===\n")
}
