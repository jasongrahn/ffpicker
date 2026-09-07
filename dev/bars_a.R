#!/usr/bin/env Rscript
#
# Experiment A bars: my_rule = "vona_fill" (VONA + mandatory-starter-fill
# constraint) vs the current recommend_picks() arm.
#
# Pre-registered in docs/handoff/ffdraft-handoff-20260907-12.md:
#   A1. Zero unfilled starter slots, every tau.
#   A2. Starters >= current recommend_picks() arm at EVERY tau.
#   A3. Golden still 3/3 (run dev/mc_golden.R; my_rule = "recommend" untouched).
#
# Settings frozen from handoff #19's bar run -- slot 5, baseline deferral,
# taus 0/3/6/12, noise seed tau+1. Do not tune them.
#
# Run: Rscript dev/bars_a.R

pkgload::load_all(quiet = TRUE)

cat("=== Experiment A — bars A1 + A2 ===\n\n")

store <- "_targets"
league_config <- targets::tar_read(league_config, store = store)
draft_board <- as.data.frame(targets::tar_read(draft_board, store = store))
draft_fallback <- as.data.frame(targets::tar_read(draft_fallback, store = store))

ctx <- sim_context(draft_board, draft_fallback)

MY_SLOT <- 5
TEAMS <- league_config$teams
ROUNDS <- league_config$roster$rounds %||% 17
DEFER <- list(K = 16, DST = 15)
taus <- c(0, 3, 6, 12)

a1_pass <- TRUE
a2_pass <- TRUE
rows <- list()

cat(sprintf("%-6s %-8s %-10s %-10s %-9s %-22s\n",
            "tau", "changed", "recommend", "vona_fill", "delta", "unfilled (fill arm)"))
cat(paste(rep("-", 74), collapse = ""), "\n")

for (tau in taus) {
  noise_matrix <- sim_noise(nrow(ctx$pool), TEAMS * ROUNDS, seed = tau + 1)

  sim_rec <- simulate_draft(ctx, league_config, my_slot = MY_SLOT, defer = DEFER,
                            tau = tau, noise = noise_matrix, my_rule = "recommend")
  sim_fill <- simulate_draft(ctx, league_config, my_slot = MY_SLOT, defer = DEFER,
                             tau = tau, noise = noise_matrix, my_rule = "vona_fill")

  sv_rec <- starter_value(sim_rec$picks, league_config)
  sv_fill <- starter_value(sim_fill$picks, league_config)

  changed <- sum(sim_rec$picks$player != sim_fill$picks$player)
  delta <- sv_fill$total - sv_rec$total
  unf <- if (length(sv_fill$unfilled) == 0) "none" else paste(sv_fill$unfilled, collapse = ", ")

  cat(sprintf("%-6g %-8d %-10.1f %-10.1f %-+9.1f %-22s\n",
              tau, changed, sv_rec$total, sv_fill$total, delta, unf))

  if (length(sv_fill$unfilled) > 0) a1_pass <- FALSE
  if (sv_fill$total < sv_rec$total) a2_pass <- FALSE

  rows[[length(rows) + 1]] <- data.frame(
    tau = tau, changed = changed, recommend = sv_rec$total,
    vona_fill = sv_fill$total, delta = delta, unfilled = unf,
    stringsAsFactors = FALSE
  )
}

results <- do.call(rbind, rows)
saveRDS(results, "dev/bars_a_results.rds")

cat("\n")
cat(sprintf("A1 (zero unfilled starter slots, every tau): %s\n", if (a1_pass) "PASS" else "FAIL"))
cat(sprintf("A2 (starters >= recommend, every tau):       %s\n", if (a2_pass) "PASS" else "FAIL"))
cat("A3 (golden 3/3): run dev/mc_golden.R separately.\n\n")

if (a1_pass && a2_pass) {
  cat("=== EXPERIMENT A: A1 + A2 PASS ===\n")
} else {
  cat("=== EXPERIMENT A: FAIL ===\n")
}
