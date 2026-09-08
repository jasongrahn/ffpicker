# Draft-day export rebuild. Two availability sources, Yahoo wins.
#   nflreadr players$status -- broad, but lags. Missed TreVeyon Henderson's
#     2026-09-08 IR placement while he sat at board #50.
#   docs/uploads/*_list.csv -- Yahoo roster pages, same-day, narrow window.
# Union them. Name-join on the Yahoo side by necessity (no id in the export).
suppressMessages(library(targets))
for (f in list.files("R", full.names = TRUE)) source(f)

p  <- as.data.frame(arrow::read_parquet("data/raw/players.parquet"))
dp <- as.data.frame(tar_read(dim_player))
st <- merge(dp[, c("player_key", "gsis_id")], p[, c("gsis_id", "status")],
            by = "gsis_id", all.x = TRUE)
board <- merge(as.data.frame(tar_read(draft_board)), st[, c("player_key", "status")],
               by = "player_key", all.x = TRUE)
board$norm <- normalize_player_name(board$player, board$pos)

# source 1: nflreadr status
out_nfl <- board$norm[!is.na(board$status) & board$status != "ACT"]

# source 2: Yahoo roster pages
yahoo_out <- function(file, col, bad) {
  d <- read.csv(file, stringsAsFactors = FALSE)
  d <- d[d$Position %in% c("QB", "RB", "WR", "TE", "K") & d[[col]] %in% bad, ]
  if (!nrow(d)) return(character(0))
  normalize_player_name(d$Player, d$Position)
}
out_ir  <- yahoo_out("docs/uploads/injured_reserve_list.csv", "Change", "On Injured Reserve")
out_ina <- yahoo_out("docs/uploads/active_inactive_list.csv", "Action", "Deactivated")
# a Deactivated player later Activated is available again
back <- yahoo_out("docs/uploads/active_inactive_list.csv", "Action", "Activated")
out_ina <- setdiff(out_ina, back)

unavailable <- unique(c(out_nfl, out_ir, out_ina))
matched_yahoo <- intersect(c(out_ir, out_ina), board$norm)
cat("yahoo IR/inactive rows matched to board:", length(matched_yahoo),
    "of", length(unique(c(out_ir, out_ina))), "\n")
cat("total unavailable:", length(unavailable), "\n")

ex <- read.csv("data/yahoo_rankings.csv", stringsAsFactors = FALSE)
ex$norm <- normalize_player_name(ex$name, ex$position)

y <- load_yahoo_names(YAHOO_NAME_SOURCES)
y$norm <- normalize_player_name(y$name, y$pos)
y$team <- toupper(trimws(y$team))
yl <- y[!duplicated(y$norm), c("norm", "team")]

ex <- merge(ex, yl, by = "norm", all.x = TRUE, suffixes = c("", "_y"))
ex <- ex[order(ex$rank), ]
ex$team <- ifelse(!is.na(ex$team_y), ex$team_y, ex$team)
ex <- ex[!is.na(ex$team_y) | ex$position == "DEF", ]

dropped <- ex[ex$norm %in% unavailable, c("rank", "name", "team", "position")]
ex <- ex[!ex$norm %in% unavailable, ]
# K and DST sink below every skill player. Yahoo's autodraft fills roster slots
# by need and ignored defer_until_round in the 2026-09-08 mock -- it took a DEF
# at pick 78 (our rank 142) and a K at 83 (our 162) with WRs still on the board.
# Ranking them last is the only lever the import format gives us. Order within
# each block is preserved, so a forced pick still lands on our best one.
# Trim the skill block FIRST, then append -- capping the combined frame would
# truncate K/DST off the end, and both are mandatory starters.
n_def <- sum(ex$position == "DEF")
n_k   <- sum(ex$position == "K")
skill <- ex[!ex$position %in% c("K", "DEF"), ]
skill <- head(skill, 300 - n_def - n_k)
ex <- rbind(skill, ex[ex$position == "DEF", ], ex[ex$position == "K", ])
ex$rank <- seq_len(nrow(ex))

out <- ex[, c("rank", "name", "team", "position")]
stopifnot(!any(grepl('[",]', unlist(out))), !any(out$team == ""))
write.csv(out, "data/yahoo_rankings_v2.csv", row.names = FALSE, quote = FALSE)
write.csv(dropped, "data/inactive_do_not_draft.csv", row.names = FALSE, quote = FALSE)
cat("dropped:", nrow(dropped), "| rows written:", nrow(out), "\n")
for (n in c("Josh Jacobs", "TreVeyon Henderson", "Darius Slayton", "AJ Barner")) {
  cat(sprintf("  %-20s in export? %s\n", n, any(out$name == n)))
}
