# Wk8 QB call: Kyler (MIN @ DET) v Stafford (LAC @ LA). Does "QB pts allowed" (DvP) add to Yahoo proj?
suppressPackageStartupMessages({library(dplyr)})
pkgload::load_all(".", quiet = TRUE)
source("dev/weekly/read_yahoo_week.R")
U <- "docs/uploads"; UNSTARTED <- "^(Sun|Mon|Tue|Wed|Thu|Fri|Sat) [0-9]+:[0-9]+ [ap]m"
clean_tmpl <- function(w) {   # copy of league_sim.R's
  d <- sprintf("week_%d_data", w)
  f <- sort(list.files(file.path(U, d), sprintf("^yahoo_week%d_qb_[0-9]{4}-[0-9]{2}-[0-9]{2}[.]csv$", w)), decreasing = TRUE)
  for (x in f) { g <- read_yahoo_position(file.path(U, d, x))$game
    if (all(is.na(g) | g == "" | grepl(UNSTARTED, g))) return(file.path(d, sub("_qb_", "_%s_", x))) }
  NA_character_
}
p  <- readRDS("data/nflreadr/pull_2026.rds")
ps <- p$player_stats |> filter(season_type == "REG")
ps$fpts <- score_player_week(ps, load_config("scoring"))
qb <- ps |> filter(position == "QB")
s  <- p$schedules
imp <- bind_rows(s |> transmute(week, team = home_team, imp = total_line/2 + spread_line/2),
                 s |> transmute(week, team = away_team, imp = total_line/2 - spread_line/2))

# 1. QB pts allowed per game (all QBs, our scoring), wks 1-7
allowed <- qb |> group_by(def = opponent_team, week) |> summarise(pts = sum(fpts), .groups = "drop")
raw <- allowed |> group_by(def) |> summarise(g = n(), ppg = mean(pts)) |> arrange(desc(ppg)) |> mutate(rank_most = row_number())
# adjusted: primary passer's pts minus his own leave-one-out avg (>= 3 games)
prim <- qb |> group_by(team, week) |> slice_max(attempts, n = 1, with_ties = FALSE) |> ungroup() |> filter(attempts >= 15) |>
  group_by(player_id) |> mutate(n = n(), loo = (sum(fpts) - fpts) / (n - 1)) |> ungroup() |> filter(n >= 3) |> mutate(resid = fpts - loo)
adj <- prim |> group_by(def = opponent_team) |> summarise(adj = mean(resid), faced = paste0(player_name, " ", round(fpts,1), " (avg ", round(loo,1), ")", collapse = "; "))
tab <- raw |> left_join(adj, by = "def") |> arrange(desc(adj)) |> mutate(rank_adj = row_number())
cat("== QB pts allowed/g, wks 1-7, our scoring. rank 1 = most allowed. adj = vs those QBs' own avg\n")
print(as.data.frame(tab |> filter(def %in% c("DET","LAC")) |> select(def, g, ppg, rank_most, adj, rank_adj)), row.names = FALSE)
for (d0 in c("DET","LAC")) cat(d0, "faced:", tab$faced[tab$def == d0], "\n")
cat("league mean QB ppg allowed:", round(mean(allowed$pts), 2), "\n")

# 2. Game logs
yq <- bind_rows(lapply(4:8, function(w) { f <- clean_tmpl(w); if (is.na(f)) return(NULL)
  read_yahoo_position(file.path(U, sprintf(f, "qb"))) |> mutate(week = w) }))
ids <- as.data.frame(p$ids); ids$yahoo_id <- as.character(ids$yahoo_id)
by_id <- ids[!is.na(ids$yahoo_id), c("yahoo_id","gsis_id")]; by_id <- by_id[!duplicated(by_id$yahoo_id), ]
by_nm <- ids[!is.na(ids$merge_name) & ids$position %in% "QB", c("merge_name","gsis_id")]; by_nm <- by_nm[!duplicated(by_nm$merge_name), ]
yq$merge_name <- nflreadr::clean_player_names(yq$player, lowercase = TRUE)
yq <- yq |> left_join(rename(by_id, g1 = gsis_id), by = "yahoo_id") |> left_join(rename(by_nm, g2 = gsis_id), by = "merge_name") |>
  mutate(gsis_id = coalesce(g1, g2), method = ifelse(!is.na(g1), "id", ifelse(!is.na(g2), "name", NA)))
