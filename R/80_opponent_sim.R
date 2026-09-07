#' Build simulation context from draft board + fallback.
#'
#' Combines draft board, fallback, scarcity input, and rankings into single ctx.
#' Mirrors dev/dryrun.R:14-24 exactly.
#'
#' @param draft_board data.frame from tar_read(draft_board).
#' @param draft_fallback data.frame from tar_read(draft_fallback).
#' @return list(pool, scarcity_board, board, fallback). pool combines
#'   selectable pool + ecr/vor/xrank columns. board/fallback are as.data.frame()
#'   versions of inputs. scarcity_board from scarcity_input().
sim_context <- function(draft_board, draft_fallback) {
  pkgload::load_all(quiet = TRUE)

  board <- as.data.frame(draft_board)
  fallback <- as.data.frame(draft_fallback)
  scarcity_board <- scarcity_input(board, fallback)

  pool <- combined_selectable_pool(board, fallback)
  pool$ecr <- c(board$ecr, fallback$ecr)
  pool$vor <- c(board$vor, rep(NA_real_, nrow(fallback)))
  pool$xrank <- c(board$xrank, fallback$xrank)

  list(pool = pool, scarcity_board = scarcity_board, board = board, fallback = fallback)
}

#' Gumbel(0,1) noise indexed by (player row, overall pick number).
#'
#' Common random numbers: player pick n always same shock even if two scenarios
#' diverged upstream, since noise is indexed by pick number, not draw order.
#'
#' @param n_players integer, nrow of pool.
#' @param n_picks integer, total picks (teams * rounds).
#' @param seed integer for set.seed().
#' @return numeric matrix, n_players x n_picks. Entry [i, j] is Gumbel(0,1)
#'   noise for player i at overall pick j.
sim_noise <- function(n_players, n_picks, seed) {
  set.seed(seed)
  matrix(-log(-log(runif(n_players * n_picks))), nrow = n_players, ncol = n_picks)
}

#' One opponent pick under Plackett-Luce model.
#'
#' score_i = -xrank_i / tau + noise_i, argmax. tau == 0 -> deterministic
#' argmin(xrank), with NA last in original row order.
#' NA xrank -> score -Inf, so unlisted players only reachable once every
#' listed player gone.
#'
#' @param xrank numeric, may contain NA. Vector of rankings for available players.
#' @param tau non-negative scalar. 0 = deterministic. Higher = more noise.
#' @param noise numeric, length(xrank), default NULL. Ignored if tau == 0 or NULL.
#' @return single integer index into xrank.
draw_opponent_pick <- function(xrank, tau, noise = NULL) {
  if (tau == 0) {
    # Deterministic: argmin(xrank), NA last in original row order
    order_xrank <- order(xrank)
    return(order_xrank[1])
  }

  # tau > 0: Plackett-Luce with noise
  # For NA xrank, score is -Inf (unlisted players only picked when all listed are gone)
  score <- ifelse(is.na(xrank), -Inf, -xrank / tau + noise)
  which.max(score)
}

