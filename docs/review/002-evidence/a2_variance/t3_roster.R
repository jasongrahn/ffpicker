# Task 3: our roster (current, and post TR1+TR2) -> stacks + NFL-team/game overlap with each weekly
# opponent's projected starters, wks 9-15 -> margin-variance change -> priced in the sim (10 seeds, CRN).
SCR <- "docs/review/002-evidence"
A2 <- file.path(SCR, "a2_variance")
suppressMessages(source(file.path(SCR, "sim_helpers.R")))
eval(local({ L <- readLines("dev/weekly/trade_finder.R"); L <- L[grep("^CAP <- ", L):(grep("^mine <- ", L) - 1)]; parse(text = L[!grepl("^(M0|p0) <- ", L)]) }))   # CAP, settle, apply_trade, lab; range by pattern (lines shift)
# ---- correlation + sd lookup by position pair, 2024-25 (same NFL team / opposing team same game)
z <- readRDS(file.path(A2, "pw_2425.rds"))
FLOOR <- c(QB1 = 14, RB1 = 8, WR1 = 7, WR2 = 7, TE1 = 5, K1 = -Inf)
pw <- z$pw |> filter(role != "QB1" | coalesce(attempts, 0) >= 10) |> group_by(season, team, player_id) |>
  mutate(gq = n(), m = mean(pts), res = pts - m) |> ungroup() |> filter(gq >= 8, m >= FLOOR[role])
dst <- z$dst |> group_by(season, team) |> mutate(res = pts - mean(pts)) |> ungroup() |> mutate(role = "DST", opponent_team = opp)
X <- bind_rows(pw |> select(season, week, team, opp = opponent_team, role, res),
               dst |> select(season, week, team, opp, role, res)) |>
  mutate(pos = recode(role, QB1 = "QB", RB1 = "RB", WR1 = "WR", WR2 = "WR", TE1 = "TE", K1 = "K", DST = "DEF"))
POS <- c("QB", "RB", "WR", "TE", "K", "DEF")
SDP <- X |> group_by(pos) |> summarise(s = sd(res)) |> (\(d) setNames(d$s, d$pos))()
cmat <- function(opp) { m <- matrix(NA, 6, 6, dimnames = list(POS, POS)); n <- m
  for (a in POS) for (b in POS) { A <- X |> filter(pos == a); B <- X |> filter(pos == b)
    j <- if (opp) inner_join(A, B, by = c("season", "week", "opp" = "team"), relationship = "many-to-many") else
      inner_join(A, B, by = c("season", "week", "team"), relationship = "many-to-many")
    if (!opp && a == b) j <- j |> filter(res.x != res.y)            # different players, same team
    if (!opp && a == b && a %in% c("QB", "TE", "K", "DEF", "RB")) j <- j[0, ]   # one starter per team in sample
    m[a, b] <- if (nrow(j) >= 100) cor(j$res.x, j$res.y) else 0; n[a, b] <- nrow(j) }
  list(r = m, n = n) }
CS <- cmat(FALSE); CO <- cmat(TRUE)
cat("sd by pos:\n"); print(round(SDP, 2))
cat("\nsame-NFL-team r:\n"); print(round(CS$r, 3)); cat("\nopposing-team-same-game r:\n"); print(round(CO$r, 3))
# ---- projection-optimal lineup with names (mirrors league_sim.R opt_total; wire fill = anonymous body)
lineup <- function(d, w) {
  d <- active(d); on <- d$nfl %in% ON[[as.character(w)]] & d$base > 0; d <- d[on, ]
  d <- d[order(-d$base), ]; pick <- function(p, k) head(d$player[d$pos == p], k)
  s <- c(pick("QB", 1), pick("RB", 2), pick("WR", 2), pick("TE", 1), pick("K", 1), pick("DEF", 1))
  fl <- d$player[d$pos %in% c("RB", "WR", "TE") & !d$player %in% s][1]
  d[d$player %in% c(s, fl), c("player", "pos", "nfl", "base")]
}
oppmap <- function(w) { g <- nfl |> filter(week == w, game_type == "REG"); setNames(c(g$away_team, g$home_team), c(g$home_team, g$away_team)) }
cov_pairs <- function(A, B, w, within) { om <- oppmap(w); out <- list()
  for (i in seq_len(nrow(A))) for (j in seq_len(nrow(B))) {
    if (within && j <= i) next
    rel <- if (A$nfl[i] == B$nfl[j]) "same" else if (!is.na(om[A$nfl[i]]) && om[A$nfl[i]] == B$nfl[j]) "opp" else next
    r <- if (rel == "same") CS$r[A$pos[i], B$pos[j]] else CO$r[A$pos[i], B$pos[j]]
    out[[length(out) + 1]] <- data.frame(week = w, a = A$player[i], b = B$player[j], rel, pa = A$pos[i], pb = B$pos[j],
      r = r, cov = r * SDP[A$pos[i]] * SDP[B$pos[j]]) }
  bind_rows(out) }
oppo <- function(w) { g <- G[G$week == w & (G$a == ME | G$b == ME), ]; ifelse(g$a == ME, g$b, g$a) }
scan <- function(Rx, tag) {
  rows <- list(); pairs <- list()
  for (w in 9:15) { o <- oppo(w); A <- lineup(Rx[Rx$owner == ME, ], w); B <- lineup(Rx[Rx$owner == o, ], w)
    pw_ <- cov_pairs(A, A, w, TRUE); px <- cov_pairs(A, B, w, FALSE)
    vin <- 2 * sum(pw_$cov %||% 0); cx <- sum(px$cov %||% 0)
    rows[[length(rows) + 1]] <- data.frame(roster = tag, week = w, opp = o, stack_var = vin, cross_cov = cx,
      dV_margin = vin - 2 * cx)
    pairs[[length(pairs) + 1]] <- bind_rows(pw_ |> mutate(kind = "ours-ours"), px |> mutate(kind = "ours-theirs")) }
  list(rows = bind_rows(rows), pairs = bind_rows(pairs)) }
