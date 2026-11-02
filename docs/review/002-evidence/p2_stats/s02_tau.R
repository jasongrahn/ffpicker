# Q2: tau. Forecast the sim way at origin k (base wks 4..k, roster frozen at k, bye fill), compare to
# (a) realized same-week ceilings wks k+1..8 (drift) and (b) actual scores wks k+1..7.
suppressMessages({library(dplyr); library(tidyr)})
OUT <- "docs/review/002-evidence/p2_stats"
source("dev/weekly/read_yahoo_week.R")
U <- "docs/uploads"
sch <- read.csv("data/weekly/2026_league_schedule.csv", encoding = "UTF-8", stringsAsFactors = FALSE)
teams <- sort(unique(sch$team))
ceil <- readRDS("data/weekly/2026_ceilings.rds") |> filter(variant == "late_roster_clean_proj") |> select(week, team, ceiling)
# week-8 realized ceiling, ceiling_vs_margin.R method: late roster 10-31, started-game players -> 10-28 proj
POS <- c("qb", "rb", "wr", "te", "k", "def")
read_set <- function(tmpl) bind_rows(lapply(POS, function(p) read_yahoo_position(sprintf(tmpl, p)))) |>
  distinct(player, yteam, .keep_all = TRUE) |> mutate(key = ifelse(pos == "DEF", paste0("DEF:", yteam), yahoo_id))
UNSTARTED <- "^(Sun|Mon|Tue|Wed|Thu|Fri|Sat) [0-9]+:[0-9]+ [ap]m"
optimal <- function(d) {
  d <- d |> filter(is.na(injury) | !grepl("IR", injury)) |> arrange(desc(proj))
  take <- function(d, p, n) { s <- d |> filter(pos %in% p) |> head(n); list(s = s, rest = anti_join(d, s, by = "player")) }
  tot <- 0; r <- d
  for (sp in list(list("QB", 1), list("RB", 2), list("WR", 2), list("TE", 1), list("K", 1), list("DEF", 1))) {
    t <- take(r, sp[[1]], sp[[2]]); tot <- tot + sum(t$s$proj); r <- t$rest }
  tot + sum(take(r, c("RB", "WR", "TE"), 1)$s$proj)
}
late <- read_set(sprintf("%s/week_8_data/yahoo_week8_%%s_2026-10-31.csv", U)); early <- read_set(sprintf("%s/week_8_data/yahoo_week8_%%s_2026-10-28.csv", U))
started <- !is.na(late$game) & late$game != "" & !grepl(UNSTARTED, late$game)
fix <- match(late$key[started], early$key); late$proj[started] <- ifelse(is.na(fix), late$proj[started], early$proj[fix])
cat(sprintf("wk8 late 10-31: %d started-game players -> 10-28 proj (%d unmatched); multi-pos rostered: %d\n", sum(started), sum(is.na(fix)),
            sum(grepl(",", late$pos) & late$owner %in% teams)))
ceil <- bind_rows(ceil, tibble(week = 8L, team = teams, ceiling = sapply(teams, function(t) optimal(late |> filter(owner == t)))))
C <- ceil |> pivot_wider(names_from = week, values_from = ceiling) |> as.data.frame(); rownames(C) <- C$team; C <- as.matrix(C[teams, -1])
cat("realized ceilings wks 3-8:\n"); print(round(C, 1))
PFm <- sch |> filter(!is.na(pf)) |> select(week, team, pf) |> pivot_wider(names_from = week, values_from = pf) |> as.data.frame()
rownames(PFm) <- PFm$team; PFm <- as.matrix(PFm[teams, -1])
GAP <- -4.242

rows <- list()
for (k in 4:7) {
  o <- readRDS(file.path(OUT, sprintf("origin_%d.rds", k))); M <- o$M[teams, , drop = FALSE]
  for (w in (k + 1):8) {
    rows[[length(rows) + 1]] <- tibble(origin = k, week = w, h = w - k, team = teams, pred = M[, as.character(w)],
      ceil = C[, as.character(w)], pf = if (w <= 7) PFm[, as.character(w)] else NA_real_)
  }
}
d <- bind_rows(rows) |> mutate(drift = ceil - pred, err = pf - pred - GAP, gapr = pf - ceil - GAP)
cat("\n== drift = realized ceiling - origin forecast, by horizon (pooled over origins) ==\n")
print(as.data.frame(d |> group_by(h) |> summarise(n = n(), mean_drift = round(mean(drift), 2), sd_drift = round(sd(drift), 2),
  rmse = round(sqrt(mean(drift^2)), 2), n_pf = sum(!is.na(pf)), sd_err = round(sd(err, na.rm = TRUE), 2), mean_err = round(mean(err, na.rm = TRUE), 2))))
