# A1 Q4: wk8 PROVISIONAL scores, all 10 teams. ESTIMATES -- Yahoo finals land Tue.
# Lineup = projection-optimal from the 10-31 Sat Yahoo pull (TNF rows still carry projections,
# log M1); replayed with nflreadr actuals (score_player_week) + DST approx (wk8_sunday.R method).
# MNF CHI @ SEA players scored AT PROJECTION, flagged. Us = actual started lineup (log M1).
# Michelle = also the 10-29 guess lineup (wk8_sunday.R). Pattern: dev/weekly/wk8_sunday.R.
suppressMessages({library(dplyr)})
pkgload::load_all(".", quiet = TRUE)
source("dev/weekly/read_yahoo_week.R")
OUT <- "docs/review/002-evidence/a1_luck"
ME <- "JGrahnasaurs"; MICH <- "Locked In Michelle"
sch <- read.csv("data/weekly/2026_league_schedule.csv", encoding = "UTF-8", stringsAsFactors = FALSE)
teams <- sort(unique(sch$team))
fs <- sprintf("docs/uploads/week_8_data/yahoo_week8_%s_2026-10-31.csv", c("qb","rb","wr","te","k","def"))
y  <- bind_rows(lapply(fs, read_yahoo_position)) |> distinct(player, yteam, .keep_all = TRUE)
r  <- attach_nfl_ids(y |> filter(owner %in% teams))
p  <- readRDS("data/nflreadr/pull_2026.rds")
ps <- p$player_stats |> filter(season_type == "REG", week == 8)
ps$fpts <- score_player_week(ps, load_config("scoring"))
sc <- load_config("scoring")$dst
pa_pts <- function(pa) sapply(pa, function(a) { if (is.na(a)) return(NA); for (t in sc$points_allowed) if (a <= t$max) return(t$points); NA })
s8 <- p$schedules |> filter(week == 8)
g  <- bind_rows(s8 |> transmute(team = home_team, pa = away_score, done = !is.na(result)),
                s8 |> transmute(team = away_team, pa = home_score, done = !is.na(result)))
ts <- p$team_stats |> filter(week == 8) |>
  transmute(team, sk = def_sacks, int = def_interceptions, fr = fumble_recovery_opp, td = def_tds + special_teams_tds,
            sf = def_safeties, blk = def_punt_blocks + def_fg_blocks + def_pat_blocks)
dst <- g |> left_join(ts, by = "team") |>
  mutate(fpts = ifelse(done, pa_pts(pa) + sc$sack*sk + sc$interception*int + sc$fumble_recovery*fr + 6*td + sc$safety*sf + sc$block_kick*blk, NA))
nfl_team <- function(y) recode(toupper(y), "LAR" = "LA")
ON8 <- c(s8$home_team, s8$away_team); MNF <- c("CHI", "SEA")
r <- r |> mutate(nfl = nfl_team(yteam))
stopifnot(all(r$nfl %in% c(ON8, "NYG", "HOU", "NO", "SF")))     # DEF map check (byes: NYG HOU NO SF)
r <- r |> left_join(ps |> select(player_id, fpts), by = c("gsis_id" = "player_id")) |>
  mutate(bye = !nfl %in% ON8, mnf = nfl %in% MNF,
         fpts = case_when(pos == "DEF" & !mnf ~ dst$fpts[match(nfl, dst$team)], TRUE ~ fpts),
         status = case_when(mnf ~ "MNF@proj", bye ~ "bye", is.na(fpts) & is.na(gsis_id) ~ "NOID", is.na(fpts) ~ "0/DNP", TRUE ~ ""),
         act = case_when(mnf ~ proj, bye ~ 0, TRUE ~ coalesce(fpts, 0)))
cat("id method:", paste(names(table(r$method, useNA = "ifany")), table(r$method, useNA = "ifany"), collapse = "  "), "\n")
cat("NOID rows (no gsis id, scored 0):\n"); print(as.data.frame(r |> filter(status == "NOID") |> select(player, pos, yteam, owner, proj)))
cat("TNF check (proj col must be projection, not points):\n")
print(as.data.frame(r |> filter(nfl %in% c("GB", "CAR")) |> select(player, pos, owner, proj, fpts) |> head(8)))

