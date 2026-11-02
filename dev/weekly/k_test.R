# K rule test (ADR 0011, K side): does a team's OWN implied total predict its kicker's
# points? 2026 REG weeks played so far, team-week level. K pts via score_player_week()
# (validated incl. FG bands) on load_player_stats(); implied totals from load_schedules().
# Reads the data/nflreadr/ cache -> run dev/weekly/pull_nflreadr.R first.
suppressMessages({library(dplyr)})
pkgload::load_all(".", quiet = TRUE)
X <- readRDS("data/nflreadr/pull_2026.rds")
sc <- load_config("scoring")
k <- X$player_stats |> filter(season_type == "REG", position == "K")
k$pts <- score_player_week(k, sc)
tw <- k |> group_by(team, week) |> summarise(pts = sum(pts), .groups = "drop")
s <- X$schedules |> filter(game_type == "REG", !is.na(result))
g <- bind_rows(s |> transmute(team = home_team, week, own = total_line / 2 + spread_line / 2, opp = total_line / 2 - spread_line / 2),
               s |> transmute(team = away_team, week, own = total_line / 2 - spread_line / 2, opp = total_line / 2 + spread_line / 2))
x <- tw |> inner_join(g, by = c("team", "week"))
cat(sprintf("team-weeks: %d (games played: %d x2), wks %d-%d\n", nrow(x), nrow(s), min(x$week), max(x$week)))
ct <- cor.test(x$pts, x$own); fit <- lm(pts ~ own, x)
cat(sprintf("own implied -> K pts: r %+.3f, p %.4f, CI [%+.3f, %+.3f], slope %+.3f pts per implied pt\n",
            ct$estimate, ct$p.value, ct$conf.int[1], ct$conf.int[2], coef(fit)[["own"]]))
cat(sprintf("K pts mean %.2f sd %.2f | own implied sd %.2f | R2 %.3f\n", mean(x$pts), sd(x$pts), sd(x$own), summary(fit)$r.squared))
ct2 <- cor.test(x$pts, x$opp)
cat(sprintf("opp implied -> K pts (control): r %+.3f, p %.3f\n", ct2$estimate, ct2$p.value))
x <- x |> group_by(week) |> mutate(top8 = rank(-own, ties.method = "first") <= 8) |> ungroup()
cat(sprintf("rule edge: top-8 own implied each week %.2f vs all %.2f -> %+.2f pts/wk\n",
            mean(x$pts[x$top8]), mean(x$pts), mean(x$pts[x$top8]) - mean(x$pts)))
