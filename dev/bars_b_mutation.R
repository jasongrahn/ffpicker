#!/usr/bin/env Rscript
#
# Bar B5. Mutation test for dev/bars_b.R. A gate that cannot fail is not a gate.
#
#   M1  tiebreak_sign = -1 (worst-first within the target position)
#       -> B4 MUST see >= 3 changed picks. This is the load-bearing test: if
#          negating the ranking key changes nothing, the tiebreak branch is dead
#          code and every other B number is meaningless.
#   M2  arm replaced by "recommend" (self-compare)
#       -> 0 changed, delta exactly 0, B1 passes.
#   M3  M2's totals docked 0.1 pt
#       -> the >= comparison MUST fail, proving it is live.
#
# Run: Rscript dev/bars_b_mutation.R

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

run_bars <- function(arm_rule, sign = 1, handicap = 0) {
  b1 <- TRUE; ge <- TRUE; changed_all <- integer(0); unf_seen <- character(0)
  for (tau in taus) {
    noise <- sim_noise(nrow(ctx$pool), TEAMS * ROUNDS, seed = tau + 1)
    rec <- simulate_draft(ctx, league_config, my_slot = MY_SLOT, defer = DEFER,
                          tau = tau, noise = noise, my_rule = "recommend")
    arm <- simulate_draft(ctx, league_config, my_slot = MY_SLOT, defer = DEFER,
                          tau = tau, noise = noise, my_rule = arm_rule,
                          tiebreak_sign = sign)
    sv_rec <- starter_value(rec$picks, league_config)
    sv_arm <- starter_value(arm$picks, league_config)
    if (length(sv_arm$unfilled) > 0) { b1 <- FALSE; unf_seen <- union(unf_seen, sv_arm$unfilled) }
    if ((sv_arm$total - handicap) < sv_rec$total) ge <- FALSE
    changed_all <- c(changed_all, sum(rec$picks$player != arm$picks$player))
  }
  list(b1 = b1, ge = ge, changed = changed_all, unfilled = unf_seen)
}

cat("=== Mutation test: dev/bars_b.R ===\n\n")
ok <- TRUE

m1 <- run_bars("vona_tiebreak", sign = -1)
cat(sprintf("M1  arm='vona_tiebreak' sign=-1   changed per tau: %s\n",
            paste(m1$changed, collapse = ", ")))
if (all(m1$changed < 3)) {
  cat("    MUTATION SURVIVED — negating the tiebreak key changed <3 picks at every tau;\n")
  cat("    the branch is dead or the pick-diff count cannot see it.\n"); ok <- FALSE
} else {
  cat("    killed — pick-diff count detects a live tiebreak.\n")
}

m2 <- run_bars("recommend")
cat(sprintf("M2  arm='recommend'  B1=%s  >=cmp=%s  changed: %s\n",
            m2$b1, m2$ge, paste(m2$changed, collapse = ", ")))
if (!m2$b1 || !m2$ge || any(m2$changed != 0)) {
  cat("    MUTATION SURVIVED — self-comparison did not come back identical\n"); ok <- FALSE
}

m3 <- run_bars("recommend", handicap = 0.1)
cat(sprintf("M3  arm='recommend' docked 0.1    >=cmp=%s\n", m3$ge))
if (m3$ge) { cat("    MUTATION SURVIVED — >= passed a strictly worse arm\n"); ok <- FALSE }

cat("\n")
if (ok) cat("=== MUTATION TEST OK — B's bars can fail ===\n") else stop("MUTATION TEST FAILED")
