suppressMessages({library(nflreadr);library(dplyr);library(data.table)})

# ---- load frozen lineups -------------------------------------------------
read_one <- function(f){
  d <- fread(f, showProgress=FALSE)
  g <- if ("proj_gameday" %in% names(d)) suppressWarnings(as.numeric(d$proj_gameday)) else rep(NA_real_, nrow(d))
  tibble(week=as.integer(d$week), player=d$player, pos=toupper(d$pos),
         tm=d$nfl_team, slot=as.character(d$slot),
         proj=suppressWarnings(as.numeric(d$proj)),
         projg=g,
         actual=suppressWarnings(as.numeric(d$actual)),
         side=ifelse(grepl("myteam", f), "ours", "theirs"))
}
fs <- Sys.glob("data/weekly/2026_week0[1-4]_{myteam,opponent}.csv")
if(!length(fs)) fs <- c(Sys.glob("data/weekly/2026_week0[1-4]_myteam.csv"),
                        Sys.glob("data/weekly/2026_week0[1-4]_opponent.csv"))
L <- bind_rows(lapply(fs, read_one)) |>
  mutate(p = ifelse(is.na(projg), proj, projg)) |>
  filter(!is.na(p), !is.na(actual))

# ---- own-team spread per (week, team) ------------------------------------
fix <- c(LAR="LA", LAC="LAC", JAC="JAX", WSH="WAS", ARZ="ARI", SD="LAC", OAK="LV")
std <- function(x){ x <- toupper(x); ifelse(x %in% names(fix), fix[x], x) }

s <- load_schedules(2026) |> filter(season==2026, week<=4) |>
  select(week, home_team, away_team, spread_line, total_line)
sp <- bind_rows(
  s |> transmute(week, tm=home_team, fav_by =  spread_line, total=total_line),
  s |> transmute(week, tm=away_team, fav_by = -spread_line, total=total_line))

L <- L |> mutate(tm=std(tm)) |> left_join(sp, by=c("week","tm"))
cat("spread matched: ", sum(!is.na(L$fav_by)), "/", nrow(L), "\n", sep="")
bad <- L |> filter(is.na(fav_by)) |> distinct(tm) |> pull(tm)
if(length(bad)) cat("unmatched team codes:", paste(bad, collapse=", "), "\n")

# ---- CLAUDE.md game-script table ----------------------------------------
bucket <- function(f) dplyr::case_when(
  is.na(f)            ~ NA_character_,
  f >= 10             ~ "fav10+",
  f >= 3  & f < 7     ~ "fav3-7",
  f >= 0  & f < 3     ~ "fav0-3",
  f <= -3 & f > -7    ~ "dog3-7",
  TRUE                ~ "other")            # unlisted bucket -> no adjustment
M <- list(
  RB = c(`dog3-7`=0.945, `fav0-3`=1.036, `fav3-7`=1.078, `fav10+`=1.134),
  WR = c(`dog3-7`=0.975, `fav0-3`=0.935, `fav3-7`=1.059, `fav10+`=1.000),
  QB = c(            `fav0-3`=0.939, `fav3-7`=1.028, `fav10+`=1.120))
mult <- function(pos, b){
  out <- rep(1, length(pos))
  for(i in seq_along(pos)){
    tab <- M[[pos[i]]]
    if(!is.null(tab) && !is.na(b[i]) && b[i] %in% names(tab)) out[i] <- tab[[b[i]]]
  }
  out
}
L <- L |> mutate(b=bucket(fav_by), m=mult(pos,b), p_adj=p*m)

# ---- scoring -------------------------------------------------------------
score <- function(d, lbl){
  if(!nrow(d)) return(invisible(NULL))
  raw <- abs(d$p - d$actual); adj <- abs(d$p_adj - d$actual)
  cat(sprintf("%-26s n=%3d  MAE raw %6.3f -> adj %6.3f  (%+.3f)   RMSE %6.3f -> %6.3f  (%+.3f)   adj better on %d/%d\n",
      lbl, nrow(d), mean(raw), mean(adj), mean(adj)-mean(raw),
      sqrt(mean((d$p-d$actual)^2)), sqrt(mean((d$p_adj-d$actual)^2)),
      sqrt(mean((d$p_adj-d$actual)^2))-sqrt(mean((d$p-d$actual)^2)),
      sum(adj<raw), sum(adj!=raw)))
}
A <- L |> filter(pos %in% c("QB","RB","WR"), m != 1)
A <- L |> filter(pos %in% c("QB","RB","WR"), m != 1)
