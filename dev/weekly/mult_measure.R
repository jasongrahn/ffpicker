# Rebuild the game-script multiplier table on 2024-25, and EXTEND it past the
# original dog3-7 / fav10+ edges. Week 5 2026 put a 7.0-pt-dog RB in the FLEX,
# a bucket the published table never covered.
# Method as originally specified: starter-calibre player-weeks, each player's
# points expressed RELATIVE TO HIS OWN SEASON AVERAGE so player quality cancels.
suppressMessages({library(dplyr)})

ps <- nflreadr::load_player_stats(c(2024, 2025)) |>
  filter(season_type == "REG") |>
  mutate(pts = 0.04*coalesce(passing_yards,0) + 4*coalesce(passing_tds,0) -
               1*coalesce(passing_interceptions,0) +
               0.1*(coalesce(rushing_yards,0)+coalesce(receiving_yards,0)) +
               6*(coalesce(rushing_tds,0)+coalesce(receiving_tds,0)) +
               0.5*coalesce(receptions,0),
         pos = position) |>
  filter(pos %in% c("RB","WR","QB"))

# starter-calibre: top 24 RB / 36 WR / 12 QB by season total, per season
rank_cut <- c(RB = 24, WR = 36, QB = 12)
keep <- ps |> group_by(season, pos, player_id) |>
  summarise(tot = sum(pts), g = n(), .groups = "drop") |>
  filter(g >= 8) |> group_by(season, pos) |>
  mutate(rk = rank(-tot)) |> ungroup() |>
  filter(rk <= rank_cut[pos]) |> select(season, player_id)

d <- ps |> inner_join(keep, by = c("season","player_id")) |>
  group_by(season, player_id) |> mutate(own_avg = mean(pts)) |> ungroup() |>
  filter(own_avg > 0) |> mutate(rel = pts / own_avg)

sch <- nflreadr::load_schedules(c(2024,2025)) |> filter(game_type == "REG")
tm <- bind_rows(
  sch |> transmute(season, week, team = home_team, fav =  spread_line, total_line),
  sch |> transmute(season, week, team = away_team, fav = -spread_line, total_line))

d <- d |> inner_join(tm, by = c("season","week","team"))

bucket <- function(f) cut(f,
  breaks = c(-Inf,-10,-7,-3,0,3,7,10,Inf),
  labels = c("dog10+","dog7-10","dog3-7","dog0-3","fav0-3","fav3-7","fav7-10","fav10+"),
  right = FALSE)
d$bkt <- bucket(d$fav)

cat("== multiplier = mean(points / own season average), 2024-25 ==\n")
cat("   starter-calibre only; n is player-weeks\n\n")
out <- d |> group_by(pos, bkt) |>
  summarise(n = n(), mult = mean(rel),
            se = sd(rel)/sqrt(n()), .groups = "drop") |>
  filter(n >= 20) |>
  mutate(lo = mult - 1.96*se, hi = mult + 1.96*se,
         sig = ifelse(lo > 1 | hi < 1, "*", ""))
print(as.data.frame(out |> transmute(pos, bucket = bkt, n,
  mult = round(mult,3), ci = sprintf("[%.3f, %.3f]", lo, hi), sig)), row.names = FALSE)

cat("\n== the question: RB as a deep underdog ==\n")
rb <- d |> filter(pos == "RB", fav < 0)
for (b in c("dog0-3","dog3-7","dog7-10","dog10+")) {
  s <- rb |> filter(bkt == b)
  if (nrow(s) >= 20) {
    tt <- t.test(s$rel, mu = 1)
    cat(sprintf("  %-9s n=%4d  mult %.3f  CI [%.3f, %.3f]  p=%.3f %s\n", b, nrow(s),
      mean(s$rel), tt$conf.int[1], tt$conf.int[2], tt$p.value,
      ifelse(tt$p.value < .05, "<- differs from 1.0", "")))
  }
}
cat("\n== is dog7-10 worse than dog3-7 for RBs? ==\n")
a <- rb$rel[rb$bkt=="dog3-7"]; b2 <- rb$rel[rb$bkt=="dog7-10"]
tt <- t.test(b2, a)
cat(sprintf("  dog7-10 (%.3f, n=%d) vs dog3-7 (%.3f, n=%d)\n", mean(b2), length(b2), mean(a), length(a)))
cat(sprintf("  diff %+.3f  p = %.3f  95%% CI [%+.3f, %+.3f]  -> %s\n",
  mean(b2)-mean(a), tt$p.value, tt$conf.int[1], tt$conf.int[2],
  ifelse(tt$p.value < .05, "REAL", "NOT DISTINGUISHABLE")))

cat("\n\n== better-powered framing: slope of (rel points) on favouredness ==\n")
cat("   bucket cells are tiny; the trend across ALL spreads uses every row.\n\n")
for (p in c("RB","WR","QB")) {
  s <- d |> filter(pos == p)
  m <- lm(rel ~ fav, s)
  co <- summary(m)$coefficients
  cat(sprintf("  %s  n=%4d  slope %+0.5f per point of spread  p = %.4f  %s\n",
    p, nrow(s), co["fav","Estimate"], co["fav","Pr(>|t|)"],
    ifelse(co["fav","Pr(>|t|)"] < .05, "<- REAL", "no trend")))
  cat(sprintf("       -> a 7-pt dog vs a neutral game: %+.1f%%\n",
    100*(co["fav","Estimate"] * -7)))
}

cat("\n== does the RB penalty differ from the WR penalty? (interaction) ==\n")
rw <- d |> filter(pos %in% c("RB","WR"))
mi <- lm(rel ~ fav * pos, rw)
co <- summary(mi)$coefficients
cat(sprintf("  fav:posWR interaction %+0.5f  p = %.4f -> %s\n",
  co["fav:posWR","Estimate"], co["fav:posWR","Pr(>|t|)"],
  ifelse(co["fav:posWR","Pr(>|t|)"] < .05,
         "RB and WR genuinely respond differently",
         "cannot distinguish RB from WR response")))
