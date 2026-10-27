# Yahoo XRank is an opponent model, not a board reorder

Yahoo's own ADP — what the nine opponents will actually do — was the known blind spot (ADR
0003). Acquired 2026-09-06: `docs/yahoo_fantasy_football_adp.csv`. User-harvested from Yahoo,
Gemini-cleaned. Cols `Player,Position,Team,Bye Week,XRank,ADP`. 332 rows, XRank on all 332,
ADP on 227, defenses coded `DEF`. Name-joins to the pool at **170/170 of the top-170-by-ECR**
(42.5% of the full 764-row pool — the misses are all undraftable tail). No `yahoo_id` to join
on: 100% NA in the `redraft-overall` slice -> `normalize_player_name()` join by necessity.

Decided: XRank drives the **opponent model** — the nine simulated opponents draft
best-available-by-XRank. Do not blend XRank into `vor`. Our board is our opinion; Yahoo tells
us what the other nine will do. Default `dev/dryrun.R` opponents to XRank, not ECR, before
trusting any scenario comparison.

Evidence — **gate PASSED 2026-09-06** (`dev/yahoo_gate.R`): swapping the nine simulated
opponents from best-available-by-ECR to best-available-by-Yahoo-XRank changes **5 of 17
picks** (bar was >= 3) and drops starter Extra pts **568.5 -> 536.0 (-32.5)**. Read: every
strategy conclusion drawn against ECR opponents is optimistic, because ECR opponents leave
value on the board that real Yahoo drafters take. Our top-70 vs Yahoo XRank: Spearman
**0.709**. Full write-up: `docs/backlog/001-yahoo-rank-divergence.md`.

**Considered and rejected**: reordering our board by XRank — XRank is the room's opinion, not
evidence about players.

## Do not confuse the two Yahoo files

An earlier audit concluded "no Yahoo ranking data exists in this repo." True at the time.
`data/yahoo_rankings.csv` is **our own board exported** by `export_yahoo_rankings()`
(`R/95_export.R:68`) for upload *into* Yahoo — Spearman 0.9976 against our board, a mirror.
Watch for: a candidate signal correlating ~1.0 with our own board IS our board.

## Draft-only

The 2026-09-06 note called this "season-long value — waivers and trades share the 'what does
the room think' problem". Superseded: XRank is *preseason*, stale by ~week 3, and waivers
have no turn structure. Do not use in-season without a new data source.
