# Q1: P(top 4) vs P(championship). Playoffs wks 16-17, seeds 1v4 / 2v3, final wk17.
SCR <- "docs/review/002-evidence"
source(file.path(SCR, "sim_helpers.R")); source(file.path(SCR, "p3_decision/sim2.R"))
t0 <- Sys.time(); a <- simulate_cond(M0); b <- sim2(M0); cat("CRN check identical top4/W:",
  identical(a$top4, b$top4), identical(a$W, b$W), " secs/run ~", round(as.numeric(Sys.time() - t0) / 2, 1), "\n")
Mpo0 <- po_strength(R)
cat("wk16-17 strength (no byes):\n"); print(round(cbind(fut_9_15 = rowMeans(M0[, -1]), Mpo0), 1))
s <- sim2(M0, Mpo0)
cat(sprintf("\nbaseline seed1: P(top4) %.4f  P(champ) %.4f  P(champ|top4) %.3f  exp wins %.2f\n", P4(s), PC(s), PC(s) / P4(s), EW(s)))
cat("our seed | top4:\n"); print(round(prop.table(table(s$seed_us[s$top4[, MEi]])), 3))
inF <- s$final[, 1] == MEi | s$final[, 2] == MEi
cat(sprintf("P(win semi | top4) %.3f   P(win final | in final) %.3f\n", mean(inF[s$top4[, MEi]]), mean(s$champ[inF] == MEi)))
cat("league P(champ):\n"); print(round(setNames(tabulate(s$champ, 10) / N, teams), 3))

# +x pts/wk in regular wks 9-15 only, playoff wks 16-17 only, both. 5 seeds, CRN within seed.
res <- ms(function(sd) {
  b0 <- sim2(M0, Mpo0, seed = sd); p4 <- P4(b0); pc <- PC(b0)
  r <- function(M, Mp) { x <- sim2(M, Mp, seed = sd); c(P4(x) - p4, PC(x) - pc) }
  Mp5 <- Mpo0; Mp5[ME, ] <- Mp5[ME, ] + 5
  c(base_p4 = p4, base_pc = pc,
    setNames(r(addw(M0, 5), Mpo0), c("reg5_dP4", "reg5_dPC")),
    setNames(r(M0, Mp5), c("po5_dP4", "po5_dPC")),
    setNames(r(addw(M0, 5), Mp5), c("both5_dP4", "both5_dPC")),
    setNames(r(addw(M0, 10), Mpo0), c("reg10_dP4", "reg10_dPC")))
})
print(res, digits = 3)
# per point-week: regular +5 x 7 wks = 35 pt-wks; playoff +5 x 2 = 10 pt-wks
m <- setNames(res$mean, res$stat)
cat(sprintf("\nP(champ) per point-week: regular %.5f pp, playoff %.5f pp -> playoff/regular ratio %.2f\n",
  100 * m["reg5_dPC"] / 35, 100 * m["po5_dPC"] / 10, (m["po5_dPC"] / 10) / (m["reg5_dPC"] / 35)))
cat(sprintf("share of a full-season (+5 wks 9-17) P(champ) gain from wks 16-17: %.2f\n", m["po5_dPC"] / m["both5_dPC"]))
saveRDS(list(res = res, Mpo0 = Mpo0), file.path(OUT, "01_objective.rds"))
