suppressMessages(library(dplyr)); options(width = 250)
SCR <- "docs/review/002-evidence"
Y <- readRDS(file.path(SCR, "p1_veteran/Y.rds")); acc <- readRDS(file.path(SCR, "p1_veteran/acc_set.rds"))
print(as.data.frame(Y |> filter(player %in% c("Amon-Ra St. Brown","Chris Olave","Ja'Marr Chase","Chase Brown","Drake London","Jaylen Warren","Kyren Williams","George Pickens","Javonte Williams","Tre Tucker","Michael Wilson","Sam LaPorta")) |>
  transmute(player, owner = substr(owner, 1, 12), inj = injury, proj8 = proj, base = round(base, 1), ppg = round(ppg, 1), l3 = round(ppg_l3, 1), gp, snap_l3 = round(100 * snap_l3), tsh_l3 = round(100 * tsh_l3), opp_l3 = round(opp_l3, 1), rank_pre, wks)), row.names = FALSE)
cat("\nMadison casual-acceptance incl. Jacobs:\n"); print(as.data.frame(acc |> filter(team == "Monday Night Madison", grepl("Jacobs", get)) |> arrange(desc(d_us_adj)) |> head(5) |> select(give, get, d_us_adj, d_them_proj, d_them_pv)), row.names = FALSE)
cat("\nMax's casual-acceptance incl. Likely or Burden:\n"); print(as.data.frame(acc |> filter(grepl("^Max", team), grepl("Likely|Burden", get)) |> arrange(desc(d_us_adj)) |> head(5) |> select(give, get, d_us_adj, d_them_proj, d_them_pv)), row.names = FALSE)
cat("\nGives appearing most in top-100 casual-acceptance trades by d_us:\n")
print(sort(table(unlist(strsplit((acc |> arrange(desc(d_us_adj)) |> head(100))$give, " \\+ "))), decreasing = TRUE))
# Tucker wk8: what happened (1 tgt, 54% snaps) - snaps by week
nf <- readRDS("data/nflreadr/pull_2026.rds")
print(as.data.frame(nf$snaps |> filter(player %in% c("Tre Tucker", "Jonah Coleman", "Amon-Ra St. Brown")) |> select(player, week, offense_pct) |> tidyr::pivot_wider(names_from = week, values_from = offense_pct)), row.names = FALSE)
print(as.data.frame(nf$injuries |> filter(full_name %in% c("Amon-Ra St. Brown", "Tre Tucker", "Chris Olave")) |> select(week, full_name, report_primary_injury, report_status)), row.names = FALSE)
