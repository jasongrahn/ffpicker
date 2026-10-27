# Trade finder, scored in WINS (handoff #44 test #2 follow-on). Every trade
# shape built on our QB surplus -- Stafford, Mahomes, Kyler: three QBs for one
# slot, and Kyler has no bye left -- against each of the nine other rosters.
# Each candidate scored as P(top 4) for US, common random numbers. The
# partner's strength change runs inside the sim, so a trade that arms a
# playoff rival is charged for it.
#
# Acceptance proxy: partner's own projected strength change, future weeks --
# they read the same Yahoo projections. Both sides > 0 = win-win on paper.
# Activity matters: Standings "Moves" SK 1, JJ 1 all season.
#
# Trades land week CUR+1 at the earliest (week CUR lineup set; review takes days).
# Rerun after each week's clean export lands; league_sim.R picks it up.
# Over the 15-man cap -> drop the body whose loss costs that roster least;
# for us that may be a QB (user 2026-10-21: "consider dropping Stafford").
# A dropped player goes to waivers, where a rival can claim him -- not costed.
source("dev/weekly/league_sim.R")
CAP <- 15; MINBASE <- 7                  # incoming: plausible starters only

M0 <- strength_matrix(R); s0 <- simulate(M0)
p0 <- colMeans(s0$top4); w0 <- colMeans(s0$W)

settle <- function(r, keep) {           # enforce cap, cheapest drop first
  dropped <- character(0)
  while (nrow(active(r)) > CAP) {
    c <- setdiff(active(r)$player, keep)
    left <- vapply(c, function(p) fut(team_strength(r[r$player != p, ])), numeric(1))
    d <- c[which.max(left)]; dropped <- c(dropped, d); r <- r[r$player != d, ]
  }
  list(r = r, dropped = dropped)
}
apply_trade <- function(Rx, tm, give, get) {
  us <- Rx[Rx$owner == ME, ]; th <- Rx[Rx$owner == tm, ]
  stopifnot(all(give %in% us$player), all(get %in% th$player))
  a <- settle(bind_rows(us[!us$player %in% give, ], th[th$player %in% get, ] |> mutate(owner = ME)), get)
  b <- settle(bind_rows(th[!th$player %in% get, ], us[us$player %in% give, ] |> mutate(owner = tm)), give)
  list(R = bind_rows(Rx[!Rx$owner %in% c(ME, tm), ], a$r, b$r), drop_us = a$dropped, drop_them = b$dropped)
}
lab <- function(p, Rx = R) paste(sprintf("%s %.1f", sub("^(\\S)\\S* ", "\\1. ", p),
                                        Rx$base[match(p, Rx$player)]), collapse = " + ")

mine <- active(R[R$owner == ME, ])
QB <- mine$player[mine$pos == "QB"]
FLX <- mine$player[mine$pos %in% c("RB", "WR", "TE")]
give_sets <- c(as.list(QB), combn(QB, 2, simplify = FALSE),
               unlist(lapply(QB, function(q) lapply(FLX, function(f) c(q, f))), recursive = FALSE))

cat(sprintf("baseline P(top4) %.3f, exp wins %.2f | our QBs: %s\n", p0[ME], w0[ME], lab(QB)))

cat(sprintf("\n=== QB market: partner's strength gain (pts/wk, %s) from adding one of our QBs, no drop ===\n", FUT))
qm <- bind_rows(lapply(setdiff(teams, ME), function(tm) {
  th <- R[R$owner == tm, ]; b0 <- fut(M0[tm, ])
  q <- active(th)[active(th)$pos == "QB", ]
  tibble(team = tm, record = sprintf("%d-%d", W0[tm], 6 - W0[tm]), their_QBs = lab(q$player),
         !!!setNames(lapply(QB, function(p) round(fut(team_strength(bind_rows(th, R[R$player == p, ]))) - b0, 2)),
                     sub("^(\\S)\\S* ", "\\1. ", QB)))
}))
print(as.data.frame(qm |> arrange(desc(.data[[sub("^(\\S)\\S* ", "\\1. ", QB[1])]]))), row.names = FALSE)

cat("\n... scanning trades\n")
t0 <- Sys.time()
cands <- bind_rows(lapply(setdiff(teams, ME), function(tm) {
  th <- active(R[R$owner == tm, ])
  IN <- th$player[th$pos %in% c("RB", "WR", "TE") & th$base >= MINBASE]
  get_sets <- c(as.list(IN), if (length(IN) >= 2) combn(IN, 2, simplify = FALSE))
  bind_rows(lapply(give_sets, function(g) bind_rows(lapply(get_sets, function(r) {
    x <- apply_trade(R, tm, g, r)
    tibble(team = tm, give = list(g), get = list(r), drop_us = paste(x$drop_us, collapse = ","),
           drop_them = paste(x$drop_them, collapse = ","),
           d_us = fut(team_strength(x$R[x$R$owner == ME, ])) - fut(M0[ME, ]),
           d_them = fut(team_strength(x$R[x$R$owner == tm, ])) - fut(M0[tm, ]))
  }))))
}))
cat(sprintf("%d candidate trades scanned in %.0fs\n", nrow(cands), as.numeric(difftime(Sys.time(), t0, units = "secs"))))

score <- function(Rx) { s <- simulate(strength_matrix(Rx)); list(p = colMeans(s$top4), w = colMeans(s$W)) }
fmt <- function(df) df |> mutate(give = vapply(give, lab, ""), get = vapply(get, function(p) lab(p), ""),
                                 across(where(is.numeric), ~ round(.x, 3)))

