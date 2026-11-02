# A1 Q5b: our weekly actual - ceiling sd is ~8 vs league 21.08. Sensitivity: P(top 4) if our sd differs.
# F-test vs pooled + multiplicity (10 teams). sig_team via simulate_cond; 5 seeds each (CRN within seed).
setwd("/Users/jasongrahn/R-projects/ffootballer")
META <- "docs/review/002-evidence"
source(file.path(META, "sim_helpers.R"))
q2 <- readRDS(file.path(META, "a1_luck/q2_decomp.rds")); d <- q2$d
g <- d |> dplyr::filter(!is.na(ceiling)) |> dplyr::mutate(e = pf - ceiling)
v <- tapply(g$e, g$team, var); n <- tapply(g$e, g$team, length)
Fv <- v / SIG^2; p1 <- pf(Fv, n - 1, 45)                          # one-sided low-variance p, pooled df ~45
print(round(data.frame(sd = sqrt(v), n = n, F = Fv, p_low = p1), 3))
cat(sprintf("ours sd %.2f; P(min of 10 p <= ours) ~ %.2f\n", sqrt(v[ME]), 1 - (1 - p1[ME])^10))
pv <- read.csv(file.path(META, "a1_luck/q4_wk8_prov_scores.csv"), encoding = "UTF-8", stringsAsFactors = FALSE)
F10 <- setNames(pv$score, pv$team)[teams]
run <- function(s_us) { st <- setNames(rep(SIG, 10), teams); st[ME] <- s_us
  mean(sapply(0:4, function(k) pt4(simulate_cond(M0, fixed = F10, sig_team = st, seed = SEED + k))[1])) }
for (s in c(8.3, 15, SIG, 28, 35)) cat(sprintf("our sd %5.2f -> P(top4) %.4f (5 seeds)\n", s, run(s)))
