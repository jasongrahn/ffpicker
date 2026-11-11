# Wk10 menu (2026-11-10): best ADR-0012-fair trade per partner from wk10_search.R (both bases), singles,
# priced in the season sim. Tate healthy (asSim). J1 (sent 11-03, open) re-judged here. KQ = the
# trade_finder.R top idea (QB -> Watson + Warren), shown for the record: fails partner ppg (-2.95).
source("docs/review/002-evidence/a3_trades/common.R")
pv <- readRDS(file.path(A3, "perceived.rds")); pv$pval <- ifelse(pv$g > 0, 0.5 * pv$ppg + 0.5 * pv$last3, 0)
SK <- "Sunday Kevin"; MICH <- "Locked In Michelle"; OWL <- "Owl Out Blitz"
JAZ <- "Jason's Jazzy Team"; MIT <- "Maybe Mitchell"
T <- list(
  J1 = list(JAZ, "Rome Odunze", c("Rhamondre Stevenson", "DK Metcalf")),
  DV = list(DAVE, c("Rome Odunze", "Brenton Strange"), c("Brock Purdy", "Tetairoa McMillan")),
  KV = list(SK, "Javonte Williams", c("Christian Watson", "Chris Olave")),
  MT = list(MIT, "Jadarian Price", c("Breece Hall", "Sam LaPorta")),
  JZ = list(JAZ, c("Javonte Williams", "Jadarian Price"), c("Chuba Hubbard", "DK Metcalf")),
  OW = list(OWL, "Jadarian Price", c("Quinshon Judkins", "Jaylen Waddle")),
  MX = list(MAX, "Derrick Henry", c("Ashton Jeanty", "Parker Washington")),
  LM = list(MICH, c("Javonte Williams", "A.J. Brown", "T.J. Hockenson"), c("Kyren Williams", "George Pickens")),
  KQ = list(SK, "Patrick Mahomes", c("Christian Watson", "Tyler Warren")),
  # partner ppg >= 0 (contenders must SEE a gain; D1 +0.37 and K2 -0.37 both declined 11-03..11-10)
  DH = list(DAVE, "T.J. Hockenson", c("Brock Purdy", "Tetairoa McMillan")),
  KN = list(SK, c("Javonte Williams", "Tre Tucker"), c("Chris Olave", "Malik Nabers")),
  MH = list(MIT, c("Jadarian Price", "T.J. Hockenson"), c("Breece Hall", "Sam LaPorta")),
  OC = list(OWL, "Tre Tucker", c("Zach Charbonnet", "Jaylen Waddle")))
inc <- unique(unlist(lapply(T, `[[`, 3)))
print(as.data.frame(R[R$player %in% inc, c("player", "owner", "pos", "nfl", "injury", "base")]), row.names = FALSE)
Mb <- M_of(R); Rp <- R; i <- match(Rp$player, pv$player); Rp$base[!is.na(i)] <- pv$pval[i[!is.na(i)]]; Mp <- strength_matrix(Rp)
SEEDS5 <- SEED + 0:4
Ms <- lapply(names(T), function(k) { t <- T[[k]]; apply_trade(R, t[[1]], t[[2]], t[[3]]) }); names(Ms) <- names(T)
res <- mclapply(SEEDS5, function(sd) { b <- sim_fast(Mb, seed = sd)
  sapply(Ms, function(a) { s <- sim_fast(M_of(a$R), seed = sd); s$p[[ME]] - b$p[[ME]] }) }, mc.cores = 4)
dP <- rowMeans(do.call(cbind, res)); se <- apply(do.call(cbind, res), 1, sd) / sqrt(length(SEEDS5))
base_p <- mean(sapply(SEEDS5, function(sd) sim_fast(Mb, seed = sd)$p[ME]))
pt <- function(sd, M) sim_fast(M, seed = sd)$p
cat(sprintf("baseline P(top 4) %.2f%% (5 seeds), BASE=%s\n", 100 * base_p, Sys.getenv("BASE", "mean")))
single <- do.call(rbind, lapply(names(T), function(k) { t <- T[[k]]; tm <- t[[1]]; a <- Ms[[k]]; M <- M_of(a$R)
  xp <- apply_trade(Rp, tm, t[[2]], t[[3]])$R
  pth <- mean(sapply(SEEDS5, function(sd) pt(sd, M)[[tm]] - pt(sd, Mb)[[tm]]))
  data.frame(offer = k, partner = substr(tm, 1, 14), give = paste(t[[2]], collapse = " + "), get = paste(t[[3]], collapse = " + "),
    our_drop = paste(a$drop_us, collapse = ","), their_drop = paste(a$drop_them, collapse = ","),
    us_pts = round(fut(M[ME, ]) - fut(Mb[ME, ]), 2), them_paper = round(fut(M[tm, ]) - fut(Mb[tm, ]), 2),
    them_ppg = round(fut(team_strength(xp[xp$owner == tm, ])) - fut(Mp[tm, ]), 2),
    dP_pp = round(100 * dP[k], 2), se = round(100 * se[k], 2), dP_them_pp = round(100 * pth, 1)) }))
options(width = 250); print(single, row.names = FALSE)
saveRDS(single, file.path("data/weekly", paste0("2026_week10_offer_menu_", Sys.getenv("BASE", "mean"), ".rds")))
