source("docs/review/002-evidence/a4_wire/a4_common.R")
cat("trade drops:\n"); str(TR_DROPS)
need <- c(QB = 1, RB = 2, WR = 2, TE = 1, K = 1, DEF = 1)
tab <- function(Rx, lab) {
  me <- Rx |> filter(owner == ME) |> left_join(byes, by = c("nfl" = "team")) |>
    mutate(ir = grepl("IR", coalesce(injury, "")))
  cat(sprintf("\n=== %s: active %d, IR %d ===\n", lab, sum(!me$ir), sum(me$ir)))
  print(as.data.frame(me |> arrange(pos, desc(base)) |> transmute(player, pos, nfl, bye, inj = coalesce(injury, ""), base = round(base, 1))), row.names = FALSE)
  g <- bind_rows(lapply(9:15, function(w) {
    a <- me |> filter(!ir, bye != w)
    n <- sapply(names(need), function(p) sum(a$pos == p))
    flex <- sum(a$pos %in% c("RB", "WR", "TE")); 
    data.frame(wk = w, t(n), flexpool = flex, out = paste(me$player[!me$ir & me$bye == w], collapse = ", "),
               short = paste(c(names(need)[n < need], if (flex < 6) "FLEX"), collapse = ","))
  }))
  print(g, row.names = FALSE)
}
tab(R_now, "CURRENT (10-28 export)"); tab(R_tr, "POST TR1+TR2")
cat("\nOther teams' changes in R_tr vs R_now:\n")
print(as.data.frame(anti_join(R_tr |> select(owner, player), R_now |> select(owner, player), by = c("owner", "player"))))
print(as.data.frame(anti_join(R_now |> select(owner, player), R_tr |> select(owner, player), by = c("owner", "player"))))
M_now <- strength_matrix(R_now); M_tr <- strength_matrix(R_tr)
cat("\nOur strength by week now / post-trade:\n"); print(round(rbind(now = M_now[ME, ], tr = M_tr[ME, ]), 1))
cat("\nP(top4) 5 seeds now:\n"); print(pt4s(M_now)); cat("post-trade:\n"); print(pt4s(M_tr))
saveRDS(list(M_now = M_now, M_tr = M_tr), "docs/review/002-evidence/a4_wire/M_base.rds")
