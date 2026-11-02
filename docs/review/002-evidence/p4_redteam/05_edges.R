# P4 items 5-8: base edge cases, DEF keys, opt_total brute force, tiebreak, locale.
SC <- "docs/review/002-evidence"
source(file.path(SC, "sim_helpers.R")); source(file.path(SC, "p4_redteam/p4_engine.R"))
options(width = 220)
# ---- 5a: live-zeroed rostered players (base 0, not IR) ----
raw <- bind_rows(lapply(names(ex), function(w) ex[[w]] |> transmute(key, week = as.integer(w), proj, yteam))) |>
  group_by(key) |> summarise(base_raw = mean(proj[proj > 0]), n_nz = sum(proj > 0), n_ex = n(),
                             projs = paste(sprintf("%.1f", proj[order(week)]), collapse = "/"),
                             teams_seen = paste(unique(toupper(yteam)), collapse = ">"), .groups = "drop")
z <- R |> filter(is.na(injury) | !grepl("IR", injury)) |> left_join(raw, by = "key")
cat("=== rostered, not IR, base 0 (live rule or never projected) ===\n")
print(as.data.frame(z |> filter(base == 0) |> transmute(owner = substr(owner, 1, 16), player, pos, nfl, injury, base_raw = round(base_raw, 1), projs)))
cat("\n=== rostered with < 3 non-zero exports (rookies/returners): base rests on few weeks ===\n")
print(as.data.frame(z |> filter(base > 0, n_nz < 3) |> transmute(owner = substr(owner, 1, 16), player, pos, nfl, base = round(base, 1), n_nz, projs)))
cat("\n=== NFL team changed across exports (rostered + wire top) ===\n")
print(as.data.frame(raw |> filter(grepl(">", teams_seen)) |> inner_join(P |> select(key, player, owner), by = "key") |>
                      filter(owner %in% teams | grepl("^W|FA", owner)) |> select(player, owner, teams_seen, projs) |> head(20)))
cat("\n=== DEF keys: yteam spelling per export ===\n")
dk <- bind_rows(lapply(names(ex), function(w) ex[[w]] |> filter(pos == "DEF") |> transmute(w, player, yteam)))
print(dk |> group_by(player) |> summarise(spell = paste(unique(yteam), collapse = "|"), n = n(), .groups = "drop") |> filter(grepl("[|]", spell) | n < length(ex)) |> as.data.frame())
cat("DEF rows per export:", tapply(dk$player, dk$w, length), "\n")
cat("DEF players with >1 key across exports:", sum(tapply(dk$yteam, dk$player, function(v) length(unique(v))) > 1), "\n")
# ---- 6: brute-force optimal lineup vs greedy, all teams, all future weeks ----
brute <- function(pos, v) {
  idx <- seq_along(v); best <- -Inf
  q <- idx[pos == "QB"]; k <- idx[pos == "K"]; d <- idx[pos == "DEF"]; fl <- idx[pos %in% c("RB", "WR", "TE")]
  top1 <- function(i) if (length(i)) max(v[i]) else 0
  fixed <- top1(q) + top1(k) + top1(d)
  if (length(fl) == 0) return(fixed)
  # enumerate all 6-subsets of flex-eligible bodies (or fewer), assign optimally by brute force
  m <- min(6, length(fl)); cmb <- combn(fl, m, simplify = FALSE)
  for (cset in cmb) {
    p <- pos[cset]
    # need: 2 RB, 2 WR, 1 TE, 1 FLEX; with fewer bodies, partial
    nrb <- sum(p == "RB"); nwr <- sum(p == "WR"); nte <- sum(p == "TE")
    ok <- (min(nrb, 2) + min(nwr, 2) + min(nte, 1) + min(1, max(0, nrb - 2) + max(0, nwr - 2) + max(0, nte - 1))) == m
    if (ok) best <- max(best, sum(v[cset]))
  }
  if (!is.finite(best)) {   # fewer legal bodies than 6: fall back to exhaustive over smaller sets
    for (mm in (m - 1):1) { for (cset in combn(fl, mm, simplify = FALSE)) { p <- pos[cset]
      nrb <- sum(p == "RB"); nwr <- sum(p == "WR"); nte <- sum(p == "TE")
      if ((min(nrb, 2) + min(nwr, 2) + min(nte, 1) + min(1, max(0, nrb - 2) + max(0, nwr - 2) + max(0, nte - 1))) == mm)
        best <- max(best, sum(v[cset])) }; if (is.finite(best)) break } }
  fixed + best
}
mx <- 0
for (t in teams) { d <- active(R[R$owner == t, ]); for (w in WEEKS[-1]) {
  on <- d$nfl %in% ON[[as.character(w)]] & d$base > 0
  g <- opt_total(d$pos[on], d$base[on]); bf <- brute(d$pos[on], d$base[on]); mx <- max(mx, abs(g - bf)) } }
cat("\nmax |greedy - brute force| over 10 teams x wks 9-15 (no fill):", mx, "\n")
# ---- 7: tiebreak ----
s <- simulate_cond(M0)
PFs <- NULL  # recompute PF range from W and rank: need PF; re-run inline
set.seed(SEED); cat("W*1e4 + PF/1e3 safe iff PF < 1e7; PF0 range", range(PF0), "\n")
# compare to lexicographic order(W desc, PF desc) on a subsample, with PF re-simulated
simPF <- function(M, n = 2000, seed = SEED, fixed = WK8_FIXED) {
  set.seed(seed); mu <- M + GAPS
  W <- matrix(W0, n, 10, byrow = TRUE); PF <- matrix(PF0, n, 10, byrow = TRUE); d <- matrix(rnorm(n * 10, 0, 0), n, 10)
  for (k in seq_along(WEEKS)) { Z <- matrix(rnorm(n * 10), n, 10); S <- matrix(mu[, k], n, 10, byrow = TRUE) + d + Z * SIG
    if (WEEKS[k] == CUR) for (t in names(fixed)) S[, match(t, teams)] <- fixed[[t]]
    PF <- PF + S
    for (j in which(G$week == WEEKS[k])) { aw <- S[, G$ia[j]] > S[, G$ib[j]]; W[, G$ia[j]] <- W[, G$ia[j]] + aw; W[, G$ib[j]] <- W[, G$ib[j]] + !aw } }
  list(W = W, PF = PF) }
sp <- simPF(M0)
rk1 <- t(apply(sp$W * 1e4 + sp$PF / 1e3, 1, function(x) rank(-x, ties.method = "first")))
rk2 <- t(sapply(seq_len(nrow(sp$W)), function(i) { o <- order(-sp$W[i, ], -sp$PF[i, ]); r <- integer(10); r[o] <- 1:10; r }))
cat("tiebreak: identical ranks (n 2000):", identical(unname(rk1), unname(rk2)), " PF range sim", round(range(sp$PF)), "\n")
cat("share of sims where our 4th-place fate is decided on PF (we tie the 4th team on W):",
    mean(apply(cbind(sp$W, rk1), 1, function(r) { W <- r[1:10]; k <- r[11:20]; w4 <- W[k == 4]; W[match(ME, teams)] == w4 })), "\n")
cat("G games per week:", tapply(G$a, G$week, length), " each team once per week:",
    all(sapply(split(G, G$week), function(g) length(unique(c(g$a, g$b))) == 10)), "\n")
# ---- 8: locale ----
cat("\nlocale:", Sys.getlocale("LC_COLLATE"), " teams:", paste(match(teams, sort(teams, method = "radix")), collapse = ","), "\n")
