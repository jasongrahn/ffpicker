# Validate data/weekly/2026_league_schedule.csv -- ten Yahoo Schedule-tab
# screenshots, transcribed by hand 2026-10-21. Every check is a transcription
# trap: one misread digit breaks the mirror check, and season totals must
# reproduce the Standings tab to the cent.
#
# Team names are byte-exact Yahoo strings. "Dave’s" and "Max’s" carry U+2019,
# "Jason's" a straight apostrophe -- same as `Roster Status` in the exports.
# Join on them as-is; never normalise one side only.
suppressMessages(library(dplyr))
s <- read.csv("data/weekly/2026_league_schedule.csv", encoding = "UTF-8", stringsAsFactors = FALSE)

# Standings tab, "Last standings update: Wed Oct 21 02:49am EDT"
st <- tribble(~team, ~w, ~l, ~pf, ~pa, ~rank,
  "Owl Out Blitz",         5, 1, 724.36, 624.36,  1,
  "Max’s TD Bombers", 4, 2, 754.58, 580.40,  2,
  "Sunday Kevin",          4, 2, 701.28, 689.76,  3,
  "Dave’s Bone Crushers", 4, 2, 676.16, 664.58, 4,
  "Jason's Jazzy Team",    4, 2, 644.02, 639.82,  5,
  "JGrahnasaurs",          3, 3, 654.82, 663.30,  6,
  "Locked In Michelle",    2, 4, 692.68, 698.84,  7,
  "Maybe Mitchell",        2, 4, 639.82, 593.88,  8,
  "Steel City",            1, 5, 552.22, 646.90,  9,
  "Monday Night Madison",  1, 5, 424.50, 662.60, 10)

stopifnot(nrow(s) == 150, !anyDuplicated(s[c("week", "team")]),
          setequal(s$week, 1:15), setequal(s$team, st$team), setequal(s$opponent, st$team))

# each week a perfect matching, and every row mirrored with scores swapped
m <- s |> inner_join(s, by = c("week", "team" = "opponent", "opponent" = "team"), suffix = c("", ".o"))
stopifnot(nrow(m) == 150, all(m$team != m$opponent))
d <- m |> filter(!is.na(pf))
stopifnot(all(abs(d$pf - d$pa.o) < 1e-9), all(abs(d$pa - d$pf.o) < 1e-9),
          all((d$pf > d$pa) == (d$result == "W")))

# structure: wk1-9 full round robin, wk10-15 replay wk1-6
pairs <- s |> filter(week <= 9) |> transmute(k = paste(pmin(team, opponent), pmax(team, opponent))) |> distinct()
stopifnot(nrow(pairs) == 45)
a <- s |> filter(week <= 6) |> arrange(team, week)
b <- s |> filter(week >= 10) |> arrange(team, week)
stopifnot(identical(a$opponent, b$opponent))

# reproduce the Standings tab -- a wk1-6 SNAPSHOT -- totals and order (tiebreak
# = PF, inferred). Weeks entered later are guarded by the mirror check above.
tbl <- function(x) x |> group_by(team) |>
  summarise(w = sum(result == "W"), l = sum(result == "L"), pf = round(sum(pf), 2), pa = round(sum(pa), 2)) |>
  arrange(desc(w), desc(pf)) |> mutate(rank = row_number())
chk <- inner_join(tbl(d |> filter(week <= 6)), st, by = "team", suffix = c("", ".y"))
stopifnot(nrow(chk) == 10, all(chk$w == chk$w.y), all(chk$l == chk$l.y),
          all(abs(chk$pf - chk$pf.y) < 0.005), all(abs(chk$pa - chk$pa.y) < 0.005),
          all(chk$rank == chk$rank.y))

own <- unlist(lapply(c("qb", "rb", "wr", "te", "k"), function(p)
  read.csv(sprintf("docs/uploads/week_7_data/yahoo_week7_%s_2026-10-21.csv", p),
           check.names = FALSE, encoding = "UTF-8", stringsAsFactors = FALSE)[["Roster Status"]]))
stopifnot(all(st$team %in% own))   # byte-exact join to the exports

cat(sprintf("schedule_check: all pass. 150 rows, %d results through wk %d, wk1-6 Standings tab reproduced incl. PF tiebreak order\n",
            nrow(d) / 2, max(d$week)))
print(as.data.frame(tbl(d)))
