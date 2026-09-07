# GATE (backlog 001): does Yahoo XRank/ADP change what we'd actually draft?
# Yahoo data is an OPPONENT model, not a board reorder. Nine opponents drafting
# by Yahoo's ordering change who survives to our pick. Our board is untouched.
pkgload::load_all(quiet = TRUE)
store <- "_targets"
league_config  <- targets::tar_read(league_config,  store = store)
draft_board    <- as.data.frame(targets::tar_read(draft_board,    store = store))
draft_fallback <- as.data.frame(targets::tar_read(draft_fallback, store = store))
scarcity_board <- scarcity_input(draft_board, draft_fallback)

pool <- combined_selectable_pool(draft_board, draft_fallback)
pool$ecr <- c(draft_board$ecr, draft_fallback$ecr)
pool$vor <- c(draft_board$vor, rep(NA_real_, nrow(draft_fallback)))

# --- name join: Yahoo's export gives name/pos/team only, no id. Match rate reported. ---
y <- read.csv("docs/yahoo_fantasy_football_adp.csv", stringsAsFactors = FALSE)
names(y) <- c("name","pos","team","bye","xrank","adp")
y <- y[nzchar(y$name), ]
y$pos[y$pos == "DEF"] <- "DST"
y$k <- normalize_player_name(y$name, y$pos)
y <- y[!duplicated(y$k), ]
pool$k <- normalize_player_name(pool$player, pool$pos)
pool$xrank <- y$xrank[match(pool$k, y$k)]
pool$yadp  <- y$adp  [match(pool$k, y$k)]
cat(sprintf("join: %d/%d pool rows matched Yahoo (%.1f%%); of top-170-by-ecr: %d/170\n",
    sum(!is.na(pool$xrank)), nrow(pool), 100*mean(!is.na(pool$xrank)),
    sum(!is.na(pool$xrank[order(pool$ecr)][1:170]))))

# opponent ordering keys
pool$key_ecr <- rank(pool$ecr, ties.method = "first")
# Yahoo: xrank where known; unknown players sort behind all 332 known, by ecr.
yk <- ifelse(is.na(pool$xrank), 1000 + pool$key_ecr, pool$xrank)
pool$key_yahoo <- rank(yk, ties.method = "first")

MY_SLOT <- 5; TEAMS <- league_config$teams
ROUNDS  <- league_config$roster$rounds %||% 17

run_draft <- function(opp_key) {
  cfg <- league_config
  log_path <- tempfile(fileext = ".jsonl"); file.create(log_path)
  start_draft(log_path, TEAMS, "JGrahnasaurs", MY_SLOT)
  my_picks <- data.frame()
  for (n in seq_len(TEAMS * ROUNDS)) {
    state <- replay_pick_log(log_path)
    remaining <- remaining_draft_pool(pool, state)
    rnd <- ceiling(n / TEAMS)
    if (slot_on_the_clock(n, TEAMS) == MY_SLOT) {
      report <- scarcity_report(scarcity_board, state, cfg)
      rec <- recommend_picks(report,
               remaining_draft_pool(draft_board, state),
               remaining_draft_pool(draft_fallback, state))
      if (nrow(rec) == 0) {
        rb <- remaining_draft_pool(draft_board, state)
        rb <- rb[!(rb$pos %in% names(deferred_notes(report))), ]
        rb <- rb[order(rb$vor, decreasing = TRUE), ]
        pick_key <- rb$player_key[1]; src <- "bench"
      } else {
        hit <- which(remaining$player == rec$Player[1] & remaining$pos == rec$Pos[1] &
                       remaining$team == rec$Team[1])
        if (length(hit) != 1) stop(sprintf("round %d: %s matched %d", rnd, rec$Player[1], length(hit)))
        pick_key <- remaining$player_key[hit]; src <- "advised"
      }
      row <- remaining[remaining$player_key == pick_key, ]
      my_picks <- rbind(my_picks, data.frame(round = rnd, overall = n,
        player = row$player, pos = row$pos, team = row$team,
        ecr = round(row$ecr), vor = round(row$vor, 1),
        xrank = row$xrank, source = src, stringsAsFactors = FALSE))
      tn <- "JGrahnasaurs"
    } else {
      pick_key <- remaining$player_key[order(remaining[[opp_key]])][1]
      tn <- paste("Team", slot_on_the_clock(n, TEAMS))
    }
    append_pick_event(log_path, list(type = "pick_made", slot = n, team = tn, player_key = pick_key))
  }
  my_picks
}

base <- run_draft("key_ecr")
yah  <- run_draft("key_yahoo")

cmp <- data.frame(round = base$round,
  ecr_opp   = sprintf("%s (%s, ecr %s)", base$player, base$pos, base$ecr),
  yahoo_opp = sprintf("%s (%s, ecr %s)", yah$player,  yah$pos,  yah$ecr),
  stringsAsFactors = FALSE)
cmp$changed <- ifelse(base$player != yah$player, "<-- CHANGED", "")
print(cmp, row.names = FALSE, right = FALSE)

sv <- function(picks) {
  st <- league_config$roster$starters
  fx <- unlist(league_config$roster$flex_eligible$FLEX)
  picks <- picks[order(picks$vor, decreasing = TRUE, na.last = TRUE), ]
  used <- rep(FALSE, nrow(picks)); ch <- integer(0)
  take <- function(p,k){ i <- head(which(!used & picks$pos %in% p), k); used[i] <<- TRUE; ch <<- c(ch,i) }
  for (p in setdiff(names(st),"FLEX")) take(p, st[[p]])
  take(fx, st$FLEX %||% 0)
  sum(picks$vor[ch], na.rm = TRUE)
}
n_ch <- sum(base$player != yah$player)
cat(sprintf("\n=== GATE: picks changed %d / 17 (bar: >= 3) -> %s\n", n_ch,
            if (n_ch >= 3) "PASS" else "FAIL"))
cat(sprintf("starter Extra pts: ecr-opponents %.1f  |  yahoo-opponents %.1f  |  delta %+.1f\n",
            sv(base), sv(yah), sv(yah) - sv(base)))
