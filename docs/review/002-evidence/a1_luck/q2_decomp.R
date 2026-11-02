# A1 Q2: decompose each of our games: margin = roster gap (our ceil - their ceil) + our miss (act - ceil)
# - their spike (act - ceil). Ceilings: 2026_ceilings.rds late_roster_clean_proj wks 3-7; wk8 frozen
# predictions csv. Wks 1-2: no league ceilings -> our side only (started-lineup proj, myteam csv).
# Wk8 actuals: us 87.50 (nflreadr, actual lineup), others = q4 provisional replay. Wk4 opp = 123.98 (Yahoo).
suppressMessages({library(dplyr)})
OUT <- "docs/review/002-evidence/a1_luck"
ME <- "JGrahnasaurs"; SIG <- 21.08
sch <- read.csv("data/weekly/2026_league_schedule.csv", encoding = "UTF-8", stringsAsFactors = FALSE)
cl <- readRDS("data/weekly/2026_ceilings.rds") |> filter(variant == "late_roster_clean_proj") |> select(week, team, ceiling)
fr <- read.csv("data/weekly/2026_week08_leaguewide_predictions.csv", encoding = "UTF-8", stringsAsFactors = FALSE)
c8 <- bind_rows(fr |> transmute(week, team, ceiling = ceil_team), fr |> transmute(week, team = opponent, ceiling = ceil_opp))
pv <- read.csv(file.path(OUT, "q4_wk8_prov_scores.csv"), encoding = "UTF-8", stringsAsFactors = FALSE)
s8 <- sch |> filter(week == 8) |> select(week, team, opponent) |>
  left_join(pv |> select(team, pf = score), by = "team") |> left_join(pv |> select(opponent = team, pa = score), by = "opponent") |>
  mutate(result = ifelse(pf > pa, "W", "L"))
d <- bind_rows(sch |> filter(!is.na(pf)) |> select(week, team, opponent, pf, pa, result), s8) |>
  left_join(bind_rows(cl, c8), by = c("week", "team")) |>
  left_join(bind_rows(cl, c8) |> rename(opponent = team, ceil_opp = ceiling), by = c("week", "opponent")) |>
  mutate(margin = pf - pa, gap = ceiling - ceil_opp, our_miss = pf - ceiling, their_spike = pa - ceil_opp,
         p_win_pre = pnorm(gap / (sqrt(2) * SIG)))
stopifnot(all(abs(d$margin - (d$gap + d$our_miss - d$their_spike)) < 1e-9 | is.na(d$gap)))

# --- our games
my1 <- read.csv("data/weekly/2026_week01_myteam.csv"); my2 <- read.csv("data/weekly/2026_week02_myteam.csv")
proj12 <- c(`1` = sum(my1$proj[my1$started]), `2` = sum(my2$proj[my2$started]))
us <- d |> filter(team == ME) |> mutate(our_proj_started = ifelse(week <= 2, proj12[as.character(week)], NA),
                                        miss_vs_started_proj = pf - our_proj_started)
regret <- c(19.76, 2.50, 25.06, 27.10, 23.30, 3.40, 4.70, NA)
hind <- c(121.56, 155.08, 133.80, 120.10, 130.32, 95.08, 104.00, NA)
us$hindsight_opt <- hind[us$week]; us$hind_minus_opp <- us$hindsight_opt - us$pa
cat("=== Our games (wk8 = PROVISIONAL; wk4 opp = Yahoo 123.98) ===\n")
print(as.data.frame(us |> select(week, opponent, pf, pa, result, margin, ceiling, ceil_opp, gap, our_miss, their_spike,
                                 p_win_pre, our_proj_started, miss_vs_started_proj, hindsight_opt, hind_minus_opp) |>
                      mutate(across(where(is.numeric), ~ round(.x, 2)))), row.names = FALSE)
