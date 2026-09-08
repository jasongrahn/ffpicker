# Rebuild data/pick_log.jsonl from the OFFICIAL Yahoo draft results.
#
# Why rebuild, not reconcile: the live log written during the draft contains
# substituted opponent picks (handoff #23 SS5) -- off-board players could not be
# entered under the pick clock, so an unknown subset of its 150 opponent rows
# name the wrong player. Official results are authoritative; the live log is
# archived, not merged.
#
# Name join by necessity: official export gives "B. Robinson", no id. Match is
# first-initial + last-name + pos. Team is NOT used as a key -- the official file
# carries 2026 teams and the pool carries the teams it was built with, so several
# rows legitimately disagree (Evans SF, Metcalf PIT, Kelce KC).

suppressMessages({ library(targets); library(jsonlite) })
invisible(lapply(list.files("R", "\\.R$", full.names = TRUE), source))

official  <- read.csv("data/official_draft_results.csv", stringsAsFactors = FALSE)
pool      <- combined_selectable_pool(tar_read(draft_board), tar_read(draft_fallback))
pool      <- unique(pool)

# --- normalization -----------------------------------------------------------
strip <- function(x) {
  x <- gsub("[.'`’]", "", x)
  x <- gsub("\\s+(Jr|Sr|II|III|IV|V)$", "", x, perl = TRUE)
  trimws(tolower(x))
}
last_of  <- function(full) {
  parts <- strsplit(strip(full), "\\s+")
  vapply(parts, function(p) paste(p[-1], collapse = " "), character(1))
}
init_of  <- function(full) substr(strip(full), 1, 1)

pool$k_last <- last_of(pool$player)
pool$k_init <- init_of(pool$player)
pool$k_pos  <- toupper(pool$pos)

official$k_last <- last_of(official$Player)
official$k_init <- init_of(official$Player)
official$k_pos  <- ifelse(toupper(official$Position) == "DEF", "DST", toupper(official$Position))

# DST rows are city/nickname ("Rams"), not person names -- key them on team code.
# Official and pool disagree on two codes, and not consistently within the pool
# (DST says JAX, the K pool says JAC), so accept either alias.
team_alias <- list(LAR = c("LAR", "LA"), JAX = c("JAX", "JAC"),
                   LA = c("LA", "LAR"), JAC = c("JAC", "JAX"))
official$k_team <- toupper(official$Team)
teams_for <- function(t) if (!is.null(team_alias[[t]])) team_alias[[t]] else t

# Manual resolutions. Only for rows the key genuinely cannot separate.
#   pick 1: "B. Robinson RB Atl" is ambiguous -- Bijan Robinson and Brian
#           Robinson Jr. are both ATL RBs. Pick 1.01 is Bijan.
manual_key <- c("1" = 6725L)

# Off-board picks: real Yahoo selections with no row in the Draft Pool at all.
# Handoff #23 SS9 names this as the gap that corrupted the live log; here they get
# synthetic negative keys (-91xxxx, distinct from the -900xxx DST block) so the
# log stays replayable and the picks stay counted.
off_board <- data.frame(
  pick = c(144L, 145L),
  name = c("Tyler Loop", "Harrison Mevis"),
  pos  = c("K", "K"),
  team = c("BAL", "LAR"),
  player_key = c(-910001L, -910002L),
  stringsAsFactors = FALSE
)

keep0 <- c("player_key", "player", "pos", "team")
resolve <- function(i) {
  o <- official[i, ]
  if (!is.na(manual_key[as.character(o$Pick)])) {
    return(pool[pool$player_key == manual_key[[as.character(o$Pick)]], keep0][1, ])
  }
  if (o$Pick %in% off_board$pick) {
    ob <- off_board[off_board$pick == o$Pick, ]
    return(data.frame(player_key = ob$player_key, player = ob$name,
                      pos = ob$pos, team = ob$team))
  }
  if (o$k_pos == "DST") {
    hit <- pool[pool$k_pos == "DST" & toupper(pool$team) %in% teams_for(o$k_team), ]
  } else {
    hit <- pool[pool$k_pos == o$k_pos & pool$k_last == o$k_last & pool$k_init == o$k_init, ]
    if (nrow(hit) > 1) {                       # disambiguate on team when needed
      t <- hit[toupper(hit$team) == o$k_team, ]
      if (nrow(t) == 1) hit <- t
    }
  }
  if (nrow(hit) == 1) return(hit[1, keep0])
  data.frame(player_key = NA_integer_, player = NA_character_,
             pos = NA_character_, team = NA_character_)
}

matched <- do.call(rbind, lapply(seq_len(nrow(official)), resolve))
official$player_key    <- matched$player_key
official$matched_name  <- matched$player
official$matched_pos   <- matched$pos

miss <- official[is.na(official$player_key), ]
dup  <- official$player_key[!is.na(official$player_key)]
cat(sprintf("matched %d/%d\n", sum(!is.na(official$player_key)), nrow(official)))
if (nrow(miss)) { cat("UNMATCHED:\n"); print(miss[, c("Pick","Player","Position","Team")]) }
if (anyDuplicated(dup)) {
  cat("DUPLICATE player_keys:\n")
  print(official[official$player_key %in% dup[duplicated(dup)],
                 c("Pick","Player","matched_name")])
}

stopifnot(!anyNA(official$player_key), !anyDuplicated(official$player_key))

# --- archive the live log, then rebuild ---------------------------------------
log_path <- "data/pick_log.jsonl"
dir.create("dev/pick_log_archive", showWarnings = FALSE, recursive = TRUE)
if (file.exists(log_path)) {
  archive <- file.path("dev/pick_log_archive",
                       format(Sys.time(), "pick_log-%Y%m%d-%H%M%S-PRE-OFFICIAL.jsonl"))
  file.copy(log_path, archive, overwrite = FALSE)
  cat("archived live log ->", archive, "\n")
  unlink(log_path)
}

official$team_name <- ifelse(official$DraftedBy == "Your Team",
                             "JGrahnasaurs", official$DraftedBy)

start_draft(log_path, teams = 10, my_team = "JGrahnasaurs", my_slot = 10)
for (i in seq_len(nrow(official))) {
  append_pick_event(log_path, list(
    type = "pick_made",
    slot = official$Pick[i],
    team = official$team_name[i],
    player_key = official$player_key[i]
  ))
}

write.csv(off_board, "data/off_board_picks.csv", row.names = FALSE)

st <- replay_pick_log(log_path)
cat(sprintf("rebuilt: %d picks, %d teams, my_slot %s, last slot %d\n",
            length(st$drafted_players), length(st$rosters), st$my_slot, st$last_pick_slot))
print(vapply(st$rosters, length, integer(1)))
