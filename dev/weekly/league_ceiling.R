suppressPackageStartupMessages({library(dplyr)})
YDIR <- Sys.getenv("YDIR", "docs/uploads/week_7_data")
source("dev/weekly/read_yahoo_week.R")
yh <- read_yahoo_week(YDIR)
teams <- setdiff(unique(yh$owner[!grepl("^FA$|^W \\(", yh$owner)]), NA)

optimal <- function(d) {
  d <- d |> filter(is.na(injury) | !grepl("IR", injury)) |> arrange(desc(proj))
  take <- function(d,p,n){s <- d|>filter(pos %in% p)|>head(n); list(s=s, rest=anti_join(d,s,by="player"))}
  tot <- 0; r <- d
  for (sp in list(list("QB",1),list("RB",2),list("WR",2),list("TE",1),list("K",1),list("DEF",1))) {
    t <- take(r, sp[[1]], sp[[2]]); tot <- tot + sum(t$s$proj); r <- t$rest }
  t <- take(r, c("RB","WR","TE"), 1); tot + sum(t$s$proj)
}

res <- sapply(teams, function(tm) optimal(yh |> filter(owner==tm)))
cat("=== WEEK 7 projection-optimal ceiling, all 10 rosters ===\n")
print(data.frame(team=names(sort(res, decreasing=TRUE)),
                 proj_optimal=round(sort(res, decreasing=TRUE),2), row.names=NULL))
cat("\nroster sizes:\n"); print(table(yh$owner[yh$owner %in% teams]))
