# Q3 (+Q4 player-level slope): is BASE (mean non-zero Yahoo proj, wks 4..k) the best rest-of-season strength?
# Rivals: latest non-zero proj, this-week proj, season ppg (nflreadr-scored, our scoring), blend.
# Targets: mean actual pts over weeks k+1..8 (nflreadr-scored; DNP while team played = 0; wk8 MNF teams dropped),
#          mean Yahoo proj over k+1..8. Population: players rostered at origin k, QB/RB/WR/TE/K, base > 0.
suppressPackageStartupMessages({library(dplyr); library(tidyr)})
pkgload::load_all(".", quiet = TRUE)
OUT <- "docs/review/002-evidence/p2_stats"
pl <- readRDS("data/nflreadr/pull_2026.rds")
ps <- pl$player_stats |> filter(season_type == "REG"); ps$fpts <- score_player_week(ps, load_config("scoring"))
s <- pl$schedules; teams_sched <- bind_rows(s |> transmute(week, nfl = home_team, gameday, weekday), s |> transmute(week, nfl = away_team, gameday, weekday))
mnf8 <- teams_sched$nfl[teams_sched$week == 8 & teams_sched$weekday == "Monday"]
cat("wk8 Monday teams (excluded from wk8 actuals):", mnf8, "\n")
ids <- pl$ids; ids$yahoo_id <- as.character(ids$yahoo_id)
o8 <- readRDS(file.path(OUT, "origin_8.rds")); ex <- o8$ex     # clean exports wks 4..8
allp <- bind_rows(lapply(names(ex), function(w) ex[[w]] |> transmute(key, player, pos, yteam, week = as.integer(w), proj))) |>
  mutate(nfl = recode(toupper(yteam), "LAR" = "LA"))
# key -> gsis: yahoo_id first, name fallback (attach_nfl_ids logic, cached ids)
pk <- allp |> distinct(key, player, pos) |> filter(!grepl("^DEF:", key))
pk$merge_name <- nflreadr::clean_player_names(pk$player, lowercase = TRUE)
byid <- ids |> filter(!is.na(yahoo_id)) |> distinct(yahoo_id, .keep_all = TRUE) |> select(yahoo_id, g1 = gsis_id)
bynm <- ids |> filter(!is.na(merge_name)) |> group_by(merge_name) |> filter(n() == 1) |> ungroup() |> select(merge_name, g2 = gsis_id)
pk <- pk |> left_join(byid, by = c("key" = "yahoo_id")) |> left_join(bynm, by = "merge_name") |> mutate(gsis = coalesce(g1, g2))
cat(sprintf("id match: %d/%d (%.1f%%), by id %d, by name %d\n", sum(!is.na(pk$gsis)), nrow(pk), 100 * mean(!is.na(pk$gsis)), sum(!is.na(pk$g1)), sum(is.na(pk$g1) & !is.na(pk$g2))))
act <- ps |> transmute(gsis = player_id, week, fpts)
# player x week actual: team played that week -> fpts or 0 (DNP)
on <- teams_sched |> distinct(week, nfl)
pw <- pk |> filter(!is.na(gsis)) |> select(key, gsis, pos) |>
  inner_join(allp |> distinct(key, nfl) |> group_by(key) |> slice_tail(n = 1), by = "key") |>   # latest NFL team
  tidyr::crossing(week = 1:8) |> semi_join(on, by = c("week", "nfl")) |>
  filter(!(week == 8 & nfl %in% mnf8)) |> left_join(act, by = c("gsis", "week")) |> mutate(played = !is.na(fpts), a0 = coalesce(fpts, 0))

