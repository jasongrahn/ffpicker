# Wire scan. RB/WR/TE ranked on opportunity, DEF on opponent implied total; owners from one
# Yahoo export set. Rules: CLAUDE.md § Roster decisions (opportunity = carries + targets,
# last 3 weeks, >= 5 opp/g bar; snap share for context) + ADR 0011 (DEF). K not ranked --
# K streaming retired (ADR 0011, dev/weekly/k_test.R).
#   TMPL=docs/uploads/week_8_data/yahoo_week8_%s_2026-10-28.csv WEEK=8 Rscript dev/weekly/wire_scan.R
# Default TMPL = wk7 actual exports of 10-27 (owners after MNF, before the Wed clear).
# `ypts` = Yahoo Fantasy Fan Pts: a projection on a clean pre-kickoff pull, points scored on
# an `_actual_` export. Needs data/nflreadr/pull_2026.rds fresh (pull_nflreadr.R).
# NA keys never join: a first draft let NA gsis_id match NA rows -> 58k-row blowup, no error.
suppressMessages({library(dplyr)})
source("dev/weekly/read_yahoo_week.R")
TMPL <- Sys.getenv("TMPL", "docs/uploads/week_7_data/yahoo_week7_%s_actual_2026-10-27.csv")
WEEK <- as.integer(Sys.getenv("WEEK", "8"))
X <- readRDS("data/nflreadr/pull_2026.rds")
avail <- function(o) o == "FA" | grepl("^W [(]", o)
nfl_team <- function(y) recode(toupper(y), "LAR" = "LA")

d <- bind_rows(lapply(c("rb", "wr", "te"), function(p) read_yahoo_position(sprintf(TMPL, p)))) |>
  distinct(player, yteam, .keep_all = TRUE) |>
  mutate(mine = grepl("JGrahnasaurs", owner), avail = avail(owner), ir = grepl("IR", coalesce(injury, "")))
d <- attach_nfl_ids(d)
n0 <- nrow(d)
L <- max(X$player_stats$week[X$player_stats$season_type == "REG"])
ps <- X$player_stats |> filter(season_type == "REG", !is.na(player_id)) |>
  mutate(opp = coalesce(carries, 0) + coalesce(targets, 0))
hist <- ps |> group_by(gsis_id = player_id) |>
  summarise(tm = last(team), opp_g = mean(opp), last3 = mean(opp[week > L - 3]),
            trend = mean(opp[week > L - 3]) - mean(opp[week <= L - 3]), .groups = "drop")
sn <- X$snaps |> filter(week > L - 3) |> group_by(pfr_id = pfr_player_id) |>
  summarise(snap3 = round(100 * mean(offense_pct)), .groups = "drop") |>
  inner_join(X$ids |> filter(!is.na(gsis_id), !is.na(pfr_id)) |> distinct(pfr_id, gsis_id), by = "pfr_id") |>
  group_by(gsis_id) |> summarise(snap3 = max(snap3), .groups = "drop")
sch <- X$schedules |> filter(game_type == "REG")
bye <- bind_rows(sch |> transmute(team = home_team, week), sch |> transmute(team = away_team, week)) |>
  group_by(team) |> summarise(bye = setdiff(1:18, week)[1], .groups = "drop")
d <- d |> left_join(hist, by = "gsis_id", na_matches = "never") |>
  left_join(sn, by = "gsis_id", na_matches = "never") |> left_join(bye, by = c("tm" = "team"))
stopifnot(nrow(d) == n0)
cat(sprintf("%s | opportunity wks %d-%d vs earlier | rows %d, history matched %d\n",
            TMPL, L - 2, L, n0, sum(!is.na(d$opp_g))))

cols <- function(x) x |> transmute(player, pos, tm, bye, inj = substr(coalesce(injury, ""), 1, 4),
  opp_g = round(opp_g, 1), last3 = round(last3, 1), trend = round(trend, 1), snap3, ypts = proj,
  owner = substr(owner, 1, 12))
cat("\n-- OURS (RB/WR/TE) --\n")
print(as.data.frame(cols(d |> filter(mine) |> arrange(pos, desc(last3)))), row.names = FALSE)
for (p in c("RB", "WR", "TE")) {
  cat(sprintf("\n-- best available %s (>= 5 opp/g, not IR), by last-3-wk opportunity --\n", p))
  print(as.data.frame(cols(d |> filter(avail, !ir, grepl(p, pos), coalesce(opp_g, 0) >= 5) |>
    arrange(desc(last3)) |> head(6))), row.names = FALSE)
}

# DEF never joins on name -- Team abbrev only (CLAUDE.md § Yahoo exports)
df <- read_yahoo_position(sprintf(TMPL, "def")) |> mutate(tm = nfl_team(yteam))
stopifnot(all(df$tm %in% c(sch$home_team, sch$away_team)), !anyDuplicated(df$tm))
s <- sch |> filter(week == WEEK)
g <- bind_rows(s |> transmute(tm = home_team, opp = away_team, opp_imp = total_line / 2 - spread_line / 2, kick = paste(weekday, gametime)),
               s |> transmute(tm = away_team, opp = home_team, opp_imp = total_line / 2 + spread_line / 2, kick = paste(weekday, gametime)))
cat(sprintf("\n-- DEF, wk%d, by opponent implied total (-0.40 DST pts per implied pt; bye teams omitted) --\n", WEEK))
print(as.data.frame(df |> inner_join(g, by = "tm") |> arrange(opp_imp) |>
  transmute(dst = player, tm, opp, opp_imp, kick, ypts = proj,
            owner = ifelse(avail(owner), paste("AVAIL", owner), substr(owner, 1, 20))) |> head(10)), row.names = FALSE)
