# P4 item 1: roster truth. 10-28 export (R) vs 10-31 pull, all 10 teams. Run from repo root.
SC <- "docs/review/002-evidence"
source(file.path(SC, "sim_helpers.R"))
rd <- function(dt) bind_rows(lapply(c("qb", "rb", "wr", "te", "k", "def"), function(p)
  read_yahoo_position(sprintf("docs/uploads/week_8_data/yahoo_week8_%s_%s.csv", p, dt)))) |>
  distinct(player, yteam, .keep_all = TRUE) |>
  mutate(key = ifelse(pos == "DEF", paste0("DEF:", yteam), yahoo_id))
a <- rd("2026-10-28"); b <- rd("2026-10-31")
cat("owner values not in teams and not FA/W:\n")
print(setdiff(unique(c(a$owner, b$owner)), c(teams, "FA")) |> grep(pattern = "^W [(]", invert = TRUE, value = TRUE))
cat("rows: 10-28", nrow(a), " 10-31", nrow(b), " dup keys 10-31:", sum(duplicated(b$key)), "\n")
j <- full_join(a |> select(key, player, pos, yteam, own28 = owner, inj28 = injury),
               b |> select(key, player31 = player, own31 = owner, inj31 = injury, proj31 = proj), by = "key")
mv <- j |> filter(coalesce(own28, "NA") != coalesce(own31, "NA"),
                  own28 %in% teams | own31 %in% teams)
mv <- mv |> left_join(P |> select(key, base), by = "key")
cat("\n=== owner changes 10-28 -> 10-31 touching a league roster ===\n")
print(as.data.frame(mv |> transmute(player = coalesce(player, player31), pos, yteam, own28, own31, base = round(base, 2), inj31)), right = FALSE)
cat("\n=== R (sim roster) vs 10-31 owners, per team: in R not 10-31 / in 10-31 not R ===\n")
R31 <- b |> filter(owner %in% teams)
for (t in teams) {
  x <- setdiff(R$key[R$owner == t], R31$key[R31$owner == t]); y <- setdiff(R31$key[R31$owner == t], R$key[R$owner == t])
  if (length(x) + length(y)) cat(sprintf("%-22s -%s | +%s\n", t, paste(R$player[match(x, R$key)], collapse = ", "),
                                         paste(R31$player[match(y, R31$key)], collapse = ", ")))
}
cat("\nour rows in R:\n"); print(as.data.frame(R |> filter(owner == ME) |> select(player, pos, yteam, injury, proj, base)))
saveRDS(list(a = a, b = b, mv = mv), file.path(SC, "p4_redteam/roster_truth.rds"))
