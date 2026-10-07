# Test: does opponent implied total predict DST fantasy points?
# League-wide, all 32 teams, weeks 1-4 of 2026. DST points derived from
# nflreadr team stats + config/scoring.json tiers (score_player_week() is
# per-player only, so DST is computed here).
suppressMessages({library(dplyr)})

ts <- nflreadr::load_team_stats(2026, summary_level = "week") |>
  filter(season_type == "REG", week <= 4)

sch <- nflreadr::load_schedules(2026) |>
  filter(season == 2026, game_type == "REG", week <= 4) |>
  select(week, home_team, away_team, home_score, away_score, spread_line, total_line)

# one row per team-week: own team, opponent, points allowed, own implied, opp implied
# spread_line POSITIVE = HOME favored
long <- bind_rows(
  sch |> transmute(week, team = home_team, opp = away_team,
                   pts_allowed = away_score,
                   own_implied = total_line/2 + spread_line/2,
                   opp_implied = total_line/2 - spread_line/2),
  sch |> transmute(week, team = away_team, opp = home_team,
                   pts_allowed = home_score,
                   own_implied = total_line/2 - spread_line/2,
                   opp_implied = total_line/2 + spread_line/2))

tier <- function(pa) dplyr::case_when(
  pa <= 0 ~ 10, pa <= 6 ~ 7, pa <= 13 ~ 4, pa <= 20 ~ 1,
  pa <= 27 ~ 0, pa <= 34 ~ -1, TRUE ~ -4)

d <- ts |>
  transmute(week, team,
            sacks = def_sacks, ints = def_interceptions,
            fr    = fumble_recovery_opp,
            saf   = def_safeties,
            blk   = def_punt_blocks + def_pat_blocks + def_fg_blocks,
            rtd   = def_tds + special_teams_tds) |>
  inner_join(long, by = c("week", "team")) |>
  mutate(dst_pts = 1*sacks + 2*ints + 2*fr + 2*saf + 2*blk + 6*rtd + tier(pts_allowed))

cat("== n team-weeks:", nrow(d), " weeks:", paste(sort(unique(d$week)), collapse=","), "\n")
cat("   mean DST pts:", round(mean(d$dst_pts),2),
    "  sd:", round(sd(d$dst_pts),2), "\n\n")

cat("== correlation of DST points with each signal ==\n")
for (v in c("opp_implied","own_implied","pts_allowed")) {
  r <- cor(d$dst_pts, d[[v]], use="complete.obs")
  ct <- cor.test(d$dst_pts, d[[v]])
  cat(sprintf("  %-12s r = %+.3f   p = %.4f   95%% CI [%+.3f, %+.3f]\n",
      v, r, ct$p.value, ct$conf.int[1], ct$conf.int[2]))
}

cat("\n== DST points by opponent-implied-total quartile ==\n")
d2 <- d |> filter(!is.na(opp_implied)) |>
  mutate(q = dplyr::ntile(opp_implied, 4))
print(d2 |> group_by(q) |>
  summarise(opp_imp_range = sprintf("%.1f-%.1f", min(opp_implied), max(opp_implied)),
            n = n(), mean_dst = round(mean(dst_pts),2),
            sd = round(sd(dst_pts),2), .groups="drop") |> as.data.frame(), row.names=FALSE)

cat("\n== decision test: pick lowest-opp-implied DST each week vs league mean ==\n")
pick <- d2 |> group_by(week) |> arrange(opp_implied, .by_group=TRUE) |>
  summarise(best_by_rule = team[1], pts_rule = dst_pts[1],
            wk_mean = round(mean(dst_pts),2),
            wk_best = max(dst_pts), .groups="drop")
print(as.data.frame(pick), row.names=FALSE)
cat(sprintf("\n  rule mean %.2f vs league mean %.2f  -> edge %+.2f pts/wk\n",
    mean(pick$pts_rule), mean(pick$wk_mean), mean(pick$pts_rule - pick$wk_mean)))
cat(sprintf("  rule captures %.0f%% of the weekly best (%.2f of %.2f)\n",
    100*mean(pick$pts_rule)/mean(pick$wk_best), mean(pick$pts_rule), mean(pick$wk_best)))

# how many top-5 DST weeks would the rule have caught?
top5 <- d2 |> group_by(week) |> mutate(rk_actual = rank(-dst_pts),
                                       rk_rule = rank(opp_implied)) |> ungroup()
cat(sprintf("\n  Spearman(opp_implied, -dst_pts) within week: %+.3f\n",
    cor(top5$rk_rule, top5$rk_actual, method="spearman")))

cat("\n\n== is the non-monotonic q1<q2 real, or noise? ==\n")
q1 <- d2$dst_pts[d2$q==1]; q2 <- d2$dst_pts[d2$q==2]
tt <- t.test(q2, q1)
cat(sprintf("  q2 - q1 = %+.2f   p = %.3f   95%% CI [%+.2f, %+.2f]  -> %s\n",
    mean(q2)-mean(q1), tt$p.value, tt$conf.int[1], tt$conf.int[2],
    ifelse(tt$p.value < .05, "REAL", "NOISE, do not act on it")))

cat("\n== does game total add anything on top of opponent implied? ==\n")
d3 <- d2 |> mutate(total = own_implied + opp_implied)
m1 <- lm(dst_pts ~ opp_implied, d3)
m2 <- lm(dst_pts ~ opp_implied + total, d3)
cat(sprintf("  opp_implied alone      adj R2 = %.4f\n", summary(m1)$adj.r.squared))
cat(sprintf("  + game total           adj R2 = %.4f\n", summary(m2)$adj.r.squared))
cat(sprintf("  total coefficient p = %.3f -> %s\n",
    summary(m2)$coefficients["total","Pr(>|t|)"],
    ifelse(summary(m2)$coefficients["total","Pr(>|t|)"] < .05, "keep", "drop it")))

cat("\n== how much of DST points is predictable at all? ==\n")
cat(sprintf("  opp_implied explains %.1f%% of variance. The other %.1f%% is\n",
    100*summary(m1)$r.squared, 100*(1-summary(m1)$r.squared)))
cat("  turnovers and return TDs, which are not forecastable.\n")
cat(sprintf("  sd of DST pts = %.2f, so a %.2f pt edge is %.2f sd. Expect\n",
    sd(d3$dst_pts), 1.92, 1.92/sd(d3$dst_pts)))
cat("  the rule to look wrong in individual weeks and still be right.\n")
