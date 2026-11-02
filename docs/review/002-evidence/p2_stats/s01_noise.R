# Q1/Q4/Q6: noise model diagnostics on the 50 team-weeks (wks 3-7) that set SIG/GAP/TAU2.
suppressMessages({library(dplyr); library(nlme)})
OUT <- "docs/review/002-evidence/p2_stats"
b <- readRDS(file.path(OUT, "baseline_objs.rds")); cl <- b$cl
cl <- cl |> mutate(r = pf - ceiling)
sk <- function(x) { m <- mean(x); s <- sd(x); mean((x - m)^3) / s^3 }
ku <- function(x) { m <- mean(x); s <- sd(x); mean((x - m)^4) / s^4 - 3 }
n <- nrow(cl)
cat(sprintf("n %d | mean gap %.2f (SE %.2f) | sd %.2f, 95%% CI [%.1f, %.1f]\n", n, mean(cl$r), sd(cl$r)/sqrt(n), sd(cl$r),
            sd(cl$r) * sqrt((n - 1) / qchisq(0.975, n - 1)), sd(cl$r) * sqrt((n - 1) / qchisq(0.025, n - 1))))
set.seed(1); bs <- replicate(5000, { i <- sample(n, n, TRUE); c(sd(cl$r[i]), sk(cl$r[i]), ku(cl$r[i])) })
cat(sprintf("bootstrap sd CI [%.1f, %.1f] | skew %.2f [%.2f, %.2f] | excess kurt %.2f [%.2f, %.2f]\n",
            quantile(bs[1, ], .025), quantile(bs[1, ], .975), sk(cl$r), quantile(bs[2, ], .025), quantile(bs[2, ], .975),
            ku(cl$r), quantile(bs[3, ], .025), quantile(bs[3, ], .975)))
print(shapiro.test(cl$r))
cat("resid quantiles:\n"); print(round(quantile(cl$r, c(0, .05, .1, .25, .5, .75, .9, .95, 1)), 1))

cat("\n== heteroskedasticity: sd vs ceiling level ==\n")
cl$terc <- cut(cl$ceiling, quantile(cl$ceiling, 0:3 / 3), include.lowest = TRUE, labels = c("low", "mid", "high"))
print(cl |> group_by(terc) |> summarise(n = n(), ceil = round(mean(ceiling), 1), gap = round(mean(r), 2), sd = round(sd(r), 2)))
bp <- lm(I(r^2) ~ ceiling, cl); cat(sprintf("BP-style: r^2 ~ ceiling slope %.2f p %.3f; |r| ~ ceiling: ", coef(bp)[2], summary(bp)$coef[2, 4]))
ab <- lm(abs(r) ~ ceiling, cl); cat(sprintf("slope %.3f p %.3f\n", coef(ab)[2], summary(ab)$coef[2, 4]))
cat(sprintf("Levene-style (|r - median| by tercile) p %.3f\n", anova(lm(abs(r - median(r)) ~ terc, cl))$`Pr(>F)`[1]))

cat("\n== calibration slope: pf ~ ceiling (Mincer-Zarnowitz) ==\n")
m1 <- lm(pf ~ ceiling, cl); print(round(summary(m1)$coef, 3)); print(round(confint(m1), 3))
m1w <- lm(pf ~ ceiling + factor(week), cl); cat("with week FE:\n"); print(round(summary(m1w)$coef[2, ], 3)); print(round(confint(m1w)[2, ], 3))
cat(sprintf("sd(ceiling) %.2f | sd(pf) %.2f | cor %.3f\n", sd(cl$ceiling), sd(cl$pf), cor(cl$ceiling, cl$pf)))

cat("\n== variance components ==\n")
a_wk <- anova(lm(r ~ factor(week), cl)); print(a_wk)
msb <- a_wk$`Mean Sq`[1]; msw <- a_wk$`Mean Sq`[2]
cat(sprintf("week component (MoM): %.1f -> sd %.1f ; within %.1f -> sd %.1f\n", (msb - msw) / 10, sqrt(max(0, (msb - msw) / 10)), msw, sqrt(msw)))
a_tm <- anova(lm(r ~ factor(team), cl)); print(a_tm)
msb <- a_tm$`Mean Sq`[1]; msw <- a_tm$`Mean Sq`[2]
cat(sprintf("team component (MoM): %.1f -> sd %.1f ; within %.1f -> sd %.1f\n", (msb - msw) / 5, sqrt(max(0, (msb - msw) / 5)), msw, sqrt(msw)))
a2 <- anova(lm(r ~ factor(team) + factor(week), cl)); print(a2)
# REML team random effect, with and without week fixed effects
f1 <- lme(r ~ 1, random = ~ 1 | team, data = cl, method = "REML")
f2 <- lme(r ~ factor(week), random = ~ 1 | team, data = cl, method = "REML")
for (f in list(f1, f2)) { vc <- as.numeric(VarCorr(f)[, "StdDev"]); cat(sprintf("REML team sd %.2f, resid sd %.2f\n", vc[1], vc[2]))
  iv <- tryCatch(intervals(f, which = "var-cov")$reStruct$team, error = function(e) NULL); if (!is.null(iv)) print(round(iv, 2)) }
