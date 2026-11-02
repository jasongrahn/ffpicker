# P4: settle() sole-K/DEF bug check (our side + FREE scan) and sign of our dP for TR1, TR2, X1, D1 under P4 corrections. 5 seeds CRN.
SC <- "docs/review/002-evidence"
source(file.path(SC, "sim_helpers.R")); source(file.path(SC, "p4_redteam/p4_engine.R"))
eval(local({ L <- readLines("dev/weekly/trade_finder.R"); L <- L[grep("^CAP <- ", L):(grep("^mine <- ", L) - 1)]; parse(text = L[!grepl("^(M0|p0) <- ", L)]) }))   # CAP, settle, apply_trade, lab; range by pattern (lines shift)
MAD <- "Monday Night Madison"; MAX <- "Max’s TD Bombers"; DAVE <- "Dave’s Bone Crushers"
us <- R[R$owner == ME, ]; b0 <- fut(team_strength(us))
cost <- sapply(active(us)$player, function(p) b0 - fut(team_strength(us[us$player != p, ])))
cat("our drop cost, pts/wk (cheapest first):\n"); print(round(sort(cost), 2))
cat("sole-slot holders whose drop is 'free' via FILL, all teams (cost <= 0.5):\n")
for (t in teams) { d <- R[R$owner == t, ]; a <- active(d); bb <- fut(team_strength(d))
  for (p in c("QB", "K", "DEF")) if (sum(a$pos == p) == 1) { pl <- a$player[a$pos == p]
    cc <- bb - fut(team_strength(d[d$player != pl, ])); if (cc <= 0.5) cat(sprintf("  %-22s %-3s %-18s cost %+.2f\n", t, p, pl, cc)) } }
settle <- function(r, keep) {   # patched: never drop a sole QB/K/DEF (A3's fix, P4 copy)
  dropped <- character(0)
  while (nrow(active(r)) > CAP) { a <- active(r); sole <- a$player[a$pos %in% c("QB", "K", "DEF") & ave(a$pos, a$pos, FUN = length) == "1"]
    c <- setdiff(a$player, c(keep, sole)); left <- vapply(c, function(p) fut(team_strength(r[r$player != p, ])), numeric(1))
    d <- c[which.max(left)]; dropped <- c(dropped, d); r <- r[r$player != d, ] }
  list(r = r, dropped = dropped) }
R31 <- bind_rows(R |> filter(!(owner == MAD & player == "Titans")), P |> filter(player == "Jaguars") |> mutate(owner = MAD),
                 P |> filter(player == "Romeo Doubs") |> mutate(owner = MAD, injury = "IR"))
zero <- function(pl, wks) tidyr::expand_grid(player = pl, week = wks) |> mutate(val = 0)
OUTP <- c("Carnell Tate", "DeVonta Smith", "RJ Harvey", "Emeka Egbuka", "Brian Robinson Jr.", "Kyle Monangai", "Breece Hall", "David Montgomery", "Mike Evans")
IRR <- bind_rows(tibble(player = "Davante Adams", week = 12:15, val = 12.6), tibble(player = "Travis Etienne Jr.", week = 9:15, val = 8.5),
                 tibble(player = "Michael Pittman Jr.", week = 10:15, val = 7.0), tibble(player = "Romeo Doubs", week = 12:15, val = 8.5))
kr <- grep("Kraft", R$player, value = TRUE); co <- grep("Coker", R$player, value = TRUE)
cat("Kraft:", kr, R$owner[R$player %in% kr], "| Coker:", co, R$owner[R$player %in% co], "\n")
TRS <- list(TR1 = list(MAD, c("Kyler Murray", "T.J. Hockenson"), "Josh Jacobs"),
            TR2 = list(MAX, c("Patrick Mahomes", "Carnell Tate"), c("Luther Burden III", "Isaiah Likely")),
            X1  = list(MAX, c("Patrick Mahomes", "Tre Tucker", "Brenton Strange"), c("Luther Burden III", kr)),
            D1  = list(DAVE, "T.J. Hockenson", co))
for (wn in c("W1_1031", "W4_corrected", "W5_inj7")) {
  ov <- switch(wn, W1_1031 = NULL, W4_corrected = bind_rows(zero(OUTP, 9:10), IRR), W5_inj7 = bind_rows(zero(OUTP, 9:15), IRR))
  Mn <- strength2(R31, ov = ov)
  for (k in names(TRS)) { x <- apply_trade(R31, TRS[[k]][[1]], TRS[[k]][[2]], TRS[[k]][[3]]); Mt <- strength2(x$R, ov = ov); Mt[, "8"] <- Mn[, "8"]
    r <- dmp(Mt, Mn); tm <- TRS[[k]][[1]]
    cat(sprintf("%-13s %-3s us dP %+.4f [%+.4f,%+.4f] dW %+.3f | us %+.2f pts/wk, partner %+.2f | drops us:%s them:%s\n", wn, k, r["dP"], r["dP_lo"], r["dP_hi"], r["dW"],
      fut(Mt[ME, ]) - fut(Mn[ME, ]), fut(Mt[tm, ]) - fut(Mn[tm, ]), paste(x$drop_us, collapse = ","), paste(x$drop_them, collapse = ","))) } }