# legal lineups QB1 RB2 WR2 TE1 FLEX1 K1 DEF1 (no multi-pos rostered; checked)
lineups <- function(d) {
  d <- d |> filter(is.na(injury) | injury != "IR")
  ix <- function(p) which(d$pos == p)
  out <- list()
  for (qi in ix("QB")) for (ki in ix("K")) for (di in ix("DEF")) {
    rb <- ix("RB"); wr <- ix("WR"); te <- ix("TE")
    for (R2 in combn(rb, 2, simplify = FALSE)) for (W2 in combn(wr, 2, simplify = FALSE)) for (t1 in te)
      for (fx in setdiff(c(rb, wr, te), c(R2, W2, t1))) out[[length(out) + 1]] <- c(qi, ki, di, R2, W2, t1, fx)
  }
  m <- do.call(rbind, out)
  list(d = d, m = m, proj = apply(m, 1, function(i) sum(d$proj[i])), act = apply(m, 1, function(i) sum(d$act[i])),
       mnfsd = apply(m, 1, function(i) sqrt(sum(ifelse(d$mnf[i], ifelse(d$pos[i] == "DEF", 5, 7), 0)^2))))
}
ours <- c("Kyler Murray","Javonte Williams","Derrick Henry","Ollie Gordon II","Denzel Boston","Tre Tucker","T.J. Hockenson","Jake Bates","Commanders")
guess <- c("Joe Burrow","Jahmyr Gibbs","Kyren Williams","Jordan Mason","George Pickens","Rashee Rice","Harold Fannin Jr.","Brandon Aubrey","Seahawks")
res <- list(); lu <- list()
for (tm in teams) {
  L <- lineups(r |> filter(owner == tm))
  o <- which.max(L$proj); lu[[tm]] <- L$d[L$m[o, ], ] |> select(player, pos, nfl, injury, proj, act, status)
  band <- L$proj >= L$proj[o] - 5                                    # plausible: within 5 proj pts of optimal
  res[[tm]] <- tibble(team = tm, n_lineups = nrow(L$m), proj_opt = L$proj[o], act_opt = L$act[o],
                      mnf_sd = L$mnfsd[o], n_mnf = sum(L$d$mnf[L$m[o, ]]),
                      band_n = sum(band), band_min = min(L$act[band]), band_med = median(L$act[band]), band_max = max(L$act[band]),
                      hind_max = max(L$act))
}
res <- bind_rows(res)
# actual started lineups we know / guess
d_us <- r |> filter(owner == ME, player %in% ours); stopifnot(nrow(d_us) == 9)
d_mi <- r |> filter(owner == MICH, player %in% guess); stopifnot(nrow(d_mi) == 9)
love <- r |> filter(owner == MICH, grepl("Love", player), pos == "QB")
cat(sprintf("\nUS actual started: proj %.2f act %.2f | proj-opt (10-31) would be proj %.2f act %.2f\n",
            sum(d_us$proj), sum(d_us$act), res$proj_opt[res$team == ME], res$act_opt[res$team == ME]))
cat(sprintf("MICH guess lineup: proj %.2f act %.2f (Burrow %.2f); with Love (%s, act %.2f) instead: %.2f\n",
            sum(d_mi$proj), sum(d_mi$act), d_mi$act[d_mi$player == "Joe Burrow"], love$player[1], love$act[1],
            sum(d_mi$act) - d_mi$act[d_mi$player == "Joe Burrow"] + love$act[1]))

ym <- read.csv("data/weekly/2026_week08_yahoo_matchups.csv", encoding = "UTF-8", stringsAsFactors = FALSE)
fr <- read.csv("data/weekly/2026_week08_leaguewide_predictions.csv", encoding = "UTF-8", stringsAsFactors = FALSE)
yset <- bind_rows(ym |> transmute(team, yahoo_set = yahoo_team), ym |> transmute(team = opponent, yahoo_set = yahoo_opp))
ceil <- bind_rows(fr |> transmute(team, ceil = ceil_team), fr |> transmute(team = opponent, ceil = ceil_opp))
res <- res |> left_join(yset, by = "team") |> left_join(ceil, by = "team") |>
  mutate(est = case_when(team == ME ~ sum(d_us$act), TRUE ~ act_opt),
         set_short = proj_opt - yahoo_set)
cat("\n=== Per team (est = proj-opt replay; us = actual started) ===\n")
print(as.data.frame(res |> mutate(across(where(is.numeric), ~ round(.x, 2)))), row.names = FALSE)

# games: winner + confidence. Unc per team: lineup deviation sd LSD (wk7 real: actual - if-followed
# sd 13.1, n 10, vs Wed proj; 0 for us) + MNF players at proj (7/player, 5/DEF) + DST approx 2.
games <- sch |> filter(week == 8, team < opponent) |> select(a = team, b = opponent)
conf <- function(LSD) games |> rowwise() |> mutate(
  sa = res$est[res$team == a], sb = res$est[res$team == b], margin = sa - sb,
  sd = sqrt(sum(c(if (a == ME) 0 else LSD, if (b == ME) 0 else LSD,
                  res$mnf_sd[res$team == a], res$mnf_sd[res$team == b], 2, 2)^2)),
  p_a = pnorm(margin / sd), winner = ifelse(margin > 0, a, b)) |> ungroup()
for (L in c(0, 8, 13.1)) {
  cat(sprintf("\n--- games, lineup-deviation sd %.1f per non-us team ---\n", L))
  print(as.data.frame(conf(L) |> mutate(across(where(is.numeric), ~ round(.x, 3)))), row.names = FALSE)
}
cat("\nprojection-optimal lineups:\n")
for (tm in teams) { cat("\n#", tm, "\n"); print(as.data.frame(lu[[tm]]), row.names = FALSE) }
write.csv(res |> select(team, score = est, proj_opt, act_opt, yahoo_set, ceil, mnf_sd, n_mnf, band_min, band_max, hind_max),
          file.path(OUT, "q4_wk8_prov_scores.csv"), row.names = FALSE, fileEncoding = "UTF-8")
saveRDS(list(res = res, lu = lu, r = r), file.path(OUT, "q4_wk8_prov.rds"))
