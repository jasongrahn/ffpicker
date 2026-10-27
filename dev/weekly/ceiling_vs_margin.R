# Gate test (handoff #44 test #1). Does projection-optimal roster ceiling
# predict who WINS? Unit = matchup, all ten rosters. Scores every week with an
# EX entry AND Schedule-tab scores: wks 3-6 n = 20; wk7 joins (n = 25) once its
# scores are entered. Wk7 ceilings + P(win) were frozen pre-kickoff in
# data/weekly/2026_week07_leaguewide_predictions.csv.
# Outcome = actual started score from the Schedule tab
# (data/weekly/2026_league_schedule.csv), not reconstructed from exports --
# the exports carry no started/bench flag.
#
# TRAP: a Sat/Sun export lists games already "Final" or live ("Half",
# "Q2 0:11"), and for those players `Fantasy Fan Pts` is points SCORED, not a
# projection. Using it leaks the outcome into the predictor. So: rosters come
# from the late export (closest to kickoff); any player whose game had started
# takes his projection from the early export of the same week, which predates
# every kickoff (checked: wk3 Wed 20:20, wk4 Thu 18:53, wk5 Wed 08:34, wk6 Wed).
# Wk7 has no Sunday pull (user travelling): late = early = Wed 10-21, so
# weekend streaming adds are invisible that week -- same as wk6.
suppressMessages({library(dplyr)})
source("dev/weekly/read_yahoo_week.R")

U <- "docs/uploads"
EX <- list(  # week = c(late, early) file sets
  `3` = c(sprintf("%s/week_3_data/wk3_0927/yahoo_week3_%%s_2026-09-27.csv", U), sprintf("%s/week_3_data/yahoo_week3_%%s.csv", U)),
  `4` = c(sprintf("%s/week_4_data/yahoo_week4_%%s_2026-10-04.csv", U), sprintf("%s/week_4_data/yahoo_week4_%%s_2026-10-01.csv", U)),
  `5` = c(sprintf("%s/week_5_data/yahoo_week5_%%s_2026-10-11.csv", U), sprintf("%s/week_5_data/yahoo_week5_%%s_2026-10-07.csv", U)),
  `6` = c(sprintf("%s/week_6_data/yahoo_week6_%%s_2026-10-14.csv", U), sprintf("%s/week_6_data/yahoo_week6_%%s_2026-10-14.csv", U)),
  `7` = c(sprintf("%s/week_7_data/yahoo_week7_%%s_2026-10-21.csv", U), sprintf("%s/week_7_data/yahoo_week7_%%s_2026-10-21.csv", U)))
POS <- c("qb", "rb", "wr", "te", "k", "def")
read_set <- function(tmpl) bind_rows(lapply(POS, function(p) read_yahoo_position(sprintf(tmpl, p)))) |>
  distinct(player, yteam, .keep_all = TRUE) |>
  mutate(key = ifelse(pos == "DEF", paste0("DEF:", yteam), yahoo_id))
UNSTARTED <- "^(Sun|Mon|Tue|Wed|Thu|Fri|Sat) [0-9]+:[0-9]+ [ap]m"

optimal <- function(d) {   # same slot logic as dev/weekly/league_ceiling.R
  d <- d |> filter(is.na(injury) | !grepl("IR", injury)) |> arrange(desc(proj))
  take <- function(d, p, n) { s <- d |> filter(pos %in% p) |> head(n); list(s = s, rest = anti_join(d, s, by = "player")) }
  tot <- 0; r <- d
  for (sp in list(list("QB", 1), list("RB", 2), list("WR", 2), list("TE", 1), list("K", 1), list("DEF", 1))) {
    t <- take(r, sp[[1]], sp[[2]]); tot <- tot + sum(t$s$proj); r <- t$rest }
  tot + sum(take(r, c("RB", "WR", "TE"), 1)$s$proj)
}

sch <- read.csv("data/weekly/2026_league_schedule.csv", encoding = "UTF-8", stringsAsFactors = FALSE)
teams <- unique(sch$team)

