source(file.path("..", "..", "R", "62_dst.R"))
# 20_stage.R (build_dim_player) is needed here too, only for the
# player_key-collision test -- it proves the synthetic DST keys never
# collide with a *real*, freshly-built dim_player, not just a hand-typed
# assumption about its range.
source(file.path("..", "..", "R", "20_stage.R"))
