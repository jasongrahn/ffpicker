source(file.path("..", "..", "R", "96_yahoo_names.R"))

# One block per player, exactly the shape the draft-room paste has: name twice,
# then "POS<dot>Team<dot>Bye N", then "XRank #N" with ADP only sometimes.
yahoo_block <- function(name, pos, team, bye, xrank, adp = NA) {
  rank <- if (is.na(adp)) sprintf("XRank #%d", xrank) else sprintf("XRank #%d·ADP %s", xrank, adp)
  c(name, name, sprintf("%s·%s·Bye %d", pos, team, bye), rank)
}

write_yahoo_file <- function(lines) {
  path <- tempfile(fileext = ".txt")
  writeLines(lines, path)
  path
}

mk_yahoo <- function() {
  data.frame(
    name = c("Patrick Mahomes", "Travis Etienne Jr.", "Texans", "Isaiah Williams",
             "Isaiah Williams", "Bijan Robinson"),
    pos = c("QB", "RB", "DEF", "WR", "WR", "RB"),
    team = c("KC", "Jax", "Hou", "Det", "Chi", "Atl"),
    xrank = 1:6,
    adp = NA_real_,
    stringsAsFactors = FALSE
  )
}
