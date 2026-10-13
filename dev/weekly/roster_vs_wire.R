# For every player we roster, find the best available alternative at that slot.
# Ranking rule per CLAUDE.md: opportunity trend governs a ROSTER swap (who to
# hold), Yahoo proj governs the START/SIT once held. Both reported; neither
# collapsed into a single score, because they answer different questions.
# K and DST are matchup slots, so they rank on implied totals, not on history.
suppressMessages({library(dplyr)})
source("dev/weekly/read_yahoo_week.R")

STAMP <- "_2026-10-07"
DIR   <- "docs/uploads/week_5_data"
SKILL <- c("qb","rb","wr","te")

rd <- function(ps) bind_rows(lapply(ps, function(p)
  read_yahoo_position(sprintf("%s/yahoo_week5_%s%s.csv", DIR, p, STAMP))))

d <- rd(c(SKILL,"k","def")) |> distinct(player, yteam, .keep_all = TRUE) |>
  mutate(pos = toupper(pos),
         pos = ifelse(pos %in% c("DST","D/ST"), "DEF", pos),
         mine  = grepl("JGrahnasaurs", owner),
         avail = owner == "FA" | grepl("^W [(]", owner),
         ir    = grepl("IR", coalesce(injury, "")))

cat("== pool", nrow(d), "| ours", sum(d$mine), "| available", sum(d$avail), "\n")
cat("== status spread ==\n")
print(table(ifelse(d$mine,"OURS", ifelse(d$avail, sub(" .*","",d$owner), "other team"))))

# ---- byes + real team from nflreadr ----
sch <- nflreadr::load_schedules(2026) |> filter(season==2026, game_type=="REG")
wks <- sort(unique(sch$week))
bye <- bind_rows(sch |> transmute(team=home_team, week),
                 sch |> transmute(team=away_team, week)) |>
  group_by(team) |> summarise(bye = setdiff(wks, week)[1], .groups="drop")

# ---- opportunity history, joined on the real key ----
d <- attach_nfl_ids(d)
ps <- nflreadr::load_player_stats(2026) |> filter(season_type=="REG", week<=4) |>
  mutate(opp = coalesce(carries,0)+coalesce(targets,0)+coalesce(attempts,0))
hist <- ps |> group_by(gsis_id = player_id, nflteam = team) |>
  summarise(g = n(), opp_g = mean(opp), last2 = mean(opp[week>=3]),
            trend = mean(opp[week>=3]) - mean(opp[week<=2]), .groups="drop") |>
  group_by(gsis_id) |> slice_max(g, n=1, with_ties=FALSE) |> ungroup()

# DEF never joins on name. Yahoo's DEF `Player` column is a nickname in some
# pulls ("Ravens") and a city in others ("Baltimore"), and "New York" is NOT
# unique -- NYG and NYJ collide. The `Team` abbreviation is the only safe key.
YA <- c(Was="WAS",Ari="ARI",Atl="ATL",Bal="BAL",Buf="BUF",Car="CAR",Chi="CHI",
  Cin="CIN",Cle="CLE",Dal="DAL",Den="DEN",Det="DET",GB="GB",Hou="HOU",Ind="IND",
  Jax="JAX",KC="KC",LV="LV",LAC="LAC",LAR="LA",Mia="MIA",Min="MIN",NE="NE",
  NO="NO",NYG="NYG",NYJ="NYJ",Phi="PHI",Pit="PIT",SF="SF",Sea="SEA",TB="TB",
  Ten="TEN")
d <- d |> left_join(hist, by="gsis_id")
d$nflteam <- ifelse(d$pos == "DEF", unname(YA[d$yteam]), d$nflteam)
stopifnot(!any(d$pos == "DEF" & is.na(d$nflteam)))
# name the defense by its team so the two New Yorks stay distinguishable
d$player <- ifelse(d$pos == "DEF", paste0(d$player, " (", d$nflteam, ")"), d$player)
d <- d |> left_join(bye, by=c("nflteam"="team"))
cat("\n== opportunity history matched:", sum(!is.na(d$opp_g)), "of", nrow(d),
    " (join key:", paste(names(table(d$method)), table(d$method), collapse=" "), ")\n")

