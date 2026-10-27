# Shared machinery for the league-wide season sims. Sourced by playoff_odds.R
# and trade_finder.R; defines data and functions, prints nothing.
#
# Week-agnostic. CUR = newest week with a clean export (env CUR_WEEK
# overrides). Clean export = the LATEST dated position export of that week
# taken before any kickoff (every Game cell unstarted or bye) -- reproduces
# the hand-picked wk4 10-01, wk5 10-07, wk6 10-14, wk7 10-21.
#
# Rosters: CUR export + TXN, moves logged in decision logs AFTER that export
# -- the log is authoritative for who is rostered (CLAUDE.md). Add the next
# move as a TXN row; rows dated before the export are already in it, skipped.
# Strength: team x week projection-optimal lineup. Player value = BASE weekly
# projection, mean of his non-zero Yahoo projections over the clean exports
# wk4..CUR, zeroed on his NFL bye. Week CUR keeps its exported projections.
# IR excluded throughout: no IR returns modelled.
# Noise: measured, sd(actual - ceiling) over scored weeks, ceiling_vs_margin.R.
# Top 4 make the playoffs; tiebreak PF (schedule_check.R reproduces it).
#
# Env sensitivities: BASE=latest (most recent non-zero weekly projection),
# GAPMODE=shrunk (team-specific actual-minus-ceiling gap, EB-shrunk).
suppressMessages({library(dplyr); library(tidyr)})
source("dev/weekly/read_yahoo_week.R")

ME <- "JGrahnasaurs"; N <- 20000; SEED <- 20261021
BASE <- Sys.getenv("BASE", "mean"); GAPMODE <- Sys.getenv("GAPMODE", "uniform")
U <- "docs/uploads"
UNSTARTED <- "^(Sun|Mon|Tue|Wed|Thu|Fri|Sat) [0-9]+:[0-9]+ [ap]m"

clean_tmpl <- function(w) {
  d <- sprintf("week_%d_data", w)
  f <- sort(list.files(file.path(U, d), sprintf("^yahoo_week%d_qb_[0-9]{4}-[0-9]{2}-[0-9]{2}[.]csv$", w)),
            decreasing = TRUE)
  for (x in f) {
    g <- read_yahoo_position(file.path(U, d, x))$game
    if (all(is.na(g) | g == "" | grepl(UNSTARTED, g))) return(file.path(d, sub("_qb_", "_%s_", x)))
  }
  NA_character_
}
CLEAN <- setNames(vapply(4:17, clean_tmpl, ""), 4:17)
CLEAN <- CLEAN[!is.na(CLEAN)]
CUR <- as.integer(Sys.getenv("CUR_WEEK", max(as.integer(names(CLEAN)))))
CLEAN <- CLEAN[as.integer(names(CLEAN)) <= CUR]
cw <- as.character(CUR)
stopifnot(cw %in% names(CLEAN), all(as.character(CUR - 1:2) %in% names(CLEAN)))
WEEKS <- CUR:15
EXDATE <- sub(".*_([0-9-]+)[.]csv$", "\\1", CLEAN[[cw]])

read_set <- function(tmpl) bind_rows(lapply(c("qb", "rb", "wr", "te", "k", "def"), function(p)
  read_yahoo_position(file.path(U, sprintf(tmpl, p))))) |>
  distinct(player, yteam, .keep_all = TRUE) |>
  mutate(key = ifelse(pos == "DEF", paste0("DEF:", yteam), yahoo_id))
ex <- lapply(CLEAN, read_set)

sch <- read.csv("data/weekly/2026_league_schedule.csv", encoding = "UTF-8", stringsAsFactors = FALSE)
teams <- sort(unique(sch$team))
if (any(!is.na(sch$pf[sch$week >= CUR])))
  stop(sprintf("week %d already scored -- pull the week %d export before simulating", CUR, CUR + 1))
nfl <- readRDS("data/nflreadr/pull_2026.rds")$schedules
ON <- split(c(nfl$home_team, nfl$away_team), c(nfl$week, nfl$week))   # NFL teams playing, by week
nfl_team <- function(y) recode(toupper(y), "LAR" = "LA")

