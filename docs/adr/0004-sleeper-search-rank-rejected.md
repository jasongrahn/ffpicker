# Sleeper `search_rank` rejected: real signal, wrong region

Sleeper API evaluated 2026-09-06 as a free ranking signal for the draft. Access clean
(read-only HTTP, no token, terms fine); usefulness not.

`search_rank` = search-autocomplete popularity. Genuinely independent of FantasyPros ECR in
the tail (rho 0.166) while still predicting 2025 PPG there (-0.314 vs ECR's -0.104). But that
edge lives only where `ecr > 290`, and a 10-team 17-round draft removes 170 players — our own
17 picks bottom out at `ecr` 219. Reordering all 160 matched tail players by `search_rank`
changed **0 of 17 picks and 0.0 starter points**. Real signal, wrong region.

Measured under the 17-round assumption. League is 15 rounds (150 players removed) -> fewer
picks reach the tail -> conclusion only strengthens.

Decided: do not use `search_rank`; do not re-investigate it.

**Considered and rejected**: reordering the tail of the board by `search_rank` — 0 picks
changed.

Not covered by this closure: the `trending/add` endpoint — a different signal, aimed at the
Yahoo-ADP blind spot (ADR 0003). Unprobed.

Evidence: `docs/handoff/drafting/ffdraft-handoff-20260906-9.md`, harness `dev/sleeper/`.
