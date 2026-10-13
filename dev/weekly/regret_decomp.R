# Decompose weekly regret: which SLOT leaks, and is it lineup error or roster error?
suppressMessages({library(dplyr);library(data.table)})

read_team <- function(f){
  d <- fread(f, showProgress=FALSE)
  tibble(week=as.integer(d$week), player=d$player, pos=toupper(d$pos),
         slot=as.character(d$slot),
         started=if("started" %in% names(d)) as.logical(d$started) else d$slot!="BN",
         actual=suppressWarnings(as.numeric(d$actual)))
}
R <- bind_rows(lapply(Sys.glob("data/weekly/2026_week0[1-4]_myteam.csv"), read_team)) |>
  filter(!is.na(actual))

# league lineup: QB1 RB2 WR2 TE1 FLEX1(RB/WR/TE) K1 DST1
optimal <- function(d){
  take <- function(pool, p, n){
    cand <- pool |> filter(pos %in% p) |> arrange(desc(actual)) |> head(n)
    list(pick=cand, rest=anti_join(pool, cand, by="player"))
  }
  pool <- d; out <- list()
  for(spec in list(c("QB",1), c("RB",2), c("WR",2), c("TE",1), c("K",1), c("DEF",1))){
    r <- take(pool, spec[1], as.integer(spec[2])); out[[length(out)+1]] <- r$pick; pool <- r$rest
  }
  r <- take(pool, c("RB","WR","TE"), 1); out[[length(out)+1]] <- r$pick
  bind_rows(out)
}

cat("=== Regret by week, recomputed ===\n")
tot <- list()
for(w in sort(unique(R$week))){
  d <- filter(R, week==w)
  st <- filter(d, started); op <- optimal(d)
  cat(sprintf("wk%d  started %.2f   optimal %.2f   regret %6.2f\n",
              w, sum(st$actual), sum(op$actual), sum(op$actual)-sum(st$actual)))
  # attribute: per position group, points in optimal minus points started
  g <- full_join(
        st |> group_by(pos) |> summarise(started=sum(actual), .groups="drop"),
        op |> group_by(pos) |> summarise(optimal=sum(actual), .groups="drop"), by="pos") |>
      mutate(across(c(started,optimal), ~coalesce(.x,0)), leak=optimal-started, week=w)
  tot[[length(tot)+1]] <- g
}
cat("\n=== Where the regret lives, 4 weeks pooled ===\n")
bind_rows(tot) |> group_by(pos) |> summarise(
    started=round(sum(started),2), optimal=round(sum(optimal),2),
    leak=round(sum(optimal-started),2), .groups="drop") |>
  arrange(desc(leak)) |> as.data.frame() |> print(row.names=FALSE)

cat("\n=== Per week x position leak ===\n")
bind_rows(tot) |> filter(abs(leak)>0.001) |> arrange(desc(leak)) |>
  transmute(week, pos, leak=round(leak,2)) |> head(12) |> as.data.frame() |> print(row.names=FALSE)
