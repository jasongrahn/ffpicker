# Exact apply_trade (cap + drops) + simulate_cond, 3 seeds, CRN. Prices veteran-style moves in P(top 4).
SCR <- "docs/review/002-evidence"
suppressMessages(source(file.path(SCR, "sim_helpers.R")))
eval(local({ L <- readLines("dev/weekly/trade_finder.R"); L <- L[grep("^CAP <- ", L):(grep("^mine <- ", L) - 1)]; parse(text = L[!grepl("^(M0|p0) <- ", L)]) }))   # CAP, settle, apply_trade, lab; range by pattern (lines shift)
seeds <- SEED + 0:2
run <- function(Rx = R, Mfix = NULL) { M <- if (is.null(Mfix)) strength_matrix(Rx) else Mfix
  v <- sapply(seeds, function(s) { a <- simulate_cond(M, seed = s); c(colMeans(a$top4), w = mean(a$W[, ME])) }); rowMeans(v) }
b <- run(); P0 <- b[teams]
cat(sprintf("baseline P(top4) %.4f exp W %.2f (3 seeds)\n", b[ME], b["w"]))
rep1 <- function(lbl, Rx, extra = "") { v <- run(Rx); d <- v[teams] - P0
  riv <- d[setdiff(teams, ME)]; big <- riv[abs(riv) >= 0.01]
  cat(sprintf("%-62s dP %+.4f  dW %+.3f  fut %+5.2f  %s %s\n", lbl, d[ME], v["w"] - b["w"],
      fut(strength_matrix(Rx)[ME, ]) - fut(M0[ME, ]), paste(sprintf("%s %+.3f", substr(names(big), 1, 10), big), collapse = " "), extra)) }
tr <- function(Rx, tm, give, get) { x <- apply_trade(Rx, tm, give, get); x$R }
MAX <- teams[grepl("^Max", teams)]; DAVE <- teams[grepl("^Dave", teams)]
TR1 <- function(Rx) tr(Rx, "Monday Night Madison", c("Kyler Murray", "T.J. Hockenson"), "Josh Jacobs")
TR2 <- function(Rx) tr(Rx, MAX, c("Patrick Mahomes", "Carnell Tate"), c("Luther Burden III", "Isaiah Likely"))
cat("\n-- project's trades --\n")
rep1("TR1 Kyler+Hock -> Jacobs", TR1(R)); rep1("TR2 Mahomes+Tate -> Burden+Likely", TR2(R)); rep1("TR1+TR2", TR2(TR1(R)))
cat("\n-- casual-acceptance candidates (perceived-win for partner, stature + voter-fair) --\n")
c1 <- tr(R, "Sunday Kevin", c("Javonte Williams", "Tre Tucker"), c("Amon-Ra St. Brown", "Chris Olave")); rep1("SK: JWilliams+Tucker -> St.Brown+Olave", c1)
c2 <- tr(R, "Steel City", c("Javonte Williams", "Ollie Gordon II", "Tre Tucker"), c("Chase Brown", "Ja'Marr Chase")); rep1("SteelCity: JW+Gordon+Tucker -> C.Brown+Chase", c2)
c3 <- tr(R, "Locked In Michelle", c("Javonte Williams", "Tre Tucker"), c("Kyren Williams", "George Pickens")); rep1("Michelle: JW+Tucker -> K.Williams+Pickens", c3)
c4 <- tr(R, DAVE, c("Javonte Williams", "Tre Tucker"), c("Jaylen Warren", "Drake London")); rep1("Dave's: JW+Tucker -> Warren+London", c4)
c5 <- tr(R, "Maybe Mitchell", c("Patrick Mahomes", "Tre Tucker", "Rome Odunze"), c("Michael Wilson", "Sam LaPorta")); rep1("Mitchell: Mahomes+Tucker+Odunze -> M.Wilson+LaPorta", c5)
c6 <- tr(R, "Owl Out Blitz", "Patrick Mahomes", "Jaylen Waddle"); rep1("Owl: Mahomes -> Waddle", c6)
c7 <- tr(R, MAX, "Tre Tucker", "Luther Burden III"); rep1("Max's: Tucker -> Burden (1-for-1)", c7)
cat("\n-- stacks of compatible moves (disjoint gives) --\n")
rep1("TR1 + SteelCity(JW+Gordon+Tucker->CBrown+Chase)", tr(TR1(R), "Steel City", c("Javonte Williams", "Ollie Gordon II", "Tre Tucker"), c("Chase Brown", "Ja'Marr Chase")))
rep1("TR1 + TR2 + Dave's(JW+Tucker->Warren+London)", tr(TR2(TR1(R)), DAVE, c("Javonte Williams", "Tre Tucker"), c("Jaylen Warren", "Drake London")))
rep1("TR1 + TR2 + SK(JW+Tucker->St.Brown+Olave)", tr(TR2(TR1(R)), "Sunday Kevin", c("Javonte Williams", "Tre Tucker"), c("Amon-Ra St. Brown", "Chris Olave")))
cat("\n-- roster construction: dead slots -> upside (no trade) --\n")
addfa <- function(Rx, add, drop, base_override = NULL) { r <- Rx[!(Rx$owner == ME & Rx$player == drop), ]
  a <- P[P$player == add, ] |> mutate(owner = ME); if (!is.null(base_override)) a$base <- base_override; bind_rows(r, a) }
for (bo in c(8.17, 10.23, 12)) rep1(sprintf("add Jonah Coleman (DEN RB) base %.1f, drop Chiefs DST", bo), addfa(R, "Jonah Coleman", "Chiefs", bo))
# Adams back wk12: sim excludes IR -> blend our row
Ra <- R; i <- which(Ra$player == "Davante Adams"); Ra$injury[i] <- NA; Ra$base[i] <- mean(c(11.24, 13.13, 13.33))
Ma <- strength_matrix(Ra); Mx <- M0; wk <- as.integer(colnames(M0)) >= 12; Mx[ME, wk] <- Ma[ME, wk]
v <- run(Mfix = Mx); cat(sprintf("%-62s dP %+.4f  dW %+.3f  (wks 12-15 +%.2f/wk)\n", "Adams returns wk12 @ 12.6 (sim currently ignores)", v[ME] - P0[ME], v["w"] - b["w"], mean(Mx[ME, wk] - M0[ME, wk])))
