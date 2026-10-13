# Does the spread adjustment order a within-5% RB/WR/TE pair better than the raw
# Yahoo projection? Run over ALL TEN rosters, weeks 4-5. Rerunnable.
#
# Rule under test (CLAUDE.md, remeasured 2026-10-07 as a slope):
#   RB multiplier = 1 + 0.00799 * favouredness ; WR and TE flat 1.0
#   Inside a ~5% gap, break the tie on the SPREAD.
#
# Only DISCORDANT pairs are informative: pairs where raw and adjusted disagree on
# who to start. Concordant pairs carry no information about the rule.
suppressMessages({library(nflreadr); library(dplyr); library(tidyr)})

RB_SLOPE <- 0.00799
GAP      <- 0.05      # "within ~5%"
PROJ_MIN <- 5.0       # startable floor, per CLAUDE.md

rd <- function(path) {
  d <- read.csv(path, check.names = FALSE, fileEncoding = "UTF-8")
  names(d) <- trimws(gsub("[\\p{Co}]", "", names(d), perl = TRUE))
  d
}

VINT <- c("4" = "2026-10-04", "5" = "2026-10-07")   # last pre-kickoff projection vintage
ACT  <- c("4" = "2026-10-05", "5" = "2026-10-13")

load_week <- function(wk) {
  dir <- sprintf("docs/uploads/week_%s_data/", wk)
  out <- list()
  for (pos in c("rb", "wr", "te")) {
    p <- rd(sprintf("%syahoo_week%s_%s_%s.csv", dir, wk, pos, VINT[[as.character(wk)]]))
    a <- rd(sprintf("%syahoo_week%s_%s_actual_%s.csv", dir, wk, pos, ACT[[as.character(wk)]]))
    p <- p |> transmute(pid = `Player ID`, player = Player, pos = toupper(pos),
                        team = Team, proj = suppressWarnings(as.numeric(`Fantasy Fan Pts`)))
    a <- a |> transmute(pid = `Player ID`, owner = `Roster Status`,
                        actual = suppressWarnings(as.numeric(`Fantasy Fan Pts`)))
    out[[pos]] <- inner_join(p, a, by = "pid")
  }
  bind_rows(out) |> mutate(week = wk)
}

# favouredness per team-week: positive = favoured by that many points
sched <- load_schedules(2026) |> filter(week %in% c(4, 5), !is.na(spread_line))
fav <- bind_rows(
  sched |> transmute(week, nfl = home_team, fav =  spread_line),
  sched |> transmute(week, nfl = away_team, fav = -spread_line)
)

d <- bind_rows(load_week(4), load_week(5)) |>
  mutate(nfl = clean_team_abbrs(toupper(team))) |>
  left_join(fav, by = c("week", "nfl")) |>
  filter(!is.na(proj), !is.na(actual), !is.na(fav), proj >= PROJ_MIN)

d <- d |> mutate(
  mult = ifelse(pos == "RB", 1 + RB_SLOPE * fav, 1),
  adj  = proj * mult
)

# rostered = Roster Status is a fantasy team name, not "FA" / "W (...)"
rostered <- d |> filter(!grepl("^(FA|W \\()", owner))
cat("rows after join: ", nrow(d), " | rostered: ", nrow(rostered),
    " | distinct owners: ", length(unique(rostered$owner)), "\n", sep = "")
print(table(rostered$week, rostered$pos))

make_pairs <- function(x, within_owner) {
  res <- list()
  grp <- if (within_owner) split(x, list(x$week, x$owner), drop = TRUE) else split(x, x$week, drop = TRUE)
  for (g in grp) {
    if (nrow(g) < 2) next
    cb <- combn(nrow(g), 2)
    for (j in seq_len(ncol(cb))) {
      a <- g[cb[1, j], ]; b <- g[cb[2, j], ]
      gap <- abs(a$proj - b$proj) / mean(c(a$proj, b$proj))
      if (gap > GAP) next
      # only pairs where at least one side is an RB can ever be reordered
      raw_pick <- if (a$proj >= b$proj) a$player else b$player
      adj_pick <- if (a$adj  >= b$adj ) a$player else b$player
      truth    <- if (a$actual > b$actual) a$player else if (b$actual > a$actual) b$player else NA_character_
      res[[length(res) + 1]] <- data.frame(
        week = a$week, owner = if (within_owner) a$owner else "POOL",
        p1 = a$player, p2 = b$player, pos1 = a$pos, pos2 = b$pos,
        proj1 = a$proj, proj2 = b$proj, adj1 = a$adj, adj2 = b$adj,
        act1 = a$actual, act2 = b$actual, gap = gap,
        raw_pick, adj_pick, truth, stringsAsFactors = FALSE)
    }
  }
  bind_rows(res)
}

