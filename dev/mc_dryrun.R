#!/usr/bin/env Rscript
#
# Sweep mode: compare draft outcomes across deferral scenarios and tau values.
# One sim_noise per replicate, reused across all scenarios and taus (common random numbers).
#
# Run: Rscript dev/mc_dryrun.R [--n_sims 200] [--tau 0,3,6,12] [--cores N] [--slot 5]

pkgload::load_all(quiet = TRUE)

# Parse command-line arguments
args <- commandArgs(trailingOnly = TRUE)
n_sims <- 200
tau_values <- c(0, 3, 6, 12)
cores <- max(1, parallel::detectCores() - 1)
my_slot <- 5

for (i in seq_along(args)) {
  if (args[i] == "--n_sims" && i < length(args)) {
    n_sims <- as.integer(args[i + 1])
  } else if (args[i] == "--tau" && i < length(args)) {
    tau_values <- as.integer(strsplit(args[i + 1], ",")[[1]])
  } else if (args[i] == "--cores" && i < length(args)) {
    cores <- as.integer(args[i + 1])
  } else if (args[i] == "--slot" && i < length(args)) {
    my_slot <- as.integer(args[i + 1])
  }
}

# Load real data
store <- "_targets"
league_config <- targets::tar_read(league_config, store = store)
draft_board <- as.data.frame(targets::tar_read(draft_board, store = store))
draft_fallback <- as.data.frame(targets::tar_read(draft_fallback, store = store))

ctx <- sim_context(draft_board, draft_fallback)
TEAMS <- league_config$teams
ROUNDS <- league_config$roster$rounds %||% 17

# Scenarios from dryrun.R
scenarios <- list(
  "baseline (K16, DST15)" = list(K = 16, DST = 15),
  "QB deferred to rd 7"   = list(K = 16, DST = 15, QB = 7),
  "QB deferred to rd 8"   = list(K = 16, DST = 15, QB = 8)
)

# Run replicates: for each replicate, generate ONE noise matrix, then try all scenarios/taus
replicate_results <- parallel::mclapply(seq_len(n_sims), function(rep_id) {
  # One noise matrix per replicate
  noise_matrix <- sim_noise(nrow(ctx$pool), TEAMS * ROUNDS, seed = rep_id)

  rep_results <- numeric(0)
  for (scen_name in names(scenarios)) {
    for (tau in tau_values) {
      sim <- simulate_draft(ctx, league_config, my_slot = my_slot, defer = scenarios[[scen_name]],
                           tau = tau, noise = noise_matrix)
      sv <- starter_value(sim$picks, league_config)
      key <- sprintf("%s_tau%d", scen_name, tau)
      rep_results[key] <- sv$total
    }
  }
  rep_results
}, mc.cores = cores)

# Reshape results: per-sim totals table
keys <- names(replicate_results[[1]])
per_sim_totals_list <- lapply(replicate_results, function(x) as.numeric(x[keys]))
per_sim_totals <- as.data.frame(do.call(rbind, per_sim_totals_list))
names(per_sim_totals) <- keys

# Output per tau
for (tau in tau_values) {
  cat(sprintf("=== tau = %d (n_sims = %d) ===\n", tau, n_sims))

  # Select columns for this tau
  tau_cols <- grep(sprintf("_tau%d$", tau), names(per_sim_totals), value = TRUE)
  scenario_names <- sub(sprintf("_tau%d$", tau), "", tau_cols)

  # Compute per-scenario stats
  cat(sprintf("%-30s %15s %10s\n", "scenario", "mean starters", "sd"))
  scenario_stats <- list()
  for (i in seq_along(scenario_names)) {
    col <- tau_cols[i]
    scen_name <- scenario_names[i]
    mean_val <- mean(per_sim_totals[[col]], na.rm = TRUE)
    sd_val <- sd(per_sim_totals[[col]], na.rm = TRUE)
    scenario_stats[[scen_name]] <- list(mean = mean_val, sd = sd_val, values = per_sim_totals[[col]])
    cat(sprintf("%-30s %15.1f %10.1f\n", scen_name, mean_val, sd_val))
  }

  # Paired deltas and bootstrap CI
  cat("\npaired deltas\n")
  cat(sprintf("%-35s %15s %20s %10s %10s\n", "A vs B", "mean", "95% CI", "P(A>B)", "P(tie)"))

  # Pairs: (rd7 vs baseline), (rd8 vs baseline), (rd8 vs rd7)
  pairs <- list(
    "rd7 - baseline" = c("QB deferred to rd 7", "baseline (K16, DST15)"),
    "rd8 - baseline" = c("QB deferred to rd 8", "baseline (K16, DST15)"),
    "rd8 - rd7" = c("QB deferred to rd 8", "QB deferred to rd 7")
  )

  for (pair_name in names(pairs)) {
    scen_a <- pairs[[pair_name]][1]
    scen_b <- pairs[[pair_name]][2]

    if (!scen_a %in% scenario_names || !scen_b %in% scenario_names) {
      next
    }

    delta <- scenario_stats[[scen_a]]$values - scenario_stats[[scen_b]]$values
    ci <- paired_bootstrap_ci(delta, n_boot = 10000, conf = 0.95)

    # Add p_tie: proportion of exact ties
    p_tie <- mean(delta == 0, na.rm = TRUE)

    ci_str <- sprintf("[%+.1f, %+.1f]", ci$lo, ci$hi)
    indistinguishable <- (ci$lo < 0 && ci$hi > 0)
    status <- if (indistinguishable) "INDISTINGUISHABLE" else ""

    cat(sprintf("%-35s %15.1f %20s %10.2f   %10.2f   %s\n", pair_name, ci$mean, ci_str, ci$p_a_gt_b, p_tie, status))

    # Store for ci_table
    if (!exists("ci_rows")) {
      ci_rows <- data.frame(
        tau = integer(), pair = character(), mean = numeric(), lo = numeric(), hi = numeric(),
        p_a_gt_b = numeric(), p_tie = numeric(), indistinguishable = logical(), stringsAsFactors = FALSE
      )
    }
    ci_rows <- rbind(ci_rows, data.frame(
      tau = tau, pair = pair_name, mean = ci$mean, lo = ci$lo, hi = ci$hi,
      p_a_gt_b = ci$p_a_gt_b, p_tie = p_tie, indistinguishable = indistinguishable, stringsAsFactors = FALSE
    ))
  }

  cat("\n")
}

# Save results
if (exists("ci_rows")) {
  ci_table <- ci_rows
} else {
  ci_table <- data.frame(
    tau = integer(), pair = character(), mean = numeric(), lo = numeric(), hi = numeric(),
    p_a_gt_b = numeric(), p_tie = numeric(), indistinguishable = logical(), stringsAsFactors = FALSE
  )
}

results <- list(
  config = list(n_sims = n_sims, tau_values = tau_values, my_slot = my_slot),
  per_sim_totals = per_sim_totals,
  ci_table = ci_table
)
saveRDS(results, "dev/mc_results.rds")
cat("Saved results to dev/mc_results.rds\n")
