# Usage (opportunity) for incoming/outgoing trade pieces: target share + snap% by week, 2026 wks 1-8 (MNF wk8 CHI@SEA missing).
suppressMessages(library(dplyr))
x <- readRDS("data/nflreadr/pull_2026.rds"); A3 <- "docs/review/002-evidence/a3_trades"
pv <- readRDS(file.path(A3, "perceived.rds"))
who <- c("Jalen Coker","Josh Downs","DJ Moore","Luther Burden III","Tucker Kraft","Isaiah Likely","Matthew Golden","George Kittle","Mike Evans","Jaylen Waddle",
         "Breece Hall","Michael Wilson","Cam Skattebo","Harold Fannin Jr.","Josh Jacobs","Tre Tucker","T.J. Hockenson","Brenton Strange","Ollie Gordon II","Denzel Boston","Rome Odunze","Carnell Tate")
ids <- as.data.frame(x$ids); ids$yahoo_id <- as.character(ids$yahoo_id)
y <- bind_rows(lapply(c("qb","rb","wr","te"), function(p) { source("dev/weekly/read_yahoo_week.R"); read_yahoo_position(sprintf("docs/uploads/week_8_data/yahoo_week8_%s_2026-10-31.csv", p)) })) |> filter(player %in% who) |> distinct(player, .keep_all = TRUE)
y$merge_name <- nflreadr::clean_player_names(y$player, lowercase = TRUE)
g <- ids |> filter(!is.na(gsis_id)) |> select(gsis_id, pfr_id, yahoo_id, merge_name)
y <- y |> left_join(g |> filter(!is.na(yahoo_id)) |> distinct(yahoo_id, .keep_all = TRUE) |> select(yahoo_id, gsis_i = gsis_id, pfr_i = pfr_id), by = "yahoo_id") |>
  left_join(g |> distinct(merge_name, .keep_all = TRUE) |> select(merge_name, gsis_n = gsis_id, pfr_n = pfr_id), by = "merge_name") |>
  mutate(gsis = coalesce(gsis_i, gsis_n), pfr = coalesce(pfr_i, pfr_n))
ps <- x$player_stats |> filter(player_id %in% y$gsis) |> select(player_id, week, targets, target_share, carries)
sn <- x$snaps |> filter(pfr_player_id %in% y$pfr) |> select(pfr_player_id, week, offense_pct)
out <- bind_rows(lapply(seq_len(nrow(y)), function(i) {
  a <- ps |> filter(player_id == y$gsis[i]); b <- sn |> filter(pfr_player_id == y$pfr[i])
  w <- 1:8; ts <- round(100 * a$target_share[match(w, a$week)]); sp <- round(100 * b$offense_pct[match(w, b$week)])
  tibble(player = y$player[i], team = y$yteam[i], pos = y$pos[i],
         tgt_share_w1_8 = paste(ifelse(is.na(ts), "-", ts), collapse = " "), snap_w1_8 = paste(ifelse(is.na(sp), "-", sp), collapse = " "),
         car_g = round(mean(a$carries, na.rm = TRUE), 1), ts_season = round(100 * mean(a$target_share, na.rm = TRUE), 1))
}))
options(width = 200); print(as.data.frame(out), row.names = FALSE, right = FALSE)
