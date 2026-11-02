# P4: per-seed spread of Max's dP / dW from TR2, Tate healthy vs Tate 0 in wk10 (pre-registered bound). 10 seeds.
SC <- "docs/review/002-evidence"
source(file.path(SC, "sim_helpers.R")); source(file.path(SC, "p4_redteam/p4_engine.R"))
eval(local({ L <- readLines("dev/weekly/trade_finder.R"); L <- L[grep("^CAP <- ", L):(grep("^mine <- ", L) - 1)]; parse(text = L[!grepl("^(M0|p0) <- ", L)]) }))   # CAP, settle, apply_trade, lab; range by pattern (lines shift)
MAD <- "Monday Night Madison"; MAX <- "Max’s TD Bombers"
R31 <- bind_rows(R |> filter(!(owner == MAD & player == "Titans")), P |> filter(player == "Jaguars") |> mutate(owner = MAD),
                 P |> filter(player == "Romeo Doubs") |> mutate(owner = MAD, injury = "IR"))
b <- apply_trade(R31, MAX, c("Patrick Mahomes", "Carnell Tate"), c("Luther Burden III", "Isaiah Likely"))$R
sd10 <- c(SEEDS, 5:9)
for (ov in list(NULL, tibble(player = "Carnell Tate", week = 10, val = 0))) {
  M0x <- strength2(R31, ov = ov); M2 <- strength2(b, ov = ov); M2[, "8"] <- M0x[, "8"]
  d <- sapply(sd10, function(s) { x0 <- simulate_cond(M0x, seed = s); x2 <- simulate_cond(M2, seed = s)
    c(maxP = mean(x2$top4[, MAX]) - mean(x0$top4[, MAX]), maxW = mean(x2$W[, MAX]) - mean(x0$W[, MAX]), usP = mean(x2$top4[, ME]) - mean(x0$top4[, ME])) })
  cat(if (is.null(ov)) "Tate healthy " else "Tate 0 wk10  ", sprintf("Max's dP mean %+.4f [%+.4f, %+.4f] dW %+.3f [%+.3f, %+.3f] | us dP %+.4f [%+.4f, %+.4f]  (10 seeds)\n",
      mean(d["maxP", ]), min(d["maxP", ]), max(d["maxP", ]), mean(d["maxW", ]), min(d["maxW", ]), max(d["maxW", ]), mean(d["usP", ]), min(d["usP", ]), max(d["usP", ])))
  cat("   Max's per-week strength change:", round(M2[MAX, ] - M0x[MAX, ], 2), "\n")
}