base <- bind_rows(lapply(names(ex), function(w) ex[[w]] |> transmute(key, week = as.integer(w), proj))) |>
  filter(proj > 0) |> group_by(key) |>
  summarise(base = if (BASE == "latest") proj[which.max(week)] else mean(proj), .groups = "drop")
# Current role. Zero in BOTH of his last two applicable exports (CUR-1+CUR, or
# CUR-2+CUR-1 when his NFL team is on bye in CUR) = backup, demoted, or
# long-term hurt. Mariota and Keenum each had ONE starter week then zeros;
# mean-of-non-zero read them as ~17-pt starters and made them the wire's
# replacement QB. No injury-tag exception: Mariota is tagged D, an injured BACKUP.
role <- ex[[cw]] |> transmute(key, pc = proj, onc = nfl_team(yteam) %in% ON[[cw]]) |>
  left_join(ex[[as.character(CUR - 1)]] |> transmute(key, p1 = proj), by = "key") |>
  left_join(ex[[as.character(CUR - 2)]] |> transmute(key, p2 = proj), by = "key") |>
  mutate(live = ifelse(onc, pmax(p1, pc, na.rm = TRUE), pmax(p2, p1, na.rm = TRUE)) > 0)
base <- base |> left_join(role |> select(key, live), by = "key") |>
  mutate(base = ifelse(coalesce(live, FALSE), base, 0)) |> select(-live)

P <- ex[[cw]] |> left_join(base, by = "key") |> mutate(base = coalesce(base, 0), nfl = nfl_team(yteam))
TXN <- tribble(~date, ~team, ~add, ~drop, ~logged,
  "2026-10-21", ME, "Kyler Murray", "Harrison Butker", "2026_week07_decisions.md M1")
R <- P |> filter(owner %in% teams)
for (i in which(TXN$date >= EXDATE)) {
  if (TXN$add[i] %in% R$player[R$owner == TXN$team[i]]) next      # export already has it
  stopifnot(TXN$drop[i] %in% R$player[R$owner == TXN$team[i]], sum(P$player == TXN$add[i]) == 1,
            !TXN$add[i] %in% R$player)
  R <- bind_rows(R |> filter(!(owner == TXN$team[i] & player == TXN$drop[i])),
                 P |> filter(player == TXN$add[i]) |> mutate(owner = TXN$team[i]))
}
stopifnot(all(R$nfl %in% unlist(ON)),
          !any(grepl(",", R$pos)))   # multi-position eligibility not modelled: fail loudly, never skip
active <- function(d) d[is.na(d$injury) | !grepl("IR", d$injury), ]

# Bye-hole fill. Without it the sim assumes nobody ever streams, so a team with
# one QB on bye scores 0 there (Max's: Dak only, DAL bye 14 -- the week they
# play us). Real managers fill an EMPTY slot from the wire. Future weeks only,
# and only empty slots: a weak starter is not upgraded for free, or every FA
# add would score zero by construction.
# `O` excluded: base cannot see a fresh injury. McLaurin (W, base 9.85) is O/knee
# at 10% snaps in wk6 -- he topped the wire on base and is not a body.
AVAIL <- P |> filter(owner == "FA" | grepl("^W [(]", owner), !player %in% R$player, nfl %in% unlist(ON),
                     is.na(injury) | !grepl("IR|^O$", injury), !grepl(",", pos), base > 0)
REPL <- AVAIL |> group_by(pos) |> slice_max(base, n = 1, with_ties = FALSE) |> ungroup()
FILL <- setNames(REPL$base, REPL$pos)
FILL["FLEX"] <- max(FILL[c("RB", "WR", "TE")])

