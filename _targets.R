library(targets)

tar_source("R")

tar_option_set(packages = c("jsonlite", "jsonvalidate", "nflreadr", "data.table", "DBI", "duckdb", "arrow", "pointblank"))

list(
  tar_target(league_config_file, "config/league.json", format = "file"),
  tar_target(scoring_config_file, "config/scoring.json", format = "file"),
  tar_target(league_config, load_config("league", config_dir = dirname(league_config_file))),
  tar_target(scoring_config, load_config("scoring", config_dir = dirname(scoring_config_file))),

  tar_target(player_stats_raw, ingest_player_stats(), format = "file"),
  tar_target(ff_playerids_raw, ingest_ff_playerids(), format = "file"),
  tar_target(players_raw, ingest_players(), format = "file"),
  tar_target(ff_rankings_raw, ingest_ff_rankings(), format = "file"),

  tar_target(dim_player, validate_dim_player(build_dim_player(ff_playerids_raw, players_raw))),
  tar_target(fct_player_week, validate_fct_player_week(build_fct_player_week(player_stats_raw, dim_player))),

  tar_target(fct_player_week_scored, add_fantasy_points(fct_player_week, scoring_config)),

  tar_target(draft_pool, validate_draft_pool(build_draft_pool(ff_rankings_raw, dim_player))),
  tar_target(player_value, build_player_value(fct_player_week_scored, draft_pool)),
  tar_target(draft_board, assign_tiers(validate_vor_table(compute_vor(player_value, league_config)))),
  tar_target(draft_fallback, build_fallback_board(player_value))
)
