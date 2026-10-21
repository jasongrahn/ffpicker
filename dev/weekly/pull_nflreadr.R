suppressPackageStartupMessages({library(nflreadr); library(dplyr)})
options(nflreadr.verbose = FALSE)
nflreadr::clear_cache()
S <- 2026
out <- "data/nflreadr"
dir.create(out, showWarnings = FALSE, recursive = TRUE)

sch <- load_schedules(S)
ps  <- load_player_stats(S)
sn  <- load_snap_counts(S)
inj <- load_injuries(S)
ts  <- load_team_stats(S)
dep <- tryCatch(load_depth_charts(S), error=function(e) NULL)
ids <- load_ff_playerids()

saveRDS(list(schedules=sch, player_stats=ps, snaps=sn, injuries=inj,
             team_stats=ts, depth=dep, ids=ids), file.path(out, "pull_2026.rds"))

cat("== PULL", format(Sys.time()), "==\n")
f <- function(d, nm) cat(sprintf("%-14s rows %6d  weeks %s\n", nm, nrow(d),
  if ("week" %in% names(d)) paste(range(d$week, na.rm=TRUE), collapse="-") else "-"))
f(ps,"player_stats"); f(sn,"snaps"); f(inj,"injuries"); f(ts,"team_stats")
if (!is.null(dep)) f(dep,"depth_charts")
cat(sprintf("%-14s rows %6d\n","playerids",nrow(ids)))

cat("\n-- games played by week --\n")
print(sch |> filter(!is.na(result)) |> count(week), n=25)
cat("\n-- week 7 games: spread/total present? --\n")
w7 <- sch |> filter(week==7) |> select(gameday,gametime,away_team,home_team,spread_line,total_line,result)
print(as.data.frame(w7))
