# A1 Q5: calibration of frozen predictions wk7 + wk8 (wk8 outcomes PROVISIONAL, q4), T4 (Yahoo set-lineup
# margin vs ceiling margin, wk8 n 5), and the actual - ceiling gap: ours vs the league's, team effect test.
suppressMessages({library(dplyr)})
OUT <- "docs/review/002-evidence/a1_luck"
ME <- "JGrahnasaurs"; SIG <- 21.08
q2 <- readRDS(file.path(OUT, "q2_decomp.rds")); d <- q2$d
pr <- bind_rows(read.csv("data/weekly/2026_week07_leaguewide_predictions.csv", encoding = "UTF-8", stringsAsFactors = FALSE),
                read.csv("data/weekly/2026_week08_leaguewide_predictions.csv", encoding = "UTF-8", stringsAsFactors = FALSE)) |>
  left_join(d |> select(week, team, pf, pa, margin), by = c("week", "team")) |> mutate(y = as.numeric(margin > 0))
# wk8 outcome uncertainty (q4, lineup sd 13.1): P(team a wins) for the 2 open games; others ~certain
p_open <- c("Max’s TD Bombers" = 0.432, "Jason's Jazzy Team" = 0.371, "Dave’s Bone Crushers" = 0.091, "Monday Night Madison" = 0.045, "JGrahnasaurs" = 0)
pr <- pr |> mutate(p_y = ifelse(week == 8, p_open[team], y),          # P(y = 1) given what we know now
                   brier = (p_team_win - y)^2,
                   brier_exp = p_y * (1 - p_team_win)^2 + (1 - p_y) * p_team_win^2,
                   logloss = -(y * log(p_team_win) + (1 - y) * log(1 - p_team_win)),
                   fav_right = (p_team_win > 0.5) == (y == 1), p_fav = pmax(p_team_win, 1 - p_team_win))
print(as.data.frame(pr |> select(week, team, opponent, pred_margin, p_team_win, margin, y, p_y, brier, brier_exp, fav_right) |>
                      mutate(across(where(is.numeric), ~ round(.x, 3)))), row.names = FALSE)
for (wk in list(7, 8, 7:8)) {
  x <- pr |> filter(week %in% wk)
  cat(sprintf("wks %s: n %d | Brier %.3f (exp-over-wk8-uncertainty %.3f; coin flip 0.250; model's own expected %.3f) | logloss %.3f | favs right %d vs exp %.2f\n",
              paste(range(wk), collapse = "-"), nrow(x), mean(x$brier), mean(x$brier_exp),
              mean(x$p_team_win * (1 - x$p_team_win)), mean(x$logloss), sum(x$fav_right), sum(x$p_fav)))
}
# Murphy-style check: is the model under-confident (too many favourites right)? binomial on 10
x <- pr; cat(sprintf("P(>= %d of 10 favs right | model calibrated) ~ %.3f (Poisson-binomial sim)\n", sum(x$fav_right),
  mean(replicate(20000, sum(runif(10) < x$p_fav)) >= sum(x$fav_right))))

# T4: wk8 Yahoo set-lineup margin vs ceiling margin
ym <- read.csv("data/weekly/2026_week08_yahoo_matchups.csv", encoding = "UTF-8", stringsAsFactors = FALSE)
t4 <- pr |> filter(week == 8) |> left_join(ym |> select(team, yahoo_margin), by = "team") |>
  mutate(err_yahoo = margin - yahoo_margin, err_ceil = margin - pred_margin)
cat("\nT4 wk8 (actual margins PROVISIONAL; us-Michelle uses Burrow 139.12):\n")
print(as.data.frame(t4 |> select(team, opponent, margin, yahoo_margin, pred_margin, err_yahoo, err_ceil) |> mutate(across(where(is.numeric), ~ round(.x, 2)))), row.names = FALSE)
cat(sprintf("MAE yahoo %.2f vs ceiling %.2f (n 5); with Michelle-Love 119.16: yahoo %.2f vs ceiling %.2f\n",
            mean(abs(t4$err_yahoo)), mean(abs(t4$err_ceil)),
            mean(abs(replace(t4$err_yahoo, t4$team == ME, -31.66 + 5.06))), mean(abs(replace(t4$err_ceil, t4$team == ME, -31.66 + 13.74)))))
cat(sprintf("Yahoo-implied P(us win) wk8 = %.3f (margin -5.06, sd %.1f*sqrt2) vs model 0.322; result L by 31.7-51.6\n",
            pnorm(-5.06 / (sqrt(2) * 21.1)), 21.1))

# Gap: actual - ceiling, ours vs league, per week
gp <- d |> filter(!is.na(ceiling)) |> mutate(gap_ac = pf - ceiling)
wk <- gp |> group_by(week) |> summarise(league_mean = mean(gap_ac), league_sd = sd(gap_ac), us = gap_ac[team == ME],
                                        us_rank = rank(-gap_ac)[team == ME], .groups = "drop")
cat("\nactual - ceiling by week (wk8 non-us PROVISIONAL replay of proj-opt lineups):\n"); print(as.data.frame(wk |> mutate(across(where(is.numeric), ~ round(.x, 2)))), row.names = FALSE)
for (ws in list(3:7, 3:8)) {
  u <- gp |> filter(team == ME, week %in% ws); l <- gp |> filter(week %in% ws)
  z <- (mean(u$gap_ac) - (-4.24)) / (SIG / sqrt(nrow(u)))
  cat(sprintf("wks %d-%d: ours mean %.2f (n %d) vs uniform -4.24 -> diff %.2f, z %.2f, p %.2f | league mean %.2f (n %d)\n",
              min(ws), max(ws), mean(u$gap_ac), nrow(u), mean(u$gap_ac) + 4.24, z, 2 * pnorm(-abs(z)), mean(l$gap_ac), nrow(l)))
  a <- anova(lm(gap_ac ~ team, data = l)); cat(sprintf("  team effect on gap (one-way ANOVA): F %.2f, df %d/%d, p %.3f\n", a$`F value`[1], a$Df[1], a$Df[2], a$`Pr(>F)`[1]))
  tg <- l |> group_by(team) |> summarise(g = mean(gap_ac), se2 = var(gap_ac) / n(), n = n(), .groups = "drop")
  tau2 <- max(0, var(tg$g) - mean(tg$se2))
  # bootstrap TAU2 (resample weeks within team)
  set.seed(1); bt <- replicate(2000, { b <- l |> group_by(team) |> slice_sample(prop = 1, replace = TRUE) |> summarise(g = mean(gap_ac), se2 = var(gap_ac) / n(), .groups = "drop"); max(0, var(b$g) - mean(b$se2)) })
  cat(sprintf("  TAU2 %.1f (sd %.1f/wk); bootstrap 90%% CI [%.1f, %.1f]; P(TAU2 = 0) %.2f\n", tau2, sqrt(tau2), quantile(bt, .05), quantile(bt, .95), mean(bt == 0)))
  print(as.data.frame(tg |> arrange(g) |> mutate(across(where(is.numeric), ~ round(.x, 2)))), row.names = FALSE)
}
