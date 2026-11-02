# IR returns priced in P(top 4). Patched per-week strength (a4_common.R team_strength2).
source("docs/review/002-evidence/a4_wire/a4_common.R")
ADAMS_B <- mean(c(11.24, 11.72, 13.13, 13.14, 13.01, 13.33))   # his Yahoo weekly proj wks 4-6 exports, pre-IR
cat(sprintf("Adams base %.2f\n", ADAMS_B))
ov <- function(p, wks, b) data.frame(player = p, week = wks, base = b)
# cheapest drop for OUR roster given overrides (protected never dropped). Returns name.
cheapest <- function(Rx, ovr, protect) {
  me <- Rx[Rx$owner == ME, ]
  c <- setdiff(active(me)$player, protect)
  left <- vapply(c, function(p) mean(team_strength2(me[me$player != p, ], ovr)[-1]), 0)
  names(which.max(left))
}
run <- function(Rx, lab, ovr, Mb, protect = character(0), needdrop = FALSE) {
  drop <- NA_character_
  if (needdrop) { drop <- cheapest(Rx, ovr, protect); Rx <- Rx[!(Rx$owner == ME & Rx$player == drop), ] }
  Ma <- M_with(Rx, ovr, M = Mb)
  d <- dP(Ma, Mb)
  data.frame(scen = lab, drop = drop, d_pts = round(mean(Ma[ME, -1] - Mb[ME, -1]), 2),
             dP_pp = round(100 * d[["dP"]], 2), se_pp = round(100 * d[["sd_dP"]], 2), dW = round(d[["dW"]], 3))
}
Mtr <- strength_matrix(R_tr); Mnow <- strength_matrix(R_now)
QBS <- c("Matthew Stafford", "Kyler Murray", "Patrick Mahomes")
out <- rbind(
  run(R_tr, "TR: Etienne wk9+ @8.5 (15th spot)", ov("Travis Etienne Jr.", 9:15, 8.5), Mtr),
  run(R_tr, "TR: Etienne wk9+ @9.7", ov("Travis Etienne Jr.", 9:15, 9.7), Mtr),
  run(R_tr, "TR: Adams wk12+ @12.6", ov("Davante Adams", 12:15, ADAMS_B), Mtr),
  run(R_tr, "TR: Adams wk13+ @12.6", ov("Davante Adams", 13:15, ADAMS_B), Mtr),
  run(R_tr, "TR: Adams wk12+ @10 (rusty)", ov("Davante Adams", 12:15, 10), Mtr),
  run(R_tr, "TR: Etienne 8.5 + Adams wk12 (drop)", rbind(ov("Travis Etienne Jr.", 9:15, 8.5), ov("Davante Adams", 12:15, ADAMS_B)), Mtr, QBS, TRUE),
  run(R_now, "NOW: Etienne wk9+ @8.5 (drop, QBs kept)", ov("Travis Etienne Jr.", 9:15, 8.5), Mnow, QBS, TRUE),
  run(R_now, "NOW: Adams wk12+ @12.6 (drop, QBs kept)", ov("Davante Adams", 12:15, ADAMS_B), Mnow, QBS, TRUE))
print(out, row.names = FALSE)
cat("\nper-week our strength, TR + Adams wk12:\n")
print(round(rbind(base = Mtr[ME, ], adams = team_strength2(R_tr[R_tr$owner == ME, ], ov("Davante Adams", 12:15, ADAMS_B))), 1))
