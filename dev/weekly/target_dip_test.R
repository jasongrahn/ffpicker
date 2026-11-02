# T2 calibration (2026_week08_decisions.md §5): does a WR's target-share dip persist?
# Event = established WR (season-to-date share 18-26%, >= 4 games), then two straight games
# under 15%. Outcome = mean share over his next 3 games. All NFL WRs, 2024-25 REG.
# Games played come from snap counts (offense_snaps > 0) -> a 0-target game counts as 0, not
# as a missing row. Then: Burden's wks 9-11 share, and P(§6 kill fires), for each wk8 value.
suppressMessages({library(dplyr)})
X   <- readRDS("data/nflreadr/pull_2026.rds")
ids <- X$ids |> filter(!is.na(pfr_id), !is.na(gsis_id)) |> distinct(pfr_id, .keep_all = TRUE) |>
  select(pfr_id, gsis_id)

shares <- function(sn, ps) {
  sn <- sn |> filter(game_type == "REG", position == "WR", offense_snaps > 0)
  d <- sn |> left_join(ids, by = c("pfr_player_id" = "pfr_id"))
  cat(sprintf("WR-games %d | pfr -> gsis matched %.1f%%\n", nrow(d), 100 * mean(!is.na(d$gsis_id))))
  d |> filter(!is.na(gsis_id)) |>
    left_join(ps |> filter(season_type == "REG") |> select(player_id, season, week, targets, target_share),
              by = c("gsis_id" = "player_id", "season", "week")) |>
    mutate(share = coalesce(target_share, 0)) |>
    select(pid = gsis_id, player, season, week, team, offense_pct, share)
}

S <- c(2024, 2025)
h <- shares(nflreadr::load_snap_counts(S), nflreadr::load_player_stats(S))
stopifnot(!anyDuplicated(h[c("pid", "season", "week")]))

h <- h |> arrange(pid, season, week) |> group_by(pid, season) |>
  mutate(i = row_number(), cs = cumsum(share), prior = lag(cs, 2) / (i - 2),
         s1 = lag(share), s2 = share,
         nx1 = lead(share, 1), nx2 = lead(share, 2), nx3 = lead(share, 3)) |>
  ungroup() |>
  mutate(next3 = (nx1 + nx2 + nx3) / 3, kill = (s2 + nx1 + nx2) / 3 < 0.15) |>
  filter(i >= 6, !is.na(next3))

boot <- function(x, pid, f, B = 2000) {
  set.seed(20261030); u <- unique(pid); idx <- split(seq_along(x), pid)
  v <- replicate(B, f(x[unlist(idx[sample(u, length(u), TRUE)], use.names = FALSE)]))
  quantile(v, c(0.025, 0.975))
}
band <- h |> filter(prior >= 0.18, prior <= 0.26)
grp <- band |> mutate(g = case_when(s1 < 0.15 & s2 < 0.15 ~ "2 straight < 15%",
                                    s2 < 0.15             ~ "last game < 15% only",
                                    TRUE                  ~ "no dip"))
cat("\n== WRs with season-to-date share 18-26% (Burden 22%), 2024-25 REG\n")
for (k in c("2 straight < 15%", "last game < 15% only", "no dip")) {
  x <- grp |> filter(g == k)
  m  <- boot(x$next3, x$pid, mean); p <- boot(x$next3 < 0.15, x$pid, mean)
  cat(sprintf("%-22s n %4d (%3d players) | next-3 share %.1f%% [%.1f, %.1f] | P(next 3 < 15%%) %2.0f%% [%2.0f, %2.0f]\n",
              k, nrow(x), n_distinct(x$pid), 100 * mean(x$next3), 100 * m[1], 100 * m[2],
              100 * mean(x$next3 < 0.15), 100 * p[1], 100 * p[2]))
}

# How much do the last two games count against the season-to-date share?
r  <- h |> filter(prior >= 0.12, prior <= 0.32)
fit <- lm(next3 ~ prior + s1 + s2, r)
cb  <- t(replicate(500, { u <- unique(r$pid); s <- sample(u, length(u), TRUE)
  rr <- bind_rows(lapply(split(r, r$pid)[s], identity)); coef(lm(next3 ~ prior + s1 + s2, rr)) }))
cat(sprintf("\n== next-3 share ~ season-to-date + last 2 games (WRs at 12-32%%, n %d)\n", nrow(r)))
print(round(cbind(est = coef(fit), lo = apply(cb, 2, quantile, 0.025), hi = apply(cb, 2, quantile, 0.975)), 3))
lk <- glm(kill ~ prior + s1 + s2, binomial, r)
lu <- glm(I(next3 < 0.15) ~ prior + s1 + s2, binomial, r)

# Burden: 2026 shares from the same join
b <- shares(X$snaps |> filter(season == 2026), X$player_stats) |>
  filter(grepl("^Luther Burden", player)) |> arrange(week)
stopifnot(nrow(b) == 7)
cat("\nBurden 2026 wk1-7 share:", paste0(round(100 * b$share), "%", collapse = " "), "\n")
sc <- tibble(prior = mean(b$share[1:6]), s1 = b$share[7], s2 = c(0, 0.05, 0.08, 0.10, 0.13, 0.15, 0.20, 0.25))
sc$wk9_11_share <- predict(fit, sc)
sc$p_wk9_11_under15 <- predict(lu, sc, type = "response")
sc$p_kill_wk8_10 <- predict(lk, sc, type = "response")
cat(sprintf("== Burden by wk8 share (season-to-date wks 1-6 %.1f%%, wk7 %.1f%%)\n", 100 * sc$prior[1], 100 * sc$s1[1]))
print(as.data.frame(sc |> transmute(wk8 = sprintf("%2.0f%%", 100 * s2),
  wk9_11_share = sprintf("%.1f%%", 100 * wk9_11_share),
  P_wk9_11_under_15 = sprintf("%2.0f%%", 100 * p_wk9_11_under15),
  P_kill_fires_wk8_10 = sprintf("%2.0f%%", 100 * p_kill_wk8_10))), row.names = FALSE)