ceil <- bind_rows(lapply(names(EX), function(w) {
  late <- read_set(EX[[w]][1]); early <- read_set(EX[[w]][2])
  started <- !is.na(late$game) & late$game != "" & !grepl(UNSTARTED, late$game)
  fix <- match(late$key[started], early$key)
  late$proj[started] <- ifelse(is.na(fix), late$proj[started], early$proj[fix])
  own <- setdiff(unique(late$owner), c("FA", grep("^W \\(", late$owner, value = TRUE)))
  stopifnot(setequal(own, teams), setequal(setdiff(unique(early$owner), c("FA", grep("^W \\(", early$owner, value = TRUE))), teams))
  cat(sprintf("wk%s: %d players in started games -> early proj (%d unmatched, kept late)\n",
              w, sum(started), sum(is.na(fix))))
  bind_rows(
    tibble(week = as.integer(w), team = teams, variant = "late_roster_clean_proj",
           ceiling = sapply(teams, function(t) optimal(late |> filter(owner == t)))),
    tibble(week = as.integer(w), team = teams, variant = "early_export_only",
           ceiling = sapply(teams, function(t) optimal(early |> filter(owner == t)))))
}))

SC <- intersect(as.integer(names(EX)), unique(sch$week[!is.na(sch$pf)]))   # scored weeks
cat(sprintf("scored weeks in the gate: %s (ceilings computed for %s)\n",
            paste(SC, collapse = ","), paste(names(EX), collapse = ",")))

# prior-weeks ppg as the naive rival predictor
ppg <- bind_rows(lapply(SC, function(w) sch |> filter(week < w) |> group_by(team) |>
  summarise(prior_ppg = mean(pf), .groups = "drop") |> mutate(week = w)))

mu <- sch |> filter(week %in% SC, team < opponent) |>
  transmute(week, team, opponent, margin = pf - pa)

score <- function(x, lab) {
  n <- nrow(x); fav <- sum(sign(x$diff) == sign(x$margin))
  ci <- binom.test(fav, n)$conf.int; ct <- cor.test(x$diff, x$margin)
  fit <- lm(margin ~ 0 + diff, data = x)
  cat(sprintf("%-26s n=%d  favourite wins %d/%d = %.0f%% [%.0f, %.0f]  r=%+.3f p=%.3f  slope %+.2f  resid sd %.1f\n",
              lab, n, fav, n, 100 * fav / n, 100 * ci[1], 100 * ci[2], ct$estimate, ct$p.value,
              coef(fit), summary(fit)$sigma))
  invisible(x)
}

cat(sprintf("\n=== GATE: does the predictor pick the winner? one row per matchup, wks %s ===\n",
            paste(SC, collapse = ",")))
for (v in unique(ceil$variant)) {
  c1 <- ceil |> filter(variant == v)
  x <- mu |> left_join(c1 |> select(week, team, c_t = ceiling), by = c("week", "team")) |>
    left_join(c1 |> select(week, team, c_o = ceiling), by = c("week", "opponent" = "team")) |>
    mutate(diff = c_t - c_o)
  score(x, v)
}
x <- mu |> left_join(ppg |> select(week, team, p_t = prior_ppg), by = c("week", "team")) |>
  left_join(ppg |> select(week, team, p_o = prior_ppg), by = c("week", "opponent" = "team")) |>
  mutate(diff = p_t - p_o)
score(x, "prior_ppg (rival)")

cat("\n=== calibration: actual started score vs clean ceiling, scored team-weeks ===\n")
cal <- sch |> filter(week %in% SC) |> select(week, team, pf) |>
  left_join(ceil |> filter(variant == "late_roster_clean_proj"), by = c("week", "team")) |>
  mutate(gap = pf - ceiling)
cat(sprintf("mean actual %.2f | mean ceiling %.2f | mean gap %+.2f | sd gap %.2f | n %d\n",
            mean(cal$pf), mean(cal$ceiling), mean(cal$gap), sd(cal$gap), nrow(cal)))
cat("weekly team-score sd (all 60 team-weeks, wks 1-6):", round(sd(sch$pf, na.rm = TRUE), 2), "\n")

cat("\n=== matchups, clean variant ===\n")
c1 <- ceil |> filter(variant == "late_roster_clean_proj")
print(as.data.frame(mu |> left_join(c1 |> select(week, team, c_t = ceiling), by = c("week", "team")) |>
  left_join(c1 |> select(week, team, c_o = ceiling), by = c("week", "opponent" = "team")) |>
  mutate(diff = round(c_t - c_o, 1), margin = round(margin, 1), fav_won = sign(diff) == sign(margin)) |>
  select(week, team, opponent, diff, margin, fav_won)))
saveRDS(ceil, "data/weekly/2026_ceilings.rds")   # every EX week, scored or not; league_sim.R reads it
