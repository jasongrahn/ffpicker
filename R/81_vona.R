#' Roll draft forward from current state to my next turn only.
#'
#' Opponents pick (`horizon` picks), I do not. Returns survival per player
#' and per-position best VOR distribution VONA needs.
#'
#' @param ctx list from sim_context().
#' @param state list from replay_pick_log().
#' @param horizon integer, picks_until_my_turn(state). 0 = everyone survives.
#' @param tau non-negative scalar. 0 = deterministic opponents.
#' @param n_sims integer default 1000L.
#' @param seed integer default 1L.
#' @return list(p_available, pos_best, n_sims, horizon, tau, elapsed_sec).
#'   p_available: data.frame(player_key, p_available) for every remaining player.
#'   pos_best: data.frame(pos, mean_best_vor, sd_best_vor).
simulate_forward <- function(ctx, state, horizon, tau, n_sims = 1000L, seed = 1L) {
  pool <- ctx$pool
  remaining <- remaining_draft_pool(pool, state)
  remaining_keys <- remaining$player_key
  n_remaining <- length(remaining_keys)

  # Precompute all vectors outside loop
  pool_keys <- pool$player_key
  pool_xrank <- pool$xrank
  pool_vor <- pool$vor
  pool_pos <- pool$pos
  n_pool <- nrow(pool)

  # Map remaining players to pool indices
  remaining_to_pool_idx <- match(remaining_keys, pool_keys)

  # Position indices (6 positions)
  positions <- c("QB", "RB", "WR", "TE", "K", "DST")
  pos_indices <- lapply(positions, function(p) which(pool_pos == p))
  names(pos_indices) <- positions

  # Track survival across replicates (matrix for speed)
  survival_matrix <- matrix(0L, nrow = n_sims, ncol = n_remaining)

  # Track pos_best values: matrix (n_sims x 6)
  pos_best_matrix <- matrix(NA_real_, nrow = n_sims, ncol = length(positions))

  elapsed_sec <- system.time({
    # Pre-generate all noise matrices
    noise_list <- lapply(seq_len(n_sims), function(s) {
      sim_noise(n_pool, horizon, seed = seed + s - 1)
    })

    for (s in seq_len(n_sims)) {
      noise_matrix <- noise_list[[s]]

      # Mark alive: TRUE for remaining, FALSE for already drafted
      alive <- logical(n_pool)
      alive[remaining_to_pool_idx] <- TRUE

      # Simulate opponent picks
      for (pick_num in seq_len(horizon)) {
        remaining_idx <- which(alive)
        if (length(remaining_idx) == 0) break

        # Draw opponent pick
        xrank_vals <- pool_xrank[remaining_idx]
        noise_vals <- noise_matrix[remaining_idx, pick_num]

        idx_in_remaining <- draw_opponent_pick(xrank_vals, tau, noise_vals)
        pick_row_id <- remaining_idx[idx_in_remaining]
        alive[pick_row_id] <- FALSE
      }

      # Record survival: map back to remaining indices
      for (i in seq_len(n_remaining)) {
        pool_idx <- remaining_to_pool_idx[i]
        if (alive[pool_idx]) {
          survival_matrix[s, i] <- 1L
        }
      }

      # Compute pos_best for this replicate
      for (j in seq_along(positions)) {
        p <- positions[j]
        idx_in_pos <- pos_indices[[p]]
        idx_alive <- idx_in_pos[alive[idx_in_pos]]

        if (length(idx_alive) > 0) {
          vors_alive <- pool_vor[idx_alive]
          finite_vors <- vors_alive[is.finite(vors_alive)]
          if (length(finite_vors) > 0) {
            pos_best_matrix[s, j] <- max(finite_vors)
          }
        }
      }
    }
  })[3]  # Extract elapsed time (user + system)

  # Convert survival to probabilities
  p_available <- data.frame(
    player_key = remaining_keys,
    p_available = colSums(survival_matrix) / n_sims,
    stringsAsFactors = FALSE
  )
  rownames(p_available) <- NULL

  # Aggregate pos_best: mean and sd per position
  pos_best_summary <- data.frame(
    pos = positions,
    mean_best_vor = colMeans(pos_best_matrix, na.rm = TRUE),
    sd_best_vor = apply(pos_best_matrix, 2, sd, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
  rownames(pos_best_summary) <- NULL

  list(
    p_available = p_available,
    pos_best = pos_best_summary,
    n_sims = n_sims,
    horizon = horizon,
    tau = tau,
    elapsed_sec = elapsed_sec
  )
}

#' VONA: value lost by waiting.
#'
#' VONA(X) = vor(X) - E[vor of best available at pos(X) next turn].
#' NA when vor is NA or position missing from pos_best.
#'
#' DEGENERATE WITHIN A POSITION -- Experiment B, closed 2026-09-07. The
#' subtracted term is read out of `pos_map` by position alone. Hold the position
#' fixed and it is a constant, so ordering by VONA equals ordering by `vor` and
#' argmax-VONA equals argmax-`vor`. Measured: 0 picks changed across 124 drafts,
#' 1920/1920 tiebreak picks identical, paired CI [0.0, 0.0], sd 0.0. This is
#' algebra, not an underpowered measurement -- no seed count, tau or n_sims
#' changes it. VONA only says something ACROSS positions, where the subtracted
#' term varies. See dev/PREREG_B.md and CLAUDE.md.
#'
#' @param board_remaining data.frame with pos, vor columns.
#' @param pos_best data.frame from simulate_forward() with pos, mean_best_vor.
#' @return numeric, length nrow(board_remaining).
vona <- function(board_remaining, pos_best) {
  # Build position-to-mean_best_vor lookup
  pos_map <- setNames(pos_best$mean_best_vor, pos_best$pos)

  # Compute VONA for each player
  result <- numeric(nrow(board_remaining))
  for (i in seq_len(nrow(board_remaining))) {
    player_vor <- board_remaining$vor[i]
    player_pos <- board_remaining$pos[i]

    if (is.na(player_vor)) {
      result[i] <- NA_real_
    } else if (!(player_pos %in% names(pos_map))) {
      result[i] <- NA_real_
    } else {
      best_next <- pos_map[[player_pos]]
      if (is.na(best_next)) {
        result[i] <- NA_real_
      } else {
        result[i] <- player_vor - best_next
      }
    }
  }
  result
}

#' Display VONA: plain signed number.
#'
#' @param v numeric scalar or vector, may contain NA.
#' @return character vector, e.g. "+12.4" or "-5.2" or "" for NA.
vona_display <- function(v) {
  ifelse(is.na(v), "", sprintf("%+.1f", v))
}

#' Display survival: percentage or low-survival warning.
#'
#' The piece of this file that is NOT closed. `simulate_forward()`'s
#' `p_available` never failed a bar because it was never a selector -- it is a
#' readout. "12% he survives to your next pick" is the question a human has on
#' the clock, and it is orthogonal to every VONA verdict. Unwired to
#' inst/app/app.R only because the 2026-09-08 draft was hours out when it was
#' built. Revive this before reviving any VONA arm.
#'
#' @param p numeric between 0 and 1, or NA. May be vector.
#' @return character. NA -> "", p >= 0.25 -> "NN%", p < 0.25 -> html red warning.
survival_display <- function(p) {
  result <- character(length(p))
  for (i in seq_along(p)) {
    if (is.na(p[i])) {
      result[i] <- ""
    } else if (p[i] >= 0.25) {
      result[i] <- sprintf("%d%%", round(p[i] * 100))
    } else {
      pct <- round(p[i] * 100)
      result[i] <- sprintf('<span style="color: #d32f2f; font-weight: bold;">%d%% ⚠</span>', pct)
    }
  }
  result
}

# Constant for low survival threshold
VONA_LOW_SURVIVAL <- 0.25

#' Positions the mandatory-starter-fill constraint forces this pick.
#'
#' Experiment A -- measured, NOT wired to the app. Bar A2 as pre-registered
#' FAILED (single frozen seed, tau=3); 30 seeds CRN then gave +7..+81 and a 93%
#' win rate, losing at no tau. Unresolved on purpose, see CLAUDE.md.
#'
#' VONA argmax across all positions drafted zero K and zero DST
#' at every tau -- correct VONA reasoning (near-identical kickers -> replacement
#' sits right behind -> tiny VONA) applied to a slot the league makes mandatory.
#' Once rounds left <= starter slots still empty, every remaining pick must
#' close a slot or one stays open.
#'
#' Which slots are open is read two ways, both existing code, neither
#' reinvented: `scarcity_report()`'s `still_needed` says *which* positions can
#' close a slot (it already models dedicated + FLEX correctly), and
#' `starter_value()`'s greedy fill says *how many* slots are still open.
#'
#' @param report data.frame from scarcity_report(); needs pos, still_needed.
#' @param picks data.frame of my picks so far; needs pos, vor. May be empty.
#' @param league_config list from load_config("league").
#' @param rounds_remaining integer, rounds left INCLUDING the current one.
#' @return character vector of positions to restrict the pick to. character(0)
#'   means unconstrained -- either slack remains, or the lineup is already full.
forced_positions <- function(report, picks, league_config, rounds_remaining) {
  total_slots <- sum(unlist(league_config$roster$starters))

  filled <- if (is.null(picks) || nrow(picks) == 0) {
    0L
  } else {
    nrow(starter_value(picks, league_config)$lineup)
  }
  slots_unfilled <- total_slots - filled

  if (slots_unfilled <= 0 || rounds_remaining > slots_unfilled) return(character(0))

  need <- report$pos[!is.na(report$still_needed) & report$still_needed > 0]
  as.character(need)
}
