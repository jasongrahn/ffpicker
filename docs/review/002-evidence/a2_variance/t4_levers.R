# Task 3/4 pricing: specific weekly-variance options + PERSISTENT (season-level) variance on our team only.
# 10 seeds x N 20000, CRN (weekly Z from seed; persistent draws from seed+7777 so baseline Z unchanged).
SCR <- "docs/review/002-evidence"
suppressMessages(source(file.path(SCR, "sim_helpers.R")))
eval(local({ L <- readLines("dev/weekly/trade_finder.R"); L <- L[grep("^CAP <- ", L):(grep("^mine <- ", L) - 1)]; parse(text = L[!grepl("^(M0|p0) <- ", L)]) }))   # CAP, settle, apply_trade, lab; range by pattern (lines shift)
x1 <- apply_trade(R, "Monday Night Madison", c("Kyler Murray", "T.J. Hockenson"), "Josh Jacobs")
Mt <- strength_matrix(apply_trade(x1$R, "Max’s TD Bombers", c("Patrick Mahomes", "Carnell Tate"), c("Luther Burden III", "Isaiah Likely"))$R)
sim4 <- function(M, seed, dV = rep(0, length(WEEKS)), shift = NULL, n = N) {
  set.seed(seed + 7777); u <- runif(n); g <- rnorm(n)
  bump <- if (is.null(shift)) rep(0, n) else shift(u, g)               # persistent, wks 9-15
  set.seed(seed); mu <- M + GAPS
  W <- matrix(W0, n, 10, byrow = TRUE); PF <- matrix(PF0, n, 10, byrow = TRUE); i_me <- match(ME, teams)
  for (k in seq_along(WEEKS)) { Z <- matrix(rnorm(n * 10), n, 10); sdv <- rep(SIG, 10); sdv[i_me] <- sqrt(SIG^2 + dV[k])
    S <- matrix(mu[, k], n, 10, byrow = TRUE) + sweep(Z, 2, sdv, `*`)
    if (WEEKS[k] > CUR) S[, i_me] <- S[, i_me] + bump
    if (WEEKS[k] == CUR) for (t in names(WK8_FIXED)) S[, match(t, teams)] <- WK8_FIXED[[t]]
    PF <- PF + S
    for (j in which(G$week == WEEKS[k])) { aw <- S[, G$ia[j]] > S[, G$ib[j]]
      W[, G$ia[j]] <- W[, G$ia[j]] + aw; W[, G$ib[j]] <- W[, G$ib[j]] + !aw } }
  rk <- t(apply(W * 1e4 + PF / 1e3, 1, function(x) rank(-x, ties.method = "first")))
  c(p = mean(rk[, i_me] <= 4), w = mean(W[, i_me])) }
wk <- function(ws, v) { d <- rep(0, length(WEEKS)); d[WEEKS %in% ws] <- v; d }
SDQ <- 7.11; SDW <- 6.79; SDT <- 5.50; SDD <- 5.18
arms <- list(
  `Adams+Stafford stack wks12-15 (QB-WR r .392)` = list(dV = wk(12:15, 2 * .392 * SDQ * SDW)),
  `DST faces opp QB every wk (r -.355)` = list(dV = wk(9:15, 2 * .355 * SDD * SDQ)),
  `max stack QB+WR+TE same team every wk` = list(dV = wk(9:15, 2 * (.392 * SDQ * SDW + .275 * SDQ * SDT + .015 * SDW * SDT))),
  `persistent N(0,3^2) our strength` = list(shift = function(u, g) 3 * g),
  `persistent N(0,6^2)` = list(shift = function(u, g) 6 * g),
  `persistent N(0,10^2)` = list(shift = function(u, g) 10 * g),
  `sure +2/wk` = list(shift = function(u, g) rep(2, length(u))),
  `25% x +8/wk (EV +2)` = list(shift = function(u, g) 8 * (u < .25)),
  `10% x +20/wk (EV +2)` = list(shift = function(u, g) 20 * (u < .10)),
  `sure +4/wk` = list(shift = function(u, g) rep(4, length(u))),
  `33% x +12/wk (EV +4)` = list(shift = function(u, g) 12 * (u < 1/3)))
out <- list()
for (rost in c("current", "TR1+TR2")) { M <- if (rost == "current") M0 else Mt
  for (s in SEED + 0:9) { b <- sim4(M, s)
    for (a in names(arms)) { r <- do.call(sim4, c(list(M = M, seed = s), arms[[a]]))
      out[[length(out) + 1]] <- data.frame(roster = rost, arm = a, seed = s, p0 = b[1], dP = r[1] - b[1], dW = r[2] - b[2]) } } }
o <- do.call(rbind, out)
res <- o |> group_by(roster, arm) |> summarise(p0 = 100 * mean(p0), dP_pp = 100 * mean(dP), se_pp = 100 * sd(dP) / sqrt(n()),
  dW = mean(dW), .groups = "drop") |> mutate(pts_eq = dP_pp / 0.493) |> arrange(roster, match(arm, names(arms)))
print(as.data.frame(res), digits = 3, row.names = FALSE)
saveRDS(o, file.path(SCR, "a2_variance", "t4_levers.rds"))
