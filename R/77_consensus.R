#' Estimate a Board value for players with no stat line, from expert consensus.
#'
#' `compute_vor()` (R/75_value.R) can only rank a player it can project, and it
#' can only project a player who played games. That leaves 89 players --
#' overwhelmingly 2026 rookies -- with a real expert rank and no Board row at
#' all, parked in an untiered fallback section under the Board. The app told
#' the drafter to "use expert rank to place a rookie against the board above",
#' which is exactly the manual eyeballing this tool exists to remove: under a
#' 1-minute clock, comparing "expert rank 40" in one table against "+68 Extra
#' pts" in another is not a comparison a human makes reliably.
#'
#' So give them a number on the same scale as everyone else, and be honest that
#' it is a different KIND of number. A projected player's value comes from his
#' own production. A consensus player's value comes from where the experts rank
#' him and how much they disagree -- nothing else. Both land in the Board's
#' `vor` column; `value_source` says which is which, and the app marks the
#' estimated ones so they never masquerade as projections.
#'
#' ## How the estimate is built
#'
#' Two monotone fits per position, both on the ranked players only:
#'
#' 1. **ECR -> VOR.** Value falls as expert rank worsens, steeply at the top and
#'    flat in the deep pool. Fit with `stats::isoreg()`, which imposes exactly
#'    that -- monotone, no assumed functional form, no extra dependency. A
#'    parametric curve would have to guess at the shape of the cliff; the
#'    isotonic fit reads it off the 389 players who already have one.
#' 2. **ECR -> sd.** Expert disagreement is mostly a function of depth, not of
#'    the individual: median `sd` runs 5.1 inside the top 25 and 30.6 past rank
#'    200. Raw `sd` is therefore NOT a clean uncertainty signal -- penalising it
#'    directly would just charge deep players twice for being deep. This fit
#'    says what spread is *normal* at a given rank, so only the excess counts.
#'
#' ## Why the penalty is applied in rank space
#'
#' Uncertainty is charged as `ecr_adj = ecr + max(0, sd - normal_sd_at_ecr)`,
#' then the value curve is read at `ecr_adj`. The obvious alternative --
#' shrinking the fitted VOR toward an anchor in proportion to `sd` -- breaks on
#' this board. VOR is negative for most of the pool (position mean VOR: RB
#' -55.6, WR -49.8), so shrinking a deep, contested player's negative VOR
#' toward replacement level *raises* him. Uncertainty would become a promotion.
#'
#' Rank space has no such failure mode: the penalty can only move a player
#' later, never earlier, and the curve flattens out in the deep pool, so a
#' badly contested player settles below replacement and stops falling.
#'
#' Sizes, on the live board: median penalty 2.6 ranks, max 57.6 (Juice Wells
#' Jr., WR, sd 94.5 where 36.9 is normal), and 36 of the 89 pay nothing at all.
#' Jeremiyah Love (RB, ecr 40.1, sd 7.9 against 6.8 normal) is charged 1.0 rank
#' and keeps essentially his consensus value -- the experts are unanimous about
#' him, so there is nothing to discount, and he lands at +51 VOR between
#' D'Andre Swift and Emeka Egbuka, exactly where his rank says he belongs.
#' Travis Hunter (WR, ecr 197.6, sd 38.5 against 31.2 normal) is charged 7.3
#' and finishes at -63 VOR, tier 18. Note honestly that his burial is mostly
#' his ECR, not the penalty: the penalty is a correction on top of consensus,
#' not a replacement for it.
#'
#' ## What this deliberately does not do
#'
#' Replacement level is not recomputed after these rows are added. It is set by
#' `compute_vor()` from players with real projections, and these estimates are
#' derived *from* that same curve -- feeding them back into the level that
#' defines them would be circular. The effect is second-order (replacement
#' shifts by at most a rank or two) and the honesty is worth more before a
#' draft two days out.
#'
#' @param vor_table data.frame from compute_vor() -- ranked players only.
#' @param value_table data.frame from build_player_value() -- every player,
#'   ranked or not, carrying ecr/sd from build_draft_pool().
#' @return `vor_table` with the estimable no-data rows appended and a
#'   `value_source` column added ("projected" / "consensus"). Rows are
#'   unsorted and untiered; `assign_tiers()` handles both.
add_consensus_rows <- function(vor_table, value_table) {
  ranked <- as.data.frame(vor_table)
  ranked$value_source <- "projected"

  vt <- as.data.frame(value_table)
  if (is.null(vt$sd) || nrow(ranked) == 0) return(ranked)

  candidates <- vt[!vt$has_current_data & !is.na(vt$ecr) & !is.na(vt$sd), , drop = FALSE]
  # A position with no ranked players has no curve to fit, so its players stay
  # in the fallback rather than getting a number pulled out of nowhere. DST is
  # the standing case: team-level, never in value_table at all.
  candidates <- candidates[candidates$pos %in% unique(ranked$pos), , drop = FALSE]
  if (nrow(candidates) == 0) return(ranked)

  est <- do.call(rbind, lapply(split(candidates, candidates$pos), function(grp) {
    ref <- ranked[ranked$pos == grp$pos[1], , drop = FALSE]

    normal_sd <- monotone_map(ref$ecr, ref$sd, grp$ecr, decreasing = FALSE)
    ecr_adj <- grp$ecr + pmax(0, grp$sd - normal_sd)

    grp$vor <- monotone_map(ref$ecr, ref$vor, ecr_adj, decreasing = TRUE)
    # Carried, not recomputed: these rows are being placed against the same
    # replacement level the curve was fit under, so it must be that level.
    grp$replacement_value <- ref$replacement_value[1]
    grp$value_source <- "consensus"
    grp
  }))
  rownames(est) <- NULL

  # An NA-VOR row would reach the Board as an unrankable player, and
  # validate_vor_table() would reject it -- correctly. Drop instead.
  #
  # A position with exactly one ranked player is not dropped: monotone_map()
  # returns that player's value everywhere, so its rookies tie him. That is
  # the rule = 2 clamp at its limit -- with one observation there is nothing
  # else to say -- and it cannot happen on the real board, where the thinnest
  # position (K) has 22 ranked players.
  est <- est[!is.na(est$vor), , drop = FALSE]

  rbind(ranked, est[, names(ranked)])
}

