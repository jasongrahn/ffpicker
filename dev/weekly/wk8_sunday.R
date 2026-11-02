# Wk8 after Sunday (MNF CHI @ SEA pending): actual pts for our + Michelle's rosters. Not the Yahoo score.
suppressMessages({library(dplyr)})
pkgload::load_all(".", quiet = TRUE)
source("dev/weekly/read_yahoo_week.R")
fs <- sprintf("docs/uploads/week_8_data/yahoo_week8_%s_2026-10-31.csv", c("qb","rb","wr","te","k","def"))
y  <- bind_rows(lapply(fs, read_yahoo_position)) |> distinct(player, yteam, .keep_all = TRUE)
OPP <- "Locked In Michelle"
r  <- attach_nfl_ids(y |> filter(owner %in% c("JGrahnasaurs", OPP)))
p  <- readRDS("data/nflreadr/pull_2026.rds")
ps <- p$player_stats |> filter(season_type == "REG", week == 8)
ps$fpts <- score_player_week(ps, load_config("scoring"))
# DST: Yahoo tiers from config; PA = opponent final score (approximation of Yahoo's PA)
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
nflab <- c(Was = "WAS", KC = "KC", Sea = "SEA")
r <- r |> left_join(ps |> select(player_id, fpts), by = c("gsis_id" = "player_id")) |>
  mutate(fpts = ifelse(pos == "DEF", dst$fpts[match(nflab[yteam], dst$team)], fpts),
         status = case_when(grepl("Mon", game) ~ "MNF", is.na(fpts) & pos != "DEF" ~ "0/DNP", TRUE ~ ""))
ours <- c("Kyler Murray","Javonte Williams","Derrick Henry","Ollie Gordon II","Denzel Boston","Tre Tucker","T.J. Hockenson","Jake Bates","Commanders")
guess <- c("Joe Burrow","Jahmyr Gibbs","Kyren Williams","Jordan Mason","George Pickens","Rashee Rice","Harold Fannin Jr.","Brandon Aubrey","Seahawks")
r <- r |> mutate(started = (owner == "JGrahnasaurs" & player %in% ours) | (owner == OPP & player %in% guess),
                 fpts = coalesce(fpts, 0), diff = fpts - proj)
cat("id method:", paste(names(table(r$method, useNA = "ifany")), table(r$method, useNA = "ifany"), collapse = "  "), "\n")
for (tm in c("JGrahnasaurs", OPP)) {
  d <- r |> filter(owner == tm) |> arrange(desc(started), pos, desc(fpts))
  cat(sprintf("\n== %s ==  started total %.2f (proj %.2f)%s\n", tm, sum(d$fpts[d$started]), sum(d$proj[d$started]),
              if (tm == OPP) "  [started = 10-29 proj-optimal GUESS; Love/Burrow unknown; SEA DEF = MNF]" else ""))
  print(as.data.frame(d |> transmute(S = ifelse(started, "*", ""), player, pos, yteam, proj, fpts = round(fpts, 2), diff = round(diff, 2), status)), row.names = FALSE)
}
