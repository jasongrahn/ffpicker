#!/usr/bin/env Rscript
#
# Golden gate: verify simulate_draft(tau=0) matches dev/dryrun.R exactly
# on real 764-row pool across all three deferral scenarios.
#
# Run: cd /Users/jasongrahn/R-projects/ffootballer && Rscript dev/mc_golden.R

pkgload::load_all(quiet = TRUE)

cat("=== MC Golden Gate (dryrun.R anchoring) ===\n\n")

# Step 1: Build ctx from real _targets store
cat("Step 1: Loading real data from _targets store...\n")
store <- "_targets"
league_config <- targets::tar_read(league_config, store = store)
draft_board <- as.data.frame(targets::tar_read(draft_board, store = store))
draft_fallback <- as.data.frame(targets::tar_read(draft_fallback, store = store))

cat("  League config: teams=", league_config$teams, ", rounds=", league_config$roster$rounds, "\n", sep = "")
cat("  Draft board: ", nrow(draft_board), " rows\n", sep = "")
cat("  Draft fallback: ", nrow(draft_fallback), " rows\n", sep = "")

ctx <- sim_context(draft_board, draft_fallback)
cat("  sim_context built: pool=", nrow(ctx$pool), " rows\n", sep = "")

# Step 2: Load dev/dryrun.R environment
cat("\nStep 2: Loading dev/dryrun.R...\n")
env <- new.env()
capture.output(sys.source("dev/dryrun.R", env))
cat("  dryrun.R environment loaded\n")

# Step 3: Compare on all three scenarios
cat("\nStep 3: Verifying tau=0 against dryrun.R scenarios...\n\n")

MY_SLOT <- 5  # Must match dryrun.R's MY_SLOT
scenarios <- list(
  "baseline (K16, DST15)" = list(K = 16, DST = 15),
  "QB deferred to rd 7"   = list(K = 16, DST = 15, QB = 7),
  "QB deferred to rd 8"   = list(K = 16, DST = 15, QB = 8)
)

all_pass <- TRUE

for (scen_name in names(scenarios)) {
  scen <- scenarios[[scen_name]]
  cat(sprintf("  Scenario: %s\n", scen_name))

  # Get dryrun reference
  ref <- env$run_draft(scen)

  # Get simulate_draft result
  tryCatch({
    sim <- simulate_draft(ctx, league_config, my_slot = MY_SLOT, defer = scen, tau = 0)
  }, error = function(e) {
    cat("    ERROR: simulate_draft() failed:", e$message, "\n")
    all_pass <<- FALSE
    return()
  })

  # Compare picks
  if (!identical(sim$picks, ref$picks)) {
    cat("    FAIL: picks differ\n")
    cat("    Expected:\n")
    print(head(ref$picks, 3))
    cat("    Got:\n")
    print(head(sim$picks, 3))
    all_pass <- FALSE
  }

  # Compare advice
  if (!identical(sim$advice, ref$advice)) {
    cat("    FAIL: advice differs\n")
    cat("    Expected:", ref$advice[1], "\n")
    cat("    Got:     ", sim$advice[1], "\n")
    all_pass <- FALSE
  }

  # Compare starter values
  ref_sv <- env$starter_value(ref$picks)$total
  sim_sv <- starter_value(sim$picks, league_config)$total
  if (!isTRUE(all.equal(sim_sv, ref_sv))) {
    cat("    FAIL: starter_value differs\n")
    cat("    Expected:", ref_sv, "\n")
    cat("    Got:     ", sim_sv, "\n")
    all_pass <- FALSE
  }

  if (all_pass) {
    cat("    PASS\n")
  }
}

cat("\n")
if (all_pass) {
  cat("=== GOLDEN OK — 3/3 scenarios identical ===\n")
} else {
  stop("GOLDEN FAIL — one or more scenarios differ from dryrun.R")
}