#' Full T x R draft simulation with configurable opponent model.
#'
#' Generalizes dev/dryrun.R by parameterizing on tau. tau = 0 reproduces
#' deterministic opponent picks exactly. Opponents sample by argmin(xrank)
#' when tau = 0, or by Plackett-Luce when tau > 0.
#'
#' @param ctx list from sim_context().
#' @param league_config list from load_config("league").
#' @param my_slot integer, draft slot (1-indexed).
#' @param defer named list, e.g. list(K = 16, DST = 15, QB = 7).
#' @param tau non-negative scalar. 0 = deterministic (exactly dev/dryrun.R).
#' @param noise numeric matrix from sim_noise(), nrow == nrow(ctx$pool),
#'   ncol == teams * rounds. NULL allowed only if tau == 0.
#' @param my_team character, default "JGrahnasaurs".
#' @param my_rule character, "recommend" (use recommend_picks()),
#'   Only "recommend" is used outside dev/ -- the three VONA arms are measurement
#'   arms, all closed 2026-09-07, kept as reproducible negative results. Verdicts
#'   in CLAUDE.md; do not re-run without reading it.
#'   "vona" (argmax vona, requires simulate_forward(); REJECTED #19 -- drafts
#'   zero K and zero DST at every tau), "vona_fill"
#'   (vona plus the Experiment A mandatory-starter-fill constraint --
#'   see forced_positions()), or "vona_tiebreak" (Experiment B: position from
#'   target_position() as today, VONA orders candidates within it only; NO-OP BY
#'   ALGEBRA -- see vona() in R/81_vona.R. Kept so nobody retries it).
#' @param tiebreak_sign 1 by default. Mutation-test hook for "vona_tiebreak"
#'   only: -1 reverses the within-position ranking key, which must change picks
#'   if the tiebreak branch is live at all. Never set it anywhere but
#'   dev/bars_b_mutation.R.
#' @return list(picks, advice, defer, tau, tb_log). picks data.frame with columns:
#'   round, overall, player, pos, team, ecr, vor, xrank, source.
#'   advice character vector of recommendations. defer copy of input.
simulate_draft <- function(ctx, league_config, my_slot, defer, tau, noise = NULL,
                           my_team = "JGrahnasaurs", my_rule = "recommend",
                           tiebreak_sign = 1) {
  if (is.null(noise) && tau != 0) {
    stop("noise cannot be NULL when tau > 0")
  }

  pool <- ctx$pool
  scarcity_board <- ctx$scarcity_board

  TEAMS <- league_config$teams
  ROUNDS <- league_config$roster$rounds %||% 17

  # Set up pick log
  log_path <- tempfile(fileext = ".jsonl")
  file.create(log_path)

  cfg <- league_config
  cfg$draft$defer_until_round <- defer

  start_draft(log_path, TEAMS, my_team, my_slot)

  my_picks <- data.frame()
  advice <- character(0)
  tb_log <- NULL

  # Track row_id in pool for noise indexing
  if (!("row_id" %in% names(pool))) {
    pool$row_id <- seq_len(nrow(pool))
  }

  for (n in seq_len(TEAMS * ROUNDS)) {
    state <- replay_pick_log(log_path)
    remaining <- remaining_draft_pool(pool, state)
    remaining_board_rows <- remaining_draft_pool(scarcity_board, state)
    rnd <- ceiling(n / TEAMS)

    if (slot_on_the_clock(n, TEAMS) == my_slot) {
      report <- scarcity_report(scarcity_board, state, cfg)

      if (my_rule == "recommend") {
        rec <- recommend_picks(report,
                               remaining_draft_pool(ctx$board, state),
                               remaining_draft_pool(ctx$fallback, state))

        advice <- c(advice, sprintf("R%02d  %s", rnd, explain_scarcity(report, rec)))

        if (nrow(rec) == 0) {
          # No recommendation -> take best bench player (highest VOR)
          rb <- remaining_draft_pool(ctx$board, state)
          rb <- rb[!(rb$pos %in% names(deferred_notes(report))), ]
          rb <- rb[order(rb$vor, decreasing = TRUE), ]
          pick_key <- rb$player_key[1]
          src <- "bench"
        } else {
          # Match recommendation to remaining pool
          hit <- which(remaining$player == rec$Player[1] & remaining$pos == rec$Pos[1] &
                       remaining$team == rec$Team[1])
          if (length(hit) != 1) stop(sprintf("round %d: %s matched %d rows", rnd,
                                             rec$Player[1], length(hit)))
          pick_key <- remaining$player_key[hit]
          src <- "advised"
        }
      } else if (my_rule == "vona_tiebreak") {
        # Experiment B. Position choice is NOT touched -- target_position()
        # still names it, exactly as the recommend arm. VONA only orders
        # candidates *within* that position. Every other path (bench branch,
        # fallback-by-ECR branch, advice string) is the recommend arm verbatim,
        # so any measured difference is attributable to the tiebreak alone.
        board_rem <- remaining_draft_pool(ctx$board, state)
        fb_rem <- remaining_draft_pool(ctx$fallback, state)
        rec <- recommend_picks(report, board_rem, fb_rem)
        advice <- c(advice, sprintf("R%02d  %s", rnd, explain_scarcity(report, rec)))

        tb_pos <- target_position(report)
        cand <- if (is.na(tb_pos)) {
          board_rem[0, , drop = FALSE]
        } else {
          board_rem[board_rem$pos == tb_pos, , drop = FALSE]
        }

        if (nrow(rec) == 0 || nrow(cand) == 0) {
          # Nothing for a within-position tiebreak to reorder: either no starter
          # slot is open (bench branch), or the target position survives only in
          # the fallback, which carries no vor (DST). Recommend arm, unchanged.
          if (nrow(rec) == 0) {
            rb <- board_rem[!(board_rem$pos %in% names(deferred_notes(report))), ]
            rb <- rb[order(rb$vor, decreasing = TRUE), ]
            pick_key <- rb$player_key[1]
            src <- "bench"
          } else {
            hit <- which(remaining$player == rec$Player[1] & remaining$pos == rec$Pos[1] &
                         remaining$team == rec$Team[1])
            if (length(hit) != 1) stop(sprintf("round %d: %s matched %d rows", rnd,
                                               rec$Player[1], length(hit)))
            pick_key <- remaining$player_key[hit]
            src <- "advised"
          }
        } else {
          horizon <- picks_until_turn(n + 1L, my_slot, TEAMS)
          vor_pick <- cand$player_key[order(cand$vor, decreasing = TRUE)][1]

          if (is.null(horizon) || horizon == 0) {
            pick_key <- vor_pick
            src <- "advised"
          } else {
            fwd <- simulate_forward(ctx, state, horizon = horizon, tau = tau,
                                    n_sims = 200L, seed = n)
            v <- vona(cand, fwd$pos_best) * tiebreak_sign
            if (all(is.na(v))) {
              pick_key <- vor_pick
              src <- "advised"
            } else {
              pick_key <- cand$player_key[which.max(replace(v, is.na(v), -Inf))]
              src <- "vona_tb"
            }
            tb_log <- rbind(tb_log, data.frame(
              round = rnd, pos = tb_pos, n_cand = nrow(cand),
              vona_pick = pick_key, vor_pick = vor_pick,
              same = identical(pick_key, vor_pick),
              stringsAsFactors = FALSE
            ))
          }
        }
      } else if (my_rule %in% c("vona", "vona_fill")) {
        # VONA arm. Still emits the same advice string -- advice is the
        # explanation surface, unchanged. Only the pick differs.
        rec <- recommend_picks(report,
                               remaining_draft_pool(ctx$board, state),
                               remaining_draft_pool(ctx$fallback, state))
        advice <- c(advice, sprintf("R%02d  %s", rnd, explain_scarcity(report, rec)))

        # Horizon = opponents between THIS pick and my next one. Measured
        # from n+1, not from the current state: picks_until_my_turn() reads 0
        # while I am on the clock, which would make the lookahead vacuous.
        horizon <- picks_until_turn(n + 1L, my_slot, TEAMS)
        board_rem <- remaining_draft_pool(ctx$board, state)
        # Respect deferral exactly as the recommend arm's bench branch does.
        # Without this VONA takes a kicker in round 1: a K's vor beats his
        # positional replacement by a mile, which is true and useless.
        board_rem <- board_rem[!(board_rem$pos %in% names(deferred_notes(report))), ]

        # Experiment A. When rounds left <= starter slots still open, every
        # pick must close a slot. Deferral loses here by construction: the
        # constraint only fires when there is no round left to wait for.
        forced <- character(0)
        if (my_rule == "vona_fill") {
          forced <- forced_positions(report, my_picks, league_config,
                                     rounds_remaining = ROUNDS - rnd + 1L)
          if (length(forced) > 0) {
            # Candidates drawn from the whole remaining pool, not just the
            # board: a mandatory slot has to be closed even if only off-board
            # fallback players are left at that position. Those carry vor NA,
            # so vona() reads NA and the vor sort drops them last -- which is
            # the right order among them (pool order is ecr order).
            cand <- remaining[remaining$pos %in% forced, ]
            if (nrow(cand) == 0) {
              # Position exhausted league-wide. Nothing to force; the slot
              # cannot be filled by anyone, so fall back to the normal rule.
              forced <- character(0)
            } else {
              board_rem <- cand
            }
          }
        }

        if (is.null(horizon) || horizon == 0 || nrow(board_rem) == 0) {
          # No lookahead possible -> fall back to today's rule.
          if (length(forced) > 0) {
            rb <- remaining[remaining$pos %in% forced, ]
          } else {
            rb <- remaining_draft_pool(ctx$board, state)
            rb <- rb[!(rb$pos %in% names(deferred_notes(report))), ]
          }
          if (length(forced) == 0 && nrow(rec) > 0) {
            hit <- which(remaining$player == rec$Player[1] & remaining$pos == rec$Pos[1] &
                         remaining$team == rec$Team[1])
            pick_key <- remaining$player_key[hit[1]]
            src <- "advised"
          } else {
            rb <- rb[order(rb$vor, decreasing = TRUE), ]
            pick_key <- rb$player_key[1]
            src <- if (length(forced) > 0) "forced" else "bench"
          }
        } else {
          fwd <- simulate_forward(ctx, state, horizon = horizon, tau = tau,
                                  n_sims = 200L, seed = n)
          v <- vona(board_rem, fwd$pos_best)
          if (all(is.na(v))) {
            board_rem <- board_rem[order(board_rem$vor, decreasing = TRUE), ]
            pick_key <- board_rem$player_key[1]
            src <- if (length(forced) > 0) "forced" else "bench"
          } else {
            pick_key <- board_rem$player_key[which.max(replace(v, is.na(v), -Inf))]
            src <- if (length(forced) > 0) "vona_forced" else "vona"
          }
        }
      } else {
        stop("my_rule must be 'recommend', 'vona', 'vona_fill' or 'vona_tiebreak'")
      }

      row <- remaining[remaining$player_key == pick_key, ]
      my_picks <- rbind(my_picks, data.frame(
        round = rnd, overall = n, player = row$player, pos = row$pos,
        team = row$team, ecr = round(row$ecr), vor = round(row$vor, 1),
        xrank = row$xrank, source = src, stringsAsFactors = FALSE
      ))
    } else {
      # Opponent pick
      remaining_idx <- which(pool$player_key %in% remaining$player_key)
      xrank_vals <- pool$xrank[remaining_idx]

      if (tau == 0) {
        # Deterministic
        noise_vals <- NA
      } else {
        noise_vals <- noise[remaining_idx, n]
      }

      idx_in_remaining <- draw_opponent_pick(xrank_vals, tau, noise_vals)
      pick_row_id <- remaining_idx[idx_in_remaining]
      pick_key <- pool$player_key[pick_row_id]
    }

    append_pick_event(log_path, list(type = "pick_made", slot = n,
                                     team = if (slot_on_the_clock(n, TEAMS) == my_slot) my_team else paste("Team", slot_on_the_clock(n, TEAMS)),
                                     player_key = pick_key))
  }

  list(picks = my_picks, advice = advice, defer = defer, tau = tau,
       tb_log = tb_log)
}