# Projection-optimal lineup total. QB1 RB2 WR2 TE1 K1 DEF1, FLEX = best leftover
# RB/WR/TE. Greedy is exact here; equals dev/weekly/league_ceiling.R optimal()
# when fill = NULL. With `fill`, a slot short of bodies takes the wire's best.
opt_total <- function(pos, v, fill = NULL) {
  s <- function(p) sort(v[pos == p], decreasing = TRUE)
  top <- function(x, n, p) {
    got <- x[seq_len(min(n, length(x)))]
    if (!is.null(fill) && length(got) < n) got <- c(got, rep(fill[[p]], n - length(got)))
    sum(got)
  }
  rb <- s("RB"); wr <- s("WR"); te <- s("TE")
  top(s("QB"), 1, "QB") + top(rb, 2, "RB") + top(wr, 2, "WR") + top(te, 1, "TE") + top(s("K"), 1, "K") +
    top(s("DEF"), 1, "DEF") + top(sort(c(rb[-(1:2)], wr[-(1:2)], te[-1]), decreasing = TRUE), 1, "FLEX")
}
team_strength <- function(d) {   # numeric vector over WEEKS
  d <- active(d)
  vapply(WEEKS, function(w) {
    if (w == CUR) return(opt_total(d$pos, d$proj))
    on <- d$nfl %in% ON[[as.character(w)]] & d$base > 0          # bye or no value = absent body
    opt_total(d$pos[on], d$base[on], FILL)
  }, numeric(1))
}
strength_matrix <- function(R) {
  M <- t(vapply(teams, function(t) team_strength(R[R$owner == t, ]), numeric(length(WEEKS))))
  dimnames(M) <- list(teams, WEEKS); M
}
fut <- function(v) mean(v[-1])   # mean over future weeks: week CUR is set, trades land next week
FUT <- sprintf("wks %d-15", CUR + 1)

cl <- readRDS("data/weekly/2026_ceilings.rds") |> filter(variant == "late_roster_clean_proj") |>
  inner_join(sch |> filter(!is.na(pf)) |> select(week, team, pf), by = c("week", "team"))
GAP <- mean(cl$pf - cl$ceiling); SIG <- sd(cl$pf - cl$ceiling)
tg <- cl |> group_by(team) |> summarise(g = mean(pf - ceiling), se2 = var(pf - ceiling) / n(), .groups = "drop")
TAU2 <- max(0, var(tg$g) - mean(tg$se2))
GAPS <- setNames(if (GAPMODE == "shrunk") GAP + TAU2 / (TAU2 + tg$se2) * (tg$g - GAP) else rep(GAP, nrow(tg)),
                 tg$team)[teams]

done <- sch |> filter(!is.na(pf)) |> group_by(team) |>
  summarise(w0 = sum(result == "W"), pf0 = sum(pf), .groups = "drop")
W0 <- setNames(done$w0, done$team)[teams]; PF0 <- setNames(done$pf0, done$team)[teams]
G <- sch |> filter(week %in% WEEKS, team < opponent) |>
  transmute(week, a = team, b = opponent, ia = match(team, teams), ib = match(opponent, teams))

# Same seed -> same draws for any M: common random numbers, so a delta between
# two calls is the move's effect, not Monte Carlo noise.
simulate <- function(M, tau = 0, n = N, seed = SEED) {
  stopifnot(identical(rownames(M), teams))   # by NAME -- arrange() vs sort() locale trap
  set.seed(seed)
  mu <- M + GAPS
  W <- matrix(W0, n, 10, byrow = TRUE); PF <- matrix(PF0, n, 10, byrow = TRUE)
  d <- matrix(rnorm(n * 10, 0, tau), n, 10)
  win <- matrix(NA, n, nrow(G))
  for (k in seq_along(WEEKS)) {
    S <- matrix(mu[, k], n, 10, byrow = TRUE) + d + matrix(rnorm(n * 10, 0, SIG), n, 10)
    PF <- PF + S
    for (j in which(G$week == WEEKS[k])) {
      aw <- S[, G$ia[j]] > S[, G$ib[j]]; win[, j] <- aw
      W[, G$ia[j]] <- W[, G$ia[j]] + aw; W[, G$ib[j]] <- W[, G$ib[j]] + !aw
    }
  }
  rk <- t(apply(W * 1e4 + PF / 1e3, 1, function(x) rank(-x, ties.method = "first")))
  colnames(rk) <- colnames(W) <- teams
  list(top4 = rk <= 4, W = W, win = win)
}