u <- us |> filter(!is.na(gap))
cat(sprintf("\nWks 3-8 (n %d): sum margin %.2f = sum gap %.2f + sum our_miss %.2f - sum their_spike %.2f\n",
            nrow(u), sum(u$margin), sum(u$gap), sum(u$our_miss), sum(u$their_spike)))
cat(sprintf("  noise net (our_miss - their_spike) %.2f; mean gap %.2f/wk; mean our_miss %.2f; mean their_spike %.2f\n",
            sum(u$our_miss - u$their_spike), mean(u$gap), mean(u$our_miss), mean(u$their_spike)))
cat(sprintf("  roster-expected wins (sum p_win_pre, sd %.2f*sqrt2) %.2f vs actual %d -> luck %+.2f\n",
            SIG, sum(u$p_win_pre), sum(u$result == "W"), sum(u$result == "W") - sum(u$p_win_pre)))
cat(sprintf("  games where gap sign == result: %d of %d\n", sum(sign(u$gap) == sign(u$margin)), nrow(u)))
cat(sprintf("  Wks 3-7 only (Yahoo finals): roster-exp W %.2f vs actual %d\n",
            sum(u$p_win_pre[u$week <= 7]), sum(u$result[u$week <= 7] == "W")))
# variance shares for our 6 games
cat(sprintf("  our games var(margin) %.1f | var(gap) %.1f | var(noise) %.1f | cov*2 %.1f\n",
            var(u$margin), var(u$gap), var(u$our_miss - u$their_spike), 2 * cov(u$gap, u$our_miss - u$their_spike)))

# --- league-wide: how much of each result is roster vs noise (one row per game)
g <- d |> filter(!is.na(gap), team < opponent)
for (wk in list(3:7, 3:8)) {
  gg <- g |> filter(week %in% wk); noise <- gg$our_miss - gg$their_spike
  f <- lm(margin ~ gap, data = gg); ct <- cor.test(gg$margin, gg$gap)
  cat(sprintf("\nLeague games wks %d-%d (n %d%s): r %.3f (p %.4f), R2 %.3f, slope %.2f, resid sd %.1f\n",
              min(wk), max(wk), nrow(gg), if (8 %in% wk) ", wk8 PROVISIONAL" else "", ct$estimate, ct$p.value,
              summary(f)$r.squared, coef(f)[2], summary(f)$sigma))
  cat(sprintf("  var(margin) %.0f = var(gap) %.0f + var(noise) %.0f + 2cov %.0f -> roster share of variance %.0f%%\n",
              var(gg$margin), var(gg$gap), var(noise), 2 * cov(gg$gap, noise), 100 * var(gg$gap) / var(gg$margin)))
  cat(sprintf("  favourite (by ceiling) won %d of %d; expected %.2f (normal, sd %.2f*sqrt2)\n",
              sum(sign(gg$gap) == sign(gg$margin)), nrow(gg), sum(pnorm(abs(gg$gap) / (sqrt(2) * SIG))), SIG))
  cat(sprintf("  |gap| mean %.1f vs |noise| mean %.1f\n", mean(abs(gg$gap)), mean(abs(noise))))
}
# per-team roster-expected wins wks 3-7 vs actual (luck vs roster league-wide, Yahoo finals only)
tw <- d |> filter(!is.na(gap), week <= 7) |> group_by(team) |>
  summarise(n = n(), W = sum(result == "W"), expW_roster = sum(p_win_pre), mean_gap = mean(gap), mean_ceil = mean(ceiling),
            mean_miss = mean(our_miss), mean_opp_spike = mean(their_spike), .groups = "drop") |>
  mutate(luck_roster = W - expW_roster) |> arrange(desc(mean_ceil))
cat("\nPer team wks 3-7: roster-expected wins (pre-game ceiling P(win)) vs actual:\n")
print(as.data.frame(tw |> mutate(across(where(is.numeric), ~ round(.x, 2)))), row.names = FALSE)
saveRDS(list(d = d, us = us), file.path(OUT, "q2_decomp.rds"))
