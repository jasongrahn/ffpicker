# Run the (patched, scratch) sim machinery as of origin week CUR_WEEK; save M, P, R, FILL. No repo writes.
OUT <- "docs/review/002-evidence/p2_stats"
suppressMessages(source(file.path(OUT, "league_sim_origin.R")))
M <- strength_matrix(R)
cat("origin", CUR, "export", EXDATE, "rostered", nrow(R), "FILL", paste(names(FILL), round(FILL, 1), collapse = " "), "\n")
saveRDS(list(CUR = CUR, M = M, P = P, R = R, FILL = FILL, ex = ex), file.path(OUT, sprintf("origin_%d.rds", CUR)))
