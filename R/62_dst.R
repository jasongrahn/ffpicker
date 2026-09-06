#' Build the draftable pool of team Defense/Special Teams (DST) units.
#'
#' `build_draft_pool()` (R/60_draft_pool.R) drops every DST row outright,
#' because a DST is scored at the team level in Yahoo, not from an
#' individual player row, so it was never part of `dim_player` -- there is
#' no `gsis_id`, no `fantasypros_id` crosswalk match, nothing to join on.
#' Left unfixed, the app cannot record a DST pick at all and the roster ends
#' the draft 16/17 with an unfillable `DST` starter slot
#' (`config/league.json`'s `roster$starters$DST` is 1).
#'
#' This is the cheap, draft-unblocking fix only: it makes the 32 team
#' defenses *selectable* with an ECR-only fallback-board shape. Real DST
#' scoring/valuation from `nflreadr::load_team_stats()` (sacks, INTs,
#' points-allowed tiers, etc. -- see `config/scoring.json`'s `dst` block) is
#' deliberately deferred to after the 2026-09-08 draft.
#'
#' Team abbreviation normalization is CLAUDE.md's one deliberate, bounded
#' exception to "never join on name": these 32 rows are matched on team
#' *abbreviation*, not player name, the set is fixed and small enough to
#' hand-check, and there is no `dim_player` row a DST could ever collide
#' with by name. Verified live 2026-09-06 against
#' `nflreadr::team_abbr_mapping`: FantasyPros' redraft-overall DST rows spell
#' Jacksonville "JAC" (nflreadr canonical: "JAX") and the LA Rams "LAR"
#' (nflreadr canonical: "LA"); all other 30 abbreviations already agree.
#' `nflreadr::clean_team_abbrs()` fixes both without a network call -- it
#' looks up the bundled `team_abbr_mapping` table, not
#' `nflreadr::load_teams()` (which does hit the network).
#'
#' @param ff_rankings_path Raw parquet from ingest_ff_rankings().
#' @return data.table, one row per DST, in the same column shape as
#'   `build_fallback_board()` (R/75_value.R) -- player_key, player, pos,
#'   team, ecr, bye, ppg_current, games_current, availability_rate,
#'   has_current_data, projected_points -- so it can be `rbind()`ed straight
#'   onto the fallback board into one selectable pool. `has_current_data` is
#'   always FALSE and the stat columns are always NA: DSTs never get a real
#'   per-game fantasy log in this cheap version, so they must present as
#'   fallback-board rows, never as VOR-ranked ones.
build_dst_pool <- function(ff_rankings_path) {
  rankings <- as.data.frame(arrow::read_parquet(ff_rankings_path))
  dst <- rankings[rankings$page_type == "redraft-overall" & rankings$pos == "DST", ]

  dst$team <- nflreadr::clean_team_abbrs(dst$team)

  # canonical_teams comes from nflreadr's own bundled mapping table (not
  # hand-typed) so it can never drift out of sync with clean_team_abbrs()'s
  # output; AFC/NFC/NFL are conference-level pseudo-codes in that table, not
  # teams, and are excluded.
  canonical_teams <- sort(setdiff(unique(nflreadr::team_abbr_mapping), c("AFC", "NFC", "NFL")))
  team_idx <- match(dst$team, canonical_teams)
  if (anyNA(team_idx)) {
    stop(
      "build_dst_pool: team abbreviation(s) not recognized after clean_team_abbrs(): ",
      paste(unique(dst$team[is.na(team_idx)]), collapse = ", ")
    )
  }

  # --- Synthetic player_key: why it cannot collide -------------------------
  # build_dim_player() (R/20_stage.R) assigns every REAL player_key as
  # `seq_len(nrow(dim))` -- a positive integer starting at 1, and it always
  # will be, no matter how large the crosswalk grows in a future ingest.
  # Every synthetic DST key here is forced NEGATIVE, so disjointness is
  # guaranteed by *sign*, not by picking a magnitude bigger than today's max
  # real key (which would silently break the day dim_player crosses it).
  #
  # Within the negative range, the key is derived from `team_idx` -- the
  # team's fixed alphabetical rank among all 32 canonical NFL abbreviations
  # -- rather than the row's position in the rankings file, so the same team
  # gets the same key on every re-ingest regardless of row order upstream.
  # DST_KEY_BASE is just a spacer to keep the values visually distinct from
  # "-1, -2, -3..."; it plays no role in the disjointness proof, which holds
  # for any negative integer.
  DST_KEY_BASE <- 900000L
  dst$player_key <- -(DST_KEY_BASE + team_idx)

  pool <- dst[order(dst$ecr), c("player_key", "player", "pos", "team", "ecr", "bye")]

  # Match build_player_value()'s column shape (R/75_value.R) exactly, so
  # this can be rbind()ed onto build_fallback_board()'s output. Every DST
  # gets has_current_data = FALSE / projected_points = NA, same as a rookie
  # with no current-season games -- the fallback board's existing meaning
  # for "no VOR, ECR-only".
  pool$ppg_current <- NA_real_
  pool$games_current <- NA_integer_
  pool$availability_rate <- NA_real_
  pool$has_current_data <- FALSE
  pool$projected_points <- NA_real_

  # Expected basis, present once _targets.R passes player_opportunity into
  # build_player_value(). DSTs are team-level, so ff_opportunity has no row
  # for them at all -- has_expected_data = FALSE is the true value here, not
  # a placeholder. Same "no data, ECR-only" meaning as the columns above.
  pool$ppg_expected <- NA_real_
  pool$has_expected_data <- FALSE
  pool$projected_points_exp <- NA_real_

  pool
}
