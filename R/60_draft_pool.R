#' Build the 2026 draft-relevant player pool from FantasyPros redraft rankings.
#'
#' load_ff_rankings() returns every page_type FantasyPros publishes (best-ball,
#' dynasty, IDP, ...) mixed into one table. "redraft-overall" is the standard
#' season-long slice this league actually drafts under.
#'
#' `redraft-overall` is truncated: FantasyPros stops it around rank 525, and
#' 281 players who appear in the per-position pages (`redraft-qb`,
#' `redraft-rb`, `redraft-wr`, `redraft-te`, `redraft-k`) never appear in it.
#' Left out, those players are unselectable on the Board -- in a 10-team,
#' 17-round draft that is fine in round 2 and wrong in round 15, where the
#' waiver-tier tight end you want is simply absent from the app. So the
#' position slices are unioned in, and their position-scoped ranks are
#' rescaled onto the overall scale by `rescale_position_ranks()`.
#'
#' Crosswalked to dim_player via FantasyPros' own id (dim_player$fantasypros_id,
#' sourced from load_ff_playerids()) -- not yahoo_id, which is NA on this
#' page_type, and never by name.
#'
#' DST is dropped: it's scored at the team level in Yahoo, not from individual
#' player rows, and was never part of dim_player to begin with.
#'
#' `sd`/`best`/`worst`/`rank_delta` ride along beside `ecr`. FantasyPros'
#' ECR is the mean of many analysts' ranks; those four describe the spread
#' around it -- how much the experts disagree about a player. A rookie with
#' no NFL games has no stat line to project from, so that disagreement is
#' the only measure of confidence available for him, and R/77_consensus.R
#' turns it into a value estimate. Carried here rather than re-read from the
#' parquet downstream, so the pool stays the single source of ranking truth.
#'
#' @param ff_rankings_path Raw parquet from ingest_ff_rankings().
#' @param dim_player data.table from build_dim_player().
#' @return data.table, one row per draftable player: player_key, player, pos,
#'   team, ecr, sd, best, worst, rank_delta, bye, ecr_source.
build_draft_pool <- function(ff_rankings_path, dim_player) {
  rankings <- as.data.frame(arrow::read_parquet(ff_rankings_path))

  overall <- rankings[rankings$page_type == "redraft-overall" & rankings$pos != "DST", ]
  overall$ecr_source <- "overall"

  extra <- position_slice_rows(rankings, overall)

  pool <- rbind(overall[, POOL_RANK_COLS], extra[, POOL_RANK_COLS])

  crosswalk <- dim_player[, c("player_key", "fantasypros_id")]
  pool <- merge(pool, crosswalk, by.x = "id", by.y = "fantasypros_id", all.x = TRUE, sort = FALSE)

  # Unmatched rows here are deep-bench/rookie noise far outside any realistic
  # draft pool (verified: 46 of 525 in a 10-team league, all ranked 200th+),
  # not a crosswalk failure -- dropped rather than carried as NA player_key.
  pool <- pool[!is.na(pool$player_key), ]
  pool <- pool[order(pool$ecr), ]

  pool[, c("player_key", "player", "pos", "team",
           "ecr", "sd", "best", "worst", "rank_delta", "bye", "ecr_source")]
}

POOL_RANK_COLS <- c("id", "player", "pos", "team",
                    "ecr", "sd", "best", "worst", "rank_delta", "bye", "ecr_source")

