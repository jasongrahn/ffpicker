#!/usr/bin/env Rscript

# Fetch Sleeper player data and cache it.

cache_dir <- "dev/sleeper/cache"
cache_file_json <- file.path(cache_dir, "sleeper_players.json")
cache_file_csv <- file.path(cache_dir, "sleeper_raw.csv")

# Check cache age
fetch_needed <- TRUE
if (file.exists(cache_file_json)) {
  mtime <- file.mtime(cache_file_json)
  age_hours <- as.numeric(difftime(Sys.time(), mtime, units = "hours"))
  if (age_hours < 24) {
    cat("Cache hit:", cache_file_json, "\n")
    fetch_needed <- FALSE
  }
}

if (fetch_needed) {
  url <- "https://api.sleeper.app/v1/players/nfl"
  cat("Fetching from", url, "\n")
  temp_file <- tempfile(fileext = ".json")
  download.file(url, temp_file, mode = "wb", quiet = TRUE)
  response <- readLines(temp_file, warn = FALSE) |> paste(collapse = "")
  file.copy(temp_file, cache_file_json, overwrite = TRUE)
  unlink(temp_file)
} else {
  response <- readLines(cache_file_json, warn = FALSE) |> paste(collapse = "")
}

# Parse JSON object (keys are player IDs)
players_obj <- jsonlite::fromJSON(response)

# Flatten to data frame
player_ids <- names(players_obj)
df <- data.frame(
  player_id = character(),
  full_name = character(),
  position = character(),
  team = character(),
  search_rank = numeric(),
  active = logical(),
  stringsAsFactors = FALSE
)

for (pid in player_ids) {
  p <- players_obj[[pid]]
  df <- rbind(df, data.frame(
    player_id = pid,
    full_name = p$full_name %||% NA_character_,
    position = p$position %||% NA_character_,
    team = p$team %||% NA_character_,
    search_rank = if (is.null(p$search_rank)) NA_real_ else as.numeric(p$search_rank),
    active = if (is.null(p$active)) NA else isTRUE(p$active),
    stringsAsFactors = FALSE
  ))
}

write.csv(df, cache_file_csv, row.names = FALSE)
cat("Rows:", nrow(df), "\n")
