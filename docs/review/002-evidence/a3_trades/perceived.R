# Perceived value: what a casual manager sees -- season ppg, last-3 ppg, draft slot, injury tag.
# ppg = nflreadr 2026 REG wks 1-8 (MNF wk8 in, pulled 11-03) scored by score_player_week()
# (validated 35/35 vs Yahoo). Join yahoo_id -> gsis via cached ids, name fallback (rookies: ids
# carry no yahoo_id for 2025-26 classes). Draft slot: official_draft_results.csv on initial+last name.
setwd("/Users/jasongrahn/R-projects/ffootballer")
A3 <- "docs/review/002-evidence/a3_trades"
suppressMessages({library(dplyr); pkgload::load_all(".", quiet = TRUE)})
source("dev/weekly/read_yahoo_week.R")
x <- readRDS("data/nflreadr/pull_2026.rds")
ps <- x$player_stats |> filter(season_type == "REG", week <= 8)
ps$fpts <- score_player_week(ps, load_config("scoring"))

f <- function(p) read_yahoo_position(sprintf("docs/uploads/week_9_data/yahoo_week9_%s_2026-11-03.csv", p))
y <- bind_rows(lapply(c("qb", "rb", "wr", "te"), f)) |> distinct(player, yteam, .keep_all = TRUE)
ids <- as.data.frame(x$ids); ids$yahoo_id <- as.character(ids$yahoo_id)
by_id <- ids[!is.na(ids$yahoo_id) & !is.na(ids$gsis_id), c("yahoo_id", "gsis_id")]; by_id <- by_id[!duplicated(by_id$yahoo_id), ]
by_nm <- ids[!is.na(ids$merge_name) & !is.na(ids$gsis_id), c("merge_name", "gsis_id")]
by_nm <- by_nm[!duplicated(by_nm$merge_name) & !by_nm$merge_name %in% by_nm$merge_name[duplicated(by_nm$merge_name)], ]
y$merge_name <- nflreadr::clean_player_names(y$player, lowercase = TRUE)
y <- y |> left_join(by_id |> rename(g_i = gsis_id), by = "yahoo_id") |> left_join(by_nm |> rename(g_n = gsis_id), by = "merge_name") |>
  mutate(method = ifelse(!is.na(g_i), "id", ifelse(!is.na(g_n), "name", NA)), gsis_id = coalesce(g_i, g_n))

pp <- ps |> group_by(player_id) |> arrange(week) |>
  summarise(g = n(), ppg = mean(fpts), last3 = mean(tail(fpts, 3)), wks = paste(week, collapse = ","),
            last_wk = max(week), .groups = "drop")
# MNF wk8 (CHI@SEA) players: last game in pull = wk7 or earlier -> flagged
mnf <- x$schedules |> filter(week == 8, is.na(result)) |> select(home_team, away_team) |> unlist()

dr <- read.csv("data/official_draft_results.csv", stringsAsFactors = FALSE, encoding = "UTF-8")
dr$key <- tolower(gsub("[^A-Za-z]", "", dr$Player))
y$key <- tolower(gsub("[^A-Za-z]", "", paste0(substr(y$player, 1, 1), sub("^\\S+ ", "", sub(" (Jr\\.|Sr\\.|II|III|IV)$", "", y$player)))))
dr1 <- dr[!duplicated(dr$key) & !dr$key %in% dr$key[duplicated(dr$key)], ]
y <- y |> left_join(dr1 |> transmute(key, pick = Pick, drafted_by = DraftedBy), by = "key")

out <- y |> filter(owner != "FA" & !grepl("^W ", owner) | player == "C.J. Stroud") |>
  left_join(pp, by = c("gsis_id" = "player_id")) |>
  transmute(player, yteam, pos, owner, injury_1031 = injury, proj_1031 = proj, method, g = coalesce(g, 0L),
            ppg = round(ppg, 2), last3 = round(last3, 2), wks, pick, round = ceiling(pick / 10),
            mnf_pending = toupper(yteam) %in% mnf)
cat("rostered players:", nrow(out), "| gsis matched:", sum(!is.na(out$method)), "(id", sum(out$method == "id", na.rm = TRUE),
    ", name", sum(out$method == "name", na.rm = TRUE), ") | with games:", sum(out$g > 0), "| draft slot matched:", sum(!is.na(out$pick)), "\n")
cat("unmatched to gsis:", paste(out$player[is.na(out$method)], collapse = ", "), "\n")
saveRDS(out, file.path(A3, "perceived.rds"))
options(width = 220)
print(as.data.frame(out |> filter(owner == "JGrahnasaurs" | player %in% c("Josh Jacobs", "Luther Burden III", "Isaiah Likely", "C.J. Stroud")) |>
  select(player, yteam, pos, owner, injury_1031, g, ppg, last3, wks, pick)), row.names = FALSE)
