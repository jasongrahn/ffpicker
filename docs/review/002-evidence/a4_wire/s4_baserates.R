# Lottery-ticket base rates, 2021-2025 REG (2024-25 reported separately). Decision time = after wk8.
# Pool: RB/WR/TE, half-PPR ppg < 8 over games played wks 1-8 (low production).
# Outcome wks 10-15: hit12 = >= 3 games and >= 12 ppg; t24 = >= 3 weeks top-24 (RB/WR) / top-12 (TE).
suppressMessages({library(dplyr); library(tidyr); pkgload::load_all(".", quiet = TRUE)})
cfg <- load_config("scoring")
SEAS <- 2021:2025
ps <- arrow::read_parquet("data/raw/player_stats.parquet") |>
  filter(season %in% SEAS, season_type == "REG", position %in% c("RB", "WR", "TE"))
ps$pts <- score_player_week(ps, cfg)
pl <- arrow::read_parquet("data/raw/players.parquet") |> select(gsis_id, pfr_id, rookie_season, display_name)
sn <- nflreadr::load_snap_counts(SEAS) |> filter(game_type == "REG", position %in% c("RB", "WR", "TE")) |>
  inner_join(pl |> filter(!is.na(pfr_id)) |> distinct(pfr_id, .keep_all = TRUE) |> select(pfr_id, gsis_id), by = c("pfr_player_id" = "pfr_id"))
tw <- bind_rows(ps |> distinct(season, week, team), sn |> distinct(season, week, team))  |> distinct()   # team played that week
# player-season-team: primary team = most games wks 1-8
w <- full_join(ps |> select(season, week, gsis_id = player_id, team, position, pts, carries, targets),
               sn |> select(season, week, gsis_id, team, snap = offense_pct, pos_sn = position), by = c("season", "week", "gsis_id", "team")) |>
  mutate(position = coalesce(position, pos_sn), pts = coalesce(pts, 0), carries = coalesce(carries, 0),
         targets = coalesce(targets, 0), snap = coalesce(snap, 0)) |> select(-pos_sn)
pt <- w |> filter(week <= 8) |> count(season, gsis_id, team) |> group_by(season, gsis_id) |> slice_max(n, n = 1, with_ties = FALSE) |> ungroup() |> select(-n)
grid <- pt |> inner_join(tw, by = c("season", "team"), relationship = "many-to-many") |> filter(week <= 15)
g <- grid |> left_join(w |> select(-team), by = c("season", "week", "gsis_id")) |>
  mutate(played = !is.na(position) & (snap > 0 | pts != 0 | carries + targets > 0),
         across(c(pts, carries, targets, snap), ~ coalesce(.x, 0)))
pos <- w |> group_by(season, gsis_id) |> summarise(position = names(which.max(table(position))), .groups = "drop")
g <- g |> select(-position) |> left_join(pos, by = c("season", "gsis_id"))
# weekly position rank among all players
rk <- w |> group_by(season, week, position) |> mutate(r = rank(-pts, ties.method = "min")) |> ungroup() |> select(season, week, gsis_id, r)
g <- g |> left_join(rk, by = c("season", "week", "gsis_id")) |>
  mutate(top = played & !is.na(r) & r <= ifelse(position == "TE", 12, 24))
team_wk <- g |> distinct(season, team, week) |> group_by(season, team) |> mutate(tg = rank(week)) |> ungroup()
S <- g |> group_by(season, gsis_id, team, position) |> summarise(
  gp18 = sum(played & week <= 8), ppg18 = sum(pts[week <= 8]) / pmax(1, gp18),
  snap35 = mean(snap[week %in% 3:5]), snap68 = mean(snap[week %in% 6:8]), gp35 = sum(played & week %in% 3:5), gp68 = sum(played & week %in% 6:8),
  tg15 = mean(targets[week <= 5]), tg68 = mean(targets[week %in% 6:8]),
  car18 = sum(carries[week <= 8]), opp68 = mean((carries + targets)[week %in% 6:8]),
  played_last = any(played & week == max(week[week <= 8])),
  gp1015 = sum(played & week %in% 10:15), ppg1015 = sum(pts[week %in% 10:15]) / pmax(1, gp1015),
  ptswk1015 = mean(pts[week %in% 10:15]), top1015 = sum(top & week %in% 10:15),
  gp915 = sum(played & week %in% 9:15), ppg915 = sum(pts[week %in% 9:15]) / pmax(1, gp915), .groups = "drop") |>
  left_join(pl |> distinct(gsis_id, .keep_all = TRUE) |> select(gsis_id, rookie_season, display_name), by = "gsis_id") |>
  mutate(hit12 = gp1015 >= 3 & ppg1015 >= 12, t24 = top1015 >= 3, rookie = !is.na(rookie_season) & rookie_season == season)
