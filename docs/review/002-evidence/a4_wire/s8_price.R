# Price A4 levers in P(top 4), 5 seeds x 20000, CRN. Base worlds: TR (TR1+TR2, Tate-out) and NOW.
source("docs/review/002-evidence/a4_wire/a4_common.R")
Mtr <- strength_matrix(R_tr); Mnow <- strength_matrix(R_now)
add_wk <- function(M, v) { M[ME, names(v)] <- M[ME, names(v)] + v; M }   # v named by week
row <- function(lab, Ma, Mb) { d <- dP(Ma, Mb); data.frame(lever = lab, d_pts_wk = round(mean(Ma[ME, -1] - Mb[ME, -1]), 2),
  dP_pp = round(100 * d[["dP"]], 2), se = round(100 * d[["sd_dP"]], 2), dW = round(d[["dW"]], 3)) }
b <- pt4s(Mtr); a <- pt4s(Mnow)
cat(sprintf("baselines (5 seeds): TR %.2f%% (%.2f W) | NOW %.2f%% (%.2f W)\n", 100 * b["p"], b["w"], 100 * a["p"], a["w"]))
# DST: stream plan vs holding Chiefs all season (rule: -0.40 DST pts per opp implied pt)
fut <- readRDS(paste0("docs/review/002-evidence/a4_wire/", "implied_wk9_15.rds"))
plan <- readRDS("docs/review/002-evidence/a4_wire/dst_plan.rds") |> filter(week <= 15)
kc <- fut |> filter(tm == "KC", week <= 15) |> select(week, opp) |> left_join(fut |> select(week, tm, imp_hat), by = c("week", "opp" = "tm"))
g <- 0.40 * (kc$imp_hat[match(plan$week, kc$week)] - plan$opp_imp); names(g) <- plan$week
cat("DST stream gain vs hold Chiefs, by week:", paste(names(g), round(g, 2), collapse = " | "), "\n")
out <- rbind(
  row("DST stream plan vs hold Chiefs (TR)", add_wk(Mtr, g), Mtr),
  row("DST stream plan vs hold Chiefs (NOW)", add_wk(Mnow, g), Mnow),
  row("wk11 QB: weak stream 15.5 vs Stroud 18.3 (TR)", add_wk(Mtr, c(`11` = 15.5 - 18.28)), Mtr),
  row("wk11 QB slot EMPTY (forgot) vs Stroud (TR)", add_wk(Mtr, c(`11` = -18.28)), Mtr))
for (x in c(2, 4, 6, 8)) out <- rbind(out, row(sprintf("hit world: +%d pts/wk wks 11-15 (TR)", x), add_wk(Mtr, setNames(rep(x, 5), 11:15)), Mtr))
for (x in c(4, 6)) out <- rbind(out, row(sprintf("hit world: +%d pts/wk wks 11-15 (NOW)", x), add_wk(Mnow, setNames(rep(x, 5), 11:15)), Mnow))
# a stash that hits as a 14-ppg WR / 15-ppg RB from wk11, in the 15th (open) spot post-trade
st <- function(pos, b) { r <- R_tr[R_tr$player == "Isaiah Likely", ][1, ]; r$player <- "STASH"; r$pos <- pos; r$nfl <- "NO"; r$base <- 0; r$proj <- 0; r$injury <- NA; r }
for (z in list(c("WR", 14), c("RB", 15), c("WR", 12))) {
  Rx <- bind_rows(R_tr, st(z[1], 0)); ov <- data.frame(player = "STASH", week = 11:15, base = as.numeric(z[2]))
  out <- rbind(out, row(sprintf("stash hits: %s @%s from wk11, 15th spot (TR)", z[1], z[2]), M_with(Rx, ov, Mtr), Mtr))
}
print(out, row.names = FALSE)
