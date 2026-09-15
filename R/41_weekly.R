#' In-season weekly mart.
#'
#' The draft layers all answer "who is worth more over a season". This one
#' answers "what happened last week, and who has the role going into next
#' week" -- the input to the start/sit picker.
#'
#' Fantasy points are NOT recomputed here. `fct_player_week_scored` already
#' ran every stat line through `score_player_week()` under this league's
#' half-PPR config, and re-deriving them would mean two scoring paths that
#' can drift. This layer only slices to the live season and attaches role
#' (snap share) and availability (injury designation).

#' Weekly injury report, standing on its own.
#'
#' MUST NOT be collapsed into `fct_player_week_current`. That table is derived
#' from `player_stats`, so it has a row only for players who recorded a stat --
#' and a player ruled Out records nothing. Measured on 2026 week 1: of 21
#' skill-position designations, the left join onto stat lines retained 3.
#' All 9 `Out` and all 3 `Doubtful` were dropped, plus 6 of 9 `Questionable`
#' who were inactive. The designations a start/sit decision turns on are
#' precisely the ones a stats-derived table cannot hold.
#'
#' Grain is (gsis_id, week) over every player on a report, played or not.
#'
#' @param injuries_path Path to raw injuries parquet.
#' @param season Season to slice to. Defaults to the live NFL season.
#' @return data.frame, one row per (gsis_id, week).
build_dim_injury_week <- function(injuries_path, season = nflreadr::most_recent_season()) {
  inj <- as.data.frame(arrow::read_parquet(injuries_path))
  inj <- inj[inj$season == season & inj$season_type == "REG", ]
  inj <- inj[!duplicated(inj[, c("gsis_id", "week")]), ]

  keep <- c("gsis_id", "season", "week", "team", "position", "full_name",
            "report_status", "report_primary_injury", "report_secondary_injury",
            "practice_status", "practice_primary_injury")
  inj <- inj[, intersect(keep, colnames(inj))]

  # An absent player is healthy, not unknown -- but an absent *designation* on
  # a listed player means "on the report, no game status yet", which is a
  # different and weaker signal. Both stay NA; do not impute either.
  inj[order(inj$week, inj$team, inj$full_name), ]
}

#' Build the current-season player-week fact table.
#'
#' @param scored data.frame from `add_fantasy_points(fct_player_week, ...)`.
#'   Carries `player_key`, `player_id` (gsis), `season`, `week`,
#'   `fantasy_points`, and the full nflverse stat line.
#' @param snap_counts_path Path to raw snap_counts parquet.
#' @param injuries_path Path to raw injuries parquet.
#' @param dim_player data.frame from `build_dim_player()`; supplies the
#'   gsis_id -> pfr_id crosswalk that the snap join needs.
#' @param season Season to slice to. Defaults to the live NFL season.
#' @return data.frame, one row per (player_key, season, week), with
#'   `offense_pct`, `st_pct` and `report_status` added.
build_fct_player_week_current <- function(scored, snap_counts_path, injuries_path,
                                          dim_player, season = nflreadr::most_recent_season()) {
  cur <- as.data.frame(scored)
  cur <- cur[cur$season == season & cur$season_type == "REG", ]
  if (nrow(cur) == 0) {
    stop("no ", season, " REG rows in fct_player_week_scored -- ",
         "data/raw/player_stats.parquet is stale. Re-run ingest_player_stats().")
  }

  snaps <- as.data.frame(arrow::read_parquet(snap_counts_path))
  snaps <- snaps[snaps$season == season, c("pfr_player_id", "week", "offense_pct", "st_pct")]
  snaps <- snaps[!duplicated(snaps[, c("pfr_player_id", "week")]), ]

  xwalk <- dim_player[!is.na(dim_player$pfr_id), c("player_key", "pfr_id")]
  cur <- merge(cur, xwalk, by = "player_key", all.x = TRUE, sort = FALSE)
  cur <- merge(cur, snaps,
               by.x = c("pfr_id", "week"), by.y = c("pfr_player_id", "week"),
               all.x = TRUE, sort = FALSE)

  # Injuries carry gsis_id natively, so this one needs no crosswalk. These
  # columns are correct for players who PLAYED and nothing more -- an Out
  # designation can never appear here, because an Out player has no stat row
  # to attach it to. Read dim_injury_week for availability. See that function
  # for the measured loss rate.
  inj <- as.data.frame(arrow::read_parquet(injuries_path))
  inj <- inj[inj$season == season & inj$season_type == "REG",
             c("gsis_id", "week", "report_status", "report_primary_injury")]
  inj <- inj[!duplicated(inj[, c("gsis_id", "week")]), ]
  cur <- merge(cur, inj,
               by.x = c("player_id", "week"), by.y = c("gsis_id", "week"),
               all.x = TRUE, sort = FALSE)

  front <- c("player_key", "player_id", "player_display_name", "position", "team",
             "opponent_team", "season", "week", "fantasy_points",
             "offense_pct", "st_pct", "report_status", "report_primary_injury")
  cur <- cur[order(cur$week, -cur$fantasy_points), ]
  cur[, c(intersect(front, colnames(cur)), setdiff(colnames(cur), front))]
}

#' Validate the in-season fact table, and report the two join rates.
#'
#' Snap match is reported rather than enforced: `pfr_id` is ~23% NA in the
#' crosswalk upstream, so a universal match is not achievable and a hard gate
#' would only fail every run. Kickers legitimately have no offensive snaps.
#'
#' @param fct data.frame from `build_fct_player_week_current()`.
#' @return `fct`, unchanged, or `stop()` on a grain or scoring violation.
validate_fct_player_week_current <- function(fct) {
  agent <- pointblank::create_agent(fct) |>
    pointblank::col_vals_not_null(pointblank::vars(player_id, season, week, fantasy_points)) |>
    pointblank::rows_distinct(pointblank::vars(player_id, season, week)) |>
    pointblank::interrogate()

  if (!pointblank::all_passed(agent)) {
    stop("fct_player_week_current failed validation:\n",
         paste(capture.output(print(agent)), collapse = "\n"))
  }

  skill <- fct[fct$position %in% c("QB", "RB", "WR", "TE"), ]
  message(sprintf(
    "fct_player_week_current: %d rows, weeks %s | snap match %.1f%% (skill positions)",
    nrow(fct), paste(sort(unique(fct$week)), collapse = ","),
    100 * mean(!is.na(skill$offense_pct))))

  fct
}
