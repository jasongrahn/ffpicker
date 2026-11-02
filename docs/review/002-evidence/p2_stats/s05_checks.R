# Slope>1 source (manager effect vs projection compression); team-level h=1 drift (frozen-roster bias).
suppressMessages(library(dplyr))
OUT <- "docs/review/002-evidence/p2_stats"
n <- readRDS(file.path(OUT, "noise_objs.rds")); cl <- n$cl; mu <- n$mu
g <- lm(margin ~ 0 + diff, mu |> filter(team != "Monday Night Madison", opponent != "Monday Night Madison"))
cat(sprintf("gate slope excl. Madison games: %.2f (SE %.2f) n %d\n", coef(g), summary(g)$coef[2], nobs(g)))
fe <- lm(pf ~ ceiling + factor(team), cl); cat(sprintf("pf~ceiling WITHIN-team (team FE): %.2f [%.2f, %.2f]\n", coef(fe)[2], confint(fe)[2, 1], confint(fe)[2, 2]))
tm <- cl |> group_by(team) |> summarise(c = mean(ceiling), pf = mean(pf), gap = mean(r))
b <- lm(pf ~ c, tm); ct <- cor.test(tm$c, tm$gap)
cat(sprintf("BETWEEN-team slope pf~ceiling %.2f (SE %.2f, n 10) | cor(team ceiling, team gap) %+.2f p %.3f\n", coef(b)[2], summary(b)$coef[2, 2], ct$estimate, ct$p.value))
t <- readRDS(file.path(OUT, "tau_objs.rds"))$d |> filter(h == 1)
dt <- t |> group_by(team) |> summarise(m = mean(drift), s2 = var(drift) / n(), n = n(), .groups = "drop")
a <- anova(lm(drift ~ factor(team), t)); T2 <- max(0, (a$`Mean Sq`[1] - a$`Mean Sq`[2]) / 4)
dt <- dt |> mutate(shr = mean(m) + T2 / (T2 + s2) * (m - mean(m))) |> arrange(desc(shr))
cat(sprintf("h=1 drift (ceiling_w - forecast from w-1), origins 4-7: team F %.2f p %.3f, between var %.1f\n", a$`F value`[1], a$`Pr(>F)`[1], T2))
print(as.data.frame(dt |> mutate(across(where(is.numeric), ~ round(.x, 2)))))
x <- t |> filter(team == "JGrahnasaurs"); tt <- t.test(x$drift); cat(sprintf("us h=1 drift %s mean %.2f t-CI [%.2f, %.2f]\n", paste(round(x$drift, 1), collapse = ","), mean(x$drift), tt$conf.int[1], tt$conf.int[2]))
# forking paths, R4 band: drop the pre-loaded wk6 pairs (58 decided, 27 right) from the 4-7 pool (314, 164)
k <- 164 - 27; m <- 314 - 58; bt <- binom.test(k, m); cat(sprintf("5-15%% band excl. wk6 (seen at registration): %d/%d = %.1f%% [%.1f, %.1f]\n", k, m, 100 * k / m, 100 * bt$conf.int[1], 100 * bt$conf.int[2]))
