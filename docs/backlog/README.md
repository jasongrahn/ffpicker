# Backlog

Ideas evaluated but not built. Each carries its measured evidence and a pass/fail
gate set *before* building, so revisiting starts from numbers, not enthusiasm.

| # | File | Status | One line |
|---|---|---|---|
| 001 | `001-yahoo-rank-divergence.md` | UNBLOCKED 2026-09-06, **draft-only** | Flag where Yahoo's ordering disagrees with ours -> predicts what the nine opponents do. Data **acquired**: `docs/yahoo_fantasy_football_adp.csv`, 332 rows, joins 170/170 of the top-170-by-ECR. Gate **PASSED** — correct use is an opponent model, not a board reorder (5 of 17 picks changed). Superseded claim: "no Yahoo ranking data exists in the repo" — that was true only before 09-06; `data/yahoo_rankings.csv` remains our own export, do not confuse the two. **Draft is over — value is retrospective now; XRank is stale by ~week 3.** |