#' Players who exist only on a per-position page, placed after the ranked board.
#'
#' The per-position pages rank a player against his own position (Brock Purdy
#' is QB 22), the overall page ranks him against everybody (Brock Purdy is
#' pick 142), so a position rank cannot go into the `ecr` column as-is.
#'
#' Translating one scale into the other by fitting the players on both pages
#' was tried and abandoned. The overall page is censored: its ECR compresses
#' hard as it approaches its own cutoff (the deepest 20 tight ends span
#' overall ranks 349 to 413, the deepest 10 quarterbacks span 330 to 356) and
#' then stops. The fitted map is therefore flat exactly where these players
#' live, which collapses dozens of them onto one number and gives several a
#' standard deviation of zero. The overall scale does not carry the
#' information, and no fit can recover it.
#'
#' So they are placed rather than translated. Within a position the ordering
#' is exact -- it is the position page's own ranking. Across positions they
#' are spread by that position's rank density (`position_rank_slope()`), so a
#' position whose players are thinly spread on the overall board stays thinly
#' spread here. All of them land past `ecr_floor`, behind every player the
#' overall page ranked, which is the one claim the source data does support:
#' FantasyPros ranked 500-odd players overall and did not rank these.
#'
#' Their `ecr` is an ordering key, not an expert rank. `ecr_source` says so,
#' and the Board's own value model is what actually prices them.
#'
#' Only the five offensive skill pages are used. `redraft-dst` is handled by
#' `build_dst_pool()`, and `redraft-{db,dl,lb,idp,op}` are IDP and superflex
#' formats this league does not play.
#'
#' @param rankings Full ff_rankings frame.
#' @param overall The redraft-overall, non-DST subset, already extracted.
#' @return Rows present in a position page but not in `overall`, with `ecr`,
#'   `sd`, `best`, `worst` restated on the overall scale and
#'   `ecr_source = "position"`.
position_slice_rows <- function(rankings, overall) {
  slice_pages <- c("redraft-qb", "redraft-rb", "redraft-wr", "redraft-te", "redraft-k")
  slices <- rankings[rankings$page_type %in% slice_pages, ]

  missing <- slices[!(slices$id %in% overall$id), ]
  if (nrow(missing) == 0) {
    empty <- missing
    empty$ecr_source <- character(0)
    return(empty[, POOL_RANK_COLS])
  }

  # A position page lists a player under exactly one position, so pos comes
  # from the row itself and needs no reconciliation with the page name.
  anchors <- merge(slices[, c("id", "pos", "ecr")],
                   overall[, c("id", "ecr")],
                   by = "id", suffixes = c("_pos", "_overall"))

  ecr_floor <- max(overall$ecr, na.rm = TRUE)

  out <- do.call(rbind, lapply(split(missing, missing$pos), function(grp) {
    ref <- anchors[anchors$pos == grp$pos[1], ]
    slope <- position_rank_slope(ref$ecr_pos, ref$ecr_overall)

    grp <- grp[order(grp$ecr), ]
    # Rank width, not rank position: sd is a spread in position-rank units, so
    # it converts by the same slope. best/worst are re-centred on the new ecr,
    # keeping each player's own asymmetry rather than flattening it.
    spread_lo <- (grp$ecr - grp$best) * slope
    spread_hi <- (grp$worst - grp$ecr) * slope

    grp$ecr <- ecr_floor + slope * seq_len(nrow(grp))
    grp$sd <- grp$sd * slope
    grp$best <- grp$ecr - spread_lo
    grp$worst <- grp$ecr + spread_hi
    grp
  }))
  rownames(out) <- NULL

  out <- out[!is.na(out$ecr), ]
  out$ecr_source <- "position"
  out[, POOL_RANK_COLS]
}

#' Overall ranks consumed per position rank, from the players on both pages.
#'
#' One WR slot costs about two overall picks because receivers are dense near
#' the top of the board; one TE slot costs about three and a half. The slope
#' is taken end to end over the anchor range rather than locally, because the
#' local slope is what the censoring at the deep end destroys.
#'
#' @param x,y Anchor pairs: position rank and the same players' overall rank.
#' @return Positive numeric. Falls back to 1 when there is nothing to fit.
position_rank_slope <- function(x, y) {
  ok <- !is.na(x) & !is.na(y)
  x <- x[ok]
  y <- y[ok]
  if (length(x) < 2) return(1)

  slope <- diff(range(y)) / diff(range(x))
  if (!is.finite(slope) || slope <= 0) 1 else slope
}

#' Validate the draft pool: one row per player, ECR must be present and positive.
#'
#' @param pool data.table from build_draft_pool().
validate_draft_pool <- function(pool) {
  agent <- pointblank::create_agent(pool) |>
    pointblank::col_vals_not_null(pointblank::vars(player_key, pos, ecr)) |>
    pointblank::col_vals_gt(pointblank::vars(ecr), 0) |>
    pointblank::rows_distinct(pointblank::vars(player_key)) |>
    pointblank::interrogate()

  if (!pointblank::all_passed(agent)) {
    stop("draft_pool failed validation:\n", paste(capture.output(print(agent)), collapse = "\n"))
  }
  invisible(pool)
}
