# Playoff odds + leverage per remaining game (handoff #44 test #2). Scored in
# WINS, per `win-by-one-not-points`. Machinery and assumptions: league_sim.R.
# Sensitivities: BASE=latest, GAPMODE=shrunk (env vars).
source("dev/weekly/league_sim.R")

M0 <- strength_matrix(R)
s0 <- simulate(M0); s6 <- simulate(M0, tau = 6)
me <- match(ME, teams)
cat(sprintf("BASE=%s GAPMODE=%s | noise: per-team weekly sd %.1f, actual-ceiling gap %+.2f (wks %s, n=%d)\n",
            BASE, GAPMODE, SIG, GAP, paste(range(cl$week), collapse = "-"), nrow(cl)))
tx <- TXN[TXN$date >= EXDATE, ]
cat(sprintf("rosters: week-%d export (%s) + %d logged move(s): %s\n", CUR, EXDATE, nrow(tx),
            paste(tx$add, "for", tx$drop, collapse = "; ")))

cat("\n=== P(top 4) and expected final wins, tau = 0 / tau = 6 ===\n")
tab <- tibble(team = teams, w0 = W0, mu_future = round(rowMeans(M0[, -1]) + GAPS, 1),
              exp_wins = round(colMeans(s0$W), 2), p_top4 = round(colMeans(s0$top4), 3),
              p_top4_tau6 = round(colMeans(s6$top4), 3)) |> arrange(desc(p_top4))
print(as.data.frame(tab)); cat("sum P(top4):", round(sum(tab$p_top4), 3), "\n")

cat("\n=== OUR remaining games: P(win), and leverage = P(top4 | win) - P(top4 | loss) ===\n")
ours <- which(G$a == ME | G$b == ME)
lev <- bind_rows(lapply(ours, function(j) {
  won <- if (G$a[j] == ME) s0$win[, j] else !s0$win[, j]; opp <- setdiff(c(G$a[j], G$b[j]), ME)
  tibble(week = G$week[j], opponent = opp,
         our_mu = round(M0[ME, as.character(G$week[j])] + GAPS[ME], 1),
         opp_mu = round(M0[opp, as.character(G$week[j])] + GAPS[opp], 1),
         p_win = round(mean(won), 3),
         p_top4_if_W = round(mean(s0$top4[won, me]), 3), p_top4_if_L = round(mean(s0$top4[!won, me]), 3))
})) |> mutate(leverage = p_top4_if_W - p_top4_if_L) |> arrange(week)
print(as.data.frame(lev))

cat("\n=== P(we make top 4 | our final win total) ===\n")
print(as.data.frame(tibble(final_wins = s0$W[, me], top4 = s0$top4[, me]) |> group_by(final_wins) |>
  summarise(sims = n(), p_top4 = round(mean(top4), 3)) |> filter(sims >= 50)))

cat("\n=== OTHER games that move our odds most (who to root for) ===\n")
print(as.data.frame(bind_rows(lapply(setdiff(seq_len(nrow(G)), ours), function(j) {
  aw <- s0$win[, j]; pa <- mean(s0$top4[aw, me]); pb <- mean(s0$top4[!aw, me])
  tibble(week = G$week[j], game = paste(G$a[j], "v", G$b[j]),
         root_for = ifelse(pa > pb, G$a[j], G$b[j]), swing = round(abs(pa - pb), 3))
})) |> arrange(desc(swing)) |> head(8)))

cat(sprintf("\n=== exchange rate: +X pts/wk to OUR strength, %s -> P(top 4) ===\n", FUT))
for (x in c(1, 3, 5, 10)) {
  Mx <- M0; Mx[ME, -1] <- Mx[ME, -1] + x; sx <- simulate(Mx)
  cat(sprintf("+%2d pt/wk: P(top4) %.3f -> %.3f (%+.3f)   exp wins %+.2f\n", x, mean(s0$top4[, me]),
              mean(sx$top4[, me]), mean(sx$top4[, me]) - mean(s0$top4[, me]), mean(sx$W[, me]) - mean(s0$W[, me])))
}
