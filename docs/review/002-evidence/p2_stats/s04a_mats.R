# Build strength matrices (baseline, TR1, TR2, TR1+TR2) under the current BASE env; save to scratch.
SC <- "docs/review/002-evidence"
source(file.path(SC, "sim_helpers.R"))
eval(local({ L <- readLines("dev/weekly/trade_finder.R"); L <- L[grep("^CAP <- ", L):(grep("^mine <- ", L) - 1)]; parse(text = L[!grepl("^(M0|p0) <- ", L)]) }))   # CAP, settle, apply_trade, lab; range by pattern (lines shift)
t1 <- apply_trade(R, "Monday Night Madison", c("Kyler Murray", "T.J. Hockenson"), "Josh Jacobs")
t2 <- apply_trade(R, "Max’s TD Bombers", c("Patrick Mahomes", "Carnell Tate"), c("Luther Burden III", "Isaiah Likely"))
t12 <- apply_trade(t1$R, "Max’s TD Bombers", c("Patrick Mahomes", "Carnell Tate"), c("Luther Burden III", "Isaiah Likely"))
cat("BASE", BASE, "| drops: TR1 us", t1$drop_us, "them", t1$drop_them, "| TR2 us", t2$drop_us, "them", t2$drop_them, "\n")
L <- list(M0 = M0, M1 = strength_matrix(t1$R), M2 = strength_matrix(t2$R), M12 = strength_matrix(t12$R))
for (n in names(L)) cat(n, "us fut", round(fut(L[[n]][ME, ]), 2), "| P", pt4(simulate_cond(L[[n]])), "\n")
saveRDS(L, file.path(SC, "p2_stats", sprintf("mats_%s.rds", BASE)))
