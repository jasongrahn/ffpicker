# A1 Q1: luck vs roster. All-play record, actual W-L, luck, PF/PA ranks, normal-model exp wins.
# Run from repo root. Input: data/weekly/2026_league_schedule.csv (Yahoo finals wks 1-7).
# Optional arg: path to a wk8 provisional csv (team, score) -> also prints wks 1-8 version.
suppressMessages({library(dplyr); library(tidyr)})
OUT <- "docs/review/002-evidence/a1_luck"
sch <- read.csv("data/weekly/2026_league_schedule.csv", encoding = "UTF-8", stringsAsFactors = FALSE)
ME <- "JGrahnasaurs"

luck_table <- function(d) {
  # d: week, team, opponent, pf, pa, result (complete weeks only)
  stopifnot(all(table(d$week) == 10))
  # all-play: per week, wins vs the other 9 scores (ties = 0.5)
  ap <- d |> group_by(week) |>
    mutate(ap_w = sapply(pf, function(s) sum(pf < s) + 0.5 * (sum(pf == s) - 1)),
           ap_l = 9 - ap_w,
           # normal smoothing: P(beat a random other team), others ~ N(mean of other 9, pooled sd)
           mu_o = (sum(pf) - pf) / 9) |> ungroup()
  sdp <- sd(ap$pf - ave(ap$pf, ap$week))  * sqrt((nrow(ap) - 1) / (nrow(ap) - length(unique(ap$week))))
  ap <- ap |> mutate(p_norm = pnorm((pf - mu_o) / sdp))
  out <- ap |> group_by(team) |>
    summarise(W = sum(result == "W"), L = sum(result == "L"),
              ap_W = sum(ap_w), ap_L = sum(ap_l),
              exp_W_allplay = sum(ap_w / 9),
              exp_W_norm = sum(p_norm),
              sd_W = sqrt(sum((ap_w / 9) * (1 - ap_w / 9))),
              PF = sum(pf), PA = sum(pa), .groups = "drop") |>
    mutate(luck = W - exp_W_allplay, z_luck = luck / sd_W,
           PF_rk = rank(-PF, ties.method = "min"), PA_rk = rank(-PA, ties.method = "min"),
           ap_rk = rank(-exp_W_allplay, ties.method = "min"),
           W_rk = rank(-(W * 1e4 + PF), ties.method = "min"),
           PA_vs_avg = PA - mean(PA)) |>
    arrange(desc(exp_W_allplay))
  attr(out, "sd_pooled") <- sdp
  out
}

d7 <- sch |> filter(!is.na(pf), week <= 7)
t7 <- luck_table(d7)
cat(sprintf("Wks 1-7, n %d team-weeks, pooled within-week sd %.2f\n", nrow(d7), attr(t7, "sd_pooled")))
print(as.data.frame(t7 |> mutate(across(where(is.numeric), ~ round(.x, 2)))), row.names = FALSE)

# Our week by week: all-play
cat("\nOur weekly all-play (wins vs 9) and league rank of our score:\n")
print(as.data.frame(d7 |> group_by(week) |> mutate(rk = rank(-pf), ap = sapply(pf, function(s) sum(pf < s))) |>
  filter(team == ME) |> select(week, opponent, pf, pa, result, rk, ap)), row.names = FALSE)
cat("\nOpponent score rank that week (1 = highest of 10) when they played us:\n")
print(as.data.frame(d7 |> group_by(week) |> mutate(rk = rank(-pf)) |> filter(opponent == ME) |>
  select(week, team, pf, rk)), row.names = FALSE)

# Points-against luck league-wide: mean opponent score vs league mean, per team
cat(sprintf("\nLeague mean score wks 1-7: %.2f\n", mean(d7$pf)))

# Optional wks 1-8 with provisional wk8 scores
args <- commandArgs(TRUE)
if (length(args) && file.exists(args[1])) {
  p8 <- read.csv(args[1], encoding = "UTF-8", stringsAsFactors = FALSE)
  w8 <- sch |> filter(week == 8) |> select(week, team, opponent) |>
    left_join(p8 |> select(team, pf = score), by = "team") |>
    left_join(p8 |> select(opponent = team, pa = score), by = "opponent") |>
    mutate(result = ifelse(pf > pa, "W", "L"))
  t8 <- luck_table(bind_rows(d7 |> select(week, team, opponent, pf, pa, result), w8))
  cat("\n=== Wks 1-8, WK8 PROVISIONAL (nflreadr replay of proj-optimal lineups) ===\n")
  print(as.data.frame(t8 |> mutate(across(where(is.numeric), ~ round(.x, 2)))), row.names = FALSE)
  saveRDS(t8, file.path(OUT, "q1_luck_wk1_8_prov.rds"))
}
saveRDS(t7, file.path(OUT, "q1_luck_wk1_7.rds"))