`%||%` <- function(a, b) if (length(a) == 0) b else a
# league context: within-lineup stack variance for all 10 teams, wks 9-15 (what SIG already averages over)
lg <- bind_rows(lapply(teams, function(t) bind_rows(lapply(9:15, function(w) { A <- lineup(R[R$owner == t, ], w)
  p <- cov_pairs(A, A, w, TRUE); data.frame(team = t, week = w, stack_var = 2 * sum(p$cov %||% 0)) }))))
cat("\nleague within-lineup stack variance, wks 9-15 (current rosters):\n")
print(lg |> group_by(team) |> summarise(mean_stack_var = round(mean(stack_var), 1)) |> as.data.frame())
# rosters
Rc <- R
x1 <- apply_trade(R, "Monday Night Madison", c("Kyler Murray", "T.J. Hockenson"), "Josh Jacobs")
x2 <- apply_trade(x1$R, "Max’s TD Bombers", c("Patrick Mahomes", "Carnell Tate"), c("Luther Burden III", "Isaiah Likely"))
Rt <- x2$R; cat("\nTR drops us:", x1$drop_us, x2$drop_us, " them:", x1$drop_them, x2$drop_them, "\n")
sc_c <- scan(Rc, "current"); sc_t <- scan(Rt, "TR1+TR2")
cat("\nOur projected lineups (current) wk9 / wk12:\n"); print(lineup(Rc[Rc$owner == ME, ], 9)); print(lineup(Rc[Rc$owner == ME, ], 12))
cat("\nOur projected lineup (TR1+TR2) wk12:\n"); print(lineup(Rt[Rt$owner == ME, ], 12))
res <- bind_rows(sc_c$rows, sc_t$rows)
cat("\nPer week: stack_var = 2*sum cov within our lineup; cross_cov = sum cov(ours, theirs); dV_margin = stack_var - 2*cross_cov\n")
print(res, digits = 3, row.names = FALSE)
cat("\nAll covarying pairs:\n"); print(bind_rows(sc_c$pairs |> mutate(roster = "current"), sc_t$pairs |> mutate(roster = "TR")) |>
  select(roster, week, kind, a, b, rel, r, cov) |> as.data.frame(), digits = 3, row.names = FALSE)
# ---- price: per-week sd for us so that margin var = 2 SIG^2 + dV  (sd_us^2 = SIG^2 + dV)
sim_w <- function(M, sdmat, seed) { set.seed(seed); mu <- M + GAPS; n <- N
  W <- matrix(W0, n, 10, byrow = TRUE); PF <- matrix(PF0, n, 10, byrow = TRUE); d <- matrix(rnorm(n * 10, 0, 0), n, 10)
  for (k in seq_along(WEEKS)) { Z <- matrix(rnorm(n * 10), n, 10)
    S <- matrix(mu[, k], n, 10, byrow = TRUE) + d + sweep(Z, 2, sdmat[, k], `*`)
    if (WEEKS[k] == CUR) for (t in names(WK8_FIXED)) S[, match(t, teams)] <- WK8_FIXED[[t]]
    PF <- PF + S
    for (j in which(G$week == WEEKS[k])) { aw <- S[, G$ia[j]] > S[, G$ib[j]]
      W[, G$ia[j]] <- W[, G$ia[j]] + aw; W[, G$ib[j]] <- W[, G$ib[j]] + !aw } }
  rk <- t(apply(W * 1e4 + PF / 1e3, 1, function(x) rank(-x, ties.method = "first"))); colnames(rk) <- colnames(W) <- teams
  c(p = mean(rk[, ME] <= 4), w = mean(W[, ME])) }
base_sd <- matrix(SIG, 10, length(WEEKS), dimnames = list(teams, WEEKS))
price <- function(Mx, rows) { sdm <- base_sd; for (i in seq_len(nrow(rows))) sdm[ME, as.character(rows$week[i])] <- sqrt(max(1, SIG^2 + rows$dV_margin[i]))
  o <- t(sapply(SEED + 0:9, function(s) c(sim_w(Mx, base_sd, s), sim_w(Mx, sdm, s)))); colnames(o) <- c("p0", "w0", "p1", "w1")
  d <- o[, "p1"] - o[, "p0"]; dw <- o[, "w1"] - o[, "w0"]
  c(p0 = mean(o[, "p0"]) * 100, dP_pp = mean(d) * 100, dP_se = sd(d) / sqrt(10) * 100, dW = mean(dw)) }
Mt <- strength_matrix(Rt)
pr <- rbind(current = price(M0, sc_c$rows), `TR1+TR2` = price(Mt, sc_t$rows))
cat("\nPriced (10 seeds x N 20000, CRN; per-week our sd set so margin var = 2*SIG^2 + dV):\n"); print(round(pr, 3))
saveRDS(list(res = res, pr = pr, CS = CS, CO = CO, SDP = SDP, lg = lg, pairs = list(sc_c$pairs, sc_t$pairs)), file.path(A2, "t3_roster.rds"))
