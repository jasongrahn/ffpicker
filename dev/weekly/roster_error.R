# Week 4: how much MORE was available on the wire than on our own bench?
suppressMessages({library(dplyr);library(data.table)})
dir <- "docs/uploads/week_4_data"
rdp <- function(p){ d <- fread(sprintf("%s/yahoo_week4_%s_2026-10-04.csv", dir, p),
                               colClasses="character", check.names=FALSE, showProgress=FALSE)
  if(p=="def") tibble(player=d[[1]], status=d[[5]], pos="DEF")
  else         tibble(player=d[[1]], status=d[[7]], pos=toupper(p)) }
rda <- function(p){ d <- fread(sprintf("%s/yahoo_week4_%s_actual_2026-10-05.csv", dir, p),
                               colClasses="character", check.names=FALSE, showProgress=FALSE)
  v <- if(p=="def") suppressWarnings(as.numeric(d[[8]])) else suppressWarnings(as.numeric(d[[10]]))
  tibble(player=d[[1]], actual=v, pos=toupper(p)) }
P <- bind_rows(lapply(c("qb","rb","wr","te","k","def"), rdp))
A <- bind_rows(lapply(c("qb","rb","wr","te","k","def"), rda))
X <- inner_join(P, A, by=c("player","pos")) |> filter(!is.na(actual)) |>
     mutate(pos=ifelse(pos=="DEF","DEF",pos),
            avail = grepl("^W [(]", status) | status == "FA", mine = grepl("JGrahnasaurs", status))
cat("week4 pool joined:", nrow(X), " | mine:", sum(X$mine), " | on waivers:", sum(X$avail), "\n")

optimal <- function(d){
  take <- function(pool,p,n){ c0 <- pool |> filter(pos %in% p) |> arrange(desc(actual)) |> head(n)
    list(pick=c0, rest=anti_join(pool,c0,by=c("player","pos"))) }
  pool<-d; out<-list()
  for(sp in list(c("QB",1),c("RB",2),c("WR",2),c("TE",1),c("K",1),c("DEF",1))){
    r<-take(pool,sp[1],as.integer(sp[2])); out[[length(out)+1]]<-r$pick; pool<-r$rest }
  r<-take(pool,c("RB","WR","TE"),1); out[[length(out)+1]]<-r$pick; bind_rows(out) }

own  <- sum(optimal(filter(X, mine))$actual)
both <- sum(optimal(filter(X, mine | avail))$actual)
cat(sprintf("\nweek 4 started            93.00\n"))
cat(sprintf("best from OWN roster     %6.2f   -> lineup error %6.2f\n", own, own-93.00))
cat(sprintf("best from own + waivers  %6.2f   -> roster error %6.2f\n", both, both-own))
cat("\n(roster error is hindsight-maximal: it picks the week's best wire outcome,\n")
cat(" which no process could have selected in advance. Treat as a ceiling, not a target.)\n")
