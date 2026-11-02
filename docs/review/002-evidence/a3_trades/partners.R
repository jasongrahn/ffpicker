# Partner context: P(top 4) (10 seeds), record, fill-slot bye holes wks 9-15, injury tags (10-31
# pull), QB situation, activity = roster churn between dated Yahoo snapshots wks 3-8 (lower bound:
# a same-week add+drop is invisible). rosterchanges_added_* is Yahoo's NFL player-DB load log
# (NFL signings, IDP, April draft dates) -> carries no league activity; not used.
source("docs/review/002-evidence/a3_trades/common.R")
res <- mclapply(SEEDS, function(sd) sim_fast(M0, seed = sd), mc.cores = 1)
p0 <- Reduce(`+`, lapply(res, `[[`, "p")) / length(res); w0 <- Reduce(`+`, lapply(res, `[[`, "w")) / length(res)

# fill slots used per week (empty starting slot -> wire body)
nfill <- function(d, w) {
  d <- active(d); on <- d$nfl %in% ON[[w]] & d$base > 0; pos <- d$pos[on]
  n <- function(p) sum(pos == p)
  max(0, 1 - n("QB")) + max(0, 2 - n("RB")) + max(0, 2 - n("WR")) + max(0, 1 - n("TE")) + max(0, 1 - n("K")) + max(0, 1 - n("DEF")) +
    as.integer(max(0, n("RB") - 2) + max(0, n("WR") - 2) + max(0, n("TE") - 1) == 0)
}
holes <- function(t) { d <- R[R$owner == t, ]; h <- sapply(FW, function(w) nfill(d, w)); paste(names(h)[h > 0], collapse = ",") }

# injury tags from the 10-31 pull (position exports carry Yahoo status)
inj <- bind_rows(lapply(c("qb", "rb", "wr", "te"), function(p) read_yahoo_position(sprintf("docs/uploads/week_8_data/yahoo_week8_%s_2026-10-31.csv", p)))) |>
  distinct(player, yteam, .keep_all = TRUE) |> filter(owner %in% teams, !is.na(injury), injury != "")

# activity: roster churn across dated snapshots
files <- unlist(lapply(3:8, function(w) list.files(sprintf("docs/uploads/week_%d_data", w),
         sprintf("^yahoo_week%d_(qb|rb|wr|te|k|def)(_actual)?_[0-9-]+[.]csv$", w), full.names = TRUE)))
snap <- bind_rows(lapply(files, function(f) { d <- tryCatch(read_yahoo_position(f), error = function(e) NULL)
  if (is.null(d) || !"owner" %in% names(d)) return(NULL)
  tibble(date = sub(".*_([0-9-]+)[.]csv$", "\\1", f), player = d$player, yteam = d$yteam, owner = d$owner) })) |>
  filter(owner %in% teams) |> distinct()
dates <- sort(unique(snap$date))
adds <- bind_rows(lapply(seq_along(dates)[-1], function(i) {
  a <- snap |> filter(date == dates[i]); b <- snap |> filter(date == dates[i - 1])
  anti_join(a, b, by = c("player", "owner")) |> mutate(from = dates[i - 1])
}))
act <- adds |> count(owner, name = "adds_seen")

ctx <- bind_rows(lapply(teams, function(t) {
  d <- active(R[R$owner == t, ]); q <- d[d$pos == "QB", ]
  qbye <- vapply(q$nfl, function(n) paste(FW[!vapply(FW, function(w) n %in% ON[[w]], TRUE)], collapse = ""), "")
  tibble(team = t, W_thru7 = W0[[t]], PF_thru7 = round(PF0[[t]], 1), P_top4 = round(100 * p0[[t]], 1), expW = round(w0[[t]], 2),
         fut = round(fut(M0[t, ]), 1), fill_wks = holes(t),
         QBs = paste(sprintf("%s %.1f%s", sub("^(\\S)\\S* ", "\\1. ", q$player), q$base, ifelse(qbye == "", "", paste0(" bye", qbye))), collapse = "; "),
         tags = paste(sprintf("%s %s", sub("^(\\S)\\S* ", "\\1. ", inj$player[inj$owner == t]), inj$injury[inj$owner == t]), collapse = "; "),
         adds_seen = coalesce(act$adds_seen[match(t, act$owner)], 0L))
}))
cat("snapshot dates:", paste(dates, collapse = " "), "\n")
options(width = 260); print(as.data.frame(ctx), row.names = FALSE, right = FALSE)
saveRDS(list(ctx = ctx, p0 = p0, w0 = w0, adds = adds), file.path(A3, "partners.rds"))
