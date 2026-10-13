# Test: is Yahoo's weekly projection better than a dumb baseline?
# If a baseline we can compute ties Yahoo, we stop trusting the export's
# authority and start ranking on our own numbers. Week 4, 2026.
suppressMessages({library(dplyr)})
source("dev/weekly/read_yahoo_week.R")

POS <- c("qb","rb","wr","te")
rd <- function(stamp) bind_rows(lapply(POS, function(p)
  read_yahoo_position(sprintf("docs/uploads/week_4_data/yahoo_week4_%s%s.csv", p, stamp))))

proj <- rd("_2026-10-04") |> select(player, yahoo_id, yteam, pos, proj, owner)
act  <- rd("_actual_2026-10-05") |> select(player, yahoo_id, yteam, actual = proj) |>
  filter(!is.na(yahoo_id), yahoo_id != "") |>
  distinct(yahoo_id, .keep_all = TRUE)
proj <- proj |> filter(!is.na(yahoo_id), yahoo_id != "") |>
  distinct(yahoo_id, .keep_all = TRUE)

d <- proj |>
  inner_join(act, by = "yahoo_id", suffix = c("", ".a"), relationship = "one-to-one") |>
  filter(!is.na(proj), !is.na(actual))
cat("== joined on Yahoo Player ID:", nrow(d), "of", nrow(proj), "projected players\n")

# ---- half-PPR actuals weeks 1-3 from nflreadr, for the baselines ----
ps <- nflreadr::load_player_stats(2026) |>
  filter(season_type == "REG", week <= 3) |>
  mutate(hp = 0.04*coalesce(passing_yards,0) + 4*coalesce(passing_tds,0) -
              1*coalesce(passing_interceptions,0) +
              0.1*(coalesce(rushing_yards,0) + coalesce(receiving_yards,0)) +
              6*(coalesce(rushing_tds,0) + coalesce(receiving_tds,0)) +
              0.5*coalesce(receptions,0),
         opp = coalesce(carries,0) + coalesce(targets,0) + coalesce(attempts,0))

hist <- ps |> group_by(player_id, player_display_name) |>
  summarise(gp = n(), ppg = mean(hp), last = hp[which.max(week)],
            opp_g = mean(opp), .groups = "drop")

# name key: first initial + last name, both sides (yahoo_id is 0% for 2026 rookies)
key <- function(x) {
  x <- toupper(gsub("[^A-Za-z ]", "", trimws(x)))
  p <- strsplit(x, " +")
  vapply(p, function(w) if (length(w) < 2) paste(w, collapse="") else
    paste0(substr(w[1],1,1), w[length(w)]), character(1))
}
d$k    <- key(d$player)
hist$k <- key(hist$player_display_name)
hist2  <- hist |> group_by(k) |> slice_max(gp, n = 1, with_ties = FALSE) |> ungroup()

d <- d |> left_join(hist2 |> select(k, ppg, last, opp_g, gp), by = "k")
cat("   matched to weeks1-3 history:", sum(!is.na(d$ppg)), "of", nrow(d), "\n\n")

# ---- baselines ----
d <- d |> mutate(
  b_yahoo = proj,
  b_ppg   = coalesce(ppg, 0),
  b_last  = coalesce(last, 0),
  b_zero  = 0)
# opportunity baseline: position-level points per opportunity x own opp/g
ppo <- d |> filter(!is.na(opp_g), opp_g > 0) |> group_by(pos) |>
  summarise(r = sum(actual) / sum(opp_g), .groups = "drop")
d <- d |> left_join(ppo, by = "pos") |>
  mutate(b_opp = coalesce(opp_g * r, 0))

mods <- c(b_yahoo="Yahoo projection", b_ppg="season ppg wk1-3",
          b_last="last week only", b_opp="opportunity x pos rate",
          b_zero="always predict 0")

score <- function(dd, label) {
  cat("==", label, " n =", nrow(dd), "\n")
  res <- lapply(names(mods), function(m) {
    e <- dd[[m]] - dd$actual
    data.frame(model = mods[[m]], MAE = mean(abs(e)), RMSE = sqrt(mean(e^2)),
               bias = mean(e),
               r = if (sd(dd[[m]]) > 0) cor(dd[[m]], dd$actual) else NA_real_)
  }) |> bind_rows() |> arrange(MAE)
  res[,2:5] <- round(res[,2:5], 3)
  print(res, row.names = FALSE); cat("\n")
  invisible(res)
}

score(d, "WHOLE POOL (mostly inactive bodies, MAE here is near-meaningless)")
start <- d |> filter(proj >= 5 | coalesce(opp_g,0) >= 5)
score(start, "STARTABLE SUBSET (proj >= 5 or >= 5 opp/g) -- the decision-relevant one")

cat("== paired test: does Yahoo beat the best baseline on the startable subset? ==\n")
ae <- function(m) abs(start[[m]] - start$actual)
best_base <- names(mods)[which.min(sapply(names(mods)[-1], function(m) mean(ae(m))))+1]
tt <- t.test(ae("b_yahoo"), ae(best_base), paired = TRUE)
cat(sprintf("  Yahoo MAE %.3f vs %s MAE %.3f\n", mean(ae("b_yahoo")),
            mods[[best_base]], mean(ae(best_base))))
cat(sprintf("  paired diff %+.3f  p = %.4f  95%% CI [%+.3f, %+.3f] -> %s\n",
    mean(ae("b_yahoo") - ae(best_base)), tt$p.value,
    tt$conf.int[1], tt$conf.int[2],
    ifelse(tt$p.value < .05,
      ifelse(mean(ae("b_yahoo")) < mean(ae(best_base)), "Yahoo WINS", "Yahoo LOSES"),
      "TIE, unresolvable at n=1 week")))

cat("\n== by position, startable subset, MAE ==\n")
bp <- start |> group_by(pos) |> summarise(n = n(),
  yahoo = round(mean(abs(b_yahoo-actual)),2),
  ppg   = round(mean(abs(b_ppg-actual)),2),
  opp   = round(mean(abs(b_opp-actual)),2),
  sd_actual = round(sd(actual),2), .groups="drop") |>
  mutate(winner = ifelse(yahoo <= pmin(ppg,opp), "Yahoo", "baseline"))
print(as.data.frame(bp), row.names = FALSE)
