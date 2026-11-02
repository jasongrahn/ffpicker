# A1 Q4b: which lineups match each team's Yahoo Thursday set-lineup projection (2026_week08_yahoo_matchups.csv)?
# Uses 10-28 export projections (closest pre-TNF pull), every rostered body allowed in a slot (bye/IR = 0 proj).
# Replays matching lineups with the q4 actuals -> a set-lineup-consistent wk8 estimate. Tolerance +-1.0.
suppressMessages({library(dplyr)})
source("dev/weekly/read_yahoo_week.R")
OUT <- "docs/review/002-evidence/a1_luck"
q4 <- readRDS(file.path(OUT, "q4_wk8_prov.rds")); r31 <- q4$r
fs <- sprintf("docs/uploads/week_8_data/yahoo_week8_%s_2026-10-28.csv", c("qb","rb","wr","te","k","def"))
y28 <- bind_rows(lapply(fs, read_yahoo_position)) |> distinct(player, yteam, .keep_all = TRUE) |> select(player, yteam, owner28 = owner, proj28 = proj)
ym <- read.csv("data/weekly/2026_week08_yahoo_matchups.csv", encoding = "UTF-8", stringsAsFactors = FALSE)
yset <- bind_rows(ym |> transmute(team, ys = yahoo_team), ym |> transmute(team = opponent, ys = yahoo_opp))
TOL <- 1.0
for (tm in setdiff(yset$team, "JGrahnasaurs")) {
  d <- r31 |> filter(owner == tm) |> left_join(y28, by = c("player", "yteam")) |> mutate(proj28 = coalesce(proj28, 0))
  ix <- function(p) which(d$pos == p)
  out <- list()
  for (qi in ix("QB")) for (ki in ix("K")) for (di in ix("DEF")) {
    rb <- ix("RB"); wr <- ix("WR"); te <- ix("TE")
    for (R2 in combn(rb, 2, simplify = FALSE)) for (W2 in combn(wr, 2, simplify = FALSE)) for (t1 in te)
      for (fx in setdiff(c(rb, wr, te), c(R2, W2, t1))) out[[length(out) + 1]] <- c(qi, ki, di, R2, W2, t1, fx)
  }
  m <- do.call(rbind, out)
  p28 <- apply(m, 1, function(i) sum(d$proj28[i])); act <- apply(m, 1, function(i) sum(d$act[i]))
  ys <- yset$ys[yset$team == tm]; hit <- abs(p28 - ys) <= TOL
  tnf <- which(d$nfl %in% c("GB", "CAR"))
  cat(sprintf("\n## %s  yahoo_set %.2f | max proj28 %.2f | matches %d of %d", tm, ys, max(p28), sum(hit), nrow(m)))
  if (any(hit)) {
    cat(sprintf(" | replay of matches: min %.2f med %.2f max %.2f\n", min(act[hit]), median(act[hit]), max(act[hit])))
    # TNF bodies (locked at Thu 20:15, after the 19:40 screenshot): share of matching lineups starting each
    for (k in tnf) cat(sprintf("   TNF %s (%s, proj28 %.2f, act %.2f): in %.0f%% of matches\n", d$player[k], d$pos[k], d$proj28[k], d$act[k],
                               100 * mean(apply(m[hit, , drop = FALSE], 1, function(i) k %in% i))))
    # bodies started in every match / in none
    inc <- sapply(seq_len(nrow(d)), function(k) mean(apply(m[hit, , drop = FALSE], 1, function(i) k %in% i)))
    cat("   always in:", paste(d$player[inc == 1], collapse = ", "), "\n")
    cat("   sometimes:", paste(sprintf("%s %.0f%%", d$player[inc > 0 & inc < 1], 100 * inc[inc > 0 & inc < 1]), collapse = ", "), "\n")
  } else cat("\n")
}
