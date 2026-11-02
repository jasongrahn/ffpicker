# A1 Q3: which wk4 Jazzy score is the Yahoo final, 98.58 (README/retro) or 123.98 (schedule csv)?
# Enumerate every legal lineup from Jazzy's post-MNF roster (wk4 _actual_ exports, 2026-10-05)
# and the frozen-opponent csv; find lineups summing to 123.98 and 98.58.
suppressMessages({library(dplyr)})
source("dev/weekly/read_yahoo_week.R")
JJ <- "Jason's Jazzy Team"
fs <- sprintf("docs/uploads/week_4_data/yahoo_week4_%s_actual_2026-10-05.csv", c("qb","rb","wr","te","k","def"))
a <- bind_rows(lapply(fs, read_yahoo_position)) |> distinct(player, yteam, .keep_all = TRUE)
cat("owners present:", paste(sort(unique(a$owner[!grepl("^FA|^W ", a$owner)])), collapse = " | "), "\n")
r <- a |> filter(owner == JJ) |> select(player, pos, yteam, injury, pts = proj)
cat("\nJazzy post-MNF roster (wk4 actual export 10-05), pts = Yahoo actual:\n"); print(as.data.frame(r), row.names = FALSE)
fr <- read.csv("data/weekly/2026_week04_opponent.csv", stringsAsFactors = FALSE)
cat("\nFrozen wk4 opponent csv starters sum:", sum(fr$actual[fr$slot != "BN"]), "\n")

# enumerate legal lineups: QB1 RB2 WR2 TE1 FLEX1 K1 DEF1
enum <- function(r) {
  r <- r |> mutate(pts = coalesce(pts, 0))
  P <- function(p) which(grepl(p, r$pos))
  q <- P("QB"); k <- P("^K$"); df <- P("DEF")
  res <- c()
  for (qi in q) for (ki in k) for (di in df) {
    sk <- setdiff(seq_len(nrow(r)), c(qi, ki, di))
    rb <- intersect(sk, P("RB")); wr <- intersect(sk, P("WR")); te <- intersect(sk, P("TE"))
    if (length(rb) < 2 || length(wr) < 2 || length(te) < 1) next
    for (R2 in combn(rb, 2, simplify = FALSE)) for (W2 in combn(setdiff(wr, R2), 2, simplify = FALSE))
      for (t1 in setdiff(te, c(R2, W2))) for (fx in setdiff(c(rb, wr, te), c(R2, W2, t1))) {
        ids <- c(qi, ki, di, R2, W2, t1, fx)
        res <- c(res, setNames(sum(r$pts[ids]), paste(sort(r$player[ids]), collapse = "; ")))
      }
  }
  res[!duplicated(names(res))]
}
L <- enum(r)
cat(sprintf("\n%d distinct legal lineups; max %.2f\n", length(L), max(L)))
for (target in c(123.98, 98.58)) {
  hit <- L[abs(L - target) < 0.005]
  cat(sprintf("\nLineups summing to %.2f: %d\n", target, length(hit))); if (length(hit)) print(hit)
}
# Kamara wk4 (retro said Jazzy added him post-freeze)
cat("\nKamara rows in wk4 actual RB export:\n"); print(as.data.frame(a |> filter(grepl("Kamara", player)) |> select(player, owner, proj)))
cat("Hubbard rows:\n"); print(as.data.frame(a |> filter(grepl("Hubbard", player)) |> select(player, owner, proj)))
cat("Achane rows:\n"); print(as.data.frame(a |> filter(grepl("Achane", player)) |> select(player, owner, injury, proj)))
