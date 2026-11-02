SCR <- "docs/review/002-evidence"
suppressMessages(source(file.path(SCR, "sim_helpers.R")))
Y <- readRDS(file.path(SCR, "p1_veteran/Y.rds"))
options(width = 220)
pkgload::load_all(".", quiet = TRUE); nf <- readRDS("data/nflreadr/pull_2026.rds")
# pre-injury Yahoo projections for IR / long-out players across clean exports wk4-8
who <- c("Davante Adams", "Travis Etienne Jr.", "De'Von Achane", "Jadarian Price", "Dameon Pierce", "Deebo Samuel Sr.", "Jonah Coleman", "Tyler Allgeier", "Christian McCaffrey", "Nico Collins", "Malik Nabers", "Chris Olave", "Mike Evans", "George Kittle", "Isaiah Likely", "Brock Purdy", "Tyler Shough")
pr <- bind_rows(lapply(names(ex), function(w) ex[[w]] |> filter(player %in% who) |> transmute(player, owner, injury, week = as.integer(w), proj)))
print(as.data.frame(pr |> select(player, week, proj) |> tidyr::pivot_wider(names_from = week, values_from = proj, names_prefix = "p")), row.names = FALSE)
cat("\n10-31 owner/injury:\n"); print(as.data.frame(Y |> filter(player %in% who) |> select(player, owner, injury, proj, base, pct_ros, gp, ppg, wks)), row.names = FALSE)
# weekly usage detail
ps <- nf$player_stats |> filter(season_type == "REG")
ps$fpts <- score_player_week(ps, load_config("scoring"))
det <- function(nm) { d <- ps |> filter(player_display_name %in% nm) |> select(player_display_name, week, team, carries, targets, receptions, fpts) |> arrange(player_display_name, week); print(as.data.frame(d), row.names = FALSE) }
cat("\nusage detail:\n"); det(c("Jonah Coleman", "Tyler Allgeier", "De'Von Achane", "Travis Etienne", "Travis Etienne Jr.", "Kendre Miller", "Alvin Kamara", "J.K. Dobbins", "RJ Harvey"))
sn <- nf$snaps |> filter(player %in% c("Jonah Coleman", "J.K. Dobbins", "RJ Harvey", "Tyler Allgeier", "Jeremiyah Love", "Kendre Miller", "Travis Etienne", "Devin Neal")) |> select(player, team, week, offense_pct) |> arrange(player, week)
print(as.data.frame(sn |> tidyr::pivot_wider(names_from = week, values_from = offense_pct)), row.names = FALSE)
inj <- nf$injuries |> filter(grepl("Achane|Etienne|Price|Coleman|Dobbins|Love|Allgeier|Kamara|Pierce", full_name)) |> select(week, team, full_name, report_primary_injury, report_status) |> arrange(full_name, week)
print(as.data.frame(inj), row.names = FALSE)
# depth chart latest for NO, MIA, DEN, ARI RBs
dp <- nf$depth |> filter(team %in% c("NO", "MIA", "DEN", "ARI", "SEA"), pos_abb == "RB") |> group_by(team) |> filter(dt == max(dt)) |> ungroup() |> select(dt, team, player_name, pos_rank) |> distinct() |> arrange(team, pos_rank)
print(as.data.frame(dp), row.names = FALSE)
