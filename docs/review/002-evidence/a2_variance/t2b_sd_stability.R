# Task 2b: is a player's weekly sd AT EQUAL MEAN a stable trait? 2024-25 REG, starter-calibre.
# e = log(sd) - fit(log sd ~ pos + pos:log mean). Reliability: (1) odd vs even weeks within season
# (Spearman-Brown), (2) 2024 vs 2025 same player. Also: implied TRUE spread of sd at equal mean and
# what the best-case pick is worth to team sd.
A2 <- "docs/review/002-evidence/a2_variance"
suppressMessages(library(dplyr))
z <- readRDS(file.path(A2, "pw_2425.rds"))$ps
FLOOR <- c(QB = 14, RB = 8, WR = 7, TE = 5)
d <- z |> filter(position %in% names(FLOOR), position != "QB" | coalesce(attempts, 0) >= 10)
ser <- function(dd, key) dd |> group_by(across(all_of(key))) |>
  summarise(g = n(), m = mean(pts), s = sd(pts), tdsh = sum(6 * (rushing_tds + receiving_tds) + 4 * passing_tds, na.rm = TRUE) / sum(pts), .groups = "drop")
fitE <- function(x) { x <- x |> filter(m > 0, s > 0); f <- lm(log(s) ~ position + position:log(m), data = x); x$e <- resid(f); x }
# (1) split-half within season: odd vs even weeks, player x season (team-agnostic), >= 4 g each half, calibre on full season
full <- ser(d, c("season", "player_id", "position")) |> filter(g >= 8, m >= FLOOR[position])
sh <- d |> semi_join(full, by = c("season", "player_id")) |> mutate(half = ifelse(week %% 2 == 1, "odd", "even"))
h <- ser(sh, c("season", "player_id", "position", "half")) |> filter(g >= 4)
h <- bind_rows(lapply(split(h, h$half), fitE))
hw <- h |> select(season, player_id, position, half, e, m, s) |> tidyr::pivot_wider(names_from = half, values_from = c(e, m, s)) |> na.omit()
r_sh <- cor.test(hw$e_odd, hw$e_even)
sb <- function(r) 2 * r / (1 + r)
cat(sprintf("split-half (odd v even wks) e=log-sd resid: n %d player-seasons, r %.3f [%.3f, %.3f], Spearman-Brown full-season %.3f\n",
  nrow(hw), r_sh$estimate, r_sh$conf.int[1], r_sh$conf.int[2], sb(r_sh$estimate)))
for (p in names(FLOOR)) { q <- hw |> filter(position == p); if (nrow(q) > 10) { ct <- cor.test(q$e_odd, q$e_even)
  cat(sprintf("   %s n %3d r %+.3f [%+.3f, %+.3f]\n", p, nrow(q), ct$estimate, ct$conf.int[1], ct$conf.int[2])) } }
# CV version
hw <- hw |> mutate(cv_odd = s_odd / m_odd, cv_even = s_even / m_even)
ct <- cor.test(hw$cv_odd, hw$cv_even)
cat(sprintf("split-half raw CV: r %.3f [%.3f, %.3f]\n", ct$estimate, ct$conf.int[1], ct$conf.int[2]))
# (2) cross-season
fs <- fitE(full)
cs <- fs |> select(season, player_id, position, e, m, s, tdsh) |> tidyr::pivot_wider(names_from = season, values_from = c(e, m, s, tdsh)) |> na.omit()
ct2 <- cor.test(cs$e_2024, cs$e_2025)
cat(sprintf("\ncross-season 2024 -> 2025 e: n %d players, r %.3f [%.3f, %.3f]\n", nrow(cs), ct2$estimate, ct2$conf.int[1], ct2$conf.int[2]))
for (p in names(FLOOR)) { q <- cs |> filter(position == p); if (nrow(q) > 8) { ct <- cor.test(q$e_2024, q$e_2025)
  cat(sprintf("   %s n %3d r %+.3f [%+.3f, %+.3f]\n", p, nrow(q), ct$estimate, ct$conf.int[1], ct$conf.int[2])) } }
# true-score spread of e: cov across seasons (if stable) vs total var
cat(sprintf("var(e) per season %.4f / %.4f ; cov(e24,e25) %.4f -> true sd of log-sd at equal mean ~ %.3f\n",
  var(cs$e_2024), var(cs$e_2025), cov(cs$e_2024, cs$e_2025), sqrt(max(0, cov(cs$e_2024, cs$e_2025)))))
# does TD share of points predict next-season e? (a "boom-bust" proxy you could see in advance)
ct3 <- cor.test(cs$tdsh_2024, cs$e_2025)
cat(sprintf("TD share of pts 2024 -> e 2025: r %.3f [%.3f, %.3f]\n", ct3$estimate, ct3$conf.int[1], ct3$conf.int[2]))
ct4 <- cor.test(fs$tdsh, fs$e)
cat(sprintf("same-season TD share vs e (mechanical): r %.3f, n %d\n", ct4$estimate, nrow(fs)))
# sampling noise check: sd of sample sd at g games ~ s/sqrt(2(g-1)) -> var(log s) ~ 1/(2(g-1))
cat(sprintf("expected sampling var of log sd at median g %d: %.4f (vs observed var(e) %.4f)\n",
  median(full$g), 1 / (2 * (median(full$g) - 1)), var(fs$e)))
# best case: pick the +1 true-sd-of-e option over the -1 option, WR-like sd 7 -> team var gain
tsd <- sqrt(max(0, cov(cs$e_2024, cs$e_2025)))
for (k in c(1, 2)) { sa <- 7 * exp(k * tsd / 2); sb_ <- 7 * exp(-k * tsd / 2)
  dv <- sa^2 - sb_^2; cat(sprintf("best case, options %g true-sd apart in log-sd at player sd 7: dvar %.1f -> team sd 21.08 -> %.2f (+%.2f)\n",
  k, dv, sqrt(21.081^2 + dv), sqrt(21.081^2 + dv) - 21.081)) }
saveRDS(list(hw = hw, cs = cs, fs = fs), file.path(A2, "t2b_sd_stability.rds"))
