suppressPackageStartupMessages({library(dplyr); library(tidyr)})
d <- readRDS("data/nflreadr/pull_2026.rds"); sch <- d$schedules
YDIR <- Sys.getenv("YDIR", "docs/uploads/week_7_data")
source("dev/weekly/read_yahoo_week.R")
yh <- read_yahoo_week(YDIR)

# byes from source
wks <- 1:18
played <- bind_rows(sch |> transmute(team=home_team, week), sch |> transmute(team=away_team, week))
byes <- played |> group_by(team) |> summarise(bye = setdiff(wks, week)[1])

mine <- yh |> filter(grepl("Grahn", owner)) |>
  mutate(ir = grepl("IR", injury),
         nfl = toupper(yteam),
         nfl = recode(nfl, "LAR"="LA"))
mine <- mine |> left_join(byes, by=c("nfl"="team"))

cat("=== STEP 1. Roster counts, ACTIVE only (IR excluded) ===\n")
print(mine |> filter(!ir) |> count(pos) |> as.data.frame())
cat("active:", sum(!mine$ir), " on IR:", sum(mine$ir), "\n")

cat("\n=== roster with byes ===\n")
print(as.data.frame(mine |> arrange(pos, bye) |> select(player,pos,nfl,bye,ir,proj)))

cat("\n=== STEP 2. Startable bodies per week, remaining weeks 7-17 ===\n")
# starters: QB1 RB2 WR2 TE1 FLEX1 K1 DEF1
act <- mine |> filter(!ir)
grid <- expand_grid(week=7:17) |> rowwise() |> mutate(
  QB  = sum(act$pos=="QB"  & act$bye!=week),
  RB  = sum(act$pos=="RB"  & act$bye!=week),
  WR  = sum(act$pos=="WR"  & act$bye!=week),
  TE  = sum(act$pos=="TE"  & act$bye!=week),
  K   = sum(act$pos=="K"   & act$bye!=week),
  DEF = sum(act$pos=="DEF" & act$bye!=week),
  flexpool = RB+WR+TE,
  ok = QB>=1 & RB>=2 & WR>=2 & TE>=1 & K>=1 & DEF>=1 & flexpool>=6
) |> ungroup()
print(as.data.frame(grid))
cat("\nweeks NOT fillable:", paste(grid$week[!grid$ok], collapse=", "), "\n")
