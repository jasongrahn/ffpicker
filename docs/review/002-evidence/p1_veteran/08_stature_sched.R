suppressMessages(library(dplyr)); options(width = 250)
SCR <- "docs/review/002-evidence"
Y <- readRDS(file.path(SCR, "p1_veteran/Y.rds"))
cat("rank_pre / rank_actual / pct_ros sample:\n")
print(as.data.frame(Y |> filter(player %in% c("Bijan Robinson","Drake London","Ollie Gordon II","Tre Tucker","Patrick Mahomes","Kyler Murray","Matthew Stafford","Josh Jacobs","Luther Burden III","Isaiah Likely","Carnell Tate","T.J. Hockenson","Davante Adams","Chase Brown","DK Metcalf","Justin Jefferson","Derrick Henry","Javonte Williams","Denzel Boston","Rome Odunze","Brenton Strange","Jaylen Waddle","A.J. Brown","Jonah Coleman")) |>
  transmute(player, owner = substr(owner, 1, 14), pos, rank_pre, rank_actual, pct_ros, base = round(base, 1), ppg = round(ppg, 1), l3 = round(ppg_l3, 1)) |> arrange(rank_pre)), row.names = FALSE)
# NFL schedule: remaining opponents wks 9-17 + defensive pts allowed 2026 (game scores) as SOS proxy
nf <- readRDS("data/nflreadr/pull_2026.rds"); s <- nf$schedules |> filter(game_type == "REG")
g <- bind_rows(s |> transmute(week, team = home_team, opp = away_team, pf = home_score, pa = away_score, total_line, spread = -spread_line),
               s |> transmute(week, team = away_team, opp = home_team, pf = away_score, pa = home_score, total_line, spread = spread_line))
dpa <- g |> filter(!is.na(pa)) |> group_by(team) |> summarise(pa_g = mean(pa), .groups = "drop")   # pts allowed by team's D
lg <- mean(dpa$pa_g)
fut <- g |> filter(week >= 9) |> left_join(dpa |> rename(opp = team, opp_pa = pa_g), by = "opp")
cat(sprintf("\nlines posted for wks 9-17? total_line non-NA by week: %s\n", paste(tapply(!is.na(fut$total_line), fut$week, sum), collapse = " ")))
sos <- fut |> group_by(team) |> summarise(ros_9_15 = mean(opp_pa[week <= 15]) - lg, po_16_17 = mean(opp_pa[week %in% 16:17]) - lg,
  opp16 = opp[week == 16][1], opp17 = opp[week == 17][1], .groups = "drop") |> arrange(desc(po_16_17))
cat(sprintf("league mean pts allowed/g %.1f; SOS = opp D pts allowed/g minus mean (+ = soft)\n", lg))
nt <- function(y) dplyr::recode(toupper(y), "LAR" = "LA", "JAX" = "JAX", "WAS" = "WAS")
key <- c("LA","MIN","KC","BAL","DAL","MIA","TEN","CLE","CHI","LV","JAX","DET","GB","NYG","ATL","CIN","PIT","DEN","ARI","NE","SEA","NO","BUF","HOU")
print(as.data.frame(sos |> filter(team %in% key) |> mutate(across(where(is.numeric), ~ round(.x, 1)))), row.names = FALSE)