cat("\n== by origin x horizon: mean drift (sd) ==\n")
print(as.data.frame(d |> group_by(origin, h) |> summarise(md = round(mean(drift), 1), sdd = round(sd(drift), 1), .groups = "drop") |>
  mutate(v = sprintf("%+.1f (%.1f)", md, sdd)) |> select(origin, h, v) |> pivot_wider(names_from = h, values_from = v)))

vc <- function(x, team) {   # one-way random effects MoM, balanced
  a <- anova(lm(x ~ factor(team))); m <- length(x) / length(unique(team))
  c(between = (a$`Mean Sq`[1] - a$`Mean Sq`[2]) / m, within = a$`Mean Sq`[2], F = a$`F value`[1], p = a$`Pr(>F)`[1], m = m)
}
cat("\n== persistent team component of DRIFT (one-way RE per origin) ==\n")
for (k in 4:6) { x <- d |> filter(origin == k); v <- vc(x$drift, x$team)
  cat(sprintf("origin %d (wks %d-8, m=%d): between var %.1f (sd %.1f) | within var %.1f (sd %.1f) | F %.2f p %.3f\n", k, k + 1, v["m"],
      v["between"], sqrt(max(0, v["between"])), v["within"], sqrt(v["within"]), v["F"], v["p"])) }
cat("\n== persistent team component of ACTUAL forecast error err = pf - pred - GAP ==\n")
for (k in 4:5) { x <- d |> filter(origin == k, !is.na(pf)); v <- vc(x$err, x$team)
  cat(sprintf("origin %d (wks %d-7, m=%d): between var %.1f (sd %.1f) | within var %.1f (sd %.1f) | F %.2f p %.3f | mean err %+.2f\n", k, k + 1, v["m"],
      v["between"], sqrt(max(0, v["between"])), v["within"], sqrt(v["within"]), v["F"], v["p"], mean(x$err))) }
# same-week baseline for the same weeks: gap residual pf - ceil - GAP
for (k in 4:5) { x <- d |> filter(origin == k, !is.na(pf)); v <- vc(x$gapr, x$team)
  cat(sprintf("  same weeks, same-week ceiling (gap resid): between var %.1f | within var %.1f (sd %.1f) p %.3f\n", v["between"], v["within"], sqrt(v["within"]), v["p"])) }

cat("\n== does the origin-k forecast still pick winners k+1..7 weeks out? (horizon gate) ==\n")
gm <- sch |> filter(team < opponent, week %in% 5:7) |> transmute(week, a = team, b = opponent, margin = pf - pa)
hg <- bind_rows(lapply(4:6, function(k) { x <- d |> filter(origin == k)
  gm |> filter(week > k) |> mutate(origin = k, h = week - k,
    pdiff = x$pred[match(paste(week, a), paste(x$week, x$team))] - x$pred[match(paste(week, b), paste(x$week, x$team))],
    cdiff = x$ceil[match(paste(week, a), paste(x$week, x$team))] - x$ceil[match(paste(week, b), paste(x$week, x$team))]) }))
for (k in c(4, 5, 6)) { x <- hg |> filter(origin == k); f <- lm(margin ~ 0 + pdiff, x)
  cat(sprintf("origin %d: n %d | r(pdiff, margin) %+.2f | slope %.2f (SE %.2f) | resid sd %.1f | fav right %d/%d | same-wk ceiling r %+.2f\n", k, nrow(x),
    cor(x$pdiff, x$margin), coef(f), summary(f)$coef[2], summary(f)$sigma, sum(sign(x$pdiff) == sign(x$margin)), nrow(x), cor(x$cdiff, x$margin))) }
x <- hg |> filter(origin == 4); ct <- cor.test(x$pdiff, x$margin); cat(sprintf("origin 4 cor CI [%.2f, %.2f] p %.3f\n", ct$conf.int[1], ct$conf.int[2], ct$p.value))
# Our team: forecast vs realized
cat("\n== JGrahnasaurs: origin forecast vs realized ceiling ==\n")
print(as.data.frame(d |> filter(team == "JGrahnasaurs") |> transmute(origin, week, pred = round(pred, 1), ceil = round(ceil, 1), drift = round(drift, 1), pf)))
# sd across teams of mean future strength forecast (what the sim spreads) vs realized
cat("\n== spread of team strength: sd across teams of forecast vs realized mean ceiling wks 5-8 (origin 4) ==\n")
x <- d |> filter(origin == 4) |> group_by(team) |> summarise(p = mean(pred), c = mean(ceil), pf = mean(pf, na.rm = TRUE))
cat(sprintf("sd forecast %.2f | sd realized ceiling %.2f | cor %.2f | regression slope ceil~pred %.2f | pf~pred slope %.2f\n",
            sd(x$p), sd(x$c), cor(x$p, x$c), coef(lm(c ~ p, x))[2], coef(lm(pf ~ p, x))[2]))
saveRDS(list(d = d, C = C, hg = hg), file.path(OUT, "tau_objs.rds"))
