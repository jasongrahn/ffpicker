# Task 2c: shape of our league's weekly scores + sim noise; does an empirical (non-normal) noise model
# change P(top 4) or the value of variance? Quantile mapping Z -> Q(pnorm(Z)) keeps CRN.
SCR <- "docs/review/002-evidence"
suppressMessages(source(file.path(SCR, "sim_helpers.R")))
sk <- function(x) { x <- x - mean(x); mean(x^3) / mean(x^2)^1.5 }
ku <- function(x) { x <- x - mean(x); mean(x^4) / mean(x^2)^2 - 3 }
bsci <- function(x, f, B = 4000) { set.seed(2); q <- quantile(replicate(B, f(sample(x, replace = TRUE))), c(.025, .975)); sprintf("[%+.2f, %+.2f]", q[1], q[2]) }
pf <- sch$pf[!is.na(sch$pf)]
pfw <- sch |> filter(!is.na(pf)) |> group_by(team) |> mutate(r = pf - mean(pf)) |> pull(r)
e <- cl$pf - cl$ceiling
mg <- sch |> filter(!is.na(pf), team < opponent) |> mutate(m = pf - pa) |> pull(m)
for (nm in c("pf", "pfw", "e")) { x <- get(nm)
  cat(sprintf("%-4s n %3d mean %7.2f sd %6.2f skew %+.2f %s exkurt %+.2f %s shapiro p %.3f\n", nm, length(x), mean(x), sd(x),
    sk(x), bsci(x, sk), ku(x), bsci(x, ku), shapiro.test(x)$p.value)) }
cat(sprintf("margins (one row per game) n %d sd %.2f exkurt %+.2f\n", length(mg), sd(mg), ku(mg)))
# underdog tail check, empirical e: P(e_us - e_opp > d) for d = 16 (typical deficit) vs normal
set.seed(3); ee <- e - mean(e); dd <- outer(ee, ee, "-"); dd <- dd[row(dd) != col(dd)]
for (d0 in c(10, 16, 20)) cat(sprintf("P(e1 - e2 > %d): empirical pairs %.3f vs normal %.3f\n", d0, mean(dd > d0), 1 - pnorm(d0 / (sqrt(2) * sd(e)))))
zs <- (e - mean(e)) / sd(e)
q_emp <- function(u) quantile(zs, u, type = 8, names = FALSE)          # clamped at observed extremes
q_t5 <- function(u) qt(u, 5) / sqrt(5 / 3)                              # fat-tail stress, unit var
q_sm <- local({ set.seed(4); h <- 0.35; x <- sample(zs, 2e5, TRUE) + rnorm(2e5, 0, h); x <- (x - mean(x)) / sd(x)
  function(u) quantile(x, u, names = FALSE) })                          # smoothed bootstrap
sim_q <- function(M, qf = NULL, seed = SEED, sig_team = NULL, n = N, fixed = WK8_FIXED) {
  set.seed(seed); mu <- M + GAPS
  sd_t <- if (is.null(sig_team)) rep(SIG, 10) else sig_team[teams]
  W <- matrix(W0, n, 10, byrow = TRUE); PF <- matrix(PF0, n, 10, byrow = TRUE)
  d <- matrix(rnorm(n * 10, 0, 0), n, 10)
  for (k in seq_along(WEEKS)) {
    Z <- matrix(rnorm(n * 10), n, 10); if (!is.null(qf)) Z[] <- qf(pnorm(Z))
    S <- matrix(mu[, k], n, 10, byrow = TRUE) + d + sweep(Z, 2, sd_t, `*`)
    if (WEEKS[k] == CUR) for (t in names(fixed)) S[, match(t, teams)] <- fixed[[t]]
    PF <- PF + S
    for (j in which(G$week == WEEKS[k])) { aw <- S[, G$ia[j]] > S[, G$ib[j]]
      W[, G$ia[j]] <- W[, G$ia[j]] + aw; W[, G$ib[j]] <- W[, G$ib[j]] + !aw }
  }
  rk <- t(apply(W * 1e4 + PF / 1e3, 1, function(x) rank(-x, ties.method = "first"))); colnames(rk) <- colnames(W) <- teams
  c(p = mean(rk[, ME] <= 4), w = mean(W[, ME]))
}
stopifnot(all.equal(sim_q(M0), pt4(simulate_cond(M0)), check.attributes = FALSE) == TRUE)   # normal arm == helper
sg <- setNames(rep(SIG, 10), teams); sg2 <- sg; sg2[ME] <- SIG + 2
Mx <- M0; Mx[ME, -1] <- Mx[ME, -1] + 1
out <- list()
for (s in SEED + 0:4) for (nm in c("normal", "emp", "smooth", "t5")) {
  qf <- switch(nm, normal = NULL, emp = q_emp, smooth = q_sm, t5 = q_t5)
  b <- sim_q(M0, qf, s); v <- sim_q(M0, qf, s, sg2); m1 <- sim_q(Mx, qf, s)
  out[[length(out) + 1]] <- data.frame(seed = s, model = nm, p = b[1], w = b[2], dP_sd2 = v[1] - b[1], dP_mu1 = m1[1] - b[1])
}
o <- do.call(rbind, out)
print(o |> group_by(model) |> summarise(p_top4 = 100 * mean(p), exp_w = mean(w), dP_sd2_pp = 100 * mean(dP_sd2),
  dP_mu1_pp = 100 * mean(dP_mu1), pts_per_sd = mean(dP_sd2) / mean(dP_mu1) / 2, .groups = "drop") |> as.data.frame(), digits = 3)
saveRDS(o, file.path(SCR, "a2_variance", "t2c_shape.rds"))
