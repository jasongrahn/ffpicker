# P4: size each finding in dP(top 4) for us AND in TR1/TR2 dP. 5 seeds, CRN. Run from repo root.
SC <- "docs/review/002-evidence"
source(file.path(SC, "sim_helpers.R")); source(file.path(SC, "p4_redteam/p4_engine.R"))
eval(local({ L <- readLines("dev/weekly/trade_finder.R"); L <- L[grep("^CAP <- ", L):(grep("^mine <- ", L) - 1)]; parse(text = L[!grepl("^(M0|p0) <- ", L)]) }))   # CAP, settle, apply_trade, lab; range by pattern (lines shift)
MAD <- "Monday Night Madison"; MAX <- "Max’s TD Bombers"; SK <- "Sunday Kevin"
TR <- list(TR1 = list(tm = MAD, give = c("Kyler Murray", "T.J. Hockenson"), get = "Josh Jacobs"),
           TR2 = list(tm = MAX, give = c("Patrick Mahomes", "Carnell Tate"), get = c("Luther Burden III", "Isaiah Likely")))
states <- function(Rx) {
  a <- apply_trade(Rx, TR$TR1$tm, TR$TR1$give, TR$TR1$get)
  b <- apply_trade(Rx, TR$TR2$tm, TR$TR2$give, TR$TR2$get)
  ab <- apply_trade(a$R, TR$TR2$tm, TR$TR2$give, TR$TR2$get)
  list(none = Rx, TR1 = a$R, TR2 = b$R, both = ab$R,
       drops = c(TR1 = paste(a$drop_us, "|", a$drop_them), TR2 = paste(b$drop_us, "|", b$drop_them)))
}
# --- roster truth 10-31: Madison -Titans +Jaguars +Doubs(IR) ---
R31 <- bind_rows(R |> filter(!(owner == MAD & player == "Titans")),
                 P |> filter(player == "Jaguars") |> mutate(owner = MAD),
                 P |> filter(player == "Romeo Doubs") |> mutate(owner = MAD, injury = "IR"))
stopifnot(sum(R31$owner == MAD) == 16)
# --- overrides ---
zero <- function(pl, wks) tidyr::expand_grid(player = pl, week = wks) |> mutate(val = 0)
OUTP <- c("Carnell Tate", "DeVonta Smith", "RJ Harvey", "Emeka Egbuka", "Brian Robinson Jr.", "Kyle Monangai",   # tagged O
          "Breece Hall", "David Montgomery", "Mike Evans")                                                     # Q, no game in 2+ team games
stopifnot(all(OUTP %in% R$player))
IRR <- bind_rows(tibble(player = "Davante Adams", week = 12:15, val = 12.6),        # IR hamstring since wk7; LA bye 11
                 tibble(player = "Travis Etienne Jr.", week = 9:15, val = 8.5),     # NO bye 8 done; wks1-3 8.5 ppg, wk3 proj 9.7
                 tibble(player = "Michael Pittman Jr.", week = 10:15, val = 7.0),   # SK; IR foot since wk5; PIT bye 9
                 tibble(player = "Romeo Doubs", week = 12:15, val = 8.5))           # Madison; IR since wk7; NE bye 11
OV <- list(INJ2 = zero(OUTP, 9:10), INJ7 = zero(OUTP, 9:15), IR = IRR,
           INJ2_IR = bind_rows(zero(OUTP, 9:10), IRR), INJ7_IR = bind_rows(zero(OUTP, 9:15), IRR),
           IR_us_only = IRR |> filter(player %in% c("Davante Adams", "Travis Etienne Jr.")),
           IR_rivals_only = IRR |> filter(!player %in% c("Davante Adams", "Travis Etienne Jr.")))
worlds <- list(
  W0_helper      = list(R = R,   ov = NULL,  leakfix = FALSE),
  W0f_leakfix    = list(R = R,   ov = NULL,  leakfix = TRUE),
  W1_roster1031  = list(R = R31, ov = NULL,  leakfix = TRUE),
  W2_inj_2wk     = list(R = R31, ov = OV$INJ2, leakfix = TRUE),
  W2b_inj_7wk    = list(R = R31, ov = OV$INJ7, leakfix = TRUE),
  W3_IR_all      = list(R = R31, ov = OV$IR, leakfix = TRUE),
  W3a_IR_us      = list(R = R31, ov = OV$IR_us_only, leakfix = TRUE),
  W3b_IR_rivals  = list(R = R31, ov = OV$IR_rivals_only, leakfix = TRUE),
  W4_inj2_IR     = list(R = R31, ov = OV$INJ2_IR, leakfix = TRUE),
  W5_inj7_IR     = list(R = R31, ov = OV$INJ7_IR, leakfix = TRUE))
res <- list(); fu <- list()
for (wn in names(worlds)) {
  wd <- worlds[[wn]]; st <- states(wd$R)
  Ms <- lapply(st[c("none", "TR1", "TR2", "both")], function(Rx) strength2(Rx, ov = wd$ov))
  if (wd$leakfix) for (k in c("TR1", "TR2", "both")) Ms[[k]][, "8"] <- Ms$none[, "8"]
  pp <- sapply(Ms, function(M) mp(M))   # rows: p1,w1,p2,w2,... per seed
  P_ <- sapply(Ms, function(M) mp(M)["p", ])            # seeds x states
  W_ <- sapply(Ms, function(M) mp(M)["w", ])
  d <- P_[, -1] - P_[, 1]
  res[[wn]] <- tibble(world = wn, p_none = mean(P_[, 1]),
                      dP_TR1 = mean(d[, "TR1"]), dP_TR2 = mean(d[, "TR2"]), dP_both = mean(d[, "both"]),
                      rng_TR1 = sprintf("%.3f..%.3f", min(d[, "TR1"]), max(d[, "TR1"])),
                      rng_TR2 = sprintf("%.3f..%.3f", min(d[, "TR2"]), max(d[, "TR2"])),
                      dW_TR1 = mean(W_[, "TR1"] - W_[, "none"]), dW_TR2 = mean(W_[, "TR2"] - W_[, "none"]),
                      us_fut = fut(Ms$none[ME, ]), dus_TR1 = fut(Ms$TR1[ME, ]) - fut(Ms$none[ME, ]),
                      dus_TR2 = fut(Ms$TR2[ME, ]) - fut(Ms$none[ME, ]),
                      dthem_TR1 = fut(Ms$TR1[MAD, ]) - fut(Ms$none[MAD, ]), dthem_TR2 = fut(Ms$TR2[MAX, ]) - fut(Ms$none[MAX, ]))
  fu[[wn]] <- apply(Ms$none, 1, fut)
  cat(wn, "done; drops:", st$drops, "\n")
}
options(width = 250)
out <- bind_rows(res); print(as.data.frame(out |> mutate(across(where(is.numeric), ~ round(.x, 4)))), right = FALSE)
cat("\nper-team fut (wks 9-15) by world, minus W1 (10-31 rosters):\n")
FU <- do.call(cbind, fu); print(round(FU[, -(1:3)] - FU[, "W1_roster1031"], 2))
cat("\nW1 - W0 (roster truth) per team:\n"); print(round(FU[, "W1_roster1031"] - FU[, "W0_helper"], 2))
saveRDS(list(out = out, FU = FU), file.path(SC, "p4_redteam/scenarios.rds"))
