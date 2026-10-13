suppressMessages({library(nflreadr);library(dplyr);library(data.table)})
source("dev/weekly/mult_core.R")

d <- abs(A$p_adj - A$actual) - abs(A$p - A$actual)   # +ve = multiplier hurt
set.seed(1)
bs <- replicate(10000, mean(sample(d, length(d), replace=TRUE)))
ci <- quantile(bs, c(.025,.975))
cat(sprintf("\n=== MAE delta (adjusted minus raw), n=%d ===\n", length(d)))
cat(sprintf("point estimate  %+.3f pts per player-week\n", mean(d)))
cat(sprintf("95%% bootstrap CI [%+.3f, %+.3f]  -> straddles zero: %s\n",
            ci[1], ci[2], ifelse(ci[1]<0 & ci[2]>0, "YES", "no")))
cat(sprintf("paired t-test p = %.3f\n", t.test(d)$p.value))
cat(sprintf("\nraw MAE %.3f. The multipliers move a projection by ~5%%,\n", mean(abs(A$p-A$actual))))
cat(sprintf("i.e. ~%.2f pts on a typical %.1f-pt projection -- an order of magnitude\n",
            0.05*mean(A$p), mean(A$p)))
cat("below the noise in a single player-week.\n")

ppg <- load_player_stats(2026) |> filter(season==2026, week<=4) |>
  mutate(fp = 0.5*receptions + 0.1*(receiving_yards+rushing_yards) +
              6*(receiving_tds+rushing_tds) + 0.04*passing_yards +
              4*passing_tds - 1*passing_interceptions) |>
  group_by(nm=player_display_name, pos=position) |>
  summarise(ppg=mean(fp,na.rm=TRUE), gms=n(), .groups="drop")
ini <- function(x){ x<-trimws(gsub(" +"," ",gsub("[^A-Za-z ]"," ",x)))
  vapply(strsplit(x," "), function(z) if(length(z)<2) tolower(z[1]) else
    tolower(paste0(substr(z[1],1,1), z[length(z)])), "") }
ppg <- ppg |> mutate(k=ini(nm)) |> filter(gms>=3, ppg>=5) |> distinct(k,pos,.keep_all=TRUE)
A2 <- A |> mutate(k=ini(player)) |> inner_join(select(ppg,k,pos,ppg), by=c("k","pos"))

cat(sprintf("\n=== Double-counting check, ppg>=5 floor, n=%d ===\n", nrow(A2)))
cat(sprintf("Pearson(favouredness, YAHOO proj / own ppg) = %+.3f\n", cor(A2$fav_by, A2$p/A2$ppg)))
cat(sprintf("Pearson(favouredness, ACTUAL   / own ppg) = %+.3f\n", cor(A2$fav_by, A2$actual/A2$ppg)))
cat("\nIf Yahoo already priced the spread, the first number would be clearly positive.\n")
suppressMessages({library(dplyr)})
# FLEX-eligible bodies on OUR roster, per week: does adjustment reorder them?
f <- L |> filter(side=="ours", pos %in% c("RB","WR","TE")) |> group_by(week)
flips <- 0; tot <- 0; detail <- list()
for(w in sort(unique(L$week))){
  d <- L |> filter(side=="ours", week==w, pos %in% c("RB","WR","TE"))
  if(nrow(d)<2) next
  for(i in 1:(nrow(d)-1)) for(j in (i+1):nrow(d)){
    tot <- tot+1
    if(sign(d$p[i]-d$p[j]) != sign(d$p_adj[i]-d$p_adj[j])){
      flips <- flips+1
      detail[[length(detail)+1]] <- sprintf("  wk%d  %s (%.2f->%.2f) vs %s (%.2f->%.2f)",
        w, d$player[i], d$p[i], d$p_adj[i], d$player[j], d$p[j], d$p_adj[j])
    }
  }
}
cat(sprintf("=== Decision impact: FLEX-eligible pairs on our roster, wks1-4 ===\n"))
cat(sprintf("pairs compared: %d   order flipped by the multiplier: %d (%.1f%%)\n\n", tot, flips, 100*flips/tot))
cat(paste(unlist(detail), collapse="\n"), "\n")