gl <- qb |> filter(player_display_name %in% c("Kyler Murray","Matthew Stafford")) |>
  left_join(yq |> select(gsis_id, week, yproj = proj), by = c("player_id" = "gsis_id", "week")) |>
  left_join(imp, by = c("team","week")) |>
  transmute(qb = player_display_name, week, team, opp = opponent_team, imp, yproj, pts = round(fpts,1), att = attempts,
            pass_yd = passing_yards, ptd = passing_tds, int = passing_interceptions, rush = carries, rush_yd = rushing_yards, rtd = rushing_tds)
cat("\n== game logs (yproj = Yahoo proj in that week's clean export; imp = own implied team total)\n")
print(as.data.frame(gl |> arrange(qb, week)), row.names = FALSE)
gl |> group_by(qb) |> summarise(g = n(), ppg = mean(pts), last3 = mean(tail(pts, 3)), rush_pts_g = mean(0.1*rush_yd + 6*rtd), sd = sd(pts)) |> as.data.frame() |> print(row.names = FALSE)

# 3. Test: does opp DvP-to-date (or own implied total) predict actual - Yahoo proj? QBs proj >= 12, wks 4-7
d <- yq |> filter(week <= 7, proj >= 12)
cat("\nQB-weeks proj >= 12:", nrow(d), "| id-matched:", sum(d$method == "id", na.rm=TRUE), "name:", sum(d$method == "name", na.rm=TRUE), "none:", sum(is.na(d$method)), "\n")
d <- d |> inner_join(qb |> select(player_id, week, team, opponent_team, fpts), by = c("gsis_id" = "player_id", "week")) |>
  left_join(imp, by = c("team","week"))
d$dvp <- mapply(function(df, w) mean(allowed$pts[allowed$def == df & allowed$week < w]), d$opponent_team, d$week)
d <- d |> group_by(week) |> mutate(dvp_c = dvp - mean(dvp), imp_c = imp - mean(imp)) |> ungroup() |>
  mutate(resid = fpts - proj) |> group_by(gsis_id) |> mutate(proj_dev = proj - mean(proj), nw = n()) |> ungroup()
cat("played + matched:", nrow(d), " weeks:", paste(sort(unique(d$week)), collapse=","), "\n")
show <- function(m, lab) { co <- summary(m)$coefficients; ci <- confint(m)
  for (v in rownames(co)[-1]) cat(sprintf("%-38s %-6s slope %+.3f  CI [%+.3f, %+.3f]  p %.3f  n %d\n", lab, v, co[v,1], ci[v,1], ci[v,2], co[v,4], nobs(m))) }
show(lm(resid ~ dvp_c, d), "actual - proj ~ DvP")
show(lm(resid ~ imp_c, d), "actual - proj ~ implied")
show(lm(resid ~ dvp_c + imp_c, d), "actual - proj ~ DvP + implied")
show(lm(proj_dev ~ dvp_c + imp_c, d |> filter(nw >= 2)), "Yahoo proj vs own mean ~ (priced in?)")
cat("resid sd:", round(sd(d$resid), 2), " mean:", round(mean(d$resid), 2), "\n")

# 4. This week's inputs
w8 <- tibble(qb = c("Kyler Murray","Matthew Stafford"), team = c("MIN","LA"), def = c("DET","LAC"))
w8$dvp <- sapply(w8$def, function(df) mean(allowed$pts[allowed$def == df & allowed$week < 8]))
w8 <- w8 |> left_join(imp |> filter(week == 8), by = "team")
print(as.data.frame(w8), row.names = FALSE)
m <- lm(resid ~ dvp_c + imp_c, d); b <- coef(m); V <- vcov(m)
x <- c(0, diff(rev(w8$dvp)) * -1, diff(rev(w8$imp)) * -1)   # Kyler minus Stafford
x <- c(0, w8$dvp[1] - w8$dvp[2], w8$imp[1] - w8$imp[2])
est <- sum(b * x); se <- sqrt(drop(t(x) %*% V %*% x))
cat(sprintf("model edge, Kyler over Stafford beyond Yahoo proj: %+.2f pts, 95%% CI [%+.2f, %+.2f]\n", est, est - 1.96*se, est + 1.96*se))