#' Monotone fit of `y` on `x`, evaluated at `xout`.
#'
#' `stats::isoreg()` fits non-decreasing only, so a decreasing fit is done on
#' the negated response and flipped back. Duplicate `x` values are collapsed to
#' one point each before interpolating, because `approx()` cannot interpolate
#' across a repeated abscissa. Outside the fitted range the nearest endpoint is
#' held (`rule = 2`): a rookie ranked ahead of every projected player at his
#' position gets that player's value, not an extrapolated one.
#'
#' @param x,y Fitting points. NA pairs are dropped.
#' @param xout Where to evaluate.
#' @param decreasing TRUE when `y` should fall as `x` rises (ECR -> VOR).
#' @return Numeric, one value per `xout`. All-NA when there is nothing to fit.
monotone_map <- function(x, y, xout, decreasing = TRUE) {
  ok <- !is.na(x) & !is.na(y)
  x <- x[ok]
  y <- y[ok]
  if (length(x) == 0) return(rep(NA_real_, length(xout)))
  if (length(x) == 1) return(rep(y, length(xout)))

  o <- order(x)
  x <- x[o]
  y <- y[o]

  fit <- stats::isoreg(x, if (decreasing) -y else y)
  yhat <- if (decreasing) -fit$yf else fit$yf

  keep <- !duplicated(x)
  yhat <- as.numeric(tapply(yhat, x, mean)[as.character(x[keep])])

  stats::approx(x[keep], yhat, xout = xout, rule = 2)$y
}
