# Correlation analysis: ECR, search_rank, and actual performance
# Compares how well ECR and search_rank predict 2025 points per game, by region.

pkgload::load_all(quiet = TRUE)

# Wait for input file with retries
input_path <- "dev/sleeper/cache/pool_sleeper.csv"
pool_sleeper <- NULL
for (attempt in 1:5) {
  if (file.exists(input_path)) {
    pool_sleeper <- read.csv(input_path, stringsAsFactors = FALSE)
    cat("✓ Loaded pool_sleeper.csv\n")
    break
  }
  if (attempt < 5) {
    cat("Waiting for", input_path, "... attempt", attempt, "\n")
    Sys.sleep(3)
  }
}

if (is.null(pool_sleeper)) {
  cat("ERROR: Could not load", input_path, "after retries.\n")
  cat("Expected columns: player_key, player, pos, team, ecr, ecr_source, sleeper_id, search_rank\n")
  quit(status = 1)
}

# Ensure numeric columns
pool_sleeper$ecr <- as.numeric(pool_sleeper$ecr)
pool_sleeper$search_rank <- as.numeric(pool_sleeper$search_rank)

# Load 2025 fantasy points per game
store <- "_targets"
fct_player_week_scored <- targets::tar_read(fct_player_week_scored, store = store)

# Filter to 2025 regular season
fct_2025 <- fct_player_week_scored[fct_player_week_scored$season == 2025, ]
if (!is.null(fct_2025$season_type)) {
  fct_2025 <- fct_2025[fct_2025$season_type == "REG", ]
}

# Compute PPG per player_key
ppg_data <- aggregate(
  fantasy_points ~ player_key,
  data = fct_2025,
  FUN = function(x) mean(x, na.rm = TRUE),
  na.action = na.pass
)
colnames(ppg_data) <- c("player_key", "ppg")

# Join to pool
pool_ppg <- merge(pool_sleeper, ppg_data, by = "player_key", all.x = TRUE)

# Define regions
pool_ppg$region <- NA_character_
pool_ppg$region[pool_ppg$ecr_source == "overall" & pool_ppg$ecr <= 290] <- "HEAD"
pool_ppg$region[pool_ppg$ecr_source == "overall" & pool_ppg$ecr > 290] <- "TAIL"
pool_ppg$region[pool_ppg$ecr_source == "position"] <- "position"

cat("\n=== SPEARMAN CORRELATIONS: ecr vs ppg, search_rank vs ppg ===\n\n")

regions <- c("HEAD", "TAIL", "position")
results <- data.frame(
  Region = character(0),
  n_ecr = integer(0),
  cor_ecr_ppg = numeric(0),
  n_search = integer(0),
  cor_search_ppg = numeric(0),
  stringsAsFactors = FALSE
)

for (reg in regions) {
  subset_reg <- pool_ppg[pool_ppg$region == reg, ]

  # ECR vs PPG (complete cases)
  cc_ecr <- complete.cases(subset_reg[, c("ecr", "ppg")])
  n_ecr <- sum(cc_ecr)
  cor_ecr_ppg <- if (n_ecr >= 2) {
    cor(subset_reg$ecr[cc_ecr], subset_reg$ppg[cc_ecr], method = "spearman", use = "complete.obs")
  } else {
    NA_real_
  }

  # Search_rank vs PPG (complete cases)
  cc_search <- complete.cases(subset_reg[, c("search_rank", "ppg")])
  n_search <- sum(cc_search)
  cor_search_ppg <- if (n_search >= 2) {
    cor(subset_reg$search_rank[cc_search], subset_reg$ppg[cc_search], method = "spearman", use = "complete.obs")
  } else {
    NA_real_
  }

  results <- rbind(results, data.frame(
    Region = reg,
    n_ecr = n_ecr,
    cor_ecr_ppg = cor_ecr_ppg,
    n_search = n_search,
    cor_search_ppg = cor_search_ppg,
    stringsAsFactors = FALSE
  ))
}

print(results, row.names = FALSE)

cat("\n=== PARTIAL SPEARMAN: search_rank vs ppg, controlling for ecr (HEAD only) ===\n\n")

head_data <- pool_ppg[pool_ppg$region == "HEAD", ]
cc_partial <- complete.cases(head_data[, c("search_rank", "ecr", "ppg")])
n_partial <- sum(cc_partial)

if (n_partial >= 3) {
  # Rank-transform all three variables
  search_rank_vals <- head_data$search_rank[cc_partial]
  ecr_vals <- head_data$ecr[cc_partial]
  ppg_vals <- head_data$ppg[cc_partial]

  rank_s <- rank(search_rank_vals, na.last = "keep")
  rank_e <- rank(ecr_vals, na.last = "keep")
  rank_p <- rank(ppg_vals, na.last = "keep")

  # Spearman correlations
  r_sp <- cor(rank_s, rank_p, method = "pearson")
  r_se <- cor(rank_s, rank_e, method = "pearson")
  r_ep <- cor(rank_e, rank_p, method = "pearson")

  # Partial correlation formula
  rho_partial <- (r_sp - r_se * r_ep) / sqrt((1 - r_se^2) * (1 - r_ep^2))

  cat("  r_sp (search_rank vs ppg):", round(r_sp, 4), "\n")
  cat("  r_se (search_rank vs ecr):", round(r_se, 4), "\n")
  cat("  r_ep (ecr vs ppg):", round(r_ep, 4), "\n")
  cat("  rho_partial:", round(rho_partial, 4), "\n")
  cat("  n:", n_partial, "\n")
} else {
  cat("Insufficient complete cases (need >= 3, have", n_partial, ")\n")
}

cat("\n=== SPEARMAN: search_rank vs ecr (TAIL only) ===\n\n")

tail_data <- pool_ppg[pool_ppg$region == "TAIL", ]
cc_tail <- complete.cases(tail_data[, c("search_rank", "ecr")])
n_tail <- sum(cc_tail)

if (n_tail >= 2) {
  cor_tail_sr_ecr <- cor(tail_data$search_rank[cc_tail], tail_data$ecr[cc_tail], method = "spearman")
  cat("  cor(search_rank, ecr):", round(cor_tail_sr_ecr, 4), "\n")
  cat("  n:", n_tail, "\n")
} else {
  cat("Insufficient complete cases (need >= 2, have", n_tail, ")\n")
}
