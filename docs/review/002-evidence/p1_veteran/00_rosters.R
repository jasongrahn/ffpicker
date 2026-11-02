# P1 veteran: dump all rosters (sim R) + base + 10-31 proj, and nflreadr pull structure
SCR <- "docs/review/002-evidence"
suppressMessages(source(file.path(SCR, "sim_helpers.R")))
cat("CUR", CUR, "EXDATE", EXDATE, "\n")
print(CLEAN)
options(width = 200)
x <- R |> select(owner, player, pos, nfl, injury, proj, base, pct_ros) |> arrange(owner, pos, desc(base))
for (t in teams) { cat("\n==", t, "== fut strength", round(fut(M0[t, ]), 1), "\n"); print(as.data.frame(x |> filter(owner == t) |> select(-owner)), row.names = FALSE) }
cat("\nM0:\n"); print(round(M0, 1))
nf <- readRDS("data/nflreadr/pull_2026.rds"); cat("\npull names:", names(nf), "\n")
for (n in names(nf)) { cat(n, ":", paste(dim(nf[[n]]), collapse = "x"), "\n") }
