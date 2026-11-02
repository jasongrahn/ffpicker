# P4: partner side of TR1/TR2 in wins (acceptance proxy) under corrections; misc footguns.
SC <- "docs/review/002-evidence"
source(file.path(SC, "sim_helpers.R")); source(file.path(SC, "p4_redteam/p4_engine.R"))
eval(local({ L <- readLines("dev/weekly/trade_finder.R"); L <- L[grep("^CAP <- ", L):(grep("^mine <- ", L) - 1)]; parse(text = L[!grepl("^(M0|p0) <- ", L)]) }))   # CAP, settle, apply_trade, lab; range by pattern (lines shift)
MAD <- "Monday Night Madison"; MAX <- "Max’s TD Bombers"
R31 <- bind_rows(R |> filter(!(owner == MAD & player == "Titans")), P |> filter(player == "Jaguars") |> mutate(owner = MAD),
                 P |> filter(player == "Romeo Doubs") |> mutate(owner = MAD, injury = "IR"))
zero <- function(pl, wks) tidyr::expand_grid(player = pl, week = wks) |> mutate(val = 0)
OUTP <- c("Carnell Tate", "DeVonta Smith", "RJ Harvey", "Emeka Egbuka", "Brian Robinson Jr.", "Kyle Monangai", "Breece Hall", "David Montgomery", "Mike Evans")
IRR <- bind_rows(tibble(player = "Davante Adams", week = 12:15, val = 12.6), tibble(player = "Travis Etienne Jr.", week = 9:15, val = 8.5),
                 tibble(player = "Michael Pittman Jr.", week = 10:15, val = 7.0), tibble(player = "Romeo Doubs", week = 12:15, val = 8.5))
W <- list(W1_roster1031 = NULL, TATE_ONLY_wk10 = zero("Carnell Tate", 10), TATE_ONLY_wk10_15 = zero("Carnell Tate", 10:15),
          W4_inj2_IR = bind_rows(zero(OUTP, 9:10), IRR))
for (wn in names(W)) {
  a <- apply_trade(R31, MAD, c("Kyler Murray", "T.J. Hockenson"), "Josh Jacobs")$R
  b <- apply_trade(R31, MAX, c("Patrick Mahomes", "Carnell Tate"), c("Luther Burden III", "Isaiah Likely"))$R
  Ms <- lapply(list(none = R31, TR1 = a, TR2 = b), function(Rx) strength2(Rx, ov = W[[wn]]))
  for (k in c("TR1", "TR2")) Ms[[k]][, "8"] <- Ms$none[, "8"]
  S <- lapply(Ms, function(M) sapply(SEEDS, function(s) { x <- simulate_cond(M, seed = s)
    c(us_p = mean(x$top4[, ME]), mad_p = mean(x$top4[, MAD]), mad_w = mean(x$W[, MAD]), max_p = mean(x$top4[, MAX]), max_w = mean(x$W[, MAX])) }))
  d1 <- rowMeans(S$TR1 - S$none); d2 <- rowMeans(S$TR2 - S$none)
  cat(sprintf("%-18s TR1: us dP %+.4f | Madison pts/wk %+.2f dP %+.4f dW %+.3f || TR2: us dP %+.4f | Max's pts/wk %+.2f dP %+.4f dW %+.3f (Max's P %.3f)\n",
              wn, d1["us_p"], fut(Ms$TR1[MAD, ]) - fut(Ms$none[MAD, ]), d1["mad_p"], d1["mad_w"],
              d2["us_p"], fut(Ms$TR2[MAX, ]) - fut(Ms$none[MAX, ]), d2["max_p"], d2["max_w"], mean(S$none["max_p", ])))
}
# us IR attribution (strength only)
f <- function(ov) fut(strength2(R31, ov = ov)[ME, ]) - fut(strength2(R31)[ME, ])
cat(sprintf("\nIR attribution, us pts/wk wks 9-15: Adams wk12-15 %+.2f | Etienne wk9-15 %+.2f\n",
            f(IRR |> filter(player == "Davante Adams")), f(IRR |> filter(player == "Travis Etienne Jr."))))
cat(sprintf("Adams-only dP(top4): %+.4f (5 seeds)\n", dmp(strength2(R31, ov = IRR |> filter(player == "Davante Adams")), strength2(R31))["dP"]))
# footgun: unnamed sig_team
x <- simulate_cond(M0, sig_team = rep(SIG, 10), n = 2000)
cat("\nunnamed sig_team: any NA in W?", anyNA(x$W), " P(top4) us =", mean(x$top4[, ME]), "(silently computed)\n")
# multi-position among rostered, 10-31 pull
rt <- readRDS(file.path(SC, "p4_redteam/roster_truth.rds"))
cat("rostered multi-position rows 10-31:", sum(grepl(",", rt$b$pos[rt$b$owner %in% teams])), " | FA/W multi-pos rows:", sum(grepl(",", rt$b$pos[!rt$b$owner %in% teams])), "\n")