res <- list()
for (k in 5:7) {
  o <- readRDS(file.path(OUT, sprintf("origin_%d.rds", k)))
  pop <- o$P |> filter(owner %in% unique(o$R$owner), pos %in% c("QB", "RB", "WR", "TE", "K"), base > 0) |> select(key, player, pos, base, proj_k = proj)
  hist <- allp |> filter(week <= k, proj > 0) |> group_by(key) |> summarise(latest = proj[which.max(week)], .groups = "drop")
  ppg <- pw |> filter(week <= k - 1, played) |> group_by(key) |> summarise(ppg = mean(fpts), gp = n(), .groups = "drop")
  fa <- pw |> filter(week > k) |> group_by(key) |> summarise(fut_act0 = mean(a0), fut_actp = mean(fpts, na.rm = TRUE), nw = n(), .groups = "drop")
  fp <- allp |> filter(week > k) |> semi_join(on |> rename(nfl2 = nfl), by = c("week", "nfl" = "nfl2")) |> group_by(key) |> summarise(fut_proj = mean(proj), .groups = "drop")
  x <- pop |> left_join(hist, by = "key") |> left_join(ppg, by = "key") |> left_join(fa, by = "key") |> left_join(fp, by = "key") |>
    mutate(origin = k, blend = ifelse(is.na(ppg), base, 0.5 * base + 0.5 * ppg))
  res[[as.character(k)]] <- x
}
X <- bind_rows(res)
ev <- function(x, tgt, preds = c("base", "latest", "proj_k", "ppg", "blend")) {
  x <- x |> filter(!is.na(.data[[tgt]]), !is.na(ppg), gp >= 2)
  bind_rows(lapply(preds, function(p) { e <- x[[p]] - x[[tgt]]; f <- lm(x[[tgt]] ~ x[[p]])
    tibble(target = tgt, pred = p, n = nrow(x), MAE = mean(abs(e)), RMSE = sqrt(mean(e^2)), bias = mean(e), r = cor(x[[p]], x[[tgt]]), slope = coef(f)[2]) }))
}
cat("\n== pooled origins 5,6,7; players with >=2 prior games ==\n")
for (tg in c("fut_act0", "fut_actp", "fut_proj")) print(as.data.frame(ev(X, tg) |> mutate(across(where(is.numeric), ~ round(.x, 3)))))
cat("\n== by origin, target = fut_act0 (DNP=0) ==\n")
for (k in 5:7) print(as.data.frame(ev(X |> filter(origin == k), "fut_act0") |> mutate(across(where(is.numeric), ~ round(.x, 3)))))
# paired: base vs each rival, squared-error difference, cluster bootstrap by player
pair <- function(x, tgt, a, b, B = 4000) { x <- x |> filter(!is.na(.data[[tgt]]), !is.na(ppg), gp >= 2)
  dd <- (x[[a]] - x[[tgt]])^2 - (x[[b]] - x[[tgt]])^2; cl <- split(seq_along(dd), x$key); keys <- names(cl)
  set.seed(4); bs <- replicate(B, { i <- unlist(cl[sample(keys, length(keys), TRUE)]); mean(dd[i]) })
  sprintf("%s vs %s on %s: mean dSE %+.2f, 95%% CI [%+.2f, %+.2f] (neg = %s better), n %d, players %d", a, b, tgt, mean(dd), quantile(bs, .025), quantile(bs, .975), a, length(dd), length(keys)) }
cat("\n"); for (tg in c("fut_act0", "fut_proj")) for (b in c("latest", "ppg", "blend")) cat(pair(X, tg, "base", b), "\n")
cat("\n== starters only (base >= 8) ==\n"); print(as.data.frame(ev(X |> filter(base >= 8), "fut_act0") |> mutate(across(where(is.numeric), ~ round(.x, 3)))))
cat("\n== DNP rate in future weeks (injury/benching the base cannot see) ==\n")
print(as.data.frame(X |> filter(!is.na(fut_act0)) |> group_by(origin) |> summarise(n = n(), mean_base = mean(base), mean_act0 = mean(fut_act0),
  mean_actp = mean(fut_actp, na.rm = TRUE), bias0 = mean(base - fut_act0), biasp = mean(base - fut_actp, na.rm = TRUE))))

cat("\n== Q4 player-level: is the WEEKLY Yahoo projection compressed? actual ~ proj, rostered, wks 4-8 ==\n")
wk <- allp |> filter(proj > 0, !grepl("^DEF:", key)) |> inner_join(pw |> select(key, week, a0, played, pos2 = pos), by = c("key", "week"))
rost <- bind_rows(lapply(4:8, function(k) readRDS(file.path(OUT, sprintf("origin_%d.rds", k)))$R |> transmute(key, week = k)))
wk <- wk |> semi_join(rost, by = c("key", "week"))
f <- lm(a0 ~ proj, wk); cat(sprintf("all rostered n %d: slope %.3f (SE %.3f) CI [%.2f, %.2f], intercept %.2f\n", nrow(wk), coef(f)[2], summary(f)$coef[2, 2], confint(f)[2, 1], confint(f)[2, 2], coef(f)[1]))
for (p in c("QB", "RB", "WR", "TE", "K")) { y <- wk |> filter(pos == p); f <- lm(a0 ~ proj, y)
  cat(sprintf("  %s n %d slope %.2f [%.2f, %.2f] mean proj %.1f mean act %.1f\n", p, nrow(y), coef(f)[2], confint(f)[2, 1], confint(f)[2, 2], mean(y$proj), mean(y$a0))) }
saveRDS(X, file.path(OUT, "player_X.rds"))
