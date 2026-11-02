# P4: verify engine == strength_matrix(); audit simulate_cond == simulate; FILL usage + variants.
SC <- "docs/review/002-evidence"
source(file.path(SC, "sim_helpers.R")); source(file.path(SC, "p4_redteam/p4_engine.R"))
M1 <- strength2(R)
cat("engine == strength_matrix:", identical(M1, M0), " max abs diff", max(abs(M1 - M0)), "\n")

# --- simulate_cond vs simulate (fixed = none, sig_team = NULL) ---
a <- simulate(M0); b <- simulate_cond(M0, fixed = c())
cat("simulate_cond(fixed=c()) == simulate: top4", identical(a$top4, b$top4), " W", identical(a$W, b$W), " win", identical(a$win, b$win), "\n")
b2 <- simulate_cond(M0, fixed = setNames(numeric(0), character(0)))
cat("  with empty named numeric:", identical(a$top4, b2$top4), "\n")
st <- simulate_cond(M0, sig_team = setNames(rep(SIG, 10), teams), fixed = c())
cat("  sig_team = rep(SIG): identical", identical(a$W, st$W), "\n")
st2 <- simulate_cond(M0, sig_team = setNames(rep(SIG, 10), rev(teams)), fixed = c())
cat("  sig_team named in REVERSED order (index by name):", identical(a$W, st2$W), "\n")
st3 <- simulate_cond(M0, sig_team = unname(rep(SIG, 10)), fixed = c())
cat("  sig_team UNNAMED vector -> sig_team[teams] =", paste(head(unname(rep(SIG, 10))[teams], 2), collapse = ","), " identical:", identical(a$W, st3$W), "\n")
# fixed applied to right teams: wk8 game us v Michelle
c8 <- simulate_cond(M0); j <- which(G$week == 8 & (G$a == ME | G$b == ME))
cat("wk8 game:", G$a[j], "v", G$b[j], " our win rate:", mean(if (G$a[j] == ME) c8$win[, j] else !c8$win[, j]), "\n")
cat("W0 us", W0[ME], " mean W after wk8 fixed loss min/max:", range(c8$W[, ME]), "\n")

# --- FILL usage: which team-weeks lean on the wire, and what ---
dd <- strength2(R, detail = TRUE)
nd <- do.call(rbind, lapply(names(dd$NEED), function(k) data.frame(k = k, t(dd$NEED[[k]])))) |>
  mutate(team = sub(" [0-9]+$", "", k), week = as.integer(sub(".* ", "", k))) |> filter(week > CUR)
cat("\n=== filled slots, wks 9-15 (count of team-weeks needing each pos) ===\n")
print(nd |> group_by(team) |> summarise(across(QB:FLEX, sum)) |> as.data.frame())
cat("\nfill points per team (orig FILL), sum wks 9-15 and per wk:\n")
print(round(cbind(sum = rowSums(dd$FILLED[, -1]), per_wk = rowMeans(dd$FILLED[, -1])), 1))
cat("\nQB-short weeks:\n"); print(nd |> filter(QB > 0) |> select(team, week))
cat("\nwire by week (top-3 base, playing that week):\n")
for (w in WEEKS[-1]) cat(w, ":", paste(sapply(c("QB", "RB", "WR", "TE", "K", "DEF"), function(p) sprintf("%s %s", p, paste(round(head(WIRE[[as.character(w)]][[p]], 3), 1), collapse = "/"))), collapse = " | "), "\n")
cat("\nFILL constants' own NFL byes: "); print(REPL |> transmute(pos, player, nfl, bye = sapply(nfl, function(x) paste(setdiff(9:15, as.integer(names(ON))[sapply(ON, function(o) x %in% o)]), collapse = ","))))

# --- variants ---
Mb <- strength2(R, fillmode = "byeaware"); Mr <- strength2(R, fillmode = "rank")
inact <- c("Sunday Kevin", "Jason's Jazzy Team")
Mn <- strength2(R, nofill_teams = inact)
Mnone <- strength2(R, nofill_teams = teams)
f <- function(M) round(apply(M, 1, fut), 2)
print(cbind(orig = f(M0), byeaware = f(Mb) - f(M0), rank = f(Mr) - f(M0), nofill_SK_JJ = f(Mn) - f(M0), nofill_all = f(Mnone) - f(M0)))
res <- rbind(byeaware = dmp(Mb, M0), rank = dmp(Mr, M0), nofill_SK_JJ = dmp(Mn, M0), nofill_all = dmp(Mnone, M0))
print(round(res, 4))
saveRDS(list(Mb = Mb, Mr = Mr, Mn = Mn, Mnone = Mnone), file.path(SC, "p4_redteam/fill_variants.rds"))
