#!/usr/bin/env Rscript
#
# Mutation test for dev/bars_a.R. A gate that cannot fail is not a gate.
# Runs the same two bar checks against arms whose answers are known in advance:
#
#   M1  fill arm replaced by unconstrained "vona"  -> A1 MUST fail (that arm is
#       the one handoff #19 measured drafting zero K and zero DST).
#   M2  fill arm replaced by "recommend"           -> A1 and A2 MUST both pass,
#       with delta exactly 0 (arm compared against itself).
#   M3  M2's totals, each docked 0.1 pt            -> A2 MUST fail (proves the
#       >= comparison is live and not stuck on TRUE).
#
# Run: Rscript dev/bars_a_mutation.R

pkgload::load_all(quiet = TRUE)

store <- "_targets"
league_config <- targets::tar_read(league_config, store = store)
ctx <- sim_context(as.data.frame(targets::tar_read(draft_board, store = store)),
                   as.data.frame(targets::tar_read(draft_fallback, store = store)))

MY_SLOT <- 5
TEAMS <- league_config$teams
ROUNDS <- league_config$roster$rounds %||% 17
DEFER <- list(K = 16, DST = 15)
taus <- c(0, 3, 6, 12)

# Same bar logic as dev/bars_a.R, parameterised on the arm under test and on a
# handicap applied to that arm's total.
run_bars <- function(arm_rule, handicap = 0) {
  a1 <- TRUE; a2 <- TRUE; unf_seen <- character(0)
  for (tau in taus) {
    noise <- sim_noise(nrow(ctx$pool), TEAMS * ROUNDS, seed = tau + 1)
    rec <- simulate_draft(ctx, league_config, my_slot = MY_SLOT, defer = DEFER,
                          tau = tau, noise = noise, my_rule = "recommend")
    arm <- simulate_draft(ctx, league_config, my_slot = MY_SLOT, defer = DEFER,
                          tau = tau, noise = noise, my_rule = arm_rule)
    sv_rec <- starter_value(rec$picks, league_config)
    sv_arm <- starter_value(arm$picks, league_config)
    if (length(sv_arm$unfilled) > 0) {
      a1 <- FALSE
      unf_seen <- union(unf_seen, sv_arm$unfilled)
    }
    if ((sv_arm$total - handicap) < sv_rec$total) a2 <- FALSE
  }
  list(a1 = a1, a2 = a2, unfilled = unf_seen)
}

cat("=== Mutation test: dev/bars_a.R ===\n\n")
ok <- TRUE

m1 <- run_bars("vona")
cat(sprintf("M1  arm='vona'      A1=%s  A2=%s   unfilled seen: %s\n",
            m1$a1, m1$a2, paste(m1$unfilled, collapse = ", ")))
if (m1$a1) { cat("    MUTATION SURVIVED — A1 passed an arm that leaves slots empty\n"); ok <- FALSE }

m2 <- run_bars("recommend")
cat(sprintf("M2  arm='recommend' A1=%s  A2=%s\n", m2$a1, m2$a2))
if (!m2$a1 || !m2$a2) { cat("    MUTATION SURVIVED — self-comparison did not pass\n"); ok <- FALSE }

m3 <- run_bars("recommend", handicap = 0.1)
cat(sprintf("M3  arm='recommend' docked 0.1  A2=%s\n", m3$a2))
if (m3$a2) { cat("    MUTATION SURVIVED — A2 passed a strictly worse arm\n"); ok <- FALSE }

cat("\n")
if (ok) cat("=== MUTATION TEST OK — both bars can fail ===\n") else stop("MUTATION TEST FAILED")
