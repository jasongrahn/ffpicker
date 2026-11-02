# Q3 sequencing/checkpoints, Q4 super-additivity + sweetener cost, Q5 arming. 10 seeds, CRN.
SCR <- "docs/review/002-evidence"
source(file.path(SCR, "sim_helpers.R")); source(file.path(SCR, "p3_decision/sim2.R"))
S10 <- SEED + 0:9
R_to <- R; R_to$base[R_to$player == "Carnell Tate"] <- 0          # Tate-out bound (log M1)
M0to <- strength_matrix(R_to); M0to[, "8"] <- M0[, "8"]
T1 <- tradeM(R, list(TR1)); T2 <- tradeM(R, list(TR2)); T12 <- tradeM(R, list(TR1, TR2))
T12to <- tradeM(R_to, list(TR1, TR2)); T2to <- tradeM(R_to, list(TR2))
cat("drops:", T12$dropped, "| fut d_us pts/wk: TR1", round(fut(T1$M[ME, ]) - fut(M0[ME, ]), 2),
    "TR2", round(fut(T2$M[ME, ]) - fut(M0[ME, ]), 2), "both", round(fut(T12$M[ME, ]) - fut(M0[ME, ]), 2),
    "| Tate-out base: both", round(fut(T12to$M[ME, ]) - fut(M0to[ME, ]), 2), "\n")
late <- function(Mt, Mb, w) { Mt[, as.character(WEEKS[WEEKS < w])] <- Mb[, as.character(WEEKS[WEEKS < w])]; Mt }
oj <- which(G$a == ME | G$b == ME); wk <- G$week[oj]
ours <- function(s) sapply(oj, function(j) if (G$a[j] == ME) s$win[, j] else !s$win[, j])
r <- ms(seeds = S10, function(sd) {
  b <- sim2(M0, seed = sd); p <- P4(b); w <- EW(b)
  d <- function(M, base = p) P4(sim2(M, seed = sd)) - base
  bto <- P4(sim2(M0to, seed = sd))
  st <- sim2(T12$M, seed = sd)
  ob <- ours(b); ot <- ours(st)
  cond <- function(s, o, w9, w10) mean(s$top4[o[, 1] == w9 & o[, 2] == w10, MEi])
  arm <- sapply(setdiff(teams, ME), function(t) d(addw(M0, 5, who = t)))
  mx14 <- d(addw(M0, 2.5, wk = 14, who = "Max’s TD Bombers"))
  bodies <- c("Brenton Strange", "Ollie Gordon II", "Rome Odunze", "Tre Tucker", "Denzel Boston", "Chiefs")
  p12 <- P4(st)
  sw <- sapply(bodies, function(x) { Rx <- T12$R[!(T12$R$owner == ME & T12$R$player == x), ]
    M <- strength_matrix(Rx); M[, "8"] <- M0[, "8"]; P4(sim2(M, seed = sd)) - p12 })
  c(base = p, TR1 = d(T1$M), TR2 = d(T2$M), both = p12 - p, both_dW = EW(st) - w,
    to_base = bto, to_TR2 = d(T2to$M, bto), to_both = d(T12to$M, bto),
    setNames(sapply(9:13, function(x) d(late(T12$M, M0, x))), paste0("both_from_wk", 9:13)),
    setNames(sapply(c(6, 8, 10, 12), function(x) d(addw(M0, x, wk = 11:15))), paste0("gen", c(6, 8, 10, 12), "_from11")),
    pW9 = mean(ob[, 1]), pW10 = mean(ob[, 2]),
    c_WW = cond(b, ob, TRUE, TRUE), c_WL = cond(b, ob, TRUE, FALSE), c_LW = cond(b, ob, FALSE, TRUE), c_LL = cond(b, ob, FALSE, FALSE),
    t_WW = cond(st, ot, TRUE, TRUE), t_WL = cond(st, ot, TRUE, FALSE), t_LW = cond(st, ot, FALSE, TRUE), t_LL = cond(st, ot, FALSE, FALSE),
    tpW9 = mean(ot[, 1]), tpW10 = mean(ot[, 2]),
    LL_plus10_from11 = { s2 <- sim2(addw(T12$M, 10, wk = 11:15), seed = sd); o2 <- ours(s2); cond(s2, o2, FALSE, FALSE) },
    c_L9 = mean(b$top4[!ob[, 1], MEi]), c_W9 = mean(b$top4[ob[, 1], MEi]),
    t_L9 = mean(st$top4[!ot[, 1], MEi]), t_W9 = mean(st$top4[ot[, 1], MEi]),
    setNames(arm, paste0("arm5_", setdiff(teams, ME))), max_wk14_2.5 = mx14,
    setNames(sw, paste0("sweet_", bodies)),
    ceil15 = d(addw(M0, 15)), ceil18.5 = d(addw(M0, 18.5)), ceil25 = d(addw(M0, 25)))
})
options(width = 140); print(r, digits = 3)
# who to root for, seed 1, N 20000
b <- sim2(M0); rf <- do.call(rbind, lapply(setdiff(which(G$week > CUR), oj), function(j) {
  aw <- b$win[, j]; pa <- mean(b$top4[aw, MEi]); pb <- mean(b$top4[!aw, MEi])
  data.frame(week = G$week[j], game = paste(G$a[j], "v", G$b[j]), root_for = ifelse(pa > pb, G$a[j], G$b[j]), swing = round(abs(pa - pb), 4)) }))
print(head(rf[order(-rf$swing), ], 10), row.names = FALSE)
saveRDS(list(r = r, rf = rf), file.path(OUT, "03_trades_seq.rds"))