# RB depth: by carries wks 1-8 within team
rbd <- S |> filter(position == "RB") |> group_by(season, team) |> arrange(desc(car18), .by_group = TRUE) |>
  mutate(rbrank = row_number()) |> ungroup() |> select(season, gsis_id, team, rbrank)
S <- S |> left_join(rbd, by = c("season", "gsis_id", "team"))
rb1 <- S |> filter(rbrank == 1) |> transmute(season, team, rb1_last = played_last, rb1_gp915 = gp915)
S <- S |> left_join(rb1, by = c("season", "team"))
low <- S |> filter(gp18 >= 1, ppg18 < 8)
ci <- function(k, n) { p <- k / n; z <- 1.96; c((p + z^2/(2*n) - z*sqrt(p*(1-p)/n + z^2/(4*n^2))) / (1 + z^2/n), (p + z^2/(2*n) + z*sqrt(p*(1-p)/n + z^2/(4*n^2))) / (1 + z^2/n)) }
summ <- function(d, lab) {
  n <- nrow(d); k <- sum(d$hit12); k2 <- sum(d$t24); cc <- ci(k, n)
  ev <- function(L) mean(pmax(0, d$ptswk1015 - L) * d$hit12)
  data.frame(group = lab, n = n, hit12 = round(k / n, 3), lo = round(cc[1], 3), hi = round(cc[2], 3), t24 = round(k2 / n, 3),
             ppg_hits = round(mean(d$ppg1015[d$hit12]), 1), ev_L9 = round(ev(9), 2), ev_L10 = round(ev(10), 2))
}
grp <- function(d) bind_rows(
  summ(d, "all low (<8 ppg wks1-8)"),
  summ(d |> filter(snap68 >= 0.40), "low + snap68 >= 40%"),
  summ(d |> filter(gp35 >= 1, gp68 >= 2, snap68 - snap35 >= 0.15), "low + snap rise >= 15pp (6-8 v 3-5)"),
  summ(d |> filter(gp35 >= 1, gp68 >= 2, snap68 - snap35 >= 0.15, snap68 >= 0.5), "  ... and snap68 >= 50%"),
  summ(d |> filter(position == "RB", rbrank == 2, rb1_last), "RB2 handcuff, RB1 healthy at wk8"),
  summ(d |> filter(position == "RB", rbrank == 2, rb1_last, rb1_gp915 <= 4), "  ... RB1 then misses >= 3 of wks 9-15"),
  summ(d |> filter(position == "RB", rbrank == 2, rb1_last, rb1_gp915 > 4), "  ... RB1 stays healthy"),
  summ(d |> filter(position == "RB", rbrank == 2, !rb1_last), "RB2, RB1 already out at wk8"),
  summ(d |> filter(position == "WR", rookie), "rookie WR (low)"),
  summ(d |> filter(position == "WR", rookie, gp68 >= 2, tg68 - tg15 >= 2), "rookie WR, tgt/g 6-8 >= wks1-5 + 2"),
  summ(d |> filter(position == "WR", !rookie, gp68 >= 2, tg68 - tg15 >= 2), "vet WR, tgt/g 6-8 >= wks1-5 + 2"),
  summ(d |> filter(opp68 >= 5), "low + opp68 >= 5/g (CLAUDE.md bar)"),
  summ(d |> filter(opp68 >= 10), "low + opp68 >= 10/g"),
  summ(d |> filter(position == "TE", snap68 >= 0.6), "TE low + snap68 >= 60%"))
cat("=== 2021-2025 ===\n"); print(grp(low), row.names = FALSE)
cat("\n=== 2024-2025 only ===\n"); print(grp(low |> filter(season >= 2024)), row.names = FALSE)
cat("\nP(RB1 misses >= 3 of wks 9-15 | healthy at wk8):", round(mean(low$rb1_gp915[low$position == "RB" & low$rbrank == 2 & low$rb1_last] <= 4, na.rm = TRUE), 3), "\n")
cat("\nRB2 handcuff ticket by RB2 opp68 bucket (2021-25):\n")
print(low |> filter(position == "RB", rbrank == 2, rb1_last) |> mutate(b = cut(opp68, c(-1, 3, 6, 10, 40))) |>
  group_by(b) |> summarise(n = n(), hit12 = round(mean(hit12), 3), t24 = round(mean(t24), 3), .groups = "drop") |> as.data.frame())
cat("\nexamples, 2025 snap-rise hits:\n")
print(as.data.frame(low |> filter(season == 2025, gp35 >= 1, gp68 >= 2, snap68 - snap35 >= 0.15, hit12) |>
  transmute(display_name, team, position, ppg18 = round(ppg18, 1), snap35 = round(snap35, 2), snap68 = round(snap68, 2), ppg1015 = round(ppg1015, 1))))
saveRDS(S, "docs/review/002-evidence/a4_wire/baserates_S.rds")
