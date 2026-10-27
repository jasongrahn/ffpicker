# Week-7 retro inputs. Every kill condition pre-registered in
# data/weekly/2026_week07_decisions.md, computed from data that lands after
# MNF. Prints KILL / pass per condition; the verdicts -- decision wrong vs
# outcome bad -- are still written by hand under the log's Retro line.
# Needs: week-7 *_actual_* exports in docs/uploads/week_7_data/, a fresh
# `Rscript dev/weekly/pull_nflreadr.R`, week-7 scores in
# data/weekly/2026_league_schedule.csv. A missing input prints WAITING.
# Keyed on Yahoo Player ID (DEF on team), never on name.
suppressMessages(library(dplyr)); source("dev/weekly/read_yahoo_week.R")
D <- "docs/uploads/week_7_data"
f <- list.files(D, "^yahoo_week7_(qb|rb|wr|te|k|def)_actual_[0-9-]+[.]csv$", full.names = TRUE)
if (!length(f)) { cat("WAITING: no week-7 *_actual_* export in", D, "\n"); quit(save = "no") }
f <- f[grepl(max(sub(".*_actual_([0-9-]+)[.]csv$", "\\1", f)), f)]
act <- bind_rows(lapply(f, read_yahoo_position)) |> distinct(player, yteam, .keep_all = TRUE) |>
  mutate(key = ifelse(pos == "DEF", paste0("DEF:", yteam), yahoo_id))
ID <- c(stafford = "9265", mahomes = "30123", kyler = "31833", bates = "40835", butker = "30346",
        henry = "29279", jwilliams = "33423", gordon = "41969", boston = "42661", tate = "42626",
        odunze = "40901", hockenson = "31840", higbee = "29344", strange = "40078",
        browns = "DEF:Cle", chiefs = "DEF:KC")
m <- match(ID, act$key)
stopifnot(!anyNA(m))                                       # every id must be IN the export...
pts <- setNames(coalesce(act$proj[m], 0), names(ID))       # ...but "-" = did not play = 0 (bye, inactive)
cat("actual export:", basename(f[1]), "\n\n")

nf <- readRDS("data/nflreadr/pull_2026.rds")
g <- nf$schedules |> filter(week == 7, home_team == "TEN", away_team == "CLE")
sn <- nf$snaps |> filter(week == 7)
snap <- function(p, t) { if (!any(sn$team == t)) return(NA_real_)   # no week-7 snaps for that team yet
  x <- sn$offense_pct[sn$player == p & sn$team == t]; if (length(x)) 100 * x else 0 }

v <- function(kill) ifelse(is.na(kill), "WAITING", ifelse(kill, "KILL", "pass"))
d1 <- pts[["odunze"]] - pts[["tate"]]
cat(sprintf("W1a  Odunze - Tate = %+.2f (kill > +3.0)                                   -> %s\n", d1, v(d1 > 3)))
tot <- if (nrow(g) == 1) g$home_score + g$away_score else NA_real_   # NA until the pull has the final
trio <- pts[["tate"]] + pts[["boston"]] + pts[["browns"]]
cat(sprintf("W1b  TEN-CLE total %s (kill < 30) AND Tate+Boston+Browns %.2f (kill < 15.0) -> %s\n",
            ifelse(is.na(tot), "NA", tot), trio, v(tot < 30 & trio < 15)))
hk <- snap("T.J. Hockenson", "MIN")
cat(sprintf("T1   Hockenson snap%% %s -> %s\n", ifelse(is.na(hk), "NA", round(hk)),
            ifelse(is.na(hk), "WAITING", ifelse(hk > 0, "played; option not needed",
                   "INACTIVE -> option forfeited by absence (pre-registered: not a wrong call)"))))
cat(sprintf("K1   Bates %.2f | Butker %s (dropped M1) -- log only; rule + projection concordant, K rule untested\n",
            pts[["bates"]], ifelse(is.na(pts[["butker"]]), "NA", sprintf("%.2f", pts[["butker"]]))))
cat(sprintf("D1   Browns DEF %.2f -- log only, DST rule validated league-wide, no kill on one week\n", pts[["browns"]]))
km <- snap("Kyler Murray", "MIN")
cat(sprintf("M1a  Kyler snap%% %s (kill < 80)                                            -> %s\n",
            ifelse(is.na(km), "NA", round(km)), v(km < 80)))

# result + regret. Frozen lineup per the log; roster = frozen + Kyler - Butker (M1)
st <- c("stafford", "henry", "jwilliams", "boston", "tate", "hockenson", "gordon", "bates", "browns")
started <- sum(pts[st])
pos <- c(stafford = "QB", mahomes = "QB", kyler = "QB", bates = "K", henry = "RB", jwilliams = "RB",
         gordon = "RB", boston = "WR", tate = "WR", odunze = "WR", hockenson = "TE", higbee = "TE",
         strange = "TE", browns = "DEF", chiefs = "DEF")
s <- function(p) sort(pts[names(pos)[pos == p]], decreasing = TRUE)
rb <- s("RB"); wr <- s("WR"); te <- s("TE")
hind <- s("QB")[1] + sum(rb[1:2]) + sum(wr[1:2]) + te[1] + s("K")[1] + s("DEF")[1] + max(c(rb[-(1:2)], wr[-(1:2)], te[-1]))
sch <- read.csv("data/weekly/2026_league_schedule.csv", encoding = "UTF-8", stringsAsFactors = FALSE)
me <- sch |> filter(week == 7, team == "JGrahnasaurs")
cat(sprintf("\nRESULT  %s\n", if (is.na(me$pf)) "WAITING: week-7 scores not entered in the schedule CSV" else
  sprintf("%.2f vs %s %.2f -> %s by %.2f | export-started %.2f %s", me$pf, me$opponent, me$pa,
          ifelse(me$pf > me$pa, "WON", "LOST"), abs(me$pf - me$pa), started,
          ifelse(abs(started - me$pf) < 0.005, "(matches Yahoo)", "(MISMATCH vs Yahoo -- stat correction or wrong lineup?)"))))
cat(sprintf("REGRET  hindsight-optimal %.2f - started %.2f = %.2f -> append to data/weekly/README.md\n",
            hind, started, hind - started))
