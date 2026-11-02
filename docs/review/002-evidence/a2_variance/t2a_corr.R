# Task 2a: player-week correlations of half-PPR pts, 2024-25 REG. Within-series demeaned
# (player x team x season), so the r is week-to-week co-movement, not "good offense" level effects.
# CI = cluster bootstrap over team-seasons (B 2000). Output a2_variance/t2a_corr.rds
A2 <- "docs/review/002-evidence/a2_variance"
suppressMessages(library(dplyr))
z <- readRDS(file.path(A2, "pw_2425.rds"))
FLOOR <- c(QB1 = 14, RB1 = 8, WR1 = 7, WR2 = 7, TE1 = 5, K1 = -Inf, DST = -Inf)
pw <- z$pw |> filter(role != "QB1" | coalesce(attempts, 0) >= 10) |>
  group_by(season, team, player_id) |> mutate(gq = n(), m = mean(pts), res = pts - m) |> ungroup() |>
  mutate(sc = gq >= 8 & m >= FLOOR[role])
dst <- z$dst |> group_by(season, team) |> mutate(m = mean(pts), res = pts - m, sc = TRUE, role = "DST") |> ungroup()
cat("starter-calibre series by role:\n"); print(pw |> distinct(season, team, player_id, role, sc) |> count(role, sc) |> tidyr::pivot_wider(names_from = sc, values_from = n))
sdr <- bind_rows(pw |> filter(sc), dst) |> group_by(role) |>
  summarise(n_pw = n(), mean_pts = mean(pts), sd_within = sqrt(sum(res^2) / (n() - n_distinct(paste(season, team, player_id)))),
            .groups = "drop")
cat("\nwithin-series sd (starter-calibre):\n"); print(as.data.frame(sdr), digits = 3)
R <- bind_rows(pw |> select(season, week, team, opp = opponent_team, role, res, pts, sc),
               dst |> select(season, week, team, opp, role, res, pts, sc))
pair <- function(ra, rb, opp = FALSE, sc_only = TRUE) {
  a <- R |> filter(role == ra, sc | !sc_only); b <- R |> filter(role == rb, sc | !sc_only)
  by <- if (opp) c("season", "week", "opp" = "team") else c("season", "week", "team")
  j <- inner_join(a, b, by = by, suffix = c("_a", "_b"), relationship = "many-to-many")
  if (opp) j$team <- j$opp
  j$cl <- paste(j$season, j$team)
  j
}
boot_r <- function(j, B = 2000) {
  cls <- unique(j$cl); idx <- split(seq_len(nrow(j)), j$cl)
  set.seed(1)
  bs <- replicate(B, { s <- unlist(idx[sample(cls, replace = TRUE)], use.names = FALSE); cor(j$res_a[s], j$res_b[s]) })
  quantile(bs, c(.025, .975))
}
spec <- tribble(~pair, ~ra, ~rb, ~opp,
  "QB1-WR1", "QB1", "WR1", FALSE, "QB1-WR2", "QB1", "WR2", FALSE, "QB1-TE1", "QB1", "TE1", FALSE,
  "QB1-RB1", "QB1", "RB1", FALSE, "WR1-WR2", "WR1", "WR2", FALSE, "WR1-TE1", "WR1", "TE1", FALSE,
  "RB1-ownDST", "RB1", "DST", FALSE, "QB1-ownDST", "QB1", "DST", FALSE, "K1-ownQB1", "K1", "QB1", FALSE,
  "QB1 v oppQB1", "QB1", "QB1", TRUE, "QB1 v oppWR1", "QB1", "WR1", TRUE, "DST v oppQB1", "DST", "QB1", TRUE,
  "DST v oppWR1", "DST", "WR1", TRUE, "DST v oppRB1", "DST", "RB1", TRUE, "RB1 v oppRB1", "RB1", "RB1", TRUE,
  "WR1 v oppWR1", "WR1", "WR1", TRUE)
out <- bind_rows(lapply(seq_len(nrow(spec)), function(i) {
  j <- pair(spec$ra[i], spec$rb[i], spec$opp[i])
  ci <- boot_r(j); ja <- pair(spec$ra[i], spec$rb[i], spec$opp[i], sc_only = FALSE)
  data.frame(pair = spec$pair[i], n = nrow(j), clusters = length(unique(j$cl)), r = cor(j$res_a, j$res_b),
             lo = ci[1], hi = ci[2], r_raw = cor(j$pts_a, j$pts_b), n_all = nrow(ja), r_all = cor(ja$res_a, ja$res_b))
}))
rownames(out) <- NULL
cat("\nr = within-series demeaned, starter-calibre; r_raw = raw pts; r_all = demeaned, no calibre filter\n")
print(out, digits = 3)
saveRDS(list(out = out, sdr = sdr), file.path(A2, "t2a_corr.rds"))