#' Greedy starter fill, then total the starters' Extra pts.
#'
#' Copied from dev/dryrun.R:93-117. That total is the decision metric:
#' a deferral is only worth adding if the lineup it produces is better.
#'
#' @param picks data.frame from simulate_draft()$picks.
#' @param league_config list from load_config("league").
#' @return list(lineup, unfilled, total). lineup data.frame of starting players.
#'   unfilled character vector of position slots not filled. total numeric VOR sum.
starter_value <- function(picks, league_config) {
  starters <- league_config$roster$starters
  flex_pos <- unlist(league_config$roster$flex_eligible$FLEX)
  picks <- picks[order(picks$vor, decreasing = TRUE, na.last = TRUE), ]
  used <- rep(FALSE, nrow(picks))
  chosen <- integer(0)
  unfilled <- character(0)

  take <- function(p, k) {
    idx <- which(!used & picks$pos %in% p)
    idx <- head(idx, k)
    used[idx] <<- TRUE
    chosen <<- c(chosen, idx)
    length(idx)
  }
  for (p in setdiff(names(starters), "FLEX")) {
    got <- take(p, starters[[p]])
    if (got < starters[[p]]) unfilled <- c(unfilled, sprintf("%s %d/%d", p, got, starters[[p]]))
  }
  got <- take(flex_pos, starters$FLEX %||% 0)
  if (got < (starters$FLEX %||% 0)) unfilled <- c(unfilled, "FLEX unfilled")

  list(lineup = picks[chosen, ], unfilled = unfilled,
       total = sum(picks$vor[chosen], na.rm = TRUE))
}

