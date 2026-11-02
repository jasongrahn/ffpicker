# Q3 checkpoints: P(top 4 | our wk9/wk10/wk11 results). Baseline, TR1+TR2 from wk9, TR1+TR2 delayed to wk10,
# and what extra strength from wk11 buys after a 0-2 start. 10 seeds, CRN. (fix: wk8 game excluded)
SCR <- "docs/review/002-evidence"
source(file.path(SCR, "sim_helpers.R")); source(file.path(SCR, "p3_decision/sim2.R"))
S10 <- SEED + 0:9
T12 <- tradeM(R, list(TR1, TR2))
late <- function(Mt, Mb, w) { Mt[, as.character(WEEKS[WEEKS < w])] <- Mb[, as.character(WEEKS[WEEKS < w])]; Mt }
oj <- which((G$a == ME | G$b == ME) & G$week > CUR); stopifnot(identical(G$week[oj], 9:15))
ours <- function(s) sapply(oj, function(j) if (G$a[j] == ME) s$win[, j] else !s$win[, j])
st <- function(s) { o <- ours(s); t4 <- s$top4[, MEi]
  c(pW9 = mean(o[, 1]), pW10 = mean(o[, 2]),
    W9 = mean(t4[o[, 1]]), L9 = mean(t4[!o[, 1]]),
    WW = mean(t4[o[, 1] & o[, 2]]), WL = mean(t4[o[, 1] & !o[, 2]]), LW = mean(t4[!o[, 1] & o[, 2]]),
    LL = mean(t4[!o[, 1] & !o[, 2]]), LLL = mean(t4[!o[, 1] & !o[, 2] & !o[, 3]]),
    pLL = mean(!o[, 1] & !o[, 2]), all = mean(t4)) }
r <- ms(seeds = S10, function(sd) {
  b <- st(sim2(M0, seed = sd)); t <- st(sim2(T12$M, seed = sd)); t10 <- st(sim2(late(T12$M, M0, 10), seed = sd))
  x <- sapply(c(5, 10, 15), function(v) st(sim2(addw(T12$M, v, wk = 11:15), seed = sd))["LL"])
  c(setNames(b, paste0("base_", names(b))), setNames(t, paste0("tr_", names(t))),
    setNames(t10, paste0("tr10_", names(t10))), setNames(x, paste0("tr_LL_plus", c(5, 10, 15), "_from11")))
})
options(width = 140); print(r, digits = 3)
saveRDS(r, file.path(OUT, "05_checkpoints.rds"))
