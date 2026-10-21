suppressPackageStartupMessages({library(dplyr)})
YDIR <- Sys.getenv("YDIR", "docs/uploads/week_7_data")
source("dev/weekly/read_yahoo_week.R")
yh <- read_yahoo_week(YDIR)
src <- "position_exports_2026-10-21"

slots_me <- c("M. Stafford"="QB","D. Henry"="RB","J. Williams"="RB","D. Boston"="WR",
              "C. Tate"="WR","T. Hockenson"="TE","O. Gordon II"="FLEX","J. Bates"="K","Browns"="DEF")

abbrev <- function(p) ifelse(grepl(" ", p),
  paste0(substr(p,1,1), ". ", sub("^\\S+ ", "", p)), p)

mk <- function(team, starters) {
  d <- yh |> filter(grepl(team, owner)) |>
    transmute(season=2026, week=7, player=abbrev(player), pos, nfl_team=yteam,
              slot=NA_character_, started=0L, proj,
              proj_gameday=NA_real_, proj_gameday_src=src, actual=NA_real_, injury)
  d$slot    <- unname(starters[d$player])
  d$started <- as.integer(!is.na(d$slot))
  d$slot[is.na(d$slot)] <- "BN"
  d$slot[grepl("IR", d$injury)] <- "IR"
  d |> select(-injury) |> arrange(desc(started), desc(proj))
}

me <- mk("Grahn", slots_me)
write.csv(me, "data/weekly/2026_week07_myteam.csv", row.names=FALSE, na="")
cat("myteam started total:", sprintf("%.2f", sum(me$proj[me$started==1])), "\n")
print(as.data.frame(me |> select(slot,player,pos,nfl_team,proj)))

slots_op <- c("T. Shough"="QB","S. Barkley"="RB","J. Jacobs"="RB","A. Brown"="WR",
              "E. Egbuka"="WR","D. Goedert"="TE","W. Marks"="FLEX","S. Shrader"="K","Titans"="DEF")
op <- mk("Monday Night Madison", slots_op)
write.csv(op, "data/weekly/2026_week07_opponent.csv", row.names=FALSE, na="")
cat("\nopponent projected-optimal total:", sprintf("%.2f", sum(op$proj[op$started==1])), "\n")
