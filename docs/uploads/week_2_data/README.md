# Week 2 upload — Yahoo player tables

Source: copy/paste from Yahoo player pages, 2026-09-16. Raw `.txt` = one table
cell per line, cells separated by lone-tab lines.

Parser: `dev/weekly/parse_yahoo_paste.py`. Three table schemas, one run.

| source | slice | rows | -> output |
|---|---|---|---|
| `qb.txt` | QB | 50 | `week_2_players.csv` |
| `rb.txt` | RB | 100 | " |
| `te.txt` | TE | 75 | " |
| `wr.txt` | WR | 125 | " |
| `wrt.txt` | FLEX (RB/WR/TE) | 125, all dupes | " |
| `game-day-calls.txt` | active/inactive calls | 422 | `week_2_game_day_calls.csv` |
| `injury-report.txt` | full injury report | 664 | `week_2_injury_report.csv` |
| `ir-reserved` | IR placements | 25 | `week_2_ir_reserved.csv` |
| `league-team-changes` | **NFL** team moves, not league | 50 | `week_2_nfl_team_changes.csv` |
| `roster-changes` | activate / deactivate | 25 | `week_2_roster_changes.csv` |

Player files dedupe on `player + nfl_team`, FLEX rows lose -> **347 unique**.
Calls and injury pass through 1:1, **422 / 422** and **664 / 664**.
No K, no DEF — only 1 of each rostered, not worth pasting.

## Columns

`player, pos, pos_eligible, nfl_team, status, opponent, home_away, kickoff,
roster_status, gp, bye, fan_pts, rank_preseason, rank_actual, pct_rostered,
pass_yds, pass_td, pass_int, rush_att, rush_yds, rush_td, tgt, rec, rec_yds,
rec_td, ret_td, two_pt, fum_lost, source_file`

- `pos` = primary. `pos_eligible` = full Yahoo string, 3 multi-pos cases
  (`RB,TE` x2, `WR,TE` x1).
- `status` = Yahoo designation. 271 blank, 47 `NA`, 16 `Q`, 9 `IR`, 2 `O`,
  2 `IR-R`.
- `roster_status` = owning team name, or `FA`.
- `kickoff` / `opponent` / `home_away` = **Week 2** game. This is the only
  forward-looking data in the file.
- `pct_rostered` = integer, `%` stripped.

All three CSVs share the first 8 columns. After that:

- `week_2_game_day_calls.csv` adds `injury, status_col, updated, depth_chart`.
  225 of 422 rows have blank `injury`/`status_col` — Yahoo lists the player
  with no active call. `updated` is a timestamp string, not parsed.
- `week_2_injury_report.csv` adds `injury_type, depth_chart`. 467 of 664 blank
  `injury_type` (mostly `NA` = not active, no injury named).
- `status` (from the name blob) and `status_col` (its own column) agree where
  both exist. `depth_chart` == `nfl_team` on every row but one: Montrell
  Johnson Jr., last row of `game-day-calls.txt`, where the paste is
  **truncated mid-row**. Source problem, not a parse problem.

## Validation

Checked against the Yahoo Week 2 matchup page (JGrahnasaurs vs Sunday Kevin),
both 15-man rosters, starters and bench: **26 of 28 players found, 0 field
mismatches** on team / pos / opponent / home-away / kickoff / status.

Two not found, both source gaps:
- `Chase McLaughlin`, `Will Reichard` — kickers, never pasted.
- `Tyrone Tracy Jr.` (NYG RB) — `grep Tracy rb.txt` = 0. Outside Yahoo's
  top-100 RB slice. Still rostered; the paste just doesn't reach him.

## Traps, both already paid for

**1. Never `text.split("\n\t\n")`.** Two adjacent empty cells share one tab
line, so that split collapses them and every later cell in the row shifts
left — rows with a blank Injury/Status silently swallow the next player's
cells. Cost 113 dropped rows in calls, 253 in injury. `split_cells()` walks
lines instead.

**2. Never paste the private-use glyph range into source.** It flattens to
`[-]`, which strips every hyphen, which kills the `TEAM - POS` match and
blanks `pos`/`nfl_team` on every row. `PRIV_RE` is escape-built for this
reason. Do not "tidy" it.

## Trap

**Stats are Week 1 actuals, not Week 2 projections.** `gp = 1` everywhere;
`fan_pts` is the season total, which right now == Week 1. Verified:
Caleb Williams 269 pass yds / 2 pass TD / 65 rush yds / 2 rush TD -> 37.26
under half-PPR, matches the file exactly.

Yahoo's projection column was not in the pasted view. Week 2 `proj` for
`data/weekly/` still has to be hand-entered, same as Week 1.

`rank_preseason` / `rank_actual` = overall Yahoo ranks, not position ranks.


## Transaction tables (`ir-reserved`, `league-team-changes`, `roster-changes`)

Different schema: `Date, Player, Roster Status, Action, Change`. Two gotchas.

1. **Date comes BEFORE the player**, and the next row's date rides on the tail
   of the last column's cell. So row N's date is the last line of the cell just
   before row N's blob. `date_prefixed=True` handles it.
2. **"Action" is two icon-button cells**, so a row is 4 cells after the blob,
   not the 3 the header implies. Parse 4, drop the icons on write.

These list IDP positions (`LB`, `DE`, `CB`, `S`, `DT`, `DL`, `DB`), so `POS` in
the regex is wider than this league's six scoring positions. League is **not**
IDP — filter to `QB/RB/WR/TE/K/DEF` before using.

`league-team-changes` is **NFL** roster movement (`Sea to Was`, `NFC to AFC`),
not fantasy-league transactions. Name is Yahoo's, kept as-is.

`week_2_ir_reserved.csv` outranks `week_2_game_day_calls.csv` where they
disagree: a player can read `Q` in the calls table and `On Injured Reserve` in
this one. IR is the later, harder fact.
