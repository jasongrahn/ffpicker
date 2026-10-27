# Third-party fantasy libraries cannot fill the Yahoo gap

Wanted: cross-league ADP, rankings or projections — above all Yahoo's own ADP, i.e. what the
nine opponents will actually do. Evaluated 2026-09-06, draft prep.

`ffscrapr` (MFL/Sleeper/Fleaflicker/ESPN, Yahoo only "perhaps eventually"), the Python
`espn-api` package, and ESPN-fantasy MCP servers all require a `league_id` for a league you
are a member of, and return that league's rosters/settings/transactions. **None expose
cross-league ADP, rankings, or projections** -> none help a Yahoo league.

Decided: do not use; do not re-investigate this category. The gap they would fill stays the
known blind spot: `yahoo_id`, `player_owned_yahoo`, and `player_owned_espn` are 100% NA in
`ff_rankings`' `redraft-overall` slice. Carried as the known blind spot in Phase 6's opponent
model. Partly filled 2026-09-06 by a user-harvested Yahoo XRank/ADP file — ADR 0005.

**Considered and rejected**:
- `ffscrapr`, `espn-api`, ESPN-fantasy MCP servers — all league-scoped, above.
- `YFAR` — wraps Yahoo's retired OAuth1 flow. ADR 0002.
