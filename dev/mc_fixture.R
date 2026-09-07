#!/usr/bin/env Rscript
#
# Generate test fixture snapshot dryrun_tau0_fixture.rds from tau=0 deterministic
# run against fixture data. Used by test-opponent-sim.R to verify simulate_draft().
#
# Run: cd /Users/jasongrahn/R-projects/ffootballer && Rscript dev/mc_fixture.R

pkgload::load_all(quiet = TRUE)

cat("=== Fixture Generator ===\n\n")

# Load fixture from tests/testthat
pool_path <- "tests/testthat/fixtures/mc_pool.csv"
fixture_pool <- read.csv(pool_path, stringsAsFactors = FALSE)

# Separate into board (has tier) and fallback (no tier)
fixture_board <- fixture_pool[!is.na(fixture_pool$tier), ]
fixture_fallback <- fixture_pool[is.na(fixture_pool$tier), ]

# Fallback should not have tier or vor columns
fixture_fallback <- fixture_fallback[, !(names(fixture_fallback) %in% c("tier", "vor"))]

# Read fixture league
league_path <- "tests/testthat/fixtures/mc_league.json"
fixture_league <- jsonlite::read_json(league_path)

# Build sim_context
ctx <- sim_context(fixture_board, fixture_league)

# Run tau=0 draft
got <- simulate_draft(ctx, fixture_league, my_slot = 2, defer = list(), tau = 0)

cat("Generated fixture snapshot:\n")
print(got$picks, row.names = FALSE)

# Save golden fixture
fixture_path <- "tests/testthat/fixtures/dryrun_tau0_fixture.rds"
saveRDS(got$picks, fixture_path)
cat("\nSaved to: ", fixture_path, "\n", sep = "")