#' Paired bootstrap CI on per-sim difference vector.
#'
#' Computes confidence interval on mean difference (A - B) using bootstrap.
#'
#' @param delta numeric, one entry per sim replicate (scenario A total minus B).
#' @param n_boot integer, default 10000L.
#' @param conf numeric default 0.95.
#' @return list(mean, lo, hi, p_a_gt_b, n). mean is mean(delta).
#'   lo/hi are bootstrap CI bounds. p_a_gt_b is mean(delta > 0).
#'   n is length(delta).
paired_bootstrap_ci <- function(delta, n_boot = 10000L, conf = 0.95) {
  n <- length(delta)
  mean_delta <- mean(delta, na.rm = TRUE)

  boot_means <- numeric(n_boot)
  for (i in seq_len(n_boot)) {
    boot_sample <- sample(delta, size = n, replace = TRUE)
    boot_means[i] <- mean(boot_sample, na.rm = TRUE)
  }

  alpha <- 1 - conf
  lo <- quantile(boot_means, alpha / 2, names = FALSE)
  hi <- quantile(boot_means, 1 - alpha / 2, names = FALSE)
  p_a_gt_b <- mean(delta > 0, na.rm = TRUE)

  list(mean = mean_delta, lo = lo, hi = hi, p_a_gt_b = p_a_gt_b, n = n)
}
