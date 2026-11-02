# a4_wire common: baseline sim + TR1/TR2 roster + per-week override strength.
# Run from repo root. Writes nothing.
source("docs/review/002-evidence/sim_helpers.R")
eval(local({ L <- readLines("dev/weekly/trade_finder.R"); L <- L[grep("^CAP <- ", L):(grep("^mine <- ", L) - 1)]; parse(text = L[!grepl("^(M0|p0) <- ", L)]) }))   # CAP, settle, apply_trade, lab; range by pattern (lines shift)   # CAP, settle, apply_trade, lab
R$base[R$player == "Carnell Tate"] <- 0                                       # Tate-out bound (brief)
R_now <- R
x1 <- apply_trade(R_now, "Monday Night Madison", c("Kyler Murray", "T.J. Hockenson"), "Josh Jacobs")
x2 <- apply_trade(x1$R, "Max’s TD Bombers", c("Patrick Mahomes", "Carnell Tate"), c("Luther Burden III", "Isaiah Likely"))
R_tr <- x2$R
TR_DROPS <- list(tr1_us = x1$drop_us, tr1_them = x1$drop_them, tr2_us = x2$drop_us, tr2_them = x2$drop_them)

# Per-week override: ovr = data.frame(player, week, base). An IR player with an override row
# for week w is ACTIVE that week at that base (IR returns); weeks without a row keep R's state.
# extra = rows (same columns as R) added to a team for given weeks only is handled by callers.
team_strength2 <- function(d, ovr = NULL) {
  vapply(WEEKS, function(w) {
    dd <- d
    if (!is.null(ovr) && nrow(ovr)) {
      o <- ovr[ovr$week == w & ovr$player %in% dd$player, , drop = FALSE]
      if (nrow(o)) { i <- match(o$player, dd$player); dd$base[i] <- o$base; dd$injury[i] <- NA }
    }
    dd <- active(dd)
    if (w == CUR) return(opt_total(dd$pos, dd$proj))
    on <- dd$nfl %in% ON[[as.character(w)]] & dd$base > 0
    opt_total(dd$pos[on], dd$base[on], FILL)
  }, numeric(1))
}
# Our row only is recomputed (others unchanged) -> any delta = our move.
M_with <- function(Rx, ovr = NULL, M = NULL) {
  if (is.null(M)) M <- strength_matrix(Rx)
  M[ME, ] <- team_strength2(Rx[Rx$owner == ME, ], ovr); M
}
# P(top 4) over several seeds (CRN within seed). Returns mean p, mean wins, per-seed vectors.
SEEDS <- 20261021 + 0:4
pt4s <- function(M, seeds = SEEDS, tau = 0) {
  r <- sapply(seeds, function(s) pt4(simulate_cond(M, tau = tau, seed = s)))
  c(p = mean(r[1, ]), w = mean(r[2, ]))
}
dP <- function(Ma, Mb, seeds = SEEDS, tau = 0) {   # paired over seeds: Ma - Mb
  r <- sapply(seeds, function(s) pt4(simulate_cond(Ma, tau = tau, seed = s)) - pt4(simulate_cond(Mb, tau = tau, seed = s)))
  c(dP = mean(r[1, ]), sd_dP = sd(r[1, ]) / sqrt(length(seeds)), dW = mean(r[2, ]))
}
byes <- local({ s <- NFL_SCH <- readRDS("data/nflreadr/pull_2026.rds")$schedules |> dplyr::filter(game_type == "REG")
  pl <- dplyr::bind_rows(s |> dplyr::transmute(team = home_team, week), s |> dplyr::transmute(team = away_team, week))
  pl |> dplyr::group_by(team) |> dplyr::summarise(bye = setdiff(1:18, week)[1], .groups = "drop") })
