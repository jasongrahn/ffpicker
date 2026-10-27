# League-wide matchup predictions. FREEZE before kickoff, SCORE after.
# Pre-registration for the sim itself: its P(win) only earns a say in trade
# decisions if it calibrates on games it had not seen.
#   Rscript dev/weekly/predictions.R freeze   # week CUR; refuses after kickoff or overwrite
#   Rscript dev/weekly/predictions.R score    # every frozen week whose scores are entered
# Calibration is NOT powered at n = 5/wk. Favourites here run 50-70%, so even a
# perfect model averages ~3 of 5. Hit rate + Brier are logged, never a verdict
# alone -- the powered form of the same question is the gate's r
# (ceiling_vs_margin.R). P(win) = pnorm(margin / (SIG * sqrt(2))), slope 1, no fit.
suppressMessages(library(dplyr))
mode <- commandArgs(TRUE)[1]
stopifnot(mode %in% c("freeze", "score"))

if (mode == "freeze") {
  source("dev/weekly/league_sim.R")
  out <- sprintf("data/weekly/2026_week%02d_leaguewide_predictions.csv", CUR)
  if (file.exists(out)) stop(out, " exists -- a frozen prediction is never rewritten")
  k <- nfl |> filter(week == CUR) |>
    mutate(t = as.POSIXct(paste(gameday, gametime), tz = "America/New_York")) |> pull(t) |> min()
  if (Sys.time() >= k) stop("week ", CUR, " kicked off ", format(k), " -- a post-kickoff freeze is not a pre-registration")
  M0 <- strength_matrix(R)
  g <- G[G$week == CUR, ]
  pr <- tibble(week = CUR, team = g$a, opponent = g$b,
               ceil_team = round(M0[g$a, cw], 2), ceil_opp = round(M0[g$b, cw], 2)) |>
    mutate(pred_margin = round(ceil_team - ceil_opp, 2), p_team_win = round(pnorm(pred_margin / (SIG * sqrt(2))), 3),
           sig = round(SIG, 2), export = EXDATE, frozen_at = format(Sys.time(), "%Y-%m-%d %H:%M %Z"),
           first_kickoff = format(k, "%Y-%m-%d %H:%M %Z"))
  write.csv(pr, out, row.names = FALSE)
  cat("FROZEN", out, "\n"); print(as.data.frame(pr |> select(team, opponent, ceil_team, ceil_opp, pred_margin, p_team_win)))
  cat(sprintf("expected favourites right if the model is perfect: %.2f of %d\n",
              sum(pmax(pr$p_team_win, 1 - pr$p_team_win)), nrow(pr)))
} else {
  sch <- read.csv("data/weekly/2026_league_schedule.csv", encoding = "UTF-8", stringsAsFactors = FALSE)
  f <- list.files("data/weekly", "^2026_week[0-9]{2}_leaguewide_predictions[.]csv$", full.names = TRUE)
  p <- bind_rows(lapply(f, read.csv, encoding = "UTF-8", stringsAsFactors = FALSE)) |>
    inner_join(sch |> select(week, team, opponent, pf, pa), by = c("week", "team", "opponent"))
  waiting <- sort(unique(p$week[is.na(p$pf)]))
  p <- p |> filter(!is.na(pf)) |> mutate(won = pf > pa, fav_right = (p_team_win > 0.5) == won,
                                         brier = (p_team_win - won)^2, margin = pf - pa)
  if (length(waiting)) cat("frozen, scores not entered yet: week", paste(waiting, collapse = ","), "\n")
  if (!nrow(p)) { cat("nothing to score\n"); quit(save = "no") }
  print(as.data.frame(p |> group_by(week) |> summarise(n = n(), fav_right = sum(fav_right),
    expected = round(sum(pmax(p_team_win, 1 - p_team_win)), 2), brier = round(mean(brier), 3),
    mae_margin = round(mean(abs(margin - pred_margin)), 1))))
  cat(sprintf("cumulative: n %d | favourites right %d (model expected %.1f) | Brier %.3f vs coin-flip 0.250\n",
              nrow(p), sum(p$fav_right), sum(pmax(p$p_team_win, 1 - p$p_team_win)), mean(p$brier)))
}
