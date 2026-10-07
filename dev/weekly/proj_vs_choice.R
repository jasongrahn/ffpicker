# Capstone: split 4 weeks of regret into "we deviated from the projection"
# vs "the projection was wrong". Only the first half is fixable by us.
suppressMessages({library(dplyr)})

opt <- function(d, col) {                     # best legal lineup by `col`
  d <- d[!is.na(d[[col]]), ]; pick <- character(0)
  take <- function(ps, n) {
    c <- d[d$pos %in% ps & !(d$player %in% pick), ]
    if (!nrow(c)) return(character(0))
    c <- c[order(-c[[col]]), ]; head(c$player, n)
  }
  for (s in list(c("QB",1), c("RB",2), c("WR",2), c("TE",1), c("K",1), c("DEF",1)))
    pick <- c(pick, take(s[[1]], as.integer(s[[2]])))
  pick <- c(pick, take(c("RB","WR","TE"), 1))          # FLEX
  sum(d$actual[d$player %in% pick], na.rm = TRUE)
}

rows <- lapply(1:4, function(w) {
  d <- as.data.frame(data.table::fread(sprintf("data/weekly/2026_week%02d_myteam.csv", w)))
  d$pos <- toupper(d$pos)
  d$pos[d$pos %in% c("DST","DEF","D/ST")] <- "DEF"
  started <- sum(d$actual[d$started %in% c(TRUE,"TRUE","true",1)], na.rm = TRUE)
  data.frame(week = w, started = started,
             proj_opt = opt(d, "proj"),      # follow Yahoo blindly
             hind_opt = opt(d, "actual"))    # hindsight ceiling
}) |> bind_rows()

rows <- rows |> mutate(
  our_deviation   = proj_opt - started,   # cost of not following the projection
  projection_wrong = hind_opt - proj_opt, # irreducible: proj was simply wrong
  total_regret    = hind_opt - started)

print(as.data.frame(rows |> mutate(across(where(is.numeric), ~round(.,2)))), row.names = FALSE)

cat(sprintf("\n4-week totals:\n  started            %7.2f\n  projection-optimal %7.2f\n  hindsight-optimal  %7.2f\n",
    sum(rows$started), sum(rows$proj_opt), sum(rows$hind_opt)))
cat(sprintf("\n  regret from OUR deviations    %+7.2f  (%.0f%%)  <- fixable\n",
    sum(rows$our_deviation), 100*sum(rows$our_deviation)/sum(rows$total_regret)))
cat(sprintf("  regret from PROJECTION error  %+7.2f  (%.0f%%)  <- not fixable by us\n",
    sum(rows$projection_wrong), 100*sum(rows$projection_wrong)/sum(rows$total_regret)))
cat(sprintf("  total                         %+7.2f\n", sum(rows$total_regret)))
cat(sprintf("\n  avg cost of our deviations: %+.2f pts/wk\n", mean(rows$our_deviation)))
