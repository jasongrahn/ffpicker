# P4 item 9: week 8 is (nearly) played. Estimate every team's wk8 score from nflreadr
# (wk8 minus MNF CHI@SEA; MNF players at their 10-31 projection), 10-31 rosters.
# Lineups unknown -> two bounds: proj-optimal lineup (10-31 Sat projections) scored with actuals,
# and best-possible (actual-optimal). DST: PA tier + sacks + 2 INT + 2 FR + 6 TD + 2 safety.
SC <- "docs/review/002-evidence"
suppressMessages(pkgload::load_all(".", quiet = TRUE))
source(file.path(SC, "sim_helpers.R")); source(file.path(SC, "p4_redteam/p4_engine.R"))
rt <- readRDS(file.path(SC, "p4_redteam/roster_truth.rds")); b <- rt$b
nf <- readRDS("data/nflreadr/pull_2026.rds")
ps8 <- nf$player_stats |> filter(week == 8)
sc <- load_config("scoring")
ps8$pts <- score_player_week(ps8, sc)
ids <- nf$ids |> mutate(yahoo_id = as.character(yahoo_id))
x <- b |> filter(owner %in% teams) |> mutate(nfl = nfl_team(yteam))
x <- x |> left_join(ids |> filter(!is.na(yahoo_id)) |> distinct(yahoo_id, .keep_all = TRUE) |> transmute(key = yahoo_id, gsis = gsis_id), by = "key")
nm <- ids |> mutate(mn = nflreadr::clean_player_names(name, lowercase = TRUE)) |> filter(!duplicated(mn))
x <- x |> mutate(mn = nflreadr::clean_player_names(player, lowercase = TRUE)) |>
  left_join(nm |> transmute(mn, gsis_n = gsis_id), by = "mn") |> mutate(gsis = coalesce(gsis, gsis_n))
x <- x |> left_join(ps8 |> select(gsis = player_id, pts), by = "gsis")
# DST
s8 <- nf$schedules |> filter(week == 8)
ts <- nf$team_stats |> filter(week == 8)
pa_pts <- function(pa) { t <- sc$dst$points_allowed; vapply(pa, function(v) { for (r in t) if (v <= r$max) return(r$points); NA_real_ }, 0) }
dst <- ts |> transmute(team, sacks = def_sacks, int = def_interceptions, fr = fumble_recovery_opp,
                       td = def_tds + special_teams_tds, sf = def_safeties, blk = def_fg_blocks + def_punt_blocks) |>
  left_join(bind_rows(s8 |> transmute(team = home_team, pa = away_score), s8 |> transmute(team = away_team, pa = home_score)), by = "team") |>
  mutate(dpts = pa_pts(pa) + sacks + 2 * int + 2 * fr + 6 * td + 2 * sf + 2 * blk)
x <- x |> left_join(dst |> select(nfl = team, dpts), by = "nfl") |>
  mutate(played = nfl %in% ON[["8"]], mnf = nfl %in% c("CHI", "SEA"),
         act = case_when(!played ~ 0, mnf ~ proj, pos == "DEF" ~ dpts, TRUE ~ coalesce(pts, 0)))
cat("unmatched skill players who played (no gsis or no stat row):\n")
print(as.data.frame(x |> filter(played, !mnf, pos != "DEF", is.na(pts), is.na(injury) | injury == "") |> select(owner, player, pos, nfl, proj)))
est <- bind_rows(lapply(teams, function(t) { d <- x |> filter(owner == t, is.na(injury) | !grepl("IR", injury))
  # proj-optimal lineup by 10-31 projection, then its actual
  lineup <- function(score) { pick <- integer(0)
    for (p in c("QB", "K", "DEF")) { i <- which(d$pos == p); pick <- c(pick, i[order(-score[i])][seq_len(min(1, length(i)))]) }
    for (pp in list(c("RB", 2), c("WR", 2), c("TE", 1))) { i <- which(d$pos == pp[1]); pick <- c(pick, i[order(-score[i])][seq_len(min(as.integer(pp[2]), length(i)))]) }
    i <- setdiff(which(d$pos %in% c("RB", "WR", "TE")), pick); pick <- c(pick, i[order(-score[i])][seq_len(min(1, length(i)))]); pick }
  lp <- lineup(d$proj); la <- lineup(d$act)
  tibble(team = t, proj_opt_proj = sum(d$proj[lp]), proj_opt_actual = sum(d$act[lp]), best_actual = sum(d$act[la]),
         n_mnf_in_lineup = sum(d$mnf[lp]), sim_mu = M0[t, "8"] + GAPS[t])
}))
y <- read.csv("data/weekly/2026_week08_yahoo_matchups.csv", encoding = "UTF-8", stringsAsFactors = FALSE)
yy <- bind_rows(y |> transmute(team, yahoo_setlineup_proj = yahoo_team), y |> transmute(team = opponent, yahoo_setlineup_proj = yahoo_opp))
est <- est |> left_join(yy, by = "team")
options(width = 200); print(as.data.frame(est |> mutate(across(where(is.numeric), ~ round(.x, 1)))))
saveRDS(list(x = x, est = est), file.path(SC, "p4_redteam/wk8_est.rds"))
cat("\nSunday Kevin roster, wk8:\n"); print(as.data.frame(x |> filter(owner == "Sunday Kevin") |> select(player, pos, nfl, injury, proj, act)))
