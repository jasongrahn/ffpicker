suppressPackageStartupMessages({library(dplyr); library(tidyr)})
source("dev/weekly/read_yahoo_week.R")
d <- readRDS("data/nflreadr/pull_2026.rds"); sn <- d$snaps; ps <- d$player_stats; sch <- d$schedules
YDIR <- Sys.getenv("YDIR", "docs/uploads/week_7_data")
source("dev/weekly/read_yahoo_week.R")
yh <- read_yahoo_week(YDIR)

avail <- yh |> filter(pos=="TE", owner=="FA" | grepl("^W \\(", owner))
cat("available TEs in export:", nrow(avail), "  (FA", sum(avail$owner=="FA"),
    "/ W", sum(grepl("^W \\(", avail$owner)), ")\n")

a <- attach_nfl_ids(avail)
cat("id match:", sum(!is.na(a$gsis_id)), "of", nrow(a),
    "| by yahoo_id:", sum(a$method=="yahoo_id", na.rm=TRUE),
    "| by name:", sum(a$method=="name", na.rm=TRUE), "\n")

# usage from nflreadr, weeks 1-6
use <- ps |> filter(position=="TE") |>
  group_by(gsis_id=player_id) |>
  summarise(g=n(), tgt=sum(targets,na.rm=TRUE), rec=sum(receptions,na.rm=TRUE),
            yds=sum(receiving_yards,na.rm=TRUE), td=sum(receiving_tds,na.rm=TRUE),
            tgt_g=round(tgt/n(),1),
            tgt_l3=round(mean(tail(targets[order(week)],3)),1), .groups="drop")
snp <- sn |> filter(position=="TE") |> arrange(week) |>
  group_by(player, team) |>
  summarise(snap_seq=paste(round(100*offense_pct), collapse="/"),
            snap_l3=round(100*mean(tail(offense_pct,3))), .groups="drop")

r <- a |> left_join(use, by="gsis_id") |>
  left_join(snp, by=c("nfl_name"="player")) |>
  filter(!is.na(tgt_g)) |>
  arrange(desc(tgt_l3))

cat("\n=== STEP 3. Available TEs, ranked on TARGETS last 3 (bar: >=5 tgt/g) ===\n")
print(as.data.frame(r |> filter(tgt_g>=3) |>
  select(player,yteam,owner,g,tgt_g,tgt_l3,yds,td,snap_seq,snap_l3,proj) |> head(15)))

cat("\n=== our TEs for comparison ===\n")
mine <- attach_nfl_ids(yh |> filter(grepl("Grahn", owner), pos=="TE")) |>
  left_join(use, by="gsis_id") |> left_join(snp, by=c("nfl_name"="player"))
print(as.data.frame(mine |> select(player,yteam,g,tgt_g,tgt_l3,yds,td,snap_seq,snap_l3,proj)))
