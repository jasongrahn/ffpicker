#!/usr/bin/env Rscript
#
# Experiment A, supplementary: is the tau=3 A2 loss a single-draw artifact?
#
# dev/bars_a.R ran ONE noise seed per tau (seed = tau + 1, frozen from handoff
# #19). That is the pre-registered bar and its verdict stands: A2 FAILED.
# This script does not re-run the bar. It estimates the effect size the bar was
# reading off one draw of.
#
# Design: 30 seeds per tau. Common random numbers -- both arms get the SAME
# noise matrix within a seed, so the paired delta removes draft-to-draft
# variance and measures the arm difference only.
#
# Read (pre-registered BEFORE running, see session transcript):
#   artifact  -- tau=3 CI contains 0, or sits above it
#   real loss -- tau=3 CI sits entirely below 0
# Neither outcome changes the A2 FAIL.
#
# Run: Rscript dev/bars_a_seeds.R

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
N_SEEDS <- 30

# --- harness self-check: the CI must be able to say "below zero" ------------
chk_pos <- paired_bootstrap_ci(rep(5, N_SEEDS))
chk_neg <- paired_bootstrap_ci(rep(-5, N_SEEDS))
if (!(chk_pos$lo > 0)) stop("harness broken: constant +5 delta did not give CI above 0")
if (!(chk_neg$hi < 0)) stop("harness broken: constant -5 delta did not give CI below 0")
cat("harness self-check OK (CI resolves both signs)\n\n")

cat(sprintf("=== Experiment A supplementary — %d seeds per tau ===\n\n", N_SEEDS))

rows <- list()
raw <- list()

for (tau in taus) {
  deltas <- numeric(N_SEEDS)
  unfilled_any <- FALSE

  for (s in seq_len(N_SEEDS)) {
    noise <- sim_noise(nrow(ctx$pool), TEAMS * ROUNDS, seed = 10000L + tau * 100L + s)
    rec <- simulate_draft(ctx, league_config, my_slot = MY_SLOT, defer = DEFER,
                          tau = tau, noise = noise, my_rule = "recommend")
    fil <- simulate_draft(ctx, league_config, my_slot = MY_SLOT, defer = DEFER,
                          tau = tau, noise = noise, my_rule = "vona_fill")
    sv_rec <- starter_value(rec$picks, league_config)
    sv_fil <- starter_value(fil$picks, league_config)
    if (length(sv_fil$unfilled) > 0) unfilled_any <- TRUE
    deltas[s] <- sv_fil$total - sv_rec$total
  }

  ci <- paired_bootstrap_ci(deltas)
  verdict <- if (ci$lo > 0) "fill WINS" else if (ci$hi < 0) "fill LOSES" else "indistinguishable"

  rows[[length(rows) + 1]] <- data.frame(
    tau = tau, mean = ci$mean, lo = ci$lo, hi = ci$hi,
    sd = sd(deltas), win_rate = mean(deltas >= 0),
    verdict = verdict, a1_ok = !unfilled_any, stringsAsFactors = FALSE
  )
  raw[[as.character(tau)]] <- deltas

  cat(sprintf("tau %-3g  mean %+8.1f  95%% CI [%+7.1f, %+7.1f]  sd %6.1f  win %3.0f%%  %-18s A1 %s\n",
              tau, ci$mean, ci$lo, ci$hi, sd(deltas), 100 * mean(deltas >= 0),
              verdict, if (unfilled_any) "FAIL" else "ok"))
}

results <- do.call(rbind, rows)
saveRDS(list(summary = results, deltas = raw), "dev/bars_a_seeds.rds")

cat("\nPre-registered A2 verdict (single frozen seed per tau) remains FAIL.\n")
cat("This table estimates effect size only; it does not re-run the bar.\n")
