# P4 items 2+3: every rostered player with an injury tag (10-31 pull), his raw base
# (mean non-zero proj wks 4-8, NO live rule), sim base, nflreadr wk8 report, snaps wks 5-8.
SC <- "docs/review/002-evidence"
source(file.path(SC, "sim_helpers.R"))
rt <- readRDS(file.path(SC, "p4_redteam/roster_truth.rds")); b <- rt$b
raw <- bind_rows(lapply(names(ex), function(w) ex[[w]] |> transmute(key, week = as.integer(w), proj))) |>
  group_by(key) |> summarise(base_raw = mean(proj[proj > 0]), n_nz = sum(proj > 0),
                             last_nz = suppressWarnings(max(week[proj > 0])),
                             projs = paste(sprintf("%.1f", proj[order(week)]), collapse = "/"), .groups = "drop")
inj <- read.csv("docs/uploads/week_8_data/yahoo_week8_injuries_2026-10-31.csv", check.names = FALSE, stringsAsFactors = FALSE)
names(inj) <- ascii_only(names(inj))
gdc <- read.csv("docs/uploads/week_8_data/yahoo_week8_gamedaycalls_2026-10-31.csv", check.names = FALSE, stringsAsFactors = FALSE)
names(gdc) <- ascii_only(names(gdc))
nf <- readRDS("data/nflreadr/pull_2026.rds")
ids <- nf$ids |> mutate(yahoo_id = as.character(yahoo_id))
snp <- nf$snaps
x <- b |> filter(owner %in% teams, !is.na(injury), injury != "") |>
  left_join(raw, by = "key") |> left_join(R |> select(key, base_sim = base), by = "key") |>
  left_join(gdc |> transmute(key = as.character(`Player ID`), gdc_status = `Game Status`, gdc_inj = Injury, updated = Updated), by = "key") |>
  left_join(inj |> transmute(key = as.character(`Player ID`), inj_type = `Injury Type`), by = "key")
# nflreadr: id first, then name
x <- x |> left_join(ids |> filter(!is.na(yahoo_id)) |> distinct(yahoo_id, .keep_all = TRUE) |>
                      transmute(key = yahoo_id, gsis = gsis_id, pfr = pfr_id), by = "key")
nm <- ids |> mutate(mn = nflreadr::clean_player_names(name, lowercase = TRUE)) |> filter(!duplicated(mn))
x <- x |> mutate(mn = nflreadr::clean_player_names(player, lowercase = TRUE)) |>
  left_join(nm |> transmute(mn, gsis_n = gsis_id, pfr_n = pfr_id), by = "mn") |>
  mutate(gsis = coalesce(gsis, gsis_n), pfr = coalesce(pfr, pfr_n))
rep8 <- nf$injuries |> filter(week == 8) |> transmute(gsis = gsis_id, rep8 = report_status, prac8 = substr(practice_status, 1, 12))
x <- x |> left_join(rep8, by = "gsis")
sn <- snp |> filter(week >= 4) |> transmute(pfr = pfr_player_id, week, off = offense_pct) |>
  group_by(pfr) |> summarise(snaps = paste(sprintf("%d:%.0f", week, 100 * off), collapse = " "), .groups = "drop")
x <- x |> left_join(sn, by = "pfr")
out <- x |> arrange(owner, desc(coalesce(base_raw, 0))) |>
  transmute(owner = substr(owner, 1, 14), player, pos, nfl = toupper(yteam), tag = injury, inj_type, base_sim = round(base_sim, 1),
            base_raw = round(base_raw, 1), projs, rep8, snaps)
options(width = 250)
print(as.data.frame(out), right = FALSE)
saveRDS(x, file.path(SC, "p4_redteam/injury_inventory.rds"))
cat("\nIR on rosters (any base):\n"); print(table(out$owner[grepl("IR", out$tag)]))
