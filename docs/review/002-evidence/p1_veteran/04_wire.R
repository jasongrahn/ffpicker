SCR <- "docs/review/002-evidence"
suppressMessages(source(file.path(SCR, "sim_helpers.R")))
Y <- readRDS(file.path(SCR, "p1_veteran/Y.rds"))
options(width = 220)
av <- Y |> filter(owner == "FA" | grepl("^W [(]", owner))
show <- function(d) print(as.data.frame(d |> transmute(owner, player, pos, nfl = yteam, inj = injury, proj8 = proj, base = round(base, 1), pct = pct_ros,
   gp, ppg = round(ppg, 1), l3 = round(ppg_l3, 1), snap_l3 = round(100 * snap_l3), snap_prev = round(100 * snap_prev), tsh_l3 = round(100 * tsh_l3), opp_l3 = round(opp_l3, 1), wks)), row.names = FALSE)
cat("=== WIRE QBs (top by base) ===\n"); show(av |> filter(pos == "QB") |> arrange(desc(base)) |> head(8))
cat("\n=== WIRE RB by opp_l3 (>= 8) ===\n"); show(av |> filter(pos == "RB", coalesce(opp_l3, 0) >= 8) |> arrange(desc(opp_l3)) |> head(15))
cat("\n=== WIRE WR/TE by opp_l3 (>= 5) ===\n"); show(av |> filter(pos %in% c("WR", "TE"), coalesce(opp_l3, 0) >= 5) |> arrange(desc(opp_l3)) |> head(20))
cat("\n=== WIRE RB with rising snaps (snap_l3 - snap_prev >= 15pp) ===\n"); show(av |> filter(pos == "RB", snap_l3 - snap_prev >= 0.15) |> arrange(desc(snap_l3 - snap_prev)))
cat("\n=== WIRE DST: count avail ===\n"); print(nrow(av |> filter(pos == "DEF")))
