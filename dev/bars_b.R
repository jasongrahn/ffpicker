#!/usr/bin/env Rscript
#
# Experiment B bars 1 and 4: my_rule = "vona_tiebreak" (position from
# target_position() as today, VONA orders candidates WITHIN it) vs the current
# recommend_picks() arm.
#
# Pre-registered in dev/PREREG_B.md, bars quoted from handoff #13:
#   B1. Zero unfilled starter slots, every tau.
#   B4. Picks changed vs current >= 3/17.
# B2 lives in dev/bars_b_seeds.R, B3 in dev/mc_golden.R, B5 in
# dev/bars_b_mutation.R. Settings frozen from Experiment A -- slot 5, baseline
# deferral, taus 0/3/6/12, noise seed tau+1. Do not tune them.
#
# Run: Rscript dev/bars_b.R

pkgload::load_all(quiet = TRUE)

cat("=== Experiment B — bars B1 + B4 ===\n\n")

store <- "_targets"
league_config <- targets::tar_read(league_config, store = store)
ctx <- sim_context(as.data.frame(targets::tar_read(draft_board, store = store)),
                   as.data.frame(targets::tar_read(draft_fallback, store = store)))

MY_SLOT <- 5
TEAMS <- league_config$teams
ROUNDS <- league_config$roster$rounds %||% 17
DEFER <- list(K = 16, DST = 15)
taus <- c(0, 3, 6, 12)

b1_pass <- TRUE
b4_pass <- TRUE
rows <- list()
tb_all <- list()

cat(sprintf("%-6s %-8s %-10s %-10s %-9s %-8s %-22s\n",
            "tau", "changed", "recommend", "vona_tb", "delta", "tb_picks", "unfilled (tb arm)"))
cat(paste(rep("-", 84), collapse = ""), "\n")

for (tau in taus) {
  noise_matrix <- sim_noise(nrow(ctx$pool), TEAMS * ROUNDS, seed = tau + 1)

  sim_rec <- simulate_draft(ctx, league_config, my_slot = MY_SLOT, defer = DEFER,
                            tau = tau, noise = noise_matrix, my_rule = "recommend")
  sim_tb  <- simulate_draft(ctx, league_config, my_slot = MY_SLOT, defer = DEFER,
                            tau = tau, noise = noise_matrix, my_rule = "vona_tiebreak")

  sv_rec <- starter_value(sim_rec$picks, league_config)
  sv_tb  <- starter_value(sim_tb$picks, league_config)

  changed <- sum(sim_rec$picks$player != sim_tb$picks$player)
  delta <- sv_tb$total - sv_rec$total
  unf <- if (length(sv_tb$unfilled) == 0) "none" else paste(sv_tb$unfilled, collapse = ", ")
  tbl <- sim_tb$tb_log
  n_tb <- if (is.null(tbl)) 0L else nrow(tbl)

  cat(sprintf("%-6g %-8d %-10.1f %-10.1f %-+9.1f %-8d %-22s\n",
              tau, changed, sv_rec$total, sv_tb$total, delta, n_tb, unf))

  if (length(sv_tb$unfilled) > 0) b1_pass <- FALSE
  if (changed < 3) b4_pass <- FALSE

  if (!is.null(tbl)) { tbl$tau <- tau; tb_all[[length(tb_all) + 1]] <- tbl }
  rows[[length(rows) + 1]] <- data.frame(
    tau = tau, changed = changed, recommend = sv_rec$total, vona_tb = sv_tb$total,
    delta = delta, tb_picks = n_tb, unfilled = unf, stringsAsFactors = FALSE)
}

results <- do.call(rbind, rows)
tb_log <- if (length(tb_all)) do.call(rbind, tb_all) else NULL
saveRDS(list(summary = results, tb_log = tb_log), "dev/bars_b_results.rds")

cat("\n--- instrumentation: within-position VONA argmax vs VOR argmax ---\n")
if (is.null(tb_log)) {
  cat("tiebreak branch never reached -- 0 picks routed through it.\n")
} else {
  cat(sprintf("picks routed through the tiebreak: %d\n", nrow(tb_log)))
  cat(sprintf("of those, VONA argmax == VOR argmax: %d (%.0f%%)\n",
              sum(tb_log$same), 100 * mean(tb_log$same)))
  diff_rows <- tb_log[!tb_log$same, , drop = FALSE]
  if (nrow(diff_rows) > 0) print(diff_rows)
}

cat("\n")
cat(sprintf("B1 (zero unfilled starter slots, every tau): %s\n", if (b1_pass) "PASS" else "FAIL"))
cat(sprintf("B4 (picks changed >= 3/17, every tau):      %s\n", if (b4_pass) "PASS" else "FAIL"))
cat("B2 (paired CI, 30 seeds): run dev/bars_b_seeds.R.\n")
cat("B3 (golden 3/3):          run dev/mc_golden.R.\n")
cat("B5 (mutation):            run dev/bars_b_mutation.R.\n")
