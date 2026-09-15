library(targets)

tar_source("R")

tar_option_set(packages = c("jsonlite", "jsonvalidate", "nflreadr", "data.table", "DBI", "duckdb", "arrow", "pointblank"))

list(
  tar_target(league_config_file, "config/league.json", format = "file"),
  tar_target(scoring_config_file, "config/scoring.json", format = "file"),
  tar_target(league_config, load_config("league", config_dir = dirname(league_config_file))),
  tar_target(scoring_config, load_config("scoring", config_dir = dirname(scoring_config_file))),

  # In-season, these five sources gain rows every week while their target
  # definitions stay byte-identical, so targets' default cue sees no reason to
  # re-run them and serves a stale cache indefinitely. The season argument does
  # not save us: it is evaluated inside the function, so targets never sees it
  # change. Measured 2026-09-15 -- a cache written 09-06 kept reporting max
  # season 2025 after week 1 had been played, and only tar_invalidate() broke it.
  #
  # cue = "always" re-pulls on every tar_make(). Downstream is gated on the
  # hash of the written parquet (format = "file"), not on the re-run itself.
  # Measured steady-state cost of a no-change tar_make(): ~24s, 18 of 26
  # targets skipped. ff_playerids_raw and ff_opportunity_raw do not round-trip
  # byte-stable, so dim_player and expected_stat_lines rebuild each run --
  # their *values* hash identical, so the cascade stops there and the board
  # and fact tables still skip. Two cheap rebuilds is the price of not
  # silently serving stale data; do not "optimize" this back to the default cue.
  #
  # ff_rankings_raw is deliberately NOT always-cued: it pulls season = "draft",
  # a preseason snapshot that does not change in-season.
  tar_target(player_stats_raw, ingest_player_stats(), format = "file",
             cue = tar_cue(mode = "always")),
  tar_target(ff_playerids_raw, ingest_ff_playerids(), format = "file",
             cue = tar_cue(mode = "always")),
  tar_target(players_raw, ingest_players(), format = "file",
             cue = tar_cue(mode = "always")),
  tar_target(ff_rankings_raw, ingest_ff_rankings(), format = "file"),
  tar_target(ff_opportunity_raw, ingest_ff_opportunity(), format = "file",
             cue = tar_cue(mode = "always")),

  # Yahoo's own draft ordering. Opponent model only -- never blended into vor.
  # See R/97_yahoo_adp.R for the name-join justification and match rate.
  tar_target(yahoo_adp_file, "docs/yahoo_fantasy_football_adp.csv", format = "file"),
  tar_target(yahoo_adp, load_yahoo_adp(yahoo_adp_file)),

  tar_target(dim_player, validate_dim_player(build_dim_player(ff_playerids_raw, players_raw))),
  tar_target(fct_player_week, validate_fct_player_week(build_fct_player_week(player_stats_raw, dim_player))),

  tar_target(fct_player_week_scored, add_fantasy_points(fct_player_week, scoring_config)),

  # In-season layer. Slices the fact table to the live season and attaches
  # role (snap share) and availability (injury designation) -- the two things
  # a start/sit decision needs that a season-long stat line does not carry.
  # Scoring is inherited from fct_player_week_scored, never recomputed.
  tar_target(snap_counts_raw, ingest_snap_counts(), format = "file",
             cue = tar_cue(mode = "always")),
  tar_target(injuries_raw, ingest_injuries(), format = "file",
             cue = tar_cue(mode = "always")),
  tar_target(fct_player_week_current,
             validate_fct_player_week_current(
               build_fct_player_week_current(fct_player_week_scored, snap_counts_raw,
                                             injuries_raw, dim_player))),
  # Separate from the fact table on purpose. A stats-derived table has no row
  # for a player who was ruled Out, which is the single most decision-relevant
  # state a start/sit picker can see. See build_dim_injury_week() for numbers.
  tar_target(dim_injury_week, build_dim_injury_week(injuries_raw)),

  # Expected (opportunity-driven) production, scored under this league's rules.
  # CLAUDE.md's core principle -- "opportunity is sticky, efficiency is mostly
  # noise" -- as an actual data source rather than an assertion. See PLAN_1.md
  # Phase 8.1 for why ranking on expected rather than actual points matters.
  tar_target(expected_stat_lines, build_expected_stat_lines(ff_opportunity_raw, dim_player)),
  tar_target(expected_stat_lines_scored, add_expected_fantasy_points(expected_stat_lines, scoring_config)),
  tar_target(player_opportunity,
             build_player_opportunity_value(expected_stat_lines_scored, fct_player_week_scored, season = 2025)),

  tar_target(draft_pool, validate_draft_pool(build_draft_pool(ff_rankings_raw, dim_player))),
  tar_target(player_value, build_player_value(fct_player_week_scored, draft_pool,
                                              player_opportunity = player_opportunity)),
  # add_consensus_rows() puts the no-stat-line players (2026 rookies, almost
  # all of them) onto the Board with a value estimated from expert consensus
  # rather than from games they haven't played. Before this they sat in an
  # untiered fallback section carrying only an expert rank, and placing them
  # against the Board was left to the drafter's eye under a 1-minute clock.
  # See R/77_consensus.R for the curve and the uncertainty penalty.
  tar_target(draft_board,
             add_yahoo_ranks(
               assign_tiers(validate_vor_table(
                 add_consensus_rows(compute_vor(player_value, league_config), player_value))),
               yahoo_adp, label = "draft_board")),

  # DSTs are team-level, so they have no dim_player row, no gsis_id, and no VOR.
  # They ride in the fallback section (has_current_data = FALSE) purely so the
  # draft app can record the pick -- without this the roster ends 16/17 with an
  # unfillable starter slot. Real DST valuation is deferred; see PLAN_1.md.
  tar_target(dst_pool, build_dst_pool(ff_rankings_raw)),

  # exclude_keys subtracts whoever the Board just absorbed via
  # add_consensus_rows(), so no player is selectable from two tables at once.
  # In practice this now leaves the fallback as DSTs plus anything the
  # consensus curve could not price.
  tar_target(draft_fallback,
             add_yahoo_ranks(
               rbind(build_fallback_board(player_value, exclude_keys = draft_board$player_key),
                     dst_pool),
               yahoo_adp, label = "draft_fallback"))
)
