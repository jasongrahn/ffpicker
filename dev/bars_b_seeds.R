#!/usr/bin/env Rscript
#
# Bar B2: paired bootstrap CI lower bound >= 0 at every tau, 30 seeds, CRN.
# Pre-registered in dev/PREREG_B.md. Seed formula and count copied unchanged
# from Experiment A (dev/bars_a_seeds.R): 10000 + tau*100 + s. Not tunable.
#
# Both arms get the SAME noise matrix within a seed, so the paired delta
# removes draft-to-draft variance and measures the arm difference only.
#
# Also tallies the instrumentation across all 120 drafts: how often the
# within-position VONA argmax differs from the VOR argmax.
#
# Run: Rscript dev/bars_b_seeds.R

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

# --- harness self-check: the CI must be able to resolve both signs ----------
# A CI of [0, 0] is the expected result here, and that is exactly the shape a
# broken CI would also produce. Prove it is not broken before reading it.
chk_pos <- paired_bootstrap_ci(rep(5, N_SEEDS))
chk_neg <- paired_bootstrap_ci(rep(-5, N_SEEDS))
if (!(chk_pos$lo > 0)) stop("harness broken: constant +5 delta did not give CI above 0")
if (!(chk_neg$hi < 0)) stop("harness broken: constant -5 delta did not give CI below 0")
cat("harness self-check OK (CI resolves both signs)\n\n")

cat(sprintf("=== Experiment B bar B2 — %d seeds per tau ===\n\n", N_SEEDS))

rows <- list()
raw <- list()
tb_same <- 0L; tb_tot <- 0L; changed_tot <- 0L

for (tau in taus) {
  deltas <- numeric(N_SEEDS)
  unfilled_any <- FALSE

  for (s in seq_len(N_SEEDS)) {
    noise <- sim_noise(nrow(ctx$pool), TEAMS * ROUNDS, seed = 10000L + tau * 100L + s)
    rec <- simulate_draft(ctx, league_config, my_slot = MY_SLOT, defer = DEFER,
                          tau = tau, noise = noise, my_rule = "recommend")
    tb  <- simulate_draft(ctx, league_config, my_slot = MY_SLOT, defer = DEFER,
                          tau = tau, noise = noise, my_rule = "vona_tiebreak")
    sv_rec <- starter_value(rec$picks, league_config)
    sv_tb  <- starter_value(tb$picks, league_config)
    if (length(sv_tb$unfilled) > 0) unfilled_any <- TRUE
    deltas[s] <- sv_tb$total - sv_rec$total
    changed_tot <- changed_tot + sum(rec$picks$player != tb$picks$player)
    if (!is.null(tb$tb_log)) {
      tb_tot <- tb_tot + nrow(tb$tb_log)
      tb_same <- tb_same + sum(tb$tb_log$same)
    }
  }

  ci <- paired_bootstrap_ci(deltas)
  verdict <- if (ci$lo > 0) "tiebreak WINS" else if (ci$hi < 0) "tiebreak LOSES" else "indistinguishable"

  rows[[length(rows) + 1]] <- data.frame(
    tau = tau, mean = ci$mean, lo = ci$lo, hi = ci$hi, sd = sd(deltas),
    win_rate = mean(deltas >= 0), verdict = verdict, b1_ok = !unfilled_any,
    stringsAsFactors = FALSE)
  raw[[as.character(tau)]] <- deltas

  cat(sprintf("tau %-3g  mean %+8.1f  95%% CI [%+7.1f, %+7.1f]  sd %6.1f  win %3.0f%%  %-18s B1 %s\n",
              tau, ci$mean, ci$lo, ci$hi, sd(deltas), 100 * mean(deltas >= 0),
              verdict, if (unfilled_any) "FAIL" else "ok"))
}

results <- do.call(rbind, rows)
saveRDS(list(summary = results, deltas = raw), "dev/bars_b_seeds.rds")

b2_pass <- all(results$lo >= 0)
cat(sprintf("\nB2 (paired CI lo >= 0 at every tau): %s\n", if (b2_pass) "PASS" else "FAIL"))
cat(sprintf("\nAcross all %d drafts: picks changed vs recommend = %d\n",
            length(taus) * N_SEEDS, changed_tot))
cat(sprintf("Tiebreak-routed picks: %d, of which VONA argmax == VOR argmax: %d (%.1f%%)\n",
            tb_tot, tb_same, 100 * tb_same / max(tb_tot, 1)))
if (b2_pass && changed_tot == 0) {
  cat("\nB2 passes VACUOUSLY -- the two arms drafted identical teams.\n")
  cat("Per dev/PREREG_B.md this must NOT be cited as support for B.\n")
}
