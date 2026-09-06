#!/usr/bin/env Rscript

# Join Sleeper player data to draft pool using dim_player as the bridge.
# HARD RULE: never join on name. Use sleeper_id (player_id) only.

library(targets)

cache_dir <- "dev/sleeper/cache"
input_file <- file.path(cache_dir, "sleeper_clean.csv")
output_file <- file.path(cache_dir, "pool_sleeper.csv")

# Read sleeper clean data
sleeper <- read.csv(input_file, stringsAsFactors = FALSE)
colnames(sleeper)[1] <- "player_id"  # Rename from player_id column

# Load targets
dim_player <- as.data.frame(tar_read(dim_player, store = "_targets"))
draft_pool <- as.data.frame(tar_read(draft_pool, store = "_targets"))

# Step 1: Join pool to dim_player on player_key to get sleeper_id
pool_with_sleeper_id <- merge(
  draft_pool,
  dim_player[, c("player_key", "sleeper_id")],
  by = "player_key",
  all.x = TRUE,
  sort = FALSE
)

# Step 2: LEFT join sleeper_clean on sleeper_id == player_id
result <- merge(
  pool_with_sleeper_id,
  sleeper[, c("player_id", "search_rank")],
  by.x = "sleeper_id",
  by.y = "player_id",
  all.x = TRUE,
  sort = FALSE
)

# Check for fan-out and dedupe if needed
if (nrow(result) > nrow(draft_pool)) {
  cat("Join fanned out:", nrow(result), "->", nrow(draft_pool), "rows\n")
  # Sort by player_key (to maintain order) and search_rank (keep best/lowest)
  result <- result[order(result$player_key, result$search_rank), ]
  result <- result[!duplicated(result$player_key), ]
  cat("Deduped to:", nrow(result), "rows\n")
}

# Select and order output columns
output <- result[, c("player_key", "player", "pos", "team", "ecr", "ecr_source", "sleeper_id", "search_rank")]

# Ensure exactly 732 rows
if (nrow(output) != 732) {
  stop("Output has ", nrow(output), " rows, expected 732")
}

write.csv(output, output_file, row.names = FALSE)

# Calculate and print match statistics
overall_match_rate <- mean(!is.na(output$search_rank))
cat("Overall match rate:", sprintf("%.2f%%", overall_match_rate * 100), "\n")

# Match rate by ecr_source
for (source in unique(output$ecr_source)) {
  source_data <- output[output$ecr_source == source, ]
  source_match <- mean(!is.na(source_data$search_rank))
  cat("  ", source, ":", sprintf("%.2f%% (%d/%d)", source_match * 100, sum(!is.na(source_data$search_rank)), nrow(source_data)), "\n")
}

# Count overall & ecr > 290 with match
overall_gt290 <- output[output$ecr_source == "overall" & output$ecr > 290, ]
overall_gt290_matched <- sum(!is.na(overall_gt290$search_rank))
cat("Overall ecr > 290 with match:", overall_gt290_matched, "of", nrow(overall_gt290), "\n")