score <- function(pr, label) {
  cat("\n================ ", label, " ================\n", sep = "")
  cat("pairs within ", GAP * 100, "%: ", nrow(pr), "\n", sep = "")
  disc <- pr |> filter(raw_pick != adj_pick, !is.na(truth))
  cat("DISCORDANT (rule changes the choice) and decidable: ", nrow(disc),
      sprintf("  (%.1f%% of pairs)\n", 100 * nrow(disc) / max(nrow(pr), 1)), sep = "")
  if (nrow(disc) == 0) return(invisible(NULL))
  right <- sum(disc$adj_pick == disc$truth)
  cat("spread-adjusted pick correct: ", right, " of ", nrow(disc),
      sprintf("  (%.1f%%)\n", 100 * right / nrow(disc)), sep = "")
  bt <- binom.test(right, nrow(disc), 0.5)
  cat("binom.test vs 0.5: p = ", signif(bt$p.value, 3),
      "  95%% CI [", sprintf("%.3f", bt$conf.int[1]), ", ",
      sprintf("%.3f", bt$conf.int[2]), "]\n", sep = "")
  # points consequence
  d_pts <- with(disc, ifelse(adj_pick == p1, act1, act2) - ifelse(raw_pick == p1, act1, act2))
  cat("mean points gained by following the spread: ", sprintf("%+.3f", mean(d_pts)),
      "  (total ", sprintf("%+.2f", sum(d_pts)), ")\n", sep = "")
  tt <- t.test(d_pts)
  cat("t-test on points delta: p = ", signif(tt$p.value, 3),
      "  CI [", sprintf("%+.2f", tt$conf.int[1]), ", ", sprintf("%+.2f", tt$conf.int[2]), "]\n", sep = "")
  invisible(disc)
}

disc_r <- score(make_pairs(rostered, TRUE),  "A. ROSTER-CONSTRAINED, all 10 teams, wks 4-5")
disc_p <- score(make_pairs(d,        FALSE), "B. POOL-WIDE, every startable RB/WR/TE, wks 4-5")

if (!is.null(disc_r) && nrow(disc_r)) {
  cat("\n--- every roster-constrained discordant pair ---\n")
  o <- disc_r |> mutate(spread_right = adj_pick == truth) |>
    select(week, owner, p1, pos1, proj1, adj1, act1, p2, pos2, proj2, adj2, act2, spread_right)
  print(as.data.frame(o), row.names = FALSE, digits = 4)
}

# ---- sensitivity: drop pairs where either side scored exactly 0.00 (late scratch) ----
cat("\n\n================ SENSITIVITY: pool-wide, excluding actual == 0 ================\n")
pp <- make_pairs(d, FALSE) |> filter(act1 != 0, act2 != 0)
dd <- pp |> filter(raw_pick != adj_pick, !is.na(truth))
r <- sum(dd$adj_pick == dd$truth)
cat("decidable discordant: ", nrow(dd), " | spread correct: ", r,
    sprintf(" (%.1f%%)\n", 100*r/nrow(dd)), sep="")
print(binom.test(r, nrow(dd), 0.5))

# ---- where do the flips happen? spread magnitude of the RB side ----
cat("\n--- discordant pairs by RB favouredness bucket ---\n")
allp <- make_pairs(d, FALSE) |> filter(raw_pick != adj_pick, !is.na(truth))
rbfav <- ifelse(allp$pos1 == "RB", allp$adj1/allp$proj1 - 1, allp$adj2/allp$proj2 - 1) / 0.00799
allp$bucket <- cut(rbfav, c(-Inf,-7,-3,0,3,7,Inf),
                   labels=c("dog7+","dog3-7","dog0-3","fav0-3","fav3-7","fav7+"))
allp$ok <- allp$adj_pick == allp$truth
print(allp |> group_by(bucket) |> summarise(n=n(), spread_right=sum(ok),
      pct=round(100*mean(ok),1)) |> as.data.frame(), row.names=FALSE)