# ---- implied totals for K / DEF ----
s5 <- sch |> filter(week==5) |>
  select(home_team, away_team, spread_line, total_line)
imp <- bind_rows(
  s5 |> transmute(nflteam=home_team, own_imp=total_line/2+spread_line/2,
                  opp_imp=total_line/2-spread_line/2),
  s5 |> transmute(nflteam=away_team, own_imp=total_line/2-spread_line/2,
                  opp_imp=total_line/2+spread_line/2))
d <- d |> left_join(imp, by="nflteam")

# ================= per-slot comparison =================
report <- function(p) {
  ours <- d |> filter(mine, pos == p)
  if (!nrow(ours)) return(invisible(NULL))
  pool <- d |> filter(avail, pos == p, !ir)

  cat("\n\n########## ", p, " ##########\n")
  if (p == "DEF") {
    key <- "opp_imp"; dirn <- 1   # lower opponent implied total is better
    pool <- pool |> arrange(opp_imp)
    cat("rank rule: lowest OPPONENT implied total (validated, n=128)\n")
  } else if (p == "K") {
    key <- "own_imp"; dirn <- -1  # higher own implied total is better
    pool <- pool |> arrange(desc(own_imp))
    cat("rank rule: highest OWN implied total (untested)\n")
  } else {
    key <- "last2"; dirn <- -1
    pool <- pool |> filter(coalesce(opp_g,0) >= 5) |> arrange(desc(last2))
    cat("rank rule: last-2-week opportunity, >=5 opp/g bar\n")
  }

  cols <- function(x) x |> transmute(
    player, tm = coalesce(nflteam, yteam), bye,
    inj = substr(coalesce(injury,""),1,4),
    opp_g = round(opp_g,1), last2 = round(last2,1), trend = round(trend,1),
    own_imp = round(own_imp,1), opp_imp = round(opp_imp,1), wk5 = proj)

  cat("\n-- OURS --\n")
  print(as.data.frame(cols(ours |> arrange(desc(proj)))), row.names=FALSE)
  cat("\n-- best available --\n")
  print(as.data.frame(cols(head(pool, 5))), row.names=FALSE)

  # verdict: is the top alternative better than our WORST at the slot?
  if (nrow(pool)) {
    worst <- ours |> arrange(if (p %in% c("K","DEF")) desc(.data[[key]]) else .data[[key]]) |> slice(1)
    best  <- pool |> slice(1)
    better <- if (p == "DEF") best$opp_imp < worst$opp_imp else
              if (p == "K")   best$own_imp > worst$own_imp else
              isTRUE(best$last2 > worst$last2)
    cat(sprintf("\n-> weakest of ours: %s | best available: %s | %s\n",
      worst$player, best$player,
      ifelse(better, "UPGRADE AVAILABLE", "hold, nothing better")))
    cat(sprintf("   wk5 proj %.2f -> %.2f  (%+.2f this week)\n",
      coalesce(worst$proj,0), coalesce(best$proj,0),
      coalesce(best$proj,0) - coalesce(worst$proj,0)))
  }
}
for (p in c("QB","RB","WR","TE","K","DEF")) report(p)

cat("\n\n########## FULL ROSTER + per-week startable bodies ##########\n")
mine <- d |> filter(mine)
print(as.data.frame(mine |> arrange(pos, desc(proj)) |>
  transmute(player, pos, tm=nflteam, bye, inj=substr(coalesce(injury,""),1,4),
            last2=round(last2,1), trend=round(trend,1), wk5=proj)), row.names=FALSE)

need <- c(QB=1,RB=2,WR=2,TE=1,K=1,DEF=1)
cat("\n== startable bodies by week (IR excluded) ==\n")
print(bind_rows(lapply(5:15, function(w) {
  a <- mine |> filter(!ir, is.na(bye) | bye != w)
  n <- sapply(names(need), function(p) sum(a$pos == p))
  data.frame(wk=w, QB=n["QB"], RB=n["RB"], WR=n["WR"], TE=n["TE"], K=n["K"],
             DEF=n["DEF"],
             short=paste(names(need)[n < need], collapse=","))
})), row.names=FALSE)
