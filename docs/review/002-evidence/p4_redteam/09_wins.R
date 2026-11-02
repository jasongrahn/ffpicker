# P4: dP and dW (5 seeds, CRN) for Adams-only return and the combined corrected world W4 vs helper M0.
SC <- "docs/review/002-evidence"
source(file.path(SC, "sim_helpers.R")); source(file.path(SC, "p4_redteam/p4_engine.R"))
MAD <- "Monday Night Madison"
R31 <- bind_rows(R |> filter(!(owner == MAD & player == "Titans")), P |> filter(player == "Jaguars") |> mutate(owner = MAD),
                 P |> filter(player == "Romeo Doubs") |> mutate(owner = MAD, injury = "IR"))
zero <- function(pl, wks) tidyr::expand_grid(player = pl, week = wks) |> mutate(val = 0)
OUTP <- c("Carnell Tate", "DeVonta Smith", "RJ Harvey", "Emeka Egbuka", "Brian Robinson Jr.", "Kyle Monangai", "Breece Hall", "David Montgomery", "Mike Evans")
IRR <- bind_rows(tibble(player = "Davante Adams", week = 12:15, val = 12.6), tibble(player = "Travis Etienne Jr.", week = 9:15, val = 8.5),
                 tibble(player = "Michael Pittman Jr.", week = 10:15, val = 7.0), tibble(player = "Romeo Doubs", week = 12:15, val = 8.5))
M31 <- strength2(R31)
print(round(rbind(adams_only_vs_R31 = dmp(strength2(R31, ov = IRR |> filter(player == "Davante Adams")), M31),
                  W4_vs_helperM0 = dmp(strength2(R31, ov = bind_rows(zero(OUTP, 9:10), IRR)), M0)), 4))
