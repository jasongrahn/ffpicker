suppressPackageStartupMessages({library(dplyr)})
WK   <- 8L
YDIR <- Sys.getenv("YDIR", "docs/uploads/week_8_data")
YDATE <- Sys.getenv("YDATE", "2026-10-28")   # which pull; read_yahoo_week() stops on a mixed folder
source("dev/weekly/read_yahoo_week.R")
yh <- read_yahoo_week(YDIR, YDATE)
src <- paste0("position_exports_", YDATE)

slots_me <- c("K. Murray"="QB","J. Williams"="RB","D. Henry"="RB","C. Tate"="WR",
              "D. Boston"="WR","T. Hockenson"="TE","O. Gordon II"="FLEX","J. Bates"="K","Commanders"="DEF")

abbrev <- function(p) ifelse(grepl(" ", p),
  paste0(substr(p,1,1), ". ", sub("^\\S+ ", "", p)), p)

mk <- function(team, starters) {
  d <- yh |> filter(grepl(team, owner)) |>
    transmute(season=2026, week=WK, player=abbrev(player), pos, nfl_team=yteam,
              slot=NA_character_, started=0L, proj,
              proj_gameday=NA_real_, proj_gameday_src=src, actual=NA_real_, injury)
  # a misspelled slot key would bench that starter silently
  stopifnot(all(names(starters) %in% d$player))
  d$slot    <- unname(starters[d$player])
  d$started <- as.integer(!is.na(d$slot))
  d$slot[is.na(d$slot)] <- "BN"
  d$slot[grepl("IR", d$injury)] <- "IR"
  d |> select(-injury) |> arrange(desc(started), desc(proj))
}

me <- mk("Grahn", slots_me)
write.csv(me, sprintf("data/weekly/2026_week%02d_myteam.csv", WK), row.names=FALSE, na="")
cat("myteam started total:", sprintf("%.2f", sum(me$proj[me$started==1])), "\n")
print(as.data.frame(me |> select(slot,player,pos,nfl_team,proj)))

slots_op <- c("J. Burrow"="QB","J. Gibbs"="RB","K. Williams"="RB","G. Pickens"="WR",
              "R. Rice"="WR","H. Fannin Jr."="TE","J. Mason"="FLEX","B. Aubrey"="K","Seahawks"="DEF")
op <- mk("Locked In Michelle", slots_op)
write.csv(op, sprintf("data/weekly/2026_week%02d_opponent.csv", WK), row.names=FALSE, na="")
cat("\nopponent projected-optimal total:", sprintf("%.2f", sum(op$proj[op$started==1])), "\n")