# shortlist PER PARTNER: a league-wide top-k by strength gain is all one
# partner and never simulates the non-contenders, where arming them is cheap
pick <- function(df, k) df |> mutate(gk = vapply(get, paste, "", collapse = "|")) |>
  group_by(team, gk) |> slice_max(d_us, n = 1, with_ties = FALSE) |>
  group_by(team) |> slice_max(d_us, n = k, with_ties = FALSE) |> ungroup() |> select(-gk)
ww <- pick(cands |> filter(d_us > 0, d_them >= 0), 3) |> mutate(kind = "win-win")
sw <- pick(cands |> filter(d_us > 0, d_them < 0, d_them >= -2), 2) |> mutate(kind = "they lose <=2")
short <- bind_rows(ww, sw)
sc <- lapply(seq_len(nrow(short)), function(i) { x <- apply_trade(R, short$team[i], short$give[[i]], short$get[[i]]); score(x$R) })
short <- short |> mutate(dP_us = vapply(sc, function(s) s$p[ME], 0) - p0[ME],
                         dP_them = mapply(function(s, tm) s$p[tm], sc, team) - p0[team],
                         dW_us = vapply(sc, function(s) s$w[ME], 0) - w0[ME])

cat(sprintf("\n=== TOP TRADES, scored in wins. d_* = pts/wk %s; dP = change in P(top 4) ===\n", FUT))
out <- fmt(short |> arrange(desc(dP_us))) |>
  select(kind, team, give, get, drop_us, drop_them, d_us, d_them, dP_us, dP_them, dW_us)
print(as.data.frame(out), row.names = FALSE, right = FALSE)

cat("\n=== best TWO-trade combos: different partners, disjoint gives, applied in sequence ===\n")
top <- short |> filter(kind == "win-win", dP_us > 0) |> arrange(desc(dP_us)) |> head(12)
combos <- list()
for (i in seq_len(nrow(top))) for (j in seq_len(nrow(top))) if (i < j && top$team[i] != top$team[j] &&
    !length(intersect(top$give[[i]], top$give[[j]]))) {
  x1 <- apply_trade(R, top$team[i], top$give[[i]], top$get[[i]])
  if (!all(top$give[[j]] %in% x1$R$player[x1$R$owner == ME])) next
  x2 <- apply_trade(x1$R, top$team[j], top$give[[j]], top$get[[j]])
  if (!any(active(x2$R[x2$R$owner == ME, ])$pos == "QB")) next
  combos[[length(combos) + 1]] <- list(i = i, j = j, R = x2$R,
    d_us = fut(team_strength(x2$R[x2$R$owner == ME, ])) - fut(M0[ME, ]))
}
if (length(combos)) {
  combos <- combos[order(-vapply(combos, `[[`, 0, "d_us"))][seq_len(min(5, length(combos)))]
  print(as.data.frame(bind_rows(lapply(combos, function(c) { s <- score(c$R)
    tibble(trade_1 = paste(top$team[c$i], ":", lab(top$give[[c$i]]), "->", lab(top$get[[c$i]])),
           trade_2 = paste(top$team[c$j], ":", lab(top$give[[c$j]]), "->", lab(top$get[[c$j]])),
           d_us = round(c$d_us, 2), dP_us = round(s$p[ME] - p0[ME], 3), dW_us = round(s$w[ME] - w0[ME], 2)) }))),
    row.names = FALSE, right = FALSE)
}

cat("\n=== FREE moves: best available RB/WR/TE (FA = now, W = claim, we are 9th of 10) ===\n")
avail <- AVAIL |> filter(pos %in% c("RB", "WR", "TE"), base >= 9)   # league_sim.R: no IR, no O
if (!nrow(avail)) { cat("none with base >= 9. Best available by position:\n")
  print(as.data.frame(REPL |> transmute(pos, player, yteam, owner, base = round(base, 2))), row.names = FALSE)
  avail <- AVAIL[0, ] }
fa <- bind_rows(tibble(player = character(), pos = character(), nfl = character(), status = character(),
                       base = numeric(), drop = character(), d_us = numeric(), Rx = list()),
                lapply(seq_len(nrow(avail)), function(i) {
  # QBs protected: they are the trade currency, and settle() sees a 3rd QB as free
  x <- settle(bind_rows(R[R$owner == ME, ], avail[i, ] |> mutate(owner = ME)), c(avail$player[i], QB))
  tibble(player = avail$player[i], pos = avail$pos[i], nfl = avail$nfl[i], status = avail$owner[i],
         base = round(avail$base[i], 2), drop = paste(x$dropped, collapse = ","),
         d_us = fut(team_strength(x$r)) - fut(M0[ME, ]), Rx = list(bind_rows(R[R$owner != ME, ], x$r)))
})) |> arrange(desc(d_us)) |> head(6)
fa$dP_us <- vapply(fa$Rx, function(Rx) score(Rx)$p[ME], 0) - p0[ME]
print(as.data.frame(fa |> select(-Rx) |> mutate(across(where(is.numeric), ~ round(.x, 3)))), row.names = FALSE)
saveRDS(list(cands = cands, short = short, combos = if (length(combos)) lapply(combos, `[`, c("i", "j", "d_us")),
             top = top, fa = fa |> select(-Rx)), sprintf("data/weekly/2026_trade_scan_wk%d.rds", CUR))