# parametric bootstrap CI for team sd (MoM) under the fitted model
set.seed(2); tsd <- sqrt(max(0, (anova(lm(r ~ factor(team), cl))$`Mean Sq`[1] - msw) / 5))
pb <- replicate(4000, { u <- rnorm(10, 0, tsd); y <- u[match(cl$team, unique(cl$team))] + rnorm(n, 0, sqrt(msw))
  a <- anova(lm(y ~ factor(cl$team))); sqrt(max(0, (a$`Mean Sq`[1] - a$`Mean Sq`[2]) / 5)) })
cat(sprintf("team sd MoM %.2f; param-bootstrap 90%% range of estimator [%.1f, %.1f]; P(est=0 | true %.1f) %.2f\n",
            tsd, quantile(pb, .05), quantile(pb, .95), tsd, mean(pb == 0)))
# under the null tau=0: how often does MoM give >= observed?
pn <- replicate(4000, { y <- rnorm(n, 0, sd(cl$r)); a <- anova(lm(y ~ factor(cl$team))); max(0, (a$`Mean Sq`[1] - a$`Mean Sq`[2]) / 5) })
cat(sprintf("null (no team effect): P(TAU2_hat >= %.1f) = %.3f\n", tsd^2, mean(pn >= tsd^2)))

cat("\n== team gaps, raw + EB-shrunk ==\n")
GAP <- mean(cl$r); tg <- cl |> group_by(team) |> summarise(g = mean(r), sdw = sd(r), se2 = var(r) / n(), .groups = "drop")
TAU2 <- max(0, var(tg$g) - mean(tg$se2))
tg <- tg |> mutate(B = TAU2 / (TAU2 + se2), shrunk = GAP + B * (g - GAP), post_sd = sqrt(TAU2 * se2 / (TAU2 + se2)))
print(as.data.frame(tg |> mutate(across(where(is.numeric), ~ round(.x, 2))) |> arrange(desc(shrunk))))
cat(sprintf("TAU2 %.2f (sd %.2f); pooled-se2 version TAU2 = var(g) - msw/5 = %.2f\n", TAU2, sqrt(TAU2), var(tg$g) - msw / 5))

cat("\n== persistence: split-half team gaps (wks 3-5 vs 6-7) and lag-1 autocorr ==\n")
sh <- cl |> mutate(h = ifelse(week <= 5, "a", "b")) |> group_by(team, h) |> summarise(g = mean(r), .groups = "drop") |>
  tidyr::pivot_wider(names_from = h, values_from = g)
ct <- cor.test(sh$a, sh$b); cat(sprintf("split-half r %.2f p %.3f CI [%.2f, %.2f] n %d\n", ct$estimate, ct$p.value, ct$conf.int[1], ct$conf.int[2], nrow(sh)))
lag <- cl |> arrange(team, week) |> group_by(team) |> mutate(rl = lag(r), rc = r - mean(r)) |> ungroup() |> filter(!is.na(rl))
ct <- cor.test(lag$r, lag$rl); cat(sprintf("lag-1 raw r %.2f p %.3f n %d\n", ct$estimate, ct$p.value, nrow(lag)))
# odd vs even weeks
oe <- cl |> mutate(h = ifelse(week %% 2 == 1, "odd", "even")) |> group_by(team, h) |> summarise(g = mean(r), .groups = "drop") |>
  tidyr::pivot_wider(names_from = h, values_from = g)
ct <- cor.test(oe$odd, oe$even); cat(sprintf("odd(3,5,7)-vs-even(4,6) r %.2f p %.3f CI [%.2f, %.2f]\n", ct$estimate, ct$p.value, ct$conf.int[1], ct$conf.int[2]))

cat("\n== gate: margin ~ 0 + diff, n 25 ==\n")
sch <- read.csv("data/weekly/2026_league_schedule.csv", encoding = "UTF-8", stringsAsFactors = FALSE)
mu <- sch |> filter(week %in% 3:7, team < opponent) |> transmute(week, team, opponent, margin = pf - pa) |>
  left_join(cl |> select(week, team, c_t = ceiling), by = c("week", "team")) |>
  left_join(cl |> select(week, team, c_o = ceiling), by = c("week", "opponent" = "team")) |> mutate(diff = c_t - c_o)
g <- lm(margin ~ 0 + diff, mu); sg <- summary(g)$coef
cat(sprintf("slope %.3f SE %.3f, 95%% CI [%.2f, %.2f]; t vs 1: %.2f p %.3f; resid sd %.2f\n", sg[1], sg[2],
            confint(g)[1], confint(g)[2], (sg[1] - 1) / sg[2], 2 * pt(-abs((sg[1] - 1) / sg[2]), 24), summary(g)$sigma))
cat(sprintf("slope fixed 1: resid sd %.2f (sim implies sqrt(2)*SIG = %.2f); with intercept slope %.2f\n",
            sqrt(sum((mu$margin - mu$diff)^2) / 25), sqrt(2) * sd(cl$r), coef(lm(margin ~ diff, mu))[2]))
set.seed(3); bsl <- replicate(5000, { i <- sample(25, 25, TRUE); coef(lm(margin ~ 0 + diff, mu[i, ])) })
cat(sprintf("bootstrap slope 95%% CI [%.2f, %.2f], P(slope<=1) %.3f\n", quantile(bsl, .025), quantile(bsl, .975), mean(bsl <= 1)))
cat(sprintf("sd(diff) %.2f, mean |diff| %.2f\n", sd(mu$diff), mean(abs(mu$diff))))
# team-level pooled estimate of beta with week FE -> margin version is within-week; compare
saveRDS(list(cl = cl, tg = tg, mu = mu), file.path(OUT, "noise_objs.rds"))
