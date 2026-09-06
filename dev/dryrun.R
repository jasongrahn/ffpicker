# Full 17-round dry run, parameterised on draft.defer_until_round so competing
# deferral configs run through identical code. Drives the SAME functions the app
# calls -- pick log, scarcity_report(), recommend_picks() -- so a pass here means
# the app's own advice path completes a draft, not that a parallel simulation does.
#
# Opponents draft best-available by expert rank (ECR). That is the closest cheap
# stand-in for nine real drafters, and it naturally pushes K/DST late (their ECR
# is 150+), so it does not hand our deferral a free win.
pkgload::load_all(quiet = TRUE)

store <- "_targets"
league_config <- targets::tar_read(league_config, store = store)
draft_board <- as.data.frame(targets::tar_read(draft_board, store = store))
draft_fallback <- as.data.frame(targets::tar_read(draft_fallback, store = store))
scarcity_board <- scarcity_input(draft_board, draft_fallback)

pool <- combined_selectable_pool(draft_board, draft_fallback)
pool$ecr <- c(draft_board$ecr, draft_fallback$ecr)
pool$vor <- c(draft_board$vor, rep(NA_real_, nrow(draft_fallback)))

MY_SLOT <- 5
TEAMS <- league_config$teams
ROUNDS <- league_config$roster$rounds %||% 17

run_draft <- function(defer) {
  cfg <- league_config
  cfg$draft$defer_until_round <- defer

  log_path <- tempfile(fileext = ".jsonl")
  file.create(log_path)
  start_draft(log_path, TEAMS, "JGrahnasaurs", MY_SLOT)

  my_picks <- data.frame()
  advice <- character(0)

  for (n in seq_len(TEAMS * ROUNDS)) {
    state <- replay_pick_log(log_path)
    remaining <- remaining_draft_pool(pool, state)
    rnd <- ceiling(n / TEAMS)

    if (slot_on_the_clock(n, TEAMS) == MY_SLOT) {
      report <- scarcity_report(scarcity_board, state, cfg)
      rec <- recommend_picks(report,
                             remaining_draft_pool(draft_board, state),
                             remaining_draft_pool(draft_fallback, state))
      advice <- c(advice, sprintf("R%02d  %s", rnd, explain_scarcity(report, rec)))

      if (nrow(rec) == 0) {
        # No recommendation -> the app tells the drafter to take the best bench
        # player. Model a drafter reading the board as it now renders: greyed
        # (deferred) rows skipped, otherwise straight down by Extra pts.
        rb <- remaining_draft_pool(draft_board, state)
        rb <- rb[!(rb$pos %in% names(deferred_notes(report))), ]
        rb <- rb[order(rb$vor, decreasing = TRUE), ]
        pick_key <- rb$player_key[1]
        src <- "bench"
      } else {
        # Insist on exactly one match: an ambiguous one would mean the
        # recommendation names someone the app could not unambiguously draft.
        hit <- which(remaining$player == rec$Player[1] & remaining$pos == rec$Pos[1] &
                       remaining$team == rec$Team[1])
        if (length(hit) != 1) stop(sprintf("round %d: %s matched %d rows", rnd,
                                           rec$Player[1], length(hit)))
        pick_key <- remaining$player_key[hit]
        src <- "advised"
      }
      row <- remaining[remaining$player_key == pick_key, ]
      my_picks <- rbind(my_picks, data.frame(
        round = rnd, overall = n, player = row$player, pos = row$pos,
        team = row$team, ecr = round(row$ecr), vor = round(row$vor, 1),
        source = src, stringsAsFactors = FALSE
      ))
      team_name <- "JGrahnasaurs"
    } else {
      pick_key <- remaining$player_key[order(remaining$ecr)][1]
      team_name <- paste("Team", slot_on_the_clock(n, TEAMS))
    }

    append_pick_event(log_path, list(type = "pick_made", slot = n,
                                     team = team_name, player_key = pick_key))
  }
  list(picks = my_picks, advice = advice, defer = defer)
}

# Greedy starter fill, then total the starters' Extra pts. That total is the
# actual decision metric here: a deferral is only worth adding if the lineup it
# produces is better, not merely if it stops one ugly-looking pick.
starter_value <- function(picks) {
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

scenarios <- list(
  "baseline (K16, DST15)" = list(K = 16, DST = 15),
  "QB deferred to rd 7"   = list(K = 16, DST = 15, QB = 7),
  "QB deferred to rd 8"   = list(K = 16, DST = 15, QB = 8)
)

results <- lapply(scenarios, run_draft)

for (nm in names(results)) {
  r <- results[[nm]]
  sv <- starter_value(r$picks)
  cat("\n\n########## ", nm, " ##########\n")
  print(r$picks, row.names = FALSE)
  cat("\n-- starting lineup --\n")
  print(sv$lineup[, c("round", "player", "pos", "team", "ecr", "vor")], row.names = FALSE)
  cat("\nstarter Extra pts total:", round(sv$total, 1),
      "| roster:", nrow(r$picks), "/", ROUNDS,
      "| unfilled:", if (length(sv$unfilled)) paste(sv$unfilled, collapse = ",") else "none", "\n")
  qb <- r$picks[r$picks$pos == "QB", ]
  cat("QBs taken: ", paste(sprintf("%s (R%d, expert %d)", qb$player, qb$round, qb$ecr),
                           collapse = "; "), "\n")
}

cat("\n\n=== SUMMARY ===\n")
for (nm in names(results)) {
  sv <- starter_value(results[[nm]]$picks)
  cat(sprintf("%-24s starters %6.1f  roster %d/%d  unfilled: %s\n", nm, sv$total,
              nrow(results[[nm]]$picks), ROUNDS,
              if (length(sv$unfilled)) paste(sv$unfilled, collapse = ",") else "none"))
}

cat("\n=== ADVICE, QB deferred to rd 7 ===\n")
cat(results[["QB deferred to rd 7"]]$advice, sep = "\n")
