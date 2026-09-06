#!/usr/bin/env Rscript

# Clean Sleeper player data by applying position and validity filters.

cache_dir <- "dev/sleeper/cache"
input_file <- file.path(cache_dir, "sleeper_raw.csv")
output_file <- file.path(cache_dir, "sleeper_clean.csv")

df <- read.csv(input_file, stringsAsFactors = FALSE)
cat("Initial rows:", nrow(df), "\n")

# Filter 1: drop search_rank NA or >= 9999999
df <- df[!(is.na(df$search_rank) | df$search_rank >= 9999999), ]
cat("After filter search_rank:", nrow(df), "\n")

# Filter 2: drop active that is not TRUE
df <- df[df$active == TRUE, ]
cat("After filter active:", nrow(df), "\n")

# Filter 3: drop team NA or ""
df <- df[!(is.na(df$team) | df$team == ""), ]
cat("After filter team:", nrow(df), "\n")

# Filter 4: keep position in QB, RB, WR, TE, K
valid_positions <- c("QB", "RB", "WR", "TE", "K")
df <- df[df$position %in% valid_positions, ]
cat("After filter position:", nrow(df), "\n")

# Validation checks
if (any(df$search_rank >= 9999999, na.rm = TRUE)) {
  stop("Found search_rank >= 9999999 in output")
}
if (any(df$active != TRUE, na.rm = TRUE)) {
  stop("Found active != TRUE in output")
}
cat("Validation passed\n")

write.csv(df, output_file, row.names = FALSE)
