# Current wire, 10-31 owners. FA and W (...) both available. Opportunity = carries + targets.
source("docs/review/002-evidence/a4_wire/a4_common.R")
OUT <- "docs/review/002-evidence/a4_wire/"
X <- readRDS("data/nflreadr/pull_2026.rds"); suppressMessages(pkgload::load_all(".", quiet = TRUE))
own <- bind_rows(lapply(c("qb", "rb", "wr", "te", "k", "def"), function(p)
  read_yahoo_position(sprintf("docs/uploads/week_8_data/yahoo_week8_%s_2026-10-31.csv", p)))) |>
  distinct(player, yteam, .keep_all = TRUE) |> mutate(key = ifelse(pos == "DEF", paste0("DEF:", yteam), yahoo_id))
# raw base: mean non-zero proj wks 4-8 WITHOUT the live filter + last-2-export proj
rawb <- bind_rows(lapply(names(ex), function(w) ex[[w]] |> transmute(key, week = as.integer(w), proj))) |>
  group_by(key) |> summarise(base_raw = mean(proj[proj > 0]), p7 = sum(proj[week == 7]), p8 = sum(proj[week == 8]),
                              last_nz = suppressWarnings(max(week[proj > 0])), .groups = "drop")
d <- own |> select(key, player, yahoo_id, yteam, pos, injury, owner31 = owner, pct_ros) |>
  left_join(P |> select(key, base), by = "key") |> left_join(rawb, by = "key") |>
  mutate(avail = owner31 == "FA" | grepl("^W [(]", owner31), nfl = recode(toupper(yteam), "LAR" = "LA"),
         base = coalesce(base, 0)) |> left_join(byes, by = c("nfl" = "team"))
d <- attach_nfl_ids(d)
cfg <- load_config("scoring")
ps <- X$player_stats |> filter(season_type == "REG"); ps$pts <- score_player_week(ps, cfg)
tw <- bind_rows(ps |> distinct(team, week)) |> arrange(team, week) |> group_by(team) |> mutate(tg = rev(row_number(rev(week)))) |> ungroup()
# last 3 TEAM games per team (handles byes + the missing wk8 MNF game)
l3 <- tw |> group_by(team) |> slice_max(week, n = 3) |> ungroup()
pl <- ps |> filter(!is.na(player_id)) |> mutate(opp = coalesce(carries, 0) + coalesce(targets, 0))
tm_of <- pl |> group_by(player_id) |> slice_max(week, n = 1, with_ties = FALSE) |> ungroup() |> select(player_id, tm = team)
h <- pl |> inner_join(tm_of, by = "player_id") |> filter(team == tm) |>
  left_join(l3 |> mutate(L3 = TRUE) |> select(team, week, L3), by = c("team", "week")) |> mutate(L3 = coalesce(L3, FALSE)) |>
  group_by(gsis_id = player_id, tm) |>
  summarise(gp = n(), ppg = mean(pts), opp_l3 = sum(opp[L3]) / 3, opp_pre = sum(opp[!L3]) / pmax(1, n_distinct(week[!L3])),
            car_l3 = sum(coalesce(carries, 0)[L3]) / 3, tgt_l3 = sum(coalesce(targets, 0)[L3]) / 3,
            tsh_l3 = mean(target_share[L3], na.rm = TRUE), pts_l3 = sum(pts[L3]) / 3, .groups = "drop") |>
  mutate(trend = opp_l3 - opp_pre)
ids <- X$ids |> filter(!is.na(gsis_id), !is.na(pfr_id)) |> distinct(pfr_id, .keep_all = TRUE)
sn <- X$snaps |> filter(game_type == "REG") |> inner_join(ids |> select(pfr_id, gsis_id), by = c("pfr_player_id" = "pfr_id")) |>
  left_join(l3 |> mutate(L3 = TRUE) |> select(team, week, L3), by = c("team", "week")) |> mutate(L3 = coalesce(L3, FALSE)) |>
  group_by(gsis_id) |> summarise(snap_l3 = round(100 * sum(offense_pct[L3]) / 3), snap_pre = round(100 * mean(offense_pct[!L3])),
                                 snap_wk = paste(round(100 * offense_pct[order(week)]), collapse = "/"), .groups = "drop")
rk <- X$ids |> filter(!is.na(gsis_id)) |> distinct(gsis_id, .keep_all = TRUE) |> transmute(gsis_id, draft_year, age)
d <- d |> left_join(h, by = "gsis_id", na_matches = "never") |> left_join(sn, by = "gsis_id", na_matches = "never") |>
  left_join(rk, by = "gsis_id", na_matches = "never") |> mutate(rookie = coalesce(draft_year == 2026, FALSE))
saveRDS(d, paste0(OUT, "wire_table.rds"))
cols <- function(x) as.data.frame(x |> transmute(player, pos, nfl, bye, inj = substr(coalesce(injury, ""), 1, 5), own = substr(owner31, 1, 11),
  base = round(base, 1), braw = round(base_raw, 1), p8 = p8, ppg = round(ppg, 1), opp3 = round(opp_l3, 1), trend = round(trend, 1),
  car3 = round(car_l3, 1), tgt3 = round(tgt_l3, 1), snap3 = snap_l3, snaps = snap_wk, rk = ifelse(rookie, "R", "")))
for (p in c("RB", "WR", "TE")) {
  cat(sprintf("\n== available %s, opp3 >= 5, healthy-ish, by opp3 ==\n", p))
  print(cols(d |> filter(avail, pos == p, !grepl("IR|^O$", coalesce(injury, "")), coalesce(opp_l3, 0) >= 5) |> arrange(desc(opp_l3)) |> head(10)), row.names = FALSE)
}
cat("\n== available ROOKIES (any pos RB/WR/TE), snaps3 >= 30 or opp3 >= 4 ==\n")
print(cols(d |> filter(avail, rookie, pos %in% c("RB", "WR", "TE"), coalesce(snap_l3, 0) >= 30 | coalesce(opp_l3, 0) >= 4) |> arrange(desc(opp_l3)) |> head(12)), row.names = FALSE)
cat("\n== available INJURED (O/IR/PUP/D) with pre-injury base_raw >= 8 (IR-slot stash candidates) ==\n")
print(cols(d |> filter(avail, grepl("IR|^O$|PUP|^D$|NFI", coalesce(injury, "")), coalesce(base_raw, 0) >= 8) |> arrange(desc(base_raw))), row.names = FALSE)
cat("\n== OUR roster ==\n"); print(cols(d |> filter(grepl("JGrahn", owner31)) |> arrange(pos)), row.names = FALSE)
cat("\n== TR incoming ==\n"); print(cols(d |> filter(player %in% c("Josh Jacobs", "Luther Burden III", "Isaiah Likely"))), row.names = FALSE)
