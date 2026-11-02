# TR1 / TR2 re-priced on the post-wk8-loss baseline. 10 seeds x N 20000, common random numbers.
# Variants: as-sim (Tate healthy wks 10-15) and Tate-out bound (Tate base 0 wks 9-15, baseline too).
source("docs/review/002-evidence/a3_trades/common.R")

# --- validation: fast sim == simulate_cond; fast fut == fut(team_strength) ---
sa <- simulate_cond(M0); sb <- sim_fast(M0)
stopifnot(isTRUE(all.equal(unname(colMeans(sa$top4)), unname(sb$p))), isTRUE(all.equal(unname(colMeans(sa$W)), unname(sb$w))))
for (t in teams) stopifnot(abs(fut_df(R[R$owner == t, ]) - fut(M0[t, ])) < 1e-9)
cat("validation OK. baseline P(top4) us", sb$p[ME], "exp W", sb$w[ME], "\n")

TR <- list(
  TR1 = list(tm = MAD, give = c("Kyler Murray", "T.J. Hockenson"), get = "Josh Jacobs"),
  TR2 = list(tm = MAX, give = c("Patrick Mahomes", "Carnell Tate"), get = c("Luther Burden III", "Isaiah Likely")),
  TR1alt_Love = list(tm = MAD, give = c("Patrick Mahomes", "T.J. Hockenson"), get = "Jeremiyah Love"),
  TR2alt_Kraft = list(tm = MAX, give = c("Matthew Stafford", "Carnell Tate"), get = c("Luther Burden III", "Tucker Kraft")),
  TR2_noTate_Mah_Likely = list(tm = MAX, give = "Patrick Mahomes", get = "Isaiah Likely"),
  TR2_Tate_Burden = list(tm = MAX, give = "Carnell Tate", get = "Luther Burden III"))

do_trades <- function(Rv, ks) {    # apply in sequence; return final R + drops
  drops <- c()
  for (k in ks) { t <- TR[[k]]; x <- apply_trade(Rv, t$tm, t$give, t$get); Rv <- x$R
    drops <- c(drops, sprintf("%s: us drop [%s] them drop [%s]", k, paste(x$drop_us, collapse = ","), paste(x$drop_them, collapse = ","))) }
  list(R = Rv, drops = drops)
}
variants <- list(asSim = R, tateOut = within(R, base[player == "Carnell Tate"] <- 0))
scen <- list(base = character(0), TR1 = "TR1", TR2 = "TR2", both = c("TR1", "TR2"),
             TR1alt_Love = "TR1alt_Love", TR2alt_Kraft = "TR2alt_Kraft", Love_Kraft = c("TR1alt_Love", "TR2alt_Kraft"),
             TR2_noTate_Mah_Likely = "TR2_noTate_Mah_Likely", TR2_Tate_Burden = "TR2_Tate_Burden",
             TR1_MahLikely = c("TR1", "TR2_noTate_Mah_Likely"))
built <- list()
for (v in names(variants)) for (s in names(scen)) {
  x <- do_trades(variants[[v]], scen[[s]])
  built[[paste(v, s)]] <- list(v = v, s = s, R = x$R, M = M_of(x$R), drops = x$drops)
}
for (b in built) if (length(b$drops)) cat(b$v, b$s, "|", paste(b$drops, collapse = " ; "), "\n")

res <- mclapply(SEEDS, function(sd) lapply(built, function(b) sim_fast(b$M, seed = sd)), mc.cores = 4)
summ <- do.call(rbind, lapply(names(built), function(nm) {
  b <- built[[nm]]; base_nm <- paste(b$v, "base")
  partners <- unique(unlist(lapply(scen[[b$s]], function(k) TR[[k]]$tm)))
  dP <- sapply(res, function(r) r[[nm]]$p[ME] - r[[base_nm]]$p[ME])
  dW <- sapply(res, function(r) r[[nm]]$w[ME] - r[[base_nm]]$w[ME])
  pP <- sapply(res, function(r) mean(r[[base_nm]]$p[ME]))
  d_us <- fut(b$M[ME, ]) - fut(built[[base_nm]]$M[ME, ])
  pt <- if (length(partners)) paste(sapply(partners, function(tm) sprintf("%s %+.2f pts/wk, dP %+.1fpp (base %.1f%%)",
          substr(tm, 1, 12), fut(b$M[tm, ]) - fut(built[[base_nm]]$M[tm, ]),
          100 * mean(sapply(res, function(r) r[[nm]]$p[tm] - r[[base_nm]]$p[tm])),
          100 * mean(sapply(res, function(r) r[[base_nm]]$p[tm])))), collapse = " | ") else ""
  data.frame(variant = b$v, scen = b$s, P_us = round(100 * mean(sapply(res, function(r) r[[nm]]$p[ME])), 2),
             dP_pp = round(100 * mean(dP), 2), dP_ci95 = sprintf("[%.2f, %.2f]", 100 * (mean(dP) - 1.96 * sd(dP) / sqrt(length(dP))),
                                                              100 * (mean(dP) + 1.96 * sd(dP) / sqrt(length(dP)))),
             dW = round(mean(dW), 3), d_us_ptswk = round(d_us, 2), partner = pt)
}))
options(width = 250)
print(summ, row.names = FALSE, right = FALSE)
saveRDS(list(summ = summ, built = lapply(built, function(b) b[c("v", "s", "M", "drops")])), file.path(A3, "tr12.rds"))
